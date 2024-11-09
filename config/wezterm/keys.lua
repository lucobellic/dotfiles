local wezterm = require('wezterm')

local M = {}

-- Integration with smart-splits.nvim

-- if you *ARE* lazy-loading smart-splits.nvim (not recommended)
-- you have to use this instead, but note that this will not work
-- in all cases (e.g. over an SSH connection). Also note that
-- `pane:get_foreground_process_name()` can have high and highly variable
-- latency, so the other implementation of `is_vim()` will be more
-- performant as well.
local function is_vim_lazy(pane)
  -- This gsub is equivalent to POSIX basename(3)
  -- Given "/foo/bar" returns "bar"
  -- Given "c:\\foo\\bar" returns "bar"
  local process_name = string.gsub(pane:get_foreground_process_name(), '(.*[/\\])(.*)', '%2')
  return process_name == 'neovim' or process_name == 'nvim' or process_name == 'vim'
end

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == 'true'
    or pane:get_user_vars().WEZTERM_PROG == 'nvim'
    or pane:get_user_vars().WEZTERM_PROG == 'neovim'
    or is_vim_lazy(pane)
end

local direction_keys = {
  LeftArrow = 'Left',
  DownArrow = 'Down',
  UpArrow = 'Up',
  RightArrow = 'Right',
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({ SendKey = { key = key, mods = 'CTRL' } }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

function M.apply(config)
  config.keys = {
    { key = '>', mods = 'CTRL|SHIFT', action = wezterm.action.MoveTabRelative(-1) },
    { key = '<', mods = 'CTRL|SHIFT', action = wezterm.action.MoveTabRelative(1) },
    { key = 'K', mods = 'CTRL', action = wezterm.action.PaneSelect },
    { key = 'H', mods = 'CTRL', action = wezterm.action.ActivatePaneDirection('Left') },
    { key = 'J', mods = 'CTRL', action = wezterm.action.ActivatePaneDirection('Down') },
    { key = 'K', mods = 'CTRL', action = wezterm.action.ActivatePaneDirection('Up') },
    { key = 'L', mods = 'CTRL', action = wezterm.action.ActivatePaneDirection('Right') },
    { key = 'M', mods = 'CTRL', action = wezterm.action.PaneSelect },
    split_nav('move', 'h'),
    split_nav('move', 'j'),
    split_nav('move', 'k'),
    split_nav('move', 'l'),
    split_nav('resize', 'LeftArrow'),
    split_nav('resize', 'DownArrow'),
    split_nav('resize', 'UpArrow'),
    split_nav('resize', 'RightArrow'),
    { key = 'V', mods = 'CTRL', action = wezterm.action.PasteFrom('Clipboard') },
    { key = 'S', mods = 'CTRL', action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = 'B', mods = 'CTRL', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = 'Q', mods = 'CTRL', action = wezterm.action.CloseCurrentPane({ confirm = false }) },
    { key = 'F11', mods = 'CTRL|SHIFT', action = wezterm.action.ToggleFullScreen },
  }
end

return M
