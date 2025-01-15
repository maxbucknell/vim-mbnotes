vim9s

if exists("g:mbnotes_loaded")
    finish
endif

if !exists("g:mbnotes_renderer_show")
    g:mbnotes_renderer_show = false
endif

if !exists("g:mbnotes_renderer_close_on_finish")
    g:mbnotes_renderer_close_on_finish = true
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

if !exists("g:mbnotes_rename_on_save")
    g:mbnotes_rename_on_save = true
endif

if !exists("g:mbnotes_quarto_binary")
    g:mbnotes_quarto_binary = "quarto"
endif

if !exists("g:mbnotes_quarto_render_args")
    g:mbnotes_quarto_render_args = []
endif

if !exists("g:mbnotes_renderer_buffer_command")
    g:mbnotes_renderer_buffer_command = "botright sbuf"
endif

if !exists("g:mbnotes_search_command")
    g:mbnotes_search_command = "rg "
        .. "--column "
        .. "--line-number "
        .. "--no-heading "
        .. "--color=always "
        .. "--smart-case "
        .. "--glob='**/*.qmd' "
        .. "-- "
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

command -nargs=? MBNotesDaily mbnotes.OpenDailyNote(<args>)
command -nargs=? MBNotesDailySplit {
    execute "<mods> new"
    mbnotes.OpenDailyNote(<args>)
}

command -nargs=0 MBNotesPDF mbnotes.RenderNote("pdf")
command -nargs=0 MBNotesHTML mbnotes.RenderNote("html")

command -nargs=0 MBNotesNew mbnotes.NewNote()
command -nargs=0 MBNotesNewSplit {
    execute "<mods> new"
    mbnotes.NewNote()
}

nnoremap <expr> <Plug>MBNotesNew <SID>mbnotes.Operator()
xnoremap <expr> <Plug>MBNotesNew <SID>mbnotes.Operator()
nnoremap <expr> <Plug>MBNotesNewLine <SID>mbnotes.Operator() .. '_'

command -nargs=? -bang MBNotes fzf#run(fzf#wrap('MBNotes', {
            \ "options": ["--query", ".qmd$ " .. <q-args>],
            \ "dir": g:mbnotes_dir
            \ }, <bang>0))

command -nargs=? -bang MBNotesSearch fzf#vim#grep(
            \ g:mbnotes_search_command .. shellescape(<q-args>),
            \ fzf#vim#with_preview({
            \   "dir": g:mbnotes_dir
            \ }), <bang>0)

command -nargs=? -bang MBNotesTags mbnotes.SearchForTags(<q-args>, <bang>0)

g:mbnotes_loaded = 1
