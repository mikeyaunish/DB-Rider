;; ============================================
;; Script: split.r
;; downloaded from: www.REBOL.org
;; on: 29-Mar-2017
;; at: 16:27:09.25391 UTC
;; owner: greggirwin [script library member who
;; can update this script]
;; ============================================
REBOL [
    File: %split.r
    Date: 6-May-2012
    Title: "Split.r"
    Author: "Gregg Irwin"
    Purpose: {
        Provide functions to split a series into pieces, according to 
        different criteria and needs.
    }
    library: [
        level: 'intermediate
        platform: 'all
        type: [module function dialect]
        domain: [parse dialects text text-processing]
        tested-under: [View 2.7.8 on Win7]
        license: 'MIT
    ]
]

use [map-each test split-tests] [

    ; R3-compatible map-each interface.
    ;
    ; This is local to the context for SPLIT, because it is not designed
    ; to be fully R3 MAP-EACH compatible. For that, you should look at
    ; Brian Hawley's %r2-forward.r.
    ;
    ; What happens if the result of the DO is unset!? For now, we'll
    ; ignore unset values. The example case being SPLIT, which uses
    ; MAP-EACH with an unset value for negative numeric vals used to
    ; skip in the series.
    scollect: func [
        {Evaluates a block, storing values via KEEP function, and returns block of collected values.}
        body [block!] "Block to evaluate"
        /into {Insert into a buffer instead (returns position after insert)}
        output [series!] "The buffer series (modified)"
    ][
        unless output [output: make block! 16]
        do make function! [keep] copy/deep body make function! [value /only] copy/deep [
            output: either only [insert/only output :value] [insert output :value]
            :value
        ]
        either into [output] [head output]
    ]
    
    
    map-each: func [
        'word 
        data [block!] 
        body [block!]
        /local tmp
    ] [
        scollect compose/deep [
            repeat (word) data [
                set/any 'tmp do bind/copy body (to lit-word! word)
                if value? 'tmp [keep/only :tmp]
            ]
        ]
    ]

    ; R2 version.
    ;
    ; There are differences from the version in R3 which, itself, will likely
    ; need to be revisited due to changes in R3.
    split: func [
        [catch]
        {Split a series into pieces; fixed or variable size, fixed number, or at delimiters}
        series [series!] "The series to split"
        dlm [block! integer! char! bitset! any-string!] "Split size, delimiter(s), or rule(s)."
        /into {If dlm is an integer, split into n pieces, rather than pieces of length n.}
        /local size count mk1 mk2 res piece-size fill-val add-fill-val type
    ][
        ; This is here becaus using "to series", which should work, fails if the
        ; target type is paren!. If we ignore that case, all the "to type" bits
        ; can go away completely.
        type: type? series
        
        either all [block? dlm parse dlm [some integer!]] [
            map-each len dlm [
                either positive? len [
                    to type copy/part series series: skip series len
                ] [
                    series: skip series negate len
                    ()
                ]
            ]
        ] [
            size: dlm
            res: scollect [
                parse/all series case [
                    all [integer? size into] [
                        if size < 1 [throw make error! compose  [script invalid-arg size]]
                        count: size - 1
                        ; Max 1 is to catch when size is larger than the series, giving us 0.
                        piece-size: max 1 round/down divide length? series size
                        [
                            count [copy series piece-size skip (keep/only to type series)]
                            copy series to end (keep/only to type series)
                        ]
                    ]
                    integer? dlm [
                        if size < 1 [throw make error! compose  [script invalid-arg size]]
                        [any [copy series 1 size skip (keep/only to type series)]]
                    ]
                    'else [
                        ; This is quite a bit different under R2, in order to stop 
                        ; at the end properly and collect the final value.
                        [
                            any [
                                mk1: [
                                    to dlm mk2: dlm (keep to type copy/part mk1 mk2)
                                    | to end mk2: (keep to type copy mk1) skip
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            ;-- Special processing, to handle cases where the spec'd more items in
            ;   /into than the series contains (so we want to append empty items),
            ;   or where the dlm was a char/string/charset and it was the last char
            ;   (so we want to append an empty field that the above rule misses).
            fill-val: make type none
            add-fill-val: does [append/only res fill-val]
            case [
                all [integer? size  into] [
                    ; If the result is too short, i.e., less items than 'size, add
                    ; empty items to fill it to 'size.
                    ; We loop here, because insert/dup doesn't copy the value inserted.
                    if size > length? res [
                        loop (size - length? res) [add-fill-val]
                    ]
                ]
                ; integer? dlm [
                ; ]
                'else [ ; = any [bitset? dlm  any-string? dlm  char? dlm]
                    ; If the last thing in the series is a delimiter, there is an
                    ; implied empty field after it, which we add here.
                    case [
                        bitset? dlm [
                            ; ATTEMPT is here because LAST will return NONE for an 
                            ; empty series, and finding none in a bitest is not allowed.
                            if attempt [find dlm last series] [add-fill-val]
                        ]
                        ; These cases are now handled, under R2, by the parse rule, and
                        ; no longer require special handling.
                        ;char? dlm [
                        ;    if dlm = last series [add-fill-val]
                        ;]
                        ;string? dlm [
                        ;    if all [
                        ;        find series dlm
                        ;        empty? find/last/tail series dlm
                        ;    ] [add-fill-val]
                        ;]
                    ]
                ]
            ]
                    
            res
            
        ]
    ]
]
