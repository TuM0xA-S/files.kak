declare-option -hidden str my_plugin_path %sh{ dirname "$kak_source" }

declare-option -hidden str browse_buffer '*files-browse*'
declare-option str markers "*/=>@|"
declare-option str disabled_keys "i I a A r R p P d <a-d> ! <a-!> | <a-|> <gt> <a-gt> <lt> <a-lt>"
declare-option bool show_hidden false
declare-option bool directories_first true
declare-option bool long_format false
declare-option str ls_options "show_hidden directories_first long_format"
declare-option str options_with_getters "show_hidden directories_first long_format cwd"
declare-option str sorting "name"
declare-option str cwd
declare-option str client

define-command -hidden ls %{
    execute-keys -client %opt{client} %sh{
        cmd="$kak_opt_my_plugin_path/nice-ls.sh\
        '$kak_opt_cwd' '$kak_opt_show_hidden' '$kak_opt_directories_first' '$kak_opt_sorting'"
        echo "%%d!$cmd<ret>dgk"
    }
}

define-command files-browse -params 0..1 %{
    edit -scratch %opt{browse_buffer}
    set-option buffer client %val{client}
    files-set-cwd %sh{
        [ -n "$1" ] && echo "$1" || pwd
    }
}

define-command -hidden disable-keys %{ evaluate-commands %sh{
    for key in $kak_opt_disabled_keys; do
        echo "map buffer normal $key ''"
    done
}}

define-command -hidden enable-hl %{
    add-highlighter buffer/ regex '(?S)^(.*)/@?$' 1:blue
    add-highlighter buffer/ regex '(?S)^(.*)\*@?$' 1:green
    add-highlighter buffer/ regex '(?S)^(.*)\|@?$' 1:yellow
    add-highlighter buffer/ regex '(?S)^(.*)\|=?$' 1:magenta
    add-highlighter buffer/ regex '@' 0:cyan
}

define-command -hidden generate-ls-option-setters %{ evaluate-commands %sh{
    for opt in $kak_opt_ls_options; do
        echo "\
        define-command -params 1 files-set-$opt %{
            set-option buffer $opt %arg{1}
            execute-keys ';x_'
            evaluate-commands %sh{
                current_line=\"\$kak_reg_dot\"
                echo 'ls'
                echo \"try %{ execute-keys '/^\Q\$current_line\E$<ret>gi' }\"
            }
        }"
    done
}}

define-command -hidden generate-getters %{ evaluate-commands %sh{
    for opt in $kak_opt_options_with_getters; do
        echo "define-command files-get-$opt %{ echo '%opt{$opt}' }"
    done
}}

define-command -params 1 files-set-cwd %{
    set-option buffer cwd %arg{1}
    ls
}

define-command -hidden files-cd-parent %{ evaluate-commands %sh{
    current_dir="$(basename "$kak_opt_cwd")"
    echo "files-browse '$(dirname "$kak_opt_cwd")'"
    echo "try %{ execute-keys '/^$current_dir[$kak_opt_markers]{,2}<ret>gi' }"
}}

define-command -hidden files-cd %{
    execute-keys ";x_"
    evaluate-commands %sh{
        choice="$(echo "$kak_reg_dot" | grep -Po "[^$kak_opt_markers]+")"
        target="$kak_opt_cwd/$choice"
        if cd "$target"; then
            echo "files-browse '$PWD'"
        else
            echo "edit '$target'"
        fi
    }
}

hook global BufCreate "\Q%opt{browse_buffer}\E" %{
    enable-hl
    disable-keys
    map buffer normal <ret> ': files-cd<ret>'
    map buffer normal <backspace> ': files-cd-parent<ret>'
}

generate-ls-option-setters
generate-getters
