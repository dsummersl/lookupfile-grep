" setup standard path settings so the gf command will work:

exec 'set path='. b:proj_cd .'/*/src/*'
exec 'set path+='. b:proj_cd .'/**/pom.xml'
set suffixesadd=.java
set includeexpr=substitute(v:fname,'\\.','/','g')

" Search for any file in the path
let searchpath=&path
let allsuffixes='.java,.xml,.properties'
exec "map <LocalLeader>r <Esc>:call CaseLookupFile('". searchpath ."','". allsuffixes ."',3)<cr>"
exec "map <LocalLeader>t <Esc>:call CaseLookupFile('". searchpath ."','.java',3)<cr>"
exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',3)<cr>"

" exec "map <C-R> <Esc>:tabnew<cr>:LUPath<cr>"
" exec "map <C-T> <Esc>:tabnew<cr>:LookupFile<cr>"
