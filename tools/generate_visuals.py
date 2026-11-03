# -*- coding: utf-8 -*-
"""
GestureMouse Visual Generator v6.0 (HD 720p @ Native 60 FPS)
- 1280x720 High Definition (Crystal clear, zero blur on Retina/4K displays)
- True 60 FPS (360 frames over 6.0 seconds) with buttery smooth motion
- Top-center concise HUD badge
- Clean Cyber Mouse Widget scaled to 720p (no text clutter, active LED highlights)
- Authentic GitHub Page content across 3 pages
- Realistic Smartphone Swipe & Fling Inertial Physics using 60 FPS friction factor (0.972)
- 7 clips:
  1. demo_back_forward: Straight Left (Back) & Straight Right (Forward)
  2. demo_tab_switch: Left then Down (Next Tab) & Left then Up (Prev Tab)
  3. demo_close_refresh: Right then Up (Close Active Tab) & Right then Down (Reload)
  4. demo_kinetic_scroll: Deep swipe down -> release fling -> brake, swipe up -> release -> brake
  5. demo_drag_scroll: 1:1 mouse & cursor drag tracking
  6. demo_pgup_pgdn: 3-page GitHub document leaps
  7. demo_volume: Rocker gesture volume control
"""

import os
import sys
import math
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

OUTPUT_DIRS = [
    os.path.abspath("docs/image"),
    os.path.abspath("image")
]
TEMP_FRAME_DIR = os.path.abspath("tools/_temp_frames")

WIDTH = 1280
HEIGHT = 720
FPS = 60
TOTAL_FRAMES = 360  # Exactly 6.0 seconds @ 60 FPS

FONT_PATH = "C:/Windows/Fonts/segoeui.ttf"
FONT_BOLD_PATH = "C:/Windows/Fonts/segoeuib.ttf"
FONT_CODE_PATH = "C:/Windows/Fonts/consola.ttf"

def get_font(size, bold=False, code=False):
    if code:
        p = FONT_CODE_PATH
    else:
        p = FONT_BOLD_PATH if bold else FONT_PATH
    try:
        return ImageFont.truetype(p, size)
    except:
        return ImageFont.load_default()

LOGO_IMG = None
ICON_L = None
ICON_R = None
ICON_LU = None
ICON_LD = None
ICON_RU = None
ICON_RD = None
try:
    if os.path.exists("image/unnamed.png"):
        LOGO_IMG = Image.open("image/unnamed.png").convert("RGBA").resize((38, 38))
    if os.path.exists("image/L.ico"):
        ICON_L = Image.open("image/L.ico").convert("RGBA").resize((32, 32))
    if os.path.exists("image/R.ico"):
        ICON_R = Image.open("image/R.ico").convert("RGBA").resize((32, 32))
    if os.path.exists("image/LU.ico"):
        ICON_LU = Image.open("image/LU.ico").convert("RGBA").resize((32, 32))
    if os.path.exists("image/LD.ico"):
        ICON_LD = Image.open("image/LD.ico").convert("RGBA").resize((32, 32))
    if os.path.exists("image/RU.ico"):
        ICON_RU = Image.open("image/RU.ico").convert("RGBA").resize((32, 32))
    if os.path.exists("image/RD.ico"):
        ICON_RD = Image.open("image/RD.ico").convert("RGBA").resize((32, 32))
except Exception:
    pass

# ==============================================================================
# TOP-CENTER CONCISE LARGE HUD (720P SCALED)
# ==============================================================================
def draw_top_hud(im, draw, text, icon=None, highlight=False):
    font = get_font(21, bold=True)
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    
    pad_x = 34
    if icon:
        pad_x += 38
    
    bw = tw + pad_x * 2
    bh = 52
    bx = (WIDTH - 280) // 2 - bw // 2 + 10
    by = 125
    
    bd_col = (6, 182, 212) if highlight else (55, 68, 88)
    bg_col = (13, 20, 32, 248) if highlight else (16, 22, 32, 240)
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=14,
                           fill=bg_col, outline=bd_col, width=2 if highlight else 1)
    
    tx = bx + 32
    if icon:
        im.paste(icon, (bx + 22, by + 10), icon)
        tx = bx + 64
        
    text_col = (255, 255, 255) if highlight else (210, 220, 235)
    draw.text((tx, by + 11), text, fill=text_col, font=font)

# ==============================================================================
# CLEAN MINIMALIST CYBER MOUSE WIDGET (720P SCALED)
# ==============================================================================
def draw_clean_mouse_widget(draw, bx, by, bw=260, bh=300,
                            lmb=False, rmb=False, wheel_dir=0,
                            mouse_offset=(0, 0), frame_idx=0):
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=22,
                           fill=(11, 15, 23, 240), outline=(38, 48, 65), width=1)
    
    pad_x = bx + 14
    pad_y = by + 14
    pad_w = bw - 28
    pad_h = bh - 28
    draw.rounded_rectangle([pad_x, pad_y, pad_x + pad_w, pad_y + pad_h], radius=16,
                           fill=(7, 10, 16), outline=(24, 32, 44), width=1)
    
    for gx in range(pad_x + 24, pad_x + pad_w, 28):
        draw.line([(gx, pad_y + 4), (gx, pad_y + pad_h - 4)], fill=(15, 20, 28), width=1)
    for gy in range(pad_y + 24, pad_y + pad_h, 28):
        draw.line([(pad_x + 4, gy), (pad_x + pad_w - 4, gy)], fill=(15, 20, 28), width=1)

    mx = pad_x + pad_w // 2 + mouse_offset[0]
    my = pad_y + pad_h // 2 + mouse_offset[1]
    
    mw = 108
    mh = 178

    draw.rounded_rectangle([mx - mw//2 + 3, my - mh//2 + 7, mx + mw//2 + 3, my + mh//2 + 7],
                           radius=42, fill=(3, 5, 8))

    led_col = (6, 182, 212) if rmb else ((37, 99, 235) if lmb else (42, 54, 72))
    draw.rounded_rectangle([mx - mw//2 - 2, my - mh//2 - 2, mx + mw//2 + 2, my + mh//2 + 2],
                           radius=44, outline=led_col, width=2)

    draw.rounded_rectangle([mx - mw//2, my - mh//2, mx + mw//2, my + mh//2],
                           radius=42, fill=(20, 26, 36), outline=(45, 56, 74), width=1)

    for gy in range(my - 16, my + 44, 11):
        draw.line([(mx - mw//2 + 4, gy), (mx - mw//2 + 9, gy)], fill=(36, 46, 62), width=2)
        draw.line([(mx + mw//2 - 9, gy), (mx + mw//2 - 4, gy)], fill=(36, 46, 62), width=2)

    # Nút Trái
    lmb_top = my - mh//2 + 6
    lmb_bot = my - 12
    lmb_left = mx - mw//2 + 6
    lmb_right = mx - 4
    if lmb:
        draw.rounded_rectangle([lmb_left, lmb_top + 3, lmb_right, lmb_bot + 3], radius=14,
                               fill=(29, 78, 216), outline=(96, 165, 250), width=2)
    else:
        draw.rounded_rectangle([lmb_left, lmb_top, lmb_right, lmb_bot], radius=14,
                               fill=(32, 40, 54), outline=(48, 60, 80), width=1)

    # Nút Phải
    rmb_top = my - mh//2 + 6
    rmb_bot = my - 12
    rmb_left = mx + 4
    rmb_right = mx + mw//2 - 6
    if rmb:
        draw.rounded_rectangle([rmb_left, rmb_top + 3, rmb_right, rmb_bot + 3], radius=14,
                               fill=(8, 145, 178), outline=(103, 232, 249), width=2)
    else:
        draw.rounded_rectangle([rmb_left, rmb_top, rmb_right, rmb_bot], radius=14,
                               fill=(32, 40, 54), outline=(48, 60, 80), width=1)

    # Con lăn kim loại
    ww = 18
    wh = 48
    wx = mx - ww // 2
    wy = my - mh // 2 + 14
    wheel_active = (wheel_dir != 0)
    wheel_bg = (6, 182, 212) if wheel_active else (15, 20, 28)
    wheel_bd = (255, 255, 255) if wheel_active else (65, 78, 98)
    draw.rounded_rectangle([wx, wy, wx + ww, wy + wh], radius=6, fill=wheel_bg, outline=wheel_bd, width=1)

    groove_offset = (frame_idx * 4) % 10 if wheel_active else 0
    for gy in range(wy + 4, wy + wh - 3, 9):
        gy_anim = gy + (groove_offset if wheel_dir < 0 else -groove_offset)
        if wy + 3 <= gy_anim <= wy + wh - 4:
            line_col = (10, 25, 35) if wheel_active else (42, 52, 68)
            draw.line([(wx + 2, gy_anim), (wx + ww - 2, gy_anim)], fill=line_col, width=1)

    if wheel_dir > 0:
        draw.text((mx - 6, wy - 15), "▲", fill=(6, 182, 212), font=get_font(13, bold=True))
    elif wheel_dir < 0:
        draw.text((mx - 6, wy + wh + 2), "▼", fill=(6, 182, 212), font=get_font(13, bold=True))

    draw.ellipse([mx - 13, my + mh//4 - 2, mx + 13, my + mh//4 + 24], fill=(26, 34, 46))
    draw.text((mx - 6, my + mh//4 + 1), "G", fill=(6, 182, 212), font=get_font(14, bold=True))

# ==============================================================================
# GITHUB PAGE RENDERING (720P SCALED)
# ==============================================================================
def draw_github_page(im, draw, scroll_y=0):
    sy = -int(scroll_y)
    draw.rectangle([0, 110, WIDTH, HEIGHT], fill=(11, 15, 25))

    # --- SECTION 1: HERO (0 - 550) ---
    s1_y = sy + 125
    if s1_y + 520 >= 110 and s1_y <= HEIGHT:
        if LOGO_IMG:
            im.paste(LOGO_IMG, (60, s1_y + 14), LOGO_IMG)
        draw.text((108, s1_y + 18), "GestureMouse — Smart Mouse Utility", fill=(240, 245, 250), font=get_font(21, bold=True))
        
        draw.rounded_rectangle([60, s1_y + 60, WIDTH - 330, s1_y + 440], radius=16, fill=(19, 25, 36), outline=(38, 48, 66))
        draw.text((90, s1_y + 90), "Supercharge Your Windows Mouse Experience", fill=(103, 232, 249), font=get_font(24, bold=True))
        draw.text((90, s1_y + 135), "Fluid kinetic inertial scrolling & rapid right-click gestures for Windows.", fill=(160, 170, 185), font=get_font(16))
        
        draw.rounded_rectangle([90, s1_y + 185, WIDTH - 390, s1_y + 245], radius=10, fill=(13, 17, 23), outline=(48, 54, 61))
        draw.text((115, s1_y + 202), "PS > winget install GestureMouse", fill=(103, 232, 249), font=get_font(16, code=True))
        draw.text((WIDTH - 435, s1_y + 202), "📋", fill=(160, 170, 185), font=get_font(16))

        draw.text((90, s1_y + 280), "✔  100% Free & Open Source on GitHub", fill=(129, 201, 149), font=get_font(16, bold=True))
        draw.text((90, s1_y + 320), "✔  Ultra-lightweight: Uses less than 15MB RAM", fill=(129, 201, 149), font=get_font(16, bold=True))
        draw.text((90, s1_y + 360), "✔  Portable zero-install standalone executable", fill=(129, 201, 149), font=get_font(16, bold=True))

    # --- SECTION 2: KEY FEATURES (550 - 1100) ---
    s2_y = sy + 620
    if s2_y + 520 >= 110 and s2_y <= HEIGHT:
        draw.text((60, s2_y), "Key Features & Capabilities", fill=(240, 245, 250), font=get_font(23, bold=True))
        cards = [
            ("🌊 Kinetic Smooth Scroll", "Simulates iOS touchscreen inertia at 60 FPS without eye strain."),
            ("⚡ Right-Click Gestures", "Instant Back, Forward, Switch Tab, and Close Tab actions."),
            ("🔊 Rocker Volume Master", "Hold Left Mouse Button + Scroll Wheel to adjust volume instantly."),
            ("🛡️ Elevated UIAccess", "Seamlessly controls elevated windows like Task Manager safely.")
        ]
        for c_idx, (c_title, c_desc) in enumerate(cards):
            cy = s2_y + 50 + c_idx * 96
            draw.rounded_rectangle([60, cy, WIDTH - 330, cy + 82], radius=12, fill=(19, 25, 36), outline=(38, 48, 66))
            draw.text((85, cy + 15), c_title, fill=(103, 232, 249), font=get_font(17, bold=True))
            draw.text((85, cy + 46), c_desc, fill=(160, 170, 185), font=get_font(15))

    # --- SECTION 3: DEFAULT GESTURES SHOWCASE (1100 - 1650) ---
    s3_y = sy + 1120
    if s3_y + 520 >= 110 and s3_y <= HEIGHT:
        draw.text((60, s3_y), "Default Gestures Showcase", fill=(240, 245, 250), font=get_font(23, bold=True))
        draw.text((60, s3_y + 34), "Hold Right Mouse Button and glide in the specified direction", fill=(156, 163, 175), font=get_font(15))
        
        gest_list = [
            ("Back (Alt + Left)", "Straight Left ←", ICON_L),
            ("Forward (Alt + Right)", "Straight Right →", ICON_R),
            ("Next Tab (Ctrl + Tab)", "Left then Down ← ↓", ICON_LD),
            ("Previous Tab (Ctrl + Shift + Tab)", "Left then Up ← ↑", ICON_LU),
            ("Close Tab (Ctrl + W)", "Right then Up → ↑", ICON_RU),
            ("Reload Page (F5 / Ctrl + R)", "Right then Down → ↓", ICON_RD)
        ]
        for g_idx, (g_title, g_desc, g_ico) in enumerate(gest_list):
            gy = s3_y + 70 + g_idx * 68
            draw.rounded_rectangle([60, gy, WIDTH - 330, gy + 58], radius=10, fill=(19, 25, 36), outline=(38, 48, 66))
            if g_ico:
                im.paste(g_ico, (75, gy + 13), g_ico)
            draw.text((120, gy + 17), g_title, fill=(240, 245, 250), font=get_font(16, bold=True))
            draw.text((WIDTH - 590, gy + 17), g_desc, fill=(6, 182, 212), font=get_font(16, bold=True))

    # --- SECTION 4: INSTALLATION ---
    s4_y = sy + 1620
    if s4_y + 520 >= 110 and s4_y <= HEIGHT:
        draw.text((60, s4_y), "Quick 10-Second Installation", fill=(240, 245, 250), font=get_font(23, bold=True))
        steps = [
            ("1. Download Release", "Grab the latest GestureMouse-v1.0.0-Portable.zip from GitHub Releases."),
            ("2. Zero Configuration", "Extract anywhere and run GestureMouse.exe with standard user rights."),
            ("3. Optional UIAccess", "Right-click tray icon and enable UIAccess for elevated Task Manager control.")
        ]
        for st_idx, (st_title, st_desc) in enumerate(steps):
            sty = s4_y + 50 + st_idx * 90
            draw.rounded_rectangle([60, sty, WIDTH - 330, sty + 76], radius=10, fill=(19, 25, 36), outline=(38, 48, 66))
            draw.text((85, sty + 14), st_title, fill=(129, 201, 149), font=get_font(17, bold=True))
            draw.text((85, sty + 42), st_desc, fill=(160, 170, 185), font=get_font(15))

def draw_browser_scrollbar(draw, scroll_y, max_scroll=1500.0, active=False):
    """Vẽ thanh cuộn trình duyệt hiện đại (Browser Scrollbar)."""
    track_x1 = WIDTH - 324
    track_x2 = WIDTH - 306
    track_y1 = 110
    track_y2 = HEIGHT
    
    # Track rãnh cuộn
    draw.rectangle([track_x1, track_y1, track_x2, track_y2], fill=(13, 17, 26))
    draw.line([(track_x1, track_y1), (track_x1, track_y2)], fill=(28, 36, 50), width=1)
    
    # Con trượt thanh cuộn (Scrollbar Thumb)
    track_h = track_y2 - track_y1 - 10
    thumb_h = 130
    max_travel = track_h - thumb_h
    clamped_scroll = max(0.0, min(float(scroll_y), float(max_scroll)))
    thumb_y = track_y1 + 5 + int((clamped_scroll / max_scroll) * max_travel)
    
    thumb_bg = (6, 182, 212) if active else (56, 68, 88)
    thumb_bd = (103, 232, 249) if active else (75, 90, 115)
    draw.rounded_rectangle([track_x1 + 3, thumb_y, track_x2 - 3, thumb_y + thumb_h],
                           radius=5, fill=thumb_bg, outline=thumb_bd, width=1)

def draw_cursor(draw, x, y, click_type=None):
    if click_type == "right":
        draw.ellipse([x - 24, y - 24, x + 24, y + 24], fill=(6, 182, 212, 60), outline=(103, 232, 249), width=2)
    elif click_type == "left":
        draw.ellipse([x - 24, y - 24, x + 24, y + 24], fill=(37, 99, 235, 60), outline=(96, 165, 250), width=2)

    points = [
        (x, y),
        (x, y + 28),
        (x + 7, y + 21),
        (x + 15, y + 33),
        (x + 19, y + 30),
        (x + 12, y + 19),
        (x + 22, y + 19)
    ]
    draw.polygon(points, fill=(255, 255, 255), outline=(15, 15, 15))

def render_frames_to_media(base_name):
    """Mã hóa video 720p @ Native 60 FPS."""
    for out_dir in OUTPUT_DIRS:
        os.makedirs(out_dir, exist_ok=True)
        mp4_path = os.path.join(out_dir, f"{base_name}.mp4")

        # MP4: NATIVE 720P @ 60 FPS (True 60 FPS, Razor sharp)
        mp4_cmd = [
            "ffmpeg", "-y", "-framerate", str(FPS),
            "-i", os.path.join(TEMP_FRAME_DIR, "frame_%04d.png"),
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-preset", "fast",
            mp4_path
        ]
        subprocess.run(mp4_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    print(f"  ==> [720p 60FPS] Successfully created: {base_name}.mp4")

# ==============================================================================
# 1. DEMO 1: BACK & FORWARD (720P 60FPS)
# ==============================================================================
def make_demo_back_forward():
    print("[1/7] Creating demo_back_forward (720p @ 60 FPS)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (32, 33, 36))
        draw = ImageDraw.Draw(im)

        # 0-60: Viewing GitHub Page
        # 60-130: Draw Straight Left (Back) -> Google Search
        # 130-230: Viewing Google Search
        # 230-300: Draw Straight Right (Forward) -> GitHub Page
        # 300-360: Viewing GitHub Page

        is_search = (110 <= i < 270)
        back_active = (90 <= i < 115)
        fwd_active = (260 <= i < 285)

        # Browser Header
        draw.rectangle([0, 0, WIDTH, 110], fill=(41, 42, 45))
        draw.text((24, 66), "←", fill=(6, 182, 212) if back_active else (180, 190, 205), font=get_font(26, bold=True))
        draw.text((64, 66), "→", fill=(6, 182, 212) if fwd_active else (180, 190, 205), font=get_font(26, bold=True))
        draw.text((104, 66), "↻", fill=(180, 190, 205), font=get_font(24))
        
        draw.rounded_rectangle([150, 60, WIDTH - 60, 100], radius=18, fill=(32, 33, 36), outline=(60, 64, 67))
        curr_url = "https://www.google.com/search?q=GestureMouse" if is_search else "https://ngtrian.github.io/GestureMouse/"
        draw.text((172, 68), "🔒", fill=(129, 201, 149), font=get_font(17))
        draw.text((202, 70), curr_url, fill=(220, 225, 230), font=get_font(17))

        if is_search:
            draw.rectangle([0, 110, WIDTH, HEIGHT], fill=(32, 33, 36))
            draw.text((60, 135), "Google", fill=(232, 234, 237), font=get_font(28, bold=True))
            draw.rounded_rectangle([190, 130, 800, 178], radius=24, fill=(48, 49, 52), outline=(95, 99, 104))
            draw.text((220, 142), "GestureMouse Windows", fill=(232, 234, 237), font=get_font(18))
            draw.text((760, 142), "🔍", fill=(154, 160, 166), font=get_font(18))

            draw.text((60, 210), "https://ngtrian.github.io › GestureMouse", fill=(189, 193, 198), font=get_font(15))
            draw.text((60, 240), "GestureMouse - Smart Mouse Gestures for Windows", fill=(138, 180, 248), font=get_font(22, bold=True))
            draw.text((60, 280), "Smart right-click mouse gestures and fluid inertial kinetic scrolling for Windows.", fill=(189, 193, 198), font=get_font(16))
            draw.text((60, 310), "Lightweight (< 15MB RAM), fully open-source and portable.", fill=(189, 193, 198), font=get_font(16))
        else:
            draw_github_page(im, draw, scroll_y=0)

        cx, cy = 600, 360
        click_type = None
        rmb_pressed = False
        mouse_offset = (0, 0)
        hud_text = "Gesture Navigation"
        hud_icon = None
        hud_high = False
        trail_pts = []

        if 60 <= i < 110:
            # STRAIGHT LEFT (BACK)
            rmb_pressed = True
            click_type = "right"
            t = (i - 60) / 50.0
            cx = int(600 - t * 200)
            cy = 360
            mouse_offset = (int(-t * 26), 0)
            trail_pts = [(int(600 - (k / 50.0) * 200), 360) for k in range(0, i - 60 + 1)]
            hud_text = "⮌  Back (Alt + Left)"
            hud_icon = ICON_L
            hud_high = True
        elif 110 <= i < 230:
            cx, cy = 400, 360
            hud_text = "Google Search Results"
        elif 230 <= i < 280:
            # STRAIGHT RIGHT (FORWARD)
            rmb_pressed = True
            click_type = "right"
            t = (i - 230) / 50.0
            cx = int(400 + t * 200)
            cy = 360
            mouse_offset = (int(t * 26), 0)
            trail_pts = [(int(400 + (k / 50.0) * 200), 360) for k in range(0, i - 230 + 1)]
            hud_text = "⮎  Forward (Alt + Right)"
            hud_icon = ICON_R
            hud_high = True
        elif i >= 280:
            cx, cy = 600, 360
            hud_text = "GitHub Landing Page"

        if len(trail_pts) > 1:
            for w, col in [(8, (6, 182, 212)), (4, (255, 255, 255))]:
                for idx in range(len(trail_pts) - 1):
                    draw.line([trail_pts[idx], trail_pts[idx + 1]], fill=col, width=w)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, hud_icon, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 275, by=HEIGHT - 315, bw=260, bh=300,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_back_forward")

# ==============================================================================
# 2. DEMO 2: TAB SWITCH (720P 60FPS)
# ==============================================================================
def make_demo_tab_switch():
    print("[2/7] Creating demo_tab_switch (720p @ 60 FPS)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (20, 24, 32))
        draw = ImageDraw.Draw(im)

        active_tab = 0
        if 110 <= i < 270:
            active_tab = 1

        draw.rectangle([0, 0, WIDTH, 55], fill=(30, 36, 48))
        tabs_info = [("🔍 Google Search", 0), ("🐙 GestureMouse - GitHub Page", 1)]
        tx = 20
        for t_title, t_idx in tabs_info:
            is_cur = (t_idx == active_tab)
            bg = (20, 24, 32) if is_cur else (38, 46, 60)
            draw.rounded_rectangle([tx, 8, tx + 260, 55], radius=8, fill=bg)
            draw.text((tx + 18, 16), t_title, fill=(240, 245, 250) if is_cur else (160, 170, 185), font=get_font(15, bold=is_cur))
            tx += 270

        draw.rectangle([0, 55, WIDTH, 110], fill=(24, 30, 40))
        draw.rounded_rectangle([70, 62, WIDTH - 70, 102], radius=18, fill=(16, 20, 28), outline=(48, 58, 76))
        urls = [
            "https://www.google.com/search?q=GestureMouse",
            "https://ngtrian.github.io/GestureMouse/"
        ]
        draw.text((90, 71), "🔒", fill=(129, 201, 149), font=get_font(16))
        draw.text((120, 71), urls[active_tab], fill=(210, 220, 235), font=get_font(17))

        if active_tab == 0:
            draw.rectangle([0, 110, WIDTH, HEIGHT], fill=(32, 33, 36))
            draw.text((60, 140), "Google Search", fill=(232, 234, 237), font=get_font(26, bold=True))
            draw.rounded_rectangle([60, 190, WIDTH - 330, 480], radius=14, fill=(40, 42, 46), outline=(60, 64, 70))
            draw.text((90, 220), "🔍 GestureMouse - Smart Mouse Gestures for Windows", fill=(138, 180, 248), font=get_font(20, bold=True))
            draw.text((90, 260), "Download the latest release from the official GitHub Page.", fill=(189, 193, 198), font=get_font(16))
        else:
            draw_github_page(im, draw, scroll_y=0)

        cx, cy = 600, 360
        click_type = None
        rmb_pressed = False
        mouse_offset = (0, 0)
        hud_text = "Tab Navigation"
        hud_icon = None
        hud_high = False
        trail_pts = []

        if 60 <= i < 110:
            # LEFT THEN DOWN (LD -> NEXT TAB)
            rmb_pressed = True
            click_type = "right"
            hud_text = "⮂  Next Tab (Ctrl + Tab)"
            hud_icon = ICON_LD
            hud_high = True

            step = i - 60
            pts_left = [(int(620 - (k / 25.0) * 150), 300) for k in range(26)]
            pts_down = [(470, int(300 + (k / 24.0) * 110)) for k in range(25)]
            if step < 25:
                cx, cy = pts_left[step]
                trail_pts = pts_left[:step + 1]
                mouse_offset = (int(-(step / 25.0) * 26), 0)
            else:
                s2 = min(step - 25, 24)
                cx, cy = pts_down[s2]
                trail_pts = pts_left + pts_down[:s2 + 1]
                mouse_offset = (-26, int((s2 / 24.0) * 22))

        elif 110 <= i < 230:
            cx, cy = 470, 410
            hud_text = "Switched to GitHub Page"

        elif 230 <= i < 280:
            # LEFT THEN UP (LU -> PREV TAB)
            rmb_pressed = True
            click_type = "right"
            hud_text = "⮃  Previous Tab (Ctrl + Shift + Tab)"
            hud_icon = ICON_LU
            hud_high = True

            step = i - 230
            pts_left = [(int(620 - (k / 25.0) * 150), 410) for k in range(26)]
            pts_up = [(470, int(410 - (k / 24.0) * 110)) for k in range(25)]
            if step < 25:
                cx, cy = pts_left[step]
                trail_pts = pts_left[:step + 1]
                mouse_offset = (int(-(step / 25.0) * 26), 0)
            else:
                s2 = min(step - 25, 24)
                cx, cy = pts_up[s2]
                trail_pts = pts_left + pts_up[:s2 + 1]
                mouse_offset = (-26, int(-(s2 / 24.0) * 22))

        elif i >= 280:
            cx, cy = 470, 300
            hud_text = "Switched to Google Search"

        if len(trail_pts) > 1:
            for w, col in [(8, (6, 182, 212)), (4, (255, 255, 255))]:
                for idx in range(len(trail_pts) - 1):
                    draw.line([trail_pts[idx], trail_pts[idx + 1]], fill=col, width=w)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, hud_icon, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 275, by=HEIGHT - 315, bw=260, bh=300,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_tab_switch")

# ==============================================================================
# 3. DEMO 3: CLOSE TAB & RELOAD (720P 60FPS)
# ==============================================================================
def make_demo_close_refresh():
    print("[3/7] Creating demo_close_refresh (720p @ 60 FPS)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (20, 24, 32))
        draw = ImageDraw.Draw(im)

        tab2_closed = (i >= 110)
        reloading = (250 <= i < 290)

        draw.rectangle([0, 0, WIDTH, 55], fill=(30, 36, 48))
        if not tab2_closed:
            draw.rounded_rectangle([20, 8, 270, 55], radius=8, fill=(38, 46, 60))
            draw.text((38, 16), "🔍 Google Search", fill=(160, 170, 185), font=get_font(15))
            
            draw.rounded_rectangle([285, 8, 550, 55], radius=8, fill=(20, 24, 32))
            draw.text((305, 16), "🐙 Active Temporary Tab", fill=(240, 245, 250), font=get_font(15, bold=True))
            draw.text((520, 16), "×", fill=(170, 180, 195), font=get_font(16))
        else:
            draw.rounded_rectangle([20, 8, 320, 55], radius=8, fill=(20, 24, 32))
            draw.text((38, 16), "🐙 GestureMouse - GitHub Page", fill=(240, 245, 250), font=get_font(15, bold=True))

        draw.rectangle([0, 55, WIDTH, 110], fill=(24, 30, 40))
        draw.rounded_rectangle([70, 62, WIDTH - 70, 102], radius=18, fill=(16, 20, 28), outline=(48, 58, 76))
        draw.text((90, 71), "🔒", fill=(129, 201, 149), font=get_font(16))
        page_url = "https://ngtrian.github.io/GestureMouse/" if tab2_closed else "https://temporary-page.org/test"
        draw.text((120, 71), page_url, fill=(210, 220, 235), font=get_font(17))
        draw.text((30, 68), "↻", fill=(6, 182, 212) if reloading else (160, 170, 185), font=get_font(21, bold=True))

        if not tab2_closed:
            draw.rectangle([0, 110, WIDTH, HEIGHT], fill=(20, 24, 34))
            draw.text((70, 150), "Temporary Active Window", fill=(240, 245, 250), font=get_font(24, bold=True))
            draw.rounded_rectangle([70, 200, WIDTH - 330, 500], radius=14, fill=(28, 34, 48), outline=(42, 52, 70))
            draw.text((100, 235), "This active tab will be closed by drawing RU gesture.", fill=(160, 170, 185), font=get_font(18))
        else:
            if reloading:
                draw.rectangle([0, 110, WIDTH, HEIGHT], fill=(11, 15, 25))
                draw.text((WIDTH // 2 - 200, 320), "↻  Reloading GitHub Page...", fill=(6, 182, 212), font=get_font(24, bold=True))
            else:
                draw_github_page(im, draw, scroll_y=0)

        cx, cy = 480, 360
        click_type = None
        rmb_pressed = False
        mouse_offset = (0, 0)
        hud_text = "Close & Reload Gestures"
        hud_icon = None
        hud_high = False
        trail_pts = []

        if 60 <= i < 110:
            # RIGHT THEN UP (RU -> CLOSE TAB)
            rmb_pressed = True
            click_type = "right"
            hud_text = "✕  Close Tab (Ctrl + W)"
            hud_icon = ICON_RU
            hud_high = True

            step = i - 60
            pts_right = [(int(460 + (k / 25.0) * 150), 400) for k in range(26)]
            pts_up = [(610, int(400 - (k / 24.0) * 110)) for k in range(25)]
            if step < 25:
                cx, cy = pts_right[step]
                trail_pts = pts_right[:step + 1]
                mouse_offset = (int((step / 25.0) * 26), 0)
            else:
                s2 = min(step - 25, 24)
                cx, cy = pts_up[s2]
                trail_pts = pts_right + pts_up[:s2 + 1]
                mouse_offset = (26, int(-(s2 / 24.0) * 22))

        elif 110 <= i < 230:
            cx, cy = 610, 290
            hud_text = "Closed Active Tab"

        elif 230 <= i < 280:
            # RIGHT THEN DOWN (RD -> RELOAD)
            rmb_pressed = True
            click_type = "right"
            hud_text = "↻  Reload Page (F5 / Ctrl + R)"
            hud_icon = ICON_RD
            hud_high = True

            step = i - 230
            pts_right = [(int(460 + (k / 25.0) * 150), 300) for k in range(26)]
            pts_down = [(610, int(300 + (k / 24.0) * 110)) for k in range(25)]
            if step < 25:
                cx, cy = pts_right[step]
                trail_pts = pts_right[:step + 1]
                mouse_offset = (int((step / 25.0) * 26), 0)
            else:
                s2 = min(step - 25, 24)
                cx, cy = pts_down[s2]
                trail_pts = pts_right + pts_down[:s2 + 1]
                mouse_offset = (26, int((s2 / 24.0) * 22))

        elif i >= 280:
            cx, cy = 610, 410
            hud_text = "GitHub Page Reloaded"

        if len(trail_pts) > 1:
            for w, col in [(8, (6, 182, 212)), (4, (255, 255, 255))]:
                for idx in range(len(trail_pts) - 1):
                    draw.line([trail_pts[idx], trail_pts[idx + 1]], fill=col, width=w)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, hud_icon, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 275, by=HEIGHT - 315, bw=260, bh=300,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_close_refresh")

# ==============================================================================
# 4. DEMO 4: KINETIC FLING SCROLL (720P 60FPS)
# ==============================================================================
def make_demo_kinetic_scroll():
    print("[4/7] Creating demo_kinetic_scroll (720p @ 60 FPS Smartphone Physics)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    scroll_pos = 0.0
    velocity_y = 0.0

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (11, 15, 25))
        draw = ImageDraw.Draw(im)

        rmb_pressed = False
        click_type = None
        mouse_offset = (0, 0)
        cx = 520
        cy = 320
        hud_text = "Kinetic Fling Scroll"
        hud_high = False

        # Phase 1: Downward Fling (0 - 180 frames = 3.0s)
        if i < 30:
            scroll_pos = 0.0
            velocity_y = 0.0
            cx, cy = 520, 260
            hud_text = "Kinetic Inertial Scroll"
            
        elif 30 <= i < 65:
            # Touch & Swipe Down with Acceleration
            rmb_pressed = True
            click_type = "right"
            t = (i - 30) / 35.0
            swipe_accel = t ** 1.8
            cx = 520
            cy = int(260 + swipe_accel * 160)
            mouse_offset = (0, int(swipe_accel * 28))
            
            scroll_pos = swipe_accel * 120.0
            velocity_y = 28.0
            
            hud_text = "👇  Flick Down ➔ Release to Coast"
            hud_high = True

        elif 65 <= i < 180:
            # Release -> Deep Kinetic Coasting to ~1020px with organic friction decay
            rmb_pressed = False
            cx, cy = 520, 420
            mouse_offset = (0, 0)
            
            scroll_pos += velocity_y
            velocity_y *= 0.970  # Gentle friction
            
            hud_text = "🌊  Inertial Auto-Scrolling"
            hud_high = True

        # Phase 2: Upward Fling - Short, Gentle, Stopping with Ample Headroom (180 - 360 frames = 3.0s)
        elif 180 <= i < 205:
            cx, cy = 520, 420
            velocity_y = 0.0
            mouse_offset = (0, 0)
            hud_text = "Kinetic Inertial Scroll"

        elif 205 <= i < 235:
            # Touch & Short Gentle Flick Upward (~90px motion)
            rmb_pressed = True
            click_type = "right"
            t = (i - 205) / 30.0
            swipe_accel = t ** 1.6
            cx = 520
            cy = int(420 - swipe_accel * 90)
            mouse_offset = (0, int(-swipe_accel * 18))
            
            scroll_pos = 1019.0 - swipe_accel * 70.0
            velocity_y = -19.5
            
            hud_text = "👆  Gentle Short Flick Upward"
            hud_high = True

        else:
            # Release -> Smooth soft coasting, coming to rest around ~317px without touching top!
            rmb_pressed = False
            cx, cy = 520, 330
            mouse_offset = (0, 0)
            
            scroll_pos += velocity_y
            velocity_y *= 0.970
            
            hud_text = "🌊  Smooth Inertial Coasting"
            hud_high = True

        draw_github_page(im, draw, scroll_y=scroll_pos)

        # Scrollbar
        draw_browser_scrollbar(draw, scroll_y=scroll_pos, max_scroll=1400.0, active=(rmb_pressed or abs(velocity_y) > 0.5))

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 275, by=HEIGHT - 315, bw=260, bh=300,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_kinetic_scroll")

# ==============================================================================
# 5. DEMO 5: DRAG SCROLL (720P 60FPS)
# ==============================================================================
def make_demo_drag_scroll():
    print("[5/7] Creating demo_drag_scroll (720p @ 60 FPS)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (11, 15, 25))
        draw = ImageDraw.Draw(im)

        rmb_pressed = False
        click_type = None
        scroll_y = 0.0
        cx = 520
        cy = 260
        mouse_offset = (0, 0)
        hud_text = "Direct Drag Scroll"
        hud_high = False

        if 60 <= i < 160:
            rmb_pressed = True
            click_type = "right"
            t = (i - 60) / 100.0
            cy = int(260 + t * 190)
            scroll_y = t * 580.0
            mouse_offset = (0, int(t * 36))
            hud_text = "🖐️  Drag Down -> Scroll Down"
            hud_high = True
        elif 160 <= i < 220:
            cy = 450
            scroll_y = 580.0
            hud_text = "Position Maintained"
        elif 220 <= i < 320:
            rmb_pressed = True
            click_type = "right"
            t = (i - 220) / 100.0
            cy = int(450 - t * 190)
            scroll_y = 580.0 - t * 580.0
            mouse_offset = (0, int(36 - t * 36))
            hud_text = "🖐️  Drag Up -> Scroll Up"
            hud_high = True
        elif i >= 320:
            cy = 260
            scroll_y = 0.0
            hud_text = "Returned to Top"

        draw_github_page(im, draw, scroll_y=scroll_y)
        draw_browser_scrollbar(draw, scroll_y=scroll_y, max_scroll=580.0, active=rmb_pressed)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 275, by=HEIGHT - 315, bw=260, bh=300,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_drag_scroll")

# ==============================================================================
# 6. DEMO 6: PAGE UP / PAGE DOWN (720P 60FPS)
# ==============================================================================
def make_demo_pgup_pgdn():
    print("[6/7] Creating demo_pgup_pgdn (720p @ 60 FPS)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (11, 15, 25))
        draw = ImageDraw.Draw(im)

        scroll_y = 0
        hud_text = "Page Navigation"
        hud_high = False
        rmb_pressed = False
        wheel_dir = 0

        if i < 80:
            if 60 <= i < 80:
                t = (i - 60) / 20.0
                scroll_y = int(t * 550)
                rmb_pressed = True
                wheel_dir = -1
                hud_text = "⮟  Page Down (PgDn)"
                hud_high = True
            else:
                scroll_y = 0
                hud_text = "Page 1: Hero Section"
        elif 80 <= i < 140:
            if 120 <= i < 140:
                t = (i - 120) / 20.0
                scroll_y = int(550 + t * 550)
                rmb_pressed = True
                wheel_dir = -1
                hud_text = "⮟  Page Down (PgDn)"
                hud_high = True
            else:
                scroll_y = 550
                hud_text = "Page 2: Key Features"
        elif 140 <= i < 260:
            if 240 <= i < 260:
                t = (i - 240) / 20.0
                scroll_y = int(1100 - t * 550)
                rmb_pressed = True
                wheel_dir = 1
                hud_text = "⮝  Page Up (PgUp)"
                hud_high = True
            else:
                scroll_y = 1100
                hud_text = "Page 3: Gestures Showcase"
        elif 260 <= i < 320:
            if 300 <= i < 320:
                t = (i - 300) / 20.0
                scroll_y = int(550 - t * 550)
                rmb_pressed = True
                wheel_dir = 1
                hud_text = "⮝  Page Up (PgUp)"
                hud_high = True
            else:
                scroll_y = 550
                hud_text = "Page 2: Key Features"
        else:
            scroll_y = 0
            hud_text = "Page 1: Hero Section"

        draw_github_page(im, draw, scroll_y=scroll_y)
        draw_browser_scrollbar(draw, scroll_y=scroll_y, max_scroll=1100.0, active=rmb_pressed)

        page_num = 1 if scroll_y < 275 else (2 if scroll_y < 825 else 3)
        draw.rounded_rectangle([WIDTH - 500, 62, WIDTH - 340, 102], radius=12, fill=(24, 32, 46), outline=(48, 60, 80))
        draw.text((WIDTH - 480, 71), f"Page {page_num} of 3", fill=(103, 232, 249), font=get_font(16, bold=True))

        draw_cursor(draw, 500, 360, "right" if rmb_pressed else None)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 275, by=HEIGHT - 315, bw=260, bh=300,
                                lmb=False, rmb=rmb_pressed, wheel_dir=wheel_dir,
                                mouse_offset=(0, 0), frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_pgup_pgdn")

# ==============================================================================
# 7. DEMO 7: VOLUME ADJUSTMENT (720P 60FPS)
# ==============================================================================
def make_demo_volume():
    print("[7/7] Creating demo_volume (720p @ 60 FPS)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (14, 18, 26))
        draw = ImageDraw.Draw(im)

        vol = 35
        lmb_pressed = False
        wheel_dir = 0
        hud_text = "Rocker Volume Control"
        hud_high = False

        if 60 <= i < 160:
            lmb_pressed = True
            wheel_dir = 1
            t = (i - 60) / 100.0
            vol = int(35 + t * 50)
            hud_text = f"🔊  Volume Up ▲ ({vol}%)"
            hud_high = True
        elif 160 <= i < 220:
            vol = 85
            hud_text = f"Volume Set to 85%"
        elif 220 <= i < 320:
            lmb_pressed = True
            wheel_dir = -1
            t = (i - 220) / 100.0
            vol = int(85 - t * 65)
            hud_text = f"🔉  Volume Down ▼ ({vol}%)"
            hud_high = True
        elif i >= 320:
            vol = 20
            hud_text = "Volume Set to 20%"

        draw.rectangle([0, 0, WIDTH, 75], fill=(22, 28, 38))
        draw.text((35, 21), "▶  YouTube Music — Lo-Fi Chill Coding Sessions", fill=(240, 245, 250), font=get_font(19, bold=True))

        draw.rounded_rectangle([50, 110, WIDTH - 340, 560], radius=20, fill=(20, 26, 36), outline=(38, 48, 66))
        draw.rounded_rectangle([95, 155, 305, 365], radius=14, fill=(35, 48, 70))
        draw.text((160, 220), "🎵", fill=(96, 165, 250), font=get_font(60))

        draw.text((345, 170), "Lo-Fi Beats to Relax / Study / Code", fill=(249, 250, 251), font=get_font(22, bold=True))
        draw.text((345, 215), "Adjust master audio instantly without leaving your active window", fill=(156, 163, 175), font=get_font(16))
        
        draw.rounded_rectangle([345, 275, 800, 285], radius=5, fill=(45, 55, 70))
        draw.rounded_rectangle([345, 275, 610, 285], radius=5, fill=(37, 99, 235))
        draw.ellipse([604, 272, 616, 288], fill=(255, 255, 255))
        draw.text((345, 300), "03:15 / 05:00", fill=(130, 145, 165), font=get_font(14))

        if lmb_pressed or (160 <= i < 190):
            osd_x, osd_y = 345, 350
            draw.rounded_rectangle([osd_x, osd_y, osd_x + 400, osd_y + 115], radius=16,
                                   fill=(13, 20, 32, 250), outline=(6, 182, 212), width=2)
            draw.text((osd_x + 25, osd_y + 20), "🔊", fill=(255, 255, 255), font=get_font(28))
            draw.text((osd_x + 75, osd_y + 23), f"Volume: {vol}%", fill=(240, 248, 255), font=get_font(19, bold=True))
            
            bar_w = 340
            cur_w = int(bar_w * (vol / 100.0))
            draw.rounded_rectangle([osd_x + 25, osd_y + 68, osd_x + 25 + bar_w, osd_y + 82], radius=7, fill=(35, 45, 62))
            draw.rounded_rectangle([osd_x + 25, osd_y + 68, osd_x + 25 + cur_w, osd_y + 82], radius=7, fill=(0, 229, 255))

        draw_cursor(draw, 500, 380, "left" if lmb_pressed else None)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 275, by=HEIGHT - 315, bw=260, bh=300,
                                lmb=lmb_pressed, rmb=False, wheel_dir=wheel_dir,
                                mouse_offset=(0, 0), frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_volume")

# ==============================================================================
# MAIN
# ==============================================================================
if __name__ == "__main__":
    targets = [t.lower() for t in sys.argv[1:]] if len(sys.argv) > 1 else ["all"]
    print(f"=== PRODUCING VISUAL DEMOS V6.0 (Targets: {targets}) ===")
    if "all" in targets or "back" in targets: make_demo_back_forward()
    if "all" in targets or "tab" in targets: make_demo_tab_switch()
    if "all" in targets or "close" in targets: make_demo_close_refresh()
    if "all" in targets or "kinetic" in targets: make_demo_kinetic_scroll()
    if "all" in targets or "drag" in targets: make_demo_drag_scroll()
    if "all" in targets or "pgup" in targets: make_demo_pgup_pgdn()
    if "all" in targets or "volume" in targets: make_demo_volume()
    if os.path.exists(TEMP_FRAME_DIR):
        shutil.rmtree(TEMP_FRAME_DIR)
    print("=== SELECTED DEMOS COMPLETED SUCCESSFULLY ===")
