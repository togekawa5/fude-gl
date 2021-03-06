(defpackage :fude-gl-examples
  (:use :cl)
  (:export #:demos))

(in-package :fude-gl-examples)

;;;; INTERFACE

(defun demos ()
  (restart-case (mapc #'funcall
                      '(hello-triangle uniform-demo colored-triangle
                                       element-buffer texture-demo mix-demo))
    (quit ())))

;;;; HELLO-TRIANGLE

(fude-gl:defshader hello-triangle 330 (fude-gl:xy)
  (:vertex () "gl_Position = vec4(xy, 0.0, 1.0);")
  (:fragment ((|outColor| :vec4)) "outColor = vec4(1.0, 1.0, 1.0, 1.0);"))

(defparameter *triangle*
  (concatenate '(array single-float (*))
               (make-instance 'fude-gl:xy :x 0.0 :y 0.5)
               (make-instance 'fude-gl:xy :x 0.5 :y -0.5)
               (make-instance 'fude-gl:xy :x -0.5 :y -0.5)))

(defun hello-triangle ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 800
                           :h 600)
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((hello-triangle *triangle*))
          (sdl2:with-event-loop (:method :poll)
            (:quit ()
              t)
            (:idle ()
              (sdl2:gl-swap-window win)
              (gl:draw-arrays :triangles 0 3))))))))

;;;; UNIFORM-DEMO

(fude-gl:defshader uniform-demo 330 (fude-gl:xy)
  ;; Re-use vertex-shader of HELLO-TRIANGLE.
  (:vertex () 'hello-triangle)
  (:fragment ((|outColor| :vec4) &uniform (|triangleColor| :vec3))
    "outColor = vec4(triangleColor, 1.0);"))

(defun uniform-demo ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 800
                           :h 600)
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((uniform-demo *triangle*
                                            :uniform (|triangleColor|)))
          (sdl2:with-event-loop (:method :poll)
            (:quit ()
              t)
            (:idle ()
              (sdl2:gl-swap-window win)
              (gl:uniformf |triangleColor|
                           (/ (+ 1.0 (sin (get-internal-real-time))) 2) 0.0
                           0.0)
              (gl:draw-arrays :triangles 0 3))))))))

;;;; COLORED-TRIANGLE

(fude-gl:defshader colored-triangle 330 (fude-gl:xy fude-gl:rgb)
  (:vertex ((color :vec3)) "color = rgb;" "gl_Position = vec4(xy, 0.0, 1.0);")
  (:fragment ((|outColor| :vec4)) "outColor = vec4(color, 1.0);"))

(defparameter *colored-triangle*
  (concatenate '(array single-float (*))
               (make-instance 'colored-triangle
                              :x 0.0
                              :y 0.5
                              :r 1.0
                              :g 0.0
                              :b 0.0)
               (make-instance 'colored-triangle
                              :x 0.5
                              :y -0.5
                              :r 0.0
                              :g 1.0
                              :b 0.0)
               (make-instance 'colored-triangle
                              :x -0.5
                              :y -0.5
                              :r 0.0
                              :g 0.0
                              :b 1.0)))

(defun colored-triangle ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 800
                           :h 600)
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((colored-triangle *colored-triangle*))
          (sdl2:with-event-loop (:method :poll)
            (:quit ()
              t)
            (:idle ()
              (sdl2:gl-swap-window win)
              (gl:draw-arrays :triangles 0 3))))))))

;;;; ELEMENT-BUFFER

(defparameter *element-buffer-example*
  (concatenate '(array single-float (*))
               (make-instance 'colored-triangle ; Top left
                              :x -0.5
                              :y 0.5
                              :r 1.0
                              :g 0.0
                              :b 0.0)
               (make-instance 'colored-triangle ; Top right
                              :x 0.5
                              :y 0.5
                              :r 0.0
                              :g 1.0
                              :b 0.0)
               (make-instance 'colored-triangle ; Bottom right
                              :x 0.5
                              :y -0.5
                              :r 0.0
                              :g 0.0
                              :b 1.0)
               (make-instance 'colored-triangle ; Bottom left
                              :x -0.5
                              :y -0.5
                              :r 1.0
                              :g 1.0
                              :b 1.0)))

(defun element-buffer ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 800
                           :h 600)
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((colored-triangle *element-buffer-example*))
          (fude-gl:with-gl-array ((elements
                                   (coerce '(0 1 2 2 3 0)
                                           '(array (unsigned-byte 8) (*)))))
            (sdl2:with-event-loop (:method :poll)
              (:quit ()
                t)
              (:idle ()
                (sdl2:gl-swap-window win)
                (gl:draw-elements :triangles elements)))))))))

;;;; TEXTURE

(fude-gl:defshader texture-demo 330 (fude-gl:xy fude-gl:rgb fude-gl:st)
  (:vertex ((color :vec3) (texcoord :vec2))
    "texcoord = st;"
    "color = rgb;"
    "gl_Position = vec4(xy, 0.0, 1.0);")
  (:fragment ((|outColor| :vec4) &uniform (tex :|sampler2D|))
    "outColor = texture(tex, texcoord) * vec4(color, 1.0);"))

(defparameter *quad*
  (concatenate '(array single-float (*))
               (make-instance 'texture-demo ; Top left
                              :x -0.5
                              :y 0.5
                              :r 1.0
                              :g 0.0
                              :b 0.0
                              :s 0.0
                              :t 0.0)
               (make-instance 'texture-demo ; Top right
                              :x 0.5
                              :y 0.5
                              :r 0.0
                              :g 1.0
                              :b 0.0
                              :s 1.0
                              :t 0.0)
               (make-instance 'texture-demo ; Bottom right
                              :x 0.5
                              :y -0.5
                              :r 0.0
                              :g 0.0
                              :b 1.0
                              :s 1.0
                              :t 1.0)
               (make-instance 'texture-demo ; Bottom left
                              :x -0.5
                              :y -0.5
                              :r 1.0
                              :g 1.0
                              :b 1.0
                              :s 0.0
                              :t 1.0)))

(defparameter *png*
  (opticl:read-png-file
    (probe-file
      (merge-pathnames "examples/lisplogo_alien_128.png"
                       (asdf:system-source-directory
                         (asdf:find-system :fude-gl-examples))))))

(defun texture-demo ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 800
                           :h 600)
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((texture-demo *quad*))
          (fude-gl:with-2d-textures ((tex *png*))
            (fude-gl:with-gl-array ((elements
                                     (coerce '(0 1 2 2 3 0)
                                             '(array (unsigned-byte 8) (*)))))
              (sdl2:with-event-loop (:method :poll)
                (:quit ()
                  t)
                (:idle ()
                  (sdl2:gl-swap-window win)
                  (gl:draw-elements :triangles elements))))))))))

;;;; MIX

(fude-gl:defshader mix-demo 330 (fude-gl:xy fude-gl:st)
  (:vertex ((texcoord :vec2))
    "texcoord = st;"
    "gl_Position = vec4(xy, 0.0, 1.0);")
  (:fragment ((|outColor| :vec4) &uniform (tex1 :|sampler2D|)
              (tex2 :|sampler2D|))
    "outColor = mix(texture(tex1, texcoord),
                     texture(tex2, texcoord),
                     0.5);"))

(defparameter *mix-demo*
  (concatenate '(array single-float (*))
               (make-instance 'mix-demo :x -0.5 :y 0.5 :s 0.0 :t 0.0)
               (make-instance 'mix-demo :x 0.5 :y 0.5 :s 1.0 :t 0.0)
               (make-instance 'mix-demo :x 0.5 :y -0.5 :s 1.0 :t 1.0)
               (make-instance 'mix-demo :x -0.5 :y -0.5 :s 0.0 :t 1.0)))

(defparameter *logo*
  (opticl:read-png-file
    (probe-file
      (merge-pathnames "examples/lisplogo_warning2_128.png"
                       (asdf:system-source-directory
                         (asdf:find-system :fude-gl-examples))))))

(defun mix-demo ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 800
                           :h 600)
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((mix-demo *mix-demo*
                                        :uniform ((tex1-loc tex1)
                                                  (tex2-loc tex2))))
          (fude-gl:with-gl-array ((elements
                                   (coerce '(0 1 2 2 3 0)
                                           '(array (unsigned-byte 8) (*)))))
            (fude-gl:with-2d-textures ((tex1 *png*) (tex2 *logo*))
              (gl:uniformi tex1-loc 0)
              (gl:uniformi tex2-loc 1)
              (sdl2:with-event-loop (:method :poll)
                (:quit ()
                  t)
                (:idle ()
                  (sdl2:gl-swap-window win)
                  (gl:draw-elements :triangles elements))))))))))

;;;; HELLO from glut-examples.

(fude-gl:defshader hello 330 (fude-gl:xy)
  (:vertex () "gl_Position = vec4(xy,0.0,1.0);")
  (:fragment ((color :vec4)) "color = vec4(1.0, 1.0, 1.0, 1.0);"))

(defparameter *hello-quad*
  (concatenate '(array single-float (*)) (make-instance 'hello :x -0.5 :y 0.5) ; top-left
               (make-instance 'hello :x 0.5 :y 0.5) ; top-right
               (make-instance 'hello :x -0.5 :y -0.5) ; bottom-left
               (make-instance 'hello :x 0.5 :y -0.5))) ; bottom-right

(defun hello ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 250
                           :h 250
                           :title "hello")
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((hello *hello-quad*))
          (fude-gl:with-gl-array ((elements
                                   (coerce '(0 1 2 2 3 1)
                                           '(array (unsigned-byte 8) (*)))))
            (sdl2:with-event-loop (:method :poll)
              (:quit ()
                t)
              (:idle ()
                (sdl2:gl-swap-window win)
                (gl:draw-elements :triangles elements)))))))))

;;;; DOUBLE from glut-examples.

(fude-gl:defshader double 330 (fude-gl::xyz)
  (:vertex ((|texCoord| :vec2) &uniform (transform :mat4))
    "gl_Position = transform * vec4(xyz, 1.0);")
  (:fragment ((color :vec4)) "color = vec4(1.0, 1.0, 1.0, 1.0);"))

(defparameter *double-quad*
  (concatenate '(array single-float (*))
               (make-instance 'double :x -0.5 :y 0.5 :z 0.0) ; top-left
               (make-instance 'double :x 0.5 :y 0.5 :z 0.0) ; top-right
               (make-instance 'double :x -0.5 :y -0.5 :z 0.0) ; bottom-left
               (make-instance 'double :x 0.5 :y -0.5 :z 0.0))) ; bottom-right

(defun double ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :flags '(:shown :opengl)
                           :x 100
                           :y 100
                           :w 250
                           :h 250
                           :title "double")
      (sdl2:with-gl-context (context win)
        (fude-gl:with-shader ((double *double-quad*))
          (fude-gl:with-gl-array ((elements
                                   (coerce '(0 1 2 2 3 1)
                                           '(array (unsigned-byte 8) (*)))))
            (let ((uniform (gl:get-uniform-location double "transform")))
              (sdl2:with-event-loop (:method :poll)
                (:quit ()
                  t)
                (:idle ()
                  (fude-gl::with-clear (win (:color-buffer-bit) :color
                                        '(0.2 0.3 0.3 1.0))
                    (gl:uniform-matrix uniform 4
                                       (vector
                                         (sb-cga:rotate* 0.0 0.0
                                                         (coerce
                                                           (fude-gl:radians
                                                             (get-internal-real-time))
                                                           'single-float))))
                    (gl:draw-elements :triangles elements)))))))))))
