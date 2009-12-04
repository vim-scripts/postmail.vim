" {{{
scriptencoding utf-8
" loaded check {{{
if &cp || exists("g:loaded_postmail")
    finish
endif
if v:version < 700
  finish
endif
if !has("python")
    finish
endif
if !has("iconv")
    finish
endif
if !has("multi_byte")
    finish
endif
let g:loaded_postmail = 1
" }}}

let s:save_cpo = &cpo
set cpo&vim


" command ':Mail' {{{
" post current buffer, or selected area with mail.
" [command example]
"     :Mail
"     :Mail {to_mailaddress}
"     :Mail {to_mailaddress1} {to_mailaddress2}, {to_mailaddress3}
command! -nargs=* -range=% Mail :<line1>,<line2>call g:PostMail(<f-args>)
" }}}


" function 'g:PostMail' {{{
"     get buffer text.
"     read smtp configuration file 'postmail.conf'.
"     display dialog to input mail subject.
"     display dialog to input to mail address.
"     send mail.
function! g:PostMail(...) range
    " get buffer text
    let l:buffertext = join(getline(a:firstline, a:lastline), "\n")
    let l:buffertext = iconv(l:buffertext, &encoding, 'utf-8')

    " get smtp configuration
    let l:smtpconf = {}
    for l:i in split(globpath(&runtimepath, "plugin/postmail.conf"), '\n')
        let l:smtpconf = s:Load(l:i)
    endfor

    " configuration file check.
    if len(l:smtpconf) < 1
        echohl ErrorMsg | echo "Please create plugin/postmail.conf. Cannot send mail. Done." | echohl None
        return
    endif
    if l:smtpconf.login_user == 'please_change@gmail.com'
        echohl ErrorMsg | echo "Please setup plugin/postmail.conf. Cannot send mail. Done." | echohl None
        return
    endif

    " get subject
    let l:subject = input("Mail Subject : ", l:smtpconf.default_subject)
    let l:subject = iconv(l:subject, &encoding, 'utf-8')

    " get to address
    let l:argc = len(a:000)
    if l:argc < 1
        let l:to_input = input("To Address : ", l:smtpconf.default_to_address)
        let l:to_input = iconv(l:to_input, &encoding, 'utf-8')
        let l:addresses = [ l:to_input ]
    else
        let l:addresses = a:000
    endif

    " POP before STMP auth
    if has_key(l:smtpconf, 'pop_host')
        let l:pop_host = l:smtpconf.pop_host
    else
        let l:pop_host = ''
    endif
    if has_key(l:smtpconf, 'pop_port')
        let l:pop_port = l:smtpconf.pop_port
    else
        let l:pop_port = '0'
    endif
    if has_key(l:smtpconf, 'pop_user')
        let l:pop_user = l:smtpconf.pop_user
    else
        let l:pop_user = ''
    endif
    if has_key(l:smtpconf, 'pop_pass')
        let l:pop_pass = l:smtpconf.pop_pass
    else
        let l:pop_pass = ''
    endif

    " loop and post mail
    let l:i = 0
    while l:i < len(l:addresses)
        let l:to_address = l:addresses[l:i]
        call s:Post(
            \     l:smtpconf.auth_type,
            \     l:smtpconf.smtp_host,
            \     l:smtpconf.smtp_port,
            \     l:smtpconf.login_user,
            \     l:smtpconf.login_pass,
            \     l:smtpconf.mail_encoding,
            \     l:smtpconf.from_address,
            \     l:to_address,
            \     l:subject,
            \     l:buffertext,
            \     l:pop_host,
            \     l:pop_port,
            \     l:pop_user,
            \     l:pop_pass
            \ )

        let l:i += 1
    endwhile
endfunction
" }}}


" function 's:Post' {{{
"     send mail with argument values.
function! s:Post(auth_type, smtp_host, smtp_port, login_user, login_pass, mail_encoding, from_address, to_address, subject, body, pop_host, pop_port, pop_user, pop_pass)
    " load mailer class
    for l:i in split(globpath(&runtimepath, "plugin/postmail.py"), '\n')
        execute "pyfile " . l:i
    endfor

python << EOF
from vim import *
import vim

auth_type     = vim.eval("a:auth_type")
smtp_host     = vim.eval("a:smtp_host")
smtp_port     = int(vim.eval("a:smtp_port"))
login_user    = vim.eval("a:login_user")
login_pass    = vim.eval("a:login_pass")
mail_encoding = vim.eval("a:mail_encoding")
from_address  = vim.eval("a:from_address")
to_address    = vim.eval("a:to_address")
subject       = unicode(vim.eval("a:subject"), 'utf-8')
body          = unicode(vim.eval("a:body"), 'utf-8')

# POP before STMP auth
pop_host      = vim.eval("a:pop_host")
pop_port      = int(vim.eval("a:pop_port"))
pop_user      = vim.eval("a:pop_user")
pop_pass      = vim.eval("a:pop_pass")

# TODO move to python script file.
# JAPANESE ISO-2022-JP ESCAPE
if mail_encoding.upper() == 'ISO-2022-JP':
    subject = subject.replace(u'\uff5e', u'\u301c')
    body    = body.replace(u'\uff5e', u'\u301c')

mailer = Mailer(auth_type, smtp_host, smtp_port, login_user, login_pass, mail_encoding, pop_host, pop_port, pop_user, pop_pass)
mailer.sendmail(from_address, to_address, subject, body)
EOF
endfunction
" }}}


" function 's:Load' {{{
"     read configuration file, and generate properties.
" http://nanasi.jp/articles/code/io/deserialize.html
function! s:Load(filename)
    let l:stored = ""
    for l:line in readfile(a:filename)
        let l:stored .= l:line
    endfor

    let l:self = eval(l:stored)
    return l:self
endfunction
" }}}


let &cpo = s:save_cpo
finish

" }}}
==============================================================================
postmail.vim : mail message posting plugin. (python required)
------------------------------------------------------------------------------
$VIMRUNTIMEPATH/plugin/postmail.vim
$VIMRUNTIMEPATH/plugin/postmail.py
$VIMRUNTIMEPATH/plugin/postmail.conf
$VIMRUNTIMEPATH/doc/postmail.txt
==============================================================================
author  : OMI TAKU
url     : http://nanasi.jp/
email   : mail@nanasi.jp
==============================================================================
" vim: set ff=unix et ft=vim nowrap foldmethod=marker :
