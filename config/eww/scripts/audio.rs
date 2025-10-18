#!/usr/bin/env -S cargo +nightly -Zscript
---
[dependencies]
serde_json = "1.0"
---
use std::env;
use std::process::Command;

fn get_volume() -> i32 {
  let output = Command::new("wpctl")
    .args(["get-volume", "@DEFAULT_AUDIO_SINK@"])
    .output()
    .ok();

  output
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| {
      s.split_whitespace()
        .nth(1)
        .and_then(|v| v.parse::<f64>().ok())
        .map(|v| (v * 100.0) as i32)
    })
    .unwrap_or(0)
}

fn get_muted() -> bool {
  let output = Command::new("wpctl")
    .args(["get-volume", "@DEFAULT_AUDIO_SINK@"])
    .output()
    .ok();

  output
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .map(|s| s.contains("MUTED"))
    .unwrap_or(false)
}

fn get_output_device() -> String {
  let output = Command::new("wpctl").arg("status").output().ok();

  output
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| {
      let mut in_sinks = false;
      for line in s.lines() {
        if line.contains("Sinks:") {
          in_sinks = true;
          continue;
        }
        if line.contains("Sources:") {
          break;
        }
        if in_sinks && line.contains('*') {
          let cleaned = line
            .split('*')
            .nth(1)?
            .trim_start()
            .split_once('.')
            .map(|(_, rest)| rest.trim())?;

          let device = cleaned.split('[').next()?.trim().to_string();

          return Some(device);
        }
      }
      None
    })
    .unwrap_or_default()
}

fn get_mic_volume() -> i32 {
  let output = Command::new("wpctl")
    .args(["get-volume", "@DEFAULT_AUDIO_SOURCE@"])
    .output()
    .ok();

  output
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| {
      s.split_whitespace()
        .nth(1)
        .and_then(|v| v.parse::<f64>().ok())
        .map(|v| (v * 100.0) as i32)
    })
    .unwrap_or(0)
}

fn get_mic_muted() -> bool {
  let output = Command::new("wpctl")
    .args(["get-volume", "@DEFAULT_AUDIO_SOURCE@"])
    .output()
    .ok();

  output
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .map(|s| s.contains("MUTED"))
    .unwrap_or(false)
}

fn get_input_device() -> String {
  let output = Command::new("wpctl").arg("status").output().ok();

  output
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .and_then(|s| {
      let mut in_sources = false;
      for line in s.lines() {
        if line.contains("Sources:") {
          in_sources = true;
          continue;
        }
        if line.contains("Filters:") {
          break;
        }
        if in_sources && line.contains('*') {
          let cleaned = line
            .split('*')
            .nth(1)?
            .trim_start()
            .split_once('.')
            .map(|(_, rest)| rest.trim())?;

          let device = cleaned.split('[').next()?.trim().to_string();

          return Some(device);
        }
      }
      None
    })
    .unwrap_or_default()
}

fn set_volume(direction: &str) {
  let delta = if direction == "up" { "5%+" } else { "5%-" };
  Command::new("wpctl")
    .args(["set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", delta])
    .output()
    .ok();
  
  let volume = get_volume();
  let muted = get_muted();
  let output = get_output_device();
  println!(
    r#"{{"volume": {}, "muted": {}, "output": "{}"}}"#,
    volume, muted, output
  );
}

fn set_mic_volume(direction: &str) {
  let delta = if direction == "up" { "5%+" } else { "5%-" };
  Command::new("wpctl")
    .args(["set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SOURCE@", delta])
    .output()
    .ok();
  
  let mic_volume = get_mic_volume();
  let mic_muted = get_mic_muted();
  let input = get_input_device();
  println!(
    r#"{{"volume": {}, "muted": {}, "input": "{}"}}"#,
    mic_volume, mic_muted, input
  );
}

fn toggle_mute() {
  Command::new("wpctl")
    .args(["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    .output()
    .ok();
  
  let volume = get_volume();
  let muted = get_muted();
  let output = get_output_device();
  println!(
    r#"{{"volume": {}, "muted": {}, "output": "{}"}}"#,
    volume, muted, output
  );
}

fn toggle_mic_mute() {
  Command::new("wpctl")
    .args(["set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
    .output()
    .ok();
  
  let mic_volume = get_mic_volume();
  let mic_muted = get_mic_muted();
  let input = get_input_device();
  println!(
    r#"{{"volume": {}, "muted": {}, "input": "{}"}}"#,
    mic_volume, mic_muted, input
  );
}

fn main() {
  let args: Vec<String> = env::args().collect();
  let command = args.get(1).map(|s| s.as_str()).unwrap_or("json");

  match command {
    "volume" => println!("{}", get_volume()),
    "muted" => println!("{}", get_muted()),
    "output" => println!("{}", get_output_device()),
    "mic-volume" => println!("{}", get_mic_volume()),
    "mic-muted" => println!("{}", get_mic_muted()),
    "input" => println!("{}", get_input_device()),
    "set-volume" => {
      if let Some(direction) = args.get(2) {
        set_volume(direction);
      }
    }
    "set-mic-volume" => {
      if let Some(direction) = args.get(2) {
        set_mic_volume(direction);
      }
    }
    "toggle-mute" => toggle_mute(),
    "toggle-mic-mute" => toggle_mic_mute(),
    "json" => {
      let volume = get_volume();
      let muted = get_muted();
      let output = get_output_device();
      println!(
        r#"{{"volume": {}, "muted": {}, "output": "{}"}}"#,
        volume, muted, output
      );
    }
    "mic-json" => {
      let mic_volume = get_mic_volume();
      let mic_muted = get_mic_muted();
      let input = get_input_device();
      println!(
        r#"{{"volume": {}, "muted": {}, "input": "{}"}}"#,
        mic_volume, mic_muted, input
      );
    }
    _ => {
      let volume = get_volume();
      let muted = get_muted();
      let output = get_output_device();
      println!(
        r#"{{"volume": {}, "muted": {}, "output": "{}"}}"#,
        volume, muted, output
      );
    }
  }
}
