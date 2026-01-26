import re
import os

def clean_svg():
    # Define files to process
    files = {
        r"c:\Users\Prith\myo_app\app\assets\body_model\male\outline_male_front.svg": "front",
        r"c:\Users\Prith\myo_app\app\assets\body_model\male\outline_male_back.svg": "back"
    }

    large_width = "3542.31" # The background canvas to keep hidden

    for file_path, ftype in files.items():
        if not os.path.exists(file_path):
            print(f"File not found: {file_path}")
            continue

        print(f"Processing {file_path}...")
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 1. Unhide small rects (specifically for front.svg where we found them)
        # We look for rects with display="none" BUT NOT width="3542.31"
        # Strategy: Iterate specifically.
        # But regex replacement is easier if we can distinguish.
        # The small rects have width="41.62"
        # We can replace 'width="41.62" ... display="none"' -> 'width="41.62" ... fill="#fff"'
        # However, attributes order varies.
        # Let's count how many we fixed.
        
        def unhide_small_rect(match):
            tag = match.group(0)
            if large_width in tag:
                return tag # Keep big one hidden
            if 'display="none"' in tag:
                # Remove display="none" and ensure fill="#fff"
                new_tag = tag.replace('display="none"', '')
                if 'fill=' not in new_tag:
                    new_tag = new_tag.replace('<rect', '<rect fill="#fff"')
                elif 'fill="#ededed"' in new_tag:
                     new_tag = new_tag.replace('fill="#ededed"', 'fill="#fff"')
                # If it had display="none", it might have had old fill or no fill.
                # In my previous step I replaced fill="#ededed" with display="none".
                # So it might be <rect display="none" x=... >
                # We want <rect fill="#fff" x=... >
                return new_tag
            return tag

        # Apply unhide only if we suspect hidden rects (front)
        if ftype == "front":
            content = re.sub(r'<rect[^>]*>', unhide_small_rect, content)

        # 2. Add stroke to ALL rects to close seams
        # This helps with the grid effect even if solid
        # We add stroke="#fff" stroke-width="1"
        def add_stroke(match):
            tag = match.group(0)
            if 'display="none"' in tag:
                return tag # Don't stroke hidden/background
            if 'stroke=' in tag:
                return tag # Already has stroke
            # Add stroke
            return tag.replace('<rect', '<rect stroke="#fff" stroke-width="1"')

        content = re.sub(r'<rect[^>]*>', add_stroke, content)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"cleaned and optimized {file_path}")

if __name__ == "__main__":
    clean_svg()
