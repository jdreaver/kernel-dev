#!/usr/bin/env bash

set -euxo pipefail

if [ $# -ne 1 ]; then
    echo 'Usage: minimal-qemu-kernel-config.sh <kernel-source-dir>'
    exit 1
fi

kernel_dir=$1

cd "$kernel_dir"
make mrproper # Clears all artifacts, do this especially if you upgrade from a significant old version
make defconfig kvm_guest.config
scripts/config \
  --set-val DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT y \
  --set-val DEBUG y \
  --set-val GDB_SCRIPTS y \
  --set-val CONFIG_RUST y \
  --set-val DEBUG_DRIVER y \
  --set-val CONFIG_DM_DEBUG y \
  --set-val CONFIG_IKCONFIG y \
  --set-val CONFIG_IKCONFIG_PROC y \
  --set-val CONFIG_LOCALVERSION '"-reaver-dev"' \
  --set-val CONFIG_FUNCTION_TRACER y \
  --set-val CONFIG_FUNCTION_GRAPH_TRACER y \
  --set-val CONFIG_FUNCTION_GRAPH_RETVAL y \
  --set-val CONFIG_FUNCTION_GRAPH_RETADDR y \
  --set-val CONFIG_FPROBE y \
  --set-val CONFIG_FUNCTION_PROFILER y \
  --set-val CONFIG_DYNAMIC_FTRACE y \
  --set-val CONFIG_FPROBE_EVENTS y \
  --set-val CONFIG_MODULE_DEBUG y \
  --set-val CONFIG_BPF_SYSCALL y \
  --set-val CONFIG_BPF_JIT y \
  --set-val CONFIG_LOCALVERSION_AUTO y

# Add more more debug options unless DEBUG=no env var is set. Some of these taken from
# https://docs.kernel.org/process/submit-checklist.html#test-your-code
if [[ "${DEBUG:-}" != "no" ]]; then
  scripts/config \
    --set-val CONFIG_PREEMPT y \
    --set-val CONFIG_DEBUG_PREEMPT y \
    --set-val CONFIG_SLUB_DEBUG y \
    --set-val CONFIG_DEBUG_PAGEALLOC y \
    --set-val CONFIG_DEBUG_KMEMLEAK y \
    --set-val CONFIG_DEBUG_MUTEXES y \
    --set-val CONFIG_DEBUG_SPINLOCK y \
    --set-val CONFIG_DEBUG_ATOMIC_SLEEP y \
    --set-val CONFIG_PROVE_RCU y \
    --set-val CONFIG_PROVE_LOCKING y \
    --set-val CONFIG_LOCKDEP y \
    --set-val CONFIG_DEBUG_LOCKDEP y \
    --set-val CONFIG_DEBUG_LIST y \
    --set-val CONFIG_BUG_ON_DATA_CORRUPTION y \
    --set-val CONFIG_GDB_SCRIPTS y \
    --set-val CONFIG_RANDOMIZE_BASE n \
    --set-val CONFIG_DYNAMIC_DEBUG y \
    --set-val CONFIG_DYNAMIC_DEBUG_CORE y \
    --set-val CONFIG_SOFTLOCKUP_DETECTOR y \
    --set-val CONFIG_HARDLOCKUP_DETECTOR y \
    --set-val CONFIG_DETECT_HUNG_TASK y \
    --set-val CONFIG_DEFAULT_HUNG_TASK_TIMEOUT 60 \
    --set-val CONFIG_WQ_WATCHDOG y \
    --set-val CONFIG_DEBUG_OBJECTS y \
    --set-val CONFIG_DEBUG_OBJECTS_RCU_HEAD y
fi

# Use new .config (properly merges config and allows you to inspect .config)
make olddefconfig
