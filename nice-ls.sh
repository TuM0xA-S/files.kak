#! /bin/bash

lscmd="ls -F --group-directories-first --dereference-command-line-symlink-to-dir"
cwd="$1"
show_hidden="$2"
directories_first="$3"

if [ "$show_hidden" = "true" ]; then
    lscmd="$lscmd -A"
fi

if [ "$directories_first" = "true" ]; then
    lscmd="$lscmd --group-directories-first"
fi

paste -d '\n' <($lscmd -L "$1") <($lscmd "$1") | while read a && read b; do
    if [ "$a" = "$b" ]; then
        echo "$a"
    else
        echo "$a"$(echo "$b" | grep -o '.$')
    fi
done
