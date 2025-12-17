#!/usr/bin/env -S cargo +nightly -Zscript
use std::fs;
use std::process::Command;

fn main() {
  if let Some(percent) = try_sysfs() {
    println!("{}", percent);
    return;
  }

  if let Some(percent) = try_upower() {
    println!("{}", percent);
    return;
  }

  println!("100");
}

fn try_sysfs() -> Option<i32> {
  let paths = fs::read_dir("/sys/class/power_supply").ok()?;

  for path in paths.flatten() {
    let capacity_file = path.path().join("capacity");
    if let Ok(content) = fs::read_to_string(&capacity_file) {
      if let Ok(percent) = content.trim().parse::<i32>() {
        return Some(percent);
      }
    }
  }

  None
}

fn try_upower() -> Option<i32> {
  let devices = Command::new("upower").arg("-e").output().ok()?;

  let device_list = String::from_utf8(devices.stdout).ok()?;
  let battery_device = device_list
    .lines()
    .find(|line| line.to_lowercase().contains("battery"))?;

  let info = Command::new("upower")
    .arg("-i")
    .arg(battery_device)
    .output()
    .ok()?;

  let info_str = String::from_utf8(info.stdout).ok()?;

  for line in info_str.lines() {
    if line.contains("percentage") {
      let percent_str = line.split_whitespace().nth(1)?.trim_end_matches('%');

      if let Ok(percent) = percent_str.parse::<f64>() {
        return Some(percent as i32);
      }
    }
  }

  None
}
