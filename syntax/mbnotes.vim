vim9s

if exists("b:current_syntax")
    finish
endif

runtime! syntax/quarto.vim
unlet b:current_syntax

syn region mbnCalloutNote start=":::\s\+{\.callout-note\s*" end=":::$" keepend
hi link mbnCalloutNote Question

syn region mbnCalloutWarning start=":::\s\+{\.callout-warning\s*" end=":::$" keepend
hi link mbnCalloutWarning SpellCap

syn region mbnCalloutImportant start=":::\s\+{\.callout-important\s*" end=":::$" keepend
hi link mbnCalloutImportant SpellBad

syn region mbnCalloutTip start=":::\s\+{\.callout-tip\s*" end=":::$" keepend
hi link mbnCalloutNote Question

syn region mbnCalloutCaution start=":::\s\+{\.callout-caution\s*" end=":::$" keepend
hi link mbnCalloutWarning SpellCap

b:current_syntax = "mbnotes"
