import xml.etree.ElementTree as ET
import os

file_path = 'app/assets/body_model/source/muscle_data_all.svg'
output_path = 'app/svg_structure.txt'

def inspect_svg(path, out_file):
    if not os.path.exists(path):
        with open(out_file, 'w') as f:
            f.write(f"File not found: {path}\n")
        return

    try:
        context = ET.iterparse(path, events=('start',))
        
        with open(out_file, 'w') as f:
            f.write(f"Analyzing {path}\n")
            
            depth = 0
            for event, elem in context:
                tag = elem.tag.split('}')[-1]
                id_attr = elem.attrib.get('id', '')
                label_attr = elem.attrib.get('{http://www.inkscape.org/namespaces/inkscape}label', '')
                
                # Only interested in Groups (g) or top level
                if tag == 'g' or tag == 'svg':
                    indent = "  " * depth
                    info = f"{indent}Tag: {tag}"
                    if id_attr:
                        info += f", ID: {id_attr}"
                    if label_attr:
                        info += f", Label: {label_attr}"
                    f.write(info + "\n")
                    depth += 1
                
                # Assume if we hit a path we are deep enough, don't go deeper?
                # Actually iterparse is linear. We can't easily track depth this way for nested closing.
                # Let's switch back to parse for structure if memory allows.
                
    except Exception as e:
        with open(out_file, 'w') as f:
            f.write(f"Error parsing SVG: {e}\n")

# Re-writer using parse for true hierarchy
def inspect_svg_tree(path, out_file):
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        
        with open(out_file, 'w') as f:
            def recurse(node, level):
                tag = node.tag.split('}')[-1]
                id_attr = node.attrib.get('id', '')
                label_attr = node.attrib.get('{http://www.inkscape.org/namespaces/inkscape}label', '')
                
                if tag == 'g' or level == 0:
                    indent = "  " * level
                    info = f"{indent}{tag} id='{id_attr}' label='{label_attr}' children={len(node)}"
                    f.write(info + "\n")
                    for child in node:
                        recurse(child, level + 1)
            
            recurse(root, 0)

    except Exception as e:
        with open(out_file, 'w') as f:
            f.write(f"Error: {e}")

inspect_svg_tree(file_path, output_path)
