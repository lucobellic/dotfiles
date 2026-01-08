---
description: Perform web search to gather online and up-to-date information.
mode: subagent
model: github-copilot/gpt-5-mini
temperature: 0.1
permission:
  bash: allow
  edit: deny
  write: deny
  read: allow
  grep: allow
  glob: allow
  list: allow
  todowrite: allow
  todoread: allow
  webfetch: deny
  "brave-search*": allow
  "exa*": deny
---
