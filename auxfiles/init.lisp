(ql:quickload 'swank)

;; define some parameters for easier update
(defparameter *shutdown-port* 6200)
(defparameter *swank-port* 4016)

(defparameter *swank-server*
  (swank:create-server :port *swank-port* :dont-close t))

(ql:quickload 'my-home-project)

(let ((socket (make-instance 'sb-bsd-sockets:inet-socket
			     :type :stream :protocol :tcp)))
  (sb-bsd-sockets:socket-bind socket #(127 0 0 1) *shutdown-port*)
  (sb-bsd-sockets:socket-listen socket 1)

  (multiple-value-bind (client-socket addr port)
		       (sb-bsd-sockets:socket-accept socket)
		       
    (sb-bsd-sockets:socket-close client-socket)
    (sb-bsd-sockets:socket-close socket)))

(dolist (thread (sb-thread:list-all-threads))
  (unless (equal sb-thread:*current-thread* thread)
    (sb-thread:terminate-thread thread)))
(sleep 1)
(sb-ext:quit)
    
