" vim:set ft=vim et sts=4 sw=4 ts=4 tw=78:
"
" pi2md.vim - Paste Image to markdown
" Maintainer:    Vincent Wancocoding  <http://cocoding.cc>
" Create date:		Sep 28, 2020
" Update date:		Oct 20, 2020
"
" Settings Example 
" more example, please see readme
"
"
" let g:pi2mdSettings = {
" \ 'debug': 1,
" \ 'storage': 0,
" \ 'storage_local_position_type': 0,
" \ 'storage_local_dir_name': 'images',
" \ 'storage_local_absolute_path': '/User/yourname/your_images_path',
" \ 'storage_local_prefer_relative_path': 1,
" \ 'storage_cloud_tool': 'picgo-core',
" \ 'storage_cloud_picgocore_path': 
" \     'd:\develop\Scoop\apps\nodejs-lts\current\bin\picgo.cmd'
" }




" Configuration

" the configuration constraint
let s:pi2mdConfigConstraint = {
	\ 'debug': {
	\	'legalRange': [0, 1], 
	\	'default': 1, 
	\	'required': 1,
	\	'errorMsg': 'the value of debug config must be 0 or 1'}, 
	\ 'storage': { 
	\	'legalRange': [0, 1], 
	\	'default': 0, 
	\	'required': 1,
	\	'errorMsg': 'the value of storage config must be 0 or 1'},
	\ 'storage_local_position_type': {
	\	'legalRange': [0, 1], 
	\	'default': 0, 
	\	'required': 1,
	\	'errorMsg': 'the value of local position type config must be 0 or 1'},
	\ 'storage_local_prefer_relative_path': {
	\	'legalRange': [0, 1], 
	\	'default': 1, 
	\	'required': 0,
	\	'errorMsg': 'the value of use relative path config must be 0 or 1'},
	\ 'storage_cloud_tool': {
	\	'legalRange': ['picgo-core', 'picgo', 'upic'], 
	\	'default': 'picgo-core', 
	\	'required': 0,
	\	'depends': {'itemKey': 'storage', 'itemVal': 1},
	\	'errorMsg': 'the value of cloud lib config must be one of picgo-core,
			\ picgo or upic'},
	\ 'storage_cloud_picgocore_path': {
	\	'default': 'picgo-core', 
	\	'required': 0,
	\	'isPath': 1,
	\	'depends': {'itemKey': 'storage_cloud_tool', 'itemVal': 'picgo-core'},
	\	'errorMsg': 'you must define your picgo-core bin path,
			\ if you use cloud by picgo-core'}
\ }


let s:Errors = {
	\ 'E-PIM-10': 'Configuration error',
	\ 'E-PIM-11': 'Configuration item error',
	\ 'E-PIM-12': 'There are no images in your system clipbord!',
	\ 'E-PIM-13': 'The python module PIL could not found,
		\ Please install it with pip',
	\ 'E-PIM-14': 'Your system does not have python3 installed or
		\ python3 and python3x.dll are not in the PATH',
	\ 'E-PIM-15': 'Sorry, The filetype of current buffer
		\ does not support right now'
	\ }

" ==========================================================
" Init Variables " 
" ==========================================================

let s:settings = {}

function! s:settings.initPi2md() dict
	try
		" add more variables
		call self.checkConfiguration()
		call self.checkPy()
		call s:utilityTools.detectOS()
		let g:pi2mdSettings['os'] = s:os

		" get the pi2md plugin root absolute path
		let s:pi2md_root_full_path = fnamemodify(resolve(
					\ expand('<sfile>:p')), ':h:h')
		let g:pi2mdSettings['pi2md_root'] = s:pi2md_root_full_path
	catch /.*/
		call s:logger.errorMsg('Caught "' . v:exception . '" in [iniPi2md]')
		throw 'E-PIM-10'
	endtry
endfunction

function s:settings.checkPy3() dict
	if !has('python3')
		throw 'E-PIM-14'
	endif
	" check module
	try
python3 << EOF
import PIL
EOF
	catch 'Vim(python3):ModuleNotFoundError: No module named \'PIL\''
		throw 'E-PIM-13'
	endtry
endfunction

" make sure all configuration is right
function! s:settings.checkConfiguration() dict
	if !exists('g:pi2mdSettings')
		" setting some default configuration
		let g:pi2mdSettings = {
			\ 'debug': 1,
			\ 'storage': 0,
			\ 'storage_local_position_type': 0,
			\ 'storage_local_dir_name': 'images',
			\ 'storage_local_prefer_relative_path': 1}
	else
		" check configuration , make sure all settings are correct
		for ckey in keys(s:pi2mdConfigConstraint)
			try
				call self.checkConfigItem(ckey)
			catch /.*/ 
				call s:logger.errorMsg('Caught "' . v:exception .
					\ '" in [checkConfiguration], error item is' . ckey)
				throw 'E-PIM-11'
			endtry
		endfor
	endif
endfunction

function s:settings.checkConfigItem(itemKey) dict
	let settingConstraint = s:pi2mdConfigConstraint[a:itemKey]
	" check if exists in global configuration
	" chech required and depends
	let hasError = 0
	" =================== check the config not defined
	if !has_key(g:pi2mdSettings, a:itemKey) && settingConstraint.required == 1
		" set default value if not exist
		if has_key(settingConstraint, 'default')
			let g:pi2mdSettings[a:itemKey] = settingConstraint.default
		else
			let hasError = 1
		endif
	elseif !has_key(g:pi2mdSettings, a:itemKey)
		\ && settingConstraint.required == 0
		" check depends
		if has_key(settingConstraint, 'depends')
			" get depends
			let depends = settingConstraint.depends
			" get depend key 
			let dependKey = depends['itemKey']
			let dependVal = depends['itemVal']
			" if depends defined , item must not be empty
			if has_key(g:pi2mdSettings, dependKey) 
				if g:pi2mdSettings[dependKey] == dependVal
					let hasError = 1
				endif
			endif
		endif
	" ================== check the config defined
	elseif has_key(g:pi2mdSettings, a:itemKey)
		" varify its legitimacy
		let userConfigItem = g:pi2mdSettings[a:itemKey]
		" check value range
		if has_key(settingConstraint, 'legalRange')
			let legalRang = settingConstraint.legalRange
			if index(legalRang, userConfigItem) == -1
				let hasError = 1
			endif
		endif
		" check path exist
		if has_key(settingConstraint, 'isPath')
			if empty(glob(fnameescape(userConfigItem)))
				let hasError = 1
			endif
		endif
	endif
	if hasError == 1
		call s:logger.errorMsg(settingConstraint.errorMsg)
	endif
endfunction

function! s:settings.getSetting(key) dict
	if !has_key(g:pi2mdSettings, a:key)
		s:logger.errorMsg(a:key . ' does not exist, 
			\ please define it in your rc file')
	else
		return g:pi2mdSettings[a:key]
	endif
endfunction

" ==========================================================
" Utility Func
" ==========================================================

let s:logger = {}

function! s:logger.getPrefix(flag) dict
	return '[Pi2md]-[' . a:flag . ']-[' . strftime('%d/%m/%y %H:%M:%S') . '] '
endfunction

function! s:logger.errorMsg(msg) dict
	echohl ErrorMsg | echom self.getPrefix('ERROR') . a:msg | echohl None
endfunction

function! s:logger.warningMsg(msg) dict
	echohl WarningMsg | echom self.getPrefix('WARNING') . a:msg | echohl None
endfunction

function s:logger.debugMsg(msg) dict
	if g:pi2mdSettings['debug'] == 1
		echohl None | echom self.getPrefix('DEBUG') . a:msg
	endif
endfunction


let s:utilityTools = {}

function s:utilityTools.caught() dict
	let catchErr = v:exception
	if has_key(s:Errors, catchErr)
		call s:logger.errorMsg(s:Errors[catchErr])
	else
		call s:logger.errorMsg('Caught "' . v:exception . '"')
	endif
endfunction

function! s:utilityTools.uuid4() dict

python3 << EOF
import uuid
uuid_string = str(uuid.uuid4())
EOF
	" let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
	" return l:new_random
	let uuid_string = py3eval('uuid_string')
	let ts_string = strftime('%Y-%m-%d-%H-%M-%S')
	let new_random = uuid_string . '-' . ts_string
	return new_random
endfunction

" check windows subsystem for linux
function! s:utilityTools.isWSL() dict
    let lines = readfile('/proc/version')
    if lines[0] =~ 'Microsoft'
        return 1
    endif
    return 0
endfunction

function! s:utilityTools.detectOS() dict
	if !exists('s:os')
		if has('win64') || has('win32') || has('win16')
			let s:os = 'Windows'
			let s:separator_char = '\'
		else
			let s:separator_char = '/'
			let s:os = substitute(system('uname'), '\n', '', '')
		endif
	endif
endfunction

" Deprecated use command args instead
function! s:utilityTools.inputName() dict
    call inputsave()
    let name = input('Image name: ')
    call inputrestore()
    return name
endfunction


" ==========================================================
" File system utils
" ==========================================================

let s:fileHandler = {}

" translate absolute path to relative path
function s:fileHandler.getRelativePath(img_path) dict
	let current_file_header_path = expand('%:p:h')
	let file_path_list = split(current_file_header_path, s:separator_char)
	let img_name = fnamemodify(a:img_path, ':p:t')
	let img_file_header_path = fnamemodify(a:img_path, ':p:h')
	let img_path_list = split(img_file_header_path, s:separator_char)
	let loop_index = 0
	let not_equal_path_index = 0
	call s:logger.debugMsg('current dir : ' . current_file_header_path)
	call s:logger.debugMsg('image save dir : ' . img_file_header_path)
	for path_i in img_path_list
		if loop_index == (len(file_path_list) - 1) 
			\ && path_i ==# file_path_list[loop_index]
			let img_left_start_index = loop_index + 1
			let img_left_path_list = img_path_list[img_left_start_index:]
			let img_left_path_string = join(img_left_path_list,
				\ s:separator_char)
			let img_relative_path = img_left_path_string . 
				\ s:separator_char . img_name
			return img_relative_path
		endif
		
		if s:os == 'Windows'
			if path_i !=? file_path_list[loop_index]
				let not_equal_path_index = loop_index
				break
			endif
		else
			if path_i !=# file_path_list[loop_index]
				let not_equal_path_index = loop_index
				break
			endif
		endif	
		let loop_index += 1
	endfor
	let img_nomatch_path_counts = len(img_path_list) - not_equal_path_index
	" return absolute path if not match path count greater then 4
	" if nomatch_path_counts == 
	" 	return a:img_path
	" endif
	let file_nomatch_path_count = len(file_path_list) - not_equal_path_index
	let up_dir_loop_index = 0
	let up_dir_string = ''
	while up_dir_loop_index < file_nomatch_path_count
		let up_dir_string .= '..' . s:separator_char
		let up_dir_loop_index += 1
	endwhile
	let img_left_path_list = img_path_list[not_equal_path_index:]
	let img_left_path_string = join(img_left_path_list, s:separator_char)
	let img_relative_path = up_dir_string . img_left_path_string 
		\ . s:separator_char . img_name
	return img_relative_path
endfunction

" convert the path to the final version, depending on your configuration file
" config: storage_local_prefer_relative_path
function! s:fileHandler.getLocalStoragePath(local_full_path) dict
	if s:settings.getSetting('storage_local_prefer_relative_path') == 0
		call s:logger.debugMsg('local storage use absolute path')
		return a:local_full_path
	else
		" try to use relative path
		" let article_full_parent_path = expand('%:p:h')
		" get current working dir
		" let current_working_dir = getcwd()
		" let article_parent_dir = expand('%:h')
		" execute 'lcd ' . article_parent_dir
		" let image_full_parent_path = fnamemodify(a:local_full_path, ':.')	
		" execute 'lcd ' . current_working_dir
		call s:logger.debugMsg('local storage use relative path')
		return self.getRelativePath(a:local_full_path)
	endif
endfunction

" copy file from one path to another,
" del_source will decide whether to delete the 
" source file
function! s:fileHandler.copyFile(source, dest, del_source=1) dict

python3 << EOF
import shutil

delete_source = vim.eval('a:del_source')
if delete_source == 1:
	shutil.move(vim.eval('a:source'), vim.eval('a:dest'))
else:
	shutil.copyfile(vim.eval('a:source'), vim.eval('a:dest'))
EOF

endfunction


" ==========================================================
" markup language tools
" ==========================================================

let s:markupLang = {}

" get current file markup language type
" so far from now, this plugin support markdown, reStructuredText and Vimwiki
function! s:markupLang.detectMarkupLanguage() dict
	let file_type = &filetype
	if file_type ==? 'markdown' || file_type ==? 'rst'
		return file_type
	endif
	let file_postfix = expand('%:e')
	if file_postfix ==? 'wiki'
		return 'vimwiki'
	endif
	throw 'E-PIM-15'
endfunction

" insert lint for different markup language
function! s:markupLang.insertImageLink(img_url) dict
	let file_type = self.detectMarkupLanguage()
	if file_type ==? 'markdown'
		execute 'normal! i![I'
		let ipos = getcurpos()
		execute 'normal! amage](' . a:img_url . ')'
		call setpos('.', ipos)
		redraw | echo 'please enter the title of this image...'
		execute 'normal! ve\<C-g>'
	elseif file_type ==? 'rst'
		execute 'normal! i!.. |I'
		let ipos = getcurpos()
		execute 'normal! amage| image:: ' . a:img_url
		call setpos('.', ipos)
		redraw | echo 'please enter the title of this image...'
		execute 'normal! ve\<C-g>'
	elseif file_type ==? 'vimwiki'
		let vimwiki_flag = ''
		if g:pi2mdSettings['storage'] == 0
			let vimwiki_flag = 'file:'
		endif
		execute 'normal! i!{{' . vimwiki_flag . a:img_url . '}}'
	endif
	return
endf


" ==========================================================
" Clipboard Tools
" ==========================================================

let s:clipboardTools = {}

function! s:clipboardTools.getClipBoardImageAndSave(save_path) dict
	let save_to = fnameescape(a:save_path)
	try
python3 << EOF
import vim
from PIL import ImageGrab
tmpimg = ImageGrab.grabclipboard()
if tmpimg is None:
	no_image_in_clip = 1
else:
	no_image_in_clip = 0
	tmpimg.save(vim.eval('save_to'), 'PNG', compress_level=9)
EOF
	catch 'Vim(python3):ModuleNotFoundError: No module named \'PIL\''
		throw 'E-PIM-13'
	catch /^Vim\%((\a\+)\)\=:E370:/
		throw 'E-PIM-14'
	endtry

	let py_fun_error = py3eval('no_image_in_clip')
	if py_fun_error == 1
		call s:logger.warningMsg('No image in your system clipboard!')
		throw 'E-PIM-12'
	endif
	return a:save_path
endfunction


function! s:clipboardTools.getAndSaveClipBoardImageTemporary() dict
	" get current dir and temp file_name
	let temp_file_name = s:utilityTools.uuid4() . '.png'
	let temp_path = expand('%:p:h')
	let temp_img_full_path = temp_path . s:separator_char . temp_file_name
	return s:clipboardTools.getClipBoardImageAndSave(temp_img_full_path)
endfunction



" ==========================================================
" 3rd part cloud lib functions
" ==========================================================

" ------ picgo-core functions



" ------ picgo functions


" ------ upic functions



" ====== Local storage

let s:localStorage = {}

function! s:localStorage.saveToLocalStorage(source) dict
	" get file name from source
	let file_name = fnamemodify(a:source, ':p:t')
	let file_dest_path = self.buildLocalStorageParentPath() 
		\ . s:separator_char . file_name
	call s:fileHandler.copyFile(a:source, file_dest_path)
	call s:logger.debugMsg('The final image local path is ' . file_dest_path)
	let markup_link_url = s:fileHandler.getLocalStoragePath(file_dest_path)
	return markup_link_url
endfunction

" build the local storage real path , not the same with temporary path
function! s:localStorage.buildLocalStorageParentPath() dict
	if s:settings.getSetting('storage_local_position_type') == 0
		" use current dirctory
		let local_save_parent_path = expand('%:p:h') . s:separator_char . 
			\ s:settings.getSetting('storage_local_dir_name')
	else
		" use absolute path for local storage
		let local_save_parent_path = 
			\ settings.getSetting('g:pi2md_localstorage_path')
	endif
	" make dir if not exists
	if !isdirectory(local_save_parent_path)
        call mkdir(local_save_parent_path)
    endif
	if s:os == 'Darwin'
        return local_save_parent_path
    else
        return fnameescape(local_save_parent_path)
    endif

endfunction

" ====== Cloud storage

let s:cloudStorage = {}

function s:cloudStorage.saveToCloudStorage(source) dict

	
endfunction


" ==========================================================
" Paste from clipboard 
" ==========================================================

function! s:pasteImageFromClipboard()
	" save image to temp file
	let temp_img_file = s:clipboardTools.getAndSaveClipBoardImageTemporary()
	" upload to cloud or save to local
	let final_img_url = 'your link'
	if s:settings.getSetting('storage') == 0
		" local storage
		call s:logger.debugMsg('paste from clipboard to local storage')
		let final_img_url = s:localStorage.saveToLocalStorage(temp_img_file)
	elseif s:settings.getSetting('storage') == 1
		call s:logger.debugMsg('paste from clipboard to cloud storage')
		" cloud storage
		let final_img_url = s:cloudStorage.saveToCloudStorage(temp_img_file)
	endif
	" write link for markup language
	call s:markupLang.insertImageLink(final_img_url)	
	return
endfunction



" ==========================================================
" Paste from Remote Url 
" ==========================================================

function! s:pasteImageFromRemoteUrl()
	" save image to a temp file
endfunction

" ==========================================================
" Paste from local
" ==========================================================


function! s:pasteImageFromLocalPath()
	" 
endfunction


" ==========================================================
" Main function and commands
" ==========================================================

function! pi2md#Pi2md(flag='c', item='') 
	try
		call s:settings.initPi2md()
		if a:flag ==? 'c'
			call s:logger.debugMsg('paste image from your clipboard start!')
			call s:pasteImageFromClipboard()
		elseif a:flag ==? 'p'
			call s:logger.debugMsg(
				\ 'paste image from your local file system start!')
		elseif a:flag ==? 'r'
			call s:logger.debugMsg('paste image from a remote url start!')
		endif
	catch
		call s:utilityTools.caught()
	finally
		call s:logger.debugMsg('paste image finish!')
	endtry
endfunction

" ==========================================================
" Bind Commands
" ==========================================================

command! -nargs=* Pi2md call pi2md#Pi2md(<f-args>)

