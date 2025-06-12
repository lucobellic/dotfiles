#!/usr/bin/env lua

--- Execute shell command and return trimmed output
--- @param cmd string Command to execute
--- @return string
local function execute_command(cmd)
  local handle = assert(io.popen(cmd), 'Failed to execute command: ' .. cmd)
  local result = handle:read('*a') --- @type string
  local success, exit_type, exit_code = handle:close()

  if not success then
    error(string.format('Command failed: %s (exit %s: %d)', cmd, exit_type, exit_code))
  end

  -- Remove leading and trailing whitespace from the result
  local trimmed = result:match('^%s*(.-)%s*$') or ''
  return trimmed
end

--- Check if monitor is connected via hyprctl
--- @param monitor_desc string Monitor description to check
--- @return boolean
local function is_monitor_connected(monitor_desc)
  local monitors = execute_command('hyprctl monitors')
  local found = monitors:find(monitor_desc, 1, true) ~= nil
  return found
end

--- Monitor configurations
--- @type table<string, string[]>
local monitor_configs = {
  work = {
    'Dell Inc. DELL U2520D DLC9923',
    'Dell Inc. DELL U2520D 70C9923',
    'Dell Inc. DELL U2518D 3C4YP9BM468L',
  },
  home = {
    'Samsung Electric Company LC49G95T H4ZNC01246',
    'Dell Inc. DELL U2415 7MT0176I0M8S',
  },
}

--- Detect monitor setup based on connected monitors
--- @return string
local function detect_setup()
  local counts = { work = 0, home = 0 }

  for setup_type, monitors in pairs(monitor_configs) do
    for _, monitor in ipairs(monitors) do
      if is_monitor_connected(monitor) then
        counts[setup_type] = counts[setup_type] + 1
      end
    end
  end

  local detected_setup
  if counts.work >= 2 then
    detected_setup = 'work'
  elseif counts.home >= 1 then
    detected_setup = 'home'
  else
    detected_setup = 'default'
  end

  return detected_setup
end

--- Check if config file exists
--- @param setup string Setup name
--- @return boolean
local function config_exists(setup)
  local config_path = os.getenv('HOME') .. '/.config/hypr/monitors/' .. setup .. '.conf'
  local file = io.open(config_path, 'r')
  if file then
    file:close()
    return true
  end
  return false
end

-- Main execution
local function main()
  local setup = detect_setup()
  local config_path = '~/.config/hypr/monitors/' .. setup .. '.conf'

  if not config_exists(setup) then
    print('ERROR: Configuration file not found: ' .. config_path)
    os.exit(1)
  end

  execute_command('hyprctl keyword source ' .. config_path)
  execute_command('notify-send "Setup Monitor: ' .. setup .. '"')
end

-- Run main function with error handling
local success, err = pcall(main)
if not success then
  execute_command('notify-send "Setup Monitor" "Error: ' .. err .. '"')
  os.exit(1)
end
