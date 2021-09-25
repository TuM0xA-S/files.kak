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
paste -d '\n' <($lscmd -Ll "$1" | sed "1d") <($lscmd "$1" | grep -o '.$') | while read a && read b; do
    ((counter++))
    output="$a"
    info="$(echo "$output" | grep -Po "(\S+\s+){7}")"
    echo -n "'$counter|$info' " >> "$gutter"
    output="$(echo "$output" | grep -Po "(?<=$info).*")"
    if [ "$b" = "@" ]; then
        output="$output$b"
    fi
    echo "$output"
done

cat "$gutter"
rm -rf "$tmpdir"
