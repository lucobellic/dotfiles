#!/usr/bin/env lua

--- @class GlobalControl
--- @field conf_dir string
--- @field hyde_conf_dir string
--- @field cache_dir string
--- @field thmb_dir string
--- @field dcol_dir string
--- @field hash_mech string
--- @field hyde_theme string
--- @field hyde_theme_dir string
--- @field wallbash_dir string
--- @field enable_wall_dcol number
--- @field hypr_border number
--- @field hypr_width number
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
  -- Hyde environment variables
  local home = os.getenv('HOME') or ''
  local xdg_config = os.getenv('XDG_CONFIG_HOME')

  self = setmetatable({
    conf_dir = xdg_config or (home .. '/.config'),
    hyde_conf_dir = (xdg_config or (home .. '/.config')) .. '/hyde',
    cache_dir = home .. '/.cache/hyde',
    thmb_dir = home .. '/.cache/hyde/thumbs',
    dcol_dir = home .. '/.cache/hyde/dcols',
    hash_mech = 'sha1sum',
    hypr_border = 0,
    hypr_width = 0,
    enable_wall_dcol = 0,
  }, GlobalControl)

  self:initialize()

  return self
end

--- Execute shell command and return output
--- @param cmd string
--- @return string output
--- @return number exitCode
function GlobalControl:execute_command(cmd)
  local handle = io.popen(cmd .. ' 2>&1')
  if not handle then
    return '', 1
  end
  local result = handle:read('*a')
  local _, _, code = handle:close()
  return result or '', code or 1
end

--- Check if file exists
--- @param path string
--- @return boolean
function GlobalControl:file_exists(path)
  local file = io.open(path, 'r')
  if file then
    file:close()
    return true
  end
  return false
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
        local find_cmd = string.format(
          'find "%s" -type f \\( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \\) -exec %s {} + | sort -k2',
          wall_source,
          self.hash_mech
        )

        local hash_map, exit_code = self:execute_command(find_cmd)

        if exit_code ~= 0 or hash_map == '' then
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
  local find_cmd = string.format('find "%s/themes" -mindepth 1 -maxdepth 1 -type d', self.hyde_conf_dir)
  local theme_dirs, _ = self:execute_command(find_cmd)

  for thm_dir in theme_dirs:gmatch('[^\r\n]+') do
    if thm_dir and thm_dir ~= '' then
      local wall_set_path = thm_dir .. '/wall.set'
      local readlink_cmd = string.format('readlink "%s" 2>/dev/null', wall_set_path)
      local wall_set_target, exit_code = self:execute_command(readlink_cmd)
      wall_set_target = wall_set_target:gsub('\n', '')

      -- Check if wall.set link is valid
      if exit_code ~= 0 or not self:file_exists(wall_set_target) then
        local hash_result = self:get_hash_map({ thm_dir }, true)
        if hash_result and #hash_result.wall_list > 0 then
          print(string.format('fixing link :: %s/wall.set', thm_dir))
          local ln_cmd = string.format('ln -fs "%s" "%s"', hash_result.wall_list[1], wall_set_path)
          self:execute_command(ln_cmd)
          wall_set_target = hash_result.wall_list[1]
        else
          goto continue
        end
      end

      -- Read sort order
      local sort_file = thm_dir .. '/.sort'
      local sort_order = '0'
      if self:file_exists(sort_file) then
        local file = io.open(sort_file, 'r')
        if file then
          sort_order = file:read('*line') or '0'
          file:close()
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

--- Load configuration from hyde.conf
function GlobalControl:load_config()
  local config_file = self.hyde_conf_dir .. '/hyde.conf'
  if self:file_exists(config_file) then
    local file = io.open(config_file, 'r')
    if file then
      for line in file:lines() do
        local key, value = line:match('^([^=]+)=(.*)$')
        if key and value then
          -- Remove quotes if present
          value = value:gsub('^"(.*)"$', '%1')
          if key == 'enableWallDcol' then
            local num = tonumber(value, 10)
            if num and num >= 0 and num <= 3 then
              self.enable_wall_dcol = num
            end
          elseif key == 'hydeTheme' then
            self.hyde_theme = value
          end
        end
      end
      file:close()
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
  local hyprctl_check = self:execute_command('command -v hyprctl')
  local jq_check = self:execute_command('command -v jq')

  if hyprctl_check == '' or jq_check == '' then
    print('Error: hyprctl or jq not found')
    return
  end

  -- Get border rounding
  local border_cmd = "hyprctl -j getoption decoration:rounding 2>&1 | jq -e '.int'"
  local border_result, border_exit = self:execute_command(border_cmd)
  if border_exit == 0 then
    local border = tonumber(border_result:gsub('\n', ''), 10)
    if border then
      self.hypr_border = border
    end
  end

  -- Get border width
  local width_cmd = "hyprctl -j getoption general:border_size 2>&1 | jq -e '.int'"
  local width_result, width_exit = self:execute_command(width_cmd)
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
  local _, pacman_exit = self:execute_command(pacman_cmd)
  if pacman_exit == 0 then
    return true
  end

  -- Check flatpak
  local flatpak_check = self:execute_command('pacman -Qi "flatpak" 2>/dev/null')
  if flatpak_check ~= '' then
    local flatpak_cmd = string.format('flatpak info "%s" 2>/dev/null', pkg_name)
    local _, flatpak_exit = self:execute_command(flatpak_cmd)
    if flatpak_exit == 0 then
      return true
    end
  end

  -- Check if command exists
  local command_cmd = string.format('command -v "%s" 2>/dev/null', pkg_name)
  local _, command_exit = self:execute_command(command_cmd)
  return command_exit == 0
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
  local config_file = self.hyde_conf_dir .. '/hyde.conf'

  -- Ensure file exists
  local touch_cmd = string.format('touch "%s"', config_file)
  self:execute_command(touch_cmd)

  -- Check if variable already exists
  local grep_cmd = string.format('grep -c "^%s=" "%s" 2>/dev/null || echo 0', var_name, config_file)
  local count, _ = self:execute_command(grep_cmd)
  count = tonumber(count:gsub('\n', ''), 10) or 0

  if count == 1 then
    -- Update existing variable
    local sed_cmd = string.format('sed -i "/^%s=/c%s=\\"%s\\"" "%s"', var_name, var_name, var_data, config_file)
    self:execute_command(sed_cmd)
  else
    -- Add new variable
    local file = io.open(config_file, 'a')
    if file then
      file:write(string.format('%s="%s"\n', var_name, var_data))
      file:close()
    end
  end
end

--- Get hash of image file
--- @param hash_image string
--- @return string|nil
function GlobalControl:set_hash(hash_image)
  local hash_cmd = string.format('%s "%s" 2>/dev/null | awk \'{print $1}\'', self.hash_mech, hash_image)
  local result, exit_code = self:execute_command(hash_cmd)
  return exit_code == 0 and result:gsub('\n', '')
end

--- Initialize the GlobalControl instance
function GlobalControl:initialize()
  -- Load configuration
  self:load_config()

  -- Validate enable_wall_dcol
  if not (self.enable_wall_dcol >= 0 and self.enable_wall_dcol <= 3) then
    self.enable_wall_dcol = 0
  end

  -- Set theme if not valid
  if not self.hyde_theme or not self:file_exists(self.hyde_conf_dir .. '/themes/' .. self.hyde_theme) then
    local themes = self:get_themes()
    if #themes.thm_list > 0 then
      self.hyde_theme = themes.thm_list[1]
    end
  end

  -- Set derived paths
  if self.hyde_theme then
    self.hyde_theme_dir = self.hyde_conf_dir .. '/themes/' .. self.hyde_theme
  end
  self.wallbash_dir = self.hyde_conf_dir .. '/wallbash'

  -- Initialize Hyprland variables
  self:init_hypr_vars()
end

-- Module interface
local M = {
  config = GlobalControl.new(),
}

function M.export_vars()
  local control = M.config

  os.execute("export conf_dir='" .. control.conf_dir .. "'")
  os.execute("export hyde_conf_dir='" .. control.hyde_conf_dir .. "'")
  os.execute("export cache_dir='" .. control.cache_dir .. "'")
  os.execute("export thmb_dir='" .. control.thmb_dir .. "'")
  os.execute("export dcol_dir='" .. control.dcol_dir .. "'")
  os.execute("export hash_mech='" .. control.hash_mech .. "'")

  if control.hyde_theme then
    os.execute("export hyde_theme='" .. control.hyde_theme .. "'")
    os.execute("export hyde_theme_dir='" .. control.hyde_theme_dir .. "'")
  end

  if control.wallbash_dir then
    os.execute("export wallbash_dir='" .. control.wallbash_dir .. "'")
  end

  os.execute("export enable_wall_dcol='" .. tostring(control.enable_wall_dcol) .. "'")
  os.execute("export hypr_border='" .. tostring(control.hypr_border) .. "'")
  os.execute("export hypr_width='" .. tostring(control.hypr_width) .. "'")
end

-- If running as script, initialize and export variables
if arg and arg[0]:match('globalcontrol%.lua$') then
  M.export_vars()
end

return M
