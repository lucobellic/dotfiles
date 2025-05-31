#!/usr/bin/env lua

local script_path = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
package.path = package.path .. ';' .. script_path .. '?.lua'
local global = require('globalcontrol')

local conf_dir = os.getenv('HOME') .. '/.config' -- Adjust based on globalcontrol.sh
local rofi_scale = 10
local hypr_border = global.config.hypr_border
local hypr_width = global.config.hypr_width

local roconf = conf_dir .. '/rofi/clipboard.rasi'
local favorites_file = os.getenv('HOME') .. '/.cliphist_favorites'

local r_scale = string.format('configuration {font: \\"JetBrainsMono Nerd Font %d\\";}', rofi_scale)
local wind_border = math.floor(hypr_border * 3 / 2)
local elem_border = hypr_border == 0 and 5 or hypr_border

--- @param cmd string
--- @return string
local function execute_command(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return ''
  end
  local result = handle:read('*a')
  handle:close()
  return result:gsub('%s+$', '') -- trim trailing whitespace
end

--- @param str string
--- @return string
local function escape_shell_arg(str) return "'" .. str:gsub("'", "'\"'\"'") .. "'" end

--- @param content string
--- @return boolean
local function is_valid_clipboard_content(content) return content and content ~= '' and not content:match('^%s*$') end

--- @param str string
--- @param max_length integer
--- @return string
local function truncate_string(str, max_length)
  max_length = max_length or 80
  if #str <= max_length then
    return str
  end
  return str:sub(1, max_length - 3) .. '...'
end

--- @param content string
--- @return string
local function sanitize_for_display(content)
  --- @diagnostic disable-next-line: redundant-return-value
  return content:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' ')
end

--- @param json_str string
--- @param path string
--- @return string
local function parse_json_value(json_str, path)
  -- This is a simplified JSON parser for specific values
  -- In a real implementation, you'd want to use a proper JSON library
  local pattern = '"' .. path .. '":%s*([%d%.%-]+)'
  local value = json_str:match(pattern)
  return value or '0'
end

--- @return boolean, string|nil
local function validate_config()
  if not roconf or roconf == '' then
    return false, 'Rofi config file path not set'
  end

  local file = io.open(roconf, 'r')
  if not file then
    return false, 'Rofi config file not found: ' .. roconf
  end
  file:close()

  return true, nil
end

--- @return string
local function get_window_positioning()
  -- Evaluate spawn position
  local cursor_pos_output = execute_command('hyprctl cursorpos -j')
  execute_command('hyprctl -j monitors')

  -- Parse cursor position
  --- @type number[]
  local cur_pos = {}
  cur_pos[1] = tonumber(parse_json_value(cursor_pos_output, 'x')) or 0
  cur_pos[2] = tonumber(parse_json_value(cursor_pos_output, 'y')) or 0

  -- Parse monitor resolution (simplified)
  --- @type number[]
  local mon_res = {}
  mon_res[1] = 1920 -- width - would need proper JSON parsing
  mon_res[2] = 1080 -- height - would need proper JSON parsing
  mon_res[3] = 100 -- scale * 100
  mon_res[4] = 0 -- x offset
  mon_res[5] = 0 -- y offset

  -- Parse offsets (simplified)
  --- @type number[]
  local off_res = { 0, 0, 0, 0 } -- would need proper JSON parsing

  -- Calculate relative cursor position
  cur_pos[1] = cur_pos[1] - mon_res[4]
  cur_pos[2] = cur_pos[2] - mon_res[5]

  -- Determine position
  --- @type string, string, integer, integer
  local x_pos, y_pos, x_off, y_off

  if cur_pos[1] >= (mon_res[1] / 2) then
    x_pos = 'east'
    x_off = -(mon_res[1] - cur_pos[1] - off_res[3])
  else
    x_pos = 'west'
    x_off = cur_pos[1] - off_res[1]
  end

  if cur_pos[2] >= (mon_res[2] / 2) then
    y_pos = 'south'
    y_off = -(mon_res[2] - cur_pos[2] - off_res[4])
  else
    y_pos = 'north'
    y_off = cur_pos[2] - off_res[2]
  end

  return string.format(
    'window{location:%s %s;anchor:%s %s;x-offset:%dpx;y-offset:%dpx;border:%dpx;border-radius:%dpx;} wallbox{border-radius:%dpx;} element{border-radius:%dpx;}',
    x_pos,
    y_pos,
    x_pos,
    y_pos,
    x_off,
    y_off,
    hypr_width,
    wind_border,
    elem_border,
    elem_border
  )
end

--- @param options string
--- @param placeholder string
--- @return string
local function show_rofi_menu(options, placeholder)
  local r_override = get_window_positioning()
  local cmd = string.format(
    'echo -e "%s" | rofi -dmenu -theme-str "entry { placeholder: \\"%s\\";}" -theme-str "%s" -theme-str "%s" -config "%s"',
    options,
    placeholder,
    r_scale,
    r_override,
    roconf
  )
  return execute_command(cmd)
end

--- @param message string
--- @return boolean
local function confirm_action(message)
  local result = show_rofi_menu('Yes\\nNo', message)
  return result == 'Yes'
end

--- @param message string
--- @param urgency string|nil
local function notify(message, urgency)
  urgency = urgency or 'normal'
  local cmd = string.format('notify-send -u "%s" "Cliphist" "%s"', urgency, message)
  execute_command(cmd)
end

--- @param filename string
--- @return boolean
local function file_exists_and_not_empty(filename)
  local file = io.open(filename, 'r')
  if not file then
    return false
  end
  local content = file:read('*a')
  file:close()
  return #content > 0
end

--- @param filename string
--- @return string[]
local function read_file_lines(filename)
  local lines = {}
  local file = io.open(filename, 'r')
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
  end
  return lines
end

--- @param filename string
--- @param content string
local function write_file(filename, content)
  local file = io.open(filename, 'w')
  if file then
    file:write(content)
    file:close()
  end
end

--- @param filename string
--- @param content string
local function append_to_file(filename, content)
  local file = io.open(filename, 'a')
  if file then
    file:write(content .. '\n')
    file:close()
  end
end

--- @return string
local function get_clipboard_history() return execute_command('cliphist list') end

--- @param item string
--- @return string
local function decode_clipboard_item(item)
  if not item or item == '' then
    return ''
  end
  return execute_command('echo ' .. escape_shell_arg(item) .. ' | cliphist decode')
end

--- @param content string
--- @return boolean
local function copy_to_clipboard(content)
  if not is_valid_clipboard_content(content) then
    return false
  end

  local cmd = 'echo ' .. escape_shell_arg(content) .. ' | wl-copy'
  execute_command(cmd)
  return true
end


--- @param content string
--- @return string
local function encode_for_favorites(content)
  return execute_command('echo ' .. escape_shell_arg(content) .. ' | base64 -w 0')
end

--- @param encoded string
--- @return string
local function decode_from_favorites(encoded)
  return execute_command('echo ' .. escape_shell_arg(encoded) .. ' | base64 --decode')
end

--- @param encoded_item string
--- @return boolean
local function item_exists_in_favorites(encoded_item)
  local favorites = read_file_lines(favorites_file)
  for _, fav in ipairs(favorites) do
    if fav == encoded_item then
      return true
    end
  end
  return false
end

--- @return integer
local function get_favorites_count()
  if not file_exists_and_not_empty(favorites_file) then
    return 0
  end
  local favorites = read_file_lines(favorites_file)
  return #favorites
end


local function handle_history_action()
  local history = get_clipboard_history()
  if not history or history == '' then
    notify('No clipboard history available', 'low')
    return
  end

  local r_override = get_window_positioning()
  local selected_item = execute_command(
    'cliphist list | rofi -dmenu -theme-str "entry { placeholder: \\"History...\\";}" -theme-str "'
      .. r_scale
      .. '" -theme-str "'
      .. r_override
      .. '" -config "'
      .. roconf
      .. '"'
  )

  if selected_item ~= '' then
    local decoded_content = decode_clipboard_item(selected_item)
    if copy_to_clipboard(decoded_content) then
      notify('Copied to clipboard')
    else
      notify('Failed to copy to clipboard', 'critical')
    end
  end
end

local function handle_delete_action()
  local history = get_clipboard_history()
  if not history or history == '' then
    notify('No clipboard history to delete', 'low')
    return
  end

  local r_override = get_window_positioning()
  local selected_item = execute_command(
    'cliphist list | rofi -dmenu -theme-str "entry { placeholder: \\"Delete...\\";}" -theme-str "'
      .. r_scale
      .. '" -theme-str "'
      .. r_override
      .. '" -config "'
      .. roconf
      .. '"'
  )

  if selected_item ~= '' then
    execute_command('echo ' .. escape_shell_arg(selected_item) .. ' | cliphist delete')
    notify('Item deleted from history')
  end
end

local function handle_view_favorites_action()
  if not file_exists_and_not_empty(favorites_file) then
    notify('No favorites available', 'low')
    return
  end

  local favorites = read_file_lines(favorites_file)
  local decoded_lines = {}

  for _, favorite in ipairs(favorites) do
    local decoded_favorite = decode_from_favorites(favorite)
    local sanitized = sanitize_for_display(decoded_favorite)
    local truncated = truncate_string(sanitized, 100)
    table.insert(decoded_lines, truncated)
  end

  local options = table.concat(decoded_lines, '\\n')
  local selected_favorite = show_rofi_menu(options, 'View Favorites')

  if selected_favorite ~= '' then
    for i, line in ipairs(decoded_lines) do
      if line == selected_favorite then
        local original_content = decode_from_favorites(favorites[i])
        if copy_to_clipboard(original_content) then
          notify('Favorite copied to clipboard')
        else
          notify('Failed to copy favorite', 'critical')
        end
        break
      end
    end
  end
end

local function handle_manage_favorites_action()
  local manage_action =
    show_rofi_menu('Add to Favorites\\nDelete from Favorites\\nClear All Favorites', 'Manage Favorites')

  if manage_action == 'Add to Favorites' then
    local r_override = get_window_positioning()
    local item = execute_command(
      'cliphist list | rofi -dmenu -theme-str "entry { placeholder: \\"Add to Favorites...\\";}" -theme-str "'
        .. r_scale
        .. '" -theme-str "'
        .. r_override
        .. '" -config "'
        .. roconf
        .. '"'
    )

    if item ~= '' then
      local full_item = decode_clipboard_item(item)
      local encoded_item = encode_for_favorites(full_item)

      if item_exists_in_favorites(encoded_item) then
        notify('Item is already in favorites', 'low')
      else
        append_to_file(favorites_file, encoded_item)
        notify('Added to favorites')
      end
    end
  elseif manage_action == 'Delete from Favorites' then
    if not file_exists_and_not_empty(favorites_file) then
      notify('No favorites to remove', 'low')
      return
    end

    local favorites = read_file_lines(favorites_file)
    local decoded_lines = {}

    for _, favorite in ipairs(favorites) do
      local decoded_favorite = decode_from_favorites(favorite)
      local sanitized = sanitize_for_display(decoded_favorite)
      local truncated = truncate_string(sanitized, 100)
      table.insert(decoded_lines, truncated)
    end

    local options = table.concat(decoded_lines, '\\n')
    local selected_favorite = show_rofi_menu(options, 'Remove from Favorites...')

    if selected_favorite ~= '' then
      for i, line in ipairs(decoded_lines) do
        if line == selected_favorite then
          table.remove(favorites, i)
          write_file(favorites_file, table.concat(favorites, '\n'))
          notify('Item removed from favorites')
          break
        end
      end
    end
  elseif manage_action == 'Clear All Favorites' then
    if not file_exists_and_not_empty(favorites_file) then
      notify('No favorites to delete', 'low')
      return
    end

    if confirm_action('Clear All Favorites?') then
      write_file(favorites_file, '')
      notify('All favorites cleared')
    end
  end
end

local function handle_clear_history_action()
  if confirm_action('Clear Clipboard History?') then
    execute_command('cliphist wipe')
    notify('Clipboard history cleared')
  end
end

local function main()
  -- Validate configuration
  local config_valid, config_error = validate_config()
  if not config_valid then
    notify('Configuration error: ' .. (config_error or 'unknown'), 'critical')
    os.exit(1)
  end

  local main_action = ''

  if #arg == 0 then
    local favorites_count = get_favorites_count()
    local menu_options = 'History\\nDelete\\nView Favorites ('
      .. favorites_count
      .. ')\\nManage Favorites\\nClear History'
    main_action = show_rofi_menu(menu_options, 'Choose action')
  else
    main_action = 'History'
  end

  if main_action == 'History' then
    handle_history_action()
  elseif main_action == 'Delete' then
    handle_delete_action()
  elseif main_action:match('^View Favorites') then
    handle_view_favorites_action()
  elseif main_action == 'Manage Favorites' then
    handle_manage_favorites_action()
  elseif main_action == 'Clear History' then
    handle_clear_history_action()
  elseif main_action ~= '' then
    notify('Unknown action: ' .. main_action, 'critical')
    os.exit(1)
  end
end

main()
