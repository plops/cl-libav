(require :cffi)

(eval-when (:compile-toplevel :execute :load-toplevel)
  (require :cl-glfw)
  (require :cl-glfw-opengl-version_1_1)
  (require :cl-glfw-glu))

(defpackage :v
  (:use :cl))

(in-package :v)

(cffi:load-foreign-library "./libav.so")
(cffi:defcfun "vid_libinit" :void)
(cffi:defcfun "vid_alloc" :uint64)
(cffi:defcfun "vid_free" :void (handle :uint64))
(cffi:defcfun "vid_init"
    :int
  (handle :uint64)
  (filename :string)
  (w :int)
  (h :int))

(cffi:defcfun "vid_decode_frame" 
    :int
  (handle :uint64))

(cffi:defcfun "vid_get_width" :int (handle :uint64))
(cffi:defcfun "vid_get_height" :int (handle :uint64))
(cffi:defcfun "vid_get_out_width" :int (handle :uint64))
(cffi:defcfun "vid_get_out_height" :int (handle :uint64))
(cffi:defcfun "vid_get_data" (:pointer :uint8) (handle :uint64) (i :int))
(cffi:defcfun "vid_get_linesize" :int (handle :uint64) (i :int))

(cffi:defcfun "vid_close" :void (handle :uint64))
 


(defvar *h* nil)
(defvar *h2* nil)
(defvar *vids* nil)

(defparameter *vids*
  (mapcar #'first
	  (sort 
	   (mapcar #'(lambda (x)
		       (list x
			     (with-open-file (s x)
			       (file-length s))))
		   (directory 
		    (merge-pathnames #p"*/*.*" "/dev/shm/")))
	   #'>
	   :key #'second)))

#+nil
(vid-libinit)
#+nil
(progn
 (defparameter *h*
   (loop for e in (subseq *vids* 0 9) collect
	(let ((h (vid-alloc)))
	
	  (vid-init h (format nil "~a" e) 128 128)
	  (vid-decode-frame h)
	  (format t "~a~%" (list e (vid-get-width h) (vid-get-height h)))
	  h)))
 (format t "finished~%"))
#+nil
(loop for i below (length *h*) do
     (vid-close (elt *h* i))
     (let ((hnew (vid-alloc))
	   (fn (format nil "~a" (elt *vids* (random (length *vids*))))))
       (format t "openingj ~a~%" fn)
       (vid-init hnew fn 128 128)
       (setf (elt *h* i) hnew)))


#+nil
(dolist (h *h*)
  (vid-close h))

#+nil
(progn
  (defparameter *h* (vid-alloc))
  (vid-init *h*  "/home/martin/Downloads2/XDC2012_-_OpenGL_Future-LesAb4sTXgA.flv"
	    128 128)
  (vid-decode-frame *h*))
#+nil
(vid-get-out-width *h*)
#+nil
(vid-close *h*)
#+nil
(dotimes (i 10000)
 (vid-decode-frame *h*))
#+nil
(loop for i from 0 do
     (format t "~d~%" i)
   while
     (= 1 (vid-decode-frame *h2*)))
#+nil
(vid-decode-frame *h2*)
#+nil
(progn
  (defparameter *h2* (vid-alloc))
  (vid-init *h2* "/home/martin/Downloads2/RC_helicopter_upside_down_head_touch-1Lg6wASg76o.mp4" 128 128)
  (vid-decode-frame *h2*))


(declaim (optimize (speed 0) (safety 3) (debug 3)))
#+nil
(defparameter *h* (vid-alloc))
#+nil
(vid-init *h*  "/home/martin/Downloads2/XDC2012_-_OpenGL_Future-LesAb4sTXgA.flv")
#+nil
(defparameter *h2* (vid-alloc))
#+nil
(vid-init *h2* "/home/martin/Downloads2/RC_helicopter_upside_down_head_touch-1Lg6wASg76o.mp4")

#+Nil
(vid-get-data *h* 0)

(let ((t1 0d0)
      (t0 0d0)
      (frames 0))
 (defun count-fps ()
   (setf t1 (glfw:get-time))
   (when (or (< 1 (- t1 t0))
             (= frames 0))
     (glfw:set-window-title (format nil "bla ~,1f FPS"
                                    (/ frames (- t1 t0))))
     (setf frames 0
           t0 t1))
   (incf frames)))

(let ((rot 0)
      (start t))
  
  (defun draw ()
    (count-fps)
    (when start
      (setf start nil)
      (vid-libinit)
      (when *h*
	(loop for i below (length *h*) do
	   (vid-close (elt *h* i))))
      (progn
	(defparameter *h*
	  (loop for e in (subseq *vids* 0 (min (* 11 6) 9 (1- (length *vids*)))) collect
	       (let ((h (vid-alloc)))
		 
		 (vid-init h (format nil "~a" e) 128 128)
		 (vid-decode-frame h)
		 (format t "~a~%" (list e (vid-get-width h) (vid-get-height h)))
		 h)))
	(format t "finished~%"))
      #+nil 
      (loop for i below (length *h*) do
	   (vid-close (elt *h* i))
	   (let ((hnew (vid-alloc))
		 (fn (format nil "~a" (elt *vids* (random (length *vids*))))))
	     (format t "openingj ~a~%" fn)
	     (vid-init hnew fn 128 128)
	     (setf (elt *h* i) hnew)))
      )
    (destructuring-bind (w h) (glfw:get-window-size)
      (setf h (max h 1))
      (gl:viewport 0 0 w h)
      (gl:clear-color .0 .2 .2 1)
      ;(gl:clear (logior gl:+color-buffer-bit+ gl:+depth-buffer-bit+))
      (gl:matrix-mode gl:+projection+)
      (gl:load-identity)
;      (glu:perspective 65 (/ w h) 1 100)
      (gl:ortho 0 (* 11 128) (* 6 128) 0 .01 10)
      (gl:matrix-mode gl:+modelview+)
      (gl:load-identity)
      #+nil      (glu:look-at 0 1 10 ;; camera
			      0 0 0   ;; target
			      0 0 1))
    (gl:translate-f 0 0 -1)
    (gl:rotate-f 0 0 0 1)
    (if (< rot 360)
	(incf rot .3)
	(setf rot 0))
    (gl:with-push-matrix
      ;(gl:rotate-f rot 0 0 1)
     
      (let* ((objs (make-array (length *h*) :element-type '(unsigned-byte 32))))
	;(sleep (/ .3 60))
	(gl:gen-textures (length objs) objs)
	(dotimes (i  (length objs)) 
	  (gl:bind-texture gl:+texture-2d+ (aref objs i))
	  ;;(gl:pixel-store-i gl:+unpack-alignment+ 1)
	  (gl:tex-parameter-i gl:+texture-2d+ 
			      gl:+texture-min-filter+ gl:+linear+)
	  (gl:tex-parameter-i gl:+texture-2d+ 
			      gl:+texture-mag-filter+ gl:+linear+))
	(gl:enable gl:+texture-2d+)
	(gl:matrix-mode gl:+modelview+)
	(let ((result (make-array (length *h*) :initial-element (sb-sys:int-sap 0))))
	  (let ((ths
		 (loop for i from 0 and h in *h* collect
		      (sb-thread:make-thread
		       #'(lambda ()
			   (when (= 0 (vid-decode-frame h))
			     (format t "closing video ~a~%" h)
			     (vid-close h)
			     (let ((hnew (vid-alloc))
				   (fn (format nil "~a" (elt *vids* (random (length *vids*))))))
			       (format t "openingb ~a~%" fn)
			       (vid-init hnew fn 128 128)
			       (vid-decode-frame hnew)
			       (setf (elt *h* i) hnew)))
			   (setf (elt result i) (vid-get-data h 0)))))))
	    (loop for e in ths do
		 (sb-thread:join-thread e)))
	 
	 (loop for i from 0 and e across result do
	      (unless (sb-sys:sap= e (sb-sys:int-sap 0))
	       (let ((ww 128)
		     (hh 128))
		 (progn
		   (gl:bind-texture gl:+texture-2d+ (aref objs i))
		  
		   (gl:tex-image-2d gl:+texture-2d+ 0 
				    gl:+rgba+
				    128
				    128
				    0
				    #x80e1 ;; bgra 
				    ;;gl:+rgba+ 
				    gl:+unsigned-byte+
				    e))
		 (gl:with-push-matrix 
		   (let ((ii (mod i 6))
			 (jj (floor i 6)))
		     (gl:translate-f (* jj ww) (* ii hh) 0))
		   (gl:with-begin gl:+quads+
		     (labels ((c (a b)
				(gl:tex-coord-2f (/ a ww)  (/ b hh))
				(gl:vertex-2f a b)))
		       (c 0 0)
		       (c 0 hh)
		       (c ww hh)
		       (c ww 0))))))))
	
	(gl:disable gl:+texture-2d+)
	(gl:delete-textures (length objs) objs)))))


#+nil
(glfw:do-window (:title "bla" :width (* 11 128) :height (* 6 128))
    ()
  (when (eql (glfw:get-key glfw:+key-esc+) glfw:+press+)
    (return-from glfw::do-open-window))
  (draw))


