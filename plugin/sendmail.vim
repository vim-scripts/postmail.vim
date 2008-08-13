" {{{
scriptencoding utf-8
" loaded check {{{
if &cp || exists("g:loaded_sendmail")
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
let g:loaded_sendmail = 1
" }}}

let s:save_cpo = &cpo
set cpo&vim


" command ':Mail' {{{
" post current buffer, or selected area with mail.
" [command example]
"     :Mail
"     :Mail {to_mailaddress}
"     :Mail {to_mailaddress1} {to_mailaddress2}, {to_mailaddress3}
command! -nargs=* -range=% Mail :<line1>,<line2>call g:SendMail(<f-args>)
" }}}


" function 'g:SendMail' {{{
"     get buffer text.
"     read smtp configuration file 'sendmail.conf'.
"     display dialog to input mail subject.
"     display dialog to input to mail address.
"     send mail.
function! g:SendMail(...) range
    " get buffer text
    let l:buffertext = join(getline(a:firstline, a:lastline), "\n")
    let l:buffertext = iconv(l:buffertext, &encoding, 'utf-8')

    " get smtp configuration
    "for l:i in split(globpath(&runtimepath, "plugin/sendmail.nanasi.pop.conf"), '\n')
    "for l:i in split(globpath(&runtimepath, "plugin/sendmail.nanasi.gmail.conf"), '\n')
    for l:i in split(globpath(&runtimepath, "plugin/sendmail.conf"), '\n')
        let l:smtpconf = s:Load(l:i)
    endfor

    " configuration file check.
    if l:smtpconf.login_user == 'please_change@gmail.com'
        echohl ErrorMsg | echo "Please setup plugin/sendmail.conf. Cannot send mail. Done." | echohl None
        finish
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
    for l:i in split(globpath(&runtimepath, "plugin/sendmail.py"), '\n')
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
sendmail.vim : mail message posting plugin.
------------------------------------------------------------------------------
$VIMRUNTIMEPATH/plugin/sendmail.vim
$VIMRUNTIMEPATH/plugin/sendmail.py
$VIMRUNTIMEPATH/plugin/sendmail.conf
$VIMRUNTIMEPATH/plugin/sendmail.basic.conf
$VIMRUNTIMEPATH/plugin/sendmail.gmail.conf
$VIMRUNTIMEPATH/plugin/sendmail.op25b.conf
$VIMRUNTIMEPATH/plugin/sendmail.pop.conf
==============================================================================
author  : OMI TAKU
url     : http://nanasi.jp/
email   : mail@nanasi.jp
version : 2008/08/13 10:00:00
==============================================================================

Send 'current editing buffer', or 'selected area of text' with email.
Most simple usage is to execute ':Mail' command.


This plugin consists of
'sendmail.vim'   ....... vim script plugin
'sendmail.py'    ....... mail sender engine
'sendmail.conf'  ....... mail server configuration

and some sample configuration files.
'sendmail.basic.conf'   ..... basic configuration file
'sendmail.gmail.conf'   ..... GMail based configuration file
'sendmail.op25b.conf'   ..... Outbound Port25 Blocking mail configuration file
'sendmail.pop.conf'     ..... POP before STMP Auth mail configuration file


This plugin requires
    Vim compiled with '+python', '+iconv', '+multi_byte', and python.


------------------------------------------------------------------------------
[installation]
1. Open sendmail.vba with vim.
    vim sendmail.vba

2. Execute ':source' command.
    :source %

3. Some files are installed to 'plugin' directory.
    - sendmail.vim
    - sendmail.py
    - sendmail.conf
    - sendmail.basic.conf
    - sendmail.gmail.conf
    - sendmail.op25b.conf
    - sendmail.pop.conf

4. Edit 'sendmail.conf' and setup mail server configuration.
   You get some more information, to see [configuration format] directive.

5. Restart vim editor.


------------------------------------------------------------------------------
[command format]

    " send mail message.
    :Mail

    " send mail message to {to_mailaddress}.
    :Mail {to_mailaddress}

    " send mail message to {to_mailaddress1}, {to_mailaddress2}, and {to_mailaddress2}.
    :Mail {to_mailaddress1} {to_mailaddress2}, {to_mailaddress3}

    " send selected text with mail to {to_mailaddress}.
    :'<,'>Mail {to_mailaddress}


------------------------------------------------------------------------------
[command sample]

    " send mail message.
    :Mail

    " send current buffer with mail to 'mail@nanasi.jp'.
    :Mail mail@nanasi.jp

    " send from line 6 to line 20 text to 'mail@nanasi.jp'.
    :6,20Mail mail@nanasi.jp


------------------------------------------------------------------------------
[configuration format]

'sendmail.conf' is mail server configuration file.
Basic format is here.

    {
        'auth_type':'{authentic method type."None","POP",or "TLS"}' ,
        'smtp_host':'{SMTP server host}' ,
        'smtp_port':'{SMTP server port}' ,
        'login_user':'{SMTP server user name}' ,
        'login_pass':'{SMTP server user password}' ,
        'mail_encoding':'{mail message encoding}' ,
        'from_address':'{from address}' ,
        'default_to_address':'{default to address}' ,
        'default_subject':'{default mail subject}'
    }


'auth_type' value and authentic method type mapping are this.

    auth_type => None ... None
    auth_type => POP  ... POP Before SMTP Auth
    auth_type => TLS  ... TLS Auth


------------------------------------------------------------------------------
[configuration sample]

GMail based mail configuration file sample.
(sample : sendmail.gmail.conf)
    {
        'auth_type':          'TLS'                     ,
        'smtp_host':          'smtp.gmail.com'          ,
        'smtp_port':          '587'                     ,
        'login_user':         'please_change@gmail.com' ,
        'login_pass':         'xxxxxxxxxxxx'            ,
        'mail_encoding':      'ISO-2022-JP'             ,
        'from_address':       'user@example.jp'         ,
        'default_to_address': 'user@example.jp'         ,
        'default_subject':    'default subject'
    }


basic mail configuration file sample.
(sample : sendmail.basic.conf)
    {
        'auth_type':          'None'                    ,
        'smtp_host':          'smtp.example.jp'         ,
        'smtp_port':          '25'                      ,
        'login_user':         'please_change@gmail.com' ,
        'login_pass':         'xxxxxxxxxxxx'            ,
        'mail_encoding':      'ISO-2022-JP'             ,
        'from_address':       'user@example.jp'         ,
        'default_to_address': 'user@example.jp'         ,
        'default_subject':    'default subject'
    }


Outbound Port25 Blocking mail configuration file sample.
(sample : sendmail.op25b.conf)
    {
        'auth_type':          'None'                    ,
        'smtp_host':          'smtp.example.jp'         ,
        'smtp_port':          '587'                     ,
        'login_user':         'please_change@gmail.com' ,
        'login_pass':         'xxxxxxxxxxxx'            ,
        'mail_encoding':      'ISO-2022-JP'             ,
        'from_address':       'user@example.jp'         ,
        'default_to_address': 'user@example.jp'         ,
        'default_subject':    'default subject'
    }


POP Before SMTP Auth mail configuration file sample.
(sample : sendmail.pop.conf)
    {
        'auth_type':          'POP'                     ,
        'pop_host':           'pop.example.jp'          ,
        'pop_port':           '110'                     ,
        'pop_user':           'user@example.jp'         ,
        'pop_pass':           'xxxxxxxxxxxx'            ,
        'smtp_host':          'smtp.example.jp'         ,
        'smtp_port':          '25'                      ,
        'login_user':         'please_change@gmail.com' ,
        'login_pass':         'xxxxxxxxxxxx'            ,
        'mail_encoding':      'ISO-2022-JP'             ,
        'from_address':       'user@example.jp'         ,
        'default_to_address': 'user@example.jp'         ,
        'default_subject':    'default subject'
    }


==============================================================================
" vim: set ff=unix et ft=vim nowrap fenc=utf-8 foldmethod=marker :
