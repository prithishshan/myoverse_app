import xml.etree.ElementTree as ET
import re
import os

SOURCE_FILE = 'app/assets/body_model/source/muscle_data_all.svg'
OUTPUT_BASE = 'app/assets/body_model'

MAPPING = {
    'man_1': ('male', 'front_muscles.svg'),
    'man_2': ('male', 'back_muscles.svg'),
    'woman_1': ('female', 'front_muscles.svg'),
    'woman_2': ('female', 'back_muscles.svg'),
}

def get_bounding_box(group_element):
    min_x, min_y = float('inf'), float('inf')
    max_x, max_y = float('-inf'), float('-inf')
    
    # Simple regex to find numbers in path data
    # This captures coordinates in 'd' attributes
    number_pattern = re.compile(r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?")
    
    paths_found = False
    
    # Recursively find all path elements
    for path in group_element.iter():
        if 'd' in path.attrib:
            d = path.attrib['d']
            coords = [float(n) for n in number_pattern.findall(d)]
            
            # SVG path data is x, y pairs mostly, but control points exist. 
            # It's a rough approximation but usually works for finding the layout extent
            # seeing as we just need a viewbox that includes everything.
            if coords:
                paths_found = True
                # Iterate pairs (not strictly accurate for raw stream of numbers but suffices for min/max sweep)
                # Actually, simpler: just min/max of ALL numbers found (x and y usually mixed range, but separating them is safer)
                # But 'd' commands are complex (M x y L x y...).
                # Heuristic: Scan all numbers. Min/Max of them is loose bbox.
                # BETTER: try to distinguish X and Y? Hard without parsing commands.
                # Strategy: Just take min/max of ALL numbers. 
                # Why? because x and y share the same coordinate space usually? No, aspect ratio matters.
                # However, for a tight crop, we really need distinct X and Y.
                # Let's try a slightly smarter parser that tracks simple commands?
                # No, that's too complex for a scratch script.
                # Alternative: Use the original ViewBox? But they might be side-by-side.
                # Let's try to assume pairs. logic: M x y ...
                # Most numbers come in pairs.
                
                # Check odd/even indices?
                xs = coords[0::2]
                ys = coords[1::2]
                
                if xs:
                    min_x = min(min_x, min(xs))
                    max_x = max(max_x, max(xs))
                if ys:
                    min_y = min(min_y, min(ys))
                    max_y = max(max_y, max(ys))

    if not paths_found:
        return None

    return (min_x, min_y, max_x, max_y)

def process_svg():
    if not os.path.exists(SOURCE_FILE):
        print("Source file not found")
        return

    tree = ET.parse(SOURCE_FILE)
    root = tree.getroot()
    
    # Register namespaces to avoid ns0: prefixes if possible, or just strip them handling
    ET.register_namespace('', "http://www.w3.org/2000/svg")
    
    # We need to find the groups
    # Namespace handling is annoying in ET, let's iterate and check IDs
    
    def strip_ns(tag):
        return tag.split('}')[-1]

    groups = {}
    for child in root.iter():
        if strip_ns(child.tag) == 'g':
            gid = child.attrib.get('id')
            if gid in MAPPING:
                groups[gid] = child
    
    print(f"Found groups: {list(groups.keys())}")
    
    for gid, element in groups.items():
        folder, filename = MAPPING[gid]
        full_dir = os.path.join(OUTPUT_BASE, folder)
        os.makedirs(full_dir, exist_ok=True)
        target_path = os.path.join(full_dir, filename)
        
        print(f"Processing {gid} -> {target_path}")
        
        # Calculate BBox
        bbox = get_bounding_box(element)
        if not bbox:
            print(f"  Warning: No paths found for {gid}, extraction might be empty.")
            view_box_str = root.attrib.get('viewBox', '0 0 100 100') # Fallback
        else:
            min_x, min_y, max_x, max_y = bbox
            # Add some padding
            padding = 10
            min_x -= padding
            min_y -= padding
            width = (max_x - min_x) + (padding * 2)
            height = (max_y - min_y) + (padding * 2)
            view_box_str = f"{min_x:.2f} {min_y:.2f} {width:.2f} {height:.2f}"
            print(f"  Calculated ViewBox: {view_box_str}")

        # Create new SVG root
        new_root = ET.Element('svg', dict(
            xmlns="http://www.w3.org/2000/svg",
            version="1.1",
            viewBox=view_box_str
        ))
        
        # Append the group
        # Note: We append the specific element instance
        # However, checking if it has definitions or styles referenced elsewhere?
        # Assuming self-contained for now.
        new_root.append(element)
        
        # Write
        new_tree = ET.ElementTree(new_root)
        new_tree.write(target_path, encoding='utf-8', xml_declaration=True)
        print("  Saved.")

if __name__ == "__main__":
    process_svg()
