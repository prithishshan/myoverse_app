import xml.etree.ElementTree as ET
import os

file_path = 'app/assets/body_model/source/muscle_data_all.svg'

def inspect_svg(path):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return

    try:
        tree = ET.parse(path)
        root = tree.getroot()
        ns = {'svg': 'http://www.w3.org/2000/svg'}
        
        print(f"Root tag: {root.tag}")
        print("Iterating immediate children of root:")
        
        # Strip namespace for easier reading if present
        def strip_ns(tag):
            return tag.split('}')[-1] if '}' in tag else tag

        for child in root:
            tag = strip_ns(child.tag)
            id_attr = child.attrib.get('id', '<no_id>')
            label_attr = child.attrib.get('{http://www.inkscape.org/namespaces/inkscape}label', '<no_label>')
            print(f"Tag: {tag}, ID: {id_attr}, Label: {label_attr}")
            
            if tag == 'g':
                print(f"  Children of {id_attr}:")
                for sub in child:
                    sub_tag = strip_ns(sub.tag)
                    sub_id = sub.attrib.get('id', '<no_id>')
                    print(f"    Tag: {sub_tag}, ID: {sub_id}")

    except Exception as e:
        print(f"Error parsing SVG: {e}")

inspect_svg(file_path)
