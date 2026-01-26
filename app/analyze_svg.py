import re

files = [
    r"c:\Users\Prith\myo_app\app\assets\body_model\male\outline_male_front.svg",
    r"c:\Users\Prith\myo_app\app\assets\body_model\male\outline_male_back.svg"
]

for file_path in files:
    print(f"Analyzing {file_path}...")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find all rects with display="none"
        # We look for <rect ... display="none" ...> or just count occurrences
        # A simple regex for the tag
        hidden_rects = re.findall(r'<rect[^>]*display="none"[^>]*>', content)
        print(f"  Found {len(hidden_rects)} hidden rects.")
        
        for i, rect in enumerate(hidden_rects[:5]):
            print(f"    Sample {i}: {rect}")
            
        # Check for width variations
        widths = re.findall(r'width="([^"]+)"', "".join(hidden_rects))
        from collections import Counter
        print(f"    Width distribution: {Counter(widths)}")

    except Exception as e:
        print(f"  Error: {e}")
