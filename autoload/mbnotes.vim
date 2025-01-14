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
            if !g:mbnotes_renderer_show
                execute g:mbnotes_renderer_buffer_command
                    .. " " .. b:mbnotes_renderer_buffer
            endif
        else
            if exists("g:mbnotes_open_command") && g:mbnotes_open_command != ""
                execute "!" .. g:mbnotes_open_command .. " " .. output
            endif

            if g:mbnotes_renderer_close_on_end
                    && exists("b:mbnotes_renderer_buffer")
                execute "bwipeout " .. b:mbnotes_renderer_buffer
            endif
        endif
    enddef

    var command = [
        g:mbnotes_quarto_binary, "render", input,
        "--to", format,
        "--output-dir", g:mbnotes_out_dir
    ] + g:mbnotes_quarto_render_args

    # echo command

    b:mbnotes_renderer_buffer = term_start(command, {
        cwd: g:mbnotes_dir,
        hidden: !g:mbnotes_renderer_show,
        term_opencmd: g:mbnotes_renderer_buffer_command .. " %d",
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

export def Operator(context = {}, type: string = ''): string
    if type == ''
        var _context = {
            "dot_command": false,
            "extend_block": '',
            "virtualedit": [&l:virtualedit, &g:virtualedit]
        }
        &operatorfunc = function(Operator, [_context])
        set virtualedit=block
        return 'g@'
    endif

    var save = {
        "clipboard": &clipboard,
        "selection": &selection,
        "virtualedit": [&l:virtualedit, &g:virtualedit],
        "register": getreginfo('m'),
        "visual_marks": [getpos("'<"), getpos("'>")]
    }

    try
        set clipboard= selection=inclusive virtualedit=
        var commands = {
            "line": "'[V']",
            "char": "`[v`]",
            "block": "`[\<c-V>`]",
        }[type]

        var [_, _, col, off] = getpos("']")
        if off != 0
            var vcol = getline("'[")->strpart(0, col + off)->strdisplaywidth()

            if vcol >= [line("'["), '$']->virtcol() - 1
                context['extend_block'] = '$'
            else
                context['extend_block'] = vcol .. '|'
            endif
        endif

        if context['extend_block'] != ''
            commands ..= 'oO' .. context['extend_block']
        endif

        commands ..= '"my'

        execute 'silent noautocmd keepjumps normal! ' .. commands

        NewNote()

        # normal! "mPG"_dd
        normal! "mPG
    finally
        setreg('m', save['register'])
        setpos("'<", save['visual_marks'][0])
        setpos("'>", save['visual_marks'][1])
        &clipboard = save['clipboard']
        &selection = save['selection']

        if context['dot_command']
            &l:virtualedit = save['virtualedit'][0]
            &g:virtualedit = save['virtualedit'][1]
        else
            &l:virtualedit = context['virtualedit'][0]
            &g:virtualedit = context['virtualedit'][1]
        endif

        context['dot_command'] = true
    endtry

    return ""
enddef
