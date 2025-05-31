#!/usr/bin/env lua

--- @type string
local script_name = arg[0]:match('([^/]+)$')

-- Check if the script is already running
local function is_already_running()
  local handle = io.popen("pgrep -cf '" .. script_name .. "' | grep -qv 1")
  local result = handle:read('*a')
  handle:close()
  return result ~= ''
end

if is_already_running() then
  print('An instance of the script is already running...')
  os.exit(1)
end

--- @type string
local scr_dir = arg[0]:match('(.*/)')
if not scr_dir then
  scr_dir = './'
end

-- Source globalcontrol.sh equivalent (would need to be converted separately)
-- require(scr_dir .. "globalcontrol")

-- Check if SwayOSD is installed
--- @type boolean
local use_swayosd = false

local function command_exists(cmd)
  local handle = io.popen('command -v ' .. cmd .. ' >/dev/null 2>&1')
  local result = handle:close()
  return result
end

local function process_running(name)
  local handle = io.popen('pgrep -x ' .. name .. ' >/dev/null')
  local result = handle:close()
  return result
end

if command_exists('swayosd-client') and process_running('swayosd-server') then
  use_swayosd = true
end

--- @return nil
local function print_error()
  local basename = script_name
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
    basename,
    basename,
    basename
  ))
end

--- @return nil
local function send_notification()
  local handle = io.popen("brightnessctl info | grep -oP '(?<=\\()\\d+(?=%)'")
  local brightness_str = handle:read('*a')
  handle:close()

  -- Clean the string and ensure it's valid
  if brightness_str then
    brightness_str = brightness_str:gsub('%s+', '')
    brightness_str = brightness_str:match('%d+')
  end

  local brightness = tonumber(brightness_str) or 0

  handle = io.popen("brightnessctl info | awk -F \"'\" '/Device/ {print $2}'")
  local brightinfo = handle:read('*a'):gsub('%s+', '')
  handle:close()

  local angle = math.floor(((brightness + 2) / 5)) * 5
  local ico = os.getenv('HOME') .. '/.config/dunst/icons/vol/vol-' .. angle .. '.svg'

  local bar_length = math.floor(brightness / 15)
  local bar = string.rep('.', bar_length)

  local cmd = string.format('notify-send -a "t2" -r 91190 -t 800 -i "%s" "%s%s" "%s"', ico, brightness, bar, brightinfo)
  os.execute(cmd)
end

--- @return number
local function get_brightness()
  local handle = io.popen("brightnessctl -m | grep -o '[0-9]\\+%' | head -c-2")
  local brightness_str = handle:read('*a'):gsub('%s+', '')
  local brightness = tonumber(brightness_str)
  handle:close()
  return brightness or 0
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
