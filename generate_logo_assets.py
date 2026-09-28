import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

def draw_gold_star(draw, cx, cy, r_outer, r_inner, rot_deg=0):
    pts = []
    for i in range(10):
        r = r_outer if i % 2 == 0 else r_inner
        ang = math.radians(rot_deg + i * 36 - 90)
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    draw.polygon(pts, fill=(245, 215, 120, 255), outline=(160, 115, 30, 255))
    # Inner highlight
    draw.polygon([(cx + (r*0.6) * math.cos(math.radians(rot_deg + i * 36 - 90)),
                   cy + (r*0.6) * math.sin(math.radians(rot_deg + i * 36 - 90)))
                  for i, r in enumerate([r_outer if k % 2 == 0 else r_inner for k in range(10)])],
                 fill=(255, 235, 160, 255))

def create_metallic_ring(size, r_out, r_in, top_color, bot_color):
    w, h = size
    cx, cy = w / 2, h / 2
    y, x = np.ogrid[:h, :w]
    angle = np.arctan2(y - cy, x - cx) # -pi to pi
    dist = np.hypot(x - cx, y - cy)
    
    # Ring mask
    mask = (dist >= r_in) & (dist <= r_out)
    
    # Gradient based on angle (light at top-left ~ -135 deg / -3pi/4)
    light_angle = -3 * math.pi / 4
    diff = np.cos(angle - light_angle) # 1 at top-left, -1 at bottom-right
    t = (diff + 1) / 2 # 0 to 1
    
    r = (1 - t) * bot_color[0] + t * top_color[0]
    g = (1 - t) * bot_color[1] + t * top_color[1]
    b = (1 - t) * bot_color[2] + t * top_color[2]
    
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[mask, 0] = r[mask]
    rgba[mask, 1] = g[mask]
    rgba[mask, 2] = b[mask]
    rgba[mask, 3] = 255
    return Image.fromarray(rgba, 'RGBA')

def draw_curved_text(img, text, font, center, radius, start_angle_deg, is_top=True, fill_color=(245, 212, 122), shadow_color=(8, 22, 14)):
    cx, cy = center
    glyphs = []
    total_w = 0
    for char in text:
        bbox = font.getbbox(char)
        cw = max(bbox[2] - bbox[0], font.size * 0.35)
        ch = bbox[3] - bbox[1]
        glyphs.append((char, cw, ch, bbox))
        total_w += cw + (font.size * 0.16)
    
    total_w -= (font.size * 0.16)
    angular_span = total_w / radius
    
    if is_top:
        start_rad = math.radians(start_angle_deg) - (angular_span / 2)
        curr_rad = start_rad
        for char, cw, ch, bbox in glyphs:
            glyph_span = (cw + font.size * 0.16) / radius
            angle_rad = curr_rad + (glyph_span / 2)
            curr_rad += glyph_span
            
            px = cx + radius * math.cos(angle_rad)
            py = cy + radius * math.sin(angle_rad)
            
            char_size = int(font.size * 2)
            c_img = Image.new('RGBA', (char_size, char_size), (0, 0, 0, 0))
            c_draw = ImageDraw.Draw(c_img)
            # Drop shadow
            c_draw.text((char_size//2 + 3, char_size//2 + 3), char, font=font, fill=(0, 0, 0, 200), anchor='mm')
            # Text
            c_draw.text((char_size//2, char_size//2), char, font=font, fill=fill_color, anchor='mm')
            
            rot_deg = math.degrees(angle_rad) + 90
            rotated = c_img.rotate(-rot_deg, resample=Image.BICUBIC)
            img.alpha_composite(rotated, (int(px - char_size//2), int(py - char_size//2)))
    else:
        start_rad = math.radians(start_angle_deg) + (angular_span / 2)
        curr_rad = start_rad
        for char, cw, ch, bbox in glyphs:
            glyph_span = (cw + font.size * 0.16) / radius
            angle_rad = curr_rad - (glyph_span / 2)
            curr_rad -= glyph_span
            
            px = cx + radius * math.cos(angle_rad)
            py = cy + radius * math.sin(angle_rad)
            
            char_size = int(font.size * 2)
            c_img = Image.new('RGBA', (char_size, char_size), (0, 0, 0, 0))
            c_draw = ImageDraw.Draw(c_img)
            c_draw.text((char_size//2 + 2, char_size//2 + 2), char, font=font, fill=(0, 0, 0, 180), anchor='mm')
            c_draw.text((char_size//2, char_size//2), char, font=font, fill=fill_color, anchor='mm')
            
            rot_deg = math.degrees(angle_rad) - 90
            rotated = c_img.rotate(-rot_deg, resample=Image.BICUBIC)
            img.alpha_composite(rotated, (int(px - char_size//2), int(py - char_size//2)))

def build_refined_crest():
    canvas_size = 1200
    cx, cy = canvas_size // 2, canvas_size // 2
    
    # 1. Base dark background (deep charcoal emerald)
    bg = Image.new('RGBA', (canvas_size, canvas_size), (8, 14, 11, 255))
    
    # 2. Main crest layer
    crest = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(crest)
    
    # Radii
    r_outer = 560
    r_band_outer = 535
    r_band_inner = 375
    
    # Outer gold rim (metallic gradient)
    outer_gold = create_metallic_ring((canvas_size, canvas_size), r_outer, r_band_outer, (255, 230, 150), (160, 115, 30))
    crest = Image.alpha_composite(crest, outer_gold)
    draw = ImageDraw.Draw(crest)
    
    # Thin highlight lines on outer rim
    draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], outline=(255, 245, 190, 255), width=2)
    draw.ellipse([cx - r_band_outer, cy - r_band_outer, cx + r_band_outer, cy + r_band_outer], outline=(120, 85, 20, 255), width=2)
    
    # Dark green enamel band
    draw.ellipse([cx - r_band_outer, cy - r_band_outer, cx + r_band_outer, cy + r_band_outer],
                 fill=(12, 34, 23, 255), outline=(180, 140, 45, 255), width=3)
    
    # Subtle inner pinstripe on green band
    r_pin_1 = r_band_outer - 12
    r_pin_2 = r_band_inner + 12
    draw.ellipse([cx - r_pin_1, cy - r_pin_1, cx + r_pin_1, cy + r_pin_1], outline=(180, 140, 45, 90), width=1)
    draw.ellipse([cx - r_pin_2, cy - r_pin_2, cx + r_pin_2, cy + r_pin_2], outline=(180, 140, 45, 90), width=1)
    
    # Inner gold border ring
    inner_gold = create_metallic_ring((canvas_size, canvas_size), r_band_inner + 6, r_band_inner - 6, (255, 225, 140), (140, 100, 25))
    crest = Image.alpha_composite(crest, inner_gold)
    draw = ImageDraw.Draw(crest)
    
    # CENTER MEDALLION PREPARATION
    # Seamless background color of the artwork
    parchment_color = (208, 206, 204)
    medallion_diam = r_band_inner * 2
    medallion = Image.new('RGB', (medallion_diam, medallion_diam), parchment_color)
    
    # Add subtle vintage parchment texture grain
    grain = np.random.normal(0, 3.5, (medallion_diam, medallion_diam, 3)).astype(np.int16)
    base_arr = np.array(medallion, dtype=np.int16)
    textured_arr = np.clip(base_arr + grain, 0, 255).astype(np.uint8)
    medallion = Image.fromarray(textured_arr, 'RGB')
    
    # Load and scale skeleton
    sk_orig = Image.open('d:/Development/Arcadia/assets/images/skeleton_cropped.jpg').convert('RGB')
    # Boost ink contrast
    sk_contrast = ImageOps.autocontrast(sk_orig, cutoff=0.5)
    
    # Target height inside medallion
    target_h = int(medallion_diam * 0.94)
    scale = target_h / sk_contrast.height
    target_w = int(sk_contrast.width * scale)
    sk_resized = sk_contrast.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    # Create feathered alpha mask for the skeleton rectangle so the edges blend 100% invisibly into parchment
    sk_w, sk_h = sk_resized.size
    fade_dist = 40
    y_idx, x_idx = np.ogrid[:sk_h, :sk_w]
    dist_left = np.clip(x_idx / fade_dist, 0, 1)
    dist_right = np.clip((sk_w - 1 - x_idx) / fade_dist, 0, 1)
    dist_top = np.clip(y_idx / fade_dist, 0, 1)
    dist_bot = np.clip((sk_h - 1 - y_idx) / fade_dist, 0, 1)
    fade_mask = (dist_left * dist_right * dist_top * dist_bot * 255).astype(np.uint8)
    fade_img = Image.fromarray(fade_mask, 'L')
    
    # Paste skeleton into medallion
    pos_x = (medallion_diam - target_w) // 2
    pos_y = (medallion_diam - target_h) // 2
    medallion.paste(sk_resized, (pos_x, pos_y), fade_img)
    
    # Circular mask for the center medallion
    circle_mask = Image.new('L', (medallion_diam, medallion_diam), 0)
    cm_draw = ImageDraw.Draw(circle_mask)
    cm_draw.ellipse([4, 4, medallion_diam - 4, medallion_diam - 4], fill=255)
    circle_mask = circle_mask.filter(ImageFilter.GaussianBlur(radius=1.5))
    
    # Convert medallion to RGBA and composite
    medallion_rgba = medallion.convert('RGBA')
    crest.paste(medallion_rgba, (cx - r_band_inner, cy - r_band_inner), circle_mask)
    
    # Inner shadow inside the medallion edge for realistic depth
    shadow_ring = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    sr_draw = ImageDraw.Draw(shadow_ring)
    for i in range(12):
        alpha = int(120 * (1 - i / 12))
        sr_draw.ellipse([cx - r_band_inner + i, cy - r_band_inner + i, cx + r_band_inner - i, cy + r_band_inner - i], outline=(0, 0, 0, alpha), width=1)
    crest = Image.alpha_composite(crest, shadow_ring)
    draw = ImageDraw.Draw(crest)
    
    # Double gold pinstripe ring framing the skeleton
    draw.ellipse([cx - r_band_inner + 1, cy - r_band_inner + 1, cx + r_band_inner - 1, cy + r_band_inner - 1], outline=(245, 215, 120, 255), width=3)
    draw.ellipse([cx - r_band_inner - 3, cy - r_band_inner - 3, cx + r_band_inner + 3, cy + r_band_inner + 3], outline=(140, 100, 25, 255), width=2)
    
    # FONTS & TEXT
    font_main = ImageFont.truetype('C:/Windows/Fonts/cambriab.ttf', 76)
    font_sub = ImageFont.truetype('C:/Windows/Fonts/cambriab.ttf', 42)
    
    r_text_top = (r_band_outer + r_band_inner) / 2 + 6
    draw_curved_text(crest, "ARCADIA CUP", font_main, (cx, cy), r_text_top, -90, is_top=True, fill_color=(250, 222, 132))
    
    r_text_bottom = (r_band_outer + r_band_inner) / 2 - 2
    draw_curved_text(crest, "ARCADIA BLUFFS  •  MICHIGAN", font_sub, (cx, cy), r_text_bottom, 90, is_top=False, fill_color=(235, 198, 115))
    
    # STARS AT 9 O'CLOCK AND 3 O'CLOCK
    r_stars = (r_band_outer + r_band_inner) / 2 + 2
    # Left stars (approx 166, 180, 194 degrees)
    for ang in [165, 180, 195]:
        rad = math.radians(ang)
        sx = cx + r_stars * math.cos(rad)
        sy = cy + r_stars * math.sin(rad)
        size = 14 if ang == 180 else 10
        draw_gold_star(draw, sx, sy, size, size * 0.42, rot_deg=ang+90)
        
    # Right stars (approx -15, 0, 15 degrees)
    for ang in [-15, 0, 15]:
        rad = math.radians(ang)
        sx = cx + r_stars * math.cos(rad)
        sy = cy + r_stars * math.sin(rad)
        size = 14 if ang == 0 else 10
        draw_gold_star(draw, sx, sy, size, size * 0.42, rot_deg=ang-90)
        
    # Outer studded gold rivets (every 12 degrees)
    for deg in range(0, 360, 12):
        rad = math.radians(deg)
        sx = cx + (r_outer - 12) * math.cos(rad)
        sy = cy + (r_outer - 12) * math.sin(rad)
        draw.ellipse([sx - 3.5, sy - 3.5, sx + 3.5, sy + 3.5], fill=(255, 240, 180, 255), outline=(130, 90, 20, 255))
        
    # Final composite over dark luxury background
    final_crest = Image.alpha_composite(bg, crest)
    
    # Save master high-res files
    # 1. assets/images/arcadia_cup_crest.jpg (Used by app screens)
    final_crest.convert('RGB').save('d:/Development/Arcadia/assets/images/arcadia_cup_crest.jpg', quality=96)
    
    # 2. Transparent background version
    trans_crest = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    t_mask = Image.new('L', (canvas_size, canvas_size), 0)
    t_draw = ImageDraw.Draw(t_mask)
    t_draw.ellipse([cx - r_outer - 2, cy - r_outer - 2, cx + r_outer + 2, cy + r_outer + 2], fill=255)
    trans_crest.paste(final_crest, (0, 0), t_mask)
    trans_crest.save('d:/Development/Arcadia/assets/images/arcadia_cup_crest_transparent.png')
    
    # 3. App Bar Logo / Icons
    trans_crest.resize((512, 512), Image.Resampling.LANCZOS).save('d:/Development/Arcadia/assets/images/arcadia_logo.png')
    trans_crest.resize((192, 192), Image.Resampling.LANCZOS).save('d:/Development/Arcadia/assets/images/arcadia_icon.png')
    
    print("Refined luxury championship crest created successfully!")

build_refined_crest()
