declare-option -hidden str files_plugin_path %sh{ dirname "$kak_source" }

declare-option -hidden str files_browse_buffer 'files-browser'
declare-option -hidden str files_selection_buffer 'files-selections'
declare-option -hidden str files_markers "*/=>@|"
declare-option -hidden str files_disabled_keys "i I a A r R p P d <a-d> ! <a-!> | <a-|> <gt> <a-gt> <lt> <a-lt>"
declare-option -hidden bool files_show_hidden true
declare-option -hidden bool files_directories_first true
declare-option -hidden bool files_long_format false
declare-option -hidden str files_sorting "name"
declare-option -hidden bool files_sorting_reverse false
declare-option -hidden str files_sorting_opts "none name size time version extension"
declare-option -hidden bool files_auto_quoting false
declare-option -hidden str files_options_with_setters "show_hidden directories_first long_format sorting_reverse"
declare-option -hidden str files_togglable_options "show_hidden directories_first long_format"
declare-option -hidden str files_cwd
declare-option -hidden int files_browse_buffer_counter 0
declare-option -hidden line-specs files_long_format_gutter
declare-option -hidden str files_editor_client

define-command -hidden files-ls %{
    execute-keys %sh{
        cmd="$kak_opt_files_plugin_path/nice-ls.sh\
        '$kak_opt_files_cwd' '$kak_opt_files_show_hidden' '$kak_opt_files_directories_first' '$kak_opt_files_sorting' '$kak_opt_files_sorting_reverse'"
        echo "%%d!$cmd<ret>d"
    }
    evaluate-commands %{ try %{
        execute-keys gjx_
        evaluate-commands %sh{
            echo set-option buffer files_long_format_gutter $kak_timestamp "$kak_selection"
        }
        execute-keys xdgk
    }}
}

define-command files-new-browser -params 0..1 %{
    edit -scratch "*%opt{files_browse_buffer}-%opt{files_browse_buffer_counter}*"
    set-option buffer filetype %opt{files_browse_buffer}
    set-option -add global files_browse_buffer_counter 1
    files-set-cwd %sh{
        [ -n "$1" ] && echo "$1" || pwd
    }
}

define-command files-new-tied-browser -params 0..1 %{
    evaluate-commands -draft %sh{
        echo new
        echo files-new-browser "$@"
        echo set-option buffer files_editor_client "$kak_client"
    }
}

define-command -hidden files-create-hl %{
    add-highlighter shared/files-filetypes group
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)/@?$' 1:blue
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)\*@?$' 1:green
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)\|@?$' 1:yellow
    add-highlighter shared/files-filetypes/ regex '(?S)^(.*)=@?$' 1:magenta
    add-highlighter shared/files-filetypes/ regex '@' 0:cyan
}

define-command files-redraw-browser -params 0..1 %{
    evaluate-commands %sh{
        if [ "$1" = false ]; then
            echo "files-ls"
            exit
        fi
        echo "files-select-current-entry
              evaluate-commands -save-regs e %{
                  set-register e %reg{.}
                  files-ls
                  files-focus-entry %reg{e}
              }"
    }
    remove-highlighter buffer/long-format
    evaluate-commands %sh{
        if [ "$kak_opt_files_long_format" = "true" ]; then
            echo add-highlighter buffer/long-format flag-lines Default files_long_format_gutter
        fi
    }
}

define-command -hidden files-focus-entry -params 1 %{
    try %{ execute-keys "/^\Q%arg{1}\E[%opt{files_markers}]*$<ret>gi" }
}

define-command -hidden files-generate-ls-option-setters %{ evaluate-commands %sh{
    for opt in $kak_opt_files_options_with_setters; do
        echo "\
        define-command -params 1 files-set-$opt %{
            set-option buffer files_$opt %arg{1}
            files-redraw-browser
        }"
    done
}}

define-command -hidden files-generate-ls-option-togglers %{ evaluate-commands %sh{
    for opt in $kak_opt_files_togglable_options; do
        echo "\
        define-command files-toggle-$opt %{ evaluate-commands %sh{
            if [ \"\$kak_opt_files_$opt\" = true ]; then
                echo files-set-$opt false
            else
                echo files-set-$opt true
            fi
        }}
        "
    done
}}

define-command -params 1 files-set-cwd %{
    evaluate-commands %sh{
        if [ ! -d "$1" ]; then
            echo "fail not a directory"
        fi
        if ! cd "$1"; then
            echo "fail can't cd to directory"
        fi
        echo "set-option buffer files_cwd '$(pwd)'"
    }
    files-redraw-browser false
}

define-command -hidden files-cd-parent %{ evaluate-commands %sh{
    current_dir="$(basename "$kak_opt_files_cwd")"
    echo "files-set-cwd '$(dirname "$kak_opt_files_cwd")'"
    echo "files-focus-entry '$current_dir'"
}}

define-command -hidden files-cd %{ evaluate-commands -save-regs rsep %{
    set-register s ''
    set-register e ''
    set-register p ''
    evaluate-commands %sh{
        echo "$kak_selections_length" | grep -v ' ' >/dev/null && echo "set-register s true"
    }
    evaluate-commands -itersel %{
        evaluate-commands -draft %{
            files-full-path-of-choice
        }
        evaluate-commands %sh{
            target="$kak_reg_r"
            can_cd="$kak_reg_s"
            if [ -d "$target" ]; then
                if [ -n "$can_cd" ]; then
                    echo "files-set-cwd '$target'"
                fi
            else
                echo "evaluate-commands -draft -try-client '$kak_opt_files_editor_client' %{ edit '$target' }"
                echo "set-register e '$target'"
            fi
        }
    }
    evaluate-commands -draft %{
        execute-keys <space>
        files-full-path-of-choice
        evaluate-commands %sh{
            primary="$kak_reg_r"
            [ -f "$primary" ] && echo "set-register p '$primary'"
        }
    }
    evaluate-commands %sh{
        focus_file="$kak_reg_e"
        primary="$kak_reg_p"
        if [ -n "$primary" ]; then
            focus_file="$primary"
        fi
        [ -n "$focus_file" ] &&
            echo "evaluate-commands -try-client '$kak_opt_files_editor_client' %{ edit '$focus_file' }"
    }
}}

hook global BufSetOption "filetype=%opt{files_browse_buffer}" %{
    add-highlighter buffer/ ref files-filetypes
    # files-disable-keys
    hook buffer NormalIdle ".*" %{
        info -title %opt{files_browse_buffer} %sh{
            printf "%-20s\n" "$kak_opt_files_cwd/"
            rp="$(realpath "$kak_opt_files_cwd")"
            if [ "$rp" != "$kak_opt_files_cwd" ]; then
                echo "realpath: $rp/"
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

define-command -hidden files-select-current-entry %{
    execute-keys ";x_"
    execute-keys "s\A[^%opt{files_markers}]+<ret>"
}

define-command -hidden files-add-to-selection -params 1 %{ evaluate-commands -draft %{
    files-focus-selections
    execute-keys "gj"
    try %{
        execute-keys "x<a-k>^.+$<ret>"
        execute-keys "o<esc>"
    }
    execute-keys "i%arg{1}"
    execute-keys %sh{ [ -d "$1" ] && echo "/" }
    execute-keys "<esc>"
    evaluate-commands %sh{ $kak_opt_files_auto_quoting && echo "execute-keys I'<esc>A'<esc>" }
}}

define-command -hidden files-full-path-of-choice %{
    files-select-current-entry
    evaluate-commands %sh{ 
        cwd="$kak_opt_files_cwd"
        choice="$kak_selection"
        if [ "$cwd" != "/" ]; then
            target="$kak_opt_files_cwd/$choice"
        else
            target="/$choice"
        fi
        echo "set-register r '$target'"
    }
}

define-command files-add-entry-to-selection %{ evaluate-commands -draft -save-regs r %{
    evaluate-commands -itersel %{
        files-full-path-of-choice
        files-add-to-selection %reg{r}
    }
}}

define-command files-add-cwd-to-selection %{
    files-add-to-selection %opt{files_cwd}
}

define-command files-commit-operations %{
    nop %sh{
        eval "$kak_reg_dot"
    }
}

define-command files-toggle-auto-quoting %{
    set-option global files_auto_quoting %sh{
        $kak_opt_files_auto_quoting && echo false || echo true
    }
}

define-command files-set-auto-quoting -params 1 %{
    set-option global files_auto_quoting %arg{1}
}

define-command files-set-sorting -params 1 \
-menu -shell-script-candidates %{
    for e in $kak_opt_files_sorting_opts; do
        echo $e
    done
} %{
    evaluate-commands %sh{
        if echo "$kak_opt_files_sorting_opts" | grep -w "$1" > /dev/null; then
            echo "set-option buffer files_sorting $1"
            echo "files-redraw-browser"
        else
            echo "fail unknown sorting option"
        fi
    }
}

define-command files-select-current-file-in-browser %{
    evaluate-commands %sh{
        path="$kak_buffile"
        echo "files-new-browser '$(dirname $path)'"
        echo "files-focus-entry '$(basename $path)'"
    }
}

files-generate-ls-option-setters
# files-generate-getters
files-create-hl
files-generate-ls-option-togglers
