#!/usr/bin/env lua

local script_path = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
package.path = package.path .. ';' .. script_path .. '?.lua'
local utils = require('utils')

--- @type string
local script_name = utils.get_script_name(arg[0])

-- Check if the script is already running
if utils.is_already_running(script_name) then
  print('An instance of the script is already running...')
  os.exit(1)
end

-- Check if SwayOSD is installed
--- @type boolean
local use_swayosd = utils.command_exists('swayosd-client') and utils.process_running('swayosd-server')

--- @return nil
local function print_error()
  print(string.format(
    [[
    %s <action> [step]
    ...valid actions are...
        i -- <i>ncrease brightness [+5%%]
        d -- <d>ecrease brightness [-5%%]

    Example:
        %s i 10    # Increase brightness by 10%%
        %s d       # Decrease brightness by default step (5%%)
]],
    script_name,
    script_name,
    script_name
  ))
end

--- @return nil
local function send_notification()
  local brightness_str, _ = utils.execute_command("brightnessctl info | grep -oP '(?<=\\()\\d+(?=%)'")

  -- Clean the string and ensure it's valid
  if brightness_str then
    brightness_str = brightness_str:gsub('%s+', '')
    brightness_str = brightness_str:match('%d+')
  end

  local brightness = tonumber(brightness_str) or 0

  local brightinfo, _ = utils.execute_command("brightnessctl info | awk -F \"'\" '/Device/ {print $2}'")
  brightinfo = brightinfo:gsub('%s+', '')

  local angle = math.floor(((brightness + 2) / 5)) * 5
  local ico = os.getenv('HOME') .. '/.config/dunst/icons/vol/vol-' .. angle .. '.svg'

  local bar_length = math.floor(brightness / 15)
  local bar = string.rep('.', bar_length)

  utils.notify(brightness .. bar, brightinfo, 'normal', '-a "t2" -r 91190 -t 800 -i "' .. ico .. '"')
end

--- @return number
local function get_brightness()
  local brightness_str, _ = utils.execute_command("brightnessctl -m | grep -o '[0-9]\\+%' | head -c-2")
  brightness_str = brightness_str:gsub('%s+', '')
  return tonumber(brightness_str) or 0
end

--- @type string
local action = arg[1]
--- @type number
local step = tonumber(arg[2]) or 5

if action == 'i' or action == '-i' then
  -- increase the backlight
  local current_brightness = get_brightness()
  if current_brightness < 10 then
    -- increase the backlight by 1% if less than 10%
    step = 1
  end

  if use_swayosd then
    local cmd = 'swayosd-client --brightness raise ' .. step
    if os.execute(cmd) then
      os.exit(0)
    end
  end

  os.execute('brightnessctl set +' .. step .. '%')
  send_notification()
elseif action == 'd' or action == '-d' then
  -- decrease the backlight
  local current_brightness = get_brightness()

  if current_brightness <= 10 then
    -- decrease the backlight by 1% if less than 10%
    step = 1
  end

  if current_brightness <= 1 then
    os.execute('brightnessctl set ' .. step .. '%')
    if use_swayosd then
      os.exit(0)
    end
  else
    if use_swayosd then
      local cmd = 'swayosd-client --brightness lower ' .. step
      if os.execute(cmd) then
        os.exit(0)
      end
    end
    os.execute('brightnessctl set ' .. step .. '%-')
  end

  send_notification()
else
  -- print error
  print_error()
end
