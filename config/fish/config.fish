function __zoxide_cd_complete
    set -l query (commandline --current-token)
    if test -n "$query"
        set -l matches (zoxide query --list --score -- inf | sort -rn | string replace -r '^[\s]*[0-9.]+\s+' '')
        for match in $matches
            echo "$match"
        end
    end
end

# Use zoxide query for cd completions
complete -c cd -f -a '(__zoxide_cd_complete)'

# Import graphical environment variables for user systemd
if type -q systemctl
    systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS
end

