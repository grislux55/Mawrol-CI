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
