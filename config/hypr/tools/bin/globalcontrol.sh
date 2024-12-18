#!/usr/bin/env bash


#// hyde envs
export confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
export hydeConfDir="${confDir}/hyde"
export cacheDir="$HOME/.cache/hyde"
export thmbDir="${cacheDir}/thumbs"
export dcolDir="${cacheDir}/dcols"
export hashMech="sha1sum"


get_hashmap()
{
    unset wallHash
    unset wallList
    unset skipStrays
    unset verboseMap

    for wallSource in "$@"; do
        [ -z "${wallSource}" ] && continue
        [ "${wallSource}" == "--skipstrays" ] && skipStrays=1 && continue
        [ "${wallSource}" == "--verbose" ] && verboseMap=1 && continue

        hashMap=$(find "${wallSource}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec "${hashMech}" {} + | sort -k2)
        if [ -z "${hashMap}" ] ; then
            echo "WARNING: No image found in \"${wallSource}\""
            continue
        fi

        while read -r hash image ; do
            wallHash+=("${hash}")
            wallList+=("${image}")
        done <<< "${hashMap}"
    done

    if [ -z "${#wallList[@]}" ] || [[ "${#wallList[@]}" -eq 0 ]] ; then
        if [[ "${skipStrays}" -eq 1 ]] ; then
            return 1
        else
            echo "ERROR: No image found in any source"
            exit 1
        fi
    fi

    if [[ "${verboseMap}" -eq 1 ]] ; then
        echo "// Hash Map //"
        for indx in "${!wallHash[@]}" ; do
            echo ":: \${wallHash[${indx}]}=\"${wallHash[indx]}\" :: \${wallList[${indx}]}=\"${wallList[indx]}\""
        done
    fi
}

get_themes()
{
    unset thmSortS
    unset thmListS
    unset thmWallS
    unset thmSort
    unset thmList
    unset thmWall

    while read thmDir ; do
        if [ ! -e "$(readlink "${thmDir}/wall.set")" ] ; then
            get_hashmap "${thmDir}" --skipstrays || continue
            echo "fixig link :: ${thmDir}/wall.set"
            ln -fs "${wallList[0]}" "${thmDir}/wall.set"
        fi
        [ -f "${thmDir}/.sort" ] && thmSortS+=("$(head -1 "${thmDir}/.sort")") || thmSortS+=("0")
        thmListS+=("$(basename "${thmDir}")")
        thmWallS+=("$(readlink "${thmDir}/wall.set")")
    done < <(find "${hydeConfDir}/themes" -mindepth 1 -maxdepth 1 -type d)

    while IFS='|' read -r sort theme wall ; do
        thmSort+=("${sort}")
        thmList+=("${theme}")
        thmWall+=("${wall}")
    done < <(parallel --link echo "{1}\|{2}\|{3}" ::: "${thmSortS[@]}" ::: "${thmListS[@]}" ::: "${thmWallS[@]}" | sort -n -k 1 -k 2)

    if [ "${1}" == "--verbose" ] ; then
        echo "// Theme Control //"
        for indx in "${!thmList[@]}" ; do
            echo -e ":: \${thmSort[${indx}]}=\"${thmSort[indx]}\" :: \${thmList[${indx}]}=\"${thmList[indx]}\" :: \${thmWall[${indx}]}=\"${thmWall[indx]}\""
        done
    fi
}

[ -f "${hydeConfDir}/hyde.conf" ] && source "${hydeConfDir}/hyde.conf"

case "${enableWallDcol}" in
    0|1|2|3) ;;
    *) enableWallDcol=0 ;;
esac

if [ -z "${hydeTheme}" ] || [ ! -d "${hydeConfDir}/themes/${hydeTheme}" ] ; then
    get_themes
    hydeTheme="${thmList[0]}"
fi

export hydeTheme
export hydeThemeDir="${hydeConfDir}/themes/${hydeTheme}"
export wallbashDir="${hydeConfDir}/wallbash"
export enableWallDcol


#// hypr vars

export hypr_border=0
export hypr_width=0

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE}" ]; then
    # Check if required commands exist
    if command -v hyprctl && command -v jq; then
        # Set fallback values in case commands fail
        export hypr_border=0
        export hypr_width=0

        # Get border rounding with error handling
        if border=$(hyprctl -j getoption decoration:rounding 2>&1 | jq -e '.int'); then
            export hypr_border="$border"
        fi

        # Get border width with error handling
        if width=$(hyprctl -j getoption general:border_size 2>&1 | jq -e '.int'); then
            export hypr_width="$width"
        fi
    else
        echo "Error: hyprctl or jq not found" >&2
    fi
fi


#// extra fns

pkg_installed()
{
    local pkgIn=$1
    if pacman -Qi "${pkgIn}" &> /dev/null ; then
        return 0
    elif pacman -Qi "flatpak" &> /dev/null && flatpak info "${pkgIn}" &> /dev/null ; then
        return 0
    elif command -v "${pkgIn}" &> /dev/null ; then
        return 0
    else
        return 1
    fi
}

get_aurhlpr()
{
    if pkg_installed yay
    then
        aurhlpr="yay"
    elif pkg_installed paru
    then
        aurhlpr="paru"
    fi
}

set_conf()
{
    local varName="${1}"
    local varData="${2}"
    touch "${hydeConfDir}/hyde.conf"

    if [ $(grep -c "^${varName}=" "${hydeConfDir}/hyde.conf") -eq 1 ] ; then
        sed -i "/^${varName}=/c${varName}=\"${varData}\"" "${hydeConfDir}/hyde.conf"
    else
        echo "${varName}=\"${varData}\"" >> "${hydeConfDir}/hyde.conf"
    fi
}

set_hash()
{
    local hashImage="${1}"
    "${hashMech}" "${hashImage}" | awk '{print $1}'
}

