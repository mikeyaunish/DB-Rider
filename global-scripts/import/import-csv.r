REBOL [
    Title: "import-csv" 
    Date: 30-Sep-2017 
    Name: "import-csv.r" 
    Author: "Mike Yaunish" 
    File: %import-csv.r 
    Version: 1.0 
    Purpose: {DB-Rider import requester script. For database:ALL and table:ALL}
]


import-context: context [
    sample-data: copy ""
    the-target-table: copy "unknown"
    target-field: copy ""
    import-data: copy []
    import-data-field-count: copy ""
    import-file-name: copy ""
    import-file-block: copy ""
    create-import-layout: func [ 
        /with import-file 
        /target-table target-table-name 
        /local x i listing-layout target-field 
    ] 
    [ 
        listing-layout: copy [
            across
            space 1x3
            do [
                file-name-field/text: import-file-block/2
                show file-name-field     
                header-check/data: true 
                show header-check
                change-sample-data: func [ direction /local sample-data ] [    
                    sample-index: sample-index + direction 
                    if (sample-index > sample-import-data-record-count) [
                        sample-index: 1
                    ]
                    if ( sample-index < 1 ) [
                        sample-index: sample-import-data-record-count
                    ]
                    sample-data: sample-import-data/:sample-index 
                    sample-data-label/text: rejoin [ "Sample Data #" ( sample-index)]
                    show sample-data-label
                    loop-ndx: 1
                    foreach i sample-data [
                        fld: get to-word rejoin [ "s-" loop-ndx ]
                        fld/text: copy i 
                        show fld  
                        loop-ndx: loop-ndx + 1                      
                    ]
                ]
                highlight-row: func [
                    index-num [ integer! ]
                    hi-state  [ logic! ] 
                    hi-light-field [ string! ]  
                ][
                    foreach [ fld-prefix norm-color ] [ "S" 255.255.255 "H" 128.128.128 "T" 255.255.255  "F" 255.255.255 ] [
                        fld-name: get to-word rejoin [ fld-prefix "-" index-num ]
                        either hi-state [
                            either (hi-light-field = fld-prefix ) [
                                fld-name/color: 255.255.0    
                            ][
                                fld-name/color: 180.215.180    
                            ]
                            
                        ][
                            fld-name/color: norm-color    
                        ]
                        show fld-name
                    ]
                ]
                table-drop-down: func [ fa ] [
                    if (the-related-field-list: query-db/related-field-list) [
                        if ( the-related-field-list: select the-related-field-list the-target-table ) [
                            row-index: to-integer second parse (to-string fa/var) "-" 
                            highlight-row row-index true "T" 
                            req-list: copy []
                            forskip the-related-field-list 2 [
                                append req-list rejoin [ the-target-table "/" (first the-related-field-list ) ]
                            ]
                            sort req-list
                            insert req-list the-target-table
                            if (request-result: request-list-enhanced/offset/one-click "Select a 'LINKED' table" req-list screen-offset? fa) [
                                table-drop-down-field: get to-word rejoin [ "T-" row-index ]
                                table-drop-down-field/text: request-result
                                show table-drop-down-field
                            ]
                            
                        ]
                        highlight-row row-index false "T"
                    ]
                ]
                get-fields-already-assigned: func [
                    the-table [ string! ] 
                    /local a-table-field table-name field-field
                ]
                [
                    result: copy []
                    for x 1 import-data-field-count 1 [
                        a-table-field: get to-word rejoin [ "T-" x ]                       
                        table-name: last parse a-table-field/text "/" 
                        
                        if (table-name = the-table) [
                            field-field: get to-word rejoin [ "F-" x ]
                            if (field-field/text <> "skip-this-field" ) [
                                append result field-field/text        
                            ]                       
                        ]
                    ]
                    return result
                ]
                show-table-info: func [
                    a-table-name
                    /local fd line1 line2 the-deets i
                ]
                [
                    fd: query-db/get-field-details/for-table a-table-name
                    ndx: 1
                    line1: rejoin ["TABLE: " a-table-name ]
                    line2: pad/with "" (length? line1) #"-" 
                    the-deets: copy rejoin [ line1 "^/" line2 "^/" ] 
                    foreach i fd [
                        append the-deets rejoin [ (pad/with ndx 2 #" ") ".)"  i/1 "^/" ]
                        ++ ndx
                    ]
                    my-request/separate  the-deets                    
                ]
                
                get-linked-table-name: func [
                    a-table-name
                    /local result
                ]
                [
                    result: last parse a-table-name "/"
                    if (find a-table-name "/" ) [ 
                        result: first select (select query-db/related-field-list the-target-table) result
                    ]
                    return result
                ]
                
                question-table: func [ fa ] [
                    row-index: second parse (to-string fa/var) "-" 
                    row-table-field: get to-word rejoin [ "T-" row-index ] 
                    show-table-info get-linked-table-name row-table-field/text 
                ]
                
                field-drop-down: func [ fa ] [
                    row-index: to-integer second parse (to-string fa/var) "-" 
                    row-table-field: get to-word rejoin [ "T-" row-index ]
                    row-table-name: get-linked-table-name row-table-field/text 
                    field-details: query-db/get-field-details/for-table row-table-name
                    req-list: copy []
                    foreach i (skip field-details 1)  [
                        append req-list i/1
                    ]
                    exclude-list: copy []
                    if ( the-related-field-list: select query-db/related-field-list row-table-name) [
                        forskip the-related-field-list 2 [
                            append exclude-list (first the-related-field-list)     
                        ]
                    ]
                    
                    req-list: difference req-list exclude-list
                    exclude-list: get-fields-already-assigned row-table-name
                    req-list: difference req-list exclude-list
                    
                    insert req-list "skip-this-field" 
                    req-list: unique req-list  
                    highlight-row row-index true "F" 
                    if (request-result: request-list-enhanced/offset/one-click "Select a field" req-list screen-offset? fa) [
                        field-drop-down-field: get to-word rejoin [ "F-" row-index ]                            
                        field-drop-down-field/text: request-result
                        show field-drop-down-field        
                    ]
                    highlight-row row-index false "F" 
                ]
                
                data-block-to-where-statement: func [
                    data-block [ block! ]
                    trx-matrix [ block! ]
                    field-details [ block! ]
                    /local result
                ]
                [
                    result: copy ""
                    foreach trx-pair trx-matrix [
                        append result rejoin [
                            pick pick field-details trx-pair/2 1
                            " = '" pick data-block trx-pair/1 "' AND "     
                        ]
                    ]
                    return copy/part result ((length? result) - 4) 
                ]
                data-block-to-insert-values: func [ 
                    data-block [ block! ]
                    trx-matrix [ block! ]
                    max-fields
                    /local result
                ]
                [
                    result: copy []
                    result: array/initial max-fields ""
                    foreach trx trx-matrix [
                        src: trx/1
                        tgt: trx/2
                        do reduce [ to-set-path reduce [ 'result :tgt ] data-block/:src ]
                    ]
                    return to-csv result
                ]
            ]
        ]
        either target-table [
            the-target-table: target-table-name
            target-field: ""
        ][
            target-field: ""
        ]
        import-table-field/text: the-target-table
        show table-field   
        
        sample-index: 2            
        if with [
            target-table-field-size: 180x24
            import-file-block: copy import-file
            import-file-name: join import-file/1 import-file/2 
            import-data: load-csv import-file-name
            sample-import-data: copy/part import-data 10
            headings: import-data/1
            sample-data: import-data/:sample-index
            import-data-field-count: length? sample-data
            sample-import-data-record-count: length? sample-import-data
            append listing-layout [
                space 1x4 
                left-sample: button 90.90.200 white "<" 29x24 [ change-sample-data -1 ]
                sample-data-label: label white 90.90.200 "Sample Data #2" 120X24    center
                space 7x2 
                right-sample: button 90.90.200 white ">" 29x24 [ change-sample-data +1 ]
                label white black "IMPORT FIELD NAME" target-table-field-size center
                label white black "TABLE / LINKED TABLE" 205x24             center
                label white black "FIELD" target-table-field-size             center
                return 
            ] 
            field-num: 0 
            foreach head-string headings [
                field-num: field-num + 1 
                append listing-layout compose/deep [
                    space 7x2 
                    (to-set-word rejoin ["S-" field-num ]) info (sample-data/:field-num) white gray             180x24
                    (to-set-word rejoin ["H-" field-num ]) label ( head-string ) white gray 180x24 center 
                    space 0x2
                    (to-set-word rejoin ["Q-" field-num ]) button light-gray "?" [ question-table face ]        14x24
                    (to-set-word rejoin ["T-" field-num ]) info white black (the-target-table)                  167x24
                    space 7x2
                    (to-set-word rejoin ["TB-" field-num ]) button 24x24 drop-down-img [ table-drop-down face ]
                    space 0x2 
                    (to-set-word rejoin ["F-" field-num ]) info white black "skip-this-field"                   155x24
                    (to-set-word rejoin ["FB-" field-num ]) button 24x24 drop-down-img [ field-drop-down face ] 
                    return
                ]
            ]
        ]
        records-in-file/text: length? import-data
        show records-in-file
        return listing-layout
    ]   


    import-layout: layout [
        across
        backdrop 170.170.170
        space 0x4
        label right "Target Table:" 210x24 
        import-table-field: field 200x24
        import-table-button: button drop-down-img 24x24 [
            table-list: query-db/run-sql  rejoin [ "show tables from " database-field/text ]
            the-request-list: copy []
            foreach table-name table-list [ insert the-request-list table-name ]
            sort the-request-list
            if (request-result: request-list-enhanced/offset/one-click "Select a table" the-request-list screen-offset? face) [
                import-table-field/text: request-result
                show import-table-field
                if (file-name-field/text) [
                    redraw-virtual import-virtual-box create-import-layout/with/target-table import-file-block request-result
                ]
            ]
        ]
        return
        label  right 210x24 "CSV Filename:" 
        file-name-field: field 200x24  
        space 8x4
        fn-button: button drop-down-img 24x24 [
            if (rf: request-file/file/keep/title/filter/save/path join query-db/root-path "exported-files" "File to Open" "Open" "*.csv") [
                import-file-block: rf
                file-name-field/text: form rf/2
                show file-name-field
                c-data: load-csv join rf/1 rf/2                                                                 
                records-in-file/text: (length? c-data)
                show records-in-file       
                redraw-virtual import-virtual-box create-import-layout/with rf
            ]
        ]
        space 0x4
        label white light-gray right 100x24 "records in file:" 
        records-in-file: label 45x24 white light-gray "___"

        
        return
        label "Skip the HEADER / first line of data:" 410x24 right header-check: check 24x24
        return
        
        space 10x8    
        import-virtual-box: box 807x500 
        return
        label "" 150x24 
        
        button "Import Data" [
            table-and-transfer: copy []
            import-data: load-csv import-file-name
            for line-num 1 import-data-field-count 1 [
                a-table-field: get to-word rejoin [ "T-" line-num ]
                field-field: get to-word rejoin [ "F-" line-num ]
                current-target-table: get-linked-table-name a-table-field/text
                if (field-field/text <> "skip-this-field") [
                    target-field-num: query-db/get-field-details/for-table/for-field/return-field-num current-target-table field-field/text
                    matrix-pair: reduce [ line-num target-field-num ] 
                    either ( fnd-pos: select table-and-transfer a-table-field/text ) [
                        append/only fnd-pos matrix-pair 
                    ][
                        append table-and-transfer  reduce [ a-table-field/text reduce [ matrix-pair ] ] 
                    ]
                ]
            ]  
            sorted-table-and-transfer: copy []
            forskip table-and-transfer 2 [ ; block format "<table-name>" [ [<src1> <dest1>] [<src2> <dest2> ] ]
                either (not fnd: find table-and-transfer/1 "/" ) [
                    append sorted-table-and-transfer reduce [ table-and-transfer/1 table-and-transfer/2 ] 
                ][
                    insert sorted-table-and-transfer reduce [ table-and-transfer/1 table-and-transfer/2 ] 
                ]
            ]
            ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            
            
            the-insert-table: copy ""
            new-linked-records: copy []
            new-records-imported: 0
            conflicting-links-to-primary: copy []
            non-unique-link-records: copy []
            confirmed-record-links: 0
            records-that-already-exist: 0
            reconnected-links: copy []
            either (header-check/data = true) [
                skip-count: 1
            ][
                skip-count: 0
            ]
            foreach record (skip import-data skip-count) [
                linked-table-imports: copy []
                forskip sorted-table-and-transfer 2 [ ; block format "<table-name>" [ [<src1> <dest1>] [<src2> <dest2> ] ]
                    insert-table: copy sorted-table-and-transfer/1
                    trx-matrix: copy sorted-table-and-transfer/2
                    
                    either (found? find insert-table "/" ) [ ; LINKED RECORD ENTRY
                        
                        linked-field-name: copy (last parse insert-table "/" )
                        the-insert-table: get-linked-table-name insert-table 
                        target-table-field-count: length? (query-db/get-field-details/for-table the-insert-table)
                        
                        where-values: data-block-to-where-statement record trx-matrix (query-db/get-field-details/for-table the-insert-table)
                        existing-record: query-db/run-sql rejoin [ {SELECT * from } the-insert-table { WHERE } where-values ]
                        
                        either ( existing-record = [] ) [
                            insert-values: data-block-to-insert-values record trx-matrix target-table-field-count 
                            query-db/run-sql rejoin [{ insert into } the-insert-table { () VALUES(} insert-values {)} ]
                            insert-id: query-db/run-sql {SELECT LAST_INSERT_ID()}    
                            append new-linked-records the-insert-table
                            append new-linked-records insert-id
                        ][
                            either ((length? existing-record) = 1 ) [
                                insert-id: existing-record/1/1    
                            ][
                                append non-unique-link-records the-insert-table 
                                foreach er existing-record [
                                    append non-unique-link-records er/1
                                ]
                                insert-id: 0
                            ]
                        ]
                        
                        ;append linked-table-imports reduce [ the-insert-table insert-id ]
                        append linked-table-imports reduce [ linked-field-name insert-id ]
                    ][ ; ****************** PRIMARY TABLE ENTRY
                        the-insert-table: insert-table
                        target-table-field-count: length? (query-db/get-field-details/for-table the-insert-table)
                        
                        where-values: data-block-to-where-statement record trx-matrix (query-db/get-field-details/for-table the-insert-table)
                        existing-record: query-db/run-sql rejoin [ {SELECT * from } the-insert-table { WHERE } where-values ]
                        record-additions: copy []
                        trx-matrix-additions: copy []
                        foreach [ linked-field-name linked-id ] linked-table-imports [
                            linked-table-pos: query-db/get-field-details/for-table/for-field/return-field-num the-insert-table linked-field-name
                        
                            append record-additions to-string linked-id
                            append/only trx-matrix-additions reduce [ (length? record) linked-table-pos ] 
                            
                            
                            append record to-string linked-id
                            append/only trx-matrix reduce [ (length? record) linked-table-pos ]     
                        ]
                        either (existing-record = [] )[ ; primary record DOES NOT exist.
                            insert-values: data-block-to-insert-values record trx-matrix target-table-field-count
                            query-db/run-sql rejoin [{ insert into } the-insert-table { () VALUES(} insert-values {)} ]
                            ++ new-records-imported
                        ][ ; primary record EXISTS
                            ++ records-that-already-exist
                            for ndx 1 (length? record-additions) 1 [
                                fld-num: trx-matrix-additions/:ndx/2
                                fld-value: to-string pick (first existing-record) fld-num
                                either (fld-value = record-additions/:ndx) [    ; Primary record HAS this link
                                    ++ confirmed-record-links
                                ][                                              ; Primary record MISSING this link
                                    either any [ (fld-value = "0") (fld-value = "" ) ] [ ; Checking if current (missing) link is valid
                                        fd: query-db/get-field-details/for-table the-insert-table
                                        fld-name: first pick fd fld-num 
                                        append reconnected-links existing-record/1/1
                                        append reconnected-links fld-name
                                        query-db/run-sql rejoin [{UPDATE } the-insert-table { SET } fld-name { = '} record-additions/:ndx {' WHERE ID = } existing-record/1/1 ]
                                    ][ ; Primary record already has a link to another record, but doesn't match with the new imported link record
                                        append conflicting-links-to-primary existing-record/1/1
                                    ]                                    
                                ]
                            ]
                        ]
                    ]
                ]
            ] ; END of record loop
            
            my-request rejoin [
             "processed " ((length? import-data) - skip-count) " records" "^/"
             "-------------------------------------------------------------^/" 
             "new-linked-records = " mold new-linked-records "^/"
             "records-that-already-exist = " mold records-that-already-exist "^/"
             "new-records-imported = " mold new-records-imported "^/"
             "reconnected-links = " mold reconnected-links "^/"
             "confirmed-record-links = " mold confirmed-record-links "^/"
             "non-unique-link-records = " mold non-unique-link-records "^/"
             "conflicting-links-to-primary = " mold conflicting-links-to-primary "^/"
            ]
        ]
        button "Cancel" [
            unview import-layout
        ]
        return
    ]  

    set 'request-import-csv func [
        the-table-name [ string! ]
        /with import-file-block [ block! ]
    ][
        either with [
            view-virtual/new-window/title import-layout import-virtual-box create-import-layout/target-table/with the-table-name import-file-block "Import CSV File"            
        ][
            view-virtual/new-window/title import-layout import-virtual-box create-import-layout/target-table the-table-name "Import CSV File"        
        ]
        do-events
    ]
] 
request-import-csv query-db/table 
