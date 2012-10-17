(require :cffi)

(defpackage :v
  (:use :cl))

(in-package :v)

(cffi:load-foreign-library "./libav.so")

(cffi:defcfun "vid_alloc" :uint64)
(cffi:defcfun "vid_init"
    :void 
  (handle :uint64)
  (filename :string))

(defparameter *h* (vid-alloc))

(vid-init *h*  "/home/martin/Downloads2/XDC2012_-_OpenGL_Future-LesAb4sTXgA.flv")

(cffi:defcfun "vid_decode_frame" 
    :int
  (handle :uint64))

(vid-decode-frame *h*)


(cffi:defcfun "vid_get_width" :int (handle :uint64))
(cffi:defcfun "vid_get_height" :int (handle :uint64))
(cffi:defcfun "vid_get_data" (:pointer :uint8) (handle :uint64) (i :int))
(cffi:defcfun "vid_get_linesize" :int (handle :uint64) (i :int))

(vid-get-data *h* 0)

(vid-get-width *h*)
