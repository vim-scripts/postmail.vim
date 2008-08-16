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
$VIMRUNTIMEPATH/plugin/postmail.basic.conf
$VIMRUNTIMEPATH/plugin/postmail.gmail.conf
$VIMRUNTIMEPATH/plugin/postmail.op25b.conf
$VIMRUNTIMEPATH/plugin/postmail.pop.conf
$VIMRUNTIMEPATH/doc/postmail.txt
==============================================================================
author  : OMI TAKU
url     : http://nanasi.jp/
email   : mail@nanasi.jp
==============================================================================

Send 'current editing buffer', or 'selected area of text' with email.
Most simple usage is to execute ':Mail' command.

This plugin consists of
    postmail.vim  ....... vim script plugin
    postmail.py   ....... mail sender engine

and some sample configuration files.
    postmail.basic.conf ..... basic configuration file.
    postmail.gmail.conf ..... GMail based configuration file.
    postmail.op25b.conf ..... Outbound Port25 Blocking mail configuration
                              file.
    postmail.pop.conf   ..... POP before STMP Auth mail configuration file.

Configuration file.
    postmail.conf  ....... mail server configuration file. This file is
                           needed to be created at Installation step.

This plugin is only available if 'compatible' is not set,
Vim is compiled with '+python', '+iconv', '+multi_byte',
Python is installed, and $PATH is appropriately set.


------------------------------------------------------------------------------
INSTALLATION

1. Unzip postmail.zip, and copy to 'plugin', 'doc', 'syntax' directory in
   your 'runtimepath' directory.

    $HOME/vimfiles/plugin or $HOME/.vim/plugin
    -  postmail.vim
    -  postmail.py
    -  postmail.basic.conf
    -  postmail.gmail.conf
    -  postmail.op25b.conf
    -  postmail.pop.conf

    $HOME/vimfiles/doc or $HOME/.vim/doc
    -  postmail.txt
    -  postmail.jax

    $HOME/vimfiles/syntax or $HOME/.vim/syntax
    -  help_ja.vim

2. Execute ':helptags' command to your vim 'doc' directory in 'runtimepath'.

    :helptags $HOME/vimfiles/doc

    or

    :helptags $HOME/.vim/doc

3. Create 'postmail.conf' configuration file.
   Rename one of configuration template file in plugin directory
    -  postmail.basic.conf
    -  postmail.gmail.conf  (recommended template)
    -  postmail.op25b.conf
    -  postmail.pop.conf
   to  postmail.conf .

4. Edit 'postmail.conf' and setup mail server configuration.
   You get some more information, to see
   CONFIGURATION directive.

   'postmail.conf' file encoding is same with &encoding value.
       :echo &encoding

5. Restart vim editor.


------------------------------------------------------------------------------
USAGE

You use command ':Mail', and so email is sent.
See also 'COMMAND EXAMPLE'.

:[range]Mail
        send mail message.
        if [range] is selected, send selected text.
        if [range] is not selected, send current buffer.

:[range]Mail {to_mailaddress}
        send mail message to {to_mailaddress}.
        if [range] is selected, send selected text.
        if [range] is not selected, send current buffer.

:[range]Mail {to_mailaddress1} {to_mailaddress2}, {to_mailaddress3}
        send mail message to {to_mailaddress1}, {to_mailaddress2}, and
        {to_mailaddress2}.
        if [range] is selected, send selected text.
        if [range] is not selected, send current buffer.


------------------------------------------------------------------------------
COMMAND EXAMPLE

:Mail
        send mail message.
        message is current buffer text.

:Mail mail@nanasi.jp
        send current buffer text to 'mail@nanasi.jp' address.

:6,20Mail mail@nanasi.jp
        send from line 6 to line 20 text to 'mail@nanasi.jp' address.


------------------------------------------------------------------------------
CONFIGURATION

'postmail.conf' file is mail server configuration file.
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


auth_type
    SMTP Server Authentic method type.
    Available type is now 'None', 'POP', or 'TLS'.

    'auth_type' value and 'authentic method type' mapping is this.

         auth_type | authentic method type
        -----------+-----------------------
         None      | None
         POP       | POP Before SMTP Auth
         TLS       | TLS Auth

smtp_host
    SMTP Server host.

smtp_port
    SMTP Server port number.

login_user
    SMTP Server user name.

login_pass
    SMTP Server user password.

mail_encoding
    Mail message encoding name.

from_address
    From email address.

default_to_address
    Default to email address value.

default_subject
    Default mail subject value.


------------------------------------------------------------------------------
CONFIGURATION EXAMPLE

Here is 'postmail.conf' configuration file examples.

---------------------------------------------------------
GMail based mail configuration file sample.
(sample : plugin/postmail.gmail.conf)

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


---------------------------------------------------------
Basic mail configuration file sample.
(sample : plugin/postmail.basic.conf)

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


---------------------------------------------------------
Outbound Port25 Blocking mail configuration file sample.
(sample : plugin/postmail.op25b.conf)

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


---------------------------------------------------------
POP Before SMTP Auth mail configuration file sample.
'POP Before SMTP Auth mail configuration' has some more configuration
than basic format.
'pop_host', 'pop_port', 'pop_user', and 'pop_pass' configuration is added.
(sample : plugin/postmail.pop.conf)

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

pop_host
    POP Server host.

pop_port
    POP Server port number.

pop_user
    POP Server user name.

pop_pass
    POP Server user password.


------------------------------------------------------------------------------
MORE ...

    :help postmail


==============================================================================
" vim: set ff=unix et ft=vim nowrap fenc=utf-8 foldmethod=marker :
