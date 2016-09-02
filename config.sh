#!/bin/bash

CONF_FS=":"
#
CONF_KEY_DEBUG="debug"
CONF_KEY_VERBOSE="verbose"
CONF_KEY_COPY="copymode"
CONF_KEY_LINK="linkmode"
#
CONF_KEY_FSRC="srcfile"
CONF_KEY_FDST="dstfile"
CONF_KEY_DROOT="dirroot"
CONF_KEY_DGROUP="dirgroup"
CONF_KEY_DARCH="dirarchive"
#
CONF_KEY_SCOPY="sync_copy"
CONF_KEY_SLINK="sync_link"
CONF_KEY_SGROUP="sync_group"

CONFIG=(
  "${CONF_KEY_FSRC}${CONF_FS}"
  "${CONF_KEY_FDST}${CONF_FS}"
  "${CONF_KEY_DROOT}${CONF_FS}"
  "${CONF_KEY_DGROUP}${CONF_FS}"
)


E_KEY=80

config_validate_key()
{
  exit 0
}

config_print()
{
    echo "Config: Print: Active"

    local i=0
    for entry in "${CONFIG[@]}" ; do
        local key=${entry%%:*}
        local value=${entry#*:}
        printf "\t[$i] Key: [$key] Value: [$value]\n"
        (( i++ ))
    done
}

config_get()
{

    local get_key="$1"
    local found=

    for entry in "${CONFIG[@]}" ; do
        local key=${entry%%:*}
        local value=${entry#*:}
        if [ $key = $get_key ]; then
            found="$value"
            break
        fi
    done

    echo "$found"
}

config_set()
{
    local set_key="$1"
    local set_val="$2"

    local i=0
    local found=0
    for entry in "${CONFIG[@]}" ; do
        local key=${entry%%=*}
        local value=${entry#*=}
        if [ "$key" = "$set_key" ]; then
            CONFIG[$i]="${key}${CONF_FS}${set_val}"
            found=1
            break
        fi
        (( i++ ))
    done

    if [ $found -eq 0 ]; then
        config_validate_key "$set_key"
        local is_valid_key=$?
        if [ $is_valid_key -gt 0 ]; then
            echo "Error: invalid key [${set_key}]"
            exit $E_KEY
        fi
        CONFIG=( "${CONFIG[@]}" "${set_key}${CONF_FS}${set_val}" )
    fi
}


config_parse_file()
{
    local fconf="./.syncconf"

    while read -r line; do
        local key=${line%=*}
        local val=${line#*=}
        case $key in
            "$CONF_KEY_DEBUG" )
                config_set "parm" "$CONF_KEY_DEBUG" "$val"
                ;;
            "$CONF_KEY_VERBOSE" )
                config_set "parm" "$CONF_KEY_VERBOSE" "$val"
                ;;
            "$CONF_KEY_COPY" )
                config_set "parm" "$CONF_KEY_COPY" "$val"
                ;;
            "$CONF_KEY_LINK" )
                config_set "parm" "$CONF_KEY_LINK" "$val"
                ;;
            "$CONF_KEY_DARCH" )
                config_set "parm" "$CONF_KEY_DARCH" "$val"
                ;;
        esac
    done < $fconf
}
