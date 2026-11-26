#!/usr/bin/env python3
"""
Generate a sleek, minimalist Obsidian Black macOS DMG installer background
with a crisp curved 'drag and drop' arrow pointing to Applications.
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

def draw_curved_arrow(draw, start, end, control, color=(255, 255, 255, 255), width=6):
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
    
    arrow_len = width * 4.0
    arrow_angle = math.radians(28)
    
    p1 = end
    p2 = (end[0] - arrow_len * math.cos(angle - arrow_angle),
          end[1] - arrow_len * math.sin(angle - arrow_angle))
    p3 = (end[0] - arrow_len * math.cos(angle + arrow_angle),
          end[1] - arrow_len * math.sin(angle + arrow_angle))
    
    draw.polygon([p1, p2, p3], fill=color)

def create_dmg_background(output_path):
    # Render at 2x Retina resolution (1320 x 840) then scale down to (660 x 420)
    w2x, h2x = 1320, 840
    
    # Pure Obsidian Black Background (#0D0E12)
    bg = Image.new("RGBA", (w2x, h2x), (13, 14, 18, 255))
    draw = ImageDraw.Draw(bg)
    
    # Subtle radial glow behind the center
    for r in range(400, 0, -10):
        alpha = int(18 * (1 - r / 400))
        bbox = [w2x // 2 - r, 420 - r // 2, w2x // 2 + r, 420 + r // 2]
        draw.ellipse(bbox, fill=(28, 32, 42, alpha))
        
    # Fonts
    title_font = get_font(34, bold=True)
    sub_font = get_font(20, bold=False)
    arrow_font = get_font(28, bold=True)
    tip_title_font = get_font(22, bold=True)
    tip_body_font = get_font(20, bold=False)
    
    # Top Header Pill Badge
    header_box = [w2x // 2 - 270, 36, w2x // 2 + 270, 110]
    draw.rounded_rectangle(header_box, radius=37, fill=(20, 22, 28, 240), outline=(255, 255, 255, 45), width=2)
    draw.text((w2x // 2, 62), "MaC Wallspace", fill=(255, 255, 255, 255), font=title_font, anchor="mm")
    draw.text((w2x // 2, 92), "Native Live Wallpaper Engine for Older Macs", fill=(160, 165, 180, 240), font=sub_font, anchor="mm")
    
    # Curved Arrow from Left (x: 440) to Right (x: 880)
    start_pt = (440, 410)
    end_pt = (880, 410)
    control_pt = (660, 300)
    
    # Arrow drop shadow
    draw_curved_arrow(draw, (start_pt[0], start_pt[1] + 3), (end_pt[0], end_pt[1] + 3), (control_pt[0], control_pt[1] + 3), color=(0, 0, 0, 180), width=9)
    # Bright Crisp Arrow
    draw_curved_arrow(draw, start_pt, end_pt, control_pt, color=(240, 245, 255, 255), width=7)
    
    # "drag and drop" text centered above the curve arch
    text_pos = (660, 260)
    for ox, oy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
        draw.text((text_pos[0] + ox, text_pos[1] + oy), "drag and drop", fill=(0, 0, 0, 220), font=arrow_font, anchor="mm")
    draw.text(text_pos, "drag and drop", fill=(255, 255, 255, 255), font=arrow_font, anchor="mm")
    
    # Bottom Frosted Glass Help Pill (Gatekeeper Helper)
    pill_rect = [110, 715, w2x - 110, 805]
    draw.rounded_rectangle(pill_rect, radius=24, fill=(20, 23, 30, 240), outline=(255, 255, 255, 40), width=2)
    draw.text((w2x // 2, 742), "First Launch: Open Applications in Finder", fill=(255, 215, 80, 255), font=tip_title_font, anchor="mm")
    draw.text((w2x // 2, 776), "Right-Click 'Mac Wallspace' → Select 'Open' (Press Open twice to approve)", fill=(215, 220, 230, 240), font=tip_body_font, anchor="mm")
    
    # Scale down to 660x420 for final output
    final_img = bg.resize((660, 420), Image.Resampling.LANCZOS)
    final_img.save(output_path, "PNG")
    print(f"✓ Created sleek Obsidian Black DMG background: {output_path}")

if __name__ == "__main__":
    dst = sys.argv[1] if len(sys.argv) > 1 else "Resources/icon_assets/dmg_background.png"
    create_dmg_background(dst)
