#!/usr/bin/env lua

local script_path = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
package.path = package.path .. ';' .. script_path .. '?.lua'
local global = require('globalcontrol')
local utils = require('utils')

local conf_dir = os.getenv('HOME') .. '/.config'
local rofi_scale = 10
local hypr_border = global.config.hypr_border
local hypr_width = global.config.hypr_width

local roconf = conf_dir .. '/rofi/clipboard.rasi'
local favorites_file = os.getenv('HOME') .. '/.cliphist_favorites'

local r_scale = string.format('configuration {font: \\"JetBrainsMono Nerd Font %d\\";}', rofi_scale)
local wind_border = math.floor(hypr_border * 3 / 2)
local elem_border = hypr_border == 0 and 5 or hypr_border

--- @return boolean, string|nil
local function validate_config()
  if not roconf or roconf == '' then
    return false, 'Rofi config file path not set'
  end

  if not utils.file_exists(roconf) then
    return false, 'Rofi config file not found: ' .. roconf
  end

  return true, nil
end

--- @return string
local function get_window_positioning()
  local cursor_pos_output, _ = utils.execute_command('hyprctl cursorpos -j')
  local monitors_output, _ = utils.execute_command('hyprctl monitors -j')

  local cur_x = tonumber(utils.parse_json_value(cursor_pos_output, 'x')) or 0
  local cur_y = tonumber(utils.parse_json_value(cursor_pos_output, 'y')) or 0

  local mon_width = tonumber(monitors_output:match('"width":%s*(%d+)')) or 1920
  local mon_height = tonumber(monitors_output:match('"height":%s*(%d+)')) or 1080
  local mon_x = tonumber(monitors_output:match('"x":%s*(%-?%d+)')) or 0
  local mon_y = tonumber(monitors_output:match('"y":%s*(%-?%d+)')) or 0

  local rel_x = cur_x - mon_x
  local rel_y = cur_y - mon_y

  local x_pos, y_pos, x_off, y_off

  if rel_x >= (mon_width / 2) then
    x_pos = 'east'
    x_off = -(mon_width - rel_x)
  else
    x_pos = 'west'
    x_off = rel_x
  end

  if rel_y >= (mon_height / 2) then
    y_pos = 'south'
    y_off = -(mon_height - rel_y)
  else
    y_pos = 'north'
    y_off = rel_y
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
  local result, _ = utils.execute_command(cmd)
  return result
end

--- @param message string
--- @return boolean
local function confirm_action(message)
  local result = show_rofi_menu('Yes\\nNo', message)
  return result == 'Yes'
end

--- @return string
local function get_clipboard_history()
  local result, _ = utils.execute_command('cliphist list')
  return result
end

--- @param item string
--- @return string
local function decode_clipboard_item(item)
  if not utils.is_valid_content(item) then
    return ''
  end
  local result, _ = utils.execute_command('echo ' .. utils.escape_shell_arg(item) .. ' | cliphist decode')
  return result
end

--- @param content string
--- @return boolean
local function copy_to_clipboard(content)
  if not utils.is_valid_content(content) then
    return false
  end

  local cmd = 'echo ' .. utils.escape_shell_arg(content) .. ' | wl-copy'
  utils.execute_command(cmd)
  return true
end

--- @param encoded_item string
--- @return boolean
local function item_exists_in_favorites(encoded_item)
  local favorites = utils.read_file_lines(favorites_file)
  for _, fav in ipairs(favorites) do
    if fav == encoded_item then
      return true
    end
  end
  return false
end

--- @return integer
local function get_favorites_count()
  if not utils.file_exists_and_not_empty(favorites_file) then
    return 0
  end
  local favorites = utils.read_file_lines(favorites_file)
  return #favorites
end

local function handle_history_action()
  local history = get_clipboard_history()
  if not utils.is_valid_content(history) then
    utils.notify('Cliphist', 'No clipboard history available', 'low')
    return
  end

  local r_override = get_window_positioning()
  local selected_item, _ = utils.execute_command(
    'cliphist list | rofi -dmenu -theme-str "entry { placeholder: \\"History...\\";}" -theme-str "'
      .. r_scale
      .. '" -theme-str "'
      .. r_override
      .. '" -config "'
      .. roconf
      .. '"'
  )

  if utils.is_valid_content(selected_item) then
    local decoded_content = decode_clipboard_item(selected_item)
    if copy_to_clipboard(decoded_content) then
      utils.notify('Cliphist', 'Copied to clipboard')
    else
      utils.notify('Cliphist', 'Failed to copy to clipboard', 'critical')
    end
  end
end

local function handle_delete_action()
  local history = get_clipboard_history()
  if not utils.is_valid_content(history) then
    utils.notify('Cliphist', 'No clipboard history to delete', 'low')
    return
  end

  local r_override = get_window_positioning()
  local selected_item, _ = utils.execute_command(
    'cliphist list | rofi -dmenu -theme-str "entry { placeholder: \\"Delete...\\";}" -theme-str "'
      .. r_scale
      .. '" -theme-str "'
      .. r_override
      .. '" -config "'
      .. roconf
      .. '"'
  )

  if utils.is_valid_content(selected_item) then
    utils.execute_command('echo ' .. utils.escape_shell_arg(selected_item) .. ' | cliphist delete')
    utils.notify('Cliphist', 'Item deleted from history')
  end
end

local function handle_view_favorites_action()
  if not utils.file_exists_and_not_empty(favorites_file) then
    utils.notify('Cliphist', 'No favorites available', 'low')
    return
  end

  local favorites = utils.read_file_lines(favorites_file)
  local decoded_lines = {}

  for _, favorite in ipairs(favorites) do
    local decoded_favorite = utils.decode_base64(favorite)
    local sanitized = utils.sanitize_for_display(decoded_favorite)
    local truncated = utils.truncate_string(sanitized, 100)
    table.insert(decoded_lines, truncated)
  end

  local options = table.concat(decoded_lines, '\\n')
  local selected_favorite = show_rofi_menu(options, 'View Favorites')

  if utils.is_valid_content(selected_favorite) then
    for i, line in ipairs(decoded_lines) do
      if line == selected_favorite then
        local original_content = utils.decode_base64(favorites[i])
        if copy_to_clipboard(original_content) then
          utils.notify('Cliphist', 'Favorite copied to clipboard')
        else
          utils.notify('Cliphist', 'Failed to copy favorite', 'critical')
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
    local item, _ = utils.execute_command(
      'cliphist list | rofi -dmenu -theme-str "entry { placeholder: \\"Add to Favorites...\\";}" -theme-str "'
        .. r_scale
        .. '" -theme-str "'
        .. r_override
        .. '" -config "'
        .. roconf
        .. '"'
    )

    if utils.is_valid_content(item) then
      local full_item = decode_clipboard_item(item)
      local encoded_item = utils.encode_base64(full_item)

      if item_exists_in_favorites(encoded_item) then
        utils.notify('Cliphist', 'Item is already in favorites', 'low')
      else
        utils.append_to_file(favorites_file, encoded_item)
        utils.notify('Cliphist', 'Added to favorites')
      end
    end
  elseif manage_action == 'Delete from Favorites' then
    if not utils.file_exists_and_not_empty(favorites_file) then
      utils.notify('Cliphist', 'No favorites to remove', 'low')
      return
    end

    local favorites = utils.read_file_lines(favorites_file)
    local decoded_lines = {}

    for _, favorite in ipairs(favorites) do
      local decoded_favorite = utils.decode_base64(favorite)
      local sanitized = utils.sanitize_for_display(decoded_favorite)
      local truncated = utils.truncate_string(sanitized, 100)
      table.insert(decoded_lines, truncated)
    end

    local options = table.concat(decoded_lines, '\\n')
    local selected_favorite = show_rofi_menu(options, 'Remove from Favorites...')

    if utils.is_valid_content(selected_favorite) then
      for i, line in ipairs(decoded_lines) do
        if line == selected_favorite then
          table.remove(favorites, i)
          utils.write_file(favorites_file, table.concat(favorites, '\n'))
          utils.notify('Cliphist', 'Item removed from favorites')
          break
        end
      end
    end
  elseif manage_action == 'Clear All Favorites' then
    if not utils.file_exists_and_not_empty(favorites_file) then
      utils.notify('Cliphist', 'No favorites to delete', 'low')
      return
    end

    if confirm_action('Clear All Favorites?') then
      utils.write_file(favorites_file, '')
      utils.notify('Cliphist', 'All favorites cleared')
    end
  end
end

local function handle_clear_history_action()
  if confirm_action('Clear Clipboard History?') then
    utils.execute_command('cliphist wipe')
    utils.notify('Cliphist', 'Clipboard history cleared')
  end
end

local function main()
  -- Validate configuration
  local config_valid, config_error = validate_config()
  if not config_valid then
    utils.notify('Cliphist', 'Configuration error: ' .. (config_error or 'unknown'), 'critical')
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
  elseif utils.is_valid_content(main_action) then
    utils.notify('Cliphist', 'Unknown action: ' .. main_action, 'critical')
    os.exit(1)
  end
end

main()
