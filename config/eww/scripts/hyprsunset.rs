#!/usr/bin/env -S cargo -Zscript
use std::env;
use std::process::Command;

fn adjust_temperature(direction: &str) {
  let step = 200;
  let adjustment = match direction {
    "up" => format!("+{}", step),
    "down" => format!("-{}", step),
    _ => return,
  };

  let _ = Command::new("hyprctl")
    .args(["hyprsunset", "temperature", &adjustment])
    .output();
}

fn adjust_gamma(direction: &str) {
  let step = 5; // Gamma is in percentage (0-200)
  let adjustment = match direction {
    "up" => format!("+{}", step),
    "down" => format!("-{}", step),
    _ => return,
  };

  let _ = Command::new("hyprctl")
    .args(["hyprsunset", "gamma", &adjustment])
    .output();
}

fn main() {
  let args: Vec<String> = env::args().collect();

  if args.len() < 2 {
    eprintln!("Usage: {} <temp|gamma> <up|down>", args[0]);
    std::process::exit(1);
  }

  let action = &args[1];
  let direction = if args.len() > 2 { &args[2] } else { "up" };

  match action.as_str() {
    "temp" | "temperature" => adjust_temperature(direction),
    "gamma" => adjust_gamma(direction),
    _ => {
      eprintln!("Invalid action: {}. Use 'temp' or 'gamma'", action);
      std::process::exit(1);
    }
  }
}
