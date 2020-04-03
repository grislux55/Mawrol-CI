detect_os() {
  hydrogen=`grep "Hydrogen" /system/build.prop`
  oxygen=`grep "Oxygen" /system/build.prop`
  if [ "$hydrogen" == "" ] && [ "$oxygen" == "" ]
  then
    os="custom"
  else
    os="stock"
  fi
}

# set_task $1:task_name $2:cgroup_name $3:target $4:resource_file
set_task() {
    # avoid matching grep itself
    # ps -Ao pid,args | grep kswapd
    # 150 [kswapd0]
    # 16490 grep kswapd
    local ps_ret
    ps_ret="$(ps -Ao pid,args)"
    for temp_pid in $(echo "$ps_ret" | grep "$1" | awk '{print $1}'); do
        for temp_tid in $(ls "/proc/$temp_pid/task/"); do
            echo "$temp_tid" > "/dev/$4/$2/$3"
        done
    done
}

set_val() {
  echo $2 > $1
}

lock_val() {
  if [ -f $2 ]; then
    chmod 0666 $2
    set_val $2 $1
    chmod 0444 $2
  fi
}

log() {
  touch $MODDIR/log
  echo $1 >> $MODDIR/log
}
