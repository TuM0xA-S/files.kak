#! /bin/bash

lscmd="ls -hGF --dereference-command-line-symlink-to-dir"
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

case "$sort_by" in none|size|time|version|extension)
    lscmd="$lscmd --sort=$sort_by"
esac

if [ "$reverse" = "true" ]; then
    lscmd="$lscmd -r"
fi

counter=0
gutter="$(mktemp)"
paste -d '\n' <($lscmd -L "$1") <($lscmd "$1" | grep -o '.$') <($lscmd -Ll "$1" | sed "1d" | grep -Po "(\S+\s+){7}") | while read a && read b && read c; do
    output="$a"
    if [ "$b" = "@" ]; then
        output="$output$b"
    fi
    echo "$output"

    ((counter++))
    info="$c"
    echo -n "'$counter|$info ' " >> "$gutter"
done

cat "$gutter"
rm -rf "$tmpdir"
