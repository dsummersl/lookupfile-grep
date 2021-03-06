" setup standard path settings so the gf command will work:

exec 'set path='. b:proj_cd .'/**'
set suffixesadd=.java,.xml,.properties,.groovy,.gsp
set includeexpr=substitute(v:fname,'\\.','/','g')

let searchpath=&path
let allsuffixes='.java,.xml,.properties,.groovy,.gsp'
exec "map <LocalLeader>r <Esc>:call BunnyCaseLookupFile('". searchpath ."','". allsuffixes ."',2)<cr>"
exec "map <LocalLeader>t <Esc>:call BunnyCaseLookupFile('". searchpath ."','.java,.grails',2)<cr>"
exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',5)<cr>"

" exec "map <C-R> <Esc>:tabnew<cr>:LUPath<cr>"
" exec "map <C-T> <Esc>:tabnew<cr>:LookupFile<cr>"

