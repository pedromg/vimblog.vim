if exists("b:current_syntax")
  finish
endif

syntax keyword wpType    Post  Title    Date  Author Link 
             \ Permalink Allow Comments Allow Pings  Categs

syntax match   wpFields /: .*/hs=s+2 contains=wpPostId, wpTitle

syntax region  wpTitle  start=/"/  end=/$/  contained
syntax region  wpPostId start=/\[/ end=/\]/ contained

if &background ==? "dark"
  highlight wpType   ctermfg=Green guifg=LightGreen 
                   \ gui=bold
  highlight wpPostId ctermfg=Red   guifg=Red
  highlight wpFields ctermfg=Blue  guifg=Blue
                   \ guibg=LightCyan
else
  highlight wpType   ctermfg=Green guifg=DarkMagenta
                   \ gui=bold
  highlight wpPostId ctermfg=Red   guifg=Red
  highlight wpFields ctermfg=Blue  guifg=Blue
                   \ guifg=DarkCyan
endif
