#! /bin/bash

lscmd="ls -F --dereference-command-line-symlink-to-dir"
cwd="$1"
show_hidden="$2"
directories_first="$3"
sort_by="$4"
reverse="$5"

if [ "$show_hidden" = "true" ]; then
    lscmd="$lscmd -A"
fi

if [ "$directories_first" = "true" ]; then
    lscmd="$lscmd --group-directories-first"
fi

if [ "$directories_first" = "true" ]; then
    lscmd="$lscmd --group-directories-first"
fi

case "$sort_by" in none|size|time|version|extension)
    lscmd="$lscmd --sort=$sort_by"
esac

if [ "$reverse" = "true" ]; then
    lscmd="$lscmd -r"
fi

paste -d '\n' <($lscmd -L "$1") <($lscmd "$1") | while read a && read b; do
    if [ "$a" = "$b" ]; then
        echo "$a"
    else
        echo "$a"$(echo "$b" | grep -o '.$')
    fi
done
