" gtags_maps module for Gutentags
" 专为 Neovim 设计，结合 GNU Global (gtags) 和 cscope_maps.nvim
" - 使用 gtags 生成 GTAGS 数据库
" - 使用 cscope_maps.nvim + gtags-cscope 查询数据库

if !has('nvim')
    throw "Can't enable the gtags_maps module for Gutentags, ".
                \"this module is only for Neovim."
endif

" Global Options {{{

if !exists('g:gutentags_gtags_executable_maps')
    let g:gutentags_gtags_executable_maps = 'gtags'
endif

if !exists('g:gutentags_gtags_dbpath_maps')
    let g:gutentags_gtags_dbpath_maps = ''
endif

if !exists('g:gutentags_gtags_options_file_maps')
    let g:gutentags_gtags_options_file_maps = '.gutgtags'
endif

" }}}

" Gutentags Module Interface {{{

let s:runner_exe = gutentags#get_plat_file('update_gtags')

function! gutentags#gtags_maps#init(project_root) abort
    let l:db_path = gutentags#get_cachefile(
                \a:project_root, g:gutentags_gtags_dbpath_maps)
    let l:db_path = gutentags#stripslash(l:db_path)
    let l:db_file = l:db_path . '/GTAGS'
    let l:db_file = gutentags#normalizepath(l:db_file)

    if !isdirectory(l:db_path)
        call mkdir(l:db_path, 'p')
    endif

    let b:gutentags_files['gtags_maps'] = l:db_file

    " 设置环境变量供 gtags-cscope 使用
    let $GTAGSDBPATH = l:db_path
    let $GTAGSROOT = a:project_root
endfunction

function! gutentags#gtags_maps#generate(proj_dir, tags_file, gen_opts) abort
    let l:cmd = [s:runner_exe]
    let l:cmd += ['-e', '"' . g:gutentags_gtags_executable_maps . '"']

    let l:file_list_cmd = gutentags#get_project_file_list_cmd(a:proj_dir)
    if !empty(l:file_list_cmd)
        let l:cmd += ['-L', '"' . l:file_list_cmd . '"']
    endif

    let l:proj_options_file = a:proj_dir . '/' . g:gutentags_gtags_options_file_maps
    if filereadable(l:proj_options_file)
        let l:proj_options = readfile(l:proj_options_file)
        let l:cmd += l:proj_options
    endif

    " gtags 需要在数据库目录中运行
    let l:db_path = fnamemodify(a:tags_file, ':p:h')
    let l:cmd += ['--incremental', '"'.l:db_path.'"']

    let l:cmd = gutentags#make_args(l:cmd)

    call gutentags#trace("Running: " . string(l:cmd))
    call gutentags#trace("In:      " . getcwd())
    if !g:gutentags_fake
        let l:job_opts = gutentags#build_default_job_options('gtags_maps')
        let l:job = gutentags#start_job(l:cmd, l:job_opts)
        call gutentags#add_job('gtags_maps', a:tags_file, l:job)
    else
        call gutentags#trace("(fake... not actually running)")
    endif
    call gutentags#trace("")
endfunction

function! gutentags#gtags_maps#on_job_exit(job, exit_val) abort
    let l:job_idx = gutentags#find_job_index_by_data('gtags_maps', a:job)
    let l:dbfile_path = gutentags#get_job_tags_file('gtags_maps', l:job_idx)
    call gutentags#remove_job('gtags_maps', l:job_idx)

    if a:exit_val != 0 && !g:__gutentags_vim_is_leaving
        call gutentags#warning(
                    \"gtags-maps job failed, returned: ".
                    \string(a:exit_val))
    endif
endfunction

" }}}
