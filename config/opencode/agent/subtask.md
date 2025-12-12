---
description: Perform sub-tasks to apply a subset of clearly defined instructions, to be spawned in parallel.
mode: subagent
model: "github-copilot/gpt-5-mini"
temperature: 0.1
tools:
  bash: true
  edit: true
  write: true
  read: true
  grep: true
  glob: true
  list: true
  todowrite: true
  todoread: true
  webfetch: false
  "brave-search*": false
  "exa*": false
---
