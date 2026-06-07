import os
from PIL import Image

brain_dir = r'C:\Users\vaibh\.gemini\antigravity-ide\brain\7917e6ff-066f-42c5-8557-05d06f9d2754'
out_dir = r'C:\Users\vaibh\Desktop\kk-infotech\Protasker\assets\icons\category'

mapping = {
    'media__1780846752713.png': 'appliance.png',
    'media__1780846752740.png': 'carpentry.png',
    'media__1780846752819.png': 'electrical.png',
    'media__1780846752824.png': 'cleaning.png',
    'media__1780846752852.png': 'other.png',
}

for src_name, dst_name in mapping.items():
    src_path = os.path.join(brain_dir, src_name)
    dst_path = os.path.join(out_dir, dst_name)
    
    if os.path.exists(src_path):
        img = Image.open(src_path).convert('RGBA')
        
        # Create a white background and composite
        bg = Image.new('RGBA', img.size, (255,255,255,255))
        img = Image.alpha_composite(bg, img).convert('L') # Convert to grayscale for easy analysis
        
        w, h = img.size
        
        row_sums = []
        for y in range(h):
            row_sum = sum(img.getpixel((x, y)) for x in range(w))
            # Average brightness of row. If it's < 250, it has non-white pixels
            avg = row_sum / w
            row_sums.append(avg)
            
        # We need to find the text at the bottom.
        # Scan from bottom up, find the first non-empty block (text),
        # then find the empty gap above it.
        bottom_text_start = h - 1
        while bottom_text_start > 0 and row_sums[bottom_text_start] >= 254.5: # 255 is pure white
            bottom_text_start -= 1
            
        gap_y = bottom_text_start
        # Find the gap above the text (where avg brightness is almost 255 again)
        while gap_y > 0 and row_sums[gap_y] < 254.5:
            gap_y -= 1
            
        if gap_y < h * 0.5:
            print(f"Warning: gap_y is too high for {src_name}, falling back to 0.75")
            gap_y = int(h * 0.75)
            
        # Re-open original image to crop
        img_color = Image.open(src_path).convert('RGBA')
        cropped = img_color.crop((0, 0, w, gap_y))
        
        # Now find true bounding box of the top part (the icon) to remove side margins
        bbox = cropped.getbbox()
        if bbox:
            cropped = cropped.crop(bbox)
            
        cropped.save(dst_path)
        print(f"Successfully processed and saved {dst_name}")
