#!/usr/bin/env python3
"""Convert Moto CarrierConfig region XMLs (binary, inside stock APK) into a
single AOSP-style vendor.xml for LyriqCarrierConfigOverlay.

Usage: convert_carrierconfig.py <stock CarrierConfig.apk> <aapt2> <out vendor.xml>
"""
import re
import subprocess
import sys
import xml.sax.saxutils as saxutils

REGIONS = ['general', 'africa', 'asia', 'europe', 'latin_america', 'oceania']

# AOSP DefaultCarrierConfigService.checkFilters() drops an entry on any
# unknown attribute, so keep only the recognized filter attributes.
FILTER_ATTRS = {
    'mcc', 'mnc', 'gid1', 'gid2', 'spn', 'imsi', 'device', 'vendorSku',
    'hardwareSku', 'board', 'cid', 'name', 'sku',
}

E_RE = re.compile(r'^(\s*)E: (\S+)')
A_RE = re.compile(r'^\s*A: ([^=]+)=.*? \(Raw: "(.*)"\)\s*$')
T_RE = re.compile(r"^\s*T: '(.*)'\s*$")

SCALARS = {'boolean', 'int', 'long', 'double', 'string'}
CONTAINERS = {'int-array', 'string-array', 'boolean-array', 'long-array',
              'pbundle_as_map'}


def esc(s):
    return saxutils.escape(s, {'"': '&quot;'})


class Node:
    __slots__ = ('tag', 'indent', 'attrs', 'value')

    def __init__(self, tag, indent):
        self.tag = tag
        self.indent = indent
        self.attrs = {}
        self.value = None

    def opening(self):
        if self.tag in SCALARS:
            name = esc(self.attrs.get('name', ''))
            v = esc(self.value if self.value is not None
                    else self.attrs.get('value', ''))
            return f'<{self.tag} name="{name}" value="{v}" />'
        if self.tag == 'item':
            v = esc(self.attrs.get('value', ''))
            return f'<item value="{v}" />'
        # containers: keep name and num (num is required by XmlUtils array
        # parsing)
        parts = []
        if self.attrs.get('name') is not None:
            parts.append(f'name="{esc(self.attrs["name"])}"')
        if self.attrs.get('num') is not None:
            parts.append(f'num="{esc(self.attrs["num"])}"')
        attr_str = (' ' + ' '.join(parts)) if parts else ''
        return f'<{self.tag}{attr_str}>'


def convert_region(text):
    """Return list of (entry_attrs, body_lines) for each carrier_config."""
    entries = []
    lines = []
    stack = []      # open container Nodes
    pending = None  # Node awaiting A:/T: data
    entry_attrs = None
    in_entry = False

    def flush_pending():
        nonlocal pending
        if pending is None:
            return
        if pending.tag == 'carrier_config':
            entry_attrs.update(
                {k: v for k, v in pending.attrs.items()
                 if k in FILTER_ATTRS})
        else:
            lines.append(' ' * pending.indent + pending.opening())
            if pending.tag in CONTAINERS:
                stack.append(pending)
        pending = None

    for line in text.splitlines():
        em = E_RE.match(line)
        if em:
            indent = len(em.group(1))
            tag = em.group(2)
            if tag == 'carrier_config_list':
                continue
            if tag == 'carrier_config':
                flush_pending()
                while stack:
                    n = stack.pop()
                    lines.append(' ' * n.indent + f'</{n.tag}>')
                if in_entry:
                    entries.append((entry_attrs, lines))
                lines = []
                entry_attrs = {}
                in_entry = True
                pending = Node(tag, indent)
                continue
            if not in_entry:
                continue
            flush_pending()
            while stack and stack[-1].indent >= indent:
                n = stack.pop()
                lines.append(' ' * n.indent + f'</{n.tag}>')
            pending = Node(tag, indent)
            continue
        am = A_RE.match(line)
        if am and pending is not None:
            pending.attrs[am.group(1)] = am.group(2)
            continue
        tm = T_RE.match(line)
        if tm and pending is not None:
            pending.value = tm.group(1)

    flush_pending()
    while stack:
        n = stack.pop()
        lines.append(' ' * n.indent + f'</{n.tag}>')
    if in_entry:
        entries.append((entry_attrs, lines))
    return entries


def main():
    apk, aapt2, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
    out = ['<?xml version="1.0" encoding="utf-8"?>',
           '<!-- CarrierConfig entries converted from the stock Moto',
           '     CarrierConfig.apk vendor_*.xml region files. The first',
           '     entry holds lyriq global defaults; entries accumulate in',
           '     document order (later entries win per key). -->',
           '<carrier_config_list>',
           '    <carrier_config>',
           '        <int-array name="carrier_nr_availabilities_int_array"'
           ' num="2">',
           '            <item value="1" />',
           '            <item value="2" />',
           '        </int-array>',
           '        <int name="preferred_network_mode_int" value="24" />',
           '        <boolean name="enhanced_4g_lte_on_by_default_bool"'
           ' value="true" />',
           '    </carrier_config>']

    total = 0
    for region in REGIONS:
        text = subprocess.run(
            [aapt2, 'dump', 'xmltree', '--file',
             f'res/xml/vendor_{region}.xml', apk],
            capture_output=True, text=True, check=True).stdout
        for attrs, body in convert_region(text):
            attr_str = ''.join(f' {k}="{esc(v)}"' for k, v in attrs.items())
            out.append(f'    <carrier_config{attr_str}>')
            out.extend(body)
            out.append('    </carrier_config>')
            total += 1

    out.append('</carrier_config_list>')
    with open(out_path, 'w') as f:
        f.write('\n'.join(out) + '\n')
    print(f'wrote {total} carrier_config entries to {out_path}')


if __name__ == '__main__':
    main()
