#!/usr/bin/env lua

local script_path = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
package.path = package.path .. ';' .. script_path .. '?.lua'
local utils = require('utils')

--- @class GlobalControl
--- @field conf_dir string
--- @field theme_conf_dir string
--- @field cache_dir string
--- @field thmb_dir string
--- @field dcol_dir string
--- @field hash_mech string
--- @field theme_theme string
--- @field theme_theme_dir string
--- @field wallbash_dir string
--- @field enable_wall_dcol number
--- @field hypr_border number
--- @field hypr_width number
--- @field theme table
local GlobalControl = {}
GlobalControl.__index = GlobalControl

--- @class HashMapResult
--- @field wall_hash string[]
--- @field wall_list string[]

--- @class ThemeResult
--- @field thm_sort string[]
--- @field thm_list string[]
--- @field thm_wall string[]

--- Initialize GlobalControl instance
--- @return GlobalControl
function GlobalControl.new()
  -- Global environment variables
  local home = os.getenv('HOME')
  local xdg_config = os.getenv('XDG_CONFIG_HOME')

  self = setmetatable({
    conf_dir = xdg_config or (home .. '/.config'),
    theme_conf_dir = (xdg_config or (home .. '/.config')) .. '/theme',
    cache_dir = home .. '/.cache/theme',
    thmb_dir = home .. '/.cache/theme/thumbs',
    dcol_dir = home .. '/.cache/theme/dcols',
    hash_mech = 'sha1sum',
    hypr_border = 0,
    hypr_width = 0,
    theme = {},
    enable_wall_dcol = 0,
  }, GlobalControl)

  self:initialize()

  return self
end

--- Get hash map from wallpaper sources
--- @param wall_sources string[]
--- @param skip_strays? boolean
--- @param verbose_map? boolean
--- @return HashMapResult|nil
function GlobalControl:get_hash_map(wall_sources, skip_strays, verbose_map)
  local wall_hash = {}
  local wall_list = {}

  for _, wall_source in ipairs(wall_sources or {}) do
    if wall_source and wall_source ~= '' then
      if wall_source ~= '--skipstrays' and wall_source ~= '--verbose' then
        local find_pattern = string.format(
          '-type f \\( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \\) -exec %s {} + | sort -k2',
          self.hash_mech
        )

        local hash_files = utils.find_files(wall_source, find_pattern)
        local hash_map = table.concat(hash_files, '\n')

        if #hash_files == 0 or hash_map == '' then
          print(string.format('WARNING: No image found in "%s"', wall_source))
        else
          for line in hash_map:gmatch('[^\r\n]+') do
            local hash, image = line:match('^(%S+)%s+(.+)$')
            if hash and image then
              table.insert(wall_hash, hash)
              table.insert(wall_list, image)
            end
          end
        end
      end
    end
  end

  if #wall_list == 0 then
    if skip_strays then
      return nil
    else
      print('ERROR: No image found in any source')
      os.exit(1)
    end
  end

  if verbose_map then
    print('// Hash Map //')
    for i, hash in ipairs(wall_hash) do
      print(string.format(':: wall_hash[%d]="%s" :: wall_list[%d]="%s"', i, hash, i, wall_list[i]))
    end
  end

  return { wall_hash = wall_hash, wall_list = wall_list }
end

--- Get available themes
--- @param verbose? boolean
--- @return ThemeResult
function GlobalControl:get_themes(verbose)
  local thm_sort_s = {}
  local thm_list_s = {}
  local thm_wall_s = {}

  -- Find theme directories
  local theme_dirs = utils.find_files(self.theme_conf_dir .. '/themes', '-mindepth 1 -maxdepth 1 -type d')

  for _, thm_dir in ipairs(theme_dirs) do
    if thm_dir and thm_dir ~= '' then
      local wall_set_path = thm_dir .. '/wall.set'
      local wall_set_target, exit_code =
        utils.execute_command(string.format('readlink "%s" 2>/dev/null', wall_set_path))
      wall_set_target = wall_set_target:gsub('\n', '')

      -- Check if wall.set link is valid
      if exit_code ~= 0 or not utils.file_exists(wall_set_target) then
        local hash_result = self:get_hash_map({ thm_dir }, true)
        if hash_result and #hash_result.wall_list > 0 then
          print(string.format('fixing link :: %s/wall.set', thm_dir))
          local ln_cmd = string.format('ln -fs "%s" "%s"', hash_result.wall_list[1], wall_set_path)
          utils.execute_command(ln_cmd)
          wall_set_target = hash_result.wall_list[1]
        else
          goto continue
        end
      end

      -- Read sort order
      local sort_file = thm_dir .. '/.sort'
      local sort_order = '0'
      if utils.file_exists(sort_file) then
        local sort_lines = utils.read_file_lines(sort_file)
        if #sort_lines > 0 then
          sort_order = sort_lines[1] or '0'
        end
      end

      table.insert(thm_sort_s, sort_order)
      table.insert(thm_list_s, thm_dir:match('([^/]+)$') or '')
      table.insert(thm_wall_s, wall_set_target)

      ::continue::
    end
  end

  -- Sort themes
  local combined = {}
  for i = 1, #thm_sort_s do
    table.insert(combined, {
      sort = tonumber(thm_sort_s[i], 10) or 0,
      theme = thm_list_s[i],
      wall = thm_wall_s[i],
    })
  end

  table.sort(combined, function(a, b)
    if a.sort == b.sort then
      return a.theme < b.theme
    end
    return a.sort < b.sort
  end)

  local thm_sort = {}
  local thm_list = {}
  local thm_wall = {}

  for _, item in ipairs(combined) do
    table.insert(thm_sort, tostring(item.sort))
    table.insert(thm_list, item.theme)
    table.insert(thm_wall, item.wall)
  end

  if verbose then
    print('// Theme Control //')
    for i, theme in ipairs(thm_list) do
      print(
        string.format(
          ':: thm_sort[%d]="%s" :: thm_list[%d]="%s" :: thm_wall[%d]="%s"',
          i,
          thm_sort[i],
          i,
          theme,
          i,
          thm_wall[i]
        )
      )
    end
  end

  return { thm_sort = thm_sort, thm_list = thm_list, thm_wall = thm_wall }
end

--- Load configuration from theme.conf and set environment variables
function GlobalControl:load_config()
  local config_file = self.theme_conf_dir .. '/theme.conf'
  if utils.file_exists(config_file) then
    local config_lines = utils.read_file_lines(config_file)
    for _, line in ipairs(config_lines) do
      -- Skip comments and empty lines
      if not line:match('^%s*#') and not line:match('^%s*$') then
        local key, value = line:match('^([^=]+)=(.*)$')
        if key and value then
          -- Remove quotes if present
          value = value:gsub('^"(.*)"$', '%1')

          self.theme[key] = value

          -- Handle specific configuration values for internal use
          if key == 'enableWallDcol' then
            local num = tonumber(value, 10)
            if num and num >= 0 and num <= 3 then
              self.enable_wall_dcol = num
            end
          elseif key == 'theme' then
            self.theme_theme = value
          end
        end
      end
    end
  end
end

--- Initialize Hyprland variables
function GlobalControl:init_hypr_vars()
  local hyprland_sig = os.getenv('HYPRLAND_INSTANCE_SIGNATURE')
  if not hyprland_sig then
    return
  end

  -- Check if required commands exist
  if not utils.command_exists('hyprctl') or not utils.command_exists('jq') then
    print('Error: hyprctl or jq not found')
    return
  end

  -- Get border rounding
  local border_cmd = "hyprctl -j getoption decoration:rounding 2>&1 | jq -e '.int'"
  local border_result, border_exit = utils.execute_command(border_cmd)
  if border_exit == 0 then
    local border = tonumber(border_result:gsub('\n', ''), 10)
    if border then
      self.hypr_border = border
    end
  end

  -- Get border width
  local width_cmd = "hyprctl -j getoption general:border_size 2>&1 | jq -e '.int'"
  local width_result, width_exit = utils.execute_command(width_cmd)
  if width_exit == 0 then
    local width = tonumber(width_result:gsub('\n', ''), 10)
    if width then
      self.hypr_width = width
    end
  end
end

--- Check if package is installed
--- @param pkg_name string
--- @return boolean
function GlobalControl:pkg_installed(pkg_name)
  -- Check with pacman
  local pacman_cmd = string.format('pacman -Qi "%s" 2>/dev/null', pkg_name)
  local _, pacman_exit = utils.execute_command(pacman_cmd)
  if pacman_exit == 0 then
    return true
  end

  -- Check flatpak
  local flatpak_check, _ = utils.execute_command('pacman -Qi "flatpak" 2>/dev/null')
  if utils.is_valid_content(flatpak_check) then
    local flatpak_cmd = string.format('flatpak info "%s" 2>/dev/null', pkg_name)
    local _, flatpak_exit = utils.execute_command(flatpak_cmd)
    if flatpak_exit == 0 then
      return true
    end
  end

  -- Check if command exists
  return utils.command_exists(pkg_name)
end

--- Get AUR helper
--- @return string|nil
function GlobalControl:get_aur_helper()
  if self:pkg_installed('yay') then
    return 'yay'
  elseif self:pkg_installed('paru') then
    return 'paru'
  end
  return nil
end

--- Set configuration value
--- @param var_name string
--- @param var_data string
function GlobalControl:set_conf(var_name, var_data)
  local config_file = self.theme_conf_dir .. '/theme.conf'

  -- Ensure file exists
  local touch_cmd = string.format('touch "%s"', config_file)
  utils.execute_command(touch_cmd)

  -- Check if variable already exists
  local grep_cmd = string.format('grep -c "^%s=" "%s" 2>/dev/null || echo 0', var_name, config_file)
  local count_str, _ = utils.execute_command(grep_cmd)
  local count = tonumber(count_str:gsub('\n', ''), 10) or 0

  if count == 1 then
    -- Update existing variable
    local sed_cmd = string.format('sed -i "/^%s=/c%s=\\"%s\\"" "%s"', var_name, var_name, var_data, config_file)
    utils.execute_command(sed_cmd)
  else
    -- Add new variable
    utils.append_to_file(config_file, string.format('%s="%s"', var_name, var_data))
  end
end

--- Get hash of image file
--- @param hash_image string
--- @return string|nil
function GlobalControl:set_hash(hash_image)
  local hash_cmd = string.format('%s "%s" 2>/dev/null | awk \'{print $1}\'', self.hash_mech, hash_image)
  local result, exit_code = utils.execute_command(hash_cmd)
  return exit_code == 0 and result:gsub('\n', '') or nil
end

--- Initialize the GlobalControl instance
function GlobalControl:initialize()
  -- Load configuration
  self:load_config()

  -- Validate enable_wall_dcol
  if not utils.check_range(self.enable_wall_dcol, 0, 3, 'enable_wall_dcol') then
    self.enable_wall_dcol = 0
  end

  -- Set theme if not valid
  if not self.theme_theme or not utils.file_exists(self.theme_conf_dir .. '/themes/' .. self.theme_theme) then
    local themes = self:get_themes()
    if #themes.thm_list > 0 then
      self.theme_theme = themes.thm_list[1]
    end
  end

  -- Set derived paths
  if self.theme_theme then
    self.theme_theme_dir = self.theme_conf_dir .. '/themes/' .. self.theme_theme
  end
  self.wallbash_dir = self.theme_conf_dir .. '/wallbash'

  -- Initialize Hyprland variables
  self:init_hypr_vars()
end

-- Module interface
local M = {
  config = GlobalControl.new(),
}

return M
