# font_modify_watcher.py
#
# Applies modify_font settings only when DMMono Nerd Font is the active
# font_family. Uses boss.call_remote_control to load config overrides so
# kitty picks them up at runtime without a full restart.
#
# Registered in kitty.conf with:
#   watcher font_modify_watcher.py

from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import get_options
from kitty.window import Window

# Font name fragment to match (case-insensitive, spaces stripped for robustness)
TARGET_FONT = "dmmono"

# modify_font overrides to apply when the target font is active
FONT_OVERRIDES = [
    "modify_font underline_position 2",
    "modify_font underline_thickness 100%",
    "modify_font strikethrough_position -2px",
    "modify_font cell_height 2px",
]

# Neutral reset values to clear overrides when a different font is active
FONT_RESETS = [
    "modify_font underline_position 0",
    "modify_font underline_thickness 100%",
    "modify_font strikethrough_position 0",
    "modify_font cell_height 0",
]


def _current_font_family() -> str:
    """Return the font_family string from current kitty options.

    Uses get_options() which reflects the live config, unlike boss.opts
    which does not exist as a public attribute.
    """
    try:
        opts = get_options()
        # FontSpec.__str__ returns created_from_string (e.g. "DMMono Nerd Font Medium")
        # Strip spaces for a reliable substring match.
        return str(opts.font_family).replace(" ", "").lower()
    except Exception:
        return ""


def _apply_modify_font(boss: Boss, window: Window) -> None:
    """Apply or reset modify_font overrides depending on the active font."""
    font = _current_font_family()
    print(f"[font_modify_watcher] Current font family: '{font}'")
    overrides = FONT_OVERRIDES if TARGET_FONT in font else FONT_RESETS

    args: list[str] = ["load-config"]
    for override in overrides:
        args += ["--override", override]

    try:
        boss.call_remote_control(window, tuple(args))
    except Exception as e:
        import sys

        print(f"[font_modify_watcher] Error applying modify_font: {e}", file=sys.stderr)


def on_load(boss: Boss, data: dict[str, Any]) -> None:
    """Called once when this watcher module is first loaded."""
    # Nothing to do here; on_resize handles initial window creation too.
    pass


def on_resize(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    """Called on window resize and also on initial window creation.

    Detect initial creation by checking that old_geometry is all zeros.
    """
    old_geo = data.get("old_geometry")
    if old_geo is not None and old_geo.xnum == 0 and old_geo.ynum == 0:
        # This is the initial window creation event
        _apply_modify_font(boss, window)
