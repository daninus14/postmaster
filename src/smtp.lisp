(in-package :cl-user)
(defpackage postmaster.smtp
  (:use :cl :postmaster.email)
  (:export :<smtp-server>
           :host
           :port
           :ssl
           :<smtp-account>
           :send))
(in-package :postmaster.smtp)

(defclass <smtp-server> ()
  ((host :reader host :initarg :host :type string)
   (port :reader port :initarg :port :type integer)
   (ssl :reader ssl :initarg :ssl :type (or null keyword)
        :initform :starttls)))

(defmethod initialize-instance :after ((server <smtp-server>) &key)
  "If the port has not been specified, set it according to the SSL preferences."
  (unless (slot-boundp server 'port)
    (setf (slot-value server 'port)
          (case (ssl server)
            (:tls 465)
            (:starttls 587)
            (nil 25)
            (t
             (error "Unknown SSL preference ~A." (ssl server)))))))

(defclass <smtp-account> ()
  ((server :reader server :initarg :server :type <smtp-server>)
   (auth-method :reader auth-method :initarg :auth-method :type (or null keyword))
   (username :reader username :initarg :username :type string)
   (password :reader password :initarg :password :type string)))

(defmethod send ((account <smtp-account>) (email <email>))
  (let ((server (server account)))
    (cl-smtp:send-email (host server)
                        (from email)
                        (to email)
                        (subject email)
                        (when (slot-boundp email 'body)
                          (body email))
                        :ssl (ssl server)
                        :port (port server)
                        :html-message
                        (when (slot-boundp email 'html-body)
                          (html-body email))
                        :authentication (if (and (slot-boundp account 'auth-method)
                                                 (auth-method account))
                                            (list (auth-method account)
                                                  (username account)
                                                  (password account))
                                            (list (username account)
                                                  (password account)))
                        :attachments (when (slot-boundp email 'attachments)
                                       (convert-attachment-list (attachments email))))))
