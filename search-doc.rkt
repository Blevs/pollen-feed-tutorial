#lang racket/base
(require (for-syntax racket/base))
(require sugar/define sugar/coerce txexpr)
(require pollen/file pollen/world pollen/cache pollen/pagetree)


(define+provide/contract (search-doc doc-source pred)
  ((or/c txexpr? pagenode? pathish?) procedure? . -> . (or/c #f txexpr?))
  (define tx (cond 
                  [(txexpr? doc-source) doc-source] 
                  [else (get-doc doc-source)]))
  (define (search-txexpr tx) 
    (cond
      [(pred tx) tx]
      [else (for/or ([x (get-elements tx)] #:when (txexpr? x))
              (search-txexpr x))]))
  (search-txexpr tx))

(define+provide/contract (search-doc* doc-source pred)
  ((or/c txexpr? pagenode? pathish?) procedure? . -> . (or/c #f (listof txexpr?)))
  (define tx (cond 
                  [(txexpr? doc-source) doc-source] 
                  [else (get-doc doc-source)]))
  (define (search-txexpr* tx)
    (for/fold ([matches (if (pred tx) (list tx) '())])
              ([x (get-elements tx)]
               #:when (txexpr? x))
                (append matches (search-txexpr* x))))
  (search-txexpr* tx))

(define (get-doc pagenode-or-path)
  ;  ((or/c pagenode? pathish?) . -> . (or/c txexpr? string?))
  (define source-path (->source-path (cond
                                       [(pagenode? pagenode-or-path) (pagenode->path pagenode-or-path)]
                                       [else pagenode-or-path])))
  (if source-path
      (cached-require source-path (world:current-main-export))
      (error (format "get-doc: no source found for '~a' in directory ~a" pagenode-or-path (current-directory)))))

(define (pagenode->path pagenode)
  (build-path (world:current-project-root) (symbol->string pagenode)))

(search-doc '(root (p "first") (p "second")) (λ (x) (equal? 'p (get-tag x))))

(search-doc* '(root (p "first") (p "second")) (λ (x) (equal? 'p (get-tag x))))

