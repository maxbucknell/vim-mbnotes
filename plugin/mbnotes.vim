vim9s

if exists("g:mbnotes_loaded")
    finish
endif

if !exists("g:mbnotes_dir")
    echoerr "MBNotes: Error: g:mbnotes_dir not set."
    finish
else
    silent mkdir(fnameescape(g:mbnotes_dir .. "/daily"), "p")
endif

if !exists("g:mbnotes_out_dir")
    g:mbnotes_out_dir = $TMPDIR .. "xyz.mpwb.vim.mbnotes"
endif

if !exists("g:mbnotes_open_command")
    if executable("open")
        g:mbnotes_open_command = "open"
    elseif executable("xdg-open")
        g:mbnotes_open_command = "xdg-open"
    endif
endif

silent mkdir(g:mbnotes_out_dir, "p")

if !exists("g:mbnotes_open_daily_on_startup")
    g:mbnotes_open_daily_on_startup = false
endif

if !exists("g:mbnotes_new_day_time")
    g:mbnotes_new_day_time = 4
endif

if !exists("g:mbnotes_date_format_short")
    g:mbnotes_date_format_short = "%Y-%m-%d"
endif

if !exists("g:mbnotes_date_format_long")
    g:mbnotes_date_format_long = "%A, %-e %B %Y"
endif

import autoload 'mbnotes.vim'

augroup MBNotes
    autocmd!

    if g:mbnotes_open_daily_on_startup
        au VimEnter * ++nested {
            if @% == ""
                mbnotes.OpenDailyNote()
            endif
        }
    endif

    execute "autocmd BufWritePre "
    .. fnameescape(g:mbnotes_dir) .. "/*.qmd mbnotes.BeforeNoteSave()"

    execute "autocmd BufWritePost "
    .. fnameescape(g:mbnotes_dir) .. "/*.qmd mbnotes.AfterNoteSave()"
augroup END

command -nargs=? MBNotesOpenDaily mbnotes.OpenDailyNote(<args>)
command -nargs=? MBNotesOpenDailySplit {
    execute "<mods> new"
    mbnotes.OpenDailyNote(<args>)
}

command -nargs=0 MBNotesRenderPDF mbnotes.RenderNote("pdf")
command -nargs=0 MBNotesRenderHTML mbnotes.RenderNote("html")

command -nargs=0 MBNotesNew mbnotes.NewNote()
command -nargs=0 MBNotesNewSplit {
    execute "<mods> new"
    mbnotes.NewNote()
}

g:mbnotes_loaded = 1
