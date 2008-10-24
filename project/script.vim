" setup standard path settings so the gf command will work:

exec 'set path='. b:proj_cd .'/**'
set suffixesadd=.txt,.xml,.sh,.rb,.py,.vim,.bat,.sql,.groovy
set includeexpr=substitute(v:fname,'\\.','/','g')

let searchpath=&path
let allsuffixes='.txt,.xml,.sh,.rb,.py,.vim,.bat,.sql,.groovy'
exec "map <LocalLeader>r <Esc>:call CaseLookupFile('". searchpath ."','". allsuffixes ."',3)<cr>"
exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',3)<cr>"
