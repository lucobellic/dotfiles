#!/usr/bin/env -S cargo +nightly -Zscript
---
[dependencies]
---
use std::fs;
use std::process::Command;

fn main() {
  if let Some(percent) = try_intel_gpu_top() {
    println!("{}", percent);
    return;
  }

  if let Some(percent) = try_sysfs_gpu_busy() {
    println!("{}", percent);
    return;
  }

  if let Some(percent) = try_radeontop() {
    println!("{}", percent);
    return;
  }

  if is_intel_gpu() {
    println!("0");
    return;
  }

  println!("0");
}

fn try_intel_gpu_top() -> Option<i32> {
  let output = Command::new("intel_gpu_top")
    .args(["-J", "-s", "0.2", "-o", "-"])
    .output()
    .ok()?;

  let stdout = String::from_utf8(output.stdout).ok()?;
  let first_line = stdout.lines().next()?;

  let start = first_line.find("\"render_busy\":")?;
  let after = &first_line[start + 14..];
  let end = after.find(|c: char| !c.is_ascii_digit())?;
  let busy = after[..end].parse::<i32>().ok()?;

  Some(busy)
}

fn try_sysfs_gpu_busy() -> Option<i32> {
  let drm_dir = fs::read_dir("/sys/class/drm").ok()?;

  for entry in drm_dir.flatten() {
    let device_path = entry.path().join("device/gpu_busy_percent");
    if let Ok(content) = fs::read_to_string(&device_path) {
      if let Ok(percent) = content.trim().parse::<i32>() {
        return Some(percent);
      }
    }
  }

  None
}

fn try_radeontop() -> Option<i32> {
  let output = Command::new("radeontop")
    .args(["-d", "-", "-l", "1"])
    .output()
    .ok()?;

  let stdout = String::from_utf8(output.stdout).ok()?;
  let first_line = stdout.lines().next()?;

  for part in first_line.split_whitespace() {
    if let Ok(num) = part.trim_end_matches('%').parse::<f64>() {
      return Some(num as i32);
    }
  }

  None
}

fn is_intel_gpu() -> bool {
  Command::new("lspci")
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .map(|s| s.to_lowercase().contains("vga") && s.to_lowercase().contains("intel"))
    .unwrap_or(false)
}
