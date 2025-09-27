#!/usr/bin/env lua

local script_path = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
package.path = package.path .. ';' .. script_path .. '?.lua'
local utils = require('utils')


local toggle_cmd = 'hyprctl activeworkspace'
local toggle_result, toggle_exit = utils.execute_command(toggle_cmd)
if toggle_exit ~= 0 then
	utils.notify('hyprctl', 'Failed to run hyprctl activeworkspace', 'Low', '-t 5000', 'Hyprpanel')
	return
end

local monitor_id = toggle_result:match("monitorID: (%d+)")
if not monitor_id or #monitor_id == 0 then
  utils.notify('hyprctl', 'Failed to get current monitor ID', 'Low', '-t 5000', 'Hyprpanel')
  return
end

-- utils.notify('hyprctl', 'Toggled current bar for workspace ID ' .. workspace_id, 'Low', '-t 2000', 'Hyprpanel')
utils.execute_command('hyprpanel toggleWindow bar-' .. monitor_id)
