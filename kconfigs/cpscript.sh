#! /bin/sh
##############################################
#$1 should be kernel source code dir         #
#$2 should be command(copy or recover)       #
##############################################
kernel_dir=$1
command=$2







backup_config=${kernel_dir}/../hardware/wifi/qualcomm/drivers/qca9377/kconfigs/Kconfig.bak
target_config=${kernel_dir}/net/wireless/Kconfig
backup_defconfig=${kernel_dir}/../hardware/wifi/qualcomm/drivers/qca9377/kconfigs/meson64_defconfig.bak
target_defconfig=${kernel_dir}/arch/arm64/configs/meson64_defconfig


if [ ! -f $target_config ] || [ ! -f $target_defconfig ]; then
echo "ERROR!!! kernel_dir is not correct! exit" 
echo "usage:\r\ncpscript.sh \"kernel source code dir\"  copy/recover"
exit
fi

if [ ! "$command" = "copy" ] && [ ! "$command" = "recover" ]; then
echo "ERROR!!! there is no command!" 
echo "usage:\r\ncpscript.sh \"kernel source code dir\"  copy/recover"
exit
fi



if [ "$command" = "copy" ];then
  echo "wifi: copy qca9377 kconfig configurations into kernel"
  #t_md5=`md5sum ${target_config}`
  #s_md5=`md5sum ${source_config}`
  #t_md5=${t_md5%%" "*}
  #s_md5=${s_md5%%" "*}
  #echo "target_config's md5 is ${t_md5}"
  #echo "source_config's md5 is ${s_md5}"
  
#  if [ "$t_md5" = "$s_md5" ];then
#	echo "config copy already done before, exit"
#	exit
#  fi

  line=`sed -n '/config WEXT_PRIV/=' ${target_config}`

  sed -e '2d' -e '1,2s/config WIRELESS_EXT/config WIRELESS_EXT\n\tbool "wireless extention, enabled only for qca9377"/g' \
      -e "`expr ${line} + 1`d" -e 's/config WEXT_PRIV/config WEXT_PRIV\n\tbool "wireless priv, enabled only for qca9377"/g' ${target_config} > ${backup_config}
  cp -rf ${backup_config} ${target_config}

  sed -e 's/CONFIG_CFG80211=y/CONFIG_CFG80211=m/g' -e 's/CONFIG_MAC80211=y/CONFIG_MAC80211=m\nCONFIG_WIRELESS_EXT=y\nCONFIG_WEXT_PRIV=y/g' ${target_defconfig} > ${backup_defconfig}
  cp -rf ${backup_defconfig} ${target_defconfig}
  rm -r ${backup_defconfig} ${backup_config}

elif [ "$command" = "recover" ];then
  echo "wifi: recover qca9377 kconfig changes in kernel"
  line=`sed -n '/config WEXT_PRIV/=' ${target_config}`
  sed -e '2d' -e "`expr ${line} + 1`d" -e "/config WIRELESS_EXT/a\\\tbool" -e "/config WEXT_PRIV/a\\\tbool" ${target_config}> ${backup_config}
  cp -rf ${backup_config} ${target_config}

  sed -e 's/CONFIG_CFG80211=m/CONFIG_CFG80211=y/g' -e 's/CONFIG_MAC80211=m/CONFIG_MAC80211=y/g' -e '/CONFIG_WIRELESS_EXT=y/'d -e '/CONFIG_WEXT_PRIV=y/'d ${target_defconfig}> ${backup_defconfig}
  cp -rf ${backup_defconfig} ${target_defconfig}
  rm -f ${backup_config} ${backup_defconfig}
fi


