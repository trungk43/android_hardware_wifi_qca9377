#
# Main Makefile
#
export ATH_TOPDIR=$(shell pwd)/..

ifeq (${KERNELPATH}, )
export KERNELPATH=/mnt/nfsroot/weiguang.ruan/android5.1/out/target/product/p201/obj/KERNEL_OBJ/
else
$(info KERNELPATH=${KERNEL_PATH})
export KERNELPATH
endif

include $(ATH_TOPDIR)/build/env.makefile
include scripts/${BOARD_TYPE}/config.${BOARD_TYPE}
include scripts/${BOARD_TYPE}/Makefile.${BOARD_TYPE}
ifneq ($(wildcard scripts/${BOARD_TYPE}/Makefile.${BLUETOOTHSTACK}), )
    include scripts/${BOARD_TYPE}/Makefile.${BLUETOOTHSTACK}
endif

#################################################################################################################################
ifndef KERNELPATH
$(error "Must specify KERNELPATH value")
endif

ifndef KERNELARCH
$(error "Must specify KERNELARCH value")
endif

#################################################################################################################################
export MAKEARCH=make ARCH=$(KERNELARCH) CROSS_COMPILE=$(TOOLPREFIX)

export INSTALL_ROOT=${ATH_TOPDIR}/rootfs-$(BOARD_TYPE).build
export ROOTFS_TOPDIR=${ATH_TOPDIR}/rootfs
export WLAN_DRIVER_TOPDIR=${ATH_TOPDIR}/drivers
export WPA_SUPPLICANT_TOPDIR=${ATH_TOPDIR}/apps/wpa_supplicant_8
export IW30_TOPDIR=${ATH_TOPDIR}/apps/iw-3.0
export LIBNL32_TOPDIR=${ATH_TOPDIR}/apps/libnl-3.2.25
export QCMBR_TOPDIR=${ATH_TOPDIR}/apps/qcmbr
export BLUETOPIA_TOPDIR=${ATH_TOPDIR}/apps/Bluetopia

export ATH_QCACLD_TOPDIR=${WLAN_DRIVER_TOPDIR}/qcacld-new
export ATHDIAG_TOPDIR=${ATH_QCACLD_TOPDIR}/tools/athdiag

#################################################################################################################################
# qcacld PATH
#################################################################################################################################
export FW_WLAN_NAME=qcacld-new
#################################################################################################################################
# CFG80211 PATH
#################################################################################################################################
export CFG80211_NAME=backports

#################################################################################################################################
clean: drivers_clean rootfs_clean

#
# rootfs build
#
rootfs_prep:
	@mkdir -p $(INSTALL_ROOT)
	@mkdir -p $(INSTALL_ROOT)/sbin
	@mkdir -p $(INSTALL_ROOT)/usr/sbin
	@mkdir -p $(INSTALL_ROOT)/lib/modules
	@mkdir -p $(INSTALL_ROOT)/etc

rootfs_build:
	@echo Build rootfs
	@cp -Rf $(ROOTFS_TOPDIR)/* $(INSTALL_ROOT)

rootfs_clean:
	@echo Clean rootfs
	@rm -rf $(INSTALL_ROOT)

#
# drivers build
#
drivers: rootfs_prep
	@echo Build drivers
	cd ${WLAN_DRIVER_TOPDIR} && ${MAKEARCH}
	find ${WLAN_DRIVER_TOPDIR} -name 'cfg80211.ko' -exec cp '{}' $(INSTALL_ROOT)/lib/modules ';'
	find ${WLAN_DRIVER_TOPDIR} -name 'compat.ko' -exec cp '{}' $(INSTALL_ROOT)/lib/modules ';'
	find ${WLAN_DRIVER_TOPDIR} -name 'wlan.ko' -exec cp '{}' $(INSTALL_ROOT)/lib/modules ';'

drivers_firmware: rootfs_prep
	@echo Install firmware
	cd ${WLAN_DRIVER_TOPDIR} && ${MAKEARCH} firmware_install

drivers_firmware_transfer:
	@echo Transfer driver firmwares
	cd ${WLAN_DRIVER_TOPDIR} && ${MAKEARCH} firmware_toarray

drivers_clean:
	@echo Clean drivers
	cd ${WLAN_DRIVER_TOPDIR} && ${MAKEARCH} driver_clean

common_patch:
	@echo Start Common Patches
	@cd ${WLAN_DRIVER_TOPDIR} && patch -s -p0 < patches/001-cfg80211-backports-3.12.8-1.patch
	@echo BOARD_TYPE_AIO_PATCH_CAF=$(BOARD_TYPE_AIO_PATCH_CAF)
ifneq ($(strip $(BOARD_TYPE_AIO_PATCH_CAF)),)
ifeq ($(BOARD_TYPE),x86)
	@cd ${WLAN_DRIVER_TOPDIR}/backports && patch -s -p1 < ${WLAN_DRIVER_TOPDIR}/patches/x86/bt_backports-3.12.8-1.patch
	@echo Enable Bluetooth backports
	@cp $(WLAN_DRIVER_TOPDIR)/backports/backports_bt_enabled.config  ${WLAN_DRIVER_TOPDIR}/backports/.config
endif
endif
	@cd ${WLAN_DRIVER_TOPDIR}/../apps/ && patch -s -p0 < ${WLAN_DRIVER_TOPDIR}/patches/002-wpa_supplicant-for-aio.patch
	@cd ${WPA_SUPPLICANT_TOPDIR} && cp wpa_supplicant/android.config wpa_supplicant/.config
	@cd ${WPA_SUPPLICANT_TOPDIR} && cp hostapd/android.config hostapd/.config
	@echo End of Common Patches

#
# wpa_supplicant build
#
wpa_supplicant: rootfs_prep wpa_supplicant_clean libnl
	@echo Build wpa_supplicant
	cd $(WPA_SUPPLICANT_TOPDIR)/wpa_supplicant && \
	${MAKEARCH} CC=$(TOOLPREFIX)gcc AR=$(TOOLPREFIX)ar LD=$(TOOLPREFIX)ld && \
	${MAKEARCH} DESTDIR=$(INSTALL_ROOT) BINDIR=/sbin LIBDIR=/lib install

wpa_supplicant_clean:
	@echo Clean wpa_supplicant
	cd $(WPA_SUPPLICANT_TOPDIR)/wpa_supplicant && ${MAKEARCH} clean

#
# hostapd build
#
hostapd: rootfs_prep hostapd_clean libnl
	@echo Build hostapd
	cd $(WPA_SUPPLICANT_TOPDIR)/hostapd && \
	${MAKEARCH} CC=$(TOOLPREFIX)gcc AR=$(TOOLPREFIX)ar LD=$(TOOLPREFIX)ld && \
	cp -f hostapd $(INSTALL_ROOT)/sbin && \
	cp -f hostapd_cli $(INSTALL_ROOT)/sbin

hostapd_clean:
	@echo Clean hostapd
	cd $(WPA_SUPPLICANT_TOPDIR)/hostapd && ${MAKEARCH} clean

#
# iw build
#
iw: rootfs_prep iw_clean
	@echo Build iw-3.0
	cd $(IW30_TOPDIR) && \
	${MAKEARCH} CC=$(TOOLPREFIX)gcc AR=$(TOOLPREFIX)ar LD=$(TOOLPREFIX)ld && \
	${MAKEARCH} DESTDIR=$(INSTALL_ROOT) SBINDIR=/sbin install

iw_clean:
	@echo Clean iw-3.0
	cd $(IW30_TOPDIR) && ${MAKEARCH} clean

#
# libnl build
#
libnl_config:
	@echo Config libnl1-3.2.25
	cd $(LIBNL32_TOPDIR) && \
	./configure --host=$(KERNELARCH) CC=$(TOOLPREFIX)gcc AR=$(TOOLPREFIX)ar LD=$(TOOLPREFIX)ld

libnl: libnl_config libnl_clean
	@echo Build libnl1-3.2.25
	cd $(LIBNL32_TOPDIR) && \
	${MAKEARCH}

libnl_clean:
	@echo Clean libnl1-3.2.25
	cd $(LIBNL32_TOPDIR) && ${MAKEARCH} clean


#
# qcmbr build
#
qcmbr: qcmbr_clean
	@echo Build qcmbr
	cd $(QCMBR_TOPDIR) && \
	${MAKEARCH} CC=$(TOOLPREFIX)gcc AR=$(TOOLPREFIX)ar LD=$(TOOLPREFIX)ld && \
	cp -f Qcmbr $(INSTALL_ROOT)/sbin
	
qcmbr_clean:
	@echo Clean qcmbr
	cd $(QCMBR_TOPDIR) && ${MAKEARCH} clean
	
#
# set athdiag build
#
athdiag: athdiag_tool_clean
	@echo Build athdiag
	cd $(ATHDIAG_TOPDIR) && \
	${MAKEARCH} CC=$(TOOLPREFIX)gcc AR=$(TOOLPREFIX)ar LD=$(TOOLPREFIX)ld && \
	cp -f athdiag $(INSTALL_ROOT)/sbin
	
athdiag_tool_clean:
	@echo Clean athdiag
	cd $(ATHDIAG_TOPDIR) && ${MAKEARCH} clean
	

