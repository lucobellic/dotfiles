#!/usr/bin/env -S cargo +nightly -Zscript
use std::fs;

const STATE_FILE: &str = "/tmp/cpu_prev";

#[derive(Default)]
struct CpuState {
  idle: u64,
  total: u64,
}

fn main() {
  let prev_state = load_state().unwrap_or_default();
  let current_state = read_cpu_stat().unwrap_or_default();

  let cpu_usage = match prev_state.total {
    0 => 0,
    _ => {
      let diff_idle = current_state.idle.saturating_sub(prev_state.idle);
      let diff_total = current_state.total.saturating_sub(prev_state.total);

      match diff_total {
        0 => 0,
        _ => (100 * (diff_total - diff_idle)) / diff_total,
      }
    }
  };

  save_state(&current_state);
  println!("{}", cpu_usage);
}

fn read_cpu_stat() -> Option<CpuState> {
  let content = fs::read_to_string("/proc/stat").ok()?;
  let cpu_line = content.lines().find(|line| line.starts_with("cpu "))?;

  let values: Vec<u64> = cpu_line
    .split_whitespace()
    .skip(1)
    .filter_map(|s| s.parse::<u64>().ok())
    .collect();

  if values.len() < 7 {
    return None;
  }

  let user = values[0];
  let nice = values[1];
  let system = values[2];
  let idle = values[3];
  let iowait = values[4];
  let irq = values[5];
  let softirq = values[6];

  let total = user + nice + system + idle + iowait + irq + softirq;

  Some(CpuState { idle, total })
}

fn load_state() -> Option<CpuState> {
  let content = fs::read_to_string(STATE_FILE).ok()?;
  let mut idle = 0;
  let mut total = 0;

  for line in content.lines() {
    if let Some(value) = line.strip_prefix("prev_idle=") {
      idle = value.parse().ok()?;
    } else if let Some(value) = line.strip_prefix("prev_total=") {
      total = value.parse().ok()?;
    }
  }

  Some(CpuState { idle, total })
}

fn save_state(state: &CpuState) {
  let content = format!("prev_idle={}\nprev_total={}\n", state.idle, state.total);
  let _ = fs::write(STATE_FILE, content);
}
