#!/usr/bin/env python3
"""Find types referenced by stock/*.te rules but never declared, and
append declarations to stock_types.te using attributes recovered from
the stock vendor CIL (falls back to name-based heuristics)."""
import re, glob, os, sys

AOSP = '/path/to/aosp/lineage'
os.chdir(AOSP)
STOCK_DIR = 'device/motorola/lyriq/sepolicy/vendor'
TYPES_TE = STOCK_DIR + '/stock_types.te'
CIL_CANDIDATES = [
    '/path/to/aosp/orig-rom/mnt/vendor/etc/selinux/vendor_sepolicy.cil',
    '/path/to/aosp/orig-rom/mnt/vendor/etc/selinux/precompiled_sepolicy',
]

TYPE_RE = r'^type\s+([\w-]+)[\s,;]'
TOKEN_RE = re.compile(r'\b([a-z][\w-]*)\b')

# attributes that are not types
NON_TYPES = {
    'allow', 'allowxperm', 'auditallow', 'dontaudit', 'neverallow', 'type',
    'typeattribute', 'typeattributeset', 'typetransition', 'type_change',
    'type_member', 'role', 'user', 'attribute', 'common', 'class', 'sid',
    'ioctl', 'range_transition', 'mlstrustedsubject', 'mlstrustedobject',
}

# macros that declare their argument as a type (domain/file/hwService)
DECL_MACROS = {
    'init_daemon_domain', 'init_daemon_service', 'hal_server_domain',
    'hal_client_domain', 'vendor_domain', 'domain', 'typeattribute',
    'add_hwservice', 'add_service', 'vndbinder_use', 'binder_use',
    # property-declaring macros (te_macros)
    'system_public_config_prop', 'system_internal_prop',
    'system_restricted_prop', 'vendor_public_prop', 'vendor_internal_prop',
    'vendor_restricted_prop', 'system_ext_public_config_prop',
    'system_ext_internal_prop', 'system_ext_restricted_prop',
    'product_public_config_prop', 'product_internal_prop',
    'product_restricted_prop', 'odm_public_prop', 'odm_internal_prop',
}

def collect_declared():
    declared = set()
    dirs = [
        'device/mediatek/sepolicy_vndr/basic/non_plat',
        'device/mediatek/sepolicy_vndr/bsp/non_plat',
        'device/mediatek/sepolicy_vndr/modem',
        'device/mediatek/sepolicy_vndr/bsp/debug/non_plat',
        'device/mediatek/sepolicy_vndr/basic/debug/non_plat',
        'device/lineage/sepolicy/libperfmgr',
        'system/sepolicy/public', 'system/sepolicy/vendor',
        'device/mediatek/sepolicy_vndr/basic/plat_public',
        'device/mediatek/sepolicy_vndr/bsp/plat_public',
        'device/mediatek/sepolicy_vndr/basic/debug/plat_public',
        'device/mediatek/sepolicy_vndr/bsp/debug/plat_public',
    ]
    dirs += glob.glob('device/lineage/sepolicy/common/vendor*')
    files = glob.glob(STOCK_DIR + '/*.te')
    files += glob.glob('device/motorola/lyriq/sepolicy/vendor/*.te')
    for d in dirs:
        if os.path.isdir(d):
            files += glob.glob(d + '/**/*.te', recursive=True)
    # prebuilt system_ext/product public policy (plain conf, types may be indented)
    files += glob.glob('system/sepolicy/prebuilts/api/*/*_general_sepolicy.conf')
    for f in files:
        text = open(f, errors='ignore').read()
        for m in re.finditer(r'^\s*type\s+([\w-]+)[\s,;]', text, re.M):
            declared.add(m.group(1))
        # macro-declared domains, e.g. init_daemon_domain(foo)
        for m in re.finditer(r'^(\w+)\(([\w-]+)\)', text, re.M):
            if m.group(1) in DECL_MACROS:
                declared.add(m.group(2))
    # AOSP attributes are not types; never re-declare them
    for f in ['system/sepolicy/public/attributes',
              'system/sepolicy/private/attributes']:
        if os.path.isfile(f):
            for m in re.finditer(r'^attribute\s+([\w-]+)\s*;',
                                 open(f).read(), re.M):
                declared.add(m.group(1))
    for f in glob.glob('system/sepolicy/prebuilts/api/*/*_general_sepolicy.conf'):
        for m in re.finditer(r'^\s*attribute\s+([\w-]+)\s*;',
                             open(f, errors='ignore').read(), re.M):
            declared.add(m.group(1))
    return declared

def collect_referenced():
    """Type names used in allow/typetransition rules across stock/*.te."""
    ref = set()
    for f in glob.glob(STOCK_DIR + '/*.te'):
        if f.endswith('stock_types.te'):
            continue
        for line in open(f, errors='ignore'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            m = re.match(r'^(allow|typetransition|type_change|type_member)\s+'
                         r'([\w-]+)\s+([\w-]+)', line)
            if m:
                ref.add(m.group(2))
                ref.add(m.group(3))
    return ref

def stock_cil_attrs():
    """type -> attrs from stock CIL, for types declared there."""
    attrs = {}
    for cil in CIL_CANDIDATES:
        if not os.path.isfile(cil):
            continue
        text = open(cil, errors='ignore').read()
        tattrs = {}
        for m in re.finditer(r'\(typeattributeset\s+(\w+)\s+\(([^)]*)\)\)', text):
            for t in m.group(2).split():
                tattrs.setdefault(t, set()).add(m.group(1))
        for m in re.finditer(r'\(type\s+([\w-]+)\)', text):
            t = m.group(1)
            attrs[t] = tattrs.get(t, set())
        if attrs:
            break
    return attrs

def guess_attrs(t):
    if t.endswith('_exec'):
        return ['exec_type', 'file_type', 'vendor_file_type']
    if t.endswith('_block_device') or t.endswith('_device'):
        return ['dev_type']
    if t.endswith('_prop'):
        return ['property_type']
    if t.endswith('_service'):
        return ['service_manager_type']
    if t.endswith('_socket'):
        return ['file_type']
    if 'sysfs' in t:
        return ['fs_type', 'sysfs_type']
    if t.endswith('_data_file'):
        return ['data_file_type', 'file_type']
    return ['file_type', 'vendor_file_type']

def main():
    declared = collect_declared()
    ref = collect_referenced()
    missing = sorted(t for t in ref - declared
                     if t not in NON_TYPES and not t.startswith('self'))
    cil_attrs = stock_cil_attrs()
    # only keep attrs that are public/known
    known_attrs = {'dev_type', 'fs_type', 'file_type', 'exec_type',
                   'data_file_type', 'system_file_type', 'vendor_file_type',
                   'service_manager_type', 'mlstrustedobject', 'property_type',
                   'sysfs_type', 'hwservice_manager_type', 'vndservice_manager_type',
                   'socket_type'}
    lines = []
    for t in missing:
        attrs = sorted(a for a in cil_attrs.get(t, set()) if a in known_attrs
                       and a != 'socket_type')
        if not attrs:
            attrs = guess_attrs(t)
        lines.append(f"type {t}, {', '.join(attrs)};")
        print(f"+ {t}: {', '.join(attrs)}")
    if lines and '--dry-run' not in sys.argv:
        with open(TYPES_TE, 'a') as fh:
            fh.write('\n# auto-added missing type declarations\n')
            fh.write('\n'.join(lines) + '\n')
    print(f"{len(lines)} types added")

if __name__ == '__main__':
    main()
