" pi2md.vim - Paste Image to markdown
" Maintainer:    Cocoding  <https://cocoding.cc>
" Version:       0.1



function! s:RandomString() 
	let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
	return l:new_random
endfunction
