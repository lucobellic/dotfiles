#!/usr/bin/env -S cargo -Zscript
---cargo
[dependencies]
anyhow = "1"
clap = { version = "4", features = ["derive"] }
hyprland = "0.4.0-beta.3"
---
use anyhow::Result;
use clap::{Parser, Subcommand};
use hyprland::data::Monitors;
use hyprland::dispatch;
use hyprland::keyword::Keyword;
use hyprland::shared::HyprData;

#[derive(Parser)]
#[command(name = "lid_monitor_handler")]
#[command(about = "Lid Monitor Handler", long_about = None)]
struct Cli {
  #[command(subcommand)]
  command: Commands,
}

#[derive(Subcommand)]
enum Commands {
  #[command(about = "close")]
  Close,
  #[command(about = "open")]
  Open,
}

fn main() -> Result<()> {
  let cli = Cli::parse();

  let nb_monitors = match Monitors::get() {
    Ok(monitors) => monitors.iter().count(),
    Err(..) => 1,
  };

  match (cli.command, nb_monitors <= 1) {
    (Commands::Open, true) => dispatch!(Exec, "dpms off")?,
    (Commands::Close, true) => {
      dispatch!(Exec, "dpms off")?;
      dispatch!(Exec, "hyprlock")?;
    }
    (Commands::Open, false) => Keyword::set("monitor", "eDP-1, highrr, auto, 1")?,
    (Commands::Close, false) => Keyword::set("monitor", "eDP-1, disable")?,
  };

  Ok(())
}
