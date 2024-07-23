local wezterm = require('wezterm')
local colors = require('colors')
local M = {}

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

function M.apply(config)

  config.hide_tab_bar_if_only_one_tab = true
  config.tab_bar_at_bottom = true
  config.use_fancy_tab_bar = false
  config.show_tab_index_in_tab_bar = false

  wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    -- local background = '#0f131a'
    local background = 'rgba(0, 0, 0, 0)'
    -- local background = colors.background
    local inactive = '#636b74'
    local selection = '#152538'
    local foreground = 'white'

    if tab.is_active then
      background = selection
    elseif hover then
      foreground = 'white'
    else
      foreground = inactive
    end

    local title = ' ' .. tab_title(tab) .. ' '

    return {
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = title },
    }
  end)
end

return M
