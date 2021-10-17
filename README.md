# files.kak
file manager in kakoune buffer
![image](https://user-images.githubusercontent.com/64231066/137635362-dc3fa83d-2927-4422-be55-86fa5719223c.png)

### features
* browse directories
* open files
* open files from file browser in tied kakoune client
* batching(can open/select multiple files at once)
* colored
* supports some of ls options(sorting, show hidden .. etc)
* select files
* manipulate files

### docs
all commands under `files-` namespace, and at most self-explanatory
some basics:
* `files-new-browser` - to open filebrowser in current buffer
* `files-focus-selections` - focus buffer with selections
* `files-cd` - open or cd
* `files-cd-parent` - `cd ..`
* `files-toggle-long_format` - basically toggle `ls -l`

### configuration
```
define-command shell-eval %{
    nop %sh{
        eval "$kak_reg_dot"
    }
}

hook global BufSetOption "filetype=%opt{files_browse_buffer}" %{
    map buffer normal '<ret>' ': files-cd<ret>'
    map buffer normal '<backspace>' ': files-cd-parent<ret>'
    map buffer normal 'm' ": files-add-entry-to-selection<ret>"
    map buffer normal 'M' ": files-add-cwd-to-selection<ret>"
    map buffer normal '.' ": files-toggle-show_hidden<ret>"
    map buffer normal '\' ": files-toggle-long_format<ret>"
    map buffer normal 'r' ": files-redraw-browser<ret>"
    map buffer normal 'S' ": files-focus-selections<ret>"
    map buffer normal 't' ": files-open-in-terminal<ret>"
}

hook global BufSetOption "filetype=%opt{files_selection_buffer}" %{
    map buffer normal <ret> ': shell-eval<ret>'
}
```
also you can use it as standalone file manager by placing `kfm` script from repo in you path
### how to manipulate files
1. the most tedious part when do file manipulations is selecting
2. so you select files/directories with file browser
3. then you just edit selections buffer to create needed command
4. do `shell-eval`

that approach is very flexible and allows creating complicated batch rename/copy/delete operation easily, by using kakoune multi-selection editing and path completion capabilities
