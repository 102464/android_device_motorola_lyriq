#!/usr/bin/env python3
"""List all conf rules `allow init|vendor_init <attr>:dir` with write-ish perms,
with source file via #line."""
import re

CONF = ('/path/to/aosp/lineage/out/soong/.intermediates/system/'
        'sepolicy/sepolicy_neverallows.checkpolicy.conf/android_common/'
        'sepolicy_neverallows.checkpolicy.conf')

# attributes of the violating types
ATTRS = {'file_type', 'fs_type', 'sysfs_type', 'sysfs', 'vendor_file_type'}

cur = '?'
for l in open(CONF, errors='ignore'):
    m = re.match(r'#line \d+ "(.+)"', l)
    if m:
        cur = m.group(1)
        continue
    s = l.strip()
    mm = re.match(r'^allow (init|vendor_init) (\S+):dir \{([^}]*)\}', s)
    if not mm:
        continue
    tgt, perms = mm.group(2), mm.group(3)
    if tgt in ATTRS and any(p in perms.split() for p in
                            ('write', 'create', 'add_name', 'remove_name', 'rmdir')):
        print(f'{s[:130]}\n    <- {cur}')
