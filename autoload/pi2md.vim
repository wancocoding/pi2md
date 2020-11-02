if exists("b:did_autoload_pi2md")
    finish
endif
let b:did_autoload_pi2md = 1
let s:max_attempts = 3


py3 from pi2md import simple_hash_text, detect_file

" temp_files format
" [{
"	'uid': 'ed3fa20cff286622c06355dba8d57d75',
"	'entity': {'fname': '/the/file/path', 'attempts': 2, 'success': 0}
" }]
"
let b:temp_files = []


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
	if has('win32') || has('win64')
		let l:args += ['cmd', '/c']
	endif
	" let delCmd = 'del /f d:\test2.txt'
	let l:args += ['del']
	let l:args += ['/f ']
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
		echom 'delete file ' . a:filePath . ' attempts: ' . f_info['attempts']
		let s:delJob = job_start(l:args, delJobOptions)
		" let l:success = (job_status(s:delJob) != 'fail')? 1 : 0
	else
		echom 'max retry, no more attempts to delete file ' . f_info['fname']
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
		echom 'delete temp file success!'
		call s:removeTempEntity(l:file_path)
	else
		" retry delete file
		sleep 3000m
		call s:deleteFile(l:file_path)
	endif
endfunction

" Deprecated
function! s:delete_on_error(channel, msg)
	echom 'error on delete temp file :' . a:msg
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

function pi2md#DeleteTempFile(filePath)
	call s:deleteFile(a:filePath)
endfunction
