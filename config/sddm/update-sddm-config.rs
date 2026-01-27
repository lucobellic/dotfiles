#!/usr/bin/env -S cargo -Zscript
---
[package]
name = "update-sddm-config"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1.0"
clap = { version = "4", features = ["derive"] }
---
use anyhow::{Context, Result};
use clap::Parser;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

const SDDM_CONF: &str = "/etc/sddm.conf";
const THEME_DEST: &str = "/usr/share/sddm/themes/silent";
const FONTS_DEST: &str = "/usr/share/fonts";

#[derive(Parser)]
#[command(name = "update-sddm-config")]
#[command(about = "Install SilentSDDM theme, fonts, and update SDDM configuration")]
struct Cli {
  /// Theme source path (defaults to finding it in Nix store)
  #[arg(short, long)]
  theme_source: Option<PathBuf>,
}

fn find_theme_source() -> Result<PathBuf> {
  // Try to find SilentSDDM in the Nix store
  let output = Command::new("find")
    .args([
      "/nix/store",
      "-name",
      "silent",
      "-type",
      "d",
      "-path",
      "*/share/sddm/themes/silent",
    ])
    .output()
    .context("Failed to run find command")?;

  let path_str = String::from_utf8(output.stdout)
    .context("Invalid UTF-8 in find output")?
    .lines()
    .next()
    .ok_or_else(|| anyhow::anyhow!("Could not find SilentSDDM theme in Nix store"))?
    .trim()
    .to_string();

  Ok(PathBuf::from(path_str))
}

fn backup_if_exists(path: &Path) -> Result<()> {
  if path.exists() {
    let timestamp = std::time::SystemTime::now()
      .duration_since(std::time::UNIX_EPOCH)
      .unwrap()
      .as_secs();
    let backup_path = format!("{}.backup.{}", path.display(), timestamp);
    let backup_path = PathBuf::from(backup_path);
    
    if path.is_dir() {
      copy_dir_all(path, &backup_path).with_context(|| format!("Failed to backup directory {}", path.display()))?;
    } else if path.is_file() {
      fs::copy(path, &backup_path).with_context(|| format!("Failed to backup file {}", path.display()))?;
    }
    println!("Backed up {} to {}", path.display(), backup_path.display());
  }
  Ok(())
}

fn install_theme(theme_source: &Path) -> Result<()> {
  let theme_dest = PathBuf::from(THEME_DEST);

  println!(
    "Installing theme from {} to {}...",
    theme_source.display(),
    theme_dest.display()
  );

  // Backup existing theme if it exists
  if theme_dest.exists() {
    backup_if_exists(&theme_dest)?;
    fs::remove_dir_all(&theme_dest).context("Failed to remove existing theme directory")?;
  }

  // Create parent directory if needed
  if let Some(parent) = theme_dest.parent() {
    fs::create_dir_all(parent).context("Failed to create theme destination parent directory")?;
  }

  // Copy theme directory
  copy_dir_all(theme_source, &theme_dest).context("Failed to copy theme directory")?;

  println!("Theme installed successfully!");
  Ok(())
}

fn install_fonts(theme_source: &Path) -> Result<()> {
  let fonts_source = theme_source.join("fonts");
  let fonts_dest = PathBuf::from(FONTS_DEST);

  if !fonts_source.exists() {
    println!("Warning: No fonts directory found in theme package");
    return Ok(());
  }

  // Check if fonts directory has any files
  let has_files = fs::read_dir(&fonts_source)
    .context("Failed to read fonts source directory")?
    .next()
    .is_some();

  if !has_files {
    println!("Warning: Fonts directory is empty");
    return Ok(());
  }

  println!("Installing fonts to {}...", fonts_dest.display());

  // Create fonts destination if needed
  fs::create_dir_all(&fonts_dest).context("Failed to create fonts destination directory")?;

  // Copy all font files
  for entry in fs::read_dir(&fonts_source).context("Failed to read fonts source directory")? {
    let entry = entry.context("Failed to read directory entry")?;
    let src_path = entry.path();
    let dest_path = fonts_dest.join(entry.file_name());

    if src_path.is_file() {
      fs::copy(&src_path, &dest_path)
        .with_context(|| format!("Failed to copy font file {}", src_path.display()))?;
    } else if src_path.is_dir() {
      copy_dir_all(&src_path, &dest_path)
        .with_context(|| format!("Failed to copy font directory {}", src_path.display()))?;
    }
  }

  // Update font cache
  if Command::new("fc-cache")
    .args(["-f", fonts_dest.to_str().unwrap()])
    .output()
    .is_ok()
  {
    println!("Font cache updated");
  }

  println!("Fonts installed successfully!");
  Ok(())
}

fn copy_dir_all(src: &Path, dst: &Path) -> Result<()> {
  fs::create_dir_all(dst)
    .with_context(|| format!("Failed to create directory {}", dst.display()))?;

  for entry in
    fs::read_dir(src).with_context(|| format!("Failed to read directory {}", src.display()))?
  {
    let entry = entry.context("Failed to read directory entry")?;
    let src_path = entry.path();
    let dst_path = dst.join(entry.file_name());

    if src_path.is_dir() {
      copy_dir_all(&src_path, &dst_path)?;
    } else {
      fs::copy(&src_path, &dst_path).with_context(|| {
        format!(
          "Failed to copy {} to {}",
          src_path.display(),
          dst_path.display()
        )
      })?;
    }
  }

  Ok(())
}

fn update_sddm_config() -> Result<()> {
  let sddm_conf = PathBuf::from(SDDM_CONF);

  println!("Updating SDDM configuration...");

  // Backup existing config if it exists
  backup_if_exists(&sddm_conf)?;

  // Complete new configuration
  let new_config = r#"[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard

[Theme]
Current=silent
"#;

  // Write complete new config (replacing any existing config)
  fs::write(&sddm_conf, new_config).context("Failed to write SDDM config")?;

  println!("SDDM config updated successfully!");
  Ok(())
}

fn main() -> Result<()> {
  let cli = Cli::parse();

  // Get theme source path
  let theme_source = match cli.theme_source {
    Some(path) => path,
    None => find_theme_source().context("Failed to find theme source in Nix store")?,
  };

  if !theme_source.exists() {
    anyhow::bail!(
      "Theme source path does not exist: {}",
      theme_source.display()
    );
  }

  println!("==========================================");
  println!("Installing SilentSDDM theme");
  println!("==========================================");
  println!("Theme source: {}", theme_source.display());
  println!();

  // Install theme
  install_theme(&theme_source)?;

  // Install fonts
  install_fonts(&theme_source)?;

  // Update SDDM config
  update_sddm_config()?;

  println!();
  println!("==========================================");
  println!("SilentSDDM installation completed!");
  println!("==========================================");
  println!("Theme installed to: {}", THEME_DEST);
  println!("Fonts installed to: {}", FONTS_DEST);
  println!("SDDM config updated: {}", SDDM_CONF);
  println!();
  println!("You may need to restart SDDM or reboot for changes to take effect.");
  println!("To test the theme, run: cd {} && ./test.sh", THEME_DEST);

  Ok(())
}
