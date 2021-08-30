#! /bin/bash

lscmd="ls -F --dereference-command-line-symlink-to-dir"
cwd="$1"
show_hidden="$2"
directories_first="$3"
sort_by="$4"
reverse="$5"
long_format="$6"

if [ "$show_hidden" = "true" ]; then
    lscmd="$lscmd -A"
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

lscmdhelper="$lscmd"
if [ "$long_format" = "true" ]; then
    lscmd="$lscmd -l"
    sedcmd="1d"
fi

paste -d '\n' <($lscmd -L "$1" | sed "$sedcmd") <($lscmdhelper "$1" | grep -o '.$') | while read a && read b; do
    output="$a"
    if [ "$b" = "@" ]; then
        output="$output$b"
    fi
    echo "$output"
done
