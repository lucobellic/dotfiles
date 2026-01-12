#!/usr/bin/env -S cargo +nightly -Zscript
---cargo
[package]
name = "terminal_dropdown"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1"
hyprland = "0.4.0-beta.3"
clap = { version = "4", features = ["derive"] }
---

//! Toggle dropdown terminal (Kitty or Ghostty) with sizing and centering

use anyhow::{Context, Result};
use clap::Parser;
use hyprland::data::{Client, Clients, Monitors, Transforms};
use hyprland::dispatch::{Dispatch, DispatchType, WindowIdentifier};
use hyprland::shared::{Address, HyprData};
use std::process::Command;
use std::thread;
use std::time::Duration;

/// Toggle dropdown terminal (Kitty or Ghostty) with sizing and centering
#[derive(Parser, Debug)]
#[command(name = "terminal-dropdown")]
#[command(author, version, about, long_about = None)]
#[command(after_help = "EXAMPLES:
    terminal-dropdown dropdown 100% 50%              # 100% width, 50% height of monitor
    terminal-dropdown dropdown 1920 540              # Fixed 1920x540 pixels
    terminal-dropdown yazi 100% 50% -- yazi          # Yazi file manager
    terminal-dropdown dropdown                       # Use defaults (100% width, 50% height)
    terminal-dropdown dropdown --terminal kitty      # Use Kitty terminal
    terminal-dropdown dropdown --terminal ghostty    # Use Ghostty terminal (default)")]
struct Args {
  /// Instance name for the dropdown terminal
  #[arg(default_value = "dropdown")]
  instance: String,

  /// Width (percentage with % or pixel value)
  #[arg(default_value = "100%")]
  width: String,

  /// Height (percentage with % or pixel value)
  #[arg(default_value = "50%")]
  height: String,

  /// Terminal to use (kitty or ghostty)
  #[arg(long, default_value = "ghostty")]
  terminal: String,

  /// Command to execute in the terminal
  #[arg(trailing_var_arg = true)]
  command: Vec<String>,
}

/// Configuration for the dropdown terminal
#[derive(Debug)]
struct DropdownConfig {
  class: String,
  terminal: String,
  width: i16,
  height: i16,
  command: Vec<String>,
}

impl DropdownConfig {
  /// Create configuration from parsed arguments
  fn from_args(args: Args) -> Result<Self> {
    let (mon_width, mon_height) = get_focused_monitor_dimensions()?;
    let terminal = args.terminal.to_lowercase();

    // Validate terminal choice
    if terminal != "kitty" && terminal != "ghostty" {
      anyhow::bail!(
        "Invalid terminal: {}. Must be 'kitty' or 'ghostty'",
        terminal
      );
    }

    // Generate appropriate class based on terminal
    let class = match terminal.as_str() {
      "kitty" => format!("kitty-{}", args.instance),
      "ghostty" => format!("ghostty-{}", args.instance),
      _ => unreachable!(),
    };

    Ok(Self {
      class,
      terminal,
      width: parse_dimension(&args.width, mon_width),
      height: parse_dimension(&args.height, mon_height),
      command: args.command,
    })
  }
}

/// Parse dimension argument (percentage or pixel value)
fn parse_dimension(arg: &str, monitor_size: i16) -> i16 {
  arg
    .strip_suffix('%')
    .and_then(|pct_str| pct_str.parse::<i32>().ok())
    .map(|pct| ((monitor_size as i32 * pct) / 100) as i16)
    .unwrap_or_else(|| arg.parse::<i16>().unwrap_or(monitor_size))
}

/// Get the focused monitor's dimensions (accounting for transform/rotation)
fn get_focused_monitor_dimensions() -> Result<(i16, i16)> {
  Monitors::get()
    .context("Failed to get monitors")?
    .into_iter()
    .find(|m| m.focused)
    .map(|m| {
      let (w, h) = (m.width as i16, m.height as i16);
      // 90° and 270° rotations swap width and height
      match m.transform {
        Transforms::Normal90
        | Transforms::Normal270
        | Transforms::Flipped90
        | Transforms::Flipped270 => (h, w),
        _ => (w, h),
      }
    })
    .context("No focused monitor found")
}

/// Find window by class
fn find_window_by_class(class: &str) -> Result<Option<Client>> {
  Clients::get()
    .context("Failed to get clients")
    .map(|clients| clients.into_iter().find(|c| c.class == class))
}

/// Wait for window to be created (retry loop with iterator)
fn wait_for_window(class: &str, max_attempts: u32) -> Option<Address> {
  (0..max_attempts).find_map(|_| {
    thread::sleep(Duration::from_millis(100));
    find_window_by_class(class)
      .ok()
      .flatten()
      .map(|c| c.address)
  })
}

/// Send a desktop notification
fn notify(urgency: &str, message: &str) -> Result<()> {
  Command::new("notify-send")
    .args([
      "-a",
      "terminal-dropdown",
      "-u",
      urgency,
      "Terminal Dropdown",
      message,
    ])
    .spawn()
    .context("Failed to send notification")?;
  Ok(())
}

/// Create window identifier from address
fn window_id(address: &Address) -> WindowIdentifier<'_> {
  WindowIdentifier::Address(address.clone())
}

/// Resize a window to exact dimensions
fn resize_window(address: &Address, width: i16, height: i16) -> Result<()> {
  Dispatch::call(DispatchType::ResizeWindowPixel(
    hyprland::dispatch::Position::Exact(width, height),
    window_id(address),
  ))
  .context("Failed to resize window")
}

/// Center a window
fn center_window(address: &Address) -> Result<()> {
  Command::new("hyprctl")
    .args(["dispatch", "centerwindow", &format!("address:{}", address)])
    .output()
    .context("Failed to center window")?;
  Ok(())
}

/// Focus a window
fn focus_window(address: &Address) -> Result<()> {
  Dispatch::call(DispatchType::FocusWindow(window_id(address))).context("Failed to focus window")
}

/// Resize, center, and focus a window in sequence
fn setup_window(address: &Address, width: i16, height: i16) -> Result<()> {
  resize_window(address, width, height)
    .and_then(|_| center_window(address))
    .and_then(|_| focus_window(address))
}

/// Move window to current workspace
fn show_window(address: &Address) -> Result<()> {
  Dispatch::call(DispatchType::MoveToWorkspace(
    hyprland::dispatch::WorkspaceIdentifierWithSpecial::Relative(0),
    Some(window_id(address)),
  ))
  .context("Failed to move window to current workspace")
}

/// Hide window to special workspace
fn hide_window(address: &Address) -> Result<()> {
  Dispatch::call(DispatchType::MoveToWorkspaceSilent(
    hyprland::dispatch::WorkspaceIdentifierWithSpecial::Special(Some("hidden")),
    Some(window_id(address)),
  ))
  .context("Failed to hide window")
}

/// Toggle existing window visibility
fn toggle_window(window: &Client, config: &DropdownConfig) -> Result<()> {
  let is_hidden = window.workspace.name.starts_with("special:");

  if is_hidden {
    show_window(&window.address)
      .and_then(|_| {
        thread::sleep(Duration::from_millis(100));
        Ok(())
      })
      .and_then(|_| setup_window(&window.address, config.width, config.height))
  } else {
    hide_window(&window.address)
  }
}

/// Spawn new terminal instance
fn spawn_terminal(config: &DropdownConfig) -> Result<()> {
  let mut cmd = Command::new(&config.terminal);

  match config.terminal.as_str() {
    "kitty" => {
      cmd.arg("--class").arg(&config.class);
      if !config.command.is_empty() {
        cmd.args(&config.command);
      }
    }
    "ghostty" => {
      cmd.arg(format!("--class={}", config.class));
      if !config.command.is_empty() {
        cmd.arg("-e").args(&config.command);
      }
    }
    _ => unreachable!(),
  }

  cmd
    .spawn()
    .context(format!("Failed to spawn {}", config.terminal))?;

  wait_for_window(&config.class, 10)
    .ok_or_else(|| {
      let _ = notify("critical", "Window was not detected after spawning");
      anyhow::anyhow!("Window creation timeout")
    })
    .and_then(|address| setup_window(&address, config.width, config.height))
}

/// Handle window management based on current state
fn handle_window(config: &DropdownConfig) -> Result<()> {
  find_window_by_class(&config.class)?.map_or_else(
    || spawn_terminal(config),
    |window| toggle_window(&window, config),
  )
}

fn main() -> Result<()> {
  DropdownConfig::from_args(Args::parse()).and_then(|config| handle_window(&config))
}
