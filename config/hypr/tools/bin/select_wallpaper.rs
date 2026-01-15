#!/usr/bin/env -S cargo -Zscript
---
[package]
edition = "2024"

[profile.dev]
opt-level = 3

[dependencies]
anyhow = "1.0"
serde_json = "1.0"
---
use anyhow::{Context, Result};
use std::env;
use std::ffi::OsStr;
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
  get_config_dir().join("theme/themes")
}

fn try_get_monitor_info() -> Result<(i32, i32)> {
  let stdout = Command::new("hyprctl")
    .args(["-j", "monitors"])
    .output()?
    .stdout;

  let monitors = serde_json::from_str::<serde_json::Value>(&String::from_utf8(stdout)?)?;
  let focused_monitor = monitors
    .as_array()
    .and_then(|arr| {
      arr
        .iter()
        .find(|mon| mon["focused"].as_bool().unwrap_or(false))
    })
    .context("No focused monitor found")?;

  Ok((
    focused_monitor["width"].as_i64().context("Missing width")? as i32,
    (focused_monitor["scale"].as_f64().context("Missing scale")? * 100.0) as i32,
  ))
}

fn get_monitor_info() -> (i32, i32) {
  try_get_monitor_info().unwrap_or((1920, 100))
}

fn is_supported_image(path: &Path) -> bool {
  match path.extension().and_then(OsStr::to_str) {
    Some(ext) => matches!(ext.to_lowercase().as_str(), "gif" | "jpg" | "jpeg" | "png"),
    None => false,
  }
}

fn try_find_wallpapers(dir: &Path) -> Result<Vec<PathBuf>> {
  let files = fs::read_dir(dir)
    .context(format!("No such file or directory {:#?}", dir))?
    .flatten()
    .map(|entry| entry.path())
    .filter(|path| path.is_file() && is_supported_image(path));

  Ok(files.collect())
}

fn find_wallpapers(dir: &Path) -> Vec<PathBuf> {
  try_find_wallpapers(dir).unwrap()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
  let conf_dir = get_config_dir();
  let theme_dir = get_wallpaper_dir();
  let thumb_dir = PathBuf::from(env::var("HOME").unwrap_or_default()).join(".cache/theme/thumbs");

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
  let width = 30;
  let col_count = (mon_x_res * 100 / mon_scale - 4 * rofi_scale) / (width * rofi_scale);

  let mut wallpapers = find_wallpapers(&theme_dir);
  wallpapers.sort();
  println!("Found {} wallpapers", wallpapers.len());
  let entries: String = wallpapers
    .iter()
    .filter_map(|path| {
      let filename = path.file_name()?.to_string_lossy();
      Some(format!(
        "{}\0icon\x1f{}/{}.sqre\n",
        filename,
        thumb_dir.display(),
        filename
      ))
    })
    .collect();

  let rofi_command = Command::new("rofi")
    .args([
      "-dmenu",
      "-cycle",
      "-theme-str",
      &format!(
        "configuration {{ font: 'JetBrainsMono Nerd Font {}'; }}",
        rofi_scale
      ),
      "-theme-str",
      &format!(
        "window {{ width: 100%; }} \
            listview {{ columns: {}; spacing: 2em; }} \
            element {{ border-radius: {}px; orientation: vertical; }} \
            element-icon {{ size: {}em; border-radius: 0em; }} \
            element-text {{ padding: 1em; }}",
        col_count, elem_border, width
      ),
      "-config",
      &conf_dir.join("rofi/selector.rasi").display().to_string(),
    ])
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .spawn();

  if let Ok(mut rofi) = rofi_command {
    rofi
      .stdin
      .take()
      .map(|mut stdin| stdin.write_all(entries.as_bytes()));

    let selection = String::from_utf8(rofi.wait_with_output()?.stdout)?
      .trim()
      .to_string();

    if !selection.is_empty() {
      let wallpaper = wallpapers.iter().find(|path| {
        path
          .file_name()
          .map(|f| f.to_string_lossy() == selection)
          .unwrap_or(false)
      });

      if let Some(path) = wallpaper {
        match Command::new("set_wallpaper.rs")
          .args(["set", path.to_str().unwrap_or("")])
          .spawn()
        {
          Ok(_) => Command::new("notify-send")
            .args([
              "-a",
              "t1",
              "-i",
              &format!("{}/{}.sqre", thumb_dir.display(), selection),
              &format!(" {}", selection),
            ])
            .spawn()?,
          Err(e) => Command::new("notify-send")
            .args([
              "-a",
              "t1",
              "-i",
              &format!("{}/{}.sqre", thumb_dir.display(), selection),
              &format!("Unable to set wallpaper: {}", e),
            ])
            .spawn()?,
        };
      }
    }
  }
  Ok(())
}
