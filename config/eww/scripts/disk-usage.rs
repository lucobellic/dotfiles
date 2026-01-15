#!/usr/bin/env -S cargo -Zscript
---
[dependencies]
sysinfo = "0.37"
---
use std::path::Path;
use sysinfo::Disks;

fn main() {
  let disks = Disks::new_with_refreshed_list();
  let root = Path::new("/");
  let disk = disks
    .iter()
    .find(|d| d.mount_point() == root)
    .or_else(|| disks.iter().next());

  let percent = disk
    .and_then(|d| {
      let total = d.total_space() as f64;
      let available = d.available_space() as f64;
      match total {
        total if total <= 0.0 => None,
        _ => {
          let used = total - available;
          Some(((used / total) * 100.0).round() as i64)
        }
      }
    })
    .unwrap_or(0);

  println!("{}", percent);
}
