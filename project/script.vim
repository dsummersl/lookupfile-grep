" setup standard path settings so the gf command will work:

exec 'set path='. b:proj_cd .'/**'
set includeexpr=substitute(v:fname,'\\.','/','g')

let searchpath=&path
set suffixesadd=.txt,.xml,.sh,.rb,.py,.vim,.bat,.sql,.groovy,.java,.properties,.cpp,.c
let allsuffixes='.txt,.xml,.sh,.rb,.py,.vim,.bat,.sql,.groovy,.java,.properties,.cpp,.c'
exec "map <LocalLeader>r <Esc>:call BunnyCaseLookupFile('". searchpath ."','". allsuffixes ."',2)<cr>"
exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',5)<cr>"
