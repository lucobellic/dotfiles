#!/usr/bin/env -S cargo +nightly -Zscript
use std::env;
use std::process::Command;

fn main() {
  let args: Vec<String> = env::args().collect();
  let mem_mode = args.iter().any(|a| a == "--mem" || a == "-m");

  if mem_mode {
    // Query memory total and used, then compute percent used
    let output = Command::new("nvidia-smi")
      .args([
        "--query-gpu=memory.total,memory.used",
        "--format=csv,noheader,nounits",
      ])
      .output();

    let percent = output
      .ok()
      .and_then(|o| String::from_utf8(o.stdout).ok())
      .and_then(|s| s.lines().next().map(|l| l.trim().to_string()))
      .and_then(|line| {
        let mut parts = line.split(',').map(|p| p.trim().to_string());
        let total = parts.next()?.parse::<f64>().ok()?;
        let used = parts.next()?.parse::<f64>().ok()?;
        if total > 0.0 {
          Some(((used * 100.0 / total).round() as i32).clamp(0, 100))
        } else {
          Some(0)
        }
      })
      .unwrap_or(0);

    println!("{}", percent);
    return;
  }

  // Default: query GPU utilization
  let output = Command::new("nvidia-smi")
    .args([
      "--query-gpu=utilization.gpu",
      "--format=csv,noheader,nounits",
    ])
    .output();

  let percent = output
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| s.lines().next().map(|l| l.trim().to_string()))
    .and_then(|s| s.parse::<i32>().ok())
    .unwrap_or(0);

  println!("{}", percent);
}
