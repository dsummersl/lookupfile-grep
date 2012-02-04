" setup standard path settings so the gf command will work:

exec 'set path='. b:proj_cd .'/**'
set suffixesadd=.java,.xml,.properties,.groovy
set includeexpr=substitute(v:fname,'\\.','/','g')

let searchpath=&path
let allsuffixes='.js,.coffee,.css,.json'
exec "map <LocalLeader>r <Esc>:call BunnyCaseLookupFile('". searchpath ."','". allsuffixes ."',2)<cr>"
exec "map <LocalLeader>t <Esc>:call BunnyCaseLookupFile('". searchpath ."','.java',2)<cr>"
" exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',5)<cr>"

" exec "map <C-R> <Esc>:tabnew<cr>:LUPath<cr>"
" exec "map <C-T> <Esc>:tabnew<cr>:LookupFile<cr>"

function! UPDATE_TAGS()
  let _f_ = expand("%:p")
  let _cmd_ = '"ctags -a -f /dvr/tags --fields=+iaS --extra=+q " ' . '"' . _f_ . '"'
  let _resp = system(_cmd_)
  unlet _cmd_
  unlet _f_
  unlet _resp
endfunction
autocmd BufWrite *.css call UPDATE_TAGS()
