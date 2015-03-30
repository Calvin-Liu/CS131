(define frag0 '())
(define frag1 '(a t g c t a))
;
; Scheme does not care about the newlines in the definition of frag2.
; From Scheme's point of view, they are merely extra white space that
; is ignored.  The newlines are present only to help humans understand
; how the patterns defined below are matched against frag2.
(define frag2 '(c c c g a t a a a a a a g t g t c g t
                a
                a g t a t a t g g a t a
                t a
                a g t a t a t g g a t a
                c g a t c c c t c g a t c t a))

; Most of the uses of "list" in the following pattern definitions
; are as a symbol that is part of a pattern, not as a procedure.
; However, there are two exceptions, one when defining pat3
; and the other when defining pat4.
(define pat1 '(list a t g c))
(define pat2 '(or
               (list a g t a t a t g g a t a)
               (list g t a g g c c g t)
               (list c c c g a t a a a a a a g t g t c g t)
               (list c g a t c c c (junk 1) c g a t c t a)))
(define pat3 (list 'list pat2 '(junk 2)))
(define pat4 (list '* pat3))

; For each pattern defined above, use "make-matcher" to create a
; matcher that matches the pattern.
(define matcher1 (make-matcher pat1))
(define matcher2 (make-matcher pat2))
(define matcher3 (make-matcher pat3))
(define matcher4 (make-matcher pat4))


; Return the first solution acceptable to ACCEPT.
(define (acceptable-match matcher frag accept)
  (let ((r (matcher frag)))
    (and r
         (or (accept (car r))
             ((cdr r))))))

; Return the first match.
(define (first-match matcher frag)
  (acceptable-match matcher frag (lambda (frag1) frag1)))

; Return true if the matcher matches all of the fragment.
(define (match-all? matcher frag)
  (acceptable-match matcher frag null?))

; Output all solutions.
(define (write-then-fail matcher frag)
  (let ((m (matcher frag)))
     (if m
         (begin
	   (write (car m))
           (newline)
           ((cdr m)))
         (void))))

; Some test cases.
(first-match matcher1 frag0) ; ⇒ #f

; A match must always match an entire prefix of a fragment.
; So, even though matcher1 finds a match in frag1,
; it does not find the match in (cons 'a frag1).
(first-match matcher1 frag1) ; ⇒ (t a)
(first-match matcher1 (cons 'a frag1)) ; ⇒ #f

(first-match matcher2 frag1) ; ⇒ #f
(first-match matcher2 frag2) ; ⇒ (a
;                                 a g t a t a t g g a t a
;                                 t a
;                                 a g t a t a t g g a t a
;                                 c g a t c c c t c g a t c t a)

; These matcher calls match the same prefix,
; so they return unmatched suffixes that are eq?.
(eq? (first-match matcher2 frag2)
     (first-match matcher3 frag2)) ; ⇒ #t

; matcher4 is lazy: it matches the empty fragment first,
; but you can force it to backtrack by insisting on progress.
(eq? (first-match matcher4 frag2)
     frag2) ; ⇒ #t
(eq? (first-match matcher2 frag2)
     (acceptable-match matcher4
           frag2
           (lambda (frag) (if (eq? frag frag2) #f frag))))
; ⇒ #t

; Here null? is being used as an acceptor.
; It accepts only the empty unmatched suffix,
; so it forces matcher4 to backtrack until all of frag2 is matched.
(match-all? matcher1 frag2) ; ⇒ #f
(match-all? matcher4 frag2) ; ⇒ #t
