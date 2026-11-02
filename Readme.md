<div align="center">

# 🖱️ GestureMouse

**[🇻🇳 Tiếng Việt](README_VI.md)** • **[🇺🇸 English](Readme.md)**

[![Release](https://img.shields.io/github/v/release/ngtrian/GestureMouse?color=blue&logo=github)](https://github.com/ngtrian/GestureMouse/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-blue?logo=windows)](https://github.com/ngtrian/GestureMouse)
[![WinGet](https://img.shields.io/badge/WinGet-ngtrian.GestureMouse-blueviolet?logo=windows-terminal)](https://github.com/microsoft/winget-pkgs/pull/468668)

> **Smart Right-Click Mouse Gestures, Physics-based Inertial Scrolling & Productivity Shortcuts for Windows**

🌐 **Official Website**: [https://ngtrian.github.io/GestureMouse/](https://ngtrian.github.io/GestureMouse/)

</div>

---

## 📖 Overview

**GestureMouse** is a lightweight, smooth, and open-source productivity utility for Windows built with **AutoHotkey (AHK)**. It turbocharges your daily computing workflow through intelligent right-click mouse gestures, physics-based inertial scrolling, instant volume & brightness controls, emergency keyboard locking, and seamless UIAccess integration that effortlessly works on elevated windows like Task Manager.

---

## ⚡ Quick Start & Installation

### Option 1: Via Windows Package Manager (Recommended)
Open **Windows Terminal** (or PowerShell / Command Prompt) and run:
```powershell
winget install GestureMouse
```

### Option 2: Standalone Executable (.exe / .zip)
1. Download the latest release from [GitHub Releases](https://github.com/ngtrian/GestureMouse/releases/latest).
2. Download `GestureMouse.exe` (or `GestureMouse-v1.0.0-Portable.zip` and extract).
3. Double-click `GestureMouse.exe` to run immediately (Portable, no installation required).
4. *(Recommended)*: Right-click the system tray icon and select **"Install to System (UIAccess)"** to enable auto-start with Windows and interact with elevated windows (e.g. Task Manager) without annoying UAC prompts.

---

## 🌟 Key Features

### 1. 🖱️ Smart Mouse Gestures
Hold down the **Right Mouse Button** and move the mouse in the indicated direction to perform fast actions across **Web Browsers** (Chrome, Edge, Firefox, Brave, Opera, Vivaldi...) and **File Explorer**:

| Icon | Movement | Action | Shortcut Equivalent |
| :---: | :--- | :--- | :--- |
| **←** | Left (L) | Go Back | `Alt + Left` |
| **→** | Right (R) | Go Forward | `Alt + Right` |
| **↑__** | Up then Left (LU) | Previous Tab | `Ctrl + Shift + Tab` |
| **↓¯¯** | Down then Left (LD) | Next Tab | `Ctrl + Tab` |
| **__↑** | Right then Up (RU) | Close Current Tab | `Ctrl + W` |
| **¯¯↓** | Right then Down (RD) | Reload / Refresh Page | `F5` / `Ctrl + R` |

- **Intuitive HUD Overlay**: Shows translucent gesture icon and action name in the center of the screen as you draw.
- **Context Protection**: Automatically suppresses gestures when selecting files in File Explorer or when the cursor is outside the target window.

---

### 2. 📜 Comprehensive Smart Scrolling
Applies universally to any scrollable application (Browsers, VS Code, Word, Excel, File Explorer...):

- **Adaptive Manual Drag-Scroll**: Hold right-click and drag the mouse up or down. Scroll speed smoothly scales with mouse acceleration. Offers two selectable styles in Settings:
  1. *Drag content up/down* (touchscreen-like flicking).
  2. *Drag scrollbar up/down*.
- **Physics-based Inertial Auto-Scroll**: Hold right-click, flick up or down quickly, and release. The page glides smoothly and decelerates naturally using simulated physics friction.
  - *To stop scrolling*: Simply left-click, middle-click, or slightly move the mouse.
- **Fast Page Flip (Page Scroll)**: Hold right-click and roll the mouse wheel to flip whole pages (`Page Up` / `Page Down`).

---

### 3. 🔊 Instant Volume & Brightness Control
- **Super-Fast Mouse Control**:
  - `Hold Left Click + Scroll Wheel`: Instantly adjust system volume anywhere without clicking the Windows taskbar.
- **Volume Hotkeys**:
  - `Win + Wheel` or `Win + PgUp / PgDn`: Increase / Decrease master system volume.
  - `Ctrl + Shift + M`: Mute / Unmute system sound.
- **Display Brightness Overlay**:
  - `F9`: Dim screen brightness with a dark overlay to protect your eyes at night.
  - `F10`: Increase screen brightness back to normal.

---

### 4. ⌨️ Productivity Shortcuts
- **Quick Toggle (`Ctrl + Alt`)**:
  - Press `Ctrl + Alt` or **single-click the system tray icon** to toggle mouse gestures and scrolling on/off (Colored icon = *Active*; Grayscale icon = *Paused*).
- **Emergency Keyboard Lock (`Ctrl + Alt + L`)**:
  - Completely disables the keyboard (with an option in Settings to lock mouse clicks too) to clean off dust or prevent pets/kids from accidental presses.
  - To unlock: Type the word `unlock` on the keyboard.
- **Auto Screen Lock Timer (`Ctrl + Shift + L`)**:
  - Countdown timer dialog with an unobtrusive semi-transparent countdown timer badge in the corner of your screen.
- **Clean Plain-Text Paste (`Ctrl + Shift + V`)**:
  - Automatically strips rich formatting, font styles, colors, and trims unwanted leading/trailing whitespace, tabs, and blank lines before pasting.

---

### 5. 🛡️ Advanced Stability & Compatibility
- **Sleep & Wake Recovery Hook**: Listens to system power (`WM_POWERBROADCAST`) and session unlock (`WM_WTSSESSION_CHANGE`) events to automatically revive mouse hooks when waking from sleep or unlocking Windows.
- **UIAccess & Elevated Windows**: Built-in self-extracting certificate installer that enables smooth operation over Task Manager and admin-elevated apps without UAC dialogs.
- **Multi-language**: Instantly switch between **English** and **Tiếng Việt** directly from the tray menu.
- **Clean Uninstallation**: Built-in uninstallation option accessible from both the Start Menu and the System Tray menu.

---

## 📂 Project Structure

```text
GestureMouse/
├── Main.ahk                  # Primary entry point
├── Lib/                      # Functional modules
│   ├── AutoScroll.ahk        # Inertial auto-scroll physics algorithm
│   ├── Brightness.ahk        # Screen dimming overlay
│   ├── ExcludedApps.ahk      # App exclusion list manager
│   ├── Hotkey.ahk            # Lock timer, Mute, Plain-text paste
│   ├── Language.ahk          # Dual-language localization (VI / EN)
│   ├── LockKeyboard.ahk      # Keyboard and mouse lock routine
│   ├── Menu.ahk              # System tray menu, Settings & About GUIs
│   ├── ToggleGesture.ahk     # Gesture state toggling and tray icon swap
│   └── Volume.ahk            # Mouse and hotkey volume control
├── docs/                     # GitHub Pages static site
├── image/                    # App icons, gesture icons, country flags
├── manifests/                # Microsoft WinGet package manifests
├── tools/                    # Automated build and UIAccess signing tools
├── README_VI.md              # Vietnamese documentation
└── Readme.md                 # English documentation
```

---

## 👨‍💻 Author & License

- **Author**: Nguyen Tri An
- **Email**: [nguyentrian87@gmail.com](mailto:nguyentrian87@gmail.com)
- **License**: Released under the [MIT License](LICENSE). Copyright © 2026 NGUYENTRIAN.
