#!/usr/bin/env -S cargo +nightly -Zscript
---
[package]
edition = "2024"

[profile.dev]
opt-level = 3

[dependencies]
serde_json = "1.0"
---
use std::env;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

fn get_config_dir() -> PathBuf {
  env::var("XDG_CONFIG_HOME")
    .map(PathBuf::from)
    .unwrap_or_else(|_| PathBuf::from(env::var("HOME").unwrap_or_default()).join(".config"))
}

fn get_wallpaper_dir() -> PathBuf {
  let hyde_theme_dir = get_config_dir().join("hyde/themes");
  if hyde_theme_dir.join("wall.set").exists() {
    return hyde_theme_dir;
  }
  fs::read_to_string(get_config_dir().join("hyde/store.txt"))
    .ok()
    .and_then(|c| {
      c.lines()
        .find(|l| l.starts_with("hydeTheme="))
        .map(|l| l[10..].trim().to_string())
    })
    .map(|theme| get_config_dir().join(format!("hyde/themes/{}", theme)))
    .unwrap_or_else(|| hyde_theme_dir)
}

fn get_monitor_info() -> (i32, i32) {
  Command::new("hyprctl")
    .args(["-j", "monitors"])
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| serde_json::from_str::<serde_json::Value>(&s).ok())
    .and_then(|m| {
      m.as_array()?.iter().find_map(|mon| {
        mon["focused"].as_bool().filter(|&f| f).and_then(|_| {
          Some((
            mon["width"].as_i64()? as i32,
            (mon["scale"].as_f64()? * 100.0) as i32,
          ))
        })
      })
    })
    .unwrap_or((1920, 100))
}

fn find_wallpapers(dir: &Path) -> Vec<(PathBuf, String)> {
  fs::read_dir(dir)
    .ok()
    .into_iter()
    .flatten()
    .flatten()
    .map(|e| e.path())
    .filter(|p| {
      p.is_file()
        && p
          .extension()
          .and_then(|e| e.to_str())
          .map(|e| matches!(e.to_lowercase().as_str(), "gif" | "jpg" | "jpeg" | "png"))
          .unwrap_or(false)
    })
    .filter_map(|p| {
      Command::new("sha1sum")
        .arg(&p)
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .and_then(|s| s.split_whitespace().next().map(String::from))
        .map(|h| (p, h))
    })
    .collect()
}

fn main() {
  let conf_dir = get_config_dir();
  let theme_dir = get_wallpaper_dir();
  let thumb_dir = PathBuf::from(env::var("HOME").unwrap_or_default()).join(".cache/hyde/thumbs");

  let rofi_scale = env::var("ROFI_SCALE")
    .ok()
    .and_then(|s| s.parse().ok())
    .unwrap_or(10);
  let elem_border = env::var("HYPR_BORDER")
    .ok()
    .and_then(|s| s.parse::<i32>().ok())
    .unwrap_or(2)
    * 3;

  let (mon_x_res, mon_scale) = get_monitor_info();
  let col_count = (mon_x_res * 100 / mon_scale - 4 * rofi_scale) / ((28 + 8 + 5) * rofi_scale);

  let wallpapers = find_wallpapers(&theme_dir);
  let entries: String = wallpapers
    .iter()
    .filter_map(|(p, h)| {
      Some(format!(
        "{}\0icon\x1f{}/{}.sqre\n",
        p.file_name()?.to_string_lossy(),
        thumb_dir.display(),
        h
      ))
    })
    .collect();

  let _current = fs::read_link(theme_dir.join("wall.set"))
    .ok()
    .and_then(|p| p.file_name().map(|f| f.to_string_lossy().to_string()));

  if let Ok(mut rofi) = Command::new("rofi")
    .args([
      "-dmenu",
      "-theme-str",
      &format!("configuration {{font: \"JetBrainsMono Nerd Font {}\";}}", rofi_scale),
      "-theme-str",
      &format!("window{{width:100%;}} listview{{columns:{};spacing:5em;}} element{{border-radius:{}px;orientation:vertical;}} element-icon{{size:28em;border-radius:0em;}} element-text{{padding:1em;}}", col_count, elem_border),
      "-config",
      &conf_dir.join("rofi/selector.rasi").display().to_string(),
    ])
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .spawn()
  {
    if let Some(mut stdin) = rofi.stdin.take() {
      let _ = stdin.write_all(entries.as_bytes());
    }

    if let Ok(output) = rofi.wait_with_output() {
      if let Ok(selection) = String::from_utf8(output.stdout) {
        let selection = selection.trim();
        if !selection.is_empty() {
          if let Some((p, h)) = wallpapers
            .iter()
            .find(|(p, _)| p.file_name().map(|f| f.to_string_lossy() == selection).unwrap_or(false))
          {
            let _ = Command::new("swwwallpaper.rs").args(["set", p.to_str().unwrap_or("")]).spawn();
            let _ = Command::new("notify-send")
              .args(["-a", "t1", "-i", &format!("{}/{}.sqre", thumb_dir.display(), h), &format!(" {}", selection)])
              .spawn();
          }
        }
      }
    }
  }
}
