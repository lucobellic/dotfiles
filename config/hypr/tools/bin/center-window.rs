#!/usr/bin/env -S cargo -Zscript
---cargo
[package]
name = "center_window"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1"
hyprland = "0.4.0-beta.3"
clap = { version = "4", features = ["derive"] }
---

//! Center the currently focused window (make it floating if not already)

use anyhow::{Context, Result};
use clap::Parser;
use hyprland::data::{Client, Monitors, Transforms};
use hyprland::dispatch::{Dispatch, DispatchType, WindowIdentifier};
use hyprland::shared::{Address, HyprData, HyprDataActiveOptional};
use std::process::Command;
use std::thread;
use std::time::Duration;

/// Center the currently focused window with optional resizing
#[derive(Parser, Debug)]
#[command(name = "center-window")]
#[command(author, version, about, long_about = None)]
#[command(after_help = "EXAMPLES:
    center-window                     # Center with default size (60% x 70%)
    center-window 80% 80%             # Center with 80% width and height
    center-window 1920 1080           # Center with fixed pixel dimensions
    center-window --address 0x12345   # Center a specific window by address")]
struct Args {
  /// Width (percentage with % or pixel value)
  #[arg(default_value = "60%")]
  width: String,

  /// Height (percentage with % or pixel value)
  #[arg(default_value = "70%")]
  height: String,

  /// Window address to center (defaults to focused window)
  #[arg(long)]
  address: Option<String>,
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

/// Get the currently focused window
fn get_focused_window() -> Result<Client> {
  Client::get_active()
    .context("Failed to get active client")?
    .context("No focused window")
}

/// Get window by address
fn get_window_by_address(addr_str: &str) -> Result<Client> {
  let clients = hyprland::data::Clients::get().context("Failed to get clients")?;
  clients
    .into_iter()
    .find(|c| {
      format!("{}", c.address).contains(addr_str) || addr_str.contains(&format!("{}", c.address))
    })
    .context(format!("No window found with address {}", addr_str))
}

/// Create window identifier from address
fn window_id(address: &Address) -> WindowIdentifier<'_> {
  WindowIdentifier::Address(address.clone())
}

/// Ensure window is floating
fn ensure_floating(client: &Client) -> Result<()> {
  if !client.floating {
    Dispatch::call(DispatchType::ToggleFloating(Some(window_id(
      &client.address,
    ))))
    .context("Failed to set window to floating")?;
    // Small delay to let Hyprland process the float change
    thread::sleep(Duration::from_millis(50));
  }
  Ok(())
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

/// Center and resize the window
fn setup_window(address: &Address, width: i16, height: i16) -> Result<()> {
  resize_window(address, width, height)?;
  center_window(address)?;
  Ok(())
}

fn main() -> Result<()> {
  let args = Args::parse();

  // Get target window (specified by address or currently focused)
  let client = match &args.address {
    Some(addr) => get_window_by_address(addr)?,
    None => get_focused_window()?,
  };

  // Calculate dimensions
  let (mon_width, mon_height) = get_focused_monitor_dimensions()?;
  let width = parse_dimension(&args.width, mon_width);
  let height = parse_dimension(&args.height, mon_height);

  // Ensure window is floating
  ensure_floating(&client)?;

  // Resize and center
  setup_window(&client.address, width, height)
}
