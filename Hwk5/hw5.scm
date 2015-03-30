(define match-junk
  (lambda (k frag) 
    (call/cc (lambda (backtrack)  
      (if (and (<= 0 k) ;if k < 0 and frag is a list
          (pair? frag))
          (cons frag (lambda () ((backtrack match-junk (- k 1) (cdr frag))))) ;cons frag and get rest of list
          (cons '() (lambda () backtrack #f))))))) ;else backtrack

(define match-*
  (lambda (matcher frag) ;matcher is pat
    (call/cc (lambda (backtrack)
       (cons frag 
       (lambda () (backtrack 
       (let ((tail (matcher frag))) ;starting from empty
                   (and tail
                    (match-* matcher (car tail))))))))))) ;try to match next letter

(define match-symbol
  (lambda (sym frag)
    (call/cc (lambda (backtrack)
      (and (pair? frag)
      (eq? sym (car frag)) ; is the pattern like the fragment?
      (cons (cdr frag) (lambda () backtrack #f))))))) ; concat and check the rest of the frag

(define make-matcher
  (lambda (pat)
    (cond
      ((symbol? pat)
        (lambda (frag)
          (match-symbol pat frag)))

      ((eq? 'or (car pat)) ;or pat
        (let make-or-matcher ((pats (cdr pat))) ;define function match or'd letters
        (if (null? pats) ;null return false
            (lambda (frag) #f) 
            ; otherwise
              (let ((match-head (make-matcher (car pats)))
                    (match-tail (make-or-matcher (cdr pats))))
                          (lambda (frag)
                                  (call/cc (lambda (backtrack)
                                          (let ((res (match-head frag)))
                                                  (if (eq? res #f) 
                                                  (match-tail frag)
                                                   (cons (car res) (lambda () (backtrack
                                                          (let ((match_next ((cdr res))))
                                                                  (if (eq? match_next #f)
                                                                          (match-tail frag)
                                                                      match_next))))))))))))))
          ((eq? 'list (car pat))
              (let make-list-matcher ((pats (cdr pat)))
                  (if (null? pats)
                  (lambda (frag)
                    (call/cc (lambda (backtrack)
                          (cons frag (lambda () (backtrack #f)))))) ;
                 
                  (let ((match-head (make-matcher (car pats)))
                                (match-tail (make-list-matcher (cdr pats))))
                                          (lambda (frag)
                                          (call/cc (lambda (backtrack)
                                                  (let ((res (match-head frag)))
                                                          (if (eq? res #f)
                                                            #f
                                                            (let ((tail (match-tail (car res))))
                                                                (if (eq? tail #f)
                                                                  #f
                                                                  (cons (car tail)
                                                                  (lambda () (backtrack
                                                                  (let ((match_next ((cdr res))))
                                                                  (if (eq? match_next #f)
                                                                          #f
                                                                          (match-tail (car match_next))))))))))))))))))

((eq? 'junk (car pat))
      (let ((k (cadr pat)))
        (lambda (frag)
          (match-junk k frag))))
 
     ((eq? '* (car pat))
      (let ((matcher (make-matcher (cadr pat))))
        (lambda (frag)
          (match-* matcher frag)))))))