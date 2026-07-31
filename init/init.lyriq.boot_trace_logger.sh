#!/vendor/bin/sh

# Temporary persistent boot tracing for normal-boot hangs. Remove after diagnosis.
#
# Continuously persists dmesg + logcat to the physical /metadata partition so
# that a hang without ADB and without pstore can still be diagnosed after
# rebooting into Lineage recovery or the stock system.
#
# Optional flags (create them from recovery/stock before booting the DSU):
#   /metadata/lyriq_boot_trace/adb_keys       - adb public key(s) to authorize
#                                               on the fresh DSU userdata
#   /metadata/lyriq_boot_trace/panic_on_hang  - force a kernel panic after the
#                                               hang timeout to obtain ramoops
#
# Stage markers written by this script (appended to the init.mt6893.rc ones):
#   logger-start / logger-adb-keys-installed / boot-completed / hang-detected /
#   panic-triggered

PATH=/system/bin:/vendor/bin:/system/xbin
export PATH

trace_dir=/metadata/lyriq_boot_trace
stage_file=${trace_dir}/stage
logcat_file=${trace_dir}/logcat.txt
dmesg_file=${trace_dir}/dmesg.txt
hang_snapshot=${trace_dir}/hang_snapshot
hang_timeout=300
interval=10
max_log_bytes=2097152

umask 077
mkdir -p "${trace_dir}" 2>/dev/null

write_stage() {
    echo "$1" > "${stage_file}"
    sync
}

trim_log() {
    # $1: file to keep below max_log_bytes (keeps the tail)
    [ -f "$1" ] || return 0
    size=$(wc -c < "$1" 2>/dev/null)
    [ -n "${size}" ] || return 0
    if [ "${size}" -gt ${max_log_bytes} ]; then
        tail -c $((max_log_bytes / 2)) "$1" > "$1.tmp" 2>/dev/null
        mv "$1.tmp" "$1" 2>/dev/null
    fi
}

write_stage logger-start

# --- ADB recovery helper (optional) ---------------------------------------
# /data here is the fresh per-DSU-install userdata (device-encrypted storage,
# already mounted at post-fs-data). Authorizing a key file works even when
# the boot hangs before any authorization dialog could be confirmed.
if [ -s "${trace_dir}/adb_keys" ]; then
    mkdir -p /data/misc/adb 2>/dev/null
    cat "${trace_dir}/adb_keys" > /data/misc/adb/adb_keys 2>/dev/null
    chmod 0640 /data/misc/adb/adb_keys 2>/dev/null
    chown shell shell /data/misc/adb/adb_keys 2>/dev/null
    restorecon /data/misc/adb /data/misc/adb/adb_keys 2>/dev/null
    # Best effort: only works if nothing set ro.adb.secure earlier.
    setprop ro.adb.secure 0 2>/dev/null
    setprop ctl.restart adbd
    write_stage logger-adb-keys-installed
fi

# --- continuous loggers ----------------------------------------------------
# logd is not up yet at post-fs-data; retry forever in the background.
# Rotation bounds the total logcat size to ~4 MiB so /metadata (which also
# stores the FBE/metadata-encryption keys) can never be filled up.
(
    while true; do
        logcat -b all -v threadtime -r 1024 -n 4 -f "${logcat_file}"
        echo "=== logcat logger restart ===" >> "${logcat_file}"
        sleep 2
    done
) &

(
    echo "=== dmesg logger start ===" >> "${dmesg_file}"
    while true; do
        dmesg -w >> "${dmesg_file}" 2>/dev/null
        echo "=== dmesg logger restart ===" >> "${dmesg_file}"
        sleep 2
    done
) &

# --- hang watchdog ---------------------------------------------------------
elapsed=0
while [ ${elapsed} -lt ${hang_timeout} ]; do
    sleep ${interval}
    elapsed=$((elapsed + interval))
    trim_log "${dmesg_file}"
    sync
    if [ "$(getprop sys.boot_completed)" = "1" ]; then
        write_stage boot-completed
        {
            echo "=== boot completed after ~${elapsed}s ==="
            echo
            echo "=== df /metadata ==="
            df -h /metadata
        } > "${trace_dir}/boot_completed_snapshot" 2>&1
        sync
        exit 0
    fi
done

# Hang detected: dump everything that explains the state, then optionally
# panic so the next boot has console-ramoops/pmsg-ramoops.
write_stage hang-detected
{
    echo "hang after ~${elapsed}s without sys.boot_completed=1"
    echo "stage=$(cat "${stage_file}" 2>/dev/null)"
    echo
    echo "=== properties ==="
    getprop
    echo
    echo "=== mounts ==="
    cat /proc/mounts
    echo
    echo "=== modules ==="
    cat /proc/modules
    echo
    echo "=== processes ==="
    ps -A
    echo
    echo "=== bootprof ==="
    cat /proc/bootprof
    echo
    echo "=== service list (10s timeout) ==="
    timeout 10 service list
    echo
    echo "=== dumpsys SurfaceFlinger (10s timeout) ==="
    timeout 10 dumpsys SurfaceFlinger
    echo
    echo "=== df ==="
    df -h
    echo
    echo "=== logcat tail ==="
    logcat -b all -d -v threadtime -t 3000
    echo
    echo "=== dmesg tail ==="
    dmesg | tail -n 2000
} > "${hang_snapshot}" 2>&1
sync

if [ -e "${trace_dir}/panic_on_hang" ]; then
    write_stage panic-triggered
    sync
    echo 1 > /proc/sys/kernel/sysrq
    echo c > /proc/sysrq-trigger
fi

# Keep the background loggers alive and flush periodically. The service is
# oneshot; sleeping forever prevents init from considering it exited.
while true; do
    sleep 60
    trim_log "${dmesg_file}"
    sync
done
