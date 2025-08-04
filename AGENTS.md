# AGENTS.md

## Build, Lint, and Test Commands
- This repository is a dotfiles/home-manager config; no standard build or test commands.
- For Nix config changes, apply with:
  - `home-manager switch`
- For Lua code (Neovim, etc):
  - Lint: use `selene` (config: selene.toml)
  - Format: use `stylua` (config: stylua.toml)

## Code Style Guidelines
- **Lua Formatting:**
  - Indent with 2 spaces, max line 120 chars
  - Prefer single quotes, always use parentheses in calls
  - Collapse simple statements in functions only
  - Requires are sorted
- **Lua Linting:**
  - Global usage, mixed tables, multiple statements allowed
  - Standard library use is permissive
- **Naming:**
  - Use clear, descriptive names for variables and functions
- **Imports:**
  - Use `require` for Lua modules, sorted if possible
- **Types:**
  - Use types where supported (Lua: optional)
- **Error Handling:**
  - Prefer explicit error handling in scripts
- **General:**
  - Keep configs modular and readable
  - Document non-obvious logic inline

No Cursor or Copilot rules detected.
