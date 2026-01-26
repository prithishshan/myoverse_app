
import re

file_path = r"c:\Users\Prith\myo_app\app\lib\widgets\some_muscles.dart"

with open(file_path, 'r') as f:
    content = f.read()

# Pattern to find size.width * NUMBER and size.height * NUMBER
# Also handles size.width / NUMBER (which is * 1/NUMBER)
# And just size.width ( * 1.0)

width_factors = []
height_factors = []

# Regex for multiplication: size\.(width|height)\s*\*\s*([\d\.]+)(?![\d\.])
# Regex for division: size\.(width|height)\s*\/\s*([\d\.]+)(?![\d\.])
# Regex for plain: size\.(width|height)(?!\s*[\*\/])

matches_mult = re.findall(r"size\.(width|height)\s*\*\s*([\d\.]+)", content)
matches_div = re.findall(r"size\.(width|height)\s*\/\s*([\d\.]+)", content)
# matches_plain = re.findall(r"size\.(width|height)(?!\s*[\*\/])", content) # Ignoring plain for now as usually modifiers are used in this file

for type_, val in matches_mult:
    if type_ == 'width':
        width_factors.append(float(val))
    else:
        height_factors.append(float(val))

for type_, val in matches_div:
    if type_ == 'width':
        width_factors.append(1.0 / float(val))
    else:
        height_factors.append(1.0 / float(val))

if width_factors:
    print(f"Width factors: Min {min(width_factors)}, Max {max(width_factors)}")
else:
    print("No width factors found")

if height_factors:
    print(f"Height factors: Min {min(height_factors)}, Max {max(height_factors)}")
else:
    print("No height factors found")
