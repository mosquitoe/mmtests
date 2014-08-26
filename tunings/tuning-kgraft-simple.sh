#!/bin/bash
# This script manipulates kgraft patches.

# Taking care about env variables:
# TUNING_KGRAFT_WORKDIR
# TUNING_KGRAFT_PACKAGE

TUNING_KGRAFT_WORKDIR=${TUNING_KGRAFT_WORKDIR:-/tmp/tuning-kgraft}
TUNING_KGRAFT_PACKAGE=${TUNING_KGRAFT_PACKAGE:-$SHELLPACK_INCLUDE/tuning_kgraft.tgz}

OP=undefined

while [ "$1" != "" ]; do
	case "$1" in
	--enable)
		OP=enable
		shift
		;;
	--disable)
		OP=disable
		shift
		;;
	*)
		echo Unrecognised option: $1
		shift
	esac
done

function kgr_assert_removed() {
	if lsmod | grep -q kgraft_patch_read; then
		echo Module kgraft_patch_read already inserted
		exit 1
	fi
}

function kgr_unpack() {
	mkdir -p $TUNING_KGRAFT_WORKDIR
	pushd $TUNING_KGRAFT_WORKDIR
	tar xzf $TUNING_KGRAFT_PACKAGE
	popd
}

function kgr_compile() {
	WORKDIR=$(readlink -f $TUNING_KGRAFT_WORKDIR/kgr_simple)
	KERN_FLAVOR=$(uname -r | sed 's/^.*-//')
	KERN_ARCH=$(uname -m)
	make -C /usr/src/linux-obj/$KERN_ARCH/$KERN_FLAVOR M="$WORKDIR" O="$WORKDIR"
}

function kgr_insert() {
	insmod $TUNING_KGRAFT_WORKDIR/kgr_simple/kgraft_patch_read.ko
	if [ ! -e /sys/kernel/kgraft/kgr_simple_patcher_sys_read ]; then
		echo "kGraft sys directory not touched, aborting"
		exit 1
	fi
}

function kgr_simple_enable() {
	kgr_assert_removed
	kgr_unpack
	kgr_compile
	kgr_insert
}

case $OP in
	undefined)
		echo No operation specified.
		exit 1
		;;
	enable)
		kgr_simple_enable
		;;
	disable)
		echo Impossible to remove kgraft module.
		exit 0
		;;
	*)
		echo Undefined operation.
		exit 1
esac

