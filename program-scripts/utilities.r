rebol [
    Title:   "utilitites"
    Filename: %utilitites.r
    Author:  "Mike Yaunish"
    Copyright: "2017 - Mike Yaunish"
    Purpose: {support scripts for DB-Rider}    
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

use [body f pos][ ; This fixes the shift+tab bug in Rebol2
    ;-- patch `ctx-text/back-field` function to fix the bug
    body: copy/deep second f: get in ctx-text 'back-field
    insert body/2/while [if head? item [item: tail item]]
    ctx-text/back-field: func first :f :body
    ;-- remove test that disables face/action for back-tabs
    body: second get in ctx-text 'edit-text
    body: find body 'word?
    pos: at body/3/7/tab-char/5/6 11
    change/part pos pos/4 4
]

touch: func [ 
    {Set the modification timestamp of the file. Author: Gregg Irwin} 
    files [file! block!] "The file, or files, you want to stamp" 
    /with "Use a specified time rather than the current time." 
        time [date!] "The date and time to stamp them with" 
    /local rd-only 
][ 
    if not with [time: now] ; We have to turn off the read-only attribute if it's on. 
    foreach item compose [(files)] [ 
        rd-only: not get-modes item 'owner-write 
        set-modes to-file item [owner-write: true modification-date: time] 
        if rd-only [set-modes item [owner-write: false]] 
    ] 
    ; Should we return the time, even though it may not match the actual 
    ; stamp on the files due to OS differences? 
    ;time 
] 

attr: func [ 
    {Return current attributes for the file. Author: Gregg Irwin} 
    file [file!] 
    /with {Retrieve only selected attributes.} 
        sel {Selected attributes to retrieve.} 
    /avail {Return a list of attributes available for the file.} 
    /copy {Copy all attributes, which are safe to copy, to f2.} 
        f2 [file!] 
    /verbose
    /local a 
][ 
    if with [return get-modes file sel] 
    if avail [return get-modes file 'file-modes] 
    if copy [ 
        ;set-modes f2 a: get-modes file get-modes file 'copy-modes 
        ; Core 2.5 includes full-path, which it shouldn't 
        ;set-modes f2 a: get-modes file exclude get-modes file 'copy-modes [full-path] 
        set-modes f2 a: get-modes file get-modes file 'copy-modes 
        if verbose [ return a ]
        return
    ] 
    get-modes file get-modes file 'file-modes 
]

copy-dir: func [
    source 
    dest 
    /with {copy attributes}
    /local src-list
][
    if not exists? dest [make-dir/deep dest]
    foreach file read source [
        either find file "/" [
            either with [
                copy-dir/with source/:file dest/:file
            ][
                copy-dir source/:file dest/:file    
            ]
        ][
            either with [
                copy-file/with source/:file dest/:file
            ][
                copy-file source/:file dest/:file
            ]
        ]
    ]
]


find-in-array-at: func [ 
    blk [any-type!] 
    at-loc [integer!] 
    find-this 
    /with-index 
    /all 
    /local ndx i collected
    
][
    
	collected: copy []
	if ((length? blk) < 1) [
	    return false
	]
	ndx: 1
	foreach i blk [
		if find-this = (pick i at-loc) [
			either with-index [
			    either all [
                    append/only collected reduce [ i ndx ]
			    ][
			        return reduce [ i ndx ]	    
			    ]
				
			][
			    either all [
			        append/only collected i
			    ][
			        return i     
			    ]
			]
		]
		ndx: ndx + 1
	]
	if all [
	    return collected
	]
	return false
]

pack-quoted-values: func [ v /local quoted-vals i j ] [
    quoted-vals: delim-extract/pairs-only v "'" "'" 
    foreach i quoted-vals [
        if ( i <> none ) [
            j: copy i 
            replace/all j " " "^@"
            replace/all v i j
        ]
    ]    
]

unpack-quoted-value: func [ v ] [
    replace/all v "^@" " " 
]

interleave: func [words values][
    set words: context append map-each word words [to set-word! word] none values
    words
]

complex-set: func [ lit-path [block!] value [any-type!] /no-check /local prefix-path the-path the-field ] [
    either lit-word? last lit-path [
        prefix-path: copy/part lit-path ((length? lit-path) - 1 )
        the-path: to-path reduce prefix-path
        the-field: to-lit-word last lit-path
        either any [ no-check ( found? find the-path the-field )] [
            do bind reduce [to-set-path reduce lit-path  value] 'do
        ][  ; field doesn't already exist so create it
            append/only the-path the-field
            append/only the-path value
        ]
    ][
        do bind reduce [to-set-path reduce lit-path  value] 'do
    ]
]

copy-file: func [ 
        Source [file! url!] 
        Destination [file! url!]
        /with {copy file attributes}
    ] 
[
    write/binary Destination read/binary Source
    if with [
        attr/copy Source Destination
    ]
]

unique-time-string: func [/local nt ][
    nt: to-string now/precise
    replace/all nt "/" "-"
    replace/all nt ":" "-"
    replace/all nt "." "-"
]

set-extension: func [ str /with with-str /exclude /local the-suffix the-prefix ] [
    the-suffix: suffix? str
    either ( the-suffix = (to-file with-str ) ) [
        return str    
    ][
        either the-suffix [
            the-prefix: copy/part str ( (length? str ) - (length? to-string the-suffix) )
            either exclude [
                return the-prefix
            ][
                return rejoin [ the-prefix with-str ]    
            ]
        ][
            either exclude [
                return str
            ][
                return rejoin [ str with-str ]    
            ]
            
        ]        
    ]
]



refine-function: function [
    "Refines a function with the specified refinements." [catch]
    'f "The function"
     r "refinements" [any-block!]
    /args a "argument block"  [any-block!]
    
] [ df to-do p ]
[
    if args [
        df: refine-function :f r
        to-do: compose reduce [ df ]
        if (length? a) > 0 [
            for i 1 (length? a)  1 [
                append/only to-do a/:i
            ]
        ]
        return to-do
    ]
    p: to-path head insert/only head copy r f
    :p
]

to-YYYY-MM-DD: func [ a-date [date!] ] [
    rejoin [ pad a-date/year 4 "-" pad a-date/month 2 "-" pad a-date/day 2]
]

pad: func [text length [integer!] /with padding [char!]][
        padding: any [padding #"0"]
        text: form text
        skip tail insert/dup text padding length negate length
]

find-deep: func [ blk str /index? /local i j cnt ] [
    j: copy ""
    cnt: 1
    foreach i blk [ 
        if find i str [ 
            j: copy i
            either index? [     
                return cnt
            ][
                return j
            ]  
        ] 
        cnt: cnt + 1
    ]
    return none
]

replace-in-block: func [ 
    [catch] 
    the-block [block!]  
    new-data [any-type!] 
    index-loc [integer!] 
]
[
    throw-on-error [
        index-loc: index-loc - 1
        either ((type? new-data) = block! ) [
            insert/only (remove (skip the-block index-loc )) new-data    
        ][
            insert (remove (skip the-block index-loc )) new-data    
        ]
    ]
]

to-safe-decimal: func [ v /local ret-val ] [
    ret-val: v
    switch (to-string type? v) [
        "money" [
            ret-val: second v
        ]
        "string" [
            ret-val: copy v
            replace/all ret-val "," ""
            replace/all ret-val "$" ""
        ]
    ]
    return either attempt [ ret-val: to-decimal ret-val ][
        ret-val
    ][
       return 0        
    ]                

]

remove-lines: func [ filename search-arg [ string! block! ] /local file-in i ] [
    file-in: read/lines filename
    if ((type? search-arg) = string!) [
        search-arg: reduce [ search-arg ] 
    ]
    foreach i search-arg [
        remove-each value file-in reduce [ 'find 'value i ]
    ]
    return file-in
]

remove-lines-from-file: func [ 
    filename search-string [ string! block! ] 
    /preserve-attr
    /local output
][
    output: copy ""
    current-modes: attr filename
    output: remove-lines filename search-string
    write/lines filename output
    if preserve-attr [
        set-modes filename current-modes        
    ]
    
]

get-past-monday: func [ a-date [date!] ] [
    return a-date - ( (a-date/weekday) - 1 )
]

split-string-on-spaces: func [ 
    {returns number of lines in a given string, cut along spaces. 
    Won't work with a line length too short to make divisions
    }
    the-string {source string } 
    line-length {length of lines}
    /with line-delimiter {if specified string variable will be modified with defined delimiter}
    /local lines-found-count next-pos last-pos backward-find
]
[
    either ((length? the-string) <= line-length) [
        return 1
    ][
        lines-found-count: 1
        next-pos: skip the-string line-length
        last-pos: the-string
        while [ next-pos <> "" ] [
            backward-find: find/reverse next-pos " "
            if ( ((index? backward-find)) <=(index? last-pos) ) [
                backward-find: find next-pos " "
            ] ; find forward
            either found? backward-find [
                either with [
                    insert skip backward-find 1 line-delimiter
                    last-pos: skip backward-find (length? line-delimiter)
                    lines-found-count: lines-found-count + 1
                    next-pos: skip last-pos line-length
                ][
                    last-pos:  backward-find
                    lines-found-count: lines-found-count + 1
                    next-pos: skip backward-find line-length
                ]

            ][
                if with [ append the-string line-delimiter ]
                next-pos: ""
            ]
        ]
        return lines-found-count
    ]
]

date-to-DDD: func [ d ] [ 
    d: to-date d 
    uppercase copy/part ( pick system/locale/days d/weekday ) 3
]

get-timestamp: does [
    return rejoin [ to-YYYY-MM-DD now/date " " now/time ]
]
