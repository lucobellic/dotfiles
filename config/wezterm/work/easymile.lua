local wezterm = require('wezterm')
local M = {}

function M.apply(config)
  -- Use the defaults as a base
  config.hyperlink_rules = wezterm.default_hyperlink_rules()

  config.ssh_domains = {
    {
      name = 'rapidash',
      remote_address = 'localhost',
      username = 'rosuser',
      -- If true, connect to this domain automatically at startup
      -- connect_automatically = true,

      -- Specify an alternative read timeout
      -- timeout = 60,

      -- The path to the wezterm binary on the remote host.
      -- Primarily useful if it isn't installed in the $PATH
      -- that is configure for ssh.
      -- remote_wezterm_path = "/home/rosuser/bin/wezterm"
    },
  }

  -- make task numbers clickable
  -- the first matched regex group is captured in $1.
  -- RD-22594
  table.insert(config.hyperlink_rules, {
    regex = [[(RD-\d+)]],
    format = 'https://easymile.atlassian.net/browse/$1',
  })

  config.ssh_domains = {
    {
      name = 'mitac',
      remote_address = '10.240.8.252',
      username = 'rdos',
    },
  }

  return config
end

return M
