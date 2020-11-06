if exists("b:did_autoload_pi2md")
    finish
endif
let b:did_autoload_pi2md = 1
" the max attempts to delete a temp file
let s:max_attempts = 3


py3 import uuid
py3 from pi2md import download_image, detect_picgo_api_server
py3 from pi2md import copy_file, remove_file, picgo_upload, save_clipboard
py3 from pi2md import simple_hash_text, detect_file

" temp_files format
" [{
"	'uid': 'ed3fa20cff286622c06355dba8d57d75',
"	'entity': {'fname': '/the/file/path', 'attempts': 2, 'success': 0}
" }]
"
let b:temp_files = []


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
	\	'default': 'picgo', 
	\	'required': 0,
	\	'isPath': 1,
	\	'depends': {'itemKey': 'storage_cloud_tool', 'itemVal': 'picgo-core'},
	\	'errorMsg': 'you must define your picgo-core bin path,
			\ if you use cloud by picgo-core'},
    \ 'storage_cloud_picgoapp_node_path': {
        \ 'default': 'node',
        \ 'required': 0,
        \ 'isPath': 1,
        \ 'depends': {'itemKey': 'storage_cloud_tool', 'itemVal': 'picgo'},
        \ 'errorMsg': 'you must define the right nodejs bin path,
            \ if you want to use picgo app'},
    \ 'storage_cloud_picgoapp_api_server_port': {
        \ 'default': '36677',
        \ 'required': 0,
        \ 'depends': {'itemKey': 'storage_cloud_tool', 'itemVal': 'picgo'},
        \ 'errorMsg': 'the picgo api server default port is [36677],
            \ if not, please set port in your settings!'}
\ }


let s:Errors = {
	\ 'E-PIM-10': 'Configuration error',
	\ 'E-PIM-11': 'Configuration item error',
	\ 'E-PIM-12': 'There are no images in your system clipbord!',
	\ 'E-PIM-13': 'The python module PIL could not found,
	\   Please install it with pip',
	\ 'E-PIM-14': 'Your system does not have python3 installed or
	\   python3 and python3x.dll are not in the PATH',
	\ 'E-PIM-15': 'Sorry, The filetype of current buffer
	\   does not support right now',
    \ 'E-PIM-16': 'An error occurred while proccessing files',
    \ 'E-PIM-17': 'Upload to the cloud by picgo-core failed, 
    \   please see the log messages.',
    \ 'E-PIM-18': 'Picgo App upload failed, please check your picgo config,
    \   or report issue',
    \ 'E-PIM-19': 'Picgo App upload failed',
    \ 'E-PIM-20': 'Invalid argument for Pi2md!',
    \ 'E-PIM-21': 'The image file does not exist!',
    \ 'E-PIM-22': 'The picgo server is not available,
    \   please check your settings',
    \ 'E-PIM-23': 'Error occurred when execute system cmd!',
    \ 'E-PIM-24': 'Error occurred when execute systemlist cmd!',
    \ 'E-PIM-25': 'File path error',
    \ 'E-PIM-26': 'Error occurred when download image from remote'
	\ }

" ==========================================================
" File class 
" ==========================================================

" File Path Class
let s:FilePathWrapper = {
    \   'originPath': '',
    \   'escapePath': '',
    \   'isPath': 1
    \ }

" get file path or url
function! s:FilePathWrapper.getPath() dict
    if self.isPath == 0
        return originPath
    else
        if s:settings.getSetting('os') !=? 'Darwin'
            return self.originPath
        endif
        if self.escapePath != ''
            return self.escapePath
        else
            let self.escapePath = fnameescape(self.originPath)
            return self.escapePath
        endif
    endif
endfunction

function! s:FilePathWrapper.getPostfix() dict
	let path_list = split(self.originPath, '\.')
	let postfix = path_list[-1]
	return postfix
endfunction


" ==========================================================
" delete file with job
" ==========================================================


function! s:getTempEntity(filePath)
	py3 vim.command('let l:uid = "%s"' % 
		\ simple_hash_text(vim.eval('a:filePath')))
	for file_entity in b:temp_files
		if file_entity.uid == l:uid
			return file_entity
		endif
	endfor
	let temp_file_entity = {
		\ 'uid': l:uid,
		\ 'entity': {'fname': a:filePath, 'attempts': 0,
		\			 'success': 0}
		\ }
	let b:temp_files += [temp_file_entity]
	return temp_file_entity
endfunction

function! s:removeTempEntity(file_path)
	py3 vim.command('let l:uid = "%s"' % 
		\ simple_hash_text(vim.eval('a:file_path')))
	for file_entity in b:temp_files
		if file_entity.uid == l:uid
			call remove(b:temp_files, index(b:temp_files, file_entity))
		endif
	endfor
endfunction

function! s:deleteFile(filePath)
	let file_entity = s:getTempEntity(a:filePath)
	let l:args = []
	let l:args += split(&shell)
	let l:args += split(&shellcmdflag)
	if s:settings.getSetting('os') == 'windows'
	" if has('win32') || has('win64')
		let l:args += ['cmd', '/c']
		let l:args += ['del']
		let l:args += ['/f']
	else
		let l:args += ['rm']
		let l:args += ['-f']
	endif
	" let delCmd = 'del /f d:\test2.txt'
	let l:args += [a:filePath]
	" \	'err_cb': function('s:delete_on_error'),
	let delJobOptions = {
	\	'callback': function('s:delete_callback'),
	\	'close_cb': function('s:delete_on_close'),
	\	'exit_cb': function('s:delete_on_job_exit'),
	\	'out_io': 'pipe',
	\	'in_io': 'null',
	\	'err_io': 'pipe',
	\	'out_mode': 'nl',
	\	'err_mode': 'nl',
	\	'stoponexit': 'term',
	\ }
	let f_info = file_entity['entity']
	let f_info['attempts'] = f_info['attempts'] + 1
	if f_info['attempts'] <= s:max_attempts
		let file_entity['entity'] = f_info
		call s:removeTempEntity(f_info['fname'])	
		let b:temp_files += [file_entity]
		call s:logger.debugMsg('delete file ' . a:filePath
			\ . ' attempts: ' . f_info['attempts'])
		let s:delJob = job_start(l:args, delJobOptions)
		" let l:success = (job_status(s:delJob) != 'fail')? 1 : 0
	else
		call s:logger.debugMsg('max retry, no more attempts to delete file '
			\ . f_info['fname'])
		call s:show_delete_error_in_qf(f_info['fname'])
		call s:removeTempEntity(f_info['fname'])	
	endif
endfunction

" on window, it can not be detect when the file is locked
function! s:CheckFileDeleted(file_path)
	let l:fp = a:file_path
	if has('win32') || has('win64')
		let l:fp = fnameescape(a:file_path)
	endif
	py3 vim.command('let l:f_exist = "%d"' % 
		\ detect_file(vim.eval('l:fp')))
	if l:f_exist == 1
		return 0
	endif
	return 1
	" echom empty(glob(l:fp))
	" if empty(glob(l:fp))
	" 	return 1
	" endif
	" return 0
endfunction

function! s:CheckDeleteJobResult(jobref)
	" let l:del_job = ch_getjob(a:channel)
	let l:del_job_info = job_info(a:jobref)
	let l:cmd = del_job_info['cmd']
	let l:file_path = cmd[-1]
	" remove success, now pop item
	let l:file_deleted = s:CheckFileDeleted(l:file_path)
	if l:file_deleted == 1
		call s:logger.debugMsg('delete temp file success!')
		call s:removeTempEntity(l:file_path)
	else
		" retry delete file
		sleep 3000m
		call s:deleteFile(l:file_path)
	endif
endfunction

" Deprecated
function! s:delete_on_error(channel, msg)
	call s:logger.debugMsg('error on delete temp file :' . a:msg)
endfunction

function! s:delete_callback(channel, text)
	" if type(a:text) != 1
	" 	return
	" endif
	" echom 'callback: ' . a:text
	" let s:async_output[s:async_head] = a:text
	" let s:async_head += 1
	" if s:async_congest != 0
	" 	call s:AsyncRun_Job_Update(-1)
	" endif
endfunc

function! s:delete_on_job_exit(job, message)
	" echom 'job exit, now check delete result'
	" echom 'exit : ' . a:message
endfunc

function! s:delete_on_close(channel)
	" echom 'channel close, now checking undeleted files...'
	" rerun all job not delete suceess
	let ch_job = ch_getjob(a:channel)
	call s:CheckDeleteJobResult(ch_job)	
	" for file_entity in b:temp_files
	" 	let f_info = file_entity['entity']
	" 	let is_success = f_info['success']
	" 	let attempts = f_info['attempts']
	" 	if is_success == 0 && attempts < s:max_attempts
	" 		" restart job
	" 		call s:deleteFile(f_info['fname'])
	" 	elseif attempts >= s:max_attempts
	" 		" show in quickfix and remove from dict
	" 		echom 'max retry, ignore'
	" 		call s:show_delete_error_in_qf(f_info['fname'])
	" 		call s:removeTempEntity(f_info['fname'])
	" 	endif
	" endfor
endfunction

function! s:show_delete_error_in_qf(filePath)
	let b:bnr = bufnr('%')
	" let b:qfid = ''
	let qf_list = []
	" if !exists('b:qfid')
	" 	let action = ' '
	" endif
	let qf_item = [{
		\	'bufnr': b:bnr,
		\	'text': 'delete temp file failed, please do it yourself later'
		\		. ', the path is: [' . a:filePath . ']',	
		\	'type': 'W'
		\ }]
	" let qf_item += [{
	" 	\	'bufnr': b:bnr,
	" 	\	'text': 'File Path : ' . a:filePath,	
	" 	\	'type': 'W'
	" 	\ }]
	let qf_list += qf_item
	call setqflist(qf_list, 'a')
	redraw | keepalt exec 'botright copen'
	keepalt wincmd k
endfunction

function s:DeleteTempFile(filePath)
	call s:deleteFile(a:filePath)
endfunction


" ==========================================================
" Init Variables " 
" ==========================================================
" let s:scriptRoot = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')

let s:settings = {}

function! s:settings.initPi2md() dict
	try
		" add more variables
        call s:settings.initSettings()
		call self.checkConfiguration()
		call self.checkPy3()

		" get the pi2md plugin root absolute path
		" let s:pi2md_root_full_path = fnamemodify(resolve(
		" 			\ expand('<sfile>:p')), ':h:h')
		" let g:pi2mdSettings['pi2md_root'] = s:scriptRoot
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


function! s:settings.initSettings() dict
	if !exists('g:pi2mdSettings')
		" setting some default configuration
		let g:pi2mdSettings = {
			\ 'debug': 1,
			\ 'storage': 0,
			\ 'storage_local_position_type': 0,
			\ 'storage_local_dir_name': 'images',
			\ 'storage_local_prefer_relative_path': 1}
    endif
    let g:pi2mdSettings['os'] = s:utilityTools.detectOS()
endfunction

" make sure all configuration is right
function! s:settings.checkConfiguration() dict
    " check configuration , make sure all settings are correct
    for ckey in keys(s:pi2mdConfigConstraint)
        try
            call self.checkConfigItem(ckey)
        catch /.*/ 
            call s:logger.errorMsg('Caught "' . v:exception .
                \ '" in [checkConfiguration], error item is: ' . ckey)
            throw 'E-PIM-11'
        endtry
    endfor
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
                    if has_key(settingConstraint, 'default')
                        let g:pi2mdSettings[a:itemKey] = settingConstraint.default
                    else
                        let hasError = 1
                    endif
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
            let filePathObj = copy(s:FilePathWrapper)
            let filePathObj.originPath = userConfigItem
			if empty(glob(filePathObj.getPath()))
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
		call s:logger.errorMsg(a:key . ' does not exist, 
			\ please define it in your rc file')
	else
		return g:pi2mdSettings[a:key]
	endif
endfunction
" ==========================================================
" Call System Command func
" ==========================================================

let s:syscall = {}

function! s:syscall.system(cmd) dict
    if has('win64') || has('win32') || has('win16')
        let envShell = &shell
        let envShellcmdflag = &shellcmdflag
        let &shell = 'cmd.exe'
        let &shellcmdflag = '/c'
        try
            return system(a:cmd)
        " catch 
        "     throw 'E-PIM-23' 
        finally
            let &shell = envShell
            let &shellcmdflag = envShellcmdflag
        endtry
    else
        return system(a:cmd)
    endif
endfunction

function! s:syscall.systemList(cmd) dict
    if has('win64') || has('win32') || has('win16')
        let envShell = &shell
        let envShellcmdflag = &shellcmdflag
        let &shell = 'cmd.exe'
        let &shellcmdflag = '/c'
        try
            return systemlist(a:cmd)
        " catch 
        "     throw 'E-PIM-24' 
        finally
            let &shell = envShell
            let &shellcmdflag = envShellcmdflag
        endtry
    else
        return systemlist(a:cmd)
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
		call s:logger.errorMsg('Caught "' . v:exception
			\ . '" in ' . v:throwpoint)
	endif
endfunction

function s:utilityTools.trimPsOutput(originLine) dict
    let realLine = substitute(a:originLine, '\%x00', '', 'g')
    let realLine = substitute(realLine, '\%x0d', '', 'g')
    return realLine
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
        return s:os
	endif
endfunction

function! s:utilityTools.inputName(...) dict
	" 1 local path 2 remote url
	let input_type = a:000[0] ? a:000[0] : 1
    redraw | call inputsave()
	if input_type == 1
		let image_path = input('Enter your image path: ')
	else
		let image_path = input('Enter a remote  url: ')
	endif
    call inputrestore()
    let filePathObj = copy(s:FilePathWrapper)
    let filePathObj.originPath = image_path
	if input_type == 1
		if empty(glob(filePathObj.getPath()))
			throw 'E-PIM-21'
		endif
	else
		let filePathObj.isPath = 0
	endif
    return filePathObj
endfunction

function! s:utilityTools.detectPicgoApiServerPort() dict
    let picgoApiServerPort = s:settings.getSetting(
        \ 'storage_cloud_picgoapp_api_server_port')
    call s:logger.debugMsg('checking the picgo api server, port is :' 
        \ . picgoApiServerPort)
    py3 vim.command("let picgoApiServerAviailable= '%s'" % detect_picgo_api_server(vim.eval('picgoApiServerPort')))
    if picgoApiServerAviailable ==? 'NO'
        throw 'E-PIM-22'
    endif
endfunction


" ==========================================================
" Async Job Helper
" ==========================================================
" Deprecated  use job_start instead
function! s:AsyncRun(fnRef)
    let timerRef = timer_start(1000, fnRef,
        \ {'repeat': 5})
endfunction




" ==========================================================
" File system utils
" ==========================================================

let s:fileHandler = {}

" translate absolute path to relative path
function s:fileHandler.getRelativePath(img_path_obj) dict
	let current_file_header_path = expand('%:p:h')
	let file_path_list = split(current_file_header_path, s:separator_char)
	let img_name = fnamemodify(a:img_path_obj.originPath, ':p:t')
	let img_file_header_path = fnamemodify(a:img_path_obj.originPath, ':p:h')
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
            let imgRelativePathObj = copy(s:FilePathWrapper)
            let imgRelativePathObj.originPath = img_relative_path
			return imgRelativePathObj
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
    let imgRelativePathObj = copy(s:FilePathWrapper)
    let imgRelativePathObj.originPath = img_relative_path
	return imgRelativePathObj
endfunction

" convert the path to the final version, depending on your configuration file
" config: storage_local_prefer_relative_path
function! s:fileHandler.getLocalStoragePath(local_full_path_obj) dict
	if s:settings.getSetting('storage_local_prefer_relative_path') == 0
		call s:logger.debugMsg('local storage use absolute path')
		return a:local_full_path_obj
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
		return self.getRelativePath(a:local_full_path_obj)
	endif
endfunction

function! s:fileHandler.copyFile(source, dest, ...) dict
    let deleteSource = get(a:, 1, 1)
    " let deleteFlag = deleteSource == 1 ? 'y' : 'n'
    " delete file by job
    let deleteFlag = 'n'
    py3 copy_file(vim.eval('a:source.getPath()'), vim.eval('a:dest.getPath()'), vim.eval('deleteFlag'))
    if deleteSource == 1
        " call self.AsyncDelete(a:source)
        call s:DeleteTempFile(a:source.getPath())
    endif
endfunction


" Deprecated, use DeleteTempFile instead
function s:fileHandler.AsyncDelete(filePathObj) dict
    call s:logger.debugMsg('delete file via a async func!')
    let fnName = 's:fileHandler.delete'
    let fnArgs = [a:filePathObj]
    let deleteFnRef = function(fnName, fnArgs, s:fileHandler)
    call s:AsyncRun(deleteFnRef)
endfunction


" Deprecated
function s:fileHandler.delete(fileObj) dict
    call s:logger.debugMsg('try to delete the temp file now!')
    try
        py3 remove_file(vim.eval('a:fileObj.getPath()'))
	catch /^Vim(py3):/
		call s:logger.errorMsg('Caught "' . v:exception . '" in [iniPi2md]')
        throw 'E-PIM-16'
    endtry
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
function! s:markupLang.insertImageLink(img_url_obj) dict
    call s:logger.debugMsg('paste image finish!')
	let file_type = self.detectMarkupLanguage()
	if file_type ==? 'markdown'
		execute "normal! i![I"
		let ipos = getcurpos()
		execute "normal! amage](" . a:img_url_obj.originPath . ")"
		call setpos('.', ipos)
		redraw | echo 'please enter the title of this image...'
		execute "normal! ve\<C-g>"
	elseif file_type ==? 'rst'
		execute "normal! i!.. |I"
		let ipos = getcurpos()
		execute "normal! amage| image:: " . a:img_url_obj.originPath
		call setpos('.', ipos)
		redraw | echo 'please enter the title of this image...'
		execute "normal! ve\<C-g>"
	elseif file_type ==? 'vimwiki'
		let vimwiki_flag = ''
		if g:pi2mdSettings['storage'] == 0
			let vimwiki_flag = 'file:'
		endif
		execute "normal! i!{{" . vimwiki_flag . a:img_url_obj.originPath . "}}"
	endif
endf


" ==========================================================
" Clipboard Tools
" ==========================================================

let s:clipboardTools = {}

function! s:clipboardTools.getClipBoardImageAndSave(save_path_obj) dict
	let save_to = a:save_path_obj.getPath()
	try
        py3 vim.command("let save_result = '%s'" % save_clipboard(vim.eval('save_to')))
	catch 'Vim(py3):ModuleNotFoundError: No module named \'PIL\''
		throw 'E-PIM-13'
	catch /^Vim\%((\a\+)\)\=:E370:/
		throw 'E-PIM-14'
	endtry

	if save_result ==? ''
		call s:logger.warningMsg('No image in your system clipboard!')
		throw 'E-PIM-12'
	endif
	return a:save_path_obj
endfunction


function! s:clipboardTools.getAndSaveClipBoardImageTemporary() dict
	" get current dir and temp file_name
    call s:logger.debugMsg('save image from clipboard temporary!')
    py3 vim.command("let random_name = '%s'" % str(uuid.uuid4()))
	let temp_file_name = random_name . '.png'
	let temp_path = expand('%:p:h')
	let temp_img_full_path = temp_path . s:separator_char . temp_file_name
    call s:logger.debugMsg('the temp image file path is:' . temp_img_full_path)
    let tempImageFIleObj = copy(s:FilePathWrapper)
    let tempImageFIleObj.originPath = temp_img_full_path
	return s:clipboardTools.getClipBoardImageAndSave(tempImageFIleObj)
endfunction



" ==========================================================
" Remote Tools
" ==========================================================

let s:remoteTools = {}

function s:remoteTools.saveRemoteTemporary(url) abort
    
endfunction





" ==========================================================
" 3rd part cloud lib functions
" ==========================================================


" ------ upic functions



" ====== Local storage

let s:localStorage = {}

function! s:localStorage.saveToLocalStorage(source, ...) dict
    let deleteSource = get(a:, 1, 1)
	" get file name from source
	let file_name = fnamemodify(a:source.originPath, ':p:t')
	let file_dest_path = self.buildLocalStorageParentPath() 
		\ . s:separator_char . file_name
    let destFileObj = copy(s:FilePathWrapper)
    let destFileObj.originPath = file_dest_path
	call s:fileHandler.copyFile(a:source, destFileObj, deleteSource)
	call s:logger.debugMsg('The final image local path is ' . file_dest_path)
	let markup_link_url = s:fileHandler.getLocalStoragePath(destFileObj)
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
			\ s:settings.getSetting('g:pi2md_localstorage_path')
	endif
	" make dir if not exists
	if !isdirectory(local_save_parent_path)
        call mkdir(local_save_parent_path)
    endif
    return local_save_parent_path

endfunction

" ====== Cloud storage

let s:cloudStorage = {}

function s:cloudStorage.saveToCloudStorage(source, ...) dict
    let deleteSource = get(a:, 1, 1)
    let remote_img_obj = copy(s:FilePathWrapper)
    let remote_img_obj.isPath = 0
    if g:pi2mdSettings['storage_cloud_tool'] ==? 'picgo-core'
        let remote_img_obj = self.uploadByPicgoCore(a:source, deleteSource)
    elseif g:pi2mdSettings['storage_cloud_tool'] ==? 'picgo'
        " use picgo app api
        let remote_img_obj = self.uploadByPicgoApp(a:source, deleteSource)
    endif
    return remote_img_obj
endfunction

function s:cloudStorage.uploadByPicgoCore(source, ...) dict
    let deleteSource = get(a:, 1, 1)
    call s:logger.debugMsg('upload image by picgo-core')
    " build a upload command
    try
        let picgocore_upload_cmd = 
            \ g:pi2mdSettings['storage_cloud_picgocore_path'] .
            \ ' upload ' .
            \ a:source.originPath
        let picgoApiCmdResult= s:syscall.systemList(picgocore_upload_cmd)
        let image_url_result = self.getPicgoResult(picgoApiCmdResult)
        call s:logger.debugMsg('upload image by Picgo app success!')
        let imageResultObj = copy(s:FilePathWrapper)
        let imageResultObj.isPath = 0
        let imageResultObj.originPath = image_url_result
        return imageResultObj
    finally
        " finally delete the temp image file
        if deleteSource == 1
            call s:DeleteTempFile(a:source.getPath())
            " call s:fileHandler.delete(a:source)
        endif
    endtry

    " if g:pi2mdSettings.os ==? 'Windows' || has('win32')
    "     " call s:logger.debugMsg('the system list output length is: ' . len(picgocore_output_list))
    "     let currentIndex = 0
    "     for oriMsg in picgocore_output_list
    "         let windowsPicgoCoreOutput = s:utilityTools.trimPsOutput(oriMsg)
    "         call s:logger.debugMsg(windowsPicgoCoreOutput)
    "         let isSuccessIndex = match(windowsPicgoCoreOutput, 'Picgo\ SUCCESS')
    "         if isSuccessIndex > 0
    "             " get url index of list
    "             let successReturnUrlIndex = currentIndex + 1
    "             let returnUrlString = s:utilityTools.trimPsOutput(picgocore_output_list[successReturnUrlIndex])
    "             call s:logger.debugMsg(returnUrlString)
    "             return returnUrlString
    "         elseif currentIndex == len(picgocore_output_list) - 1
    "             " upload to picgo failed
    "             throw 'E-PIM-17'
    "         endif
    "         let currentIndex += 1
    "     endfor
    " else
    "     let output_file_remote_url = picgocore_output_list[-1]
    "     return output_file_remote_url
    " endif
endfunction


" Deprecated use py3 instead of node script
" function! s:cloudStorage.buildPicgoAppCmd(source) dict
"     let picgo_node_script_path = g:pi2mdSettings['pi2md_root']
"         \ . s:separator_char . 'scripts' . s:separator_char . 'picgo.js'
"     let picgo_upload_cmd = 
"         \ g:pi2mdSettings['storage_cloud_picgoapp_node_path']
"         \ . ' ' . picgo_node_script_path
"         \ . ' -p '
"         \ . s:settings.getSetting('storage_cloud_picgoapp_api_server_port')
"     if a:source.originPath !=# ''
"         let picgo_upload_cmd .= ' -f '
"             \ . a:source.originPath
" 	endif
"     call s:logger.debugMsg('the picgo app upload cmd is ' . picgo_upload_cmd)
"     return picgo_upload_cmd
" endfunction

function! s:cloudStorage.uploadByPicgoApp(source, ...) dict
    let deleteSource = get(a:, 1, 1)
    call s:logger.debugMsg('upload image by picgo app')
    try
		call s:utilityTools.detectPicgoApiServerPort()
        " let picgoapp_upload_cmd = self.buildPicgoAppCmd(a:source)
        " " let picgoappCmdResultList = system(picgoapp_upload_cmd)
        " " let @r = system(picgoapp_upload_cmd)
        " let picgoApiCmdResult = s:syscall.systemList(picgoapp_upload_cmd)
        " let image_url_result = self.getPicgoResult(picgoApiCmdResult)
        let image_path = a:source.originPath
        let api_port = s:settings.getSetting(
            \ 'storage_cloud_picgoapp_api_server_port')
        py3 vim.command("let upload_result = '%s'" % 
            \ picgo_upload(image_path=vim.eval('image_path'), 
            \ api_port=vim.eval('api_port')))
        if upload_result != ''
            call s:logger.debugMsg('upload image by Picgo app success!')
            let imageResultObj = copy(s:FilePathWrapper)
            let imageResultObj.isPath = 0
            let imageResultObj.originPath = upload_result
            return imageResultObj
        endif
        throw 'E-PIM-18'
    finally
        if deleteSource == 1
            call s:DeleteTempFile(a:source.getPath())
            " call s:fileHandler.delete(a:source)
        endif
    endtry
endfunction

function! s:cloudStorage.getPicgoResult(resultList)
    if len(a:resultList) == 1
        let firstLine = a:resultList[0] 
        call s:logger.debugMsg('the picgo api result is: ' . firstLine)
        if match(firstLine, '^http[s]\?:\/\/.\?') >= 0
            return firstLine
        endif
    elseif len(a:resultList) > 1
        let resultIndex = 0
        let currentIndex = 0
        for lineText in a:resultList
            if match(lineText, 'Picgo\ SUCCESS') > 0
                let resultIndex = currentIndex + 1
                return a:resultList[resultIndex]
            elseif match(lineText, 'Picgo\ ERROR') > 0
                throw 'E-PIM-18'
            endif
            let currentIndex += 1
        endfor
        throw 'E-PIM-18'
    endif
    call s:logger.errorMsg('error occurred when call picgo api')
    throw 'E-PIM-19'
endfunction


function! s:pasteImage(source, ...)
    let deleteSource = get(a:, 1, 1)
	" upload to cloud or save to local
	if s:settings.getSetting('storage') == 0
		" local storage
		call s:logger.debugMsg('use local storage')
		let final_img_path_obj= s:localStorage.saveToLocalStorage(
            \ a:source, deleteSource)
        return final_img_path_obj
	elseif s:settings.getSetting('storage') == 1
		call s:logger.debugMsg('use cloud storage')
		" cloud storage
		let final_img_url_obj = s:cloudStorage.saveToCloudStorage(
            \ a:source, deleteSource)
        return final_img_url_obj
	endif
endfunction

" ==========================================================
" Paste from clipboard 
" ==========================================================

function! s:pasteImageFromClipboard()
	" save image to temp file
	let temp_img_file = s:clipboardTools.getAndSaveClipBoardImageTemporary()
	let final_img_url_obj = s:pasteImage(temp_img_file, 1)
	" write link for markup language
	call s:markupLang.insertImageLink(final_img_url_obj)	
endfunction



" ==========================================================
" Paste from Remote Url 
" ==========================================================

function! s:pasteImageFromRemoteUrl()
	" wait for user input
    let image_file_obj = s:utilityTools.inputName(2)
	" download image

	try
		py3 vim.command("let random_name = '%s'" % str(uuid.uuid4()))
		let temp_path_str = expand('%:p:h') . s:separator_char .
			\ random_name . '.' . image_file_obj.getPostfix()
		let temp_path_exp = fnameescape(temp_path_str)
		py3 download_image(vim.eval('image_file_obj.originPath'),
			\	vim.eval('temp_path_exp'))
	catch /^Vim(py3):/
		call s:logger.errorMsg('Caught "' . v:exception . '" in [iniPi2md]')
		throw 'E-PIM-26'	
	endtry
	let tmp_img_obj = copy(s:FilePathWrapper)
	let tmp_img_obj.originPath = temp_path_str
	let final_img_url_obj = s:pasteImage(tmp_img_obj, 1)
	" write link for markup language
	call s:markupLang.insertImageLink(final_img_url_obj)	
endfunction

" ==========================================================
" Paste from local
" ==========================================================


function! s:pasteImageFromLocalPath()
	" wait for user input
    let image_file_obj = s:utilityTools.inputName()
    let final_img_url_obj = s:pasteImage(image_file_obj, 0)
	" write link for markup language
	call s:markupLang.insertImageLink(final_img_url_obj)	
    return
endfunction


" ==========================================================
" Main function and commands
" ==========================================================

function! pi2md#Pi2md(...) 
	try
        if a:0 > 0 && a:0 <=2
            let methodFlag = a:000[0] == '' ? 'c' : a:000[0]
            call s:logger.debugMsg('the command argument is:[' . methodFlag . ']')
        else
            throw 'E-PIM-20'
        endif
		call s:settings.initPi2md()
		if methodFlag ==? 'c'
			call s:logger.debugMsg('paste image from your clipboard start!')
			call s:pasteImageFromClipboard()
		elseif methodFlag ==? 'p'
			call s:logger.debugMsg(
				\ 'paste image from your local file system start!')
            call s:pasteImageFromLocalPath()
		elseif methodFlag ==? 'r'
			call s:logger.debugMsg('paste image from a remote url start!')
            call s:pasteImageFromRemoteUrl()
		endif
	catch
		call s:utilityTools.caught()
	endtry
endfunction


" vim:set ft=vim et sts=4 sw=4 ts=4 tw=78:
