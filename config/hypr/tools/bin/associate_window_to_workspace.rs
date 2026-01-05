#!/usr/bin/env -S cargo +nightly -Zscript
---cargo
[package]
name = "associate_window_to_workspace"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1"
hyprland = "0.4.0-beta.3"
tokio = "1"
regex = "1"
---

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
    // Get the active window
    let active_window = Client::get_active()
        .context("Failed to get active window")?;

    let Some(active_window) = active_window else {
        send_notification(
            "Workspace Association",
            "No active window found",
            "low",
        )?;
        anyhow::bail!("No active window found");
    };

    let window_class = &active_window.class;
    let window_title = &active_window.title;
    let workspace_id = active_window.workspace.id;

    if window_class.is_empty() {
        send_notification(
            "Workspace Association",
            "No active window found",
            "low",
        )?;
        anyhow::bail!("No active window class found");
    }

    // Escape special regex characters in class and title
    let escaped_class = regex_escape(window_class);
    let escaped_title = regex_escape(window_title);

    // Create a window rule to bind this window to the current workspace
    // Using class and title for precise matching
    let rule = format!(
        "workspace {} silent, match:class ^({})$, match:title ^({})$",
        workspace_id, escaped_class, escaped_title
    );

    Keyword::set("windowrulev2", rule)
        .context("Failed to set window rule")?;

    // Notify user
    let message = format!(
        "Window '{}' associated to workspace {}",
        window_class, workspace_id
    );
    send_notification("Workspace Association", &message, "low")?;

    println!(
        "Associated window '{}' (title: '{}') to workspace {}",
        window_class, window_title, workspace_id
    );

    Ok(())
}
