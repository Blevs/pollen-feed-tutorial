#lang scribble/manual

@(require (for-label pollen/pagetree pollen/world pollen/template pollen/decode racket/match) "mb-tools.rkt")

@title{Creating an RSS Feed with Pollen}

In this tutorial you will build an atom RSS feed generator using Pollen. In the process, you will learn:

@itemlist[

@item{The Atom specification (or some of it).}

@item{Storing and retrieving metadata inside pollen files.}

@item{Using pagetrees as stores of relational information about files.}

@item{To leverage the power of Racket to extract and transform information from Pollen files.}
]

Keep in mind that one of the advantages of Pollen is the lack of restrictions on your freedom. This guide does not purport to be @italic{the} solution for your Pollen projects. Instead, it should guide you through the process of conforming its idea's to your existing structure.

At a high level, it represents organizational strategies and the tools available through Pollen and Racket to pull information from your documents and bring it into a single place.

@section{The Atom Specification}

Let's start by taking a look at the RSS feed you will build over the course of this tutorial:

@fileblock["atom.xml" 
@codeblock[#:keep-lang-line? #f]{
#lang pollen
<?xml version="1.0" encoding="utf-8"?>
   <feed xmlns="http://www.w3.org/2005/Atom">

     <title>Short Stories Blog</title>
     <subtitle>The best short stories of Phillip K. Dick</subtitle>
     <link href="http://example.com/pkd/blog/atom.xml" rel="self"/>
     <link href="http://example.com/pkd/blog/"/>
     <updated>2016-01-02T12:30:00-06:00</updated>
     <author>
       <name>Phillip K. Dick</name>
     </author>
     <id>urn:uuid:6463c846-128f-443e-8444-32e95a196742</id>

     <entry>
     	<title>The Variable Man</title>
     	<link href="http://example.com/pkd/blog/variable.html" />
     	<id>urn:uuid:6b773c5f-d840-4bfb-9c0b-2372d9009e61</id>
     	<updated>2016-01-02T12:30:00-06:00</updated>
        <summary type="html"><p>He fixed things—clocks, refrigerators,
        vidsenders and destinies. But he had no business in the future,
        where the calculators could not handle him. He was Earth’s only
        hope—and its sure failure!</p></summary>
     </entry>
     <entry>
     	<title>The Eyes Have It</title>
     	<link href="http://example.com/pkd/blog/eyes.html" />
     	<id>urn:uuid:d0118878-2215-43f2-9595-1f473d688d67</id>
     	<updated>2016-01-01T20:00:00-06:00</updated>
        <summary type="html"><p>A little whimsy, now and then, makes for
        good balance. Theoretically, you could find this type of humor
        anywhere. But only a topflight science-fictionist, we thought,
        could have written this story, in just this way...</p></summary>
     </entry>
     <entry>
     	<title>Beyond Lies the Wub</title>
     	<link href="http://example.com/pkd/blog/wub.html" />
     	<id>urn:uuid:ecc9e8ca-c8b1-4b58-8c8b-60bccf7d0fad</id>
     	<updated>2015-12-25T18:20:00-06:00</updated>
        <summary type="html"><p>The slovenly wub might well have said:
        Many men talk like philosophers and live like
        fools.</p></summary>
     </entry>

   </feed>
}]

Hopefully, it seems more uninteresting than overwhelming. While the actual @link["https://tools.ietf.org/html/rfc4287"]{Atom Specification} is quite long, this tutorial will cover the basics need to build a working feed and start experimenting.

As seen above, an Atom RSS feed is an xml document consisting of metadata and a number of entries. All of this information is contained within xml tags. Most of the tags are self explanatory. The @tt{<title>} contains a title, the @tt{<author>} an author, and so on. 

A few of the tags are less transparent. The @tt{<updated>} tag holds the date and time the feed or post was published in the @link["https://www.ietf.org/rfc/rfc3339.txt"]{RFC-3339} format. It is a useful format that encodes the date in order of significance, beginning with the year and ending with the second (followed by an offset for the timezone). This allows for direct comparison of date strings to determine order.

The @tt{<id>} tag contains a unique, permanent identifier of an entry over time and across feeds. Here, it is a @link["https://www.ietf.org/rfc/rfc4122.txt"]{UUID URN}, or Universally Unique IDentifier Uniform Resource Name. While there are many other options, these are easy to make unlike contortions of permlinks and dates and finger crossing that no one will ever make a feed with the same id.

More information about the specifics and methods to generate and integrate them into your workflow can be found in the @secref["Extras"] sections @secref["RFC-3339"] and @secref["UUID_URN"].

@section{Posts}

Now, lets create some sample posts to feed into your RSS feed. Each post will contain an h1 title tag and some body content. Additionally, the publish date and uuid will be stored in the metas hash table (see @secref["Inserting_metas"]). 

@fileblock["variable.html.pm" @codeblock{
#lang pollen

◊define-meta[publish-date]{2016-01-02T12:30:00}
◊define-meta[uuid]{6b773c5f-d840-4bfb-9c0b-2372d9009e61}

◊h1{The Variable Man}

He fixed things—clocks, refrigerators, vidsenders and destinies. But he had no
business in the future, where the calculators could not handle him. He was
Earth’s only hope—and its sure failure!

Security Commissioner Reinhart rapidly climbed the front steps and entered the
Council building. Council guards stepped quickly aside and he entered the
familiar place of great whirring machines. His thin face rapt, eyes alight
with emotion, Reinhart gazed intently up at the central SRB computer, studying
its reading.
}]

@fileblock["eyes.html.pm" @codeblock{
#lang pollen

◊define-meta[publish-date]{2016-01-01T20:00:00}
◊define-meta[uuid]{d0118878-2215-43f2-9595-1f473d688d67}

◊h1{The Eyes Have It}

A little whimsy, now and then, makes for good balance. Theoretically, you could
find this type of humor anywhere. But only a topflight science-fictionist, we
thought, could have written this story, in just this way...

It was quite by accident I discovered this incredible invasion of Earth by
lifeforms from another planet. As yet, I haven’t done anything about it; I
can’t think of anything to do. I wrote to the Government, and they sent back a
pamphlet on the repair and maintenance of frame houses. Anyhow, the whole thing
is known; I’m not the first to discover it. Maybe it’s even under control.

}]
@fileblock["wub.html.pm" @codeblock{
#lang pollen

◊define-meta[publish-date]{2015-12-25T18:20:00}
◊define-meta[uuid]{ecc9e8ca-c8b1-4b58-8c8b-60bccf7d0fad}

◊h1{Beyond Lies the Wub}

The slovenly wub might well have said: Many men talk like philosophers and live
like fools.

THEY had almost finished with the loading. Outside stood the Optus, his arms
folded, his face sunk in gloom. Captain Franco walked leisurely down the
gangplank, grinning.

}]

@section{@tt{atom.xml.pm}}

We will also need a pollen file for the rss feed itself.

@fileblock["atom.xml.pm" @codeblock{
#lang pollen

◊define-meta[uuid]{6463c846-128f-443e-8444-32e95a196742}
}]

That is it. All of the content for the generated file will be determined in the template. Though it is certainly possible to move more meta information, and even the content generating logic, into this file the proposed method is more straightforward and less dependent on knowledge of Pollen's quirks (see @seclink{Empowering_atom.xml.pm}).

@section{Pagetree}

With all of the markup files at hand it is time to make the @tt{index.ptree}. The posts will be children of the RSS feed. This will allow for easy access to them later with the aptly named @racket[children].

@fileblock["index.ptree" @codeblock{
#lang pollen

◊atom.xml{
    variable.html
    eyes.html
    wub.html
}
}]

Another valid strategy would be to maintain a separate file containing date sorted posts and use @racket[load-pagetree] and @racket[pagetree->list].

@section{Building an @tt{<entry>}}

Now it is time to take a closer look at a post's @tt{<entry>} in the feed:

@codeblock[#:keep-lang-line? #f]{
#lang pollen
<entry>
    <title>Beyond Lies the Wub</title>
    <link href="http://example.com/pkd/blog/wub.html" />
    <id>urn:uuid:ecc9e8ca-c8b1-4b58-8c8b-60bccf7d0fad</id>
    <updated>2015-12-25T18:20:00+06:00</updated>
    <summary type="html"><p>The slovenly wub might well have said: Many men
    talk like philosophers and live like fools.</p></summary>
</entry>
}

In order to pull all of that information from the Pollen files you will need to write a few functions for your @tt{pollen.rkt}.

@fileblock["pollen.rkt"
@codeblock{
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
}]

While the functions are, in this case, very short it is still a good idea to encapsulate the functionality in @tt{pollen.rkt} instead of writing the code directly in the template. You then get to reuse the components elsewhere while being able to change implementation details without the templates knowing the difference.

@section{template.xml}

Now that all the tools have been made, its time to put together the template.

@fileblock["template.xml" 
@codeblock[#:keep-lang-line? #f]{
#lang pollen
<?xml version="1.0" encoding="utf-8"?>
   <feed xmlns="http://www.w3.org/2005/Atom">

     ◊(define posts (children 'here))

     <title>My Short Stories Blog</title>
     <subtitle>The best short stories of Phillip K. Dick</subtitle>
     <link href="◊(pagenode-url here)" rel="self"/>
     <link href="◊|root-url|"/>
     <updated>◊(post-date-rfc3339 (car posts))</updated>
     <author>
       <name>Phillip K. Dick</name>
     </author>
     <id>◊(uuid here)</id>

     ◊(map (λ (post) ; potentially change to a for comprehension, I think
       (->html       ; the syntax and intention is clearer for a novice to parse
        `((entry 
           "\n\t" (title ,(title post)) 
           "\n\t" (link [[href ,(pagenode-url post)]]) 
           "\n\t" (id ,(uuid post))
           "\n\t" (updated ,(post-date-rfc3339 post)) 
           "\n\t" (summary [[type "html"]] ,(summary post))
           "\n")
           "\n")))
         posts)
   </feed>
}]

The interesting part of the template starts off on line 4 by defining a list of posts. Thanks to the pagetree setup (see @secref{Pagetree}), all of your posts are already stored as children of the @tt{atom.xml} file. 

For a different setup, it would be easy to modify this line to load another pagetree or perform some filtering, like taking a number of the most recent posts or only those in a certain category. 

There are even ways to move this definition into the markup file (see @seclink{Empowering_atom.xml.pm}) enabling different feeds without need to for individual templates. But, for now, this works just fine.

The following metadata itself is straightforward. Links are made to the feed and the website. After that, the date the feed was updated is pulled out of the first, and most recent, post. Finally, the uuid is retrieved from the feed file.

To create the entires some potentially new features of Racket are used. The first is @racket[map], which applies a given function to each item in a list. This is used to create an entry for every post in @tt{posts}. The function to make that entry is created using another @racket[lambda], though it could just as easily been defined @tt{pollen.rkt} or elsewhere. This function uses the @racket[->html] to render the entry to what is functionally equivalent to xml. (NOTE: Should this be changed? I have not encountered a problem with it in my testing, but I don't know an incredible amount about xml and html differences.)

The really self and powerful bit is how the entry is constructed. The @litchar{`} is a @racket[quasiquote]. Just like literal data can be made using a @litchar{'}, such as a list @code{'(a b c)}, a quasiquote can do the same, except expressions can be @racket[unquote]'d (abbreviated with the @litchar{,} operator) and replaced with their result, @code{`(a b ,some-var ,(some-expression))} (see @secref{Programming Racket Quasiquote}).

There are also some newlines (@litchar{\n}) and tabs (@litchar{\t}) thrown in to improve the output's human readability and are otherwise unnecessary.

And that is it, a working RSS feed generator with Pollen with what is about a notecard worth of implementation. 

@section{Extras}

There are many more ways of producing the above results, so the author suggests some additional ideas and tools for the curious.

@subsection[#:tag "Empowering_atom.xml.pm"]{Empowering @tt{atom.xml.pm}}

As it currently stands every decision for the content inside of the RSS feed in made inside of @tt{template.xml}. This greatly simplifies the process, but if you wanted to make more feeds with different aspects you would need to make a custom template for each. That violates what is so useful about the markup and template dichotomy. However, it is possible to transfer over some of the decision making functionality with clever use of the document body.

First, the simpler approach of defining dynamic values outside of the metas. Metas are great for many things, but because they are processed before the rest of the document there is no way to @racket[require] in other files or libraries before they are evaluated (NOTE: someone please correct me if I am wrong).

However, because the template doesn't actually render the document body you can be sneaky and place values inside and retrieve them with @racket[select] and its friends. This could be used to define the list of posts in the feed outside of the template:

@fileblock["atom.xml.pm" 
@codeblock{
#lang pollen

◊define-meta[uuid]{6463c846-128f-443e-8444-32e95a196742}

◊(require pollen/pagetree)

`(posts ,@"@"(children here))

}]

The @litchar{,@"@"} is the @racket[unquote-splicing] operator. The operation unquotes and evaluates the expression, removing the outer layer of parentheses from the substitute value and effectively @italic{splicing} its elements into the current list.

All of these elements can then be accessed in the template using the @racket[select*] function.

@fileblock["template.xml" 
@codeblock[#:keep-lang-line? #f]{
#lang pollen
<?xml version="1.0" encoding="utf-8"?>
   <feed xmlns="http://www.w3.org/2005/Atom">

     ◊(define posts (select* 'posts doc))

    ...
}]

Now multiple feeds can be made with different markup files while still using the same template.

If you want to take it even farther, you could put the entirety of the entry-generation functionality into the file, like so:

@fileblock["atom.xml.pm" 
@codeblock{
#lang pollen

◊define-meta[uuid]{6463c846-128f-443e-8444-32e95a196742}

◊(require pollen/pagetree)

◊(define posts (children 'here))

◊`(rss-entries 
    ,@"@"(map (λ (post) 
        `(entry 
            (title ,(title post)) 
            (link [[href ,(pagenode-url post)]]) 
            (id ,(uuid post))
            (updated ,(post-date-rfc-3339 post)) 
            (summary [[type "html"]] ,(summary post))))
         posts))

}]

Like the solution for defining the posts list in the document, the entires need to be placed inside of a tag, in this case @tt{rss-entires}. This is not only to provide @racket[select*] a target in the document, but because the document body must be encodable as a tagged X-expression. In this case, it means every list must begin with a symbol. That is why the list of entries must be encapsulated pulled out with @racket[select*], rather than straight through @tt{doc}. 

Wrapping the list with an arbitrary tag also provides the optional benefit of being able to add @tt{rss-entries} to the @tt{#:excluded-tags} section of your root @racket[decode] to prevent any meddling with the contents.

@fileblock["template.xml" 
@codeblock[#:keep-lang-line? #f]{
#lang pollen
<?xml version="1.0" encoding="utf-8"?>
   <feed xmlns="http://www.w3.org/2005/Atom">
    ...
    ◊(->html (select* 'rss-entires doc))
    ...
}]

And just like that it would be easy to create a secondary feed that contains entire posts instead of summaries, or whatever else you can think up.

@subsection{RFC-3339}

The RFC-3339 format can be sketched roughly as @tt{yyyy-mm-ddThh:mm:ss[+/-]hh:mm}. It is a very convenient format to use for post dates as two dates can be compared directly as strings, assuming they have the same time zone offset.

Dates in these formats can be generated using the GNU @tt{date} command:

@verbatim|{
$ date '+%FT%T%:z'
2016-01-13T13:44:10-06:00
}|

Unfortunately the BSD @tt{date} (the default on OS X) does not support @tt{%:z} and will not output a colon in the timezone offset. This can be corrected with quick @tt{sed} regex:

@verbatim|{
$ date +%Y-%m-%dT%T%z | sed 's/\([0-9]\{2\}\)$/:\1/'
2016-01-13T13:44:10-06:00
}|

A Vim user could insert the current date directly into their document with @tt{strftime}:

@verbatim|{
nnoremap <F3> a<C-R>=strftime("%FT%T%z")<CR><Esc>hi:<Esc>ll
inoremap <F3> <C-R>=strftime("%FT%T%z")<CR><Esc>hi:<Esc>lla
}|

While all of that is nice, you may have already chosen a different date format in your documents. Luckily, Racket can be made to output a @racket[date] struct (see @secref{time}) with a little tweaking.  

RFC-3339 is more specifically a subset of the ISO-8601 standard, which Racket is happy to output when asked:

@codeblock{
#lang racket
(require racket/date)

(date-display-format 'iso-8601)
(date->string (current-date) #t) ; ex. 2016-01-12T09:19:13
}

The only thing missing is the timezone. However, the @racket[date] struct has a field @tt{timezone-offset} which stores the offset in seconds as a signed integer. An RFC-3339 conversion function only needs to append the offset formatted as @tt{[+/-]hh:mm}. 

@codeblock{
#lang racket
(require racket/date format)

(define (date->string-rfc-3339 date)
  (date-display-format 'iso-8601)
  (define timezone-offset
    (if (= 0 (date-time-zone-offset date))
        "Z" ; UTC can be signified with a Z rather than an offset
        (let* ([offset-int (date-time-zone-offset (current-date))]
               [offset-date (seconds->date (abs offset-int) #f)]
               [sign (if (< 0 offset-int) "+" "-")])
          (string-append sign 
                         (~r (date-hour offset-date) 
                             #:min-width 2 #:pad-string "0")
                         ":"
                         (~r (date-minute offset-date) 
                             #:min-width 2 #:pad-string "0")))))
  (string-append (date->string date #t) timezone-offset))
}

Translating your own chosen format into a date struct is left as an exercise for the reader, but a suggestion would be @racket[regexp-split] and @racket[match].

@subsection{UUID URN}

The Atom id field must represent an unchanging, unique identifier for a feed or entry. How to make good ones is a very long and undecided debate. For simplicity, a method was chosen here to generate unique id's largely independent of implementation and nitty-gritty specification details. 

What the UUID means is a Universally Unique IDentifier. They are also reffered to by GUIDs, or  Globally Unique IDentifiers. The URN bit stands for Uniform Resource Name and essentially means that we are representing the UUID with a string formatted as @tt{"urn:uuid:(the actual uuid)"}. More specifically, it provides the URI, or Uniform Resource Identifier, namespace for the UUID. You might be familiar with more common ones, like @tt{http} or @tt{mailto}.

What the UUID is, however, is 128bit, unique (in time @italic{and} space) string that can be easily generated on demand in a variety of ways. You might ask just how easily. Well, if you are on a Linux system it is this easy:

@verbatim|{
$ cat /proc/sys/kernel/random/uuid
}|

In addition, there is a huge number of tools to do the same, including the Racket package @secref{libuuid}. 

In fact, using the power of Racket, you could write a function that reads pollen files writes in missing metas. Note that the following is less of a good, well tested, ready to use function and more accurately the exact, unrefined function I wrote the first day I picked up Racket and Pollen and wanted to do this. It could very obviously use a rewrite. 

@fileblock["uuid.rkt"
@codeblock{
#lang racket
(require libuuid 
         pollen/template
         racket/file)

(define (add-meta post key value)
  ; assumes that post is a relative, output path (read: pagenode)
  (define path-string ; transforms to absolute .pm file
    (format "~a~a.pm" (world:current-project-root) post))
  (define post-lines ; file should not be loaded until after metas are checked
    (file->lines path-string))
  (define new-meta-string 
    (format "◊define-meta[~a]{~a}" key value))
  (define (is-not-meta-line? line) ; only detects single line definitions
   (not (or (regexp-match? #rx"◊define-meta\\[.*\\].*" line)
       (regexp-match? #rx"◊\\(define-meta .*\\)" line))))
  (if (select-from-metas key post)
      ; if meta is already in file, return its value
      (select-from-metas key post)
      ; if metas is not in post, add the new-meta-string on the line before
      ; the first meta. If no metas are found, that would be the end of the document.
      ; Then return the newly written value
      (let-values ([(premeta postmeta) (splitf-at post-lines is-not-meta-line?)])
        (display-lines-to-file
          (append premeta (list new-meta-string) postmeta) path-string
          #:exists 'replace)
        value)))
}]

