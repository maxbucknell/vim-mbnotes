vim9s

if !exists("g:mbnotes_loaded")
    finish
endif

export def OpenDailyNote(offset: number = 0)
    var diff = (g:mbnotes_new_day_time * -3600) + (offset * 86400)
    var date = strftime(g:mbnotes_date_format_short, localtime() + diff)
    var filename = g:mbnotes_dir .. "/daily/" .. date .. "-daily.qmd"

    execute "silent edit " .. fnameescape(filename)

    if !filereadable(filename)
        python3 import mbnotes
        python3 import vim

        execute "python3 vim.current.buffer[:] = mbnotes.generate_daily_note(" .. diff .. ").splitlines()"

        write

        normal G
    endif
enddef

export def RenderNote(format: string, buffer = "%")
    var input = expand(buffer)
    var output = substitute(
        fnamemodify(input, ":r"),
        g:mbnotes_dir,
        g:mbnotes_out_dir,
        ""
    ) .. "." .. format

    def ExitCb(job: job, exit: number)
        if exit != 0
            execute "botright sbuf " .. b:mbnotes_renderer_buffer
        elseif exists("g:mbnotes_open_command")
            execute "botright sbuf " .. b:mbnotes_renderer_buffer
            execute "!" .. g:mbnotes_open_command .. " " .. output
            execute "bwipeout " .. b:mbnotes_renderer_buffer
        endif

        unlet b:mbnotes_renderer_buffer
    enddef

    b:mbnotes_renderer_buffer = term_start([
        "quarto",
        "render",
        input,
        "--to",
        format,
        "--output-dir",
        g:mbnotes_out_dir
    ], {
        cwd: g:mbnotes_dir,
        hidden: true,
        exit_cb: ExitCb
    })
enddef

export def BeforeNoteSave()
    var full_path = expand('%:p')
    var daily_path = g:mbnotes_dir .. "/daily"

    # Don't touch daily notes
    if g:mbnotes_rename_on_save && daily_path != full_path[0 : len(daily_path) - 1]
        var base = expand('%:t')
        var date = base[0 : 9]

        var original_mark = getpos("'s")

        normal! ms

        cursor(1, 1)
        var title_line = search('^#\s\+')

        if title_line == 0
            throw "Unable to save note: No title found."
        endif

        var title = substitute(getline(title_line), '^#\s\+', '', '')
        var sanitised = substitute(
            tolower(title),
            '[^a-z0-9]\+',
            "-",
            "g"
        )

        normal! `s
        setpos("'s", original_mark)

        b:new_name = date .. "_" .. sanitised .. ".qmd"
    endif
enddef

export def AfterNoteSave()
    if exists("b:new_name")
        execute "silent Move " .. fnameescape(g:mbnotes_dir) .. "/" .. b:new_name
    endif
enddef

export def NewNote()
    var diff = (g:mbnotes_new_day_time * -3600)
    var date = strftime(g:mbnotes_date_format_short, localtime() + diff)

    var file = date .. "_new-note.qmd"
    execute "edit " .. g:mbnotes_dir .. "/" .. file
enddef
