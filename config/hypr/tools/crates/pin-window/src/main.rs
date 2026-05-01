use anyhow::Context;
use hyprland::data::Client;
use hyprland::keyword::Keyword;
use hyprland::shared::HyprDataActiveOptional;
use regex::escape as regex_escape;
use std::process::Command;

fn send_notification(title: &str, message: &str, urgency: &str) -> anyhow::Result<()> {
  Command::new("notify-send")
    .arg("-u")
    .arg(urgency)
    .arg("-t")
    .arg("2000")
    .arg(title)
    .arg(message)
    .spawn()?;
  Ok(())
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> anyhow::Result<()> {
  // Get all window properties in a single IPC call
  let active_window = Client::get_active().context("Failed to get active window")?;

  let Some(w) = active_window else {
    send_notification("Pin Window", "No active window found", "low")?;
    anyhow::bail!("No active window found");
  };

  let window_class = &w.class;
  if window_class.is_empty() {
    send_notification("Pin Window", "Active window has no class", "low")?;
    anyhow::bail!("No active window class found");
  }

  let escaped_class = regex_escape(window_class);
  let workspace_id = w.workspace.id;
  let (width, height) = w.size;

  // Build the rule string - all effects combined into one windowrule call
  // Each effect is appended as a separate comma-separated token
  let mut effects: Vec<String> = Vec::new();

  // Workspace assignment
  effects.push(format!("workspace {}", workspace_id));

  // Monitor assignment
  if let Some(monitor_id) = w.monitor {
    effects.push(format!("monitor {}", monitor_id));
  }

  // Float state — always record it so the window re-opens in the same mode
  if w.floating {
    effects.push("float on".to_string());
  }

  // Size — useful for both floating and tiled (initial size hint)
  effects.push(format!("size {} {}", width, height));

  // Pin state
  if w.pinned {
    effects.push("pin on".to_string());
  }

  // Build the final anonymous windowrule: "effect1, effect2, ..., match:class CLASS"
  let rule = format!("{}, match:class {}", effects.join(", "), escaped_class);
  Keyword::set("windowrule", rule.clone()).context("Failed to set window rule")?;

  send_notification("Pin Window", &rule, "low")?;
  println!("{}", &rule);

  Ok(())
}
