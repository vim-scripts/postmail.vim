# -*- coding: utf-8 -*-
# vim:set nowrap :
import smtplib
from email.MIMEText import MIMEText
from email.Header import Header
from email.Utils import formatdate
import threading


class BaseMailer:
    def __init__(self, smtp_host, smtp_port, login_user, login_pass, mail_encoding):
        self.smtp_host     = smtp_host
        self.smtp_port     = smtp_port
        self.login_user    = login_user
        self.login_pass    = login_pass
        self.mail_encoding = mail_encoding

    def __create_message__(self, from_address, to_address, subject, body):
        message            = MIMEText(body.encode(self.mail_encoding), 'plain', self.mail_encoding)
        message['Subject'] = Header(subject.encode(self.mail_encoding), self.mail_encoding)
        message['From']    = from_address
        message['To']      = to_address
        message['Date']    = formatdate()
        return message
    create_message = __create_message__

    def __send_message__(self, from_address, to_address, message):
        smtp = smtplib.SMTP(self.smtp_host, self.smtp_port)
        smtp.sendmail(from_address, [to_address], message.as_string())
        smtp.close()
    send_message = __send_message__

    def __sendmail__(self, from_address, to_address, subject, body):
        message = self.create_message(from_address, to_address, subject, body)
        self.send_message(from_address, to_address, message)
    sendmail = __sendmail__


class TLSMailer(BaseMailer):
    def __init__(self, smtp_host, smtp_port, login_user, login_pass, mail_encoding):
        BaseMailer.__init__(self, smtp_host, smtp_port, login_user, login_pass, mail_encoding)

    def __send_tls_auth_message__(self, from_address, to_address, message):
        smtp = smtplib.SMTP(self.smtp_host, self.smtp_port)
        smtp.ehlo()
        smtp.starttls()
        smtp.ehlo()
        smtp.login(self.login_user, self.login_pass)
        smtp.sendmail(from_address, [to_address], message.as_string())
        smtp.close()
    send_message = __send_tls_auth_message__


class POPMailer(BaseMailer):
    def __init__(self, smtp_host, smtp_port, login_user, login_pass, mail_encoding, pop_host, pop_port, pop_user, pop_pass):
        BaseMailer.__init__(self, smtp_host, smtp_port, login_user, login_pass, mail_encoding)
        self.pop_host = pop_host
        self.pop_port = pop_port
        self.pop_user = pop_user
        self.pop_pass = pop_pass

    def __connect_pop_server__(self):
        import poplib
        popserver = poplib.POP3(self.pop_host, pop_port)
        popserver.user(self.pop_user)
        popserver.pass_(self.pop_pass)
        popserver.quit()

    def __pop_before_smtp_auth_sendmail__(self, from_address, to_address, subject, body):
        self.__connect_pop_server__()
        self.__sendmail__(from_address, to_address, subject, body)
    sendmail = __pop_before_smtp_auth_sendmail__


class Mailer(threading.Thread):
    def __init__(self, auth_type, smtp_host, smtp_port, login_user, login_pass, mail_encoding, pop_host, pop_port, pop_user, pop_pass):
        threading.Thread.__init__(self)

        if auth_type == 'None':
            self.mailer = BaseMailer(smtp_host, smtp_port, login_user, login_pass, mail_encoding)
        if auth_type == 'TLS':
            self.mailer = TLSMailer(smtp_host, smtp_port, login_user, login_pass, mail_encoding)
        if auth_type == 'POP':
            self.mailer = POPMailer(smtp_host, smtp_port, login_user, login_pass, mail_encoding, pop_host, pop_port, pop_user, pop_pass)

    def sendmail(self, from_address, to_address, subject, body):
        self.from_address = from_address
        self.to_address   = to_address
        self.subject      = subject
        self.body         = body
        self.start()

    def run(self):
        self.mailer.sendmail(self.from_address, self.to_address, self.subject, self.body)


