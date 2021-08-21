#! /bin/bash

lscmd="ls -AF --dereference-command-line-symlink-to-dir"
paste -d '\n' <($lscmd -L $1) <($lscmd $1) | while read a && read b; do
    if [ "$a" = "$b" ]; then
        echo "$a"
    else
        echo "$a"$(echo "$b" | grep -o '.$')
    fi
done
