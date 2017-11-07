rebol [
    Title:   "query-listing-functions"
    Filename: %query-listing-functions.r
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

view-resizable: func [
    aface
    'resize-func-block
    min-window-size
    /offset offset-value 
    /title the-title
    /local err the-error
][
    either offset [
        view/options/new/offset aface reduce [ 'resize 'min-size :min-window-size ]offset-value
    ][
        view/options/new aface reduce [ 'resize 'min-size :min-window-size  ]
    ]
    
    insert-event-func [
    	if event/type = 'resize [ do resize-func-block ]
    	event
    ]
    if error? err: try [
        do join query-db/root-path "settings/auto-start.r"
        true ; to make the try happy
    ][
        the-error: disarm :err 
        show-error-details the-error "level-zero"  "script ERROR"                   
    ]
    forever [
        if error? err: try [
            do-events
            true ; to make the try happy
        ][
            the-error: disarm :err 
            show-error-details the-error "DB-Rider internal program error"  "DB-Rider"                   
        ]
    ]  
]

reduce-block-1deep: func [ 
    b [block!] 
    /local x i  
]
[
    x: copy []
    foreach i b [ append/only x reduce i ]
    return x        
]

create-new-listing-layout: func [ 
    /local x fd res-blk small-size big-size total-size the-gadget size row-block rel-field-list
][
    fd: query-db/get-field-details        
    res-blk: copy []
    small-size: 75x20
    big-size: 200x20
    total-size: 100x20
    rel-field-list: query-db/get-related-field-list
    foreach i fd [
        if (i/1 <> "ID") [
            the-gadget:  [ info 80 edge [size: 1x1] left ]       
            case [
                any [ ( found? find i/2 "varchar" ) ( found? find i/2 "blob" ) ] [
                    the-gadget: [ info 120 edge [size: 1x1] left ] 
                ]
                ( find-in-array-at rel-field-list 1 i/1 ) [
                    the-gadget: [ info 150 edge [size: 1x1] left ] 
                ]
            ]
            row-block: copy []
            append/only row-block 'heading
            append/only row-block to-string i/1
            append/only row-block 'data 
            either (x: query-db/get-related-table-for query-db/table i/1)[
                either x/3 [
                    append/only row-block reduce [ 'to-human to-string i/1 ]                                                                                         
                ][
                    append/only row-block reduce [ to-word i/1 ]           
                ]                
            ][
                append/only row-block reduce [ to-word i/1 ]           
            ]                
            append/only row-block 'format
            append/only row-block the-gadget
            append/only res-blk  row-block 
        ]                
    ]
    return res-blk       
]

clean-block: func [ s [file!] /locals a ][
    a: read s
    replace/all a "] [" "]^/["
    write s a           
]                

set-listing-layout: func [ 
    table-name 
    this-layout [block!] 
    /local a-table-word  
]  
[ 
    a-table-word: to-word table-name
    remove-listing-layout-entry a-table-word 
    insert query-db/listing-layout reduce [ a-table-word this-layout ] ; over ride existing named layout
    query-db/report-layout-status: 1
]

remove-listing-layout-entry: func [ the-table-word [word!] /local fnd-pos ] [
    while [ (found? fnd-pos: find query-db/listing-layout the-table-word) ] [     ; remove every entry that matches just in case there are multiples.
        remove/part fnd-pos 2
    ]
]

get-listing-layout: func [ 
    /refresh 
    /default 
    /local a-table a-table-word new-listing llfn split-file the-path the-file backup-path backup-filename r table-name
][ 
    table-name: query-db/table
    a-table-word: to-word table-name
    if refresh [
        
        if ( not query-db/valid-listing-layout? query-db/get-listing-layout-filename ) [ return none ] 
        new-listing: load query-db/get-listing-layout-filename
        remove-listing-layout-entry a-table-word
        append query-db/listing-layout reduce [ a-table-word new-listing ] 
        return new-listing
    ]        

    if default [
        remove-listing-layout-entry a-table-word ; remove entry so that listing is rebuilt below
    ]

    either (found? find query-db/listing-layout :a-table-word) [ ; if listing-layout is empty then this is a brand new load or a database change.
        return query-db/listing-layout/:a-table-word ; return existing listing-layout NOT case sensitive
    ][
        ; then this layout doesn't exist at all in the cache.
        either all [ ( exists? query-db/get-listing-layout-filename )  (not default) ]  [
            new-listing: load query-db/get-listing-layout-filename 
        ][
            new-listing: create-new-listing-layout    
        ]
        llfn: query-db/get-listing-layout-filename 
        
        split-file: split-path llfn
        the-path: first split-file
        the-file: second split-file 
        if not exists? the-path [
            make-dir/deep the-path          
        ]
        either default [
            backup-path: join  the-path "listing-layout-backup/" 
            backup-filename: to-string the-file
            remove/part (back tail backup-filename ) 1 
            backup-filename: to-file rejoin [ backup-filename unique-time-string ] 
            r: my-request/buttons rejoin  [ {Do you want a backup of 'listing-layout.r' saved to ^/<DB-RIDER>/} ( replace  to-string backup-path to-string query-db/root-path "" ) newline backup-filename ] " NO BACKUP "
            if ( r = "OK" ) [          
                if not exists? backup-path [
                    make-dir/deep backup-path           
                ]
                file-copy llfn join backup-path backup-filename
            ]                        
            save llfn new-listing
        ][
            save llfn new-listing    
        ]
        
        clean-block llfn
        append query-db/listing-layout reduce [ a-table-word new-listing ]
    ]
    return new-listing
]        

update-main-listing: func [  
    db-results 
    /refresh /default /no-view /test /clear-listing
    /locals len-dbr field-details data-layout i j prefix-data-layout temp-block len-fd refinements 
    field-data var-name prefix-columns z connection-name
]
[
    
    switch  query-db/report-layout-status [
        1 [
            query-db/report-layout-status: 2
        ]
        2 [
            query-db/report-layout-status: 0
            refresh: true                                                
        ] 
    ]
    
    if (not clear-listing) [
        if db-results = [] [ 
            user-msg/query  "No data to display because this query has returned nothing." 
            update-main-listing/clear-listing []
            return 
        ]
    ]
    
    main-list/sorted-by: 0
    len-dbr: length? db-results
    field-details: query-db/get-field-details
    len-fd: length? field-details
    clear main-list-data ; blank out the list data
    
    refinements: copy []
    if refresh [ append refinements 'refresh ]                
    if default [ append refinements 'default ]                
    
    if ((listing-layout: do refine-function get-listing-layout refinements) = none) [ return ] 
    
    for i 1 len-dbr 1 [ ; This is looping through each record set.
        field-data: copy []
        for j 1 len-fd 1 [ ; loop that sets all of the "local" field names ie. ID Name or whatever field name
            var-name: to-set-word to-string field-details/:j/1
            do-safe reduce [ :var-name db-results/:i/:j ] rejoin ["setting main-listing field named" var-name ]
            ; set each field name to it's appropriate value.
            append field-data  reduce [ db-results/:i/:j ]
        ]
        prefix-listing-layout: [
            [data (false) type "check" ID (to-integer ID)] 
            [ text (to-integer ID) ]
        ]

        temp-block: copy []    
        
        foreach i prefix-listing-layout [
            insert/only tail temp-block to-block i
        ] 
        foreach i listing-layout [ ; stepping through each column entry in the listing-layout.r file 
            did-safe?: do-safe [ insert/only tail temp-block to-block compose/deep [ text (to-paren i/data)] ] 
                reduce [ "listing layout" query-db/get-listing-layout-filename ]
            if (not did-safe?) [ return ] 
        ]
        either (query-db/report-layout-status = 2) [
            do-safe-filename: replace copy query-db/current-report-name ".r" ".datr"
        ][
            do-safe-filename: query-db/get-listing-layout-filename
        ]
        did-safe?: do-safe [ insert/only tail main-list-data compose/deep to-block temp-block ] 
            reduce ["listing layout2" do-safe-filename ]
        if (not did-safe?) [ 
            query-db/report-layout-error: true
            return 
        ] 
                    
    ]  ; END OF main-list-data composition ******************************

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
        do-safe [ append main-list/rowbar i/heading ] reduce [ "listing layout" query-db/get-listing-layout-filename ]
    ]    
    
    
    if ( not no-view ) [
        main-list/update-list
        update-record-count len-dbr
    ] 
    if query-db/connection-changed? [
        
        save join query-db/get-settings-path %last-db-connection.datr z: make object! [
            connection-name:    "query-db"
            user:               query-db/user
            pass:               query-db/pass
            host:               query-db/host
            database:           query-db/database
            table:              query-db/table
            root-path:          query-db/root-path
            text-editor:        query-db/text-editor
            overlay-path:       query-db/overlay-path
            records-to-display: query-db/records-to-display
        ]
        query-db/connection-changed?: false
    ]
    load-new-environment
] ; End update-main-listing

get-print-block: func [ /no-id ] [
    either no-id [
        main-list-to-raw-data/no-id main-list-data     
    ][
        main-list-to-raw-data main-list-data 
    ]
    
]

main-list-to-raw-data: func [ main-list-block /no-id /local i j out-block skip-size record-block ]
[
    out-block: copy []
    skip-size: either no-id [ 2 ] [ 1 ] 
    foreach i main-list-block [
        record-block: copy []
        foreach j (skip i skip-size)  [ ; skip first extraneous field used for checkmarks.
            append record-block last j           
        ]                           
        append/only out-block record-block
    ]
    return out-block                  
]        

parse-related-field-list: func [ 
    relationship-file 
    /local rel-block output table-refs gather fnd sfnd table-name
] 
[                                               
    rel-block: load relationship-file
    output: copy []
    table-refs: copy []
    gather: copy []                 
    foreach t rel-block [
        ; look for existing table
        either found? fnd: find gather to-word t/source-table [
            sfnd: select gather (to-word t/source-table )
            append sfnd compose/deep [
                        [ (rejoin [ "" t/source-field "" ]) (rejoin [ "" t/target-table "" ]) (rejoin [ "" t/target-field "" ]) (rejoin [ "" t/human-readable-target-field "" ]) ]
                    ]
        ][
            insert gather compose/deep [ 
                ( to-word t/source-table ) 
                    [ 
                        [ (rejoin [ "" t/source-field "" ]) (rejoin [ "" t/target-table "" ]) (rejoin [ "" t/target-field "" ]) (rejoin [ "" t/human-readable-target-field "" ]) ]
                    ]
            ]
        ]        
    ]  ; coalate data from "gather" variable into related-field-list format.
    forskip gather 2 [
        table-refs: copy []
        table-name: gather/1
        foreach val gather/2 [
            append table-refs val/1 
            append/only table-refs reduce [ val/2 val/3 val/4 ]        
        ]    
        append output to-string table-name
        append/only output table-refs
    ]    
    
    return output
]                 

