local M = {}

M.foreground = '#bfbdb6'
M.background = '#0f131a'

function M.apply(config)
  -- local colors, metadata = wezterm.color.load_scheme("~/.config/wezterm/ayugloom.toml")
  config.color_scheme = 'Ayu Gloom'

  local foreground = M.foreground
  local tab_bar_background = 'rgba(0, 0, 0, 0)'
  local inactive = '#636b74'
  local selection = '#152538'
  config.command_palette_fg_color = foreground
  config.command_palette_bg_color = M.background

  config.colors = {
    -- foreground = foreground,
    -- background = background,
    tab_bar = {
      -- The color of the strip that goes along the top of the window
      -- (does not apply when fancy tab bar is in use)
      background = tab_bar_background,

      -- The active tab is the one that has focus in the window
      active_tab = {
        -- The color of the tab_bar_background area for the tab
        bg_color = selection,
        -- The color of the text for the tab
        fg_color = 'white',

        -- Specify whether you want "Half", "Normal" or "Bold" intensity for the
        -- label shown for this tab.
        -- The default is "Normal"
        intensity = 'Half',

        -- Specify whether you want "None", "Single" or "Double" underline for
        -- label shown for this tab.
        -- The default is "None"
        underline = 'None',

        -- Specify whether you want the text to be italic (true) or not (false)
        -- for this tab.  The default is false.
        italic = false,

        -- Specify whether you want the text to be rendered with strikethrough (true)
        -- or not for this tab.  The default is false.
        strikethrough = false,
      },

      -- Inactive tabs are the tabs that do not have focus
      inactive_tab = {
        bg_color = tab_bar_background,
        fg_color = inactive,

        -- The same options that were listed under the `active_tab` section above
        -- can also be used for `inactive_tab`.
      },

      -- You can configure some alternate styling when the mouse pointer
      -- moves over inactive tabs
      inactive_tab_hover = {
        bg_color = tab_bar_background,
        fg_color = inactive,
        italic = false,

        -- The same options that were listed under the `active_tab` section above
        -- can also be used for `inactive_tab_hover`.
      },

      -- The new tab button that let you create new tabs
      new_tab = {
        bg_color = tab_bar_background,
        fg_color = inactive,

        -- The same options that were listed under the `active_tab` section above
        -- can also be used for `new_tab`.
      },

      -- You can configure some alternate styling when the mouse pointer
      -- moves over the new tab button
      new_tab_hover = {
        bg_color = tab_bar_background,
        fg_color = 'white',
        italic = true,

        -- The same options that were listed under the `active_tab` section above
        -- can also be used for `new_tab_hover`.
      },
    },
  }
end

return M
