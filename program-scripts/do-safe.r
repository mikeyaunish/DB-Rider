rebol [
    Title: "do-safe"
    Filename: %do-safe.r
    Author: "Mike Yaunish"
    Purpose: {Support scripts for DB-Rider}
    License: {
        BSD 3-Clause License

        Copyright (c) 2017, Mike Yaunish
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, this
          list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

        * Neither the name of the copyright holder nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
        AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
        IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
        FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
        DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
        SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
        CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
        OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
        OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.	
    }    
]

find-valid-delim-string: func [ 
    src-string [string!]
    tgt-string [string!]
    /in-code-block code-block [ string! block! ]
    /local delims found-string pre-char pre-char-good? post-char-good? block-len fnd-at block-pos path-name block-val return-val
]
[
    delims: { []"^/^-()}            ;" matching quote
    found-string: copy ""
    return-val: copy []
    
    select-correct: func [ name /local cname ] [
        cname: copy name
        either ((first cname) =  #"^"")[ ; check for double quoted string
            return replace/all  cname   #"^"" ""
        ][
            return to-word cname
        ]
    ]
    if in-code-block [
        either ( code-block <> "" ) [
            if ((type? code-block) = string!) [
                code-block: reduce [ code-block ]
            ]
            orig-src-string: copy src-string
            block-val: load src-string
            
            foreach path-name code-block [
                block-val: select block-val select-correct path-name 
            ]
            correct-header: select-correct last code-block
            block-sample: mold/flat/only/all compose/deep [ ( correct-header ) [ (block-val) ] ]
            if (fnd-at: find src-string block-sample) [
                block-pos: ((index? fnd-at) - 1) 
            ]
            block-len: length? block-sample
            src-string: copy/part ( skip src-string block-pos ) block-len
        ][
            in-code-block: false
        ]
        if (tgt-string = "") [
            either in-code-block [
                return reduce [  (skip orig-src-string block-pos) ]
            ][
                return none
            ]
        ]
    ]
    while [ src-string: find src-string tgt-string ] [
        str-ndx: index? src-string 
        pre-char: back src-string
        pre-char-good?: false
        post-char-good?: false
        either ((index? src-string) <> (index? pre-char))[
            pre-str: to-string first pre-char
            if (found? find delims pre-str ) [
                pre-char-good?: true    
            ]
        ][
            pre-char-good?: true
        ]
        if pre-char-good? [
            either ((length? tgt-string) = (length? src-string))[
                post-char-good?: true                
            ][
                post-str: (skip src-string (length? tgt-string) )
                post-str: to-string first post-str
                if (found?  find delims post-str ) [
                    post-char-good?: true    
                ]
            ]
        ]
        if post-char-good? [
            either(in-code-block) [
                append return-val (skip orig-src-string ( block-pos + (index? src-string) - 1 ))
            ][
                append return-val src-string
            ]            
        ]
        src-string: next src-string
    ]
    either (return-val = []) [
        return none    
    ][
        return return-val
    ]
    
]


delim-extract: func [
        "returns a block of every string found that is surrounded by defined delimeters"
         source-str [string!] "Text string to extract from."
         left-delim [string!] "Text string delimiting the left side of the desired string."
         right-delim [string!] "Text string delimiting the right side of the desired string."
         /include-delimiters "Returned extractions will include the delimiters"
         /use-head "Head of string is used as left delimiter"
         /first "Return the first match found only"
         /pairs-only "Return only fully matched pairs of delimiters. Left and right delimiter need to be the same."
         /local tags tag i j paired-tags
]
[
    tag: ""
    tags: copy []
    if use-head [
        either include-delimiters [
            parse source-str [ copy tag thru right-delim ]
            insert head tag left-delim
        ][
            parse source-str [ copy tag to right-delim ]
        ]
        append tags tag
    ]
    either  include-delimiters [
        parse source-str [some [ [ thru left-delim copy tag to right-delim ] (append tags rejoin [ left-delim tag right-delim] )]]
    ][
        parse source-str [some [ [ thru left-delim copy tag to right-delim ] (append tags tag)]]
    ]
    either first [
    	either ((length? tags) = 0 ) [
    	    return none
    	][
    	    return tags/1
        ]
    ][
        either all [ pairs-only (left-delim = right-delim)][
            paired-tags: copy []
            foreach [ i j ] tags  [
                append paired-tags i
            ]
            return paired-tags
        ][
            return tags    
        ]
    ]
]

num-occurrences: func [big-string search-string [string!] /local num] [
    num: 0
    parse big-string [some [thru search-string (num: num + 1)]]
    return num
]

find-position-in-file: func [ 
    input-file 
    search-string   { string of "" will just find the code-block specified }
    code-block-name [ string! block! ]
    /rebol-script
    /local file-data found-at line-num prev-cr prev-ndx col-num line-here-count source-line-count zsd source-data j new-search-string fnd curr-msg
] 
[
    either rebol-script [
        file-data: load/all input-file
        file-data: mold/flat file-data
    ][
        file-data: read input-file
    ]
    found-at: find-valid-delim-string/in-code-block file-data search-string code-block-name
    
    
    if ((length? found-at) > 1 ) [
        curr-msg: query-user-msg-field/text
        replace curr-msg "ERROR:" (rejoin [  "ERROR APPEARS "(length? found-at)" TIMES:" ])
        user-msg/query curr-msg
    ]
    found-at: first found-at
    either found-at [
        line-num: (num-occurrences ( copy/part file-data (index? found-at)) "^/") + 1
        prev-cr: find/reverse found-at "^/"
        either not prev-cr [
            prev-ndx: 0
        ][
            prev-ndx: index? prev-cr
        ]
        col-num: ( (index? found-at) - prev-ndx )
        if rebol-script [
            line-here-count: 0
            source-line-count: 0
            zsd: source-data: read/lines input-file
            foreach i source-data [
                j: copy i 
                source-line-count: source-line-count + 1
                if all [  ((trim j) <> "") ((first trim j) <> #";") ] [
                    line-here-count: line-here-count + 1    
                ]
                if ( line-here-count = line-num ) [
                    break
                ]
            ]
            if ( search-string <> "" ) [
                line-num: source-line-count
                new-search-string: first parse search-string none
                if (fnd: find-valid-delim-string source-data/:source-line-count new-search-string) [
                    fnd: first fnd
                    col-num: index? fnd
                ]
            ]
        ]
        return reduce [ line-num col-num  ]
    ][
        return none
    ]
]


do-safe: func [ 
    do-this [ file! block! ] 
    error-response [ string! block! ] { 3 pieces to block: 1.) err-msg / 2.) filename / 3.) code-block-details }
    /local err the-error return-val
] 
[
    return-val: true
    either capture-errors [  ; Global variable 'capture-errors'
        if error? err: try [
            do do-this
            true ; make the try happy
        ][
            the-error: disarm :err 
            change-dir root-path
            show-error-details the-error error-response do-this
            return-val: false
        ]
    ][
        do do-this
    ]
    return return-val   
]

error-matrix: [ ; msg & code must be the first two entries in the matrix !!!
    [
         msg         [ rejoin [ "The word named: '" error-obj/arg1 "' is protected and ^/can not be used as a field name.^/Change the name of the field before restarting DB-Rider."] ]
        code         325 
        type         'script 
          id         'locked-word
    recovery         [ halt ]
    ]             
    [             
         msg        [ rejoin [{Can NOT connect to hostname: '} error-obj/arg1 {'.^/Either the server is down or the ^/hostname isn't correct.} ]  ]
        code        507 
        type        'access 
          id        'no-connect 
       where        'open-proto 
    ]             
    [             
         msg        {Username or password provided is NOT correct}
        code        800 
        type        'user 
          id        'message 
        arg1        [ {ERROR 1045} {Access denied} ]
    ]             
    [             
         msg        [ rejoin ["Database name: '" last parse error-obj/arg1 "'"  "' is UNKNOWN"]  ]
        code        800 
        type        'user 
          id        'message 
        arg1        ["ERROR 1049" "Unknown database" ]
    ]             
    [
        msg         {Creating query listing^/previous errors should be corrected to resolve this problem}
       code         311
       type         'script
         id         'cannot-use
       near         [as-pair tmp-pane/:idx/size/x rb-height]
    ]
    [
        msg         [ rejoin [ {Syntax error - missing '} error-obj/arg2 {'}]]
       code         201
       type         'syntax
         id         'missing
    ]
    [
        msg         {field-actions.r ~ previous errors need to be resolved.}
       code         300
       type         'script
         id         'no-value
       arg1         'field-actions
    ]
    [
          msg       [ rejoin [ {Invalid field name of: '} second to-block error-obj/arg1 {'} ] ]
         code       800
         type       'user
           id       'message
         arg1       "get-field-number"
         near       [get-field-number col-names reduce [datr-report-name "underlay" report-block-name]]
     recovery       [ 
                        source-error-string: second to-block error-obj/arg1 
                        source-error-file:   third to-block error-obj/arg1
                        source-error-block: reduce [ (fourth to-block error-obj/arg1) (fifth to-block error-obj/arg1) ]
                        error-msg: rejoin [ "report script at code block '" (fifth to-block error-obj/arg1) "'" ]
                        error-detail: rejoin [ "reference to invalid field name '" source-error-string "'" ] 
                    ]
    ]    
    [
          msg       [ rejoin [ {Invalid field name of: '} second parse/all error-obj/arg1 "'"  {'} ] ]
         code       800
         type       'user
           id       'message
         arg1       "get-field-number"
         near       [get-field-number field-name ["set-field" "report"]]
     recovery       [ 
                        source-error-string: trim/with mold/flat/only/all error-source "^/"
                        error-detail: rejoin [ "'" (third to-block error-obj/arg1) "' trying to access invalid field name: '" second to-block error-obj/arg1 "'^/Near: [" source-error-string "]" ] 
                    ]
    ]

    [
          msg       [ rejoin [ {Invalid field name of: '} second parse/all error-obj/arg1 "'"  {'} ] ]
         code       800
         type       'user
           id       'message
         arg1       "get-field-number"
         near       [get-field-number field-name ["get-field" "report"]]
     recovery       [ 
                        source-error-string: trim/with mold/flat/only/all error-source "^/"
                        error-detail: rejoin [ "'" (third to-block error-obj/arg1) "' trying to access invalid field name: '" second to-block error-obj/arg1 "'^/Near: [" source-error-string "]" ] 
                    ]
    ]
    [
          msg       [ rejoin [ {Invalid field name of: '} second to-block error-obj/arg1 {'} ] ]
         code       800
         type       'user
           id       'message
         arg1       "get-field-number"
         near       [get-field-number col reduce [datr-report-name "underlay" report-block-name]]
     recovery       [ 
                        source-error-string: second to-block error-obj/arg1 
                        source-error-file:   third to-block error-obj/arg1 
                        source-error-block: reduce [ (fourth to-block error-obj/arg1) (fifth to-block error-obj/arg1) ]
                        error-msg: rejoin [ "report script code-block: 'exended-totals'" ]
                        if ( source-error-block = ["underlay" "extended-totals"] )[
                            query-db/extended-totals-error: true
                        ]
                        error-detail: rejoin [ "reference to invalid field name '" source-error-string "'" ] 
                    ]
    ]
    [
          msg       [ rejoin [ {Invalid field name of: '} second to-block error-obj/arg1 {'} ] ]
         code       800
         type       'user
           id       'message
         arg1       "get-field-number"
         near       [get-field-number field-name ["get-field" "underlay" "at-each-total-on-columns-line"]]
     recovery       [ 
                        source-error-string: second to-block error-obj/arg1   
                        source-error-block: reduce [ (fourth to-block error-obj/arg1) (fifth to-block error-obj/arg1) ]
                        error-msg: rejoin [ "'" (third to-block error-obj/arg1) "' trying to access invalid field name: '" source-error-string "'" ] 
                        error-detail: copy error-msg
                    ]
    ]    
    [
          msg       [ rejoin [ {Invalid field name of: '} second to-block error-obj/arg1 {'} ] ]
         code       800
         type       'user
           id       'message
         arg1       "get-field-number"
         near       [get-field-number field-name ["set-field" "underlay" "at-each-total-on-columns-line"]]
     recovery       [ 
                        source-error-string: second to-block error-obj/arg1   
                        source-error-block: reduce [ (fourth to-block error-obj/arg1) (fifth to-block error-obj/arg1) ]
                        error-msg: "report script code-block: 'at-each-total-on-columns-line'"
                        error-detail: rejoin [ "'" (third to-block error-obj/arg1) "' trying to access invalid field name: '" source-error-string "'" ] 
                    ]
    ]        
    [
          msg       {creating valid 'extended-totals'}
         code       303
         type       'script
           id       'expect-arg
         arg1       'replace-in-block
         near       [replace-in-block grand-total-line1 underline etb/2]
     recovery       [ 
                        error-msg: copy {invalid entry in the 'extended-totals' code block }
                        error-detail: copy error-msg
                        source-error-block: "extended-totals"
                        if (query-db/extended-totals-error = true) [
                            query-db/extended-totals-error: false
                            abort-displaying-error?: true
                        ]
                    ]
    ] 
    [
          msg       {creating a valid report}
         code       300
         type       'script
           id       'no-value
        where       'create-underlay/return-total-rows/group-on-column
     recovery       [ 
                        this-report: query-db/current-report-name
                        source-error-file: replace (copy query-db/current-report-name) ".r" ".datr"
                        source-error-string: mold/flat/only/all error-obj/arg1  
                        source-error-block: [ "underlay" "group-on-column" ] 
                        error-msg: rejoin [ "report script at code block: 'group-on-column'" ]                        
                        error-detail: rejoin [  {'group-on-column' code block contains an ^/invalid referenece to field name: '} source-error-string {'} ]
                    ]
    ] 
    [
          msg       {creating a valid report}
         code       300
         type       'script
           id       'no-value
        where       'create-underlay/return-total-rows/group-on-column/total-on-columns
     recovery       [ 
                        this-report: query-db/current-report-name
                        source-error-file: replace (copy query-db/current-report-name) ".r" ".datr"
                        source-error-string: mold/flat/only/all error-obj/arg1  
                        source-error-block: [ "underlay" "total-on-columns" ] 
                        error-msg: rejoin [ "report script at code block: 'total-on-columns'" ]                        
                        error-detail: rejoin [  {'total-on-columns' code block contains an ^/invalid referenece to field name: '} source-error-string {'} ]
                    ]
    ] 
    
    [
          msg       {creating a valid report}
         code       303
         type       'script
           id       'expect-arg
         arg1       'column-name-to-number
        where       'create-underlay/return-total-rows/group-on-column
     recovery       [ 
                        this-report: query-db/current-report-name
                        source-error-file: replace (copy query-db/current-report-name) ".r" ".datr"
                        source-error-string: ""
                        source-error-block: [ "underlay" "group-on-column" ] 
                        error-msg: rejoin [ "report script at code block: 'group-on-column'" ]                        
                        error-detail: "Invalid entry at code block: 'group-on-column'"
                    ]
    ] 
    
    [
          msg       {creating a valid report}
         code       300
         type       'script
           id       'no-value
        where       'create-underlay/return-total-rows/total-on-columns
     recovery       [ 
                        this-report: query-db/current-report-name
                        source-error-file: replace (copy query-db/current-report-name) ".r" ".datr"
                        source-error-string: mold/flat/only/all error-obj/arg1  
                        error-msg: rejoin [  {report script. Reference to invalid item: '} source-error-string {'} ]
                        error-detail: rejoin [  {report script. Reference to invalid item: '} source-error-string {'} ]
                    ]
    ]
    [
          msg       {set-field infinite loop}
         code       902
         type       'internal
           id       'stack-overflow
         near       [set-field]
     recovery       [
                        error-detail: rejoin [ "Infinite loop created using 'set-field'^/Near: [" mold/flat/only/all error-obj/near "]"]
                    ]
    ]
    [
          msg       {set-field infinite loop}
         code       800
         type       'user
           id       'message
         arg1       {Infinite 'set-field' loop detected on field name}
     recovery       [
                        error-detail: rejoin [ error-obj/arg1 "^/Near: [" mold/flat/only/all error-obj/near "]"]
                    ]
    ]
    
    
    
] ; END error-matrix

show-error-details: func [ 
    error-obj error-response error-source
    /local fnd-in-matrix not-fnd? arg-val val m error-msg source-error-file show-error-script sample-line sample-line-num-string fnd-pos search-in mr error-detail request-button fnd res source-error-block source-error-string abort-displaying-error? arg-vals error-obj-val
]
[

    error-msg: copy ""
    error-detail: copy ""
    source-error-block: copy ""
    source-error-string: none
    abort-displaying-error?: false
    show-error-script: does [
        
        either source-error-string [
            sample-line: source-error-string
        ][
            sample-line: error-obj/near    
        ]
        if ((type? sample-line) = block!)[
            sample-line: mold/only/flat sample-line
        ]
        sample-line-num-string: delim-extract/include-delimiters to-string sample-line {(line} {) }
        if sample-line-num-string <> [] [
            replace sample-line (first sample-line-num-string) ""
        ]
        if (sample-line <> "") [
            sample-line: trim (first parse/all sample-line "^/")
        ]
        
        if source-error-file [
            either ( sample-line-num-string = [] ) [
                fnd-pos: find-position-in-file/rebol-script source-error-file sample-line source-error-block   
            ][
                fnd-pos: find-position-in-file source-error-file sample-line source-error-block
            ]
            either fnd-pos [
                query-db/edit-text-file/position source-error-file fnd-pos    
            ][
                query-db/edit-text-file source-error-file 
            ]
        ]
    ]
    fnd-in-matrix: find-in-array error-matrix 'code error-obj/code 
    source-error-file: none
    either ((type? error-response) = block!) [
        error-msg: copy first error-response
        source-error-file: second error-response
        if ((length? error-response) > 2) [
            source-error-block: third error-response
        ]
    ][
        error-msg: copy error-response
        if (( type? error-source) = file!) [ 
            source-error-file: error-source
        ]
    ]
    if ( fnd-in-matrix <> [] )[
        foreach entry fnd-in-matrix  [ ; bypass first two associative entries
            foreach [ nam val ] skip entry 4 [ ; process all name value pairs in the found error matrix
                not-fnd?: false
                either ( nam <> 'recovery ) [
                    either (find (form nam) "arg") [ ; special handling for any "ARG" type found
                        either ((type? val) = block!) [
                            ;arg-val: first val 
                            arg-vals: copy val       
                        ][
                            arg-vals: reduce [ to-string val ]
                        ]
                        foreach arg-val arg-vals [                        
                            search-in: to-string select error-obj nam
                            if (not found? find search-in arg-val ) [
                                not-fnd?: true
                                break
                            ]             
                        ]
                    ][ ; reglar name value pairing checked here
                        error-obj-val: select error-obj nam
                        not-fnd?: not switch/default ( to-string type? val) [
                            "block" [
                                found? find error-obj-val val 
                            ]
                        ][ ; default compare
                            error-obj-val = val 
                        ]
                        if not-fnd? [ break ] 
                    ]
                ][
                ]
            ] ; *********** END foreach [ nam val ]
            either (not not-fnd?) [
                if ((type? entry/msg) = block!) [
                    bind entry/msg 'error-obj    
                ]
                if (select entry 'recovery) [ 
                    do bind entry/recovery 'error-detail
                ]
                break
            ][
            ]
        ] ; ******************* END of foreach entry
        
    ]
    if ( not abort-displaying-error? ) [
        if (error-detail = "")  [
            error-detail: printerror/return-a-value error-obj    
        ]

        either source-error-file [
            append error-msg rejoin [ "^/      FILE: '" last split-path source-error-file
                {'^/    FOLDER: '} first split-path source-error-file {'}
            ]    
            request-button: [ "  Edit Script  " ]
            if (found? fnd: find error-detail "where:" )[
                error-detail: copy/part error-detail ((index? fnd) - 1) 
            ]
        ][
            request-button: []
        ]
        res: my-request/buttons rejoin [ {ERROR WITH: } error-msg 
            "^/-----------------------------------------------------------------------------^/"  
            error-detail
        ] request-button
        user-msg/query rejoin [ "ERROR: " replace/all error-detail "^/" "." ]
        if ( res = "  Edit Script  " ) [
            show-error-script
        ]
    ]
]

find-in-array: func [ra field [word!] value /local result] [
    result: copy []
    foreach record ra [
        if ((select record :field) = value) [
            append/only result record
        ]
    ]
    result
]

my-request: func [ 
    s 
    /face f 
    /separate
    /buttons buttons-val [ string! block! ]
    /local req-return the-offset l button-block button-size my-req name size ok-button area-s
]
[ 
    req-return: copy ""
    either face [
        the-offset: screen-offset? f
    ][
        the-offset: 20x20
    ]
    either separate [
        ok-button: []
    ][
        ok-button: [
            button "OK" #" " [        
            	req-return: "OK"      
    	            hide-popup  	
            ]
        ]
    ]
    l: compose [ 
        styles area-style
        area-s: area-scroll vscroll hscroll outer-edge read-only as-is font [name: font-fixed size: 14 ]  580x200 (s)
        across
        (ok-button)
    ]
    if buttons [
        button-block: to-blocked buttons-val
        foreach bstring button-block [
            button-size: to-pair reduce [ ((length? bstring) * 7 + 15) 24 ]
            append l compose/deep [ 
                button (bstring) (button-size)   [
                    req-return: (bstring) 
                    hide-popup
                ]
            ]                  
        ]
    ]        
    either separate [
        my-req: view/new layout l "Message" 
    ][
        my-req: inform layout l "Message"     
    ]
    return req-return
]

dump-obj: func [
    "Returns a block of information about an object." 
    obj [object!] 
    /match "Include only those that match a string or datatype" pat 
    /no-type-data /packed /centered
    /expand-near
    /local clip-str form-val form-pad words vals str wild
][
    clip-str: func [str] [
        trim/lines str 
        if (length? str) > 50 [str: append copy/part str 50 "..."] 
        str
    ] 

    form-val: func [val /no-clip ] [
        if any-block? :val [return reform ["length:" length? val]] 
        if image? :val [return reform ["size:" val/size]] 
        if any-function? :val [
            val: third :val 
            if block? val/1 [val: next val] 
            either no-clip [
                return split-str/pad-lines (either string? val/1 [copy val/1] [mold val]) 60 10 8
            ][
                return clip-str either string? val/1 [copy val/1] [mold val]
            ]
        ] 
        if object? :val [val: next first val] 

        either no-clip [
            return split-str/pad-lines (mold :val) 60 10 8
        ][
            return clip-str (mold :val)
        ]
    ] 
    
    form-pad: func [val size /right] [
        val: form val 
        either(right) [
            num: size - (length? val) 
            insert/dup val #" " size - length? val
            return reduce [ val num ]
        ][
            insert/dup tail val #" " size - length? val     
            return val
        ]
    ] 
    either packed [
        spacer: ""
    ][
        spacer: "   "    
    ]
    
    words: first obj 
    vals: next second obj 
    obj: copy [] 
    smallest-pad: 15
    
    
    wild: all [string? pat find pat "*"] 
    foreach word next words [
        type: type?/word pick vals 1 
        str: form word
        if any [
            not match 
            all [
                not unset? pick vals 1 
                either string? :pat [
                    either wild [
                        tail? any [find/any/match str pat pat]
                    ] [
                        find str pat
                    ]
                ] [
                    all [
                        datatype? get :pat 
                        type = :pat
                    ]
                ]
            ]
        ] [
            either(centered) [
                formed-word: form-pad/right (rejoin [ word ":" ] ) 15 
                str: copy formed-word/1
                if ( formed-word/2 < smallest-pad ) [
                    smallest-pad: formed-word/2
                ]
            ][
                str: form-pad (rejoin [ word ":" ] ) 15 
            ]
            append str #" " 
            if (not no-type-data) [
                append str form-pad type 10 - ((length? str) - 15) 
            ]    
            
            append obj reform [
                spacer str 
                if type <> 'unset! [
                    either all [ expand-near ( word = 'near ) ] [
                        form-val/no-clip mold ( pick vals 1) 
                    ][
                        form-val/no-clip pick vals 1
                    ]
                ] 
                newline
            ]
        ] 
        vals: next vals
    ] 
    if (centered) [
        foreach i obj [
            remove/part i smallest-pad
        ]
    ]
    obj
]

dump-error-obj: func [ o ] [ 
    dump-obj/no-type-data/packed/centered/expand-near o 
]

split-str: func [
    str [string!] {input string} 
    len [ integer!] {max length of string}  
    tol [integer!] {margin tolerance}
    /pad-lines pad-size
    /local end-pos str-pos res-str pad-str space-at gap-of next-str-pos space-correction copy-length
] 
[
    end-pos: len
    str-pos: 0
    res-str: copy {}
    pad-str: copy ""
    if pad-lines [
        insert/dup pad-str " " pad-size
    ]
    while [ ( end-pos < (length? str)) ] [
        either (space-at: find/last/part str " " end-pos)[
            space-at: index? space-at    
        ][
            space-at: 0
        ]
        either ((gap-of: end-pos - space-at) < ( tol + 1 ) ) [
            next-str-pos: space-at
            space-correction: 1
        ][
            gap-of: 0
            next-str-pos: str-pos + len
            space-correction: 0
        ]
        end-pos: next-str-pos + len
        copy-length: ( len - gap-of - space-correction)
        append res-str rejoin [ head remove tail ( copy/part ( skip str str-pos ) copy-length ) newline pad-str ]
        str-pos: next-str-pos
    ]
    append res-str ( copy/part ( skip str str-pos ) len ) 
    res-str
]

to-blocked: func [ v /local blk ] [
    either ((type? v) = block!) [
        return v    
    ][
        blk: copy []
        insert/only blk v
        return blk
    ]
]
