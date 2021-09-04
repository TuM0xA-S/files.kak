declare-option -hidden str my_plugin_path %sh{ dirname "$kak_source" }

declare-option -hidden str files_browse_buffer 'files-browser'
declare-option -hidden str files_selection_buffer 'files-selection'
declare-option str files_markers "*/=>@|"
declare-option str files_disabled_keys "i I a A r R p P d <a-d> ! <a-!> | <a-|> <gt> <a-gt> <lt> <a-lt>"
declare-option bool files_show_hidden true
declare-option bool files_directories_first true
declare-option bool files_long_format false
declare-option str files_sorting "name"
declare-option bool files_sorting_reverse false
declare-option str files_ls_options "files_show_hidden files_directories_first files_long_format files_sorting files_sorting_reverse"
declare-option str files_options_with_getters "files_show_hidden files_directories_first files_long_format files_cwd"
declare-option str files_togglable_options "files_show_hidden files_directories_first files_long_format"
declare-option str files_cwd
declare-option int files_browse_buffer_counter 0

define-command -hidden files-ls %{
    execute-keys %sh{
        cmd="$kak_opt_my_plugin_path/nice-ls.sh\
        '$kak_opt_files_cwd' '$kak_opt_files_show_hidden' '$kak_opt_files_directories_first' '$kak_opt_files_sorting' '$kak_opt_files_sorting_reverse' '$kak_opt_files_long_format'"
        echo "%%d!$cmd<ret>dgk"
    }
}

define-command files-new-browser -params 0..1 %{
    edit -scratch "*%opt{files_browse_buffer}-%opt{files_browse_buffer_counter}*"
    set buffer filetype %opt{files_browse_buffer}
    set-option -add global files_browse_buffer_counter 1
    files-set-cwd %sh{
        [ -n "$1" ] && echo "$1" || pwd
    }
}

define-command -hidden files-disable-keys %{ evaluate-commands %sh{
    for key in $kak_opt_files_disabled_keys; do
        echo "map buffer normal $key ''"
    done
}}

define-command -hidden files-create-hl %{
    add-highlighter shared/files-filetypes group
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)/@?$' 1:blue
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)\*@?$' 1:green
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)\|@?$' 1:yellow
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)=@?$' 1:magenta
    add-highlighter shared/files-filetypes/ regex '@' 0:cyan
    add-highlighter shared/long-format regex "(?S)^(\S+ +){8}" 0:Default
}

define-command files-redraw-browser %{
    execute-keys ';x_'
    evaluate-commands %sh{
        current_line="$kak_reg_dot"
        echo 'files-ls'
        echo "try %{ execute-keys '/^\Q$current_line\E$<ret>gi' }"
    }
}

define-command -hidden files-generate-ls-option-setters %{ evaluate-commands %sh{
    for opt in $kak_opt_files_ls_options; do
        echo "\
        define-command -params 1 files-set-$opt %{
            set-option buffer $opt %arg{1}
            files-redraw-browser
        }"
    done
}}

define-command -hidden files-generate-ls-option-togglers %{ evaluate-commands %sh{
    for opt in $kak_opt_files_togglable_options; do
        echo "\
        define-command files-toggle-$opt %{ evaluate-commands %sh{
            if [ \"\$kak_opt_$opt\" = true ]; then
                echo files-set-$opt false
            else
                echo files-set-$opt true
            fi
        }}
        "
    done
}}

define-command -hidden files-generate-getters %{ evaluate-commands %sh{
    for opt in $kak_opt_files_options_with_getters; do
        echo "define-command files-get-$opt %{ echo '%opt{$opt}' }"
    done
}}

define-command -params 1 files-set-cwd %{
    set-option buffer files_cwd %arg{1}
    files-ls
}

define-command -hidden files-cd-parent %{ evaluate-commands %sh{
    current_dir="$(basename "$kak_opt_files_cwd")"
    echo "files-set-cwd '$(dirname "$kak_opt_files_cwd")'"
    echo "try %{ execute-keys '/\\\b$current_dir[$kak_opt_files_markers]{,2}<ret>gi' }"
}}

define-command -hidden files-cd %{
    execute-keys ";x_"
    evaluate-commands %sh{
        line="$kak_reg_dot"
        if [ "$kak_opt_files_long_format" = true ]; then
            line="$(echo "$line" | sed -E "s/^(\S+ +){8}(.*)/\2/")"
        fi
        choice="$(echo "$line" | grep -Po "[^$kak_opt_files_markers]+")"
        cwd="$kak_opt_files_cwd"
        if [ "$cwd" != "/" ]; then
            target="$kak_opt_files_cwd/$choice"
        else
            target="/$choice"
        fi
        if cd "$target"; then
            echo "files-set-cwd '$PWD'"
        else
            echo "edit '$target'"
        fi
    }
}

hook global BufSetOption "filetype=%opt{files_browse_buffer}" %{
    add-highlighter buffer/ ref files-filetypes
    add-highlighter buffer/ ref long-format
    # files-disable-keys
    map buffer normal <ret> ': files-cd<ret>'
    map buffer normal <backspace> ': files-cd-parent<ret>'
    hook buffer NormalIdle ".*" %{
        info -title %opt{files_browse_buffer} %sh{
            printf "%-20s\n" "$kak_opt_files_cwd"
            rp="$(realpath "$kak_opt_files_cwd")"
            if [ "$rp" != "$kak_opt_files_cwd" ]; then
                echo "realpath: $rp"
            fi
            echo -n "sorting: $kak_opt_files_sorting"
            [  $kak_opt_files_sorting_reverse = "true" ] && echo -n "(rev)"
            echo
            echo -n "options: "
            [ $kak_opt_files_show_hidden = "true" ] && echo -n "show_hidden "
            [ $kak_opt_files_directories_first = "true" ] && echo -n "dir_first "
            echo
            echo -n "format: "
            [ $kak_opt_files_long_format = "true" ] && echo -n "long" || echo -n "short"
            echo
        }
    }
}

define-command files-cd-browser-to-realpath %{
    set-option buffer files_cwd %sh{echo "$(realpath "$kak_opt_files_cwd")"}
}

define-command files-cd-server-to-browser %{
    change-directory %opt{files_cwd} 
}

define-command files-cd-browser-to-server %{
    files-set-cwd %sh{pwd}
}

define-command files-focus-selections %{
    edit -scratch "*%opt{files_selection_buffer}*"
}

define-command files-select-current-entry %{
    execute-keys ";x_"
    try %{
        execute-keys "s(\S+ +){8}<ret>"
        execute-keys "l"
        execute-keys "<a-l>"
    }
    execute-keys "s\A[^%opt{files_markers}]+<ret>"
}

map global normal . ":files-add-entry-to-selection<ret>"

define-command files-add-entry-to-selection %{ evaluate-commands -draft %{
    files-select-current-entry
    execute-keys '"ey'
    set-register d %opt{files_cwd}
    files-focus-selections
    execute-keys "gj"
    try %{
        execute-keys "x<a-k>^.+$<ret>"
        execute-keys "o<esc>"
    }
    execute-keys '"dP'
    execute-keys 'ghgl'
    try %{
        execute-keys '<a-K>/<ret>'
        execute-keys 'li/<esc>'
    }
    execute-keys l
    execute-keys '"eP'
}}

define-command files-commit-operations %{
    nop %sh{
        eval "$kak_reg_dot"
    }
}

files-generate-ls-option-setters
# files-generate-getters
files-create-hl
files-generate-ls-option-togglers
