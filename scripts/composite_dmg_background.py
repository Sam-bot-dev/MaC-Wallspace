#!/usr/bin/env python3
"""
Composite a gorgeous, cinematic macOS DMG installer background with an anime wallpaper,
featuring a smooth curved 'drag and drop' arrow pointing to Applications,
just like the Docker DMG reference but significantly more beautiful and clean.
"""

import sys
import os
import math
from PIL import Image, ImageDraw, ImageFont

def get_font(size, bold=False):
    font_paths = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in font_paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()

def draw_curved_arrow(draw, start, end, control, color=(255, 255, 255, 255), width=5):
    """Draw a smooth quadratic bezier curve with an arrow head."""
    num_steps = 100
    points = []
    for i in range(num_steps + 1):
        t = i / num_steps
        x = (1 - t)**2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0]
        y = (1 - t)**2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1]
        points.append((x, y))
    
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=color, width=width)
    
    # Calculate tangent at the end point for arrow head
    t = 0.95
    prev_x = (1 - t)**2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0]
    prev_y = (1 - t)**2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1]
    
    dx = end[0] - prev_x
    dy = end[1] - prev_y
    angle = math.atan2(dy, dx)
    
    arrow_len = width * 3.8
    arrow_angle = math.radians(28)
    
    p1 = end
    p2 = (end[0] - arrow_len * math.cos(angle - arrow_angle),
          end[1] - arrow_len * math.sin(angle - arrow_angle))
    p3 = (end[0] - arrow_len * math.cos(angle + arrow_angle),
          end[1] - arrow_len * math.sin(angle + arrow_angle))
    
    draw.polygon([p1, p2, p3], fill=color)

def create_dmg_background(input_image_path, output_path):
    # Render at 2x Retina resolution (1320 x 840) then scale down to (660 x 420)
    w2x, h2x = 1320, 840
    
    if os.path.exists(input_image_path):
        bg = Image.open(input_image_path).convert("RGBA")
        
        # Crop & resize to fit 1320x840
        img_ratio = bg.width / bg.height
        target_ratio = w2x / h2x
        
        if img_ratio > target_ratio:
            new_width = int(bg.height * target_ratio)
            left = (bg.width - new_width) // 2
            bg = bg.crop((left, 0, left + new_width, bg.height))
        else:
            new_height = int(bg.width / target_ratio)
            top = (bg.height - new_height) // 2
            bg = bg.crop((0, top, bg.width, top + new_height))
            
        bg = bg.resize((w2x, h2x), Image.Resampling.LANCZOS)
    else:
        bg = Image.new("RGBA", (w2x, h2x), (16, 18, 25, 255))

    # Subtle cinematic darkening overlays (no circular cutouts!)
    overlay = Image.new("RGBA", (w2x, h2x), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    
    # Top header soft vignette
    for y in range(160):
        alpha = int(180 * (1 - y / 160))
        ov_draw.line([(0, y), (w2x, y)], fill=(8, 10, 15, alpha))
        
    # Bottom instructions bar soft vignette
    for y in range(h2x - 200, h2x):
        t = (y - (h2x - 200)) / 200
        alpha = int(210 * t)
        ov_draw.line([(0, y), (w2x, y)], fill=(8, 10, 15, alpha))
    
    bg = Image.alpha_composite(bg, overlay)
    draw = ImageDraw.Draw(bg)
    
    # Fonts
    title_font = get_font(32, bold=True)
    body_font = get_font(22, bold=False)
    arrow_font = get_font(28, bold=True)
    tip_title_font = get_font(22, bold=True)
    tip_body_font = get_font(20, bold=False)
    
    # Top Header Pill Badge
    header_box = [w2x // 2 - 240, 36, w2x // 2 + 240, 106]
    draw.rounded_rectangle(header_box, radius=35, fill=(14, 16, 22, 210), outline=(255, 255, 255, 60), width=2)
    draw.text((w2x // 2, 60), "MaC Wallspace", fill=(255, 255, 255, 255), font=title_font, anchor="mm")
    draw.text((w2x // 2, 88), "Native Live Wallpaper Engine for Older Macs", fill=(190, 195, 210, 240), font=get_font(18), anchor="mm")
    
    # Curved Arrow from Left (x: 440) to Right (x: 880)
    # macOS Finder icon centers at 660x420 are x: 160 and x: 500 (in 2x: x: 320 and x: 1000)
    # The arrow curves between the icons: start (430, 420), end (890, 420), arched up to (660, 310)
    start_pt = (440, 410)
    end_pt = (880, 410)
    control_pt = (660, 300)
    
    # Drop shadow for arrow
    draw_curved_arrow(draw, (start_pt[0], start_pt[1] + 4), (end_pt[0], end_pt[1] + 4), (control_pt[0], control_pt[1] + 4), color=(0, 0, 0, 160), width=9)
    # Crisp white arrow with soft pink sakura glow
    draw_curved_arrow(draw, start_pt, end_pt, control_pt, color=(255, 255, 255, 255), width=7)
    
    # "drag and drop" text centered above the curve arch
    # Text shadow
    text_pos = (660, 260)
    for ox, oy in [(-2, 0), (2, 0), (0, -2), (0, 2), (-2, -2), (2, 2)]:
        draw.text((text_pos[0] + ox, text_pos[1] + oy), "drag and drop", fill=(0, 0, 0, 220), font=arrow_font, anchor="mm")
    draw.text(text_pos, "drag and drop", fill=(255, 255, 255, 255), font=arrow_font, anchor="mm")
    
    # Bottom Frosted Glass Help Pill (Gatekeeper Helper)
    pill_rect = [90, 710, w2x - 90, 804]
    draw.rounded_rectangle(pill_rect, radius=24, fill=(12, 15, 22, 220), outline=(255, 255, 255, 55), width=2)
    draw.text((w2x // 2, 738), "Important: If macOS says 'Cannot check for malicious software'", fill=(255, 215, 80, 255), font=tip_title_font, anchor="mm")
    draw.text((w2x // 2, 774), "Right-Click 'Mac Wallspace' -> Select 'Open'  |  Or double-click 'Fix Gatekeeper & Open.command'", fill=(230, 235, 245, 240), font=tip_body_font, anchor="mm")
    
    # Scale down to 660x420 for final output
    final_img = bg.resize((660, 420), Image.Resampling.LANCZOS)
    final_img.save(output_path, "PNG")
    print(f"✓ Created refined cinematic anime DMG background: {output_path}")

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else ""
    dst = sys.argv[2] if len(sys.argv) > 2 else "dmg_background.png"
    create_dmg_background(src, dst)
