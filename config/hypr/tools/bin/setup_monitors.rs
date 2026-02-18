#!/usr/bin/env -S cargo -Zscript
---cargo
[package]
name = "setup_monitors"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1"
dirs = "6"
hyprland = "0.4.0-beta.3"
serde = { version = "1", features = ["derive"] }
serde_yaml = "0.9"
sha1 = "0.10"
tokio = "1"
---

use std::collections::HashMap;
use std::fs;
use std::process::Command;

use dirs::home_dir;
use hyprland::data::Monitors;
use hyprland::dispatch;
use hyprland::keyword::Keyword;
use hyprland::shared::HyprData;
use serde::Deserialize;
use tokio::try_join;

use anyhow::Context;

#[allow(dead_code)]
#[derive(Default, Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
enum Rotation {
  #[default]
  Normal = 0,
  Deg90 = 1,
  Deg180 = 2,
  Deg270 = 3,
  Flipped = 4,
  FlippedDeg90 = 5,
  FlippedDeg180 = 6,
  FlippedDeg270 = 7,
}

#[derive(Default, PartialEq, Eq, Debug, Deserialize)]
struct ScreenConfig {
  name: String,
  position: String,
  workspace: u32,
  description: String,
  rotation: Rotation,
}

impl ScreenConfig {
  fn apply(&self) -> hyprland::Result<()> {
    Keyword::set(
      "monitor",
      format!(
        "desc:{}, highres, {}, 1, transform, {}",
        self.description, self.position, self.rotation as u32
      ),
    )?;

    Keyword::set(
      "workspace",
      format!(
        "{}, monitor:desc:{}, default:true",
        self.workspace, self.description
      ),
    )?;
    Ok(())
  }
}

fn load_screen_configs(
  path: &std::path::Path,
) -> anyhow::Result<HashMap<String, Vec<ScreenConfig>>> {
  let content = fs::read_to_string(path).context(format!(
    "Failed to read screen configuration file {:?}",
    path
  ))?;
  let configs: HashMap<String, Vec<ScreenConfig>> = serde_yaml::from_str(&content)?;

  if !configs.contains_key("default") {
    anyhow::bail!("Configuration must contain a 'default' section");
  }

  Ok(configs)
}

async fn setup_home() -> anyhow::Result<()> {
  let home = home_dir().context("Failed to get home directory")?;
  let cursor_path = home.join(".local/bin/Cursor.AppImage");
  let _cursor_cmd = format!("pgrep Cursor || {}", cursor_path.display());

  Keyword::set("windowrule", "workspace 2, match:class ^([Ss]lack)$")?;
  Keyword::set("windowrule", "workspace 2, match:class kitty-logs")?;
  Keyword::set("windowrule", "workspace 2, match:class ^([Cc]ursor)$")?;
  Keyword::set("windowrule", "workspace 2, match:class kitty-dev")?;
  Keyword::set("windowrule", "workspace 3, match:class ^([Oo]pera)$")?;
  Keyword::set("windowrule", "workspace 3, match:class ^([Zz]en)$")?;

  try_join!(
    dispatch!(async; Exec, "pgrep zen    || zen"),
    dispatch!(async; Exec, "pgrep slack  || slack"),
    dispatch!(async; Exec, "pgrep kitty  || kitty --class kitty-dev"),
    // dispatch!(async; Exec, cursor_cmd.as_str())
  )?;

  Ok(())
}

async fn setup_work() -> anyhow::Result<()> {
  let home = home_dir().context("Failed to get home directory")?;
  let cursor_path = home.join(".local/bin/Cursor.AppImage");
  let _cursor_cmd = format!("pgrep Cursor || {}", cursor_path.display());

  Keyword::set("windowrule", "workspace 3, match:class kitty-dev")?;
  Keyword::set("windowrule", "workspace 4, match:class ^([Ss]lack)$")?;
  Keyword::set("windowrule", "workspace 1, match:class ^([Zz]en)$")?;
  Keyword::set("windowrule", "workspace 2, match:class ^([Cc]ursor)$")?;
  Keyword::set("windowrule", "workspace 2, match:class kitty-logs")?;

  try_join!(
    dispatch!(async; Exec, "pgrep zen    || zen"),
    dispatch!(async; Exec, "pgrep slack  || slack"),
    dispatch!(async; Exec, "pgrep kitty  || kitty --class kitty-dev"),
    // dispatch!(async; Exec, cursor_cmd.as_str())
  )?;

  Ok(())
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> anyhow::Result<()> {
  let home = home_dir().context("Failed to get home directory")?;
  let config_path = home.join(".config/hypr/monitors/screens.yaml");
  let configs = load_screen_configs(&config_path)?;

  let monitors = Monitors::get()?;
  let screens = configs
    .iter()
    .filter(|(name, _)| name.as_str() != "default")
    .find(|(_name, screens)| match screens.first() {
      Some(first_screen) => monitors
        .iter()
        .any(|m| m.description == first_screen.description),
      _ => false,
    });

  let (config_name, screens_to_apply) = match screens {
    Some((name, screens)) => (name.as_str(), screens),
    None => ("default", configs.get("default").unwrap()),
  };

  Command::new("notify-send")
    .arg("-a")
    .arg("setup_monitors")
    .arg("-u")
    .arg("normal")
    .arg("Setting monitors")
    .arg(config_name)
    .spawn()?;

  screens_to_apply
    .iter()
    .try_for_each(|screen| screen.apply())?;

  match config_name {
    "home" => setup_home().await?,
    "work" => setup_work().await?,
    _ => {
      println!("Using default screen configuration");
    }
  }

  let eww_screen = match config_name {
    "home" | "work" => 1,
    _ => 0,
  };

  let _ = Command::new("pkill").arg("eww").status();

  Command::new("eww")
    .args([
      "open-many",
      "modern-clock",
      "--arg",
      &format!("screen={eww_screen}"),
      "--arg",
      "stacking=bottom",
    ])
    .spawn()?;

  Command::new("open_eww_workspaces.rs").spawn()?;

  Ok(())
}
