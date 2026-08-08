#!/usr/bin/env python3
"""Dedup stock contexts (file_contexts, property_contexts, service_contexts,
hwservice_contexts, vndservice_contexts) against the already-active MTK/Lineage
contexts that ship in the same partition files.

Rules:
- identical spec+label duplicate  -> drop from stock file (keep existing)
- same spec, different label      -> keep BOTH but report (manual decision)
"""
import re, glob, os, sys

AOSP = '/path/to/aosp/lineage'
os.chdir(AOSP)
STOCK = 'device/motorola/lyriq/sepolicy/vendor'

EXISTING_DIRS = [
    'device/mediatek/sepolicy_vndr',
    'device/lineage/sepolicy',
    'device/lineage/sepolicy/libperfmgr',
    # AOSP vendor-partition policy merges into the same files
    'system/sepolicy/vendor',
    'system/sepolicy/public',
]
CTX_FILES = ['file_contexts', 'property_contexts', 'service_contexts',
             'hwservice_contexts', 'vndservice_contexts']

def load(path):
    """spec -> (label, srcline)"""
    out = {}
    if not os.path.isfile(path):
        return out
    for ln in open(path, errors='ignore'):
        ln = ln.strip()
        if not ln or ln.startswith('#'):
            continue
        m = re.match(r'^(\S+)\s+u:object_r:([\w-]+):s0', ln)
        if m:
            out.setdefault(m.group(1), (m.group(2), path))
    return out

def main():
    apply = '--apply' in sys.argv
    for ctx in CTX_FILES:
        stock_path = f'{STOCK}/{ctx}'
        if not os.path.isfile(stock_path):
            continue
        existing = {}
        for d in EXISTING_DIRS:
            for f in glob.glob(f'{d}/**/{ctx}', recursive=True):
                for spec, v in load(f).items():
                    existing.setdefault(spec, v)
        stock_entries = load(stock_path)
        drop, conflict = [], []
        for spec, (label, _) in stock_entries.items():
            if spec in existing:
                elabel, efile = existing[spec]
                if elabel == label:
                    drop.append(spec)
                else:
                    conflict.append((spec, label, elabel, efile))
        print(f'== {ctx}: {len(drop)} identical dups, {len(conflict)} label conflicts')
        for spec, label, elabel, efile in conflict:
            print(f'  CONFLICT {spec}: stock={label} existing={elabel} ({efile})')
        if drop and apply:
            lines = open(stock_path).read().splitlines(True)
            out = []
            for ln in lines:
                m = re.match(r'^(\S+)\s+u:object_r:([\w-]+):s0', ln.strip())
                if m and m.group(1) in drop:
                    continue
                out.append(ln)
            open(stock_path, 'w').write(''.join(out))
            print(f'  dropped {len(drop)} identical dups from {stock_path}')

if __name__ == '__main__':
    main()
