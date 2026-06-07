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
    'media__1780847064881.png': 'plumbing.png',
    'media__1780847171159.png': 'painting.png',
    'media__1780847262928.png': 'shifting.png',
}

for src_name, dst_name in mapping.items():
    src_path = os.path.join(brain_dir, src_name)
    dst_path = os.path.join(out_dir, dst_name)
    
    if os.path.exists(src_path):
        img = Image.open(src_path).convert('RGBA')
        
        # Create a white background and composite
        bg = Image.new('RGBA', img.size, (255,255,255,255))
        img_composited = Image.alpha_composite(bg, img)
        img_gray = img_composited.convert('L')
        
        w, h = img.size
        
        row_sums = []
        for y in range(h):
            row_sum = sum(img_gray.getpixel((x, y)) for x in range(w))
            avg = row_sum / w
            row_sums.append(avg)
            
        # Scan from bottom up, find the first non-empty block (text),
        # then find the empty gap above it.
        bottom_text_start = h - 1
        while bottom_text_start > 0 and row_sums[bottom_text_start] >= 254.5:
            bottom_text_start -= 1
            
        gap_y = bottom_text_start
        # Find the gap above the text
        while gap_y > 0 and row_sums[gap_y] < 254.5:
            gap_y -= 1
            
        if gap_y < h * 0.5:
            print(f"Warning: gap_y is too high for {src_name}, falling back to 0.75")
            gap_y = int(h * 0.75)
            
        # Crop the text out
        cropped = img_composited.crop((0, 0, w, gap_y))
        
        # Now find the true bounding box of non-white pixels
        # To do this, we can use getbbox on an inverted grayscale image where white=0
        cropped_gray = cropped.convert('L')
        # Invert: white becomes 0, dark becomes > 0
        inverted = Image.eval(cropped_gray, lambda x: 255 - x)
        # Anything > 5 is considered non-white
        bw = Image.eval(inverted, lambda x: 255 if x > 5 else 0)
        
        bbox = bw.getbbox()
        if bbox:
            # Crop the original RGBA image (with transparent bg) using this precise bbox
            final_img = img.crop((0, 0, w, gap_y)).crop(bbox)
            final_img.save(dst_path)
            print(f"Successfully tightly cropped and saved {dst_name}")
        else:
            print(f"Failed to find bbox for {dst_name}")
    else:
        print(f"Error: {src_path} not found")
