#!/usr/bin/env -S cargo -Zscript
---
[dependencies]
serde_json = "1.0"
sysinfo = "0.37"
---
use serde_json::json;
use sysinfo::{Components, CpuRefreshKind, RefreshKind, System};

fn get_temp(components: &Components, core_index: usize) -> u64 {
  components
    .iter()
    .find(|c| {
      c.label().contains("Core")
        && c
          .label()
          .split_whitespace()
          .last()
          .and_then(|s| s.parse::<usize>().ok())
          == Some(core_index)
    })
    .map(|c| c.temperature().unwrap_or(0.0) as u64)
    .unwrap_or(0)
}

fn main() {
  let mut sys =
    System::new_with_specifics(RefreshKind::nothing().with_cpu(CpuRefreshKind::everything()));
  std::thread::sleep(std::time::Duration::from_millis(500));

  let components = Components::new_with_refreshed_list();
  sys.refresh_cpu_usage();

  let cores_data: Vec<_> = sys
    .cpus()
    .iter()
    .enumerate()
    .map(|(i, cpu)| {
      json!({
        "core": i,
        "usage": cpu.cpu_usage() as u64,
        "temp": get_temp(&components, i / 2)
      })
    })
    .collect();

  println!("{}", json!(cores_data));
}
