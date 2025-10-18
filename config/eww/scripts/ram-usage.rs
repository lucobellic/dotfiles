#!/usr/bin/env -S cargo +nightly -Zscript
---
[dependencies]
---
use std::fs;

fn main() {
  let content = fs::read_to_string("/proc/meminfo").unwrap_or_default();

  let mut mem_total: Option<u64> = None;
  let mut mem_available: Option<u64> = None;

  for line in content.lines() {
    if line.starts_with("MemTotal:") {
      mem_total = line.split_whitespace().nth(1).and_then(|s| s.parse().ok());
    } else if line.starts_with("MemAvailable:") {
      mem_available = line.split_whitespace().nth(1).and_then(|s| s.parse().ok());
    }
  }

  let percent = match (mem_total, mem_available) {
    (Some(total), Some(available)) if total > 0 => {
      let used = ((total - available) * 100 / total).min(100);
      used as i32
    }
    _ => 0,
  };

  println!("{}", percent);
}
