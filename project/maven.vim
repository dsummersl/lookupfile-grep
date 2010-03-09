" setup standard path settings so the gf command will work:

exec 'set path='. b:proj_cd .'/*/src/*'
exec 'set path+='. b:proj_cd .'/src/*'
exec 'set path+='. b:proj_cd .'/**/pom.xml'
set suffixesadd=.java,.xml,.properties,.groovy
set includeexpr=substitute(v:fname,'\\.','/','g')

" Search for any file in the path
let searchpath=&path
let allsuffixes='.java,.xml,.properties,.groovy,.jsp,.txt'
exec "map <LocalLeader>r <Esc>:call BunnyCaseLookupFile('". searchpath ."','". allsuffixes ."',2)<cr>"
exec "map <LocalLeader>t <Esc>:call BunnyCaseLookupFile('". searchpath ."','.java',2)<cr>"
exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',5)<cr>"

" exec "map <C-R> <Esc>:tabnew<cr>:LUPath<cr>"
" exec "map <C-T> <Esc>:tabnew<cr>:LookupFile<cr>"
