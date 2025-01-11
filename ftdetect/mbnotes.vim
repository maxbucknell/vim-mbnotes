vim9s

def IsMBNotes()
    var path_prefix = expand('%:p')[0 : len(g:mbnotes_dir) - 1]

    if path_prefix == g:mbnotes_dir
        set filetype=mbnotes
    endif
enddef

au BufNewFile,BufRead *.qmd IsMBNotes()
