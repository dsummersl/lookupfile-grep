" setup standard path settings so the gf command will work:

exec 'set path='. b:proj_cd .'/**'
set suffixesadd=.java,.xml,.properties,.groovy
set includeexpr=substitute(v:fname,'\\.','/','g')

let searchpath=&path
let allsuffixes='.java,.xml,.properties,.groovy,.jsp,.txt'
exec "map <LocalLeader>r <Esc>:call BunnyCaseLookupFile('". searchpath ."','". allsuffixes ."',2)<cr>"
exec "map <LocalLeader>t <Esc>:call BunnyCaseLookupFile('". searchpath ."','.java',2)<cr>"
exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',5)<cr>"

" exec "map <C-R> <Esc>:tabnew<cr>:LUPath<cr>"
" exec "map <C-T> <Esc>:tabnew<cr>:LookupFile<cr>"

function! UPDATE_TAGS()
  let _f_ = expand("%:p")
  let _cmd_ = '"ctags -a -f /dvr/tags --c++-kinds=+p --fields=+iaS --extra=+q " ' . '"' . _f_ . '"'
  let _resp = system(_cmd_)
  unlet _cmd_
  unlet _f_
  unlet _resp
endfunction
autocmd BufWrite *.cpp,*.h,*.c call UPDATE_TAGS()

" so maybe a new plugin:
"  - takes the types of files you want
"  - takes the ctags equivalent commands...
"  - generates lookup hotkeys (you pass in the command) for fuzzyfinder.
"  - generates auto commands to keep ctags files up to date, makes sure gf
"  works and the like...
"  setup omnicompletion.
