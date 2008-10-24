" lookupfile-grep.vim: Lookup files that contain text matches in them.
" Author: Dane Summers (dsummersLa ata yahooa dotta comma (take an 'a' of the
" end of everything))
" Last Change: Oct 23, 2008
" Revision: 15
" Requires:
" Vim-7.0
" lookupfile plugin (v 1.4+)
" findutils (find command requires -wholename for 'folder/*/subfolder' type patterns in find command)
" textutils (sed, xargs, etc)
"
" Documentation:
"
" This is a plugin for the lookupfile plugin. It has two usable functions that
" integrate into the lookupfile plugin. Both functions have these basic
" features:
"
"   - The &path and the &suffixesadd are taken into account to determine
"     whether a file should be visible in the drop down list.
"   - To make for quicker file lookups when '*' is part of the search pattern
"     it is treated as if it were '.*' (the probably intent of * by the user).
"   - You can setup whether searches are case sensitive through the
"     g:LookupFileGrep_IgnoreCase setting.
"   - To support changing the path/suffixesadd values on the fly you can use
"     the GrepLookup/CaseLookupFile functions directly (b/c &path and
"     &suffixesadd are settings local to the buffer they are not garaunteed to
"     work with any lookupfile functions if you set &path/&suffixesadd directly.
"
" GrepLookup:
"   The GrepLookup provides a similar feature set to the builtin :grep and
"   :vimgrep provided in Vim, except that it is integrated into the lookupfile
"   plugin. In short: type in a pattern, and any file that contains the
"   pattern is displayed in a drop down.
"
" CaseLookupFile:
"   This function is similar to the default LUPath function provided by the
"   lookupfile plugin, except that it has the standard behavior listed
"   previously (takes &path & &suffixesadd plus '*' converted to '.*', etc).
"
" BunnyCaseLookupFile:
"   Matches files as above, but in addition automatically turns a capital
"   letter search into '\u*' so that you can quickly match agains the capital
"   letters (handy for long java file names).
"
" TODO add the ability to specify whether cache files are temporary or permanent (and if they are
" permanent, then add a function to flush them out.
"
" Thanks:
" Hari Krishna Dara, the lookupfile plugin author
" Adam Thorsen, suffering beta tester

" Settings:{{{
if !exists('g:LookupFileGrep_IgnoreCase')
	" If set to true, then all searches will ignore case during the search
	" process without disturbing the user's 'ignorecase' setting.
	let g:LookupFileGrep_IgnoreCase = 0
endif

if !exists('g:LookupFileGrep_TempCaches')
	" If set, then all lookup functions use a temporary
	" filename for cacheing. Otherwise, a permanent file
	" in the project directory is created.
	let g:LookupFileGrep_TempCaches = 0
endif

if !exists('g:LookupFileGrep_UtilsBase')
	" textutils and findutils commands base directory where they are installed.
	" The default ones on OSX are not good (I used fink).
	let g:LookupFileGrep_UtilsBase = '/sw/bin/'
endif

if !exists('g:LookupFileGrep_Ctags')
	" find command
	let g:LookupFileGrep_Ctags = 'ctags'
endif
" }}}

command! GrepLookup call GrepLookupDefault()
command! CaseLookupFile call CaseLookupFileDefault()
command! BunnyCaseLookupFile call BunnyCaseLookupFileDefault()
command! FunctionLookupFile call FunctionLookupFileDefault()

" Support functions{{{

function! TagFileMatch(tagfile,pattern)
	" GIVEN:
	"  - a tagfile
	"  - a pattern
	"
	" RETURNS:
	"  - returns a list of all tags from a:tagfile that matches a:pattern.
	let _tags = &tags
	try
		let &tags = a:tagfile
		let l:ig = &ignorecase
		if (g:LookupFileGrep_IgnoreCase == 1)
			set ignorecase
		endif
		let matches = taglist(a:pattern)
		if (l:ig == 0)
			set noignorecase
		endif
		return map(matches, '{"word": v:val["filename"],"abbr": fnamemodify(v:val["filename"], ":t"), "menu": fnamemodify(v:val["filename"], ":p:~:h")}')
	catch
		echohl ErrorMsg | echo "Exception: " . v:exception | echohl NONE
	finally
		let &tags = _tags
	endtry
	return ""
endfunction

function! <SID>NewFile()
	" Return a new file name that can be used. This is a wrapper function that
	" acts very much like tempname(), but allows the ability to return non
	" temp file names.
endfunction

function! <SID>PathExists(somepath)
  "return getfsize(a:somepath) == 0
  return 1 == 1 
endfunction

function! <SID>CommandsForFind(paths,suffixes,find)
	" Given:
	" a:paths = A &path setting.
	" a:suffixes = A &suffixesadd setting.
	" a:find = find command
	"
	" Return:
	" A string that compiles a list of all eligible files in the a:path
	" given the a:suffixes.

	let splitpaths = split(a:paths,',')
	let splitsuffixes = split(a:suffixes,',')
	let results = ''
	let first = 0
	if (len(splitpaths) > 0)
		for apath in splitpaths
			let somepath = fnamemodify(apath,":p")
			" let results = '['. somepath .']'. results
			if first == 0
				let first = 1
			elseif strpart(results,strlen(results)-1,1) != ';'
				let results = results .';'
			endif

			let params = ''
			let doubleStarIndex = stridx(somepath,'**')
			if (doubleStarIndex >= 0)
				let splitStars = split(somepath,'\*\*')

				if len(splitStars) == 0
					let cleanpath = '.'
				elseif len(splitStars) > 2
					" TODO for double stars consider:
					" /some/path/**/that/goes/**/here
					" should result in:
					" find /some/path -type d -depth 1 -exec find {}/that/goes -name here
					"
					" Basically I think we can just do a nested find command to do that
					" here I guess we need a recursive function.
					throw "not implemented!"
				elseif len(splitStars) > 1
					let cleanpath = splitStars[0] .' -name '. substitute(splitStars[1],'/','','g')
				else
					let cleanpath = splitStars[0]
					if !s:PathExists(cleanpath)
						continue
					endif
				endif
				let results = results . a:find .' '. cleanpath
			elseif (stridx(somepath,'*') >= 0)
				let first_star = stridx(somepath,'*')
				if !s:PathExists(strpart(somepath,0,first_star))
					continue
				endif
				let results = results . a:find .' '. strpart(somepath,0,first_star)
				if (strpart(somepath,0,1) != '/')
					let params = '-wholename \*'. substitute(somepath,'*','\\*','g')
				else
					let params = '-wholename '. substitute(somepath,'*','\\*','g')
				endif
			else
        " TODO verify that the path actually exists
				" No * expander, so we don't need a find command
				if !s:PathExists(somepath)
					continue
				endif
				let results = results . a:find .' '. somepath .' -maxdepth 1'
			endif
			if (len(splitsuffixes) > 0)
				let firstsuffix = 0
				let allsuffixes = ''
				for suffix in splitsuffixes
					if (firstsuffix == 0)
						let firstsuffix = 1
					else
						let allsuffixes = allsuffixes .' -o'
					endif
					let allsuffixes = allsuffixes .' -name \*'. suffix
				endfor
				" allow both normal files and symbolic links
				" let results = results .' '. params .' \( -type f -o -type l \) -a \( '. allsuffixes .' \)'
				let results = results .' '. params .' -follow -type f -a \( '. allsuffixes .' \)'
			else
				let results = results .' '. params .' -follow -type f'
				"let results = results .' '. params .' \( -type f -o -type l \)'
			endif
		endfor
	else
		return 'echo hi'
	endif
	return results
endfunction

function! <SID>SearchKey(type,pattern)
	" make a key that is typed to the kind of search plugin and the ignorecase
	" setting (plus path/suffixes).
	if (g:LookupFileGrep_IgnoreCase == 1)
		return s:CurrentPathKey() . a:type . "-i" . a:pattern
	endif
	return s:CurrentPathKey() . a:type . a:pattern
endfunction

function! <SID>PathKey(somepath,suffixes)
	return a:somepath . a:suffixes
endfunction

function! <SID>CurrentPathKey()
	call s:CompileMatchesFile()
	return s:PathCaches[s:PathKey(s:SavedLookupPath,s:SavedLookupSuffixes)]
endfunction

function! <SID>CompileMatchesFile()
	" Compile a list of eligible files from the &path and &suffixesadd
	" and stick it into a:tagfile
	" Expects two script variables for the paths & suffixes:
	" s:SavedLookupPath
	" s:SavedLookupSuffixes

	if !exists('s:PathCaches')
		" dictionary of all cache files we've created.
		let s:PathCaches = {}
	endif
	let key = s:PathKey(s:SavedLookupPath,s:SavedLookupSuffixes)
	if !has_key(s:PathCaches,key)
		let newfile = tempname()
		let s:PathCaches[key] = newfile
		let command = s:CommandsForFind(s:SavedLookupPath,s:SavedLookupSuffixes,g:LookupFileGrep_UtilsBase ."find")
		echom "silent !(". command .') | uniq > '. newfile
		exec "silent !(". command .') | uniq > '. newfile
	endif
endfunction

function! <SID>MakeTagsFile(tagFile,fileList)
	" Put in the tags header at the top of the file,
	" and then convert the full path file names to "<filename> <fullpathname>"
	" format...sorted
	echom 'silent !(echo "\!_TAG_FILE_SORTED	2	/2=foldcase/"; (cat '. a:fileList
				\ '|'.g:LookupFileGrep_UtilsBase.'sed  -e "s/^\(.*\)\/\(.*\)$/\2	\1\/\2	1/" | sort -f)) > '. a:tagFile
	exec 'silent !(echo "\!_TAG_FILE_SORTED	2	/2=foldcase/"; (cat '. a:fileList
				\ '|'.g:LookupFileGrep_UtilsBase.'sed  -e "s/^\(.*\)\/\(.*\)$/\2	\1\/\2	1/" | sort -f)) > '. a:tagFile
endfunction

" Test functions:
" put your curser in the function somwhere and then type ":call VUAutoRun()"
" !!!Also check the PathExists so it returns true by default!!!
" Requires vimunit

function! TestPathFunctions()
	call VUAssertEquals(s:CommandsForFind('','','find'),'echo hi')

	call VUAssertEquals(s:CommandsForFind('/app/**','','find'),'find /app/  -follow -type f')
	call VUAssertEquals(s:CommandsForFind('**','','find'),'find .  -follow -type f')
	call VUAssertEquals(s:CommandsForFind('/app/**/pom.xml','','find'),'find /app/ -name pom.xml  -follow -type f')
	call VUAssertEquals(s:CommandsForFind('/app/**/pom.xml','.xml','find'),'find /app/ -name pom.xml  -follow -type f -a \(  -name \*.xml \)')

	" only supported by gnu find (wholename)?
	call VUAssertEquals(s:CommandsForFind('/app/*/anotherfolder','','find'),'find /app/ -wholename /app/\*/anotherfolder -follow -type f')
	call VUAssertEquals(s:CommandsForFind('app/*/anotherfolder','','find'),'find app/ -wholename \*app/\*/anotherfolder -follow -type f')
	" TODO technically this isn't the proper interpretation of /som/*/path/*
	" It is getting interpretted as if it meant /some/**/path/**
	call VUAssertEquals(s:CommandsForFind('/app/*/anotherfolder/to/*','','find'),'find /app/ -wholename /app/\*/anotherfolder/to/\* -follow -type f')

	" no stars equals no finds
	call VUAssertEquals(s:CommandsForFind('.','','find'),'find . -maxdepth 1  -follow -type f')
	call VUAssertEquals(s:CommandsForFind('/some/folder','','find'),'find /some/folder -maxdepth 1  -follow -type f')

	call VUAssertEquals(s:CommandsForFind('app/**,test/*/unit','.txt','find'),'find app/  -follow -type f -a \(  -name \*.txt \);find test/ -wholename \*test/\*/unit -follow -type f -a \(  -name \*.txt \)')
	call VUAssertEquals(s:CommandsForFind('.,app/**,test/*/unit','.rb,.rhtml','find'),'find . -maxdepth 1  -follow -type f -a \(  -name \*.rb -o -name \*.rhtml \);find app/  -follow -type f -a \(  -name \*.rb -o -name \*.rhtml \);find test/ -wholename \*test/\*/unit -follow -type f -a \(  -name \*.rb -o name \*.rhtml \)')
endfunction

"}}}
" Lookupfile plugin functions{{{

function! <SID>CompileFilesAndSearch(pattern)
	" Do a grep search and cache all the intermediate steps.
	" Note: takes into account g:LookupFileGrep_IgnoreCase variable
	" Returns: the tags format file of all matches.
	if !exists('s:GrepCaches')
		let s:GrepCaches = {}
	endif
	let grepKey = s:SearchKey('',a:pattern)
	if has_key(s:GrepCaches,grepKey)
		return s:GrepCaches[grepKey]
	endif
	let file = tempname()
	let s:GrepCaches[grepKey] = file
	let filterAnFormat = "| paste -d ' ' - - - - - - - - - - - - - - - | ".g:LookupFileGrep_UtilsBase."xargs -iXX sh -c \"grep -l "
	let grepParams = ' '
	if (g:LookupFileGrep_IgnoreCase == 1)
		let grepParams = '-i '
	endif
	let currentPathCache = s:SearchKey("<grep>",a:pattern)
	let grepPathCache = s:GetPathCache('<grep>',strpart(a:pattern,0,strlen(a:pattern)-1))
	" we have to make a new file b/c we haven't searched this term before:
	let file = tempname()
	let s:PathCaches[currentPathCache] = file
	echom 'silent !cat '. grepPathCache . filterAnFormat . grepParams .'\"'. a:pattern .'\" XX" > '. file
	exec 'silent !cat '. grepPathCache . filterAnFormat . grepParams .'\"'. a:pattern .'\" XX" > '. file
	let tagfile = tempname()
	let s:GrepCaches[grepKey] = tagfile
	call s:MakeTagsFile(tagfile,file)
	return tagfile
endfunction

function! <SID>GetPathCache(type,pattern)
	call s:CompileMatchesFile()
	" If this is based upon the last search then use the last searches file list
	" rather than the larger list of all eligible files.
	let key = s:SearchKey(a:type,a:pattern)
	if strlen(a:pattern) > 0 && has_key(s:PathCaches,key)
		" otherwise, use the subset of files from the previous search
		" as a starting point.
		return s:PathCaches[key]
	endif
	return s:CurrentPathKey()
endfunction

"
" ==============================================================================
"

function! RevertNotify()
	" For any custom definition this function lets you revert to the previous
	" (default) setting for searches after the custom one is used. (this is from
	" the example in the documentation for lookupfile).
	unlet g:LookupFile_LookupFunc g:LookupFile_LookupNotifyFunc
	let g:LookupFile_LookupFunc = g:SavedLookupFunc
	let g:LookupFile_LookupNotifyFunc = g:SavedLookupNotifyFunc
endfunction

function! MatchFunction(somepath,somesuffixes,lookupfunction,revertfunction,minPatLen)
	" Generic matching function used to setup the basic variables used during a
	" search function.
	let s:SavedLookupPath = a:somepath
	let s:SavedLookupSuffixes = a:somesuffixes
	unlet! s:SavedLookupFunc s:SavedLookupNotifyFunc
	let g:SavedLookupFunc = g:LookupFile_LookupFunc
	let g:SavedLookupNotifyFunc = g:LookupFile_LookupNotifyFunc
	unlet g:LookupFile_LookupFunc g:LookupFile_LookupNotifyFunc
	let g:LookupFile_LookupFunc = a:lookupfunction
	let g:LookupFile_LookupNotifyFunc = a:revertfunction
  let g:LookupFile_MinPatLength = a:minPatLen
	LookupFile
endfunction

" Grep match functions"{{{
function! GrepMatch(pattern)
	" LookupFile function that returns all files that have a:pattern inside of
	" them. This function uses the 'path' setting to determine which folders to
	" look in, and the 'suffixesadd' to determine which files to search. If
	" neither option is set, then the current path of VIM is used as the default
	" path.
	if !exists('s:LastPattern')
		let s:LastPattern = ''
	endif
	let s:LastPattern = a:pattern
	let cleanedPattern = substitute(a:pattern,'*','.*','g')
	let file = s:CompileFilesAndSearch(cleanedPattern)
	return TagFileMatch(file,".*")
endfunction

function! GrepNotify()
	call RevertNotify()
	" jump to the first instance of the search pattern and hilight all
	" instances:
	if (&ignorecase || g:LookupFileGrep_IgnoreCase == 1)
		exec "match Search /\\c". s:LastPattern ."/"
		exec "/\\c". s:LastPattern
	else
		exec "match Search /". s:LastPattern ."/"
		exec "/". s:LastPattern
	endif
endfunction

function! GrepLookupDefault()
	call GrepLookup(&path,&suffixesadd,g:LookupFile_MinPatLength)
endfunction

function! GrepLookup(somepath,somesuffixes,minPatLen)
	" GrepLookup command: this is all derived from the lookupfile
	" documentation.
	call MatchFunction(a:somepath,a:somesuffixes,'GrepMatch','GrepNotify',a:minPatLen)
endfunction
" "}}}
" Case LookupFile functions"{{{
function! BunnyCaseLookupMatch(pattern)
	let cleanedPattern = substitute(a:pattern,"\\(\\u\\)","\\1*","g")
	return CaseLookupMatch(cleanedPattern)
endfunction

function! CaseLookupMatch(pattern)
	if !exists('s:CaseLookupCaches')
		let s:CaseLookupCaches = {}
	endif
	let caseLookupKey = s:SearchKey('',a:pattern)
	if has_key(s:CaseLookupCaches,caseLookupKey)
		return TagFileMatch(s:CaseLookupCaches[caseLookupKey],".*")
	endif
	let currentPathCache = s:SearchKey("<case>",a:pattern)
	let casePathCache = s:GetPathCache('<case>',strpart(a:pattern,0,strlen(a:pattern)-1))
	let file = tempname()
	let s:PathCaches[currentPathCache] = file

	let cleanedPattern = substitute(a:pattern,'*','.*','g')
	let file = tempname()
	let s:PathCaches[currentPathCache] = file
	if (g:LookupFileGrep_IgnoreCase == 1)
		"echom 'silent !cat '. casePathCache .' | '.g:LookupFileGrep_UtilsBase.'sed -e "s/^\(.*\)\/\(.*\)$/\2	\1\/\2/" | grep -i "^'. cleanedPattern .'.*	" | cut -d "	" -f 2 > '. file
		exec 'silent !cat '. casePathCache .' | '.g:LookupFileGrep_UtilsBase.'sed -e "s/^\(.*\)\/\(.*\)$/\2	\1\/\2/" | grep -i "^'. cleanedPattern .'.*	" | cut -d "	" -f 2 > '. file
	else
		"echom 'silent !cat '. casePathCache .' | '.g:LookupFileGrep_UtilsBase.'sed -e "s/^\(.*\)\/\(.*\)$/\2	\1\/\2/" | grep "^'. cleanedPattern .'.*	" | cut -d "	" -f 2 > '. file
		exec 'silent !cat '. casePathCache .' | '.g:LookupFileGrep_UtilsBase.'sed -e "s/^\(.*\)\/\(.*\)$/\2	\1\/\2/" | grep "^'. cleanedPattern .'.*	" | cut -d "	" -f 2 > '. file
	endif
	let caseCacheFile = tempname()
	let s:CaseLookupCaches[caseLookupKey] = caseCacheFile
	call s:MakeTagsFile(caseCacheFile,file)
	return TagFileMatch(caseCacheFile,".*")
endfunction

function! CaseLookupFileDefault()
	call CaseLookupFile(&path,&suffixesadd,g:LookupFile_MinPatLength)
endfunction

function! BunnyCaseLookupFileDefault()
	call BunnyCaseLookupFile(&path,&suffixesadd,g:LookupFile_MinPatLength)
endfunction

function! CaseLookupFile(somepath,somesuffixes,minPatLen)
	" Just like the builtin 'LookupFile' except it
	" checks the 'g:LookupFileGrep_IgnoreCase' setting
	" while doing the search...also converts all '*' searches
	" to '.*' to speed up a search.
	call MatchFunction(a:somepath,a:somesuffixes,'CaseLookupMatch','RevertNotify',a:minPatLen)
endfunction

function! BunnyCaseLookupFile(somepath,somesuffixes,minPatLen)
	" For matching bunny case names, like: CCAR would match
	" CreditCardAuthResult.
	call MatchFunction(a:somepath,a:somesuffixes,'BunnyCaseLookupMatch','RevertNotify',a:minPatLen)
endfunction

"}}}
" Functions lookup functions {{{
function! FunctionLookupMatch(pattern)
	let cleanedPattern = substitute(a:pattern,'*','.*','g')
	if !exists('s:LastPattern')
		let s:LastPattern = ''
	endif
	let s:LastPattern = cleanedPattern

	" For the current file, generate ctags file, and present the user with a
	" drop down list of all functions in the file.
	if !exists('s:FunctionLookupTagsFile')
		let s:FunctionLookupTagsFile = ''
	endif
	if s:FunctionLookupTagsFile == s:FunctionLookupFileName
		let filteredList = []
		for entry in s:lastFunctionLookup
			if match(entry['word'],cleanedPattern) >= 0
				let filteredList += [entry]
			endif
		endfor
		return filteredList
	endif
	let s:FunctionLookupTagsFile = s:FunctionLookupFileName
	
	" TODO somehow I need to be able to get the completion menu to appear
	" automatically when the user hasn't even typed anything yet.

	" We want a mapping like this, kind of:
	" return map(matches, '{"word": v:val["name"],"abbr": v:val["name"], "menu": v:val["kind"]}')

	" the ctags command should be parsed manually, so we can parse out the function/method
	" name and then a corresponding line number (or matching string) so we can then jump
	" to the specific name with ease.
	" See the taglist.vim library for a good summary of how to do this quickly they got it
	" figured out pat.
	let cmd_output = system(g:LookupFileGrep_Ctags ." -f - --sort=yes --fields=nks --format=2 --excmd=pattern ". s:FunctionLookupFileName)
	if v:shell_error
		return ''
	endif
	if cmd_output == ''
		return ''
	endif

	" The following variables are used by LG_Parse_Tagline
	" This is entirely based on the taglist plugin (though simplified and
	" customized for my own lookup function)

	" just support the 'field' type tag:
	let s:ctags_flags = 'fm'
	let s:fidx = 'lookup'
	let s:tidx = 0

	" Process the ctags output one line at a time.
	call substitute(cmd_output, "\\([^\n]\\+\\)\n",
							\ '\=s:Tlist_Parse_Tagline(submatch(1))', 'g')

	" TODO take the results of the parsed tags file, and present it
	" return map(matches, '{"word": v:val["name"],"abbr": v:val["name"], "menu": v:val["kind"]}')
	" as a list to the user.
	let s:lastFunctionLookup = []
	let index = 0
	while index < s:tidx
		let index = index + 1
		let fidx_tidx = 's:tlist_' . s:fidx . '_' . index
    let ttype = s:Tlist_Extract_Tagtype({fidx_tidx}_tag)
		" let line = " ". s:Tlist_Extract_Tag_LNumber({fidx_tidx}_tag)
		let line = s:Tlist_Get_Tag_SearchPat('lookup', index)
		let line = strpart(line,4,len(line)-6)
    let fidx_ttype = 's:tlist_' . s:fidx . '_' . ttype
		let s:lastFunctionLookup += [eval('{ "word": "'. {fidx_tidx}_tag_name .'", "abbr": "'. {fidx_tidx}_tag_name .'", "menu": "'. line .'","index": '. index .'}')]
	endwhile

	" The following script local variables are no longer needed
	unlet! s:ctags_flags
	unlet! s:tidx
	unlet! s:fidx

	" At this point, we have the completed lookup list. Filter it and return.
	let filteredList = []
	for entry in s:lastFunctionLookup
		if match(entry['word'],cleanedPattern) >= 0
			let filteredList += [entry]
		endif
	endfor
	return filteredList
endfunction

" Tlist_Get_Tag_SearchPat
function! s:Tlist_Get_Tag_SearchPat(fidx, tidx)
    let tpat_var = 's:tlist_' . a:fidx . '_' . a:tidx . '_tag_searchpat'

    " Already parsed and have the tag search pattern
    if exists(tpat_var)
        return {tpat_var}
    endif

    " Parse and extract the tag search pattern
    let tag_line = s:tlist_{a:fidx}_{a:tidx}_tag
    let start = stridx(tag_line, '/^') + 2
    let end = stridx(tag_line, '/;"' . "\t")
    if tag_line[end - 1] == '$'
        let end = end -1
    endif
    let {tpat_var} = '\V\^' . strpart(tag_line, start, end - start) .
                        \ (tag_line[end] == '$' ? '\$' : '')

    return {tpat_var}
endfunction

" Tlist_Extract_Tagtype
" Extract the tag type from the tag text
function! s:Tlist_Extract_Tagtype(tag_line)
    " The tag type is after the tag prototype field. The prototype field
    " ends with the /;"\t string. We add 4 at the end to skip the characters
    " in this special string..
    let start = strridx(a:tag_line, '/;"' . "\t") + 4
    let end = strridx(a:tag_line, 'line:') - 1
    let ttype = strpart(a:tag_line, start, end - start)

    return ttype
endfunction

" Tlist_Extract_Tag_Scope
" Extract the tag scope from the tag text
function! s:Tlist_Extract_Tag_Scope(tag_line)
    let start = strridx(a:tag_line, 'line:')
    let end = strridx(a:tag_line, "\t")
    if end <= start
        return ''
    endif

    let tag_scope = strpart(a:tag_line, end + 1)
    let tag_scope = strpart(tag_scope, stridx(tag_scope, ':') + 1)

    return tag_scope
endfunction

function! s:Tlist_Extract_Tag_LNumber(tag_line)
    let start = strridx(a:tag_line, 'line:')
    let end = strridx(a:tag_line, "\t",start)
    if start == -1
        return 'nan'
    endif

		if end == -1
			let end = len(a:tag_line)
		endif

		"return strpart(strpart(a:tag_line, start),0,end-start)
		return strpart(a:tag_line, start,end-1)
endfunction

function! s:Tlist_Parse_Tagline(tag_line)
    if a:tag_line == ''
        " Skip empty lines
        return
    endif

    " Extract the tag type
    let ttype = s:Tlist_Extract_Tagtype(a:tag_line)

    if ttype == ''
        " Line is not in proper tags format
        return
	endif

    " make sure the tag type is supported
    if stridx(s:ctags_flags, ttype) == -1
        " Tag type is not supported
        return
    endif

    " Update the total tag count
    let s:tidx = s:tidx + 1

    " The following variables are used to optimize this code.  Vim is slow in
    " using curly brace names. To reduce the amount of processing needed, the
    " curly brace variables are pre-processed here
    let fidx_tidx = 's:tlist_' . s:fidx . '_' . s:tidx
    let fidx_ttype = 's:tlist_' . s:fidx . '_' . ttype

    " Update the count of this tag type
		if !exists(fidx_ttype . '_count')
			let {fidx_ttype}_count = 0
		endif
    let ttype_idx = {fidx_ttype}_count + 1
    let {fidx_ttype}_count = ttype_idx

    " Store the ctags output for this tag
    let {fidx_tidx}_tag = a:tag_line

    " Store the tag index and the tag type index (back pointers)
    let {fidx_ttype}_{ttype_idx} = s:tidx
    let {fidx_tidx}_ttype_idx = ttype_idx

    " Extract the tag name
    let tag_name = strpart(a:tag_line, 0, stridx(a:tag_line, "\t"))

    " Extract the tag scope/prototype
    if g:Tlist_Display_Prototype
        let ttxt = '    ' . s:Tlist_Get_Tag_Prototype(s:fidx, s:tidx)
    else
        let ttxt = '    ' . tag_name

        " Add the tag scope, if it is available and is configured. Tag
        " scope is the last field after the 'line:<num>\t' field
        if g:Tlist_Display_Tag_Scope
            let tag_scope = s:Tlist_Extract_Tag_Scope(a:tag_line)
            if tag_scope != ''
                let ttxt = ttxt . ' [' . tag_scope . ']'
            endif
        endif
    endif

    " Add this tag to the tag type variable
		if !exists(fidx_ttype)
			let {fidx_ttype} = ''
		endif
    let {fidx_ttype} = {fidx_ttype} . ttxt . "\n"

    " Save the tag name
    let {fidx_tidx}_tag_name = tag_name
endfunction

function! FunctionLookupNotify()
	call RevertNotify()
	unlet g:LookupFile_LookupAcceptFunc s:FunctionLookupFileName
	let g:LookupFile_LookupAcceptFunc = s:SavedLookupAcceptFunc

	if !exists('s:LastPattern')
		return
	endif

	let filteredList = []
	for entry in s:lastFunctionLookup
		if match(entry['word'],g:matchingPattern) >= 0
			let tagpat = s:Tlist_Get_Tag_SearchPat('lookup', entry['index'])
			if tagpat == ''
					return
			endif

			" Add the current cursor position to the jump list, so that user can
			" jump back using the ' and ` marks.
			mark '

			silent call search(tagpat, 'w')

			" Bring the line to the middle of the window
			normal! z.

			" If the line is inside a fold, open the fold
			if foldclosed('.') != -1
					.foldopen
			endif
			return
		endif
	endfor
endfunction

function! FunctionLookupAccept(splitWin, key)
  let nextCmd = "\<C-R>=(getline('.') == lookupfile#lastPattern)?\"\\<C-N>\":''\<CR>"
  let acceptCmd = "\<Esc>:AddPattern\<CR>:let g:matchingPattern = getline('.')\<CR>:call lookupfile#CloseWindow()\<CR>:call FunctionLookupNotify()\<CR>"
	return nextCmd.acceptCmd
endfunction

function! FunctionLookupFileDefault()
	call FunctionLookupFile(@%,-1)
endfunction

function! FunctionLookupFile(somefile,minPatLen)
	" This kind of works: 
	" map <F3> i<C-R>=FunctionLookupFileDefault()\<CR>
	if !exists('s:FunctionLookupFileName')
		let s:FunctionLookupFileName =''
	endif
	let s:FunctionLookupFileName = a:somefile
	let s:SavedLookupAcceptFunc = g:LookupFile_LookupAcceptFunc
	let g:LookupFile_LookupAcceptFunc = 'FunctionLookupAccept'
	call MatchFunction(&path,&suffixesadd,'FunctionLookupMatch','FunctionLookupNotify',a:minPatLen)
	call FunctionLookupMatch('')
	call complete(1,s:lastFunctionLookup)
endfunction
" }}}
" }}}

" vim: set ai fdm=marker:
