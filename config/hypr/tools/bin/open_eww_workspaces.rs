#!/usr/bin/env -S cargo +nightly -Zscript
---cargo
[package]
name = "open_eww_workspaces"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1"
hyprland = "0.4.0-beta.3"
---

//! Opens eww workspace widgets on all monitors with optional auto-close timer.

use anyhow::{Result, bail};
use hyprland::data::{Monitor, Monitors};
use hyprland::shared::HyprData;
use std::process::{Command, Output};

/// Sends a desktop notification with the given urgency and message.
fn notify(urgency: &str, message: &str) -> Result<()> {
  Command::new("notify-send")
    .args([
      "-a",
      "eww_workspaces",
      "-u",
      urgency,
      "eww workspaces",
      message,
    ])
    .spawn()?;
  Ok(())
}

/// Generates the eww window ID for a monitor's workspace widget.
fn window_id(monitor_id: i128, stacking: &str) -> String {
  format!("workspaces-{stacking}-mon-{monitor_id}")
}

/// Runs a command and returns an error if it fails.
fn run_checked(cmd: &mut Command, action: &str) -> Result<()> {
  let output = cmd.output()?;
  if !output.status.success() {
    bail!("{action}: {}", String::from_utf8_lossy(&output.stderr));
  }
  Ok(())
}

/// Sets up a systemd timer to auto-close workspaces after a delay.
fn setup_timer(monitors: &[Monitor], stacking: &str, delay_secs: u64) -> Result<()> {
  let delay_secs = delay_secs.max(1);
  let timer_unit = format!("eww-workspaces-closer-{stacking}.timer");

  let is_active = Command::new("systemctl")
    .args(["--user", "is-active", "--quiet", &timer_unit])
    .output()?
    .status
    .success();

  if is_active {
    return run_checked(
      Command::new("systemctl").args(["--user", "restart", &timer_unit]),
      "Failed to restart timer",
    );
  }

  let close_cmd = monitors
    .iter()
    .fold(String::from("eww close"), |mut cmd, m| {
      cmd.push(' ');
      cmd.push_str(&window_id(m.id, stacking));
      cmd
    });

  run_checked(
    Command::new("systemd-run").args([
      "--user",
      "--unit",
      &format!("eww-workspaces-closer-{stacking}.service"),
      &format!("--on-active={delay_secs}s"),
      "--timer-property=AccuracySec=100ms",
      "--collect",
      "/bin/sh",
      "-c",
      &close_cmd,
    ]),
    "Failed to create timer",
  )
}

/// Opens eww workspace widgets on all specified monitors.
fn open_workspaces(monitors: &[Monitor], stacking: &str) -> Result<Output> {
  let mut cmd = Command::new("eww");
  cmd.arg("open-many");
  for &Monitor { id, .. } in monitors {
    let wid = window_id(id, stacking);
    cmd.args([
      &format!("workspaces:{wid}"),
      "--arg",
      &format!("{wid}:screen={id}"),
      "--arg",
      &format!("{wid}:monitor={id}"),
      "--arg",
      &format!("{wid}:stacking={stacking}"),
    ]);
  }
  Ok(cmd.output()?)
}

fn main() -> Result<()> {
  let args: Vec<String> = std::env::args().collect();
  let stacking = args.get(1).map_or("bottom", String::as_str);
  let close_delay: Option<u64> = args.get(2).and_then(|s| s.parse().ok());

  let monitors: Vec<Monitor> = Monitors::get()?.into_iter().collect();
  if monitors.is_empty() {
    notify("critical", "No monitors detected")?;
    return Ok(());
  }

  let output = open_workspaces(&monitors, stacking)?;
  if !output.status.success() {
    notify(
      "critical",
      &format!(
        "Failed to open workspaces: {}",
        String::from_utf8_lossy(&output.stderr)
      ),
    )?;
    return Ok(());
  }

  if let Some(delay) = close_delay {
    setup_timer(&monitors, stacking, delay)?;
  }

  Ok(())
}
