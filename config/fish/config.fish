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
