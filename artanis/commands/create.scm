;;  -*-  indent-tabs-mode:nil; coding: utf-8 -*-
;;  Copyright (C) 2015
;;      "Mu Lei" known as "NalaGinrut" <NalaGinrut@gmail.com>
;;  Artanis is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License and GNU
;;  Lesser General Public License published by the Free Software
;;  Foundation, either version 3 of the License, or (at your option)
;;  any later version.

;;  Artanis is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License and GNU Lesser General Public License
;;  for more details.

;;  You should have received a copy of the GNU General Public License
;;  and GNU Lesser General Public License along with this program.
;;  If not, see <http://www.gnu.org/licenses/>.

(define-module (artanis commands create)
  #:use-module (artanis utils)
  #:use-module (artanis env)
  #:use-module (artanis commands)
  #:use-module (artanis irregex)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match))

(define %summary "Create a new Artanis project.")

(define (show-help)
  (display announce-head)
  (display "\nUsage:\n  art create proj-path\n")
  (display announce-foot))

(define conf-header
"##  -*-  indent-tabs-mode:nil; coding: utf-8 -*-
##  Copyright (C) 2015
##      \"Mu Lei\" known as \"NalaGinrut\" <NalaGinrut@gmail.com>
##  Artanis is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.

##  Artanis is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.

##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.

## ---------------------------------------------------------------------
## The skeleton of config file, you may modify it on your own purpose.
## DON'T TYPE `;' AT THE END OF LINE!!!
## ---------------------------------------------------------------------

## Please read the manual or /etc/artanis/default.conf if you have problem
## to understand these items.\n
")

(define conf-footer "\n\n## End Of Artanis conf.\n")

(define (create-local-config)
  (define (->proper v)
    (match v
      ((or #t 'true 'on 'yes) 'enable)
      ((or #f 'false 'off 'no) 'disable)
      ((? list?) (format #f "~{~a~^,~}" v))
      (else v)))
  (define (->cstr ctb)
    (call-with-output-string
     (lambda (port)
       (for-each (lambda (c)
                   (match c
                     ((ns val)
                      (format port "~{~a~^.~} = ~a~%" ns (->proper val)))
                     (else (error create-local-config "BUG: Invalid conf value!" c))))
                 ctb))))
  (let* ((ctb (@@ (artanis config) *default-conf-values*))
         (cstr (->cstr ctb))
         (fp (open-file "artanis.conf" "w")))
    (display conf-header fp)
    (display cstr fp)
    (display conf-footer fp)
    (close fp)))

(define (touch f)
  (close (open-file f "w")))

;; ENHANCEME: make some color
(define (print-create-info pstr)
  (format #t "create~10t~a~%" pstr))

(define (tmp-cache-handler p)
  (define (-> f) (string-append p "/" f))
  (let ((readme (-> "README"))
        (route-cache (-> ".route.cache")))
    (print-create-info readme)
    (touch readme)
    (call-with-output-file route-cache
      (lambda (port)
        (format port ";; Do not touch anything!!!~%")
        (format port ";; All things here should be automatically handled properly!!!~%")))))

(define (benchmark-handler p)
  (define (-> f) (string-append p "/" f))
  (let ((readme (-> "README")))
    (print-create-info readme)
    (touch readme)
    ;; TODO: generate template
    ))

(define (sm-handler p)
  (define (-> f) (string-append p "/" f))
  (let ((readme (-> "README")))
    (print-create-info readme)
    (touch readme)
    ;; TODO: generate template
    ))

(define *files-handler*
  `(((sm) . ,sm-handler)
    ((tmp cache) . ,tmp-cache-handler)
    ((test benchmark) . ,benchmark-handler)))

(define *dir-arch*
  '((app (model controller view)) ; MVC stuff
    (sys (pages i18n)) ; system stuff
    (db (migration sm)) ; DB (include SQL Mappings)
    (log) ; log files
    (lib) ; libs
    (pub ((img (upload)) css js)) ; public assets
    (prv) ; private stuff, say, something dedicated config or tokens
    (tmp (cache)) ; temporary files
    (test (unit functional benchmark)))) ; tests stuffs

;; Simple recursive depth-first order traverser for generic tree (in list).
;; We use this function for making *dir-arch* directory tree, it's little data,
;; so we don't care about the performance very much.
(define (dfs t p l)
  (match t
    (() #t)
    (((r (children ...)) rest ...)
     (p r l)
     (for-each (lambda (x) (dfs (list x) p (cons r l))) children)
     (dfs rest p l))
    (((r) rest ...)
     (p r l)
     (dfs rest p l))
    ((children ...)
     (p (car children) l)
     (dfs (cdr children) p l))
    (else (error dfs "BUG: Impossible pattern! Please report it!" t))))

(define (create-framework)
  (define (->path p)
    (format #f "~{~a~^/~}" p))
  (define (generate-elements x l)
    (let* ((p (reverse (cons x l)))
           (pstr (->path p)))
      (mkdir pstr) ; generate path
      (print-create-info pstr)
      (and=> (assoc-ref *files-handler* p)
             (lambda (h) (h pstr)))))
  (dfs *dir-arch* generate-elements '()))

(define *entry-string*
  "
 (use-modules (artanis artanis)
              ;; Put modules you want to be imported here

              (artanis utils))
 ;; Put whatever you want to be called before server initilization here

 (init-server)

 ;; Put whatever you want to be called before server running here
")

(define (create-entry name)
  (let ((fp (open-file "ENTRY" "w")))
    (format fp ";; Artanis top-level: ~a~%" (getcwd))
    (display *entry-string* fp)
    (close fp)))

(define (working-for-toplevel)
  (define (gen-readme)
    (touch "README")
    (print-create-info "README"))

  (gen-readme)
  ;; TODO
  )

(define (create-project name)
  (define (within-another-app?)
    (let ((entry (find-ENTRY-path
                  (lambda (p) (string-append p "/" *artanis-entry*))
                  #:check-only? #t)))
      (and entry (verify-ENTRY entry))))
  (cond
   ((file-exists? name)
    (format #t
            "`~a' exists, please choose a new name or remove the existed one!~%"
            name))
   ((within-another-app?)
    (display "Can't create a new Artanis app within the directory of another, ")
    (display "please change to a non-Artanis directory first.\n")
    (exit 1))
   (else
    (print-create-info name)
    (mkdir name)
    (chdir name)
    (working-for-toplevel)
    (create-local-config)
    (create-framework)
    (create-entry name)
    (format #t "OK~%"))))

(define (create . args)
  (define (validname? x)
    (irregex-search "^-.*" x))
  (match args
    (("create" (or () (? validname?) "help" "--help" "-help" "-h")) (show-help))
    (("create" name) (create-project name))
    (else (show-help))))

(define main create)
