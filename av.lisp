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


#+nil
(vid-libinit)
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
(progn
  (defparameter *h2* (vid-alloc))
  (vid-init *h2* "/home/martin/Downloads2/RC_helicopter_upside_down_head_touch-1Lg6wASg76o.mp4" 640 480)
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

(let ((rot 0))
  (defun draw ()
    (destructuring-bind (w h) (glfw:get-window-size)
      (setf h (max h 1))
      (gl:viewport 0 0 w h)
      (gl:clear-color .0 .2 .2 1)
      (gl:clear (logior gl:+color-buffer-bit+ gl:+depth-buffer-bit+))
      (gl:matrix-mode gl:+projection+)
      (gl:load-identity)
;      (glu:perspective 65 (/ w h) 1 100)
      (gl:ortho 0 640 480 0 .01 10)
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
     
      (let* ((ww 640)
	     (hh 480)
	     (objs (make-array 2 :element-type '(unsigned-byte 32))))
	
	(sleep (/ 60))
	(gl:gen-textures (length objs) objs)
	(dotimes (i  (length objs)) 
	 (gl:bind-texture gl:+texture-2d+ (aref objs i))
	 ;;(gl:pixel-store-i gl:+unpack-alignment+ 1)
	 (gl:tex-parameter-i gl:+texture-2d+ 
			     gl:+texture-min-filter+ gl:+linear+)
	 (gl:tex-parameter-i gl:+texture-2d+ 
			     gl:+texture-mag-filter+ gl:+linear+)
	 )
	(gl:enable gl:+texture-2d+)
		
	(gl:matrix-mode gl:+modelview+)
	
	(let ((h *h*)
	      (i 0))
	  (when h
	    (gl:bind-texture gl:+texture-2d+ (aref objs i))
	    (vid-decode-frame h)
	    (gl:tex-image-2d gl:+texture-2d+ 0 gl:+rgba+
			     (vid-get-out-width h)
			     (vid-get-out-height h) 0
			     gl:+rgba+ gl:+unsigned-byte+
			     (vid-get-data h 0))
	    (gl:with-begin gl:+quads+
	      (labels ((c (a b)
			 (gl:tex-coord-2f (/ a ww)  (/ b hh))
			 (gl:vertex-2f a b)))
		(c 0 0)
		(c 0 hh)
		(c ww hh)
		(c ww 0)))))

	#+nil
	(let ((h *h2*)
	      (i 1))
	  (when h
	    (gl:bind-texture gl:+texture-2d+ (aref objs i))
	    (vid-decode-frame h)
	    (gl:tex-image-2d gl:+texture-2d+ 0 gl:+rgba+
			     (vid-get-out-width h)
			     (vid-get-out-height h) 0
			     gl:+rgba+ gl:+unsigned-byte+
			     (vid-get-data h 0))
	    (gl:translate-f 300 100 0)
	    (gl:with-begin gl:+quads+
	      (labels ((c (a b)
			 (gl:tex-coord-2f (/ a ww)  (/ b hh))
			 (gl:vertex-2f a b)))
		(c 0 0)
		(c 0 hh)
		(c ww hh)
		(c ww 0)))))
	
	

	
	(gl:disable gl:+texture-2d+)
	(gl:delete-textures (length objs) objs)))))


#+nil
(glfw:do-window (:title "bla" :width 512 :height 512)
    ()
  (when (eql (glfw:get-key glfw:+key-esc+) glfw:+press+)
    (return-from glfw::do-open-window))
  (draw))

