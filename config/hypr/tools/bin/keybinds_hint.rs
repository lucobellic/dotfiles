#!/usr/bin/env -S cargo +nightly -Zscript
---
[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
---
use serde::{Deserialize, Serialize};
use std::io::Write;
use std::process::{Command, Stdio};

#[derive(Debug, Deserialize, Serialize)]
struct Bind {
  locked: bool,
  mouse: bool,
  release: bool,
  repeat: bool,
  non_consuming: bool,
  has_description: bool,
  modmask: u32,
  submap: String,
  key: String,
  keycode: u32,
  catch_all: bool,
  description: String,
  dispatcher: String,
  arg: String,
}

fn modmask_to_string(modmask: u32) -> String {
  let mut parts = Vec::new();

  if modmask & 64 != 0 {
    parts.push("SUPER");
  }
  if modmask & 8 != 0 {
    parts.push("ALT");
  }
  if modmask & 4 != 0 {
    parts.push("CTRL");
  }
  if modmask & 1 != 0 {
    parts.push("SHIFT");
  }

  if parts.is_empty() {
    String::new()
  } else {
    parts.join(" + ")
  }
}

fn format_key(key: &str) -> String {
  match key {
    "mouse_up" => "󱕑".to_string(),
    "mouse_down" => "󱕐".to_string(),
    "mouse:272" => "󰍽".to_string(),
    "mouse:273" => "󰍽".to_string(),
    "UP" => "".to_string(),
    "DOWN" => "".to_string(),
    "LEFT" => "".to_string(),
    "RIGHT" => "".to_string(),
    "XF86AudioLowerVolume" => "󰝞".to_string(),
    "XF86AudioMicMute" => "󰍭".to_string(),
    "XF86AudioMute" => "󰓄".to_string(),
    "XF86AudioNext" => "󰒭".to_string(),
    "XF86AudioPause" => "󰏤".to_string(),
    "XF86AudioPlay" => "󰐊".to_string(),
    "XF86AudioPrev" => "󰒮".to_string(),
    "XF86AudioRaiseVolume" => "󰝝".to_string(),
    "XF86MonBrightnessDown" => "󰃜".to_string(),
    "XF86MonBrightnessUp" => "󰃠".to_string(),
    "backspace" => "󰁮".to_string(),
    _ => key.to_string(),
  }
}

fn get_category(dispatcher: &str) -> &str {
  match dispatcher {
    "exec" => "Execute a Command",
    "global" => "Global",
    "exit" => "Exit Hyprland Session",
    "fullscreen" | "fakefullscreen" => "Toggle Functions",
    "movefocus" | "movewindow" | "resizeactive" => "Window Functions",
    "togglefloating" | "togglegroup" | "togglespecialworkspace" | "togglesplit" => {
      "Toggle Functions"
    }
    "workspace" | "movetoworkspace" | "movetoworkspacesilent" => "Navigate Workspace",
    "changegroupactive" => "Change Active Group",
    _ => "Other",
  }
}

fn format_description(bind: &Bind) -> String {
  if bind.has_description && !bind.description.is_empty() {
    return bind.description.clone();
  }

  // Generate description from dispatcher and arg
  let dispatcher_desc = match bind.dispatcher.as_str() {
    "movefocus" => "Move Focus",
    "resizeactive" => "Resize Active Window",
    "exit" => "End Hyprland Session",
    "movetoworkspacesilent" => "Silently Move to Workspace",
    "movewindow" => "Move Window",
    "movetoworkspace" => "Move To Workspace",
    "workspace" => "Navigate to Workspace",
    "togglefloating" => "Toggle Floating",
    "fullscreen" => "Toggle Fullscreen",
    "togglegroup" => "Toggle Group",
    "togglesplit" => "Toggle Split",
    "togglespecialworkspace" => "Toggle Special Workspace",
    "changegroupactive" => "Switch Active Group",
    _ => &bind.dispatcher,
  };

  let arg_desc = match bind.arg.as_str() {
    "r+1" => "Relative Right",
    "r-1" => "Relative Left",
    "e+1" => "Next",
    "e-1" => "Previous",
    "d" => "Down",
    "l" => "Left",
    "r" => "Right",
    "u" => "Up",
    "f" => "Forward",
    "b" => "Backward",
    _ => &bind.arg,
  };

  if bind.dispatcher == "exec" {
    arg_desc.to_string()
  } else if arg_desc.is_empty() {
    dispatcher_desc.to_string()
  } else {
    format!("{} {}", dispatcher_desc, arg_desc)
  }
}

fn get_hypr_setting(setting: &str) -> i32 {
  Command::new("hyprctl")
    .arg("-j")
    .arg("getoption")
    .arg(setting)
    .output()
    .ok()
    .and_then(|output| {
      if output.status.success() {
        serde_json::from_slice::<serde_json::Value>(&output.stdout)
          .ok()
          .and_then(|json| json["int"].as_i64())
          .map(|v| v as i32)
      } else {
        None
      }
    })
    .unwrap_or(0)
}

fn get_gsetting(schema: &str, key: &str) -> String {
  Command::new("gsettings")
    .arg("get")
    .arg(schema)
    .arg(key)
    .output()
    .ok()
    .and_then(|output| {
      if output.status.success() {
        Some(
          String::from_utf8_lossy(&output.stdout)
            .trim()
            .replace("'", ""),
        )
      } else {
        None
      }
    })
    .unwrap_or_default()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
  // Get binds from hyprctl
  let output = Command::new("hyprctl").arg("binds").arg("-j").output()?;

  if !output.status.success() {
    eprintln!("Failed to run hyprctl binds");
    std::process::exit(1);
  }

  let binds: Vec<Bind> = serde_json::from_slice(&output.stdout)?;

  // Format binds for rofi
  let mut lines = Vec::new();
  let header = format!("{:<35} {} {:<20}", "󰌌 Keybinds", "", "Description");
  let term_width = 100; // fallback if tput fails
  let linebreak = "━".repeat(term_width);

  lines.push(header);
  lines.push(linebreak.clone());

  // Group by category
  let mut grouped: std::collections::HashMap<String, Vec<String>> =
    std::collections::HashMap::new();

  for bind in binds {
    let modkeys = modmask_to_string(bind.modmask);
    let key = format_key(&bind.key);
    let keybind = if modkeys.is_empty() {
      key.clone()
    } else {
      format!("{} + {}", modkeys, key)
    };

    let description = format_description(&bind);
    let category = get_category(&bind.dispatcher).to_string();

    let formatted = format!("{:<25} > {:<30}", keybind, description);

    grouped
      .entry(category)
      .or_insert_with(Vec::new)
      .push(formatted);
  }

  // Sort categories and output
  let mut categories: Vec<_> = grouped.keys().collect();
  categories.sort();

  for category in categories {
    if let Some(binds) = grouped.get(category) {
      lines.push(category.to_string());
      for bind in binds {
        lines.push(bind.clone());
      }
      lines.push(linebreak.clone());
    }
  }

  let rofi_input = lines.join("\n");

  // Get Hyprland styling settings
  let hypr_border = get_hypr_setting("decoration:rounding");
  let hypr_width = get_hypr_setting("general:border_size");
  let wind_border = (hypr_border * 3) / 2;
  let elem_border = if hypr_border == 0 { 5 } else { hypr_border };

  // Get system font and icon theme
  let font_size = get_gsetting("org.gnome.desktop.interface", "font-name")
    .split_whitespace()
    .last()
    .and_then(|s| s.parse::<u32>().ok())
    .unwrap_or(11);
  let icon_theme = get_gsetting("org.gnome.desktop.interface", "icon-theme");

  // Build rofi theme overrides
  let kb_hint_width = "48em";
  let kb_hint_height = "35em";
  let kb_hint_line = 13;

  let r_override = format!(
    "window {{height: {}; width: {}; border: {}px; border-radius: {}px;}} \
     entry {{border-radius: {}px;}} \
     element {{border-radius: {}px;}} \
     listview {{ lines: {}; }}",
    kb_hint_height, kb_hint_width, hypr_width, wind_border, elem_border, elem_border, kb_hint_line
  );

  let fnt_override = format!(
    "configuration {{font: \"JetBrainsMono Nerd Font {}\";}}",
    font_size
  );
  let icon_override = format!("configuration {{icon-theme: \"{}\";}}", icon_theme);

  // Launch rofi with dmenu
  let conf_dir = std::env::var("XDG_CONFIG_HOME")
    .unwrap_or_else(|_| format!("{}/.config", std::env::var("HOME").unwrap_or_default()));
  let rofi_config = format!("{}/rofi/clipboard.rasi", conf_dir);

  let mut rofi = Command::new("rofi")
    .args(&[
      "-dmenu",
      "-p",
      "",
      "-i",
      "-theme-str",
      &fnt_override,
      "-theme-str",
      &r_override,
      "-theme-str",
      &icon_override,
      "-config",
      &rofi_config,
    ])
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .spawn()?;

  if let Some(mut stdin) = rofi.stdin.take() {
    stdin.write_all(rofi_input.as_bytes())?;
  }

  let output = rofi.wait_with_output()?;

  if !output.status.success() {
    // User cancelled
    std::process::exit(0);
  }

  // Parse selection and execute if needed
  let selection = String::from_utf8_lossy(&output.stdout);
  let selection = selection.trim();

  if !selection.is_empty()
    && !selection.starts_with("━")
    && !selection.starts_with("󰌌")
    && !selection.ends_with(":")
    && selection.contains(">")
  {
    // Extract keybind from selection (first part before >)
    if let Some(pos) = selection.find('>') {
      let _keybind = selection[..pos].trim();
      // Note: Executing the selected bind would require mapping back to dispatcher+arg
      // This is left as a future enhancement
    }
  }

  Ok(())
}
