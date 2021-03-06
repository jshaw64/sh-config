#!/bin/bash

CONF_FS=":"

CONFIG=()

E_KEY=80

config_validate_key()
{
  return 0
}

config_print()
{
  local i=0
  for entry in "${CONFIG[@]}" ; do
      local key=${entry%%$CONF_FS*}
      local value=${entry#*$CONF_FS}
      printf "\t[$i] Key: [$key] Value: [$value]\n"
      (( i++ ))
  done
}

config_get()
{
  local get_key="$1"
  local found=

  for entry in "${CONFIG[@]}" ; do
    local key=${entry%%$CONF_FS*}
    local value=${entry#*$CONF_FS}
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
    local key=${entry%%$CONF_FS*}
    local value=${entry#*$CONF_FS}
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

config_parse_file_block()
{
  local block_begin="$1"
  local block_end="$2"
  local block_num=$3
  local conf_file="$4"

  local block_contents_raw=$(
    awk '
      /'${block_begin}'/ {
        v = $0
        while(!/'${block_end}'/) { 
          if(!getline) 
            exit
          v = v ORS $0
        }
        if(++nr == n) 
          print v
    }' n=${block_num} < "${conf_file}"
  )

  local block_contents_parsed=
  while read -r line; do
    if [ "$line" = "$block_begin" -o "$line" = "$block_end" ]; then
      continue
    fi
    local key=${line%=*}
    local val=${line#*=}
    block_contents_parsed+="${val}${CONF_FS}"
  done <<< "$block_contents_raw"

  # Remove trailing CONF_FS
  block_contents_parsed="${block_contents_parsed::${#block_contents_parsed}-1}"

  echo "$block_contents_parsed"
}

config_parse_file()
{
  local block_begin="$1"
  local block_end="$2"
  local conf_file="$3"
  local curr_block=1

  while :; do
    local block_contents=$(config_parse_file_block "$block_begin" "$block_end" $curr_block "$conf_file")
    if [ -z "$block_contents" ]; then
      break
    fi
    config_set $curr_block "$block_contents"
    (( curr_block++ ))
  done
}
