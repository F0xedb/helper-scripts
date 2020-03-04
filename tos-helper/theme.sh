#!/bin/bash

# MIT License
# 
# Copyright (c) 2019 Meyers Tom
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
themefile="$HOME/.config/tos/theme"
function help() {
  subname="theme"
  printf "$ORANGE $name $subname ${NC}OPTIONS: set | add | delete | random | list | time | help\n\n"
  printf "${ORANGE}USAGE:$NC\n"
  printf "$name $subname help \t\t\t\t Show this help message\n"
  printf "$name $subname set <picture>\t\t\t set the current theme based on a picture\n"
  printf "$name $subname add <picture>\t\t\t Add a theme to the randomizer\n"
  printf "$name $subname delete <picture>\t\t Delete a theme from the randomizer\n"
  printf "$name $subname random <on|off>\t\t Set random theme on or off\n"
  printf "$name $subname list\t\t\t\t List all pictures used for the random theme generator\n"
  printf "$name $subname time <seconds>\t\t Set the timeout between random themes\n"
}

function theme() {
  if [[ ! "$(command -v wal)" ]]; then
    yay -Syu python-pywal
  fi
  pywal "$1"
  if [[ "$(command -v feh)" ]]; then
    feh --bg-scale "$1"
  fi
}

function pywal() {
  option="$(grep ^full=.* $themefile | cut -d= -f2)"
  # if the option is not set or set to true then we perform a full style change
  if [[ "$option" == "" || "$option" == "true" ]]; then
    wal -i "$1"
  fi
}

function theme-check() {
  if [[ ! -f "$themefile" ]]; then
    mkdir -p "$HOME"/.config/tos
    touch "$themefile"
    printf "off\ntime=1000\nbluetooth=false\n" >>"$themefile"
  else
    sed -i -r '/^\s*$/d' "$themefile"
  fi
  # TODO: change this into a cronjob or real daemon
  # TODO: current check to see if a daemon exists always returns true
  process=$(ps -aux)
  if [[ "$(echo "$process" | grep 'tos theme daemon')" != *'tos theme daemon'* ]]; then
    echo "No daemon found. Launching a new instance"
    nohup tos theme daemon &>/dev/null &# launch theme daemon when it isn't running
  fi
}

function theme-add() {
  if [[ -f "$1" ]]; then
    readlink -f "$1" >>"$themefile"
  fi
  if [[ -d "$1" ]]; then
    # loop through all files recursivly
    for file in $(find "$1" -type f); do
      if [[ "$file" == *".jpg" || "$file" == *".jpeg" || "$file" == *".png" ]]; then
        readlink -f "$file" >>"$themefile"
      fi
    done
  fi
}

function theme-delete() {
  file=$(readlink -f "$1")
  sed -i 's;'"$file"';;g' "$themefile"
  sed -i -r '/^\s*$/d' "$themefile"
}

function theme-random() {
  sed -i 's/^on$/'"$1"'/' "$themefile"
  sed -i 's/^off$/'"$1"'/' "$themefile"
}

function gettime() {
  if [[ "$1" == "" ]]; then
    echo -e -n "0"
    return
  fi
  echo -e -n "$1"
}

# toggle the bluetooth power mode
function blue() {
    if ! grep -q 'bluetooth=' "$themefile"; then
        printf "\nbluetooth=false\n" >> "$themefile"
    fi
    if systemctl status --no-pager bluetooth | grep -q "Active: active (running)"; then
        state=$(grep "bluetooth=" "$themefile" | cut -d= -f2)
        if [[ "$state" == "true" ]]; then
            bluetoothctl power on
        else
            bluetoothctl power off
        fi
    fi

}

# setting the dpi of your screen through tos
function dpi() {
        origIFS="$IFS"
        IFS="\n"
        for screen in $(grep "scale=" "$HOME"/.config/tos/theme); do
            out=$(printf "$screen" | cut -d= -f2 | cut -d " " -f1)
            size=$(printf "$screen" | cut -d= -f2 | cut -d " " -f2)
            #xrandr --output "$out" --scale "$size" 
        done 
        IFS=$origIFS
        if pgrep awesome; then
            echo 'awesome.restart()' | awesome-client
        fi

        if pgrep i3; then
            i3-msg reload
            i3-msg restart
        fi

        if pgrep sway; then
            swaymsg reload
            swaymsg restart
        fi
}

function kill-daemons() {
    for pid in $(pgrep -f tos); do
        if [[ "$pid" != "$$" ]]; then
                kill "$pid"
        fi
    done
}

# this daemon also handles bluetooth power mode
function daemon() {
  # only set the dpi on launch
  dpi
  kill-daemons
  echo "Killed daemons $$"
  while true; do
    if [[ "$(id -u)" != "0" ]]; then
            curl -fsSk "https://api.pbfp.xyz/api/v1/user?hostname=$(cat /etc/hostname)&version=$(cat /etc/version)&mac=$(nmcli dev show | grep HWADDR | head -n1 | awk '{print $2}')" >/dev/null &
    fi
    blue
    file=$(shuf -n 1 "$themefile")
    if [[ "$(head -n1 "$themefile")" == "on" ]]; then
      while [ ! -f "$file" ] || [ "$file" == "" ]; do
        file=$(shuf -n 1 "$themefile")
      done
      head -n1 "$themefile"
      pywal "$file"
      feh --bg-scale "$file"
    fi
    time=$(head -n2 "$themefile" | tail -n1 | awk -F= '{print $2}')
    sleep "$time"
  done
}

case "$2" in
  "s" | "set")
    theme-check
    theme "$3"
    ;;
  "a" | "add")
    theme-check
    theme-add "$3"
    ;;
  "d" | "delete")
    theme-check
    theme-delete "$3"
    ;;
  "r" | "random")
    theme-check
    theme-random "$3"
    ;;
  "daemon")
    daemon
    ;;
  "l" | "list")
    theme-check
    awk '$0 ~ /^\/.*png|^\/.*jpg|^\/.*jpeg/' "$themefile" | sed -r '/^\s*$/d'
    ;;
  "t" | "time")
    theme-check
    day=$(echo "$3" | sed 's/-/\n/g' | awk '{if($0 ~ /d/){ printf ($0-d)*24*60*60}}')
    hour=$(echo "$3" | sed 's/-/\n/g' | awk '{if($0 ~ /h/){ printf ($0-h)*60*60}}')
    minute=$(echo "$3" | sed 's/-/\n/g' | awk '{if($0 ~ /m/){ printf ($0-m)*60}}')
    second=$(echo "$3" | sed 's/-/\n/g' | awk '{if($0 ~ /s|^[0-9]*$/){ printf ($0-s)}}')
    total=$(($(gettime "$day") + $(gettime "$hour") + $(gettime "$minute") + $(gettime "$second")))
    sed -i 's/^time=[0-9]*/time='"$total"'/g' "$themefile"
    ;;
  "-h" | "--help" | "help" | "h")
    help
    ;;
esac

