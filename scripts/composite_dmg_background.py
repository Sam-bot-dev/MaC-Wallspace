#!/usr/bin/env python3
"""
Composite a high-end macOS DMG installer background with an anime wallpaper,
featuring a smooth curved 'drag and drop' arrow pointing to Applications,
just like the Docker DMG but significantly more beautiful and cinematic.
"""

import sys
import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def draw_curved_arrow(draw, start, end, control, color=(255, 255, 255, 230), width=4):
    """Draw a smooth quadratic bezier curve with an arrow head."""
    # Generate points along bezier curve
    num_steps = 60
    points = []
    for i in range(num_steps + 1):
        t = i / num_steps
        # B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
        x = (1 - t)**2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0]
        y = (1 - t)**2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1]
        points.append((x, y))
    
    # Draw curve
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=color, width=width)
    
    # Calculate tangent at the end point for arrow head
    t = 0.96
    prev_x = (1 - t)**2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0]
    prev_y = (1 - t)**2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1]
    
    dx = end[0] - prev_x
    dy = end[1] - prev_y
    angle = math.atan2(dy, dx)
    
    # Arrowhead geometry
    arrow_len = 16
    arrow_angle = math.radians(26)
    
    p1 = end
    p2 = (end[0] - arrow_len * math.cos(angle - arrow_angle),
          end[1] - arrow_len * math.sin(angle - arrow_angle))
    p3 = (end[0] - arrow_len * math.cos(angle + arrow_angle),
          end[1] - arrow_len * math.sin(angle + arrow_angle))
    
    draw.polygon([p1, p2, p3], fill=color)

def create_dmg_background(input_image_path, output_path, width=660, height=420):
    if os.path.exists(input_image_path):
        bg = Image.open(input_image_path).convert("RGBA")
        
        # Crop & resize to fit width x height maintaining aspect ratio
        img_ratio = bg.width / bg.height
        target_ratio = width / height
        
        if img_ratio > target_ratio:
            new_width = int(bg.height * target_ratio)
            left = (bg.width - new_width) // 2
            bg = bg.crop((left, 0, left + new_width, bg.height))
        else:
            new_height = int(bg.width / target_ratio)
            top = (bg.height - new_height) // 2
            bg = bg.crop((0, top, bg.width, top + new_height))
            
        bg = bg.resize((width, height), Image.Resampling.LANCZOS)
    else:
        # Fallback dark anime gradient if file missing
        bg = Image.new("RGBA", (width, height), (20, 24, 38, 255))
        draw_tmp = ImageDraw.Draw(bg)
        for y in range(height):
            ratio = y / height
            r = int(24 * (1 - ratio) + 12 * ratio)
            g = int(30 * (1 - ratio) + 16 * ratio)
            b = int(55 * (1 - ratio) + 32 * ratio)
            draw_tmp.line([(0, y), (width, y)], fill=(r, g, b, 255))

    # Add subtle cinematic darkening overlay for icon readability
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    
    # Top bar gradient
    for y in range(80):
        alpha = int(140 * (1 - y / 80))
        ov_draw.line([(0, y), (width, y)], fill=(10, 12, 18, alpha))
        
    # Bottom bar gradient for instructions
    for y in range(height - 110, height):
        t = (y - (height - 110)) / 110
        alpha = int(170 * t)
        ov_draw.line([(0, y), (width, y)], fill=(10, 12, 18, alpha))
        
    # Soft vignette / dark circles behind icons for clean contrast
    # Left icon area (160, 195)
    ov_draw.ellipse([80, 115, 240, 275], fill=(12, 14, 20, 90))
    # Right icon area (500, 195)
    ov_draw.ellipse([420, 115, 580, 275], fill=(12, 14, 20, 90))
    
    bg = Image.alpha_composite(bg, overlay)
    draw = ImageDraw.Draw(bg)
    
    # Header Branding
    header_box = [width // 2 - 120, 20, width // 2 + 120, 52]
    draw.rounded_rectangle(header_box, radius=16, fill=(15, 18, 26, 200), outline=(255, 255, 255, 50), width=1)
    draw.text((width // 2, 36), "MaC Wallspace", fill=(255, 255, 255, 255), anchor="mm")
    
    # Draw Curved Arrow from Left (x: 235, y: 195) to Right (x: 425, y: 195)
    # Control point is arched upward (x: 330, y: 140)
    start_pt = (235, 200)
    end_pt = (425, 200)
    control_pt = (330, 135)
    
    # Shadow for arrow for extra depth
    draw_curved_arrow(draw, (start_pt[0], start_pt[1] + 2), (end_pt[0], end_pt[1] + 2), (control_pt[0], control_pt[1] + 2), color=(0, 0, 0, 120), width=5)
    # Crisp white arrow
    draw_curved_arrow(draw, start_pt, end_pt, control_pt, color=(255, 255, 255, 240), width=4)
    
    # "drag and drop" text centered above the curve arch
    # Text shadow
    draw.text((330, 117), "drag and drop", fill=(0, 0, 0, 180), anchor="mm")
    draw.text((330, 116), "drag and drop", fill=(255, 255, 255, 255), anchor="mm")
    
    # Bottom Frosted Glass Help Pill (Gatekeeper Helper)
    pill_rect = [50, 350, width - 50, 398]
    draw.rounded_rectangle(pill_rect, radius=12, fill=(15, 18, 25, 210), outline=(255, 255, 255, 45), width=1)
    draw.text((width // 2, 366), "⚠️ If Apple blocks opening: Right-Click 'Mac Wallspace' → Open", fill=(255, 220, 100, 255), anchor="mm")
    draw.text((width // 2, 384), "Or double-click 'Fix Gatekeeper & Open.command' below", fill=(220, 225, 235, 230), anchor="mm")
    
    bg.save(output_path, "PNG")
    print(f"✓ Created anime-themed DMG background: {output_path}")

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else ""
    dst = sys.argv[2] if len(sys.argv) > 2 else "dmg_background.png"
    create_dmg_background(src, dst)
