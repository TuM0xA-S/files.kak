declare-option -hidden str my_plugin_path %sh{ dirname "$kak_source" }

declare-option -hidden str browse_buffer '*files-browse*'
declare-option str cwd

define-command -hidden ls %{
    execute-keys "%%d!%opt{my_plugin_path}/nice-ls.sh %opt{cwd}<ret>gk"
}

define-command files-browse -params 0..1 %{
    edit -scratch %opt{browse_buffer}
    set-option buffer cwd %sh{
        [ -n "$1" ] && echo "$1" || pwd
    }
    ls
}

hook global BufCreate "\*files-browse\*" %{
    hook buffer NormalKey '<ret>' %{
        try %{
            execute-keys "gl<a-k>[*/=>@|]<ret>d"
        }
        execute-keys "x_"
        evaluate-commands %sh{
            choice="$kak_reg_dot"
            cwd="$kak_opt_cwd"
            echo $cwd/$choice > dump
            if cd "$cwd/$choice"; then
                echo "files-browse '$PWD'"
            else
                echo "edit '$cwd/$choice'"
            fi
        }
    }
    hook buffer NormalKey '<backspace>' %{ evaluate-commands %sh{
        current_dir="$(basename "$kak_opt_cwd")"
        echo files-browse "$(dirname "$kak_opt_cwd")"
        echo "execute-keys '/^$current_dir<ret>gi'"
    }}
}
