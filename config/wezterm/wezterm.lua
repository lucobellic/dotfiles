-- Pull in the wezterm API
local colors = require('colors')
local keys = require('keys')
local tabbar = require('tabbar')
local wezterm = require('wezterm')
local work = require('work')
-- local mux = wezterm.mux

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

colors.apply(config)
tabbar.apply(config)
keys.apply(config)
work.apply(config)
-- docker.apply(config)

config.window_background_opacity = 0.75
config.text_background_opacity = 0.75

config.font = wezterm.font_with_fallback({
  { family = 'DMMono Nerd Font', weight = 'Medium' },
  { family = 'Liga SFMono Nerd Font', weight = 'Medium' },
  { family = 'Iosevka Custom', weight = 'Medium' },
})

config.font_size = 11.0
-- config.
config.strikethrough_position = '0.5cell'
config.underline_position = '200%'
config.warn_about_missing_glyphs = false
config.force_reverse_video_cursor = false
-- config.cursor_blink_rate = 0

-- config.term = 'wezterm'
config.set_environment_variables = {
  TERM = 'wezterm',
}

config.window_decorations = 'NONE'
config.window_padding = {
  left = '1.0cell',
  right = '0.5cell',
  top = '0.5cell',
  bottom = '0cell',
}

-- Disable ime to fix issue with one shot layer custom key
config.use_ime = false

return config
