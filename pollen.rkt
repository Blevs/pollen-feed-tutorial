#lang racket
(require pollen/decode
         pollen/template
         txexpr
         "search-doc.rkt")

(provide (all-defined-out))

; Pull a post's title out of the first h1 tag
(define (title post)
  (select 'h1 post))

; Define the website root url for use in links
(define root-url "http://example.com/pkd/blog/")

; Make a link to a pagenode by appending it to the root-url
(define (pagenode-url pagenode)
  (format "~a~a" root-url pagenode))

; Get a post's date in RFC-3339. 
(define (post-date-rfc-3339 post)
  (select-from-metas 'publish-date post))

; Retrieve and format a uuid from a post
(define (uuid post)
  (string-append "urn:uuid:" (select-from-metas 'uuid post)))

; Retrieve the first paragraph X-expression in a post
; Obviously depends on the decision to expose get-doc or add search-doc
; or an alternate solution.
(define (summary post)
  (search-doc post (λ (x) ; Create a predicate function to check tags for 'p
                     (equal? 'p (get-tag x))))) 

; Implementation detail. Tells pollen to make blocks of text separated
; by a blank line into paragraphs, but replace newlines with spaces to
; remove the hard line wraps from the rendered files.
(define (root . items)
  (decode (make-txexpr 'root '() items)
          #:txexpr-elements-proc 
          (λ (x) (detect-paragraphs x #:linebreak-proc 
                  (λ (x) (detect-linebreaks 
                          x #:insert " "))))))
