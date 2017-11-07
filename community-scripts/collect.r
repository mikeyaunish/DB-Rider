;; =======================================================
;; Script: collect.r
;; downloaded from: www.REBOL.org
;; on: 11-Jul-2014
;; at: 20:43:50.028312 UTC
;; owner: greggirwin [script library member who can update
;; this script]
;; =======================================================
REBOL [
    File: %collect.r
    Date: 10-Jan-2006	
    Author: "Gregg Irwin"
    Title: "Collect Function"
    Purpose: {Eliminate the "result: copy [] ... append result value" dance.}
    library: [
        level: 'intermediate
        platform: 'all
        type: [function dialect]
        domain: [dialects]
        tested-under: [View 1.3.2 on WinXP by Gregg "And under a lot of other versions and products"]
        license: 'BSD
        support: none
    ]
]

collect: func [  ; a.k.a. gather ?
    [throw]
    {Collects block evaluations.}
    'word "Word to collect (as a set-word! in the block)"
    block [any-block!] "Block to evaluate"
    /into dest [series!] "Where to append results"
    /only "Insert series results as series"
    ;/debug
    /local code marker at-marker? marker* mark replace-marker rules
] [
    block: copy/deep block
    dest: any [dest make block! []]
    ; "not only" forces the result to logic!, for use with PICK.
    ; insert+tail pays off here over append.
    ;code: reduce [pick [insert insert/only] not only 'tail 'dest]
    ; FIRST BACK allows pass-thru assignment of value. Speed hit though.
    ;code: reduce ['first 'back pick [insert insert/only] not only 'tail 'dest]
    code: compose [first back (pick [insert insert/only] not only) tail dest]
    marker: to set-word! word
    at-marker?: does [mark/1 = marker]
    ; We have to use change/part since we want to replace only one
    ; item (the marker), but our code is more than one item long.
    replace-marker: does [change/part mark code 1]
    ;if debug [probe code probe marker]
    marker*: [mark: set-word! (if at-marker? [replace-marker])]
    parse block rules: [any [marker* | into rules | skip]]
    ;if debug [probe block]
    do block
    head :dest
]

    
