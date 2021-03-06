" Plugin that improved vim spelling.
" Version 1.0.0
" Author kamykn
" License VIM LICENSE

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim


function! s:get_correct_list(target_word)
	let l:current_spell_setting = spelunker#get_current_spell_setting()
	setlocal spell

	let l:spell_suggest_list = spellsuggest(a:target_word, g:spelunker_max_suggest_words)

	call spelunker#reduce_spell_setting(l:current_spell_setting)

	if len(l:spell_suggest_list) == 0
		echon "No suggested words."
		return ''
	endif

	return spelunker#words#format_spell_suggest_list(l:spell_suggest_list, a:target_word)
endfunction

function! spelunker#correct#correct(is_correct_all)
	let l:target_word = spelunker#words#search_target_word()
	if l:target_word == ''
		echo "There is no word under the cursor."
		return
	endif

	let l:prompt = 'spelunker (' . l:target_word . '->):'
	if a:is_correct_all
		let l:prompt = 'correct-all (' . l:target_word . '->):'
	endif
	let l:input_word = input(l:prompt)

	call spelunker#words#replace_word(l:target_word, l:input_word, a:is_correct_all)
endfunction

function! spelunker#correct#correct_from_list(is_correct_all, is_feeling_lucky)
	let l:target_word = spelunker#words#search_target_word()
	if l:target_word == ''
		echo "There is no word under the cursor."
		return
	endif

	let [l:spell_suggest_list_for_input_list, l:spell_suggest_list_for_replace] = s:get_correct_list(l:target_word)

	if len(l:spell_suggest_list_for_replace) < 1
		return
	endif

	if a:is_feeling_lucky
		call spelunker#words#replace_word(l:target_word, l:spell_suggest_list_for_replace[0], a:is_correct_all)
		return
	endif

	" 共通化でpopup_menuとinputlistの差を吸収
	let l:callback = {
				\ 'target_word': l:target_word,
				\ 'is_correct_all': a:is_correct_all,
				\ 'spell_suggest_list_for_replace': l:spell_suggest_list_for_replace}

	function l:callback.funcall(_id, selected) dict
		call s:correct_callback(
					\ self.target_word,
					\ self.is_correct_all,
					\ self.spell_suggest_list_for_replace,
					\ a:selected)
	endfunction

	if exists('*popup_menu') && (!exists('g:enable_inputlist_for_test') || g:enable_inputlist_for_test != 1)
		let l:curpos = getpos(".")
		call popup_menu(l:spell_suggest_list_for_replace, #{
			\ callback: l:callback.funcall,
			\ title: '[spelunker.vim]',
			\ pos: 'topleft',
			\ line: 'cursor+1',
			\ col: 'cursor'
			\ })
	else
		let l:selected = inputlist(l:spell_suggest_list_for_input_list)
		call l:callback.funcall(0, l:selected)
	endif
endfunction

function! s:correct_callback(target_word, is_correct_all, spell_suggest_list_for_replace, selected)
	if a:selected <= 0
		return
	endif

	let l:selected_word = a:spell_suggest_list_for_replace[a:selected - 1]
	call spelunker#words#replace_word(a:target_word, l:selected_word, a:is_correct_all)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
