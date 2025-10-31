#!/usr/bin/env -S cargo +nightly -Zscript
---
[package]
edition = "2024"

[profile.dev]
opt-level = 3

[dependencies]
anyhow = "1.0"
clap = { version = "4", features = ["derive"] }
sha1 = "0.10"
---
use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use sha1::{Digest, Sha1};
use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

const LOCK_FILE_BASE: &str = "/tmp/hyde";

#[derive(Parser)]
#[command(name = "swwwallpaper")]
#[command(about = "Hyde wallpaper manager", long_about = None)]
struct Cli {
  #[command(subcommand)]
  command: Commands,
}

#[derive(Subcommand)]
enum Commands {
  #[command(about = "Switch to next wallpaper")]
  Next,
  #[command(about = "Switch to previous wallpaper")]
  Previous,
  #[command(about = "Set specific wallpaper")]
  Set { path: PathBuf },
}

struct LockGuard(PathBuf);

impl Drop for LockGuard {
  fn drop(&mut self) {
    let _ = fs::remove_file(&self.0);
  }
}

fn get_config_dir() -> PathBuf {
  std::env::var("XDG_CONFIG_HOME")
    .map(PathBuf::from)
    .unwrap_or_else(|_| PathBuf::from(std::env::var("HOME").unwrap_or_default()).join(".config"))
}

fn get_cache_dir() -> PathBuf {
  PathBuf::from(std::env::var("HOME").unwrap_or_default()).join(".cache/hyde")
}

fn get_wallpaper_dir() -> PathBuf {
  let conf_dir = get_config_dir();
  let hyde_theme_dir = conf_dir.join("hyde/themes");
  if hyde_theme_dir.join("wall.set").exists() {
    return hyde_theme_dir;
  }
  fs::read_to_string(conf_dir.join("hyde/store.txt"))
    .ok()
    .and_then(|c| {
      c.lines()
        .find(|l| l.starts_with("hydeTheme="))
        .map(|l| l[10..].trim().to_string())
    })
    .map(|theme| conf_dir.join(format!("hyde/themes/{}", theme)))
    .unwrap_or(hyde_theme_dir)
}

// fn hash_file(path: &Path) -> Option<String> {
//   let data = fs::read(path).ok()?;
//   let hash = Sha1::digest(&data);
//   Some(format!("{:x}", hash))
// }

fn hash_file(path: &PathBuf) -> Option<String> {
  Command::new("sha1sum")
    .arg(path)
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| s.split_whitespace().next().map(String::from))
    .map(|hash| hash)
}

fn is_supported_image(path: &Path) -> bool {
  match path.extension().and_then(OsStr::to_str) {
    Some(ext) => matches!(ext.to_lowercase().as_str(), "gif" | "jpg" | "jpeg" | "png"),
    None => false,
  }
}

fn try_find_wallpapers(dir: &Path) -> Result<Vec<(PathBuf, String)>> {
  let files = fs::read_dir(dir)
    .context(format!("No such file or directory {:#?}", dir))?
    .flatten()
    .map(|entry| entry.path())
    .filter(|path| path.is_file() && is_supported_image(path));

  let images_with_hash = files
    .filter_map(|path| {
      let hash = Sha1::digest(fs::read(&path).ok()?);
      Some((path, format!("{:x}", hash)))
    })
    .collect();

  Ok(images_with_hash)
}

fn find_wallpapers(dir: &Path) -> Vec<(PathBuf, String)> {
  try_find_wallpapers(dir).unwrap()
}

fn create_lock() -> Option<LockGuard> {
  let uid = Command::new("id")
    .arg("-u")
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| s.trim().parse::<u32>().ok())
    .unwrap_or(1000);
  let lock_path = PathBuf::from(format!("{}{}swwwallpaper.lock", LOCK_FILE_BASE, uid));

  if lock_path.exists() {
    eprintln!("Lock file exists: {}", lock_path.display());
    return None;
  }

  fs::write(&lock_path, "").ok()?;
  Some(LockGuard(lock_path))
}

fn cache_wall(wall_path: &Path, hash: &str, scr_dir: &Path, theme_dir: &Path, cache_dir: &Path) {
  let thumb_dir = cache_dir.join("thumbs");
  let dcol_dir = cache_dir.join("dcols");

  let _ = fs::remove_file(theme_dir.join("wall.set"));
  let _ = std::os::unix::fs::symlink(wall_path, theme_dir.join("wall.set"));
  let _ = fs::remove_file(cache_dir.join("wall.set"));
  let _ = std::os::unix::fs::symlink(wall_path, cache_dir.join("wall.set"));

  let _ = Command::new(scr_dir.join("swwwallcache.sh"))
    .args(["-w", wall_path.to_str().unwrap_or("")])
    .output();
  let _ = Command::new(scr_dir.join("swwwallbash.sh"))
    .arg(wall_path)
    .spawn();

  for (link, ext) in [
    ("wall.sqre", "sqre"),
    ("wall.thmb", "thmb"),
    ("wall.blur", "blur"),
    ("wall.quad", "quad"),
  ] {
    let _ = fs::remove_file(cache_dir.join(link));
    let _ = std::os::unix::fs::symlink(
      thumb_dir.join(format!("{}.{}", hash, ext)),
      cache_dir.join(link),
    );
  }

  let _ = fs::remove_file(cache_dir.join("wall.dcol"));
  let _ = std::os::unix::fs::symlink(
    dcol_dir.join(format!("{}.dcol", hash)),
    cache_dir.join("wall.dcol"),
  );
}

fn apply_wallpaper(wall_path: &Path, transition: &str) {
  let cursor_pos = Command::new("hyprctl")
    .arg("cursorpos")
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| s.lines().next().map(String::from))
    .unwrap_or_else(|| "0,0".to_string());

  let _ = Command::new("hyprctl")
    .arg("hyprpaper")
    .arg("reload")
    .arg(format!(",{}", wall_path.display()))
    .spawn();
}

fn main() {
  let cli = Cli::parse();

  let _lock = match create_lock() {
    Some(l) => l,
    None => return,
  };

  let scr_dir = std::env::current_exe()
    .ok()
    .and_then(|p| p.parent().map(|p| p.to_path_buf()))
    .unwrap_or_else(|| PathBuf::from("."));
  let cache_dir = get_cache_dir();
  let theme_dir = get_wallpaper_dir();

  if !theme_dir.exists() {
    eprintln!("ERROR: \"{}\" does not exist", theme_dir.display());
    return;
  }

  let wallpapers = find_wallpapers(&theme_dir);
  let wall_set = theme_dir.join("wall.set");

  if !fs::read_link(&wall_set)
    .ok()
    .and_then(|p| p.canonicalize().ok())
    .is_some()
    && !wallpapers.is_empty()
  {
    eprintln!("fixing link :: {}", wall_set.display());
    let _ = std::os::unix::fs::symlink(&wallpapers[0].0, &wall_set);
  }

  let (wall_path, hash, transition) = match cli.command {
    Commands::Set { path } => {
      if !path.is_file() {
        eprintln!("Error: \"{}\" is not a valid file", path.display());
        std::process::exit(1);
      }
      hash_file(&path).map(|h| (path, h, "grow"))
    }
    Commands::Next | Commands::Previous => {
      let current_hash = fs::read_link(&wall_set).ok().and_then(|p| hash_file(&p));
      current_hash.and_then(|cur_hash| {
        let idx = wallpapers.iter().position(|(_, h)| h == &cur_hash)?;
        let new_idx = match (&cli.command, idx) {
          (Commands::Next, _) => (idx + 1) % wallpapers.len(),
          (Commands::Previous, _idx @ 0) => wallpapers.len() - 1,
          (Commands::Previous, idx) => idx - 1,
          _ => unreachable!(),
        };
        let (path, hash) = wallpapers.get(new_idx)?;
        let transition = match cli.command {
          Commands::Next => "grow",
          Commands::Previous => "outer",
          _ => unreachable!(),
        };
        Some((path.clone(), hash.clone(), transition))
      })
    }
  }
  .unwrap_or_else(|| {
    eprintln!("Failed to determine wallpaper");
    std::process::exit(1);
  });

  cache_wall(&wall_path, &hash, &scr_dir, &theme_dir, &cache_dir);
  apply_wallpaper(&wall_path, transition);
}
