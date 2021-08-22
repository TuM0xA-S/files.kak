declare-option -hidden str my_plugin_path %sh{ dirname "$kak_source" }

declare-option -hidden str browse_buffer '*files-browse*'
declare-option str markers "*/=>@|"
declare-option str disabled_keys "i I a A r R p P d <a-d> ! <a-!> | <a-|> <gt> <a-gt> <lt> <a-lt>"
declare-option bool show_hidden false
declare-option bool directories_first true
declare-option bool long_format false
declare-option str sorting "name"
declare-option str cwd
declare-option str options_changing_view "show_hidden directories_first long_format sorting cwd"

define-command -hidden ls %{
    execute-keys %sh{
        cmd="$kak_opt_my_plugin_path/nice-ls.sh\
        '$kak_opt_cwd' '$kak_opt_show_hidden' '$kak_opt_directories_first' '$kak_opt_sorting'"
        echo "%%d!$cmd<ret>dgk"
    }
}

define-command files-browse -params 0..1 %{
    edit -scratch %opt{browse_buffer}
    set-option buffer cwd %sh{
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

define-command -hidden enable-redraw %{ evaluate-commands %sh{
    for opt in $kak_opt_options_changing_view; do
        echo "hook buffer BufSetOption $opt=.* %{ eval -try-client $kak_client ls }"
    done
}}

define-command -hidden files-cd-parent %{ evaluate-commands %sh{
    current_dir="$(basename "$kak_opt_cwd")"
    echo "files-browse '$(dirname "$kak_opt_cwd")'"
    echo "execute-keys '/^$current_dir<ret>gi'"
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
    enable-redraw
    map buffer normal <ret> ': files-cd<ret>'
    map buffer normal <backspace> ': files-cd-parent<ret>'
}
