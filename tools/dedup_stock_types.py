#!/usr/bin/env python3
"""Remove type declarations from stock_types.te that already exist in
the active vendor sepolicy dirs (MTK + Lineage common), to avoid
'Duplicate declaration of type' checkpolicy errors."""
import re, glob, os, sys

AOSP = '/path/to/aosp/lineage'
os.chdir(AOSP)

dirs = [
    'device/mediatek/sepolicy_vndr/basic/non_plat',
    'device/mediatek/sepolicy_vndr/bsp/non_plat',
    'device/mediatek/sepolicy_vndr/modem',
    'device/mediatek/sepolicy_vndr/bsp/debug/non_plat',
    'device/mediatek/sepolicy_vndr/basic/debug/non_plat',
    'device/lineage/sepolicy/libperfmgr',
]
dirs += glob.glob('device/lineage/sepolicy/common/vendor*')
# vendor conf merges system public policy too
dirs += ['system/sepolicy/public', 'system/sepolicy/vendor',
         'system/sepolicy/prebuilts/api/202404/public']
dirs += ['device/mediatek/sepolicy_vndr/basic/plat_public',
         'device/mediatek/sepolicy_vndr/bsp/plat_public',
           'device/mediatek/sepolicy_vndr/basic/debug/plat_public',
         'device/mediatek/sepolicy_vndr/bsp/debug/plat_public',
         'device/mediatek/sepolicy_vndr/bsp/debug/plat_private']

TYPE_RE = r'^type\s+([\w-]+)[\s,;]'

existing = {}
for d in dirs:
    if not os.path.isdir(d):
        continue
    for f in glob.glob(d + '/**/*.te', recursive=True):
        for m in re.finditer(TYPE_RE,
                             open(f, errors='ignore').read(), re.M):
            existing.setdefault(m.group(1), f)

stock = 'device/motorola/lyriq/sepolicy/vendor/stock_types.te'
lines = open(stock).read().splitlines(True)
out, removed = [], []
for ln in lines:
    m = re.match(TYPE_RE, ln)
    if m and m.group(1) in existing:
        removed.append((m.group(1), existing[m.group(1)]))
        continue
    out.append(ln)

if '--dry-run' not in sys.argv:
    open(stock, 'w').write(''.join(out))
print(f"removed {len(removed)} duplicate type decls:")
for t, f in removed:
    print(' ', t, '<-', f)
