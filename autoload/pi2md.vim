if exists("b:did_autoload_pi2md")
    finish
endif
let b:did_autoload_pi2md = 1

function! s:deleteFile()
	let l:args = []
	let l:args += split(&shell)
	let l:args += split(&shellcmdflag)
	" let delCmd = 'del /f d:\test2.txt'
	let l:args += ['del /f d:\test2.txt']
	let delJobOptions = {
	\	'callback': function('s:delete_callback'),
	\	'err_cb': function('s:delete_on_error'),
	\	'close_cb': function('s:delete_on_close'),
	\	'exit_cb': function('s:delete_on_exit'),
	\	'out_io': 'pipe',
	\	'in_io': 'null',
	\	'err_io': 'pipe',
	\	'out_mode': 'nl',
	\	'err_mode': 'nl',
	\	'stoponexit': 'term',
	\ }
	let s:delJob = job_start(l:args, delJobOptions)
	let l:success = (job_status(s:delJob) != 'fail')? 1 : 0
endfunction

function! s:delete_on_error(channel, msg)
	echom 'error: ' . a:msg
	call s:show_delete_error_in_qf()
endfunction

function! s:delete_callback(channel, text)
	if !exists("s:delJob")
		return
	endif
	" if not string return , see: h: type()
	if type(a:text) != 1
		return
	endif
	echom 'callback: ' . a:text
	" let s:async_output[s:async_head] = a:text
	" let s:async_head += 1
	" if s:async_congest != 0
	" 	call s:AsyncRun_Job_Update(-1)
	" endif
endfunc

function! s:delete_on_exit(job, message)
	echom 'job exit'
	echom 'exit : ' . a:message
endfunc

function! s:delete_on_close(channel)
	echom 'channel close'
endfunction

function! s:show_delete_error_in_qf()
	let b:bnr = bufnr('%')
	" let b:qfid = ''
	let qf_list = []
	" if !exists('b:qfid')
	" 	let action = ' '
	" endif
	let qf_item = [{
		\	'bufnr': b:bnr,
		\	'text': 'can not delete the temporary file',	
		\	'type': 'W'
		\ }]
	let qf_list += qf_item
	call setqflist(qf_list)
	keepalt exec 'botright copen'
	keepalt wincmd k
endfunction

function pi2md#Testdelete()
	call s:deleteFile()
endfunction
