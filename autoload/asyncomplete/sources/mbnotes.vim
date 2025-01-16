function! asyncomplete#sources#mbnotes#get_source_options(opts)
    let l:defaults = {
                \ 'name': 'mbnotes',
                \ 'completor': function('asyncomplete#sources#mbnotes#completor'),
                \ 'allowlist': ['mbnotes.quarto']
                \ }

    return extend(l:defaults, a:opts)
endfunction

let s:notes = []
let s:notes_ttl = 0
let s:command = "rg -N --no-heading --color=never --smart-case "
            \ .. "--glob='**/*.qmd' -m 1 --  '^#\\s' "
            \ .. shellescape(g:mbnotes_dir)

function! asyncomplete#sources#mbnotes#format_cache_entry(key, line)
    let l:line = substitute(a:line, g:mbnotes_dir .. "/", "", "")
    let l:parts = split(l:line, '\.qmd:#\s*')

    return ['[' .. l:parts[1] .. '](' .. l:parts[0] .. '.qmd)'] + l:parts
endfunction!

function! asyncomplete#sources#mbnotes#refresh_cache()
    let l:output = systemlist(s:command)

    let s:notes = mapnew(l:output, function('asyncomplete#sources#mbnotes#format_cache_entry'))
    let s:notes_ttl = localtime() + 20
endfunction!

function! asyncomplete#sources#mbnotes#completor(opt, ctx)
    let l:title_pattern = '\[[^\]]*$'
    let l:title = matchstr(a:ctx['typed'], l:title_pattern)

    if l:title !=# ''
        if localtime() > s:notes_ttl
            call asyncomplete#sources#mbnotes#refresh_cache()
        endif

        let l:col = a:ctx['col'] - len(l:title)
        let l:matches = mapnew(s:notes, '{"word": v:val[0], "dup": 1, "menu": v:val[1], "abbr": v:val[2]}')

        call asyncomplete#complete(a:opt['name'], a:ctx, l:col, l:matches)

        return
    endif

    let l:link_pattern = '\]([^)]*$'
    let l:link = matchstr(a:ctx['typed'], l:link_pattern)

    if l:link !=# ''
        if localtime() > s:notes_ttl
            call asyncomplete#sources#mbnotes#refresh_cache()
        endif

        let l:col = a:ctx['col'] - len(l:link)
        let l:matches = mapnew(s:notes, '{"word": "](" .. v:val[1] .. ".qmd)", "abbr": v:val[1]}')

        call asyncomplete#complete(a:opt['name'], a:ctx, l:col, l:matches)

        return
    endif
endfunction
