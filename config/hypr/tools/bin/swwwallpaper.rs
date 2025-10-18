#!/usr/bin/env -S cargo +nightly -Zscript
---
[package]
edition = "2024"

[profile.dev]
opt-level = 3

[dependencies]
clap = { version = "4", features = ["derive"] }
---
use clap::{Parser, Subcommand};
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

fn hash_file(path: &Path) -> Option<String> {
  Command::new("sha1sum")
    .arg(path)
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| s.split_whitespace().next().map(String::from))
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
    .filter_map(|p| hash_file(&p).map(|h| (p, h)))
    .collect()
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
    eprintln!("An instance of the script is already running...");
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

fn ensure_swww_daemon() {
  if Command::new("swww")
    .arg("query")
    .output()
    .map(|o| !o.status.success())
    .unwrap_or(true)
  {
    let _ = Command::new("swww-daemon")
      .args(["--format", "xrgb"])
      .spawn();
    std::thread::sleep(std::time::Duration::from_millis(500));
    let _ = Command::new("swww").arg("restore").spawn();
  }
}

fn apply_wallpaper(wall_path: &Path, transition: &str) {
  let cursor_pos = Command::new("hyprctl")
    .arg("cursorpos")
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| s.lines().next().map(String::from))
    .unwrap_or_else(|| "0,0".to_string());

  println!(":: applying wall :: \"{}\"", wall_path.display());

  let _ = Command::new("swww")
    .arg("img")
    .arg(wall_path)
    .args(["--transition-bezier", ".43,1.19,1,.4"])
    .args(["--transition-type", transition])
    .args(["--transition-duration", "0.4"])
    .args(["--transition-fps", "60"])
    .arg("--invert-y")
    .args(["--transition-pos", &cursor_pos])
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
  ensure_swww_daemon();
  apply_wallpaper(&wall_path, transition);
}
