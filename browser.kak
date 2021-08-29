declare-option -hidden str my_plugin_path %sh{ dirname "$kak_source" }

declare-option -hidden str files_browse_buffer 'files-browse'
declare-option str files_markers "*/=>@|"
declare-option str files_disabled_keys "i I a A r R p P d <a-d> ! <a-!> | <a-|> <gt> <a-gt> <lt> <a-lt>"
declare-option bool files_show_hidden true
declare-option bool files_directories_first true
declare-option bool files_long_format false
declare-option str files_sorting "name"
declare-option bool files_sorting_reverse false
declare-option str files_ls_options "files_show_hidden files_directories_first files_long_format files_sorting files_sorting_reverse"
declare-option str files_options_with_getters "files_show_hidden files_directories_first files_long_format files_cwd"
declare-option str files_cwd
declare-option int files_browse_buffer_counter 0

define-command -hidden files-ls %{
    execute-keys %sh{
        cmd="$kak_opt_my_plugin_path/nice-ls.sh\
        '$kak_opt_files_cwd' '$kak_opt_files_show_hidden' '$kak_opt_files_directories_first' '$kak_opt_files_sorting' '$kak_opt_files_sorting_reverse'"
        echo "%%d!$cmd<ret>dgk"
    }
}

define-command files-new-browse -params 0..1 %{
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

define-command -hidden files-enable-hl %{
    add-highlighter buffer/ regex '(?S)^(.*)/@?$' 1:blue
    add-highlighter buffer/ regex '(?S)^(.*)\*@?$' 1:green
    add-highlighter buffer/ regex '(?S)^(.*)\|@?$' 1:yellow
    add-highlighter buffer/ regex '(?S)^(.*)\|=?$' 1:magenta
    add-highlighter buffer/ regex '@' 0:cyan
}

define-command -hidden files-generate-ls-option-setters %{ evaluate-commands %sh{
    for opt in $kak_opt_files_ls_options; do
        echo "\
        define-command -params 1 files-set-$opt %{
            set-option buffer $opt %arg{1}
            execute-keys ';x_'
            evaluate-commands %sh{
                current_line=\"\$kak_reg_dot\"
                echo 'files-ls'
                echo \"try %{ execute-keys '/^\Q\$current_line\E$<ret>gi' }\"
            }
        }"
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
    echo "try %{ execute-keys '/^$current_dir[$kak_opt_files_markers]{,2}<ret>gi' }"
}}

define-command -hidden files-cd %{
    execute-keys ";x_"
    evaluate-commands %sh{
        choice="$(echo "$kak_reg_dot" | grep -Po "[^$kak_opt_files_markers]+")"
        target="$(realpath "$kak_opt_files_cwd/$choice")"
        if cd "$target"; then
            echo "files-set-cwd '$PWD'"
        else
            echo "edit '$target'"
        fi
    }
}

hook global BufSetOption "filetype=%opt{files_browse_buffer}" %{
    files-enable-hl
    files-disable-keys
    map buffer normal <ret> ': files-cd<ret>'
    map buffer normal <backspace> ': files-cd-parent<ret>'
    hook buffer NormalIdle ".*" %{
        info -title %opt{files_browse_buffer} %sh{
            printf "%-20s\n" "$kak_opt_files_cwd"
            echo -n "sorting: $kak_opt_files_sorting"
            [  $kak_opt_files_sorting_reverse = "true" ] && echo -n "(rev)"
            echo
            echo -n "options: "
            [ $kak_opt_files_show_hidden = "true" ] && echo -n "show_hidden "
            [ $kak_opt_files_directories_first = "true" ] && echo -n "dir_first "
            echo 
        }
    }
}

files-generate-ls-option-setters
files-generate-getters
