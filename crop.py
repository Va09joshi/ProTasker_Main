from PIL import Image
import os

img_path = r'C:\Users\vaibh\.gemini\antigravity-ide\brain\7917e6ff-066f-42c5-8557-05d06f9d2754\media__1780845078350.png'
out_dir = r'C:\Users\vaibh\Desktop\kk-infotech\Protasker\assets\icons\category'

img = Image.open(img_path)
bg = Image.new('RGBA', img.size, (255,255,255,255))
img = Image.alpha_composite(bg, img).convert('RGB')

mapping = {
    (0, 0): 'plumbing.png',
    (0, 1): 'electrical.png',
    (0, 2): 'painting.png',
    (0, 3): 'carpentry.png',
    (1, 0): 'appliance.png',
    (1, 1): 'cleaning.png',
    (1, 2): 'shifting.png',
    (2, 0): 'other.png',
}

# Values found from bounding box analysis
x0, y0 = 102, 70
cell_w = 860 / 4
cell_h = 510 / 3

for (row, col), filename in mapping.items():
    left = x0 + col * cell_w
    top = y0 + row * cell_h
    right = left + cell_w
    bottom = top + cell_h
    
    # Crop to just the icon part (cutting out the text label at the bottom)
    # The cell is 215x170. The text is usually in the bottom 40px.
    crop_box = (int(left), int(top), int(right), int(bottom - 35))
    cropped = img.crop(crop_box)
    cropped.save(os.path.join(out_dir, filename))

print("Cropped using precise bounding box.")
