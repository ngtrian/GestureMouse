# -*- coding: utf-8 -*-
"""
GestureMouse Visual Generator v5.0
100% English UI, 6-second clips (180 frames @ 30 FPS).
- Top-center concise large HUD (above gesture area, no description clutter).
- Clean Cyber Mouse Widget (no text clutter).
- Shorter, natural straight Back & Forward strokes.
- GitHub Page content used for:
  - PgUp / PgDn leaping across 3 real pages (Hero -> Features -> Gestures Table).
  - Tab switching between Google Search and GitHub Page.
  - Close Tab (closes active tab) & Reload (reloading flash/spinner).
- Kinetic Scroll: Hold RMB -> FLICK/SWIPE mouse -> RELEASE RMB -> Flings with momentum! Move mouse to brake.
- Drag Scroll: Cursor moves with mouse, drag down = content down, drag up = content up.
- Volume: Rocker Volume.
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

WIDTH = 854
HEIGHT = 480
FPS = 30
TOTAL_FRAMES = 180  # 6.0 seconds

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

# Load icons
LOGO_IMG = None
ICON_L = None
ICON_R = None
ICON_LU = None
ICON_LD = None
ICON_RU = None
ICON_RD = None
try:
    if os.path.exists("image/unnamed.png"):
        LOGO_IMG = Image.open("image/unnamed.png").convert("RGBA").resize((26, 26))
    if os.path.exists("image/L.ico"):
        ICON_L = Image.open("image/L.ico").convert("RGBA").resize((22, 22))
    if os.path.exists("image/R.ico"):
        ICON_R = Image.open("image/R.ico").convert("RGBA").resize((22, 22))
    if os.path.exists("image/LU.ico"):
        ICON_LU = Image.open("image/LU.ico").convert("RGBA").resize((22, 22))
    if os.path.exists("image/LD.ico"):
        ICON_LD = Image.open("image/LD.ico").convert("RGBA").resize((22, 22))
    if os.path.exists("image/RU.ico"):
        ICON_RU = Image.open("image/RU.ico").convert("RGBA").resize((22, 22))
    if os.path.exists("image/RD.ico"):
        ICON_RD = Image.open("image/RD.ico").convert("RGBA").resize((22, 22))
except Exception:
    pass

# ==============================================================================
# TOP-CENTER CONCISE LARGE HUD (ABOVE GESTURE, NO ACTION TEXT)
# ==============================================================================
def draw_top_hud(im, draw, text, icon=None, highlight=False):
    """
    Vẽ HUD to, ngắn gọn, đặt ở trên cử chỉ (ngay dưới thanh địa chỉ, căn giữa).
    Không có chữ mô tả thừa, nổi bật, dễ nhìn.
    """
    font = get_font(15, bold=True)
    full_text = text
    bbox = font.getbbox(full_text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    
    pad_x = 24
    if icon:
        pad_x += 28
    
    bw = tw + pad_x * 2
    bh = 38
    bx = (WIDTH - 190) // 2 - bw // 2 + 10
    by = 84  # Nằm phía trên vùng vẽ cử chỉ
    
    bd_col = (6, 182, 212) if highlight else (55, 68, 88)
    bg_col = (13, 20, 32, 245) if highlight else (16, 22, 32, 235)
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=10,
                           fill=bg_col, outline=bd_col, width=2 if highlight else 1)
    
    tx = bx + 24
    if icon:
        im.paste(icon, (bx + 16, by + 8), icon)
        tx = bx + 48
        
    text_col = (255, 255, 255) if highlight else (210, 220, 235)
    draw.text((tx, by + 8), full_text, fill=text_col, font=font)

# ==============================================================================
# CLEAN MINIMALIST CYBER MOUSE WIDGET (NO TEXT)
# ==============================================================================
def draw_clean_mouse_widget(draw, bx, by, bw=180, bh=210,
                            lmb=False, rmb=False, wheel_dir=0,
                            mouse_offset=(0, 0), frame_idx=0):
    """Widget chuột công thái học cao cấp không chữ rác."""
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=16,
                           fill=(11, 15, 23, 235), outline=(38, 48, 65), width=1)
    
    pad_x = bx + 10
    pad_y = by + 10
    pad_w = bw - 20
    pad_h = bh - 20
    draw.rounded_rectangle([pad_x, pad_y, pad_x + pad_w, pad_y + pad_h], radius=12,
                           fill=(7, 10, 16), outline=(24, 32, 44), width=1)
    
    for gx in range(pad_x + 18, pad_x + pad_w, 22):
        draw.line([(gx, pad_y + 4), (gx, pad_y + pad_h - 4)], fill=(15, 20, 28), width=1)
    for gy in range(pad_y + 18, pad_y + pad_h, 22):
        draw.line([(pad_x + 4, gy), (pad_x + pad_w - 4, gy)], fill=(15, 20, 28), width=1)

    mx = pad_x + pad_w // 2 + mouse_offset[0]
    my = pad_y + pad_h // 2 + mouse_offset[1]
    
    mw = 76
    mh = 126

    draw.rounded_rectangle([mx - mw//2 + 2, my - mh//2 + 5, mx + mw//2 + 2, my + mh//2 + 5],
                           radius=32, fill=(3, 5, 8))

    led_col = (6, 182, 212) if rmb else ((37, 99, 235) if lmb else (42, 54, 72))
    draw.rounded_rectangle([mx - mw//2 - 2, my - mh//2 - 2, mx + mw//2 + 2, my + mh//2 + 2],
                           radius=34, outline=led_col, width=1)

    draw.rounded_rectangle([mx - mw//2, my - mh//2, mx + mw//2, my + mh//2],
                           radius=32, fill=(20, 26, 36), outline=(45, 56, 74), width=1)

    for gy in range(my - 12, my + 30, 8):
        draw.line([(mx - mw//2 + 3, gy), (mx - mw//2 + 7, gy)], fill=(36, 46, 62), width=2)
        draw.line([(mx + mw//2 - 7, gy), (mx + mw//2 - 3, gy)], fill=(36, 46, 62), width=2)

    # Nút Trái
    lmb_top = my - mh//2 + 4
    lmb_bot = my - 10
    lmb_left = mx - mw//2 + 5
    lmb_right = mx - 3
    if lmb:
        draw.rounded_rectangle([lmb_left, lmb_top + 2, lmb_right, lmb_bot + 2], radius=10,
                               fill=(29, 78, 216), outline=(96, 165, 250), width=2)
    else:
        draw.rounded_rectangle([lmb_left, lmb_top, lmb_right, lmb_bot], radius=10,
                               fill=(32, 40, 54), outline=(48, 60, 80), width=1)

    # Nút Phải
    rmb_top = my - mh//2 + 4
    rmb_bot = my - 10
    rmb_left = mx + 3
    rmb_right = mx + mw//2 - 5
    if rmb:
        draw.rounded_rectangle([rmb_left, rmb_top + 2, rmb_right, rmb_bot + 2], radius=10,
                               fill=(8, 145, 178), outline=(103, 232, 249), width=2)
    else:
        draw.rounded_rectangle([rmb_left, rmb_top, rmb_right, rmb_bot], radius=10,
                               fill=(32, 40, 54), outline=(48, 60, 80), width=1)

    # Con lăn
    ww = 14
    wh = 36
    wx = mx - ww // 2
    wy = my - mh // 2 + 10
    wheel_active = (wheel_dir != 0)
    wheel_bg = (6, 182, 212) if wheel_active else (15, 20, 28)
    wheel_bd = (255, 255, 255) if wheel_active else (65, 78, 98)
    draw.rounded_rectangle([wx, wy, wx + ww, wy + wh], radius=5, fill=wheel_bg, outline=wheel_bd, width=1)

    groove_offset = (frame_idx * 3) % 8 if wheel_active else 0
    for gy in range(wy + 3, wy + wh - 2, 7):
        gy_anim = gy + (groove_offset if wheel_dir < 0 else -groove_offset)
        if wy + 2 <= gy_anim <= wy + wh - 3:
            line_col = (10, 25, 35) if wheel_active else (42, 52, 68)
            draw.line([(wx + 2, gy_anim), (wx + ww - 2, gy_anim)], fill=line_col, width=1)

    if wheel_dir > 0:
        draw.text((mx - 5, wy - 11), "▲", fill=(6, 182, 212), font=get_font(10, bold=True))
    elif wheel_dir < 0:
        draw.text((mx - 5, wy + wh + 1), "▼", fill=(6, 182, 212), font=get_font(10, bold=True))

    draw.ellipse([mx - 9, my + mh//4 - 2, mx + 9, my + mh//4 + 16], fill=(26, 34, 46))
    draw.text((mx - 4, my + mh//4), "G", fill=(6, 182, 212), font=get_font(10, bold=True))

# ==============================================================================
# GITHUB PAGE RENDERING (AUTHENTIC GESTUREMOUSE GITHUB LANDING PAGE)
# ==============================================================================
def draw_github_page(im, draw, scroll_y=0):
    """
    Vẽ trang web GestureMouse GitHub Page chuẩn:
    - Section 1 (scroll_y = 0): Hero, Logo, Title, Winget Box
    - Section 2 (scroll_y ~ 380): Key Features (Kinetic Scroll, Gestures, Rocker Volume, UIAccess)
    - Section 3 (scroll_y ~ 760): Gestures Showcase (Default Gestures with real icons)
    """
    sy = -int(scroll_y)
    draw.rectangle([0, 75, WIDTH, HEIGHT], fill=(11, 15, 25))

    # --- SECTION 1: HERO (0 - 380) ---
    s1_y = sy + 85
    if s1_y + 360 >= 75 and s1_y <= HEIGHT:
        if LOGO_IMG:
            im.paste(LOGO_IMG, (45, s1_y + 10), LOGO_IMG)
        draw.text((78, s1_y + 12), "GestureMouse — Smart Mouse Utility", fill=(240, 245, 250), font=get_font(15, bold=True))
        
        # Hero Box
        draw.rounded_rectangle([45, s1_y + 45, WIDTH - 235, s1_y + 320], radius=12, fill=(19, 25, 36), outline=(38, 48, 66))
        draw.text((65, s1_y + 65), "Supercharge Your Windows Mouse Experience", fill=(103, 232, 249), font=get_font(17, bold=True))
        draw.text((65, s1_y + 98), "Fluid kinetic inertial scrolling & rapid right-click gestures for Windows.", fill=(160, 170, 185), font=get_font(12))
        
        # Winget install box
        draw.rounded_rectangle([65, s1_y + 135, WIDTH - 280, s1_y + 180], radius=8, fill=(13, 17, 23), outline=(48, 54, 61))
        draw.text((80, s1_y + 148), "PS > winget install GestureMouse", fill=(103, 232, 249), font=get_font(12, code=True))
        draw.text((WIDTH - 310, s1_y + 148), "📋", fill=(160, 170, 185), font=get_font(12))

        # Highlights
        draw.text((65, s1_y + 205), "✔  100% Free & Open Source on GitHub", fill=(129, 201, 149), font=get_font(12, bold=True))
        draw.text((65, s1_y + 232), "✔  Ultra-lightweight: Uses less than 15MB RAM", fill=(129, 201, 149), font=get_font(12, bold=True))
        draw.text((65, s1_y + 258), "✔  Portable zero-install standalone executable", fill=(129, 201, 149), font=get_font(12, bold=True))

    # --- SECTION 2: KEY FEATURES (380 - 760) ---
    s2_y = sy + 440
    if s2_y + 360 >= 75 and s2_y <= HEIGHT:
        draw.text((45, s2_y), "Key Features & Capabilities", fill=(240, 245, 250), font=get_font(16, bold=True))
        cards = [
            ("🌊 Kinetic Smooth Scroll", "Simulates iOS touchscreen inertia at 60 FPS without eye strain."),
            ("⚡ Right-Click Gestures", "Instant Back, Forward, Switch Tab, and Close Tab actions."),
            ("🔊 Rocker Volume Master", "Hold Left Mouse Button + Scroll Wheel to adjust volume instantly."),
            ("🛡️ Elevated UIAccess", "Seamlessly controls elevated windows like Task Manager safely.")
        ]
        for c_idx, (c_title, c_desc) in enumerate(cards):
            cy = s2_y + 35 + c_idx * 68
            draw.rounded_rectangle([45, cy, WIDTH - 235, cy + 58], radius=8, fill=(19, 25, 36), outline=(38, 48, 66))
            draw.text((60, cy + 10), c_title, fill=(103, 232, 249), font=get_font(12, bold=True))
            draw.text((60, cy + 32), c_desc, fill=(160, 170, 185), font=get_font(11))

    # --- SECTION 3: DEFAULT GESTURES SHOWCASE (760 - 1140) ---
    s3_y = sy + 800
    if s3_y + 360 >= 75 and s3_y <= HEIGHT:
        draw.text((45, s3_y), "Default Gestures Showcase", fill=(240, 245, 250), font=get_font(16, bold=True))
        draw.text((45, s3_y + 24), "Hold Right Mouse Button and glide in the specified direction", fill=(156, 163, 175), font=get_font(11))
        
        gest_list = [
            ("Back (Alt + Left)", "Straight Left ←", ICON_L),
            ("Forward (Alt + Right)", "Straight Right →", ICON_R),
            ("Next Tab (Ctrl + Tab)", "Left then Down ← ↓", ICON_LD),
            ("Previous Tab (Ctrl + Shift + Tab)", "Left then Up ← ↑", ICON_LU),
            ("Close Tab (Ctrl + W)", "Right then Up → ↑", ICON_RU),
            ("Reload Page (F5 / Ctrl + R)", "Right then Down → ↓", ICON_RD)
        ]
        for g_idx, (g_title, g_desc, g_ico) in enumerate(gest_list):
            gy = s3_y + 50 + g_idx * 48
            draw.rounded_rectangle([45, gy, WIDTH - 235, gy + 42], radius=8, fill=(19, 25, 36), outline=(38, 48, 66))
            if g_ico:
                im.paste(g_ico, (55, gy + 10), g_ico)
            draw.text((85, gy + 12), g_title, fill=(240, 245, 250), font=get_font(11, bold=True))
            draw.text((WIDTH - 420, gy + 12), g_desc, fill=(6, 182, 212), font=get_font(11, bold=True))

    # --- SECTION 4: QUICK INSTALLATION & SETUP (1140 - 1520) ---
    s4_y = sy + 1160
    if s4_y + 360 >= 75 and s4_y <= HEIGHT:
        draw.text((45, s4_y), "Quick 10-Second Installation", fill=(240, 245, 250), font=get_font(16, bold=True))
        steps = [
            ("1. Download Release", "Grab the latest GestureMouse-v1.0.0-Portable.zip from GitHub Releases."),
            ("2. Zero Configuration", "Extract anywhere and run GestureMouse.exe with standard user rights."),
            ("3. Optional UIAccess", "Right-click tray icon and enable UIAccess for elevated Task Manager control.")
        ]
        for st_idx, (st_title, st_desc) in enumerate(steps):
            sty = s4_y + 35 + st_idx * 64
            draw.rounded_rectangle([45, sty, WIDTH - 235, sty + 54], radius=8, fill=(19, 25, 36), outline=(38, 48, 66))
            draw.text((60, sty + 10), st_title, fill=(129, 201, 149), font=get_font(12, bold=True))
            draw.text((60, sty + 30), st_desc, fill=(160, 170, 185), font=get_font(11))

def draw_cursor(draw, x, y, click_type=None):
    if click_type == "right":
        draw.ellipse([x - 16, y - 16, x + 16, y + 16], fill=(6, 182, 212, 100), outline=(103, 232, 249), width=2)
    elif click_type == "left":
        draw.ellipse([x - 16, y - 16, x + 16, y + 16], fill=(37, 99, 235, 100), outline=(96, 165, 250), width=2)

    points = [
        (x, y),
        (x, y + 20),
        (x + 5, y + 15),
        (x + 11, y + 24),
        (x + 14, y + 22),
        (x + 9, y + 14),
        (x + 16, y + 14)
    ]
    draw.polygon(points, fill=(255, 255, 255), outline=(15, 15, 15))

def render_frames_to_media(base_name, fps=FPS):
    for out_dir in OUTPUT_DIRS:
        os.makedirs(out_dir, exist_ok=True)
        gif_path = os.path.join(out_dir, f"{base_name}.gif")
        mp4_path = os.path.join(out_dir, f"{base_name}.mp4")

        palette_cmd = [
            "ffmpeg", "-y", "-framerate", str(fps),
            "-i", os.path.join(TEMP_FRAME_DIR, "frame_%04d.png"),
            "-vf", f"fps={fps},split[s0][s1];[s0]palettegen=max_colors=128:reserve_transparent=0[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3",
            gif_path
        ]
        subprocess.run(palette_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        mp4_cmd = [
            "ffmpeg", "-y", "-framerate", str(fps),
            "-i", os.path.join(TEMP_FRAME_DIR, "frame_%04d.png"),
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "medium",
            mp4_path
        ]
        subprocess.run(mp4_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    print(f"  ==> Successfully created: {base_name}.gif & {base_name}.mp4")

# ==============================================================================
# 1. DEMO 1: BACK & FORWARD (SHORTER NATURAL STRAIGHT STROKES)
# ==============================================================================
def make_demo_back_forward():
    print("[1/7] Creating demo_back_forward (Shorter straight strokes)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (32, 33, 36))
        draw = ImageDraw.Draw(im)

        # 0-30: Viewing GitHub Page
        # 30-65: Draw Straight Left (Stroke ~120px) -> BACK to Google Search
        # 65-115: Viewing Google Search
        # 115-150: Draw Straight Right (Stroke ~120px) -> FORWARD to GitHub Page
        # 150-180: Viewing GitHub Page

        is_search = (55 <= i < 135)
        back_active = (45 <= i < 58)
        fwd_active = (130 <= i < 142)

        # Browser Header
        draw.rectangle([0, 0, WIDTH, 75], fill=(41, 42, 45))
        draw.text((16, 44), "←", fill=(6, 182, 212) if back_active else (180, 190, 205), font=get_font(18, bold=True))
        draw.text((44, 44), "→", fill=(6, 182, 212) if fwd_active else (180, 190, 205), font=get_font(18, bold=True))
        draw.text((72, 44), "↻", fill=(180, 190, 205), font=get_font(16))
        
        draw.rounded_rectangle([100, 40, WIDTH - 40, 68], radius=14, fill=(32, 33, 36), outline=(60, 64, 67))
        curr_url = "https://www.google.com/search?q=GestureMouse" if is_search else "https://ngtrian.github.io/GestureMouse/"
        draw.text((115, 45), "🔒", fill=(129, 201, 149), font=get_font(12))
        draw.text((135, 47), curr_url, fill=(220, 225, 230), font=get_font(12))

        # Content
        if is_search:
            draw.rectangle([0, 75, WIDTH, HEIGHT], fill=(32, 33, 36))
            draw.text((45, 95), "Google", fill=(232, 234, 237), font=get_font(20, bold=True))
            draw.rounded_rectangle([130, 92, 540, 126], radius=17, fill=(48, 49, 52), outline=(95, 99, 104))
            draw.text((150, 99), "GestureMouse Windows", fill=(232, 234, 237), font=get_font(13))
            draw.text((515, 99), "🔍", fill=(154, 160, 166), font=get_font(12))

            draw.text((45, 145), "https://ngtrian.github.io › GestureMouse", fill=(189, 193, 198), font=get_font(11))
            draw.text((45, 165), "GestureMouse - Smart Mouse Gestures for Windows", fill=(138, 180, 248), font=get_font(15, bold=True))
            draw.text((45, 192), "Smart right-click mouse gestures and fluid inertial kinetic scrolling.", fill=(189, 193, 198), font=get_font(12))
            draw.text((45, 212), "Lightweight (< 15MB RAM), fully open-source and portable.", fill=(189, 193, 198), font=get_font(12))
        else:
            draw_github_page(im, draw, scroll_y=0)

        # ANIMATION: NATURAL 120PX STROKE
        cx, cy = 400, 240
        click_type = None
        rmb_pressed = False
        mouse_offset = (0, 0)
        hud_text = "Gesture Navigation"
        hud_icon = None
        hud_high = False
        trail_pts = []

        if 30 <= i < 55:
            # STRAIGHT LEFT 120PX
            rmb_pressed = True
            click_type = "right"
            t = (i - 30) / 25.0
            cx = int(400 - t * 130)
            cy = 240
            mouse_offset = (int(-t * 18), 0)
            trail_pts = [(int(400 - (k / 25.0) * 130), 240) for k in range(0, i - 30 + 1)]
            hud_text = "⮌  Back (Alt + Left)"
            hud_icon = ICON_L
            hud_high = True
        elif 55 <= i < 115:
            cx, cy = 270, 240
            hud_text = "Google Search Results"
        elif 115 <= i < 140:
            # STRAIGHT RIGHT 120PX
            rmb_pressed = True
            click_type = "right"
            t = (i - 115) / 25.0
            cx = int(270 + t * 130)
            cy = 240
            mouse_offset = (int(t * 18), 0)
            trail_pts = [(int(270 + (k / 25.0) * 130), 240) for k in range(0, i - 115 + 1)]
            hud_text = "⮎  Forward (Alt + Right)"
            hud_icon = ICON_R
            hud_high = True
        elif i >= 140:
            cx, cy = 400, 240
            hud_text = "GitHub Landing Page"

        if len(trail_pts) > 1:
            for w, col in [(6, (6, 182, 212)), (3, (255, 255, 255))]:
                for idx in range(len(trail_pts) - 1):
                    draw.line([trail_pts[idx], trail_pts[idx + 1]], fill=col, width=w)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, hud_icon, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 195, by=HEIGHT - 225, bw=185, bh=215,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_back_forward")

# ==============================================================================
# 2. DEMO 2: TAB SWITCH (GOOGLE SEARCH <-> GITHUB PAGE)
# ==============================================================================
def make_demo_tab_switch():
    print("[2/7] Creating demo_tab_switch (Google Search <-> GitHub Page)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (20, 24, 32))
        draw = ImageDraw.Draw(im)

        # 0-35: Tab 0 (Google Search)
        # 35-75: Draw Left then Down (LD) -> Switch to Tab 1 (GestureMouse GitHub Page)
        # 75-115: Viewing Tab 1 (GitHub Page)
        # 115-155: Draw Left then Up (LU) -> Switch back to Tab 0 (Google Search)
        # 155-180: Viewing Tab 0

        active_tab = 0
        if 55 <= i < 135:
            active_tab = 1

        # Tab Bar
        draw.rectangle([0, 0, WIDTH, 38], fill=(30, 36, 48))
        tabs_info = [("🔍 Google Search", 0), ("🐙 GestureMouse - GitHub Page", 1)]
        tx = 15
        for t_title, t_idx in tabs_info:
            is_cur = (t_idx == active_tab)
            bg = (20, 24, 32) if is_cur else (38, 46, 60)
            draw.rounded_rectangle([tx, 6, tx + 180, 38], radius=6, fill=bg)
            draw.text((tx + 12, 12), t_title, fill=(240, 245, 250) if is_cur else (160, 170, 185), font=get_font(10, bold=is_cur))
            tx += 186

        # Address bar
        draw.rectangle([0, 38, WIDTH, 75], fill=(24, 30, 40))
        draw.rounded_rectangle([50, 44, WIDTH - 50, 70], radius=13, fill=(16, 20, 28), outline=(48, 58, 76))
        urls = [
            "https://www.google.com/search?q=GestureMouse",
            "https://ngtrian.github.io/GestureMouse/"
        ]
        draw.text((65, 50), "🔒", fill=(129, 201, 149), font=get_font(11))
        draw.text((85, 50), urls[active_tab], fill=(210, 220, 235), font=get_font(12))

        # Content
        if active_tab == 0:
            draw.rectangle([0, 75, WIDTH, HEIGHT], fill=(32, 33, 36))
            draw.text((45, 95), "Google Search", fill=(232, 234, 237), font=get_font(18, bold=True))
            draw.rounded_rectangle([45, 130, WIDTH - 235, 340], radius=10, fill=(40, 42, 46), outline=(60, 64, 70))
            draw.text((65, 150), "🔍 GestureMouse - Smart Mouse Gestures for Windows", fill=(138, 180, 248), font=get_font(14, bold=True))
            draw.text((65, 180), "Download the latest release from the official GitHub Page.", fill=(189, 193, 198), font=get_font(12))
        else:
            draw_github_page(im, draw, scroll_y=0)

        # ANIMATION: DRAW LEFT THEN DOWN (LD) & LEFT THEN UP (LU)
        cx, cy = 400, 230
        click_type = None
        rmb_pressed = False
        mouse_offset = (0, 0)
        hud_text = "Tab Navigation"
        hud_icon = None
        hud_high = False
        trail_pts = []

        if 30 <= i < 60:
            # DRAW LEFT THEN DOWN (LD -> NEXT TAB)
            rmb_pressed = True
            click_type = "right"
            hud_text = "⮂  Next Tab (Ctrl + Tab)"
            hud_icon = ICON_LD
            hud_high = True

            step = i - 30
            pts_left = [(int(420 - (k / 15.0) * 100), 200) for k in range(16)]
            pts_down = [(320, int(200 + (k / 14.0) * 70)) for k in range(15)]
            if step < 15:
                cx, cy = pts_left[step]
                trail_pts = pts_left[:step + 1]
                mouse_offset = (int(-(step / 15.0) * 18), 0)
            else:
                s2 = min(step - 15, 14)
                cx, cy = pts_down[s2]
                trail_pts = pts_left + pts_down[:s2 + 1]
                mouse_offset = (-18, int((s2 / 14.0) * 14))

        elif 60 <= i < 115:
            cx, cy = 320, 270
            hud_text = "Switched to GitHub Page"

        elif 115 <= i < 145:
            # DRAW LEFT THEN UP (LU -> PREV TAB)
            rmb_pressed = True
            click_type = "right"
            hud_text = "⮃  Previous Tab (Ctrl + Shift + Tab)"
            hud_icon = ICON_LU
            hud_high = True

            step = i - 115
            pts_left = [(int(420 - (k / 15.0) * 100), 270) for k in range(16)]
            pts_up = [(320, int(270 - (k / 14.0) * 70)) for k in range(15)]
            if step < 15:
                cx, cy = pts_left[step]
                trail_pts = pts_left[:step + 1]
                mouse_offset = (int(-(step / 15.0) * 18), 0)
            else:
                s2 = min(step - 15, 14)
                cx, cy = pts_up[s2]
                trail_pts = pts_left + pts_up[:s2 + 1]
                mouse_offset = (-18, int(-(s2 / 14.0) * 14))

        elif i >= 145:
            cx, cy = 320, 200
            hud_text = "Switched to Google Search"

        if len(trail_pts) > 1:
            for w, col in [(6, (6, 182, 212)), (3, (255, 255, 255))]:
                for idx in range(len(trail_pts) - 1):
                    draw.line([trail_pts[idx], trail_pts[idx + 1]], fill=col, width=w)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, hud_icon, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 195, by=HEIGHT - 225, bw=185, bh=215,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_tab_switch")

# ==============================================================================
# 3. DEMO 3: CLOSE ACTIVE TAB & RELOAD GITHUB PAGE
# ==============================================================================
def make_demo_close_refresh():
    print("[3/7] Creating demo_close_refresh (Close active tab & Reload GitHub page)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (20, 24, 32))
        draw = ImageDraw.Draw(im)

        # 0-35: Tab 1 (Google Search) and Tab 2 ACTIVE (Temporary Tab)
        # 35-65: Draw Right then Up (RU) -> CLOSES ACTIVE TAB 2! View switches to Tab 1 (GitHub Page)!
        # 65-115: Viewing GitHub Page on Tab 1
        # 115-145: Draw Right then Down (RD) -> RELOADS GITHUB PAGE! Loading spinner & re-render!
        # 145-180: Freshly reloaded GitHub Page!

        tab2_closed = (i >= 55)
        reloading = (130 <= i < 155)

        # Tab Bar
        draw.rectangle([0, 0, WIDTH, 38], fill=(30, 36, 48))
        if not tab2_closed:
            # Tab 1 inactive, Tab 2 ACTIVE
            draw.rounded_rectangle([15, 6, 185, 38], radius=6, fill=(38, 46, 60))
            draw.text((28, 12), "🔍 Google Search", fill=(160, 170, 185), font=get_font(10))
            
            draw.rounded_rectangle([192, 6, 365, 38], radius=6, fill=(20, 24, 32))
            draw.text((205, 12), "🐙 Active Temporary Tab", fill=(240, 245, 250), font=get_font(10, bold=True))
            draw.text((345, 12), "×", fill=(170, 180, 195), font=get_font(10))
        else:
            # Only GitHub Page active
            draw.rounded_rectangle([15, 6, 210, 38], radius=6, fill=(20, 24, 32))
            draw.text((28, 12), "🐙 GestureMouse - GitHub Page", fill=(240, 245, 250), font=get_font(10, bold=True))

        # Address bar
        draw.rectangle([0, 38, WIDTH, 75], fill=(24, 30, 40))
        draw.rounded_rectangle([50, 44, WIDTH - 50, 70], radius=13, fill=(16, 20, 28), outline=(48, 58, 76))
        draw.text((65, 50), "🔒", fill=(129, 201, 149), font=get_font(11))
        page_url = "https://ngtrian.github.io/GestureMouse/" if tab2_closed else "https://temporary-page.org/test"
        draw.text((85, 50), page_url, fill=(210, 220, 235), font=get_font(12))
        draw.text((20, 48), "↻", fill=(6, 182, 212) if reloading else (160, 170, 185), font=get_font(15, bold=True))

        # Content
        if not tab2_closed:
            # Active temporary tab
            draw.rectangle([0, 75, WIDTH, HEIGHT], fill=(20, 24, 34))
            draw.text((50, 110), "Temporary Active Window", fill=(240, 245, 250), font=get_font(16, bold=True))
            draw.rounded_rectangle([50, 145, WIDTH - 235, 350], radius=10, fill=(28, 34, 48), outline=(42, 52, 70))
            draw.text((70, 170), "This active tab will be closed by drawing RU gesture.", fill=(160, 170, 185), font=get_font(13))
        else:
            # GitHub Page
            if reloading:
                draw.rectangle([0, 75, WIDTH, HEIGHT], fill=(11, 15, 25))
                draw.text((WIDTH // 2 - 140, 220), "↻  Reloading GitHub Page...", fill=(6, 182, 212), font=get_font(16, bold=True))
            else:
                draw_github_page(im, draw, scroll_y=0)

        # ANIMATION
        cx, cy = 340, 240
        click_type = None
        rmb_pressed = False
        mouse_offset = (0, 0)
        hud_text = "Close & Reload Gestures"
        hud_icon = None
        hud_high = False
        trail_pts = []

        if 30 <= i < 60:
            # RIGHT THEN UP (RU -> CLOSE TAB)
            rmb_pressed = True
            click_type = "right"
            hud_text = "✕  Close Tab (Ctrl + W)"
            hud_icon = ICON_RU
            hud_high = True

            step = i - 30
            pts_right = [(int(320 + (k / 15.0) * 100), 270) for k in range(16)]
            pts_up = [(420, int(270 - (k / 14.0) * 70)) for k in range(15)]
            if step < 15:
                cx, cy = pts_right[step]
                trail_pts = pts_right[:step + 1]
                mouse_offset = (int((step / 15.0) * 18), 0)
            else:
                s2 = min(step - 15, 14)
                cx, cy = pts_up[s2]
                trail_pts = pts_right + pts_up[:s2 + 1]
                mouse_offset = (18, int(-(s2 / 14.0) * 14))

        elif 60 <= i < 115:
            cx, cy = 420, 200
            hud_text = "Closed Active Tab"

        elif 115 <= i < 145:
            # RIGHT THEN DOWN (RD -> RELOAD PAGE)
            rmb_pressed = True
            click_type = "right"
            hud_text = "↻  Reload Page (F5 / Ctrl + R)"
            hud_icon = ICON_RD
            hud_high = True

            step = i - 115
            pts_right = [(int(320 + (k / 15.0) * 100), 200) for k in range(16)]
            pts_down = [(420, int(200 + (k / 14.0) * 70)) for k in range(15)]
            if step < 15:
                cx, cy = pts_right[step]
                trail_pts = pts_right[:step + 1]
                mouse_offset = (int((step / 15.0) * 18), 0)
            else:
                s2 = min(step - 15, 14)
                cx, cy = pts_down[s2]
                trail_pts = pts_right + pts_down[:s2 + 1]
                mouse_offset = (18, int((s2 / 14.0) * 14))

        elif i >= 145:
            cx, cy = 420, 270
            hud_text = "GitHub Page Reloaded"

        if len(trail_pts) > 1:
            for w, col in [(6, (6, 182, 212)), (3, (255, 255, 255))]:
                for idx in range(len(trail_pts) - 1):
                    draw.line([trail_pts[idx], trail_pts[idx + 1]], fill=col, width=w)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, hud_icon, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 195, by=HEIGHT - 225, bw=185, bh=215,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_close_refresh")

# ==============================================================================
# 4. DEMO 4: KINETIC FLING SCROLL (HOLD RMB -> FLICK -> RELEASE -> MOVE TO BRAKE)
# ==============================================================================
def make_demo_kinetic_scroll():
    print("[4/7] Creating demo_kinetic_scroll (Deep downward swipe with ample upward runway)...")
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
        cx = 360
        cy = 220
        hud_text = "Kinetic Fling Scroll"
        hud_high = False

        # --- GIAI ĐOẠN 1: VUỐT XUỐNG SÂU (0 - 90 frames = 3.0s) ---
        if i < 18:
            scroll_pos = 0.0
            velocity_y = 0.0
            cy = 190
            hud_text = "Swipe Like a Smartphone"
            
        elif 18 <= i < 36:
            # 1. CHẠM & VUỐT XUỐNG SÂU VỚI GIA TỐC MẠNH
            rmb_pressed = True
            click_type = "right"
            t = (i - 18) / 18.0
            swipe_accel = t ** 2
            cy = int(190 + swipe_accel * 130)
            mouse_offset = (0, int(swipe_accel * 24))
            
            scroll_pos = swipe_accel * 110.0
            velocity_y = 42.0  # Cú hất mạnh đưa trang trôi sâu xuống dưới
            
            hud_text = "👇  Touch & Swipe Down Fast"
            hud_high = True

        elif 36 <= i < 75:
            # 2. THẢ TAY -> TRÔI SÂU XUỐNG DƯỚI VỚI MA SÁT SUY GIẢM TỰ NHIÊN
            rmb_pressed = False
            cy = 320
            
            scroll_pos = min(scroll_pos + velocity_y, 960.0)
            velocity_y *= 0.948  # Ma sát mượt mà
            
            hud_text = "🌊  Smooth Deep Inertial Fling"
            hud_high = True

        elif 75 <= i < 95:
            # 3. CỬ ĐỘNG NHẸ CHUỘT -> HÃM PHANH DỪNG Ở VỊ TRÍ SÂU (~920px)
            rmb_pressed = False
            velocity_y = 0.0
            t = (i - 75) / 20.0
            cx = int(360 + math.sin(t * math.pi * 2) * 26)
            cy = int(320 + math.cos(t * math.pi * 2) * 12)
            
            hud_text = "🛑  Move Mouse to Brake & Halt"
            hud_high = True

        # --- GIAI ĐOẠN 2: VUỐT NGƯỢC LÊN VỚI KHÔNG GIAN RỘNG RÃI (95 - 180 frames = 3.0s) ---
        elif 95 <= i < 110:
            # Tạm dừng ở vùng sâu, tạo đà và không gian trống phía trên
            cy = 320
            velocity_y = 0.0
            hud_text = "Position Held Stable"

        elif 110 <= i < 128:
            # 4. CHẠM & VUỐT LÊN DỨT KHOÁT
            rmb_pressed = True
            click_type = "right"
            t = (i - 110) / 18.0
            swipe_accel = t ** 2
            cy = int(320 - swipe_accel * 130)
            mouse_offset = (0, int(-swipe_accel * 24))
            
            scroll_pos = max(scroll_pos - swipe_accel * 90.0, 0.0)
            velocity_y = -34.0  # Vận tốc hất ngược lên
            
            hud_text = "👆  Touch & Swipe Up Fast"
            hud_high = True

        elif 128 <= i < 165:
            # 5. THẢ TAY -> BAY THEO QUÁN TÍNH NGƯỢC LÊN QUA KHOẢNG KHÔNG TRỐNG (~600px)
            rmb_pressed = False
            cy = 190
            
            scroll_pos = max(scroll_pos + velocity_y, 0.0)
            velocity_y *= 0.948
            
            hud_text = "🌊  Smooth Upward Inertial Fling"
            hud_high = True

        else:
            # 6. CỬ ĐỘNG CHUỘT HÃM PHANH TỰ NHIÊN TRƯỚC KHI CHẠM ĐẦU TRANG
            rmb_pressed = False
            velocity_y = 0.0
            t = (i - 165) / 15.0
            cx = int(360 + math.sin(t * math.pi * 2) * 26)
            cy = int(190 + math.cos(t * math.pi * 2) * 12)
            
            hud_text = "🛑  Move Mouse to Brake"
            hud_high = True

        draw_github_page(im, draw, scroll_y=scroll_pos)

        # Scrollbar (tổng chiều dài trang 1100px)
        bar_h = 70
        max_travel = HEIGHT - 85 - bar_h
        bar_y = 80 + int((scroll_pos / 1050.0) * max_travel)
        draw.rounded_rectangle([WIDTH - 225, bar_y, WIDTH - 220, bar_y + bar_h], radius=3, fill=(96, 165, 250))

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 195, by=HEIGHT - 225, bw=185, bh=215,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_kinetic_scroll")

# ==============================================================================
# 5. DEMO 5: DRAG SCROLL (CURSOR MOVES WITH MOUSE, 1:1 PROPORTIONAL)
# ==============================================================================
def make_demo_drag_scroll():
    print("[5/7] Creating demo_drag_scroll (Cursor moves with mouse, 1:1)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (11, 15, 25))
        draw = ImageDraw.Draw(im)

        # 0-30: Positioned in center
        # 30-80: Hold RMB and drag DOWN -> Cursor moves DOWN, page scrolls DOWN!
        # 80-110: Idle at bottom
        # 110-160: Hold RMB and drag UP -> Cursor moves UP, page scrolls UP!
        # 160-180: Release & Idle at top

        rmb_pressed = False
        click_type = None
        scroll_y = 0.0
        cx = 360
        cy = 180
        mouse_offset = (0, 0)
        hud_text = "Direct Drag Scroll"
        hud_high = False

        if 30 <= i < 80:
            # DRAG DOWN: CURSOR MOVES DOWN, CONTENT SCROLLS DOWN
            rmb_pressed = True
            click_type = "right"
            t = (i - 30) / 50.0
            cy = int(180 + t * 130)   # Cursor moves down from 180 to 310
            scroll_y = t * 380.0      # Content scrolls down proportionally
            mouse_offset = (0, int(t * 26))
            hud_text = "🖐️  Drag Down -> Scroll Down"
            hud_high = True
        elif 80 <= i < 110:
            cy = 310
            scroll_y = 380.0
            hud_text = "Position Maintained"
        elif 110 <= i < 160:
            # DRAG UP: CURSOR MOVES UP, CONTENT SCROLLS UP
            rmb_pressed = True
            click_type = "right"
            t = (i - 110) / 50.0
            cy = int(310 - t * 130)   # Cursor moves up from 310 to 180
            scroll_y = 380.0 - t * 380.0
            mouse_offset = (0, int(26 - t * 26))
            hud_text = "🖐️  Drag Up -> Scroll Up"
            hud_high = True
        elif i >= 160:
            cy = 180
            scroll_y = 0.0
            hud_text = "Returned to Top"

        draw_github_page(im, draw, scroll_y=scroll_y)

        draw_cursor(draw, cx, cy, click_type)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 195, by=HEIGHT - 225, bw=185, bh=215,
                                lmb=False, rmb=rmb_pressed, wheel_dir=0,
                                mouse_offset=mouse_offset, frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_drag_scroll")

# ==============================================================================
# 6. DEMO 6: PAGE UP / PAGE DOWN ACROSS 3 PAGES OF GITHUB PAGE
# ==============================================================================
def make_demo_pgup_pgdn():
    print("[6/7] Creating demo_pgup_pgdn (Leaping across 3 pages of GitHub page)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (11, 15, 25))
        draw = ImageDraw.Draw(im)

        # 3 PAGES OF GITHUB PAGE:
        # Page 1 = Hero (scroll_y = 0)
        # Page 2 = Key Features (scroll_y = 380)
        # Page 3 = Gestures Showcase (scroll_y = 760)

        # 0-30: Page 1 (Hero)
        # 30-60: Hold RMB + WheelDown -> Leap to Page 2 (Features)
        # 60-90: Hold RMB + WheelDown -> Leap to Page 3 (Gestures)
        # 90-120: On Page 3 (Gestures)
        # 120-150: Hold RMB + WheelUp -> Leap back to Page 2 (Features)
        # 150-180: Hold RMB + WheelUp -> Leap back to Page 1 (Hero)

        scroll_y = 0
        hud_text = "Page Navigation"
        hud_high = False
        rmb_pressed = False
        wheel_dir = 0

        if i < 40:
            scroll_y = 0
            if 30 <= i < 40:
                rmb_pressed = True
                wheel_dir = -1
                hud_text = "⮟  Page Down (PgDn)"
                hud_high = True
        elif 40 <= i < 70:
            scroll_y = 380
            hud_text = "Page 2: Key Features"
            if 60 <= i < 70:
                rmb_pressed = True
                wheel_dir = -1
                hud_text = "⮟  Page Down (PgDn)"
                hud_high = True
        elif 70 <= i < 130:
            scroll_y = 760
            hud_text = "Page 3: Gestures Showcase"
            if 120 <= i < 130:
                rmb_pressed = True
                wheel_dir = 1
                hud_text = "⮝  Page Up (PgUp)"
                hud_high = True
        elif 130 <= i < 160:
            scroll_y = 380
            hud_text = "Page 2: Key Features"
            if 150 <= i < 160:
                rmb_pressed = True
                wheel_dir = 1
                hud_text = "⮝  Page Up (PgUp)"
                hud_high = True
        else:
            scroll_y = 0
            hud_text = "Page 1: Hero Section"

        draw_github_page(im, draw, scroll_y=scroll_y)

        # Page indicator badge
        page_num = 1 if scroll_y == 0 else (2 if scroll_y == 380 else 3)
        draw.rounded_rectangle([WIDTH - 360, 44, WIDTH - 240, 70], radius=8, fill=(24, 32, 46), outline=(48, 60, 80))
        draw.text((WIDTH - 345, 50), f"Page {page_num} of 3", fill=(103, 232, 249), font=get_font(11, bold=True))

        draw_cursor(draw, 340, 240, "right" if rmb_pressed else None)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 195, by=HEIGHT - 225, bw=185, bh=215,
                                lmb=False, rmb=rmb_pressed, wheel_dir=wheel_dir,
                                mouse_offset=(0, 0), frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_pgup_pgdn")

# ==============================================================================
# 7. DEMO 7: VOLUME ADJUSTMENT (ROCKER GESTURE)
# ==============================================================================
def make_demo_volume():
    print("[7/7] Creating demo_volume (Hold LMB + Scroll Wheel)...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        im = Image.new("RGB", (WIDTH, HEIGHT), (14, 18, 26))
        draw = ImageDraw.Draw(im)

        # 0-30: Idle at 35%
        # 30-80: Hold LMB + Scroll Up -> Volume 35% -> 85%
        # 80-110: Idle at 85%
        # 110-160: Hold LMB + Scroll Down -> Volume 85% -> 20%
        # 160-180: Release & Idle at 20%

        vol = 35
        lmb_pressed = False
        wheel_dir = 0
        hud_text = "Rocker Volume Control"
        hud_high = False

        if 30 <= i < 80:
            lmb_pressed = True
            wheel_dir = 1
            t = (i - 30) / 50.0
            vol = int(35 + t * 50)
            hud_text = f"🔊  Volume Up ▲ ({vol}%)"
            hud_high = True
        elif 80 <= i < 110:
            vol = 85
            hud_text = f"Volume Set to 85%"
        elif 110 <= i < 160:
            lmb_pressed = True
            wheel_dir = -1
            t = (i - 110) / 50.0
            vol = int(85 - t * 65)
            hud_text = f"🔉  Volume Down ▼ ({vol}%)"
            hud_high = True
        elif i >= 160:
            vol = 20
            hud_text = "Volume Set to 20%"

        # Media Player Background
        draw.rectangle([0, 0, WIDTH, 50], fill=(22, 28, 38))
        draw.text((25, 14), "▶  YouTube Music — Lo-Fi Chill Coding Sessions", fill=(240, 245, 250), font=get_font(13, bold=True))

        draw.rounded_rectangle([35, 75, WIDTH - 240, 360], radius=14, fill=(20, 26, 36), outline=(38, 48, 66))
        draw.rounded_rectangle([65, 105, 205, 245], radius=10, fill=(35, 48, 70))
        draw.text((110, 150), "🎵", fill=(96, 165, 250), font=get_font(40))

        draw.text((230, 115), "Lo-Fi Beats to Relax / Study / Code", fill=(249, 250, 251), font=get_font(15, bold=True))
        draw.text((230, 145), "Adjust master audio instantly without leaving your active window", fill=(156, 163, 175), font=get_font(11))
        
        draw.rounded_rectangle([230, 185, 540, 191], radius=3, fill=(45, 55, 70))
        draw.rounded_rectangle([230, 185, 410, 191], radius=3, fill=(37, 99, 235))
        draw.ellipse([406, 183, 414, 193], fill=(255, 255, 255))
        draw.text((230, 202), "03:15 / 05:00", fill=(130, 145, 165), font=get_font(10))

        # GESTUREMOUSE MODERN GLASS VOLUME OSD
        if lmb_pressed or (80 <= i < 95):
            osd_x, osd_y = 230, 240
            draw.rounded_rectangle([osd_x, osd_y, osd_x + 280, osd_y + 80], radius=12,
                                   fill=(13, 20, 32, 250), outline=(6, 182, 212), width=2)
            draw.text((osd_x + 18, osd_y + 14), "🔊", fill=(255, 255, 255), font=get_font(20))
            draw.text((osd_x + 55, osd_y + 16), f"Volume: {vol}%", fill=(240, 248, 255), font=get_font(13, bold=True))
            
            bar_w = 240
            cur_w = int(bar_w * (vol / 100.0))
            draw.rounded_rectangle([osd_x + 18, osd_y + 48, osd_x + 18 + bar_w, osd_y + 58], radius=5, fill=(35, 45, 62))
            draw.rounded_rectangle([osd_x + 18, osd_y + 48, osd_x + 18 + cur_w, osd_y + 58], radius=5, fill=(0, 229, 255))

        draw_cursor(draw, 340, 260, "left" if lmb_pressed else None)
        draw_top_hud(im, draw, hud_text, None, hud_high)
        draw_clean_mouse_widget(draw, bx=WIDTH - 195, by=HEIGHT - 225, bw=185, bh=215,
                                lmb=lmb_pressed, rmb=False, wheel_dir=wheel_dir,
                                mouse_offset=(0, 0), frame_idx=i)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_volume")

# ==============================================================================
# MAIN
# ==============================================================================
if __name__ == "__main__":
    print("=== PRODUCING 7 VISUAL DEMOS V5.0 (TOP HUD, GITHUB PAGE, FLING SCROLL) ===")
    make_demo_back_forward()
    make_demo_tab_switch()
    make_demo_close_refresh()
    make_demo_kinetic_scroll()
    make_demo_drag_scroll()
    make_demo_pgup_pgdn()
    make_demo_volume()
    if os.path.exists(TEMP_FRAME_DIR):
        shutil.rmtree(TEMP_FRAME_DIR)
    print("=== ALL 7 DEMOS GENERATED SUCCESSFULLY ===")
