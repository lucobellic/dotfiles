#!/usr/bin/env -S cargo -Zscript
---
[package]
edition = "2024"

[profile.dev]
opt-level = 3

[dependencies]
anyhow = "1.0"
clap = { version = "4", features = ["derive"] }
---
use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

const LOCK_FILE_BASE: &str = "/tmp/theme";

#[derive(Parser)]
#[command(name = "set_wallpaper")]
#[command(about = "Wallpaper manager", long_about = None)]
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
  #[command(about = "Generate cache for all wallpapers")]
  CacheAll,
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
  PathBuf::from(std::env::var("HOME").unwrap_or_default()).join(".cache/theme")
}

fn get_wallpaper_dir() -> PathBuf {
  get_config_dir().join("theme/themes")
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
    .filter(|path| path.is_file() && is_supported_image(path))
    .collect();

  Ok(files)
}

fn find_wallpapers(dir: &Path) -> Vec<PathBuf> {
  try_find_wallpapers(dir).unwrap_or_default()
}

fn is_cache_valid(wall_name: &str, cache_dir: &Path) -> bool {
  let thumb_dir = cache_dir.join("thumbs");

  // Check all required thumbnail files exist
  for ext in ["thmb", "sqre", "blur", "quad"] {
    if !thumb_dir.join(format!("{}.{}", wall_name, ext)).exists() {
      return false;
    }
  }
  true
}

fn generate_thumbnails(wall_path: &Path, wall_name: &str, cache_dir: &Path) -> Result<()> {
  let thumb_dir = cache_dir.join("thumbs");
  fs::create_dir_all(&thumb_dir).context("Failed to create thumbs directory")?;

  let base_path = thumb_dir.join(wall_name);
  let wall_path_str = wall_path.to_str().context("Invalid wall path")?;

  println!("Generating thumbnails for {}", wall_name);

  // Notify user that cache generation has started
  let _ = Command::new("notify-send")
    .args([
      "-a",
      "Wallpaper",
      "-i",
      "image-loading",
      "Wallpaper Cache",
      &format!("Generating thumbnails for {}", wall_name),
    ])
    .spawn();

  // 1. Generate .thmb (1000x1000)
  Command::new("magick")
    .args([
      &format!("{}[0]", wall_path_str),
      "-strip",
      "-resize",
      "1000",
      "-gravity",
      "center",
      "-extent",
      "1000",
      "-quality",
      "90",
      &format!("{}.thmb", base_path.display()),
    ])
    .output()
    .context("Failed to generate .thmb")?;

  // 2. Generate .sqre (500x500)
  Command::new("magick")
    .args([
      &format!("{}[0]", wall_path_str),
      "-strip",
      "-thumbnail",
      "500x500^",
      "-gravity",
      "center",
      "-extent",
      "500x500",
      &format!("{}.sqre", base_path.display()),
    ])
    .output()
    .context("Failed to generate .sqre")?;

  // 3. Generate .blur
  Command::new("magick")
    .args([
      &format!("{}[0]", wall_path_str),
      "-strip",
      "-scale",
      "10%",
      "-blur",
      "0x3",
      "-resize",
      "100%",
      &format!("{}.blur", base_path.display()),
    ])
    .output()
    .context("Failed to generate .blur")?;

  // 4. Generate .quad (complex composite)
  Command::new("magick")
    .args([
      &format!("{}.sqre", base_path.display()),
      "(",
      "-size",
      "500x500",
      "xc:white",
      "-fill",
      "rgba(0,0,0,0.7)",
      "-draw",
      "polygon 400,500 500,500 500,0 450,0",
      "-fill",
      "black",
      "-draw",
      "polygon 500,500 500,0 450,500",
      ")",
      "-alpha",
      "Off",
      "-compose",
      "CopyOpacity",
      "-composite",
      &format!("{}.quad", base_path.display()),
    ])
    .output()
    .context("Failed to generate .quad")?;

  // Notify user that cache generation is complete
  let _ = Command::new("notify-send")
    .args([
      "-a",
      "Wallpaper",
      "-i",
      "image-x-generic",
      "Wallpaper Cache",
      &format!("Thumbnails generated for {}", wall_name),
    ])
    .spawn();

  Ok(())
}

fn create_lock() -> Option<LockGuard> {
  let uid = Command::new("id")
    .arg("-u")
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| s.trim().parse::<u32>().ok())
    .unwrap_or(1000);
  let lock_path = PathBuf::from(format!("{}{}wallpaper.lock", LOCK_FILE_BASE, uid));

  if lock_path.exists() {
    eprintln!("Lock file exists: {}", lock_path.display());
    return None;
  }

  fs::write(&lock_path, "").ok()?;
  Some(LockGuard(lock_path))
}

fn cache_wall(wall_path: &Path, theme_dir: &Path, cache_dir: &Path) {
  let thumb_dir = cache_dir.join("thumbs");
  let wall_name = wall_path.file_name().unwrap_or_default().to_string_lossy();

  let _ = fs::remove_file(theme_dir.join("wall.set"));
  let _ = std::os::unix::fs::symlink(wall_path, theme_dir.join("wall.set"));
  let _ = fs::remove_file(cache_dir.join("wall.set"));
  let _ = std::os::unix::fs::symlink(wall_path, cache_dir.join("wall.set"));

  // Only generate thumbnails if cache doesn't exist
  if !is_cache_valid(&wall_name, cache_dir) {
    println!("Generating thumbnail cache for {}", wall_path.display());
    if let Err(e) = generate_thumbnails(wall_path, &wall_name, cache_dir) {
      eprintln!("Warning: Failed to generate thumbnails: {}", e);
    }
  } else {
    println!("Using existing thumbnail cache for {}", wall_path.display());
  }

  for (link, ext) in [
    ("wall.sqre", "sqre"),
    ("wall.thmb", "thmb"),
    ("wall.blur", "blur"),
    ("wall.quad", "quad"),
  ] {
    let _ = fs::remove_file(cache_dir.join(link));
    let _ = std::os::unix::fs::symlink(
      thumb_dir.join(format!("{}.{}", wall_name, ext)),
      cache_dir.join(link),
    );
  }
}

fn apply_awww_wallpaper(wall_path: &Path) {
  let _ = Command::new("awww")
    .args([
      "img",
      &format!("{}", wall_path.display()),
      "--resize",
      "crop",
      "--transition-type",
      "none",
    ])
    .spawn();
}

fn apply_hyprpaper_wallpaper(_wall_path: &Path) {
  // restart hyprpaper until hyprctl with hyprpaper is fixed
  let _ = Command::new("pkill").arg("hyprpaper").status();
  // Use setsid to fully detach the process from the parent session
  let _ = Command::new("setsid")
    .arg("hyprpaper")
    .stdin(Stdio::null())
    .stdout(Stdio::null())
    .stderr(Stdio::null())
    .spawn();
  // let _ = Command::new("hyprctl")
  //   .arg("hyprpaper")
  //   .arg("reload")
  //   .arg(format!(",{}", wall_path.display()))
  //   .spawn();
}

fn main() {
  let cli = Cli::parse();

  let _lock = match create_lock() {
    Some(l) => l,
    None => return,
  };

  let _scr_dir = std::env::current_exe()
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
    let _ = std::os::unix::fs::symlink(&wallpapers[0], &wall_set);
  }

  match cli.command {
    Commands::CacheAll => {
      if wallpapers.is_empty() {
        eprintln!("No wallpapers found in {}", theme_dir.display());
        return;
      }

      let total = wallpapers.len();
      println!("Found {} wallpapers to process", total);

      let _ = Command::new("notify-send")
        .args([
          "-a",
          "Wallpaper",
          "-i",
          "image-loading",
          "Wallpaper Cache",
          &format!("Starting cache generation for {} wallpapers", total),
        ])
        .spawn();

      let mut cached = 0;
      let mut generated = 0;

      for (idx, wallpaper) in wallpapers.iter().enumerate() {
        let wall_name = wallpaper.file_name().unwrap_or_default().to_string_lossy();
        println!(
          "Processing [{}/{}]: {}",
          idx + 1,
          total,
          wallpaper.display()
        );

        if is_cache_valid(&wall_name, &cache_dir) {
          println!("  Cache already exists, skipping");
          cached += 1;
        } else {
          match generate_thumbnails(wallpaper, &wall_name, &cache_dir) {
            Ok(_) => {
              println!("  Generated thumbnails");
              generated += 1;
            }
            Err(e) => {
              eprintln!("  Failed to generate thumbnails: {}", e);
            }
          }
        }
      }

      let _ = Command::new("notify-send")
        .args([
          "-a",
          "Wallpaper",
          "-i",
          "image-x-generic",
          "Wallpaper Cache",
          &format!(
            "Complete! Generated: {}, Already cached: {}, Total: {}",
            generated, cached, total
          ),
        ])
        .spawn();

      println!("\nCache generation complete!");
      println!("  Generated: {}", generated);
      println!("  Already cached: {}", cached);
      println!("  Total processed: {}", total);
    }
    _ => {
      let (wall_path, _transition) = match cli.command {
        Commands::Set { path } => {
          if !path.is_file() {
            eprintln!("Error: \"{}\" is not a valid file", path.display());
            std::process::exit(1);
          }
          Some((path, "grow"))
        }
        Commands::Next | Commands::Previous => {
          let current_path = fs::read_link(&wall_set)
            .ok()
            .and_then(|p| p.canonicalize().ok());
          current_path.and_then(|cur_path| {
            let idx = wallpapers.iter().position(|p| p == &cur_path)?;
            let new_idx = match (&cli.command, idx) {
              (Commands::Next, _) => (idx + 1) % wallpapers.len(),
              (Commands::Previous, _idx @ 0) => wallpapers.len() - 1,
              (Commands::Previous, idx) => idx - 1,
              _ => unreachable!(),
            };
            let path = wallpapers.get(new_idx)?;
            let transition = match cli.command {
              Commands::Next => "grow",
              Commands::Previous => "outer",
              _ => unreachable!(),
            };
            Some((path.clone(), transition))
          })
        }
        _ => unreachable!(),
      }
      .unwrap_or_else(|| {
        eprintln!("Failed to determine wallpaper");
        std::process::exit(1);
      });

      cache_wall(&wall_path, &theme_dir, &cache_dir);
      apply_hyprpaper_wallpaper(&wall_path);
      // apply_awww_wallpaper(&wall_path);
    }
  }
}
