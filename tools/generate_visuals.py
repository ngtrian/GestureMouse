# -*- coding: utf-8 -*-
"""
GestureMouse Visual Generator
Tạo ảnh GIF động và MP4 chất lượng cao mô phỏng 4 tính năng chính của GestureMouse:
1. demo_gesture: Cử chỉ chuột quẹt Back và vẽ chữ L Đóng tab.
2. demo_scroll: Cuộn trang có quán tính mượt mà (Kinetic Smooth Scroll).
3. demo_volume: Rocker Gesture (Giữ chuột trái + Lăn cuộn chỉnh âm lượng).
4. demo_lock: Khóa phím khẩn cấp (Ctrl + Alt + L) lau bàn phím không sợ gõ nhầm.
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

# Thư mục xuất file
OUTPUT_DIRS = [
    os.path.abspath("docs/image"),
    os.path.abspath("image")
]
TEMP_FRAME_DIR = os.path.abspath("tools/_temp_frames")

WIDTH = 800
HEIGHT = 450
FPS = 30

FONT_PATH = "C:/Windows/Fonts/segoeui.ttf"
FONT_BOLD_PATH = "C:/Windows/Fonts/segoeuib.ttf"

def get_font(size, bold=False):
    p = FONT_BOLD_PATH if bold else FONT_PATH
    try:
        return ImageFont.truetype(p, size)
    except:
        return ImageFont.load_default()

def draw_cursor(draw, x, y, click_type=None):
    """Vẽ con trỏ chuột và hiệu ứng click."""
    if click_type == "right":
        draw.ellipse([x - 16, y - 16, x + 16, y + 16], fill=(255, 90, 90, 90), outline=(255, 70, 70), width=2)
    elif click_type == "left":
        draw.ellipse([x - 16, y - 16, x + 16, y + 16], fill=(50, 160, 255, 90), outline=(50, 150, 255), width=2)

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

def draw_badge(draw, x, y, text, icon="🖱️", bg_color=(25, 30, 38), border_color=(60, 130, 246)):
    """Vẽ huy hiệu thao tác phím/chuột."""
    font = get_font(13, bold=True)
    full_text = f"{icon}  {text}"
    bbox = font.getbbox(full_text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    px, py = 12, 6
    rect = [x, y, x + tw + px * 2, y + th + py * 2]
    draw.rounded_rectangle(rect, radius=6, fill=bg_color, outline=border_color, width=2)
    draw.text((x + px, y + py), full_text, fill=(240, 245, 255), font=font)

def draw_hud(draw, x, y, text, icon="✓"):
    """Vẽ Tooltip/HUD cử chỉ nổi bên cạnh con trỏ."""
    font = get_font(14, bold=True)
    full_text = f"{icon}  {text}"
    bbox = font.getbbox(full_text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    px, py = 12, 7
    rect = [x, y, x + tw + px * 2, y + th + py * 2]
    draw.rounded_rectangle(rect, radius=8, fill=(16, 24, 38), outline=(0, 229, 255), width=2)
    draw.text((x + px, y + py), full_text, fill=(0, 229, 255), font=font)

def draw_window_frame(draw, title="Google Chrome", address="https://github.com/gesturemouse/gesturemouse"):
    # Header
    draw.rectangle([0, 0, WIDTH, 75], fill=(30, 34, 42))
    # Dot buttons
    draw.ellipse([14, 12, 24, 22], fill=(255, 95, 87))
    draw.ellipse([30, 12, 40, 22], fill=(254, 188, 46))
    draw.ellipse([46, 12, 56, 22], fill=(40, 200, 64))
    # Address bar
    draw.rounded_rectangle([70, 40, WIDTH - 70, 68], radius=12, fill=(42, 48, 58), outline=(65, 75, 90))
    draw.text((85, 45), "🔒", fill=(100, 200, 120), font=get_font(12))
    draw.text((105, 46), address, fill=(210, 220, 235), font=get_font(13))
    # Back/Forward buttons
    draw.text((18, 45), "←", fill=(170, 180, 195), font=get_font(16, bold=True))
    draw.text((42, 45), "→", fill=(170, 180, 195), font=get_font(16, bold=True))

def render_frames_to_media(base_name, fps=FPS):
    """Mã hóa các frame thành GIF tối ưu (paletteuse) và MP4."""
    for out_dir in OUTPUT_DIRS:
        os.makedirs(out_dir, exist_ok=True)
        gif_path = os.path.join(out_dir, f"{base_name}.gif")
        mp4_path = os.path.join(out_dir, f"{base_name}.mp4")

        # GIF Palettegen
        palette_cmd = [
            "ffmpeg", "-y", "-framerate", str(fps),
            "-i", os.path.join(TEMP_FRAME_DIR, "frame_%04d.png"),
            "-vf", f"fps={fps},split[s0][s1];[s0]palettegen=max_colors=128:reserve_transparent=0[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3",
            gif_path
        ]
        subprocess.run(palette_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        # MP4 H.264
        mp4_cmd = [
            "ffmpeg", "-y", "-framerate", str(fps),
            "-i", os.path.join(TEMP_FRAME_DIR, "frame_%04d.png"),
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "medium",
            mp4_path
        ]
        subprocess.run(mp4_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    print(f"  ==> Đã tạo xong: {base_name}.gif và {base_name}.mp4")

# ==============================================================================
# 1. DEMO GESTURE (Vẽ Back & Đóng Tab)
# ==============================================================================
def make_demo_gesture():
    print("[1/4] Đang tạo demo_gesture...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    total_frames = 115
    for i in range(total_frames):
        im = Image.new("RGB", (WIDTH, HEIGHT), (20, 24, 30))
        draw = ImageDraw.Draw(im)

        # Trình duyệt
        # Tabs
        tab2_open = (i < 85)
        draw.rectangle([0, 0, WIDTH, 75], fill=(28, 32, 40))
        draw.ellipse([14, 12, 24, 22], fill=(255, 95, 87))
        draw.ellipse([30, 12, 40, 22], fill=(254, 188, 46))
        draw.ellipse([46, 12, 56, 22], fill=(40, 200, 64))

        # Tab 1
        draw.rounded_rectangle([75, 8, 220, 36], radius=4, fill=(45, 52, 64))
        draw.text((85, 14), "GestureMouse - Home", fill=(240, 245, 250), font=get_font(12, bold=True))
        # Tab 2
        if tab2_open:
            draw.rounded_rectangle([226, 8, 360, 36], radius=4, fill=(35, 40, 50))
            draw.text((236, 14), "Tin tức công nghệ", fill=(170, 180, 195), font=get_font(12))
            draw.text((345, 14), "×", fill=(170, 180, 195), font=get_font(12))

        # URL address
        url_text = "https://github.com/gesturemouse/gesturemouse" if i >= 38 else "https://news.ycombinator.com/item?id=38912"
        draw.rounded_rectangle([70, 40, WIDTH - 70, 68], radius=12, fill=(40, 46, 56), outline=(60, 70, 85))
        draw.text((85, 45), "🔒", fill=(100, 200, 120), font=get_font(12))
        draw.text((105, 46), url_text, fill=(210, 220, 235), font=get_font(13))
        draw.text((18, 45), "←", fill=(0, 229, 255) if (25 <= i < 38) else (170, 180, 195), font=get_font(16, bold=True))
        draw.text((42, 45), "→", fill=(170, 180, 195), font=get_font(16, bold=True))

        # Web page content mock
        draw.rectangle([0, 75, WIDTH, HEIGHT], fill=(18, 22, 28))
        draw.text((40, 100), "GestureMouse — Cuộn Mượt & Cử Chỉ Chuột Đỉnh Cao", fill=(240, 245, 250), font=get_font(18, bold=True))
        draw.text((40, 130), "Điều khiển Windows nhanh gấp 3 lần với các nét vẽ chuột mượt mà.", fill=(150, 160, 175), font=get_font(13))

        # Card demo
        draw.rounded_rectangle([40, 160, 360, 280], radius=8, fill=(28, 34, 44), outline=(45, 55, 70))
        draw.text((60, 180), "✦ Quẹt Trái (Left): Quay lại trang trước", fill=(0, 229, 255), font=get_font(13, bold=True))
        draw.text((60, 210), "✦ Vẽ chữ L (Down-Right): Đóng ngay Tab đang mở", fill=(255, 170, 0), font=get_font(13, bold=True))
        draw.text((60, 240), "✦ Tùy biến mọi hành động theo ý bạn", fill=(180, 190, 205), font=get_font(13))

        draw.rounded_rectangle([400, 160, 740, 280], radius=8, fill=(28, 34, 44), outline=(45, 55, 70))
        draw.text((420, 180), "🚀 Hiệu Năng Vượt Trội", fill=(100, 230, 140), font=get_font(14, bold=True))
        draw.text((420, 210), "Chiếm chưa tới 15MB RAM, tốc độ phản hồi < 1ms.", fill=(180, 190, 205), font=get_font(13))

        # Footer tip
        draw.text((WIDTH // 2 - 160, HEIGHT - 35), "⚡ Giữ chuột phải và vẽ cử chỉ bất cứ đâu trên màn hình", fill=(120, 135, 155), font=get_font(13))

        # ANIMATION:
        trail_pts = []
        cx, cy = 480, 240
        click_type = None

        if i < 10:
            cx, cy = 520, 260
        elif 10 <= i < 40:
            # Phase 1: Vẽ quẹt trái (Back)
            t = (i - 10) / 25.0
            cx = int(520 - t * 240)
            cy = int(260 + math.sin(t * math.pi) * 8)
            click_type = "right"
            draw_badge(draw, 30, HEIGHT - 75, "Giữ Chuột Phải & Quẹt Trái", "🖱️", bg_color=(40, 20, 20), border_color=(255, 80, 80))
            draw_hud(draw, cx - 180, cy - 20, "Quay lại (Back)", "⮌")
            trail_pts = [(int(520 - (k / 25.0) * 240), int(260 + math.sin((k / 25.0) * math.pi) * 8)) for k in range(0, i - 10 + 1)]
        elif 40 <= i < 55:
            # Nghỉ giữa 2 cử chỉ
            t = (i - 40) / 15.0
            cx = int(280 + t * 160)
            cy = int(260 - t * 60)
        elif 55 <= i < 90:
            # Phase 2: Vẽ chữ L (Down -> Right: Đóng Tab)
            click_type = "right"
            draw_badge(draw, 30, HEIGHT - 75, "Giữ Chuột Phải & Vẽ chữ L", "🖱️", bg_color=(40, 20, 20), border_color=(255, 80, 80))
            draw_hud(draw, cx + 25, cy - 10, "Đóng Tab Hiện Tại", "✕")

            pts_down = [(440, int(200 + (k / 17.0) * 110)) for k in range(18)]
            pts_right = [(int(440 + (k / 17.0) * 120), 310) for k in range(18)]

            if i < 72: # Kéo xuống
                step = i - 55
                cx = 440
                cy = int(200 + (step / 17.0) * 110)
                trail_pts = pts_down[:step + 1]
            else: # Rẽ phải
                step = i - 72
                cx = int(440 + (step / 17.0) * 120)
                cy = 310
                trail_pts = pts_down + pts_right[:step + 1]
        else:
            # Kết thúc & chuẩn bị lặp
            cx, cy = 560, 310
            draw_badge(draw, 30, HEIGHT - 75, "Tab đã đóng tức thì!", "✓", bg_color=(15, 35, 25), border_color=(40, 200, 100))

        # Vẽ vệt cử chỉ (Glow Trail)
        if len(trail_pts) > 1:
            for w, alpha, col in [(6, 80, (0, 180, 255)), (3, 255, (0, 240, 255))]:
                for idx in range(len(trail_pts) - 1):
                    draw.line([trail_pts[idx], trail_pts[idx + 1]], fill=col, width=w)

        # Vẽ con trỏ chuột
        draw_cursor(draw, cx, cy, click_type)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_gesture")

# ==============================================================================
# 2. DEMO SCROLL (Cuộn trang quán tính mượt mà)
# ==============================================================================
def make_demo_scroll():
    print("[2/4] Đang tạo demo_scroll...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    total_frames = 110
    # Danh sách các bài viết giả lập
    articles = [
        ("Tin Công Nghệ 01: AutoHotkey v2 và bước chuyển mình mạnh mẽ", "AutoHotkey đem lại khả năng tự động hóa tối đa cho người dùng Windows..."),
        ("Tin Công Nghệ 02: Trải nghiệm Kinetic Smooth Scrolling", "Cuộn trang có gia tốc quán tính giúp mắt không bị mỏi khi đọc tài liệu dài..."),
        ("Tin Công Nghệ 03: Cách tối ưu hiệu suất làm việc với chuột", "Thay vì với tay lên góc màn hình, cử chỉ chuột giúp bạn tiết kiệm 30% thời gian..."),
        ("Tin Công Nghệ 04: Đánh giá GestureMouse Portable", "Không cần cài đặt, không ghi vào Registry, chạy ngay với quyền User..."),
        ("Tin Công Nghệ 05: Phím tắt thông minh và an toàn cho bàn phím", "Tính năng khóa phím khẩn cấp giúp bạn thoải mái vệ sinh bàn phím...")
    ]

    for i in range(total_frames):
        im = Image.new("RGB", (WIDTH, HEIGHT), (22, 26, 33))
        draw = ImageDraw.Draw(im)

        draw_window_frame(draw, "Trình duyệt - Tin Tức Cuộn Mượt", "https://vnexpress.net/so-hoa/gesturemouse-smooth-scroll")

        # Tính toán độ cuộn (scroll_offset) với vật lý quán tính (Kinetic Physics)
        # Bắt đầu cuộn từ frame 20, lực đẩy v0 lớn rồi giảm tốc ma sát
        scroll_y = 0
        if i >= 20:
            t = min((i - 20) / 75.0, 1.0)
            # Cubic ease-out: 1 - (1 - t)^3
            ease = 1.0 - math.pow(1.0 - t, 3)
            scroll_y = ease * 340

        # Vẽ nội dung bài viết trôi theo scroll_y
        base_y = 90 - int(scroll_y)
        for idx, (title, desc) in enumerate(articles):
            card_y = base_y + idx * 115
            if -100 <= card_y <= HEIGHT:
                draw.rounded_rectangle([50, card_y, WIDTH - 70, card_y + 95], radius=8, fill=(28, 34, 44), outline=(42, 50, 65))
                draw.ellipse([70, card_y + 18, 100, card_y + 48], fill=(60, 130, 246))
                draw.text((79, card_y + 22), "📰", fill=(255, 255, 255), font=get_font(14))
                draw.text((115, card_y + 16), title, fill=(240, 245, 250), font=get_font(14, bold=True))
                draw.text((115, card_y + 45), desc, fill=(160, 170, 185), font=get_font(12))
                draw.text((115, card_y + 68), "👁️ 1.2k lượt đọc  •  ⏱️ 3 phút", fill=(100, 115, 135), font=get_font(10))

        # Thanh Scrollbar mượt mà bên phải
        draw.rectangle([WIDTH - 16, 75, WIDTH, HEIGHT], fill=(24, 28, 36))
        bar_h = 90
        max_bar_travel = HEIGHT - 75 - bar_h - 10
        bar_y = 80 + int((scroll_y / 340.0) * max_bar_travel)
        draw.rounded_rectangle([WIDTH - 12, bar_y, WIDTH - 4, bar_y + bar_h], radius=4, fill=(80, 120, 180))

        # Chỉ báo trạng thái cuộn
        if 20 <= i < 40:
            draw_badge(draw, 40, HEIGHT - 65, "Lăn con lăn 1 nấc nhẹ...", "🔄", bg_color=(25, 45, 60), border_color=(0, 200, 255))
        elif i >= 40:
            draw_badge(draw, 40, HEIGHT - 65, "Cuộn quán tính Kinetic 60 FPS (Mượt như iPhone)", "⚡", bg_color=(15, 40, 30), border_color=(50, 220, 120))

        # Con trỏ chuột đặt nhẹ nhàng ở giữa màn hình
        draw_cursor(draw, 450, 220, None)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_scroll")

# ==============================================================================
# 3. DEMO VOLUME (Rocker Gesture: Giữ Chuột Trái + Lăn Cuộn)
# ==============================================================================
def make_demo_volume():
    print("[3/4] Đang tạo demo_volume...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    total_frames = 115
    for i in range(total_frames):
        im = Image.new("RGB", (WIDTH, HEIGHT), (18, 22, 28))
        draw = ImageDraw.Draw(im)

        # Background Desktop / Music Player
        draw.rectangle([0, 0, WIDTH, HEIGHT], fill=(16, 20, 26))
        # Player card
        draw.rounded_rectangle([80, 60, WIDTH - 80, 370], radius=16, fill=(24, 30, 40), outline=(40, 50, 66))
        # Album Art
        draw.rounded_rectangle([110, 90, 260, 240], radius=12, fill=(45, 60, 85))
        draw.text((155, 145), "🎵", fill=(100, 180, 255), font=get_font(40))
        # Song info
        draw.text((290, 105), "Đang phát: Lofi Chill Study Beats", fill=(245, 250, 255), font=get_font(18, bold=True))
        draw.text((290, 138), "Nghệ sĩ: GestureMouse Lo-Fi Sessions", fill=(140, 155, 175), font=get_font(13))
        # Timeline
        draw.rounded_rectangle([290, 175, 670, 181], radius=3, fill=(50, 60, 75))
        draw.rounded_rectangle([290, 175, 490, 181], radius=3, fill=(60, 140, 255))
        draw.ellipse([486, 173, 496, 183], fill=(255, 255, 255))
        draw.text((290, 192), "02:14 / 04:30", fill=(140, 155, 175), font=get_font(11))

        # Controls mockup
        draw.text((450, 220), "⏮   ▶   ⏭", fill=(200, 215, 235), font=get_font(20))

        # VOLUME CONTROL ACTION LOGIC
        # 0-15: idle (Vol 40)
        # 15-55: Giữ chuột trái + lăn lên (Vol tăng từ 40% -> 80%)
        # 55-95: Lăn xuống (Vol giảm từ 80% -> 25%)
        # 95-115: Nhả chuột, volume giữ ở 25%
        vol = 40
        holding_lmb = False
        action_text = "Giữ chuột trái ở bất kỳ đâu rồi lăn con lăn"
        badge_bg = (25, 30, 40)
        badge_bd = (70, 85, 110)

        if 15 <= i < 55:
            holding_lmb = True
            t = (i - 15) / 40.0
            vol = int(40 + t * 40) # 40 -> 80
            action_text = f"Giữ Chuột Trái + Lăn Cuộn Lên ⮝ (Âm lượng: {vol}%)"
            badge_bg = (15, 40, 60)
            badge_bd = (0, 180, 255)
        elif 55 <= i < 95:
            holding_lmb = True
            t = (i - 55) / 40.0
            vol = int(80 - t * 55) # 80 -> 25
            action_text = f"Giữ Chuột Trái + Lăn Cuộn Xuống ⮟ (Âm lượng: {vol}%)"
            badge_bg = (50, 25, 15)
            badge_bd = (255, 140, 40)
        elif i >= 95:
            vol = 25
            action_text = "Xong! Không cần với tay click icon Loa ở Taskbar"
            badge_bg = (15, 40, 25)
            badge_bd = (50, 220, 120)

        draw_badge(draw, 110, 290, action_text, "🔊" if holding_lmb else "💡", bg_color=badge_bg, border_color=badge_bd)

        # OSD Volume Popup sang trọng (Hiện ra khi chỉnh âm lượng)
        if holding_lmb:
            osd_x, osd_y = WIDTH // 2 - 140, 120
            draw.rounded_rectangle([osd_x, osd_y, osd_x + 280, osd_y + 110], radius=14, fill=(15, 20, 30, 240), outline=(60, 130, 246), width=2)
            draw.text((osd_x + 25, osd_y + 20), "🔊", fill=(255, 255, 255), font=get_font(26))
            draw.text((osd_x + 75, osd_y + 24), f"Âm Lượng: {vol}%", fill=(240, 248, 255), font=get_font(16, bold=True))
            # Progress bar
            bar_w = 230
            fill_w = int(bar_w * (vol / 100.0))
            draw.rounded_rectangle([osd_x + 25, osd_y + 68, osd_x + 25 + bar_w, osd_y + 80], radius=6, fill=(35, 45, 60))
            draw.rounded_rectangle([osd_x + 25, osd_y + 68, osd_x + 25 + fill_w, osd_y + 80], radius=6, fill=(0, 200, 255))

        # Con trỏ chuột
        cx, cy = 400, 280
        draw_cursor(draw, cx, cy, "left" if holding_lmb else None)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_volume")

# ==============================================================================
# 4. DEMO LOCK (Khóa phím khẩn cấp - Ctrl + Alt + L)
# ==============================================================================
def make_demo_lock():
    print("[4/4] Đang tạo demo_lock...")
    if os.path.exists(TEMP_FRAME_DIR): shutil.rmtree(TEMP_FRAME_DIR)
    os.makedirs(TEMP_FRAME_DIR, exist_ok=True)

    total_frames = 125
    for i in range(total_frames):
        im = Image.new("RGB", (WIDTH, HEIGHT), (16, 20, 26))
        draw = ImageDraw.Draw(im)

        # Mockup Text Editor (VS Code / Notepad)
        draw.rectangle([0, 0, WIDTH, 40], fill=(24, 28, 36))
        draw.text((20, 11), "📄 tailieu_quan_trong.txt — Đang soạn thảo", fill=(200, 210, 225), font=get_font(13))
        draw.rectangle([0, 40, WIDTH, HEIGHT], fill=(20, 24, 32))

        # Dòng text soạn thảo
        draw.text((40, 60), "1 |  Báo cáo kế hoạch phát triển GestureMouse 2026:", fill=(120, 135, 155), font=get_font(13))
        draw.text((40, 90), "2 |  - Hỗ trợ cuộn trang quán tính Kinetic Smooth Scrolling.", fill=(220, 230, 240), font=get_font(14))
        draw.text((40, 120), "3 |  - Cử chỉ vẽ chuột thông minh (Back, Forward, Close Tab).", fill=(220, 230, 240), font=get_font(14))
        draw.text((40, 150), "4 |  - Khóa bàn phím tức thì khi cần lau phím sạch sẽ.", fill=(220, 230, 240), font=get_font(14))

        # Con trỏ soạn thảo nhấp nháy
        if (i // 8) % 2 == 0:
            draw.rectangle([455, 150, 457, 168], fill=(0, 229, 255))

        # Giai đoạn:
        # 0-25: Gõ bình thường
        # 25-35: Nhấn Ctrl + Alt + L
        # 35-95: Đang khóa bàn phím! Mèo cào / tay lau phím bấm loạn xạ [A][S][Delete][Enter] -> Đều bị chặn 100%!
        # 95-110: Nhấn Ctrl + Alt + L mở khóa
        # 110-125: Mở khóa thành công

        is_locked = (35 <= i < 95)
        key_pressed = None

        if 25 <= i < 35:
            draw_badge(draw, WIDTH // 2 - 130, 210, "Bấm Ctrl + Alt + L", "⌨️", bg_color=(60, 30, 80), border_color=(200, 100, 255))
        elif is_locked:
            # Banner khóa phím trung tâm
            draw.rounded_rectangle([WIDTH // 2 - 250, 200, WIDTH // 2 + 250, 360], radius=14, fill=(28, 20, 24, 245), outline=(255, 60, 60), width=2)
            draw.text((WIDTH // 2 - 200, 220), "🔒  BÀN PHÍM ĐÃ KHÓA (KEYBOARD LOCKED)", fill=(255, 90, 90), font=get_font(16, bold=True))
            draw.text((WIDTH // 2 - 200, 255), "An tâm lau bàn phím / chống thú cưng giẫm phím!", fill=(240, 240, 240), font=get_font(13))
            draw.text((WIDTH // 2 - 200, 280), "Tất cả phím gõ đều bị vô hiệu hóa an toàn.", fill=(180, 190, 200), font=get_font(12))

            # Giả lập phím bấm dồn dập bị chặn
            sim_keys = ["[A]", "[Space]", "[Enter]", "[BackSpace]", "[Ctrl+C]"]
            cur_key = sim_keys[(i // 10) % len(sim_keys)]
            draw.rounded_rectangle([WIDTH // 2 - 200, 312, WIDTH // 2 + 200, 342], radius=6, fill=(45, 25, 30), outline=(255, 80, 80))
            draw.text((WIDTH // 2 - 180, 318), f"🛡️ Đã chặn tín hiệu phím: {cur_key} (Văn bản nguyên vẹn!)", fill=(255, 170, 170), font=get_font(11, bold=True))

        elif 95 <= i < 110:
            draw_badge(draw, WIDTH // 2 - 140, 230, "Bấm lại Ctrl + Alt + L để mở", "🔓", bg_color=(15, 45, 30), border_color=(40, 220, 100))
        else:
            draw_badge(draw, WIDTH // 2 - 140, 230, "Phím tắt khẩn cấp: Ctrl + Alt + L", "💡", bg_color=(25, 30, 40), border_color=(70, 90, 120))

        # Con trỏ chuột để góc
        draw_cursor(draw, 640, 340, None)

        im.save(os.path.join(TEMP_FRAME_DIR, f"frame_{i:04d}.png"))

    render_frames_to_media("demo_lock")

# ==============================================================================
# MAIN
# ==============================================================================
if __name__ == "__main__":
    print("=== BẮT ĐẦU TẠO 4 VISUAL DEMOS BẰNG PYTHON & FFMPEG ===")
    make_demo_gesture()
    make_demo_scroll()
    make_demo_volume()
    make_demo_lock()
    if os.path.exists(TEMP_FRAME_DIR):
        shutil.rmtree(TEMP_FRAME_DIR)
    print("=== HOÀN TẤT TOÀN BỘ 4 DEMO GIF & MP4 CHO GESTUREMOUSE ===")
