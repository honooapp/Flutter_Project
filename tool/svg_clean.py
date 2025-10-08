#!/usr/bin/env python3
import os, sys, shutil
import xml.etree.ElementTree as ET

KNOWN = {
    "fill", "stroke", "stroke-width", "stroke-linecap", "stroke-linejoin",
    "stroke-miterlimit", "stroke-dasharray", "stroke-dashoffset",
    "opacity", "fill-opacity", "stroke-opacity"
}

def strip_ns(tag):
    return tag.split('}', 1)[-1] if '}' in tag else tag

def parse_style(style_str):
    out = {}
    for decl in style_str.split(';'):
        decl = decl.strip()
        if not decl or ':' not in decl: continue
        k, v = decl.split(':', 1)
        k, v = k.strip(), v.strip()
        out[k] = v
    return out

def process_svg(in_path, out_path):
    # ensure directory
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    # parse
    ET.register_namespace('', "http://www.w3.org/2000/svg")
    tree = ET.parse(in_path)
    root = tree.getroot()

    # remove all <style> elements (any namespace)
    to_remove = []
    for elem in root.iter():
        if strip_ns(elem.tag).lower() == 'style':
            to_remove.append(elem)
    for st in to_remove:
        parent = None
        # find parent (ElementTree doesn’t expose parent; walk)
        for p in root.iter():
            if st in list(p):
                parent = p
                break
        if parent is not None:
            parent.remove(st)

    # inline style="" into attributes
    for elem in root.iter():
        style = elem.attrib.get('style')
        if not style:
            continue
        kv = parse_style(style)
        for k, v in kv.items():
            # prefer explicit attributes already present
            if k in KNOWN and k not in elem.attrib:
                elem.set(k, v)
        # remove original style attr
        elem.attrib.pop('style', None)

    tree.write(out_path, encoding='utf-8', xml_declaration=True)

def main():
    if len(sys.argv) < 3:
        print("Usage: svg_clean.py <input_dir> <output_dir>  (use same dir for in-place)")
        sys.exit(1)
    inp, out = sys.argv[1], sys.argv[2]
    if os.path.abspath(inp) == os.path.abspath(out):
        # in-place: copy to temp then overwrite
        tmp = out.rstrip('/').rstrip('\\') + "_tmp"
        if os.path.exists(tmp): shutil.rmtree(tmp)
        shutil.copytree(inp, tmp)
        for rootdir, _, files in os.walk(tmp):
            for f in files:
                if f.lower().endswith(".svg"):
                    src = os.path.join(rootdir, f)
                    rel = os.path.relpath(src, tmp)
                    dst = os.path.join(out, rel)
                    process_svg(src, dst)
        shutil.rmtree(tmp)
    else:
        if os.path.exists(out): shutil.rmtree(out)
        shutil.copytree(inp, out)
        for rootdir, _, files in os.walk(out):
            for f in files:
                if f.lower().endswith(".svg"):
                    path = os.path.join(rootdir, f)
                    process_svg(path, path)

if __name__ == "__main__":
    main()
