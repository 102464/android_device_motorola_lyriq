#!/usr/bin/env python3
"""One-shot AOSP-convention fixes for stock_types.te:
1. *_prop types: add vendor_property_type (AOSP enforce_sysprop_owner requires
   property types to carry an ownership attribute).
2. fs_type types: drop file_type (AOSP convention: fs labels never carry
   file_type; carrying it pulls them into vendor_init's generic
   file_type:dir create rule and the fs_type+file_type associate neverallow).
"""
import re

F = '/path/to/aosp/lineage/device/motorola/lyriq/sepolicy/vendor/stock_types.te'

out = []
for ln in open(F):
    s = ln.strip()
    m = re.match(r'^type\s+([\w-]+)\s*,\s*(.+);$', s)
    if not m:
        out.append(ln)
        continue
    name, attrs = m.group(1), [a.strip() for a in m.group(2).split(',')]
    orig = list(attrs)
    if 'property_type' in attrs and 'vendor_property_type' not in attrs:
        attrs.append('vendor_property_type')
    if 'fs_type' in attrs and 'file_type' in attrs:
        attrs.remove('file_type')
    if attrs != orig:
        print(f'{name}: {orig} -> {attrs}')
        ln = f"type {name}, {', '.join(attrs)};\n"
    out.append(ln)

open(F, 'w').write(''.join(out))
