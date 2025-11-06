#!/usr/bin/env lua

local script_path = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
package.path = package.path .. ';' .. script_path .. '?.lua'
local global = require('globalcontrol')
local utils = require('utils')

--- @class RofiLauncher
--- @field conf_dir string
--- @field rofi_style string
--- @field rofi_scale number
--- @field hypr_border number
--- @field hypr_width number
local RofiLauncher = {}
RofiLauncher.__index = RofiLauncher

--- Initialize RofiLauncher instance
--- @return RofiLauncher
function RofiLauncher.new()
  local self = setmetatable({
    conf_dir = global.config.conf_dir,
    rofi_style = global.config.theme['rofiStyle'] or '10',
    rofi_scale = utils.get_env_number('rofiScale', 10),
    hypr_border = global.config.hypr_border,
    hypr_width = global.config.hypr_width,
  }, RofiLauncher)

  return self
end

--- Get rofi configuration file
--- @return string
function RofiLauncher:get_rofi_config()
  local roconf = string.format('%s/rofi/styles/style_%s.rasi', self.conf_dir, self.rofi_style)

  if not utils.file_exists(roconf) then
    -- Find first available style file
    local pattern = '-type f -name "style_*.rasi" | sort -t "_" -k 2 -n | head -1'
    local style_files = utils.find_files(self.conf_dir .. '/rofi/styles', pattern)
    if #style_files > 0 then
      roconf = style_files[1]
    end
  end

  return roconf
end

--- Get icon theme from gsettings
--- @return string
function RofiLauncher:get_icon_theme()
  local cmd = 'gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null'
  local result, exit_code = utils.execute_command(cmd)
  if exit_code == 0 and result ~= '' then
    return result:gsub("'", '')
  end
  return 'Papirus'
end

--- Launch rofi with specified mode
--- @param mode string
function RofiLauncher:launch(mode)
  local roconf = self:get_rofi_config()

  -- Build theme strings
  local r_scale = string.format('configuration {font: \\"DM Mono Medium %d\\";}', self.rofi_scale)
  local i_override = string.format('configuration {icon-theme: \\"%s\\";}', self:get_icon_theme())

  -- Build and execute rofi command
  local cmd =
    string.format('rofi -show "%s" -theme-str "%s" -theme-str "%s" -config "%s"', mode, r_scale, i_override, roconf)
  print('Executing command:', cmd)

  os.execute(cmd)
end

--- Show help message
function RofiLauncher:show_help()
  local script_name = utils.get_script_name(arg[0])
  print(string.format('%s [action]', script_name))
  print('r :  run mode')
  print('d :  drun mode')
  print('w :  window mode')
  print('f :  filebrowser mode')
end

--- Main function
local function main()
  local launcher = RofiLauncher.new()
  local actions = {
    ['r'] = function() launcher:launch('run') end,
    ['--run'] = function() launcher:launch('run') end,
    ['d'] = function() launcher:launch('drun') end,
    ['--drun'] = function() launcher:launch('drun') end,
    ['w'] = function() launcher:launch('window') end,
    ['--window'] = function() launcher:launch('window') end,
    ['f'] = function() launcher:launch('filebrowser') end,
    ['--filebrowser'] = function() launcher:launch('filebrowser') end,
    ['h'] = function()
      launcher:show_help()
      os.exit(0)
    end,
    ['--help'] = function()
      launcher:show_help()
      os.exit(0)
    end,
  }

  -- Parse command line arguments
  if #arg > 0 and actions[arg[1]] then
    actions[arg[1]]()
  else
    launcher:launch('run')
  end
end

-- Run main function if script is executed directly
if arg and arg[0]:match('rofilaunch%.lua$') then
  main()
end

return RofiLauncher
