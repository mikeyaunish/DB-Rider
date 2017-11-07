rebol []

; do %global-scripts/export/export-data.r

get-screen-data: func [ /no-headers /no-id /export-real /local the-block heading new-rec] [
    either export-real [
        the-query: load (join query-db/get-query-path %last-query.datr)
        the-block: query-db/run-sql the-query
        if no-id [
            foreach i the-block [
                remove i 
            ]    
        ]
    ][
        either no-id [
            the-block: get-print-block/no-id    
        ][
            the-block: get-print-block
        ]    
    ]
    
    header-block: none
    if not no-headers [
        heading: get-listing-layout
        either no-id [
            header-block: copy []    
        ][
            header-block: copy ["ID"]    
        ]
        
        foreach i heading [
            append header-block i/heading
        ]    
        
        insert/only the-block header-block  
    ]
    return the-block      
]


view/new/title xlay: layout [
    across
    label "Headers?"  right 100x24
    header-tog: toggle 140x24 light-gray  "WITH HEADERS" "WITHOUT HEADERS" 
    return
    label "Include ID?" right 100x24
    id-tog: toggle 140x24 light-gray  "WITH ID #" "WITHOUT ID #" 
    return
    label "Data Source?" right 100x24
    data-tog: toggle 140x24 light-gray  "SCREEN DATA" "RAW DATA" 
    return

    label "Export Type:" 100x24 right  space 0x4 
    x-type: field 
    space 4x4 
    button drop-down-img 24x24 [
        t: request-list/offset "select an export type" [ "TSV" "CSV" "Rebol data" "Rebol Object" ] ((screen-offset? xlay)  + 100x80) 
        if t [
            x-type/text: copy t 
            show x-type
        ]
    ]
    return
    label " " 100x24
    button "Export Data"  gray 200X24 [

        refinements: copy []
        if header-tog/state = true [
            append refinements 'no-headers
        ]
        if id-tog/state = true [
            append refinements 'no-id
        ]
        if data-tog/state = true [
            append refinements 'export-real
        ]
        the-data: do refine-function get-screen-data refinements 
        
        switch x-type/text [
            "TSV" [
                if (rf: request-a-file "*.tsv") [
                    tsv-data: collect zz [ foreach i the-data [ zz: rejoin [ to-csv/with i tab newline ] ] ]
                    write join rf/1 rf/2 tsv-data
                    user-msg/query rejoin [ "TSV File: " rf/2 " saved." ] 
                ]
            ]
            "CSV" [
                if (rf: request-a-file "*.csv") [
                    csv-data: collect zz [ foreach i the-data [ zz: rejoin [ to-csv i newline ] ] ]
                    write join rf/1 rf/2 csv-data
                    user-msg/query rejoin [ "TSV File: " rf/2 " saved." ] 
                ]
            ]
            "Rebol data" [
                if (rf: request-a-file "*.datr") [
                    new-line/skip the-data true 1
                    save join rf/1 rf/2 the-data
                    user-msg/query rejoin [ "Rebol File: " rf/2 " saved." ] 
                ]
            ]
            "Rebol Object" [
                if ( header-tog/state = true ) [
                    my-request "Rebol Object can not be^/created without header names"
                    return
                ]
                out-block: copy []
                ndx: 0
                val-names: copy the-data/1 
                foreach i (skip the-data 1) [
                    ndx: ndx + 1
                    append out-block interleave val-names i
                ]
                if (rf: request-a-file "*.r") [
                     save join rf/1 rf/2 out-block
                ]
            ]
        ]
    ]
    do [
        request-a-file: func [ filter-type] [
            if (rf: request-file/file/keep/title/filter/save/path join query-db/root-path "exported-files" "File to Save" "Save" filter-type) [
                if ((suffix? last rf ) = none ) [
                    append rf/2 (skip filter-type 1 )
                ]    
            ]
            return rf
        ]
    ]
] "Export Data"
