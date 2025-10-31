---
description: Perform web search to gather online and up-to-date information.
mode: subagent
model: "github-copilot/gpt-5-mini"
temperature: 0.1
tools:
  bash: true
  edit: false
  write: false
  read: true
  grep: true
  glob: true
  list: true
  todowrite: true
  todoread: true
  webfetch: false
  "brave-search*": true
  "exa*": false
---
