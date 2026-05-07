use std::collections::HashMap;
use std::fmt;
use std::fs;
use std::process::Command;

use dirs::home_dir;
use hyprland::data::{Monitors, Workspaces};
use hyprland::dispatch;
use hyprland::dispatch::{Dispatch, DispatchType, MonitorIdentifier, WorkspaceIdentifier};
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

#[derive(Default, Debug, Clone, PartialEq, Eq, Deserialize)]
enum Layout {
  #[default]
  Master,
  Dwindle,
  Scrolling,
  Monocle,
}


impl fmt::Display for Layout {
  fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    match self {
      Layout::Master => write!(f, "master"),
      Layout::Dwindle => write!(f, "dwindle"),
      Layout::Scrolling => write!(f, "scrolling"),
      Layout::Monocle => write!(f, "monocle"),
    }
  }
}

#[derive(Default, PartialEq, Eq, Debug, Deserialize)]
struct ScreenConfig {
  description: String,
  layout: Layout,
  name: String,
  position: String,
  rotation: Rotation,
  workspace: u32,
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
        "{}, layout:{}, monitor:desc:{}, default:true",
        self.workspace, self.layout, self.description
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
  )?;

  Ok(())
}

/// Force-reassign workspaces to their configured monitors.
async fn reassign_workspaces(screens: &[ScreenConfig]) -> anyhow::Result<()> {
  let monitors = Monitors::get()?;
  let workspaces = Workspaces::get()?;

  for screen in screens {
    // Find the physical monitor matching this screen config by description.
    let Some(monitor) = monitors.iter().find(|m| m.description == screen.description) else {
      // Monitor not currently connected — skip.
      continue;
    };

    let desired_ws_id = screen.workspace as i32;

    // Find where the desired workspace currently lives (if it exists at all).
    let currently_on_wrong_monitor = workspaces
      .iter()
      .find(|w| w.id == desired_ws_id)
      .map(|w| w.monitor != monitor.name)
      .unwrap_or(false);

    if currently_on_wrong_monitor {
      Dispatch::call(DispatchType::MoveWorkspaceToMonitor(
        WorkspaceIdentifier::Id(desired_ws_id),
        MonitorIdentifier::Name(&monitor.name),
      ))?;
    }
  }

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
    .arg("setup-monitors")
    .arg("-u")
    .arg("normal")
    .arg("Setting monitors")
    .arg(config_name)
    .spawn()?;

  screens_to_apply
    .iter()
    .try_for_each(|screen| screen.apply())?;

  reassign_workspaces(screens_to_apply).await?;

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
