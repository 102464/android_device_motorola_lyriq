#!/vendor/bin/sh

PATH=/system/bin:/vendor/bin:/system/xbin
export PATH

trace_dir=/metadata/lyriq_boot_trace
stage_file=${trace_dir}/stage
snapshot_file=${trace_dir}/late_fs_snapshot

sleep 90

[ -r "${stage_file}" ] || exit 0
[ "$(cat "${stage_file}")" = "late-fs-before-mount-all-late" ] || exit 0

umask 077
{
    echo "stage=$(cat "${stage_file}")"
    echo
    echo "=== properties ==="
    getprop
    echo
    echo "=== mounts ==="
    cat /proc/mounts
    echo
    echo "=== bootprof ==="
    cat /proc/bootprof
    echo
    echo "=== processes ==="
    ps -A
    echo
    echo "=== logcat ==="
    logcat -b all -d -t 2000
    echo
    echo "=== dmesg ==="
    dmesg | tail -n 1000
} > "${snapshot_file}" 2>&1

sync