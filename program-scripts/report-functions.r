rebol [
    Title:   "report-functions"
    Filename: %report-functions.r
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

get-rebol-scripts-for-report-type: func [ 
    the-path [ file!]
    the-report-type [string!]
    /all-types
    /local res-list file-list script-name full-name src-file rt hf
]
[
    res-list: copy []
    if ( not exists? the-path ) [ 
        make-dir/deep the-path 
        return []
    ]
    file-list: read the-path
    foreach script-name file-list [ 
        if ( find/any script-name "*.r" ) [
            either all-types [
                append/only res-list script-name        
            ][
                full-name: join the-path script-name
                src-file: load/all full-name
                if ( select src-file 'rebol ) [
                    hf: load/header full-name
                    if ((type? hf) = block!) [
                        hf: hf/1
                    ] ; in case that is an object then leave it alone
                    if (rt: select hf 'for-report-type) [
                        if any [ (rt = the-report-type) (rt = "all" ) ] [
                            append/only res-list set-extension/exclude script-name 
                        ]
                    ]
                ]
            ]
        ]
    ]
    return res-list
]

get-available-reports: func [ 
    the-path [ file!]
    /local res-list file-list script-name full-name rt hf src-file report-type
]
[
    res-list: copy []
    if ( not exists? the-path ) [ 
        make-dir/deep the-path 
        return []
    ]
    file-list: read the-path
    foreach script-name file-list [ 
        if ( find/any script-name "*.datr" ) [
            full-name: join the-path script-name
            src-file: load/all full-name
            if ( found? report-type: select src-file 'report-type ) [
                script-name: set-extension/exclude script-name
                append/only res-list reduce [to-string script-name report-type ]
            ]
        ]
    ]
    return res-list
]

to-valid-rebol-name: func [ s /local valid-chars digits  ] [
    valid-chars: charset [#"a" - #"z" #"A" - #"Z" #"0" - #"9" #"-"]	
    digits: charset "0123456789"
    replace/all s " " "-" 
    replace/all s negate valid-chars "_"
    trim/all s 
    if ( found? find digits first s) [
        insert s "#"
    ]
   return s
]

report-context: context [
    data-block: copy []
    the-layout: copy []
    record-index: 1
    full-report-name: copy ""
    to-argument-block: func [ the-args /local ret a] [
        ret: copy []
        foreach a the-args [
            append ret reduce [ (to-set-word a) ( get a) ]
        ]
        return ret
    ]

    set-field: func [ 
        field-name [ string! ]  
        set-val 
        /local pos 
    ] 
    [
	    pos: get-field-number field-name ["set-field" "report"]
	    if (data-block/:record-index) [
	        replace-in-block (data-block/:record-index) set-val pos     
	    ] 
	]
	
	get-record-id: func [ 
	    [catch] 
	]
	[
	    if error? try [
            return data-block/:record-index/1
            true ; make the try happy
        ][
            throw make error! rejoin [ {Problem retrieving the current record ID}] 
        ]
	]
	
	get-field: func [ 
	    field-name [ string! ] 
	    /local pos  
	]
	[
	    pos: get-field-number field-name [ "get-field" "report" ]
	    return if (data-block/:record-index) [ data-block/:record-index/:pos ]
	]
	
	get-field-number: func [ 
	    [catch] 
	    field-name 
	    reference-point [block!] {block identifying where potential error originates from}
	    /local err-script-name err-msg1 err-msg2 zz field-list i do-report-name
	] 
	[
	    if error? try [
      	    res: find-in-array-at/with-index the-layout 2 field-name
            return ((second res) + 1)
            true ; make the try happy
        ][
            throw make error! rejoin [ {"get-field-number" "} field-name {" } mold/flat/all/only reference-point ] 
        ]
	]

	get-row: does [
	    return data-block/:record-index 
	]
	
	remove-row: does [
	    remove skip data-block ( record-index - 1 )
	]
    
    all-records-loop: func [ 
		arl-data-block 
		all-code
		arl-the-layout
		/local col the-code ins-val set-col get-col err the-error
		/no-error-trap
    ] 
    [
        ;throw-on-error [ 
        data-block: copy arl-data-block
        the-layout: copy arl-the-layout
    	record-index: 1
    	
    	foreach the-code all-code [ ; ensure there are block entries in "the-code" for each -loop type.
    		if ( not select the-code 'before-loop )[
    			insert the-code reduce [ 'before-loop [] ]
    		]
    		if ( not select the-code 'in-loop )[
    			insert the-code reduce [ 'in-loop [] ]
    		]
    		bind the-code/before-loop 'data-block
    		bind the-code/in-loop 'data-block
    	]	

    	is-pos?: func [ val ] [
    		if ( val = "" ) [ return false ]
    		either ( (to-decimal val) > 0) [
    			return true	
    		][
    			return false
    		]
    	]

    	do-report-name: copy full-report-name 
    	replace do-report-name ".r" ".datr" 

    	foreach the-code all-code [
    	    do-safe the-code/before-loop 
    	    reduce [ 
    	        "Report script in 'before-loop' block" 
    	        do-report-name
    	    ]
    	]
    	
    	loop (length? data-block) [
        	foreach the-code all-code [
                do-safe the-code/in-loop 
                reduce [
                    "report script at code block: 'in-loop'"
                    do-report-name
                ]
        	]
        	record-index: record-index + 1
    	]
    ]

    create-underlay: func [ 
        cu-data-block 
        underlay-data
        /group-on-column
        /total-on-columns
        /extended-totals
        /at-each-total-on-columns-line
        /finish-up
        /return-total-rows
        /local groups last-group-id ret-block total-rows all-group-block total-column-number 
        make-blank-record return-block insert-string a group-column curr-group-block 
        curr-group-id sample-record blank-record total-column-values extended-total-block 
        extended-total-values group-number tcn-index ptcn new-val total-line2 total-line1 fib new-total col err the-error grand-total-line1 etv-index grand-total-line2 underline extract-val-and-format ndx blk-ndx col-blk fmt-blk default-format v get-xtotal-format ret-blk total-column-format extracted-val-and-format extended-total-format tot-col-val x-tot-val get-field set-field
    ]
    [
        default-format: #.0
        data-block: copy cu-data-block
        total-line2: 0
        extended-total-block: copy []
        extract-val-and-format: func [ 
            col-format-block [ block! ]
            /local ndx blk-ndx col-blk fmt-blk v
        ][
            ndx: 0
            blk-ndx: 0
            col-blk: copy []
            fmt-blk: copy []
            while [ ndx < ( length? col-format-block ) ] [
                ndx: ndx + 1
                blk-ndx: blk-ndx + 1
                v: col-format-block/:ndx
                either ((type? v) = issue!) [
                    blk-ndx: blk-ndx - 1
                    replace-in-block fmt-blk v blk-ndx
                                    
                ][
                    append col-blk v
                    append fmt-blk default-format
                ]
            ]
            return reduce [ col-blk fmt-blk ]
        ] 
        get-xtotal-format: func [
            xtotal-blk [ block! ]
            /local ret-blk i 
        ][
            ret-blk: copy []
            foreach i xtotal-blk [
                either ((type? last i) = issue!) [
                    append ret-blk last i            
                ][
                    append ret-blk #.0
                ]
            ]
            return ret-blk 
        ]
           
        new-line data-block true
        new-line underlay-data true
        underline: "____________"
        
        groups: copy []
        all-group-block: copy []
        last-group-id: none
        ret-block: copy []
        total-rows: copy []
        total-column-number: [ 1 ]
        total-column-format: copy []
        make-blank-record: func [ 
            sample-block 
            /with-this with-this-text 
            /with-this-at with-this-at-string with-this-index 
            /local return-block 
        ]
        [
            return-block: copy []
            insert-string: copy ""
            if with-this [
                insert/dup insert-string with-this-text 20
            ]                
            insert return-block "0"
            insert/dup tail return-block insert-string ((length? sample-block) - 1)
            if with-this-at [ ; replace position in record with with-this-at-string 
                replace-in-block return-block with-this-at-string with-this-index
            ]
            return return-block
        ]
        add-row: func [ 
            row-vals [block!] { A block of blocks with this format [ "<field-name>" <field-value> #<field-format-issue> ] format is optional}
            /local new-row ndx default-format total-length cnum val fmt set-xrow-default-format fld-num
        ][
            row-vals: reduce row-vals
            set-xrow-default-format: func [ row-values ] [
                ndx: 3
                default-format: #.0
                total-length: ((length? row-values) + 1 )
                while [(ndx <= total-length )] [
                    if ((type? row-values/:ndx) <> issue! ) [
                        insert (skip row-values (ndx - 1)) default-format
                    ]
                    ndx: ndx + 3
                    total-length: ((length? row-values) + 1 )
                ]
            ]
            
            set-xrow-default-format row-vals
            new-row: copy []
            insert/dup new-row "" (length? ret-block/1)
            foreach [ field-name val fmt ] row-vals [
                fld-num: get-field-number field-name [ "report" "add-row"  ]
                replace-in-block new-row (format val fmt) fld-num
            ]
        	append/only ret-block new-row
        ]
        column-name-to-number: func [ 
            col-names [ block! string! integer! ]
            /report-block report-block-name [ string!] 
            /local return-val col datr-report-name
        ]
        [
            if not report-block [
                report-block-name: copy ""
            ]
            return-val: copy []
            datr-report-name: copy full-report-name
            replace datr-report-name ".r" ".datr" 
            if ((type? col-names) <> block!) [
                either ((type? col-names) <> string!) [
                    return col-names
                ][
                    return get-field-number col-names reduce [datr-report-name "underlay" report-block-name]
                ]
            ]
            foreach col col-names [
                append return-val
                switch/default (mold type? col) [
                    "string!" [ get-field-number col reduce [ datr-report-name "underlay" report-block-name ] ] 
                    "block!" [ reduce [ column-name-to-number/report-block col report-block-name ] ] 
                ][ col ] ;default
            ]
            return return-val            
        ]
        get-column-total: func [ column-number [ integer! string! ] /local fnd ndx-pos ] [
            if ((type? column-number) = string! ) [
                column-number: get-field-number column-number [ "report" "underlay" "get-column-total"  ]
            ]
            either (found? fnd: find total-column-number column-number ) [
                ndx-pos: index? fnd
            ][
                return none!
            ]
            pick total-column-values ndx-pos
        ]
        get-extended-total: func [ column-number [ integer! string! ] /local fnd ndx-pos ] [
            if ((type? column-number) = string! ) [
                column-number: get-field-number column-number [ "report" "underlay" "get-extended-total"  ]
            ]
            either (found? fnd: find-in-array-at/with-index  extended-total-block 2 column-number ) [
                ndx-pos: second fnd
            ][
                return none!
            ]
            return to-safe-decimal pick extended-total-values ndx-pos
        ]
        either (group-on-column) [
            if ( (type? underlay-data/group-on-column) = block! ) [
                group-on-column-block: underlay-data/group-on-column
                bind group-on-column-block 'groups
                bind group-on-column-block 'column
                group-column: column-name-to-number/report-block (first reduce group-on-column-block) "group-on-column" ; can return none if there is a error
            ]
            either group-column = none [
                all-group-block: reduce [ data-block ] 
            ][
                all-group-block: copy []
                curr-group-block: copy []
                foreach rec data-block [
                    curr-group-id: to-string (pick rec group-column) ; Group text identifier IE: '2-12-2013'
                    if curr-group-id = "" [
                        curr-group-id: "0" 
                    ]
                    either any [ (curr-group-id = last-group-id)]   [
                        append/only curr-group-block rec
                        last-group-id: copy curr-group-id

                    ][ ; NEW group 
                        if  (last-group-id <> none)  [ ; if not first record 
                            append/only all-group-block curr-group-block
                        ]
                        last-group-id: copy curr-group-id                
                        curr-group-block: copy []
                        append/only curr-group-block rec
                    ]                       
                ]            
                append/only all-group-block curr-group-block
            ]
        ][
            all-group-block: reduce [ data-block ] 
        ]
        sample-record: first first all-group-block 
        blank-record: make-blank-record sample-record
        ret-block: copy []
        if total-on-columns [
            a: underlay-data/total-on-columns
            bind a 'columns
            bind a 'groups
            total-column-number: reduce a
                                    
            total-column-number: column-name-to-number/report-block  total-column-number "total-on-columns"
            
            extracted-val-and-format: extract-val-and-format total-column-number
            total-column-number: extracted-val-and-format/1
            total-column-format: extracted-val-and-format/2
            either ( (type? total-column-number) = block!)[
                total-column-values: array/initial (length? total-column-number) 0            
            ][  ; Turn the individual value into a block - so totalling is streamlined below
                total-column-values: array/initial 1 0            
                total-column-number: to-block total-column-number
            ]
        ]
        if extended-totals [
            do-report-name: copy full-report-name 
        	replace do-report-name ".r" ".datr" 
            do-safe [
                extended-total-block: reduce-block-1deep underlay-data/extended-totals
                extended-total-block: column-name-to-number/report-block  extended-total-block "extended-totals"
                extended-total-format: get-xtotal-format extended-total-block
                extended-total-values: array/initial (length? extended-total-block ) 0            
            ] reduce [ "creating extended-totals "  do-report-name ]
        ]
        group-number: 0
        new-line/skip all-group-block true 1
        all-group-block-len: length? all-group-block
        
        total-on-column-obj: make object! [
            set-field: func [ field-name set-val /local field-num ] [
                field-num: get-field-number field-name [ "set-field" "underlay" "at-each-total-on-columns-line"]
                replace-in-block total-line2 set-val field-num
            ]
            get-field: func [ field-name /local field-num ] [
                field-num: get-field-number field-name [ "get-field" "underlay" "at-each-total-on-columns-line" ]
                return total-line2/:field-num
            ]  
            do-this: func [ b ] [
            	do-report-name: copy full-report-name 
            	replace do-report-name ".r" ".datr" 
                bind b 'self
                do-safe b 
                reduce [ "Report script in 'at-each-total-on-columns-line' code block."
                    do-report-name
                    [ "underlay" "at-each-total-on-columns-line" ]
                ]
            ]
        ]        
        
        foreach g all-group-block [
            group-number: group-number + 1
            total-column-values: array/initial (length? total-column-number) 0            
            foreach r g [ ; thru each (R)ecord in (G)roup
                append/only ret-block r 
                
                if all [ (total-on-columns) (total-column-number <> []) ] [
                     tcn-index: 0
                     foreach tcn total-column-number [
                         ptcn: pick r tcn
                         ptcn: any [(attempt [to-safe-decimal ptcn]) (0)]
                         new-val: ( (pick total-column-values (tcn-index + 1)) + (to-safe-decimal ptcn ) )
                         replace-in-block total-column-values new-val (tcn-index + 1)
                         
                         tcn-index: tcn-index + 1
                     ]                                
                ]                    
            ] 

            if total-on-columns [
                total-line2: copy total-line1: make-blank-record sample-record        
                tcn-index: 1
                foreach tcn total-column-number [ ; Walk thru total-column-number block IE: [ 3 6 10 ] 
                    replace-in-block total-line1 underline ( tcn )
                    tot-col-val: format (pick total-column-values tcn-index) total-column-format/:tcn-index

                    replace-in-block total-line2  tot-col-val ( tcn )
                    if all [ extended-totals ( extended-total-block <> [[]] ) ] [
                        fib: find-in-array-at/with-index extended-total-block 1 tcn ; search for source-column in extended-total-block at index=1
                        if fib [ ; matched for this column fib returns a block [ [ src-col tgt-col ] index-pos ]
                            index-pos: fib/2
                            
                            x-tot-val: format total-column-values/:tcn-index extended-total-format/:index-pos
                            
                            replace-in-block total-line2 x-tot-val ( fib/1/2 ) ; copy to target-column
                            new-total: ( (to-safe-decimal (pick extended-total-values fib/2 )) + total-column-values/:tcn-index )
                            new-total: format new-total extended-total-format/:index-pos
                            replace-in-block extended-total-values new-total fib/2
                        ]
                    ]

                    tcn-index: tcn-index + 1
                ]
                
                append/only ret-block total-line1
                append/only ret-block total-line2  
                if at-each-total-on-columns-line [
                    total-on-column-obj/do-this underlay-data/at-each-total-on-columns-line
                ]
                if return-total-rows [
                    append total-rows ( length? ret-block )
                ]
            ]                   
            if (group-number < all-group-block-len) [
                append/only ret-block blank-record ; add a blank line after each group    
            ]
        ] ;********** END foreach all-group-block 

        ; END OF REPORT FINISHING UP
        



        
        if all [ (extended-totals) ( extended-total-block <> [[]] ) ] [
            do-report-name: copy full-report-name 
        	replace do-report-name ".r" ".datr" 
            do-safe [
                grand-total-line1: make-blank-record sample-record
                etv-index: 1
                grand-total-line2: copy grand-total-line1: make-blank-record sample-record
                foreach etb extended-total-block [
                    replace-in-block grand-total-line1 underline etb/2          
                    replace-in-block grand-total-line2 extended-total-values/:etv-index etb/2
                    etv-index: etv-index + 1
                ]
                append/only ret-block grand-total-line1
                append/only ret-block grand-total-line2  
            ] reduce [ "creating extended-totals" do-report-name ] 
            
        ] 


        
        if finish-up [ 
        	do-report-name: copy full-report-name 
        	replace do-report-name ".r" ".datr" 
            
            bind underlay-data/finish-up 'data-block
            do-safe underlay-data/finish-up reduce [ 
                "report script code-block: 'finish-up'"
                do-report-name
                [ "underlay" "finish-up" ]
            ]
        ]
        
        either return-total-rows [ 
            return reduce [ ret-block total-rows ]
        ][
            return ret-block    
        ]
    ]        

    load-underlay: func [  
        underlay-block 
        report-foundation-name
        /locals len-underlay field-details len-fd prefix-columns prefix-listing-layout field-data i j temp-block listing-layout ID fld-cnt flddata dlayout tblock
    ]
    [
        len-underlay: length? underlay-block
        field-details: query-db/get-field-details
        len-fd: length? first underlay-block
        clear main-list-data 
        if ( not query-db/valid-listing-layout?/report query-db/get-listing-layout-filename ) [ return false ]          
        listing-layout: get-listing-layout 
        for i 1 len-underlay 1 [ ; This is looping through each record set.
            ; Need to check for underlay-block/:i/1 and if = 0 bypass most of loop below and just 
            ; dump the data into the main-list-data
            field-data: copy []
            for j 1 len-fd 1 [ ; loop that sets all of the "local" field names ie. "ID" "FirstName" or whatever field name
                append field-data  reduce [ underlay-block/:i/:j ]
            ]
            ID: to-integer pick field-data 1
            either ID = 0 [ ID: "" ][ ID: to-integer ID ]
            prefix-listing-layout: [
                [data (false) type "check" ID (ID)] 
                [ text (ID) ]
            ]
            temp-block: copy []    
            foreach i prefix-listing-layout [
                insert/only tail temp-block to-block i
            ] 
            fld-cnt: 1 ; skip the first field - has already been inserted in the prefix-listing-layout
            flddata: copy ""

            dlayout: copy listing-layout    
            foreach i listing-layout [ 
                fld-cnt: fld-cnt + 1
                flddata: pick field-data fld-cnt
                insert/only tail temp-block to-block compose/deep [ text (flddata) ] 
            ]
            tblock: copy temp-block
            Insert/only tail main-list-data compose/deep to-block temp-block
        ]  ; END OF load-underlay ******************************

        prefix-columns: [
            check 25x24 [ ; check box template 
                main-list/update-check face
            ]
            button 55 [ 
                if main-list/has-user-data? face [
                    edit-mysql-record/new-window query-db face/user-data/text
                ]
            ]
        ]        

        clear main-list/columns
        append main-list/columns prefix-columns
        foreach i listing-layout [
            append main-list/columns i/format
        ]        
        main-list/rowbar: copy [ "X" "-Link-" ]
        foreach i listing-layout [
            append main-list/rowbar i/heading
        ]    
        main-list/update-list
    ]

    process-underlay: func [ 
        the-underlay 
        pu-the-layout
        report-foundation-name
        /local refinements rval i 
    ][
        the-layout: copy pu-the-layout
        if (the-underlay = []) [ return [] ]
    	raw-list-data: main-list-to-raw-data main-list-data
    	all-records-loop/no-error-trap raw-list-data the-underlay/all-records-loop the-layout ; modifications made directly to 'raw-list-data
    	
    	refinements: copy []
    	append refinements 'return-total-rows

        append-if-valid: func [ 
            source-block to-find-word dest-block 
            /compare compare-block 
            /local v 
        ]
        [
            if not compare [
                compare-block: [ [] ]
            ]
            if ( v: select source-block to-find-word ) [
                foreach i compare-block [
                    if v = i [
                        return
                    ]            
                ]
                append dest-block to-find-word    
            ]    
        ]

        foreach i [ 'group-on-column 'total-on-columns 'finish-up 'at-each-total-on-columns-line ] [
            append-if-valid the-underlay i refinements
        ]
        append-if-valid/compare the-underlay 'extended-totals refinements [ [] [[]] ]
    	
    	rval: do ( refine-function create-underlay refinements ) raw-list-data the-underlay    
        raw-list-data: first rval 
    	load-underlay raw-list-data report-foundation-name
    	return ( second rval ) 
    ]

    set 'run-report func [ ; run-report:
            the-report 
            the-args
            /local report-query table-name group-totals-on-rows lrr ab
    ][
    	full-report-name: join query-db/get-report-path the-report/report-name
    	query-db/current-report-name: full-report-name
    	
        do the-args
    	if ( select the-report 'setup )[
    		do the-report/setup 
    	]
    	report-query: first reduce the-report/query
    	
    	
    	table-name: lowercase first parse ( find/tail report-query "FROM" ) none
    	if ( select the-report 'layout )[
    	    ; override the default layout and use the one supplied in this report template
    	    if (not query-db/valid-listing-layout?/report the-report/layout) [
    	        return
    	    ]
    		set-listing-layout table-name the-report/layout
    	]
    	display-query-results/no-view report-query
    	if ( main-list-data = [] ) [
    	    either(query-db/report-layout-error) [
                query-db/report-layout-error: false
                return
            ][
                my-request rejoin [ 
        	        "The Query for this report hasn't retrieved any data" newline
        	        "The Query = {" report-query "}" 
        	    ]
        	    return                
            ]
    	]
    	group-totals-on-rows: process-underlay the-report/underlay the-report/layout the-report/report-foundation
    	group-totals-on-rows

        lrr: join query-db/get-last-report-path %last-report-run.datr 
        either ( select the-report 'arguments ) [
            ab: to-argument-block the-report/arguments    
        ][
            ab: copy []
        ]
        
        save lrr reduce [
            'report-name the-report/report-name 
            'report-foundation the-report/report-foundation
            'report-type the-report/report-type 
            'arguments ab
            'setup the-report/setup
            'group-totals-on-rows group-totals-on-rows ; Keeps track of where groups have been broken - to allow for precise printing
        ]
    ]

    make-report-file: func [ 
        the-foundation report-name 
        /separate-foundation 
        /local just-report-name path-part em report-name-base report-code
    ] 
    [
        report-name: to-file report-name
        just-report-name: last split-path report-name
        path-part: first split-path report-name
        
        em: func [ s ] [ append report-code s ]
        report-name-base: first parse just-report-name "." 
        the-foundation/report-foundation: reduce ( to-file rejoin [ report-name-base ".datr" ] )
        report-code: rejoin [  {rebol [] } newline newline ] 
        
        em "the-foundation: " 
        either separate-foundation [
            em rejoin [ "load %" report-name-base ".datr" newline ]
            em rejoin [ "the-foundation/report-name: " {"} just-report-name {"} newline ]
        ][
            em ( mold the-foundation )    
        ]
        
        em rejoin [ newline newline ]
        em {run-report the-foundation [] }
        em newline
        write report-name  report-code
        if separate-foundation [
            save to-file rejoin [ path-part report-name-base ".datr" ] the-foundation
        ]
    ] 

    set 'create-report-from-current-query func [ ; create-report-from-current-query:
        /local areport the-report afoundation field-list zz create-report-layout create-report-query-field group-field request-result totals-field parsed-totals-field new-totals-field-value report-type report-name saved-report run-this-report edit-report-button
    ]
    [ 
        
        areport: [
            the-report: ""
            the-report/report-name: ""
            the-report/setup:  [
            ]    
            run-report the-report [
            ]
        ]
        afoundation:    load to-file rejoin [ query-db/root-path %program-scripts/report-foundation-template.datr ]

        afoundation/report-type: "adhoc-report" ""                      ; *** REQUIRED ***
        afoundation/report-name: "my-temporary-report"
        afoundation/report-foundation: %temp-report-foundation.datr     ; *** REQUIRED ***

        afoundation/query:  reduce [ query-field/text ]
        afoundation/layout: get-listing-layout
        new-line afoundation/layout true

        field-list: collect zz [ foreach i afoundation/layout [ zz: i/heading ] ]
        sort field-list
        insert field-list "ID" 

        view/new/title create-report-layout: layout [
            space 4x4
            across
            label 120x24 right "SQL Query:" 
            create-report-query-field: field 400x24
            return
            label 120x24 right "Group on column:" 
            space 1x4
            group-field: field  400x24 [] 
            space 4x4
            button drop-down-img 24x24 [
                if ( request-result: request-list-enhanced/offset/one-click "Pick Group Field" field-list (( screen-offset? face)+ 0x20 ))[
                    group-field/text: request-result 
                    show group-field
                ]
            ]
            return
            label 120x24 right "Total on columns:" 
            space 1x4
            totals-field: field 400x24 [] 
            space 4x4
            button drop-down-img 24x24 [
                if ( request-result: request-multi-item/offset "Pick columns(s) that you want calculated totals for" field-list (( screen-offset? face)+ 0x20 ))[
                    parsed-totals-field: parse totals-field/text none
                    new-totals-field-value: copy ""
                    foreach i parsed-totals-field [
                        append new-totals-field-value rejoin [ " " i ]
                    ]
                    append new-totals-field-value rejoin [ " " request-result  ]
                    totals-field/text: new-totals-field-value
                    show totals-field
                ]
            ]
            return
            
            label 120x24 right "Report Type:" 
            report-type: field 
            
            return
            label 120x24 right "Report Name:" 
            report-name: field
            return
            label 120x24 ""
            button "Just Run Report" 120x24 [
                run-this-report
            ]
            
            button 150x24 "Run and Save Report" [
                either all [ ((trim report-name/text) <> "") ((trim report-type/text) <> "") ][
                    saved-report: query-db/get-report-path
                    saved-report: join saved-report ( set-extension/with report-name/text ".r" )
                    run-this-report
                    make-report-file/separate-foundation afoundation saved-report
                ][
                    my-request "Can not run and save the report because^/the 'report type' or 'report name' has not been specified."
                ]
            ]
            
            edit-report-button: button 150x24 "Edit Report" [
                either saved-report [
                    query-db/edit-text-file set-extension/with saved-report ".datr"
                ][
                    my-request "You need to click the 'Run and Save Report' button before^/you can edit the report."
                ]
            ]

            do [
                 saved-report: none
                 create-report-query-field/text: afoundation/query
                 show create-report-query-field
                 run-this-report: does [
                    afoundation/underlay/group-on-column: copy []
                    afoundation/underlay/total-on-columns: copy []
                    either (group-field/text <> "") [
                        append afoundation/underlay/group-on-column group-field/text
                    ][
                        afoundation/underlay/group-on-column: []
                    ]
                    
                    foreach i (parse totals-field/text none)  [
                        append afoundation/underlay/total-on-columns  i
                    ]
                    
                    the-report: afoundation 
                    the-report/report-name: report-name/text
                    the-report/report-type: report-type/text
                    the-report/setup:  []    
                    run-report the-report []
                ]
            ]
        ] "Create Report"
    ]
]

