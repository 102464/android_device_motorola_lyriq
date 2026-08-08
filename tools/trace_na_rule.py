#!/usr/bin/env python3
"""Trace neverallow-violating allow rules back to their source file using the
#line directives in the merged neverallows conf."""
import re, sys

CONF = ('/path/to/aosp/lineage/out/soong/.intermediates/system/'
        'sepolicy/sepolicy_neverallows.checkpolicy.conf/android_common/'
        'sepolicy_neverallows.checkpolicy.conf')

lines = open(CONF, errors='ignore').read().splitlines()
cur = '?'
# any allow rule on :dir with write-ish perms, or :filesystem associate,
# or hwservice add, or *_prop:file
pat = re.compile(r'^allow (\S+) (\S+):(dir|filesystem|hwservice_manager|file|socket|qipcrtr_socket) ')
hits = []
for l in lines:
    m = re.match(r'#line \d+ "(.+)"', l)
    if m:
        cur = m.group(1)
        continue
    s = l.strip()
    mm = pat.match(s)
    if not mm:
        continue
    tgt = mm.group(2)
    if ('lyriq' in cur) and ('stock' in cur or 'mobicore' in cur):
        hits.append((cur, s))

# only print rules involving the violating targets
INTEREST = ('vendor_sysfs_battery_supply', 'vendor_sysfs_usb_supply', 'fsg_file',
            'mnt_vendor_trustlet_file', 'mtk_hal_bluetooth_audio_hwservice')
seen = set()
for cur, s in hits:
    if any(t in s for t in INTEREST):
        key = (cur, s)
        if key in seen:
            continue
        seen.add(key)
        print(f'{cur}\n    {s[:160]}')
