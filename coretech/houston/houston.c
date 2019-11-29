/* Copyright for changes pappschlumpf@xda Erik Müller*/

#define pr_fmt(fmt) "houston: " fmt

#include <linux/init.h>
#include <linux/kthread.h>
#include <linux/module.h>
#include <linux/tick.h>
#include <linux/kernel.h>
#include <linux/kernel_stat.h>
#include <linux/delay.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/cpufreq.h>
#include <linux/cpumask.h>
#include <linux/freezer.h>
#include <linux/wait.h>
#include <linux/device.h>
#include <linux/poll.h>
#include <linux/ioctl.h>
#include <linux/perf_event.h>
#include <linux/cdev.h>
#include <linux/workqueue.h>
#include <linux/clk.h>
#include <linux/oem/houston.h>
#include "houston.h"

static DECLARE_WAIT_QUEUE_HEAD(ht_poll_waitq);

static dev_t ht_ctl_dev;
static struct class *driver_class;
static struct cdev cdev;
static int perf_ready = -1;

struct cpuload_info {
	int cnt;
	int cmin;
	int cmax;
	int sum;
	long long iowait_min;
	long long iowait_max;
	long long iowait_sum;
};
static struct ai_parcel parcel;

static int log_lv = 0;
module_param(log_lv, int, 0664);

/* ais */
static int ais_enable = 0;
module_param(ais_enable, int, 0664);

static bool cpuload_query = false;
module_param(cpuload_query, bool, 0664);

/* battery query, it takes time to query */
static bool bat_query = false;
module_param(bat_query, bool, 0664);

static bool bat_sample_high_resolution = false;
module_param(bat_sample_high_resolution, bool, 0664);

/* force update battery current */
static unsigned long bat_update_period_us = 1000000; // 1 sec
module_param(bat_update_period_us, ulong, 0664);

/* fps boost switch */
static bool fps_boost_enable = false;
module_param(fps_boost_enable, bool, 0664);

/* freq hispeed */
static bool cpufreq_hispeed_enable = false;
module_param_named(cpufreq_hispeed_enable, cpufreq_hispeed_enable, bool, 0664);

static unsigned int cpufreq_hispeed[3] = { 1209600, 1612800, 1612800 };
module_param_array(cpufreq_hispeed, uint, NULL, 0664);

static bool ddrfreq_hispeed_enable = false;
module_param(ddrfreq_hispeed_enable, bool, 0664);

static unsigned int ddrfreq_hispeed = 1017;
module_param(ddrfreq_hispeed, uint, 0664);

/* choose boost freq to lock or lower bound */
static unsigned int fps_boost_type = 1;
module_param(fps_boost_type, uint, 0664);

/* filter out too close boost hint */
static unsigned long fps_boost_filter_us = 8000;
module_param(fps_boost_filter_us, ulong, 0664);

unsigned int ht_enable = 0;
module_param(ht_enable, uint, 0664);

unsigned int sample_rate_ms = 0;
module_param(sample_rate_ms, uint, 0664);

unsigned int fps_data_sync = 0;
module_param(fps_data_sync, uint, 0664);

extern unsigned long long task_sched_runtime(struct task_struct *p);

static long ht_ctl_ioctl(struct file *file, unsigned int cmd, unsigned long __user arg)
{
	if (_IOC_TYPE(cmd) != HT_IOC_MAGIC) return 0;
	if (_IOC_NR(cmd) > HT_IOC_MAX) return 0;

	switch (cmd) {
	case HT_IOC_COLLECT:
	{
		memset (&parcel, 0, sizeof(parcel));
		if (copy_to_user((struct ai_parcel __user *) arg, &parcel, sizeof(parcel))) {
			wake_up_interruptible(&ht_poll_waitq);
			return 0;
		}
		break;
	}
	case HT_IOC_SCHEDSTAT:
	{
		struct task_struct *task;
		u64 exec_ns = 0;
		u64 pid;
		if (copy_from_user(&pid, (u64 *) arg, sizeof(u64)))
			return 0;

		rcu_read_lock();
		task = find_task_by_vpid(pid);
		if (task) {
			get_task_struct(task);
			rcu_read_unlock();
			exec_ns = task_sched_runtime(task);
			put_task_struct(task);
		} else {
			rcu_read_unlock();
		}
		if (copy_to_user((u64 *) arg, &exec_ns, sizeof(u64))) {
			wake_up_interruptible(&ht_poll_waitq);
			return 0;
		}
		break;
	}
	case HT_IOC_CPU_LOAD:
	{
		struct cpuload cl;
		if (copy_from_user(&cl, (struct cpuload *) arg, sizeof(struct cpuload)))
			return 0;
		memset (&cl, 0, sizeof(struct cpuload));
		if (copy_to_user((struct cpuload *) arg, &cl, sizeof(struct cpuload))) {
			wake_up_interruptible(&ht_poll_waitq);
			return 0;
		}
		break;
	}
	}
	return 0;
}

static unsigned int ht_ctl_poll(struct file *fp, poll_table *wait)
{
	poll_wait(fp, &ht_poll_waitq, wait);
	return POLLIN;
}

static const struct file_operations ht_ctl_fops = {
	.owner = THIS_MODULE,
	.poll = ht_ctl_poll,
	.unlocked_ioctl = ht_ctl_ioctl,
	.compat_ioctl = ht_ctl_ioctl,
};

static int perf_ready_store(const char *buf, const struct kernel_param *kp)
{
	int val;
	if (sscanf(buf, "%d\n", &val) <= 0)
		return 0;

	perf_ready = val;
	return 0;
}

static int perf_ready_show(char *buf, const struct kernel_param *kp)
{
	return snprintf(buf, PAGE_SIZE, "%d\n", perf_ready);
}

static struct kernel_param_ops perf_ready_ops = {
	.set = perf_ready_store,
	.get = perf_ready_show,
};
module_param_cb(perf_ready, &perf_ready_ops, NULL, 0664);

static int ht_fps_boost_store(const char *buf, const struct kernel_param *kp)
{
	return 0;
}

static struct kernel_param_ops ht_fps_boost_ops = {
	.set = ht_fps_boost_store,
};
module_param_cb(fps_boost, &ht_fps_boost_ops, NULL, 0220);

static int fps_sync_init(void)
{
	int rc;
	struct device *class_dev;

	rc = alloc_chrdev_region(&ht_ctl_dev, 0, 1, HT_CTL_NODE);
	if (rc < 0) {
		return 0;
	}

	driver_class = class_create(THIS_MODULE, HT_CTL_NODE);
	if (IS_ERR(driver_class)) {
		rc = -ENOMEM;
		goto exit_unreg_chrdev_region;
	}
	class_dev = device_create(driver_class, NULL, ht_ctl_dev, NULL, HT_CTL_NODE);
	if (IS_ERR(class_dev)) {
		rc = -ENOMEM;
		goto exit_destroy_class;
	}
	cdev_init(&cdev, &ht_ctl_fops);
	cdev.owner = THIS_MODULE;
	rc = cdev_add(&cdev, MKDEV(MAJOR(ht_ctl_dev), 0), 1);
	if (rc < 0) {
		goto exit_destroy_device;
	}
	return 0;
exit_destroy_device:
	device_destroy(driver_class, ht_ctl_dev);
exit_destroy_class:
	class_destroy(driver_class);
exit_unreg_chrdev_region:
	unregister_chrdev_region(ht_ctl_dev, 1);
	return 0;
}

static int ht_init(void)
{
	fps_sync_init();
	return 0;
}
pure_initcall(ht_init);
