(use-modules (haunt asset)
             (haunt builder blog)
             (haunt builder atom)
             (haunt builder assets)
             (haunt html)
             (haunt page)
             (haunt reader)
             (haunt reader commonmark)
             (haunt site)
             (haunt post)
             (commonmark)
             (srfi srfi-1))

(define (stylesheet name)
  `(link (@ (rel "stylesheet")
            (href ,(string-append "/css/" name ".css")))))

(define (menu-item href content)
  `(li (@ (class "pure-menu-item"))
       (a (@ (href ,href) (class "pure-menu-link"))
          ,content)))

(define (link href content)
  `(a (@ (href ,href)) ,content))

(define (javascript name)
  `(script (@ (src ,(string-append "/js/" name ".js")))))

(define (site-ref site key)
  (assq-ref (site-default-metadata site) key))

(define (atom-feed-attr title site)
  `(@ (rel ,(if (equal? title "Recent Posts")
                "alternate" "home"))
      (type "application/atom+xml")
      (href ,(string-append (site-domain site) "/feed.xml"))))

(define (post-tags tags)
  (map (lambda (tag)
         `(span (@ (class "tag")) ,tag))
       tags))

(define my-theme
  (theme #:name "OrangeShark"
         #:layout
         (lambda (site title body)
           `((doctype "html")
             (head
              (meta (@ (charset "utf-8")))
              (meta (@ (name "author")
                       (content ,(site-ref site 'author))))
              (meta (@ (name "generator")
                       (content "haunt")))
              (meta (@ (content "width=device-width, initial-scale=1.0")
                       (name "viewport")))
              (title ,(string-append title " - "(site-title site)))
              ,(stylesheet "pure-min")
              ,(stylesheet "grids-responsive-min")
              ,(stylesheet "style")
              (link ,(atom-feed-attr title site))
              (body
               (div (@ (id "layout") (class "pure-g"))
                    (div (@ (id "menu") (class "pure-u-1"))
                         (div (@ (class "home-menu pure-menu pure-menu-open pure-menu-horizontal"))
                              (a (@ (href "/") (class "pure-menu-heading pure-menu-link"))
                                 ,(site-title site))
                              (ul (@ (class "pure-menu-list"))
                                  ,(menu-item "/index.html" "Blog")
                                  ,(menu-item "/projects.html" "Projects")
                                  ,(menu-item "/about.html" "About"))))
                    (div (@ (class "pure-u-1 pure-u-md-3-4"))
                         (div (@ (class "content"))
                              ,body))
                    (div (@ (class "pure-u-1 pure-u-md-1-4"))
                         (div (@ (class "sidebar"))
                              (ul (li (a ,(atom-feed-attr title site) "Atom feed"))
                                  (li ,(link "https://github.com/OrangeShark" "GitHub"))
                                  (li ,(link "https://gitlab.com/OrangeShark" "GitLab")))))
                    (div (@ (class "pure-u-1"))
                         (div (@ (class "footer"))
                              (p "Site generated by " ,(link "https://haunt.dthompson.us/" "haunt"))
                              (p (emp ,(site-ref site 'footer))))))))))
         #:post-template
         (lambda (post)
           `(article
             (h1 (@ (class "post-title")) ,(post-ref post 'title))
             (p (@ (class "post-meta")) 
                ,(date->string* (post-date post))
                " - "
                ,@(post-tags (post-ref post 'tags)))
             (div ,(post-sxml post))))
         #:collection-template
         (lambda (site title posts prefix)
           (define (post-uri post)
             (string-append (or prefix "") "/"
                            (site-post-slug site post) ".html"))
           (map (lambda (post)
                  `(article
                    (h1 (@ (class "post-title"))
                        (a (@ (href ,(post-uri post))) ,(post-ref post 'title)))
                    (p (@ (class "post-meta")) ,(date->string* (post-date post))
                       " - " ,@(post-tags (post-ref post 'tags)))
                    ,@(if (pair? (car (post-sxml post)))
                          (take-while (lambda (elem) (eq? 'p (car elem))) (post-sxml post))
                          (list (post-sxml post)))
                    (p (a (@ (href ,(post-uri post))) "Read More"))))
                posts))))

(define (date-post-slug post)
  (define (file-base str)
    (car (string-split (cadr (string-split str #\/))
                       #\.)))
  (let ((post-parts (string-split (file-base (post-file-name post)) #\-)))
    (string-append (string-join (take post-parts 3) "/")
                   "/" (string-join (drop post-parts 3) "-"))))

(define (markdown-page title file-name body)
  (lambda (site posts)
    (make-page file-name
               (with-layout my-theme site title
                            (commonmark->sxml body))
               sxml->html)))

(define about-page
  (markdown-page
   "About" "about.html"
   "# About

My name is Erik Edrosa and this is my blog about Computer Science, Software Development,
and other related topics. I'm a professional software developer and graduated from
[Florida International University](www.fiu.edu) with a BS in Computer Science."))

(define project-page
  (markdown-page
   "Projects" "projects.html"
   "# Projects

Here are some select software projects.

- [guile-commonmark](https://github.com/OrangeShark/guile-commonmark) Implementation of CommonMark in GNU Guile Scheme."))


(site #:title "OrangeShark"
      #:domain "http://www.erikedrosa.com"
      #:default-metadata
      '((author . "Erik Edrosa")
        (email . "erik.edrosa@gmail.com")
        (footer . "© Erik Edrosa 2014-2017 All Rights Reserved"))
      #:make-slug date-post-slug
      #:readers (list commonmark-reader)
      #:builders (list (blog #:theme my-theme)
                       about-page
                       project-page
                       (atom-feed)
                       (atom-feeds-by-tag)
                       (static-directory "imgs")
                       (static-directory "css")))
