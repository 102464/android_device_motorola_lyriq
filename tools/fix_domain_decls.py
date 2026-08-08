#!/usr/bin/env python3
"""Fix domain setup in stock/*.te:
- domains that already have init_daemon_domain()/hal_server_domain() in the
  merged vendor-visible policy (AOSP system/sepolicy/vendor, MTK sepolicy_vndr)
  must not repeat the macro (would duplicate type_transition) -> drop the line.
- all other domains need an explicit `type X, domain;` declaration, which the
  stock CIL extraction did not carry over -> insert before the macro.
"""
import re, glob, os

AOSP = '/path/to/aosp/lineage'
os.chdir(AOSP)
STOCK_DIR = 'device/motorola/lyriq/sepolicy/vendor'

DOMAIN_MACROS = ('init_daemon_domain', 'hal_server_domain', 'init_daemon_service')

scan_dirs = ['device/mediatek/sepolicy_vndr', 'system/sepolicy/public',
             'system/sepolicy/vendor', 'device/lineage/sepolicy']

existing = {}
for d in scan_dirs:
    for f in glob.glob(d + '/**/*.te', recursive=True):
        text = open(f, errors='ignore').read()
        for macro in DOMAIN_MACROS:
            for m in re.finditer(r'^%s\(([\w-]+)' % macro, text, re.M):
                existing.setdefault(m.group(1), []).append(f)

for f in sorted(glob.glob(STOCK_DIR + '/*.te')):
    lines = open(f).read().splitlines(True)
    out, changed = [], False
    for ln in lines:
        m = re.match(r'^(init_daemon_domain|hal_server_domain|init_daemon_service)'
                     r'\(([\w-]+)(,\s*[\w-]+)?\)\s*$', ln.strip())
        if m:
            dom = m.group(2)
            if dom in existing:
                print(f'{f}: drop duplicate macro for {dom} (in {existing[dom][0]})')
                changed = True
                continue
            out.append(f'type {dom}, domain;\n')
            out.append(ln)
            changed = True
            print(f'{f}: add type decl for {dom}')
            continue
        out.append(ln)
    if changed:
        open(f, 'w').write(''.join(out))
