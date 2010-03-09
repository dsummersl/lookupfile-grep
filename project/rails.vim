" TODO make the mapping for C-H jump to the function rhtml file matching the
" controller function name. It doesn't really do that now - it's more of a
" fuck ya'll approach, matching the first one. Really, if the name of the
" controller is 'register_controller', we should only look in
" 'app/views/register/' for the function in question.
"
" Ideally the solution would be to use the search name INSIDE the lookupfile
" plugin.
" 1. If there is ONLY one match, then jump to the match...
" 2. If there is MORE than one match, then present a list.
" exec "map <C-L> <Esc>:set includeexpr=substitute(v:fname,'s$','','g')<cr>:set suffixesadd=.rb<cr>:set path=".b:proj_cd."/app/**<cr>:set path=".b:proj_cd."/lib/**<cr>:set path+=".b:proj_cd."/app/**<cr>:set path+=".b:proj_cd."/test/**<cr>gf"
" exec "map <C-H> <Esc>:set includeexpr=substitute(v:fname,'s$','','g')<cr>:set suffixesadd=.rhtml<cr>:set path=".b:proj_cd."/app/**<cr>:set path+=".b:proj_cd."/lib/**<cr>gf"
" exec "map <C-K> <Esc>:set includeexpr=substitute(substitute(v:fname,'s$','',''),'$','_test','g')<cr>:set suffixesadd=.rb<cr>:set path=".b:proj_cd."/test/**<cr>gf"

let searchpath=b:proj_cd .'/app/**,'. b:proj_cd .'/lib/**,'. b:proj_cd .'/test/**,'. b:proj_cd .'/config/**,'. b:proj_cd .'/db/**'
let allsuffixes='.rb,.yml,.rhtml'
exec "map <LocalLeader>r <Esc>:call CaseLookupFile('". searchpath ."','". allsuffixes ."',2)<CR>"
exec "map <LocalLeader>t <Esc>:call CaseLookupFile('". searchpath ."','.rb',2)<CR>"
exec "map <LocalLeader>g <Esc>:call GrepLookup('". searchpath ."','". allsuffixes ."',5)<CR>"
