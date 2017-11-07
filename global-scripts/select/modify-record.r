rebol [
    Title: "modify-record" 
    Date: 15-Dec-2016 
    Filename: %modify-record.r
    Author: "Mike Yaunish" 
    Version: 1.0     
    Purpose: {DB-Rider global-select script. For database:ALL and table:ALL}
]

the-field-details: query-db/get-field-details
get-text-size: func [ s /local b ] [
    b: [ text: s ]
    aface: make face b
    size-text aface
]

the-layout: copy [ across 
    
]
size-block: copy []
foreach fld (skip the-field-details 1) [
    append size-block get-text-size fld/1
    
]
sort size-block
label-size: (last size-block) + 30x0
label-size/y: 22

validate-and-update-field: func [ f-name db-field-name ] [
    f-obj: do mold (to-word f-name)
    
    if f-obj/text <> "" [
        validated: validate-input-data f-obj/text reduce [ query-db/table db-field-name ]
        either (validated/1 = "true" )[
            f-obj/text: validated/2
            show f-obj
            return true
        ][
            edit-db/flash-field f-obj
            return false
        ]    
    ]
    return true
]

hm: do-to-selected/how-many []

modify-records: does [
    modify-record-sql: copy {}
    msg-string: copy ""
    foreach fld (skip the-field-details 1) [
        field-name: rejoin [ to-string fld/1 "-field" ]
        field-obj: do mold (to-word field-name)
        if field-obj/text <> "" [
            append modify-record-sql rejoin reduce [ fld/1 {='} field-obj/text {' ,} ]
            append msg-string rejoin [ fld/1 " = " field-obj/text newline ]
        ]
    ]
    remove back tail modify-record-sql ; remove last comma from sql query code
    
    rr: my-request/buttons rejoin [ hm " records will be MODIFIED as follows;"  newline newline msg-string ] "Cancel"
    either (rr = "Cancel") [
        user-msg/query "Record modification CANCELLED - Nothing has been changed."    
    ][
        selected: main-list/get-selected-checks
        foreach rec-id selected [
            qry-str: rejoin [ {UPDATE } query-db/table { SET } ]
            append qry-str modify-record-sql 
            append qry-str rejoin [ {WHERE ID = '} rec-id {'}]
            u: run-sql-cmd qry-str
        ]
        user-msg/query rejoin [ hm " record(s) MODIFIED" ]
    ]
]


requester-button: func [ table-name field-name ] [
    related: query-db/get-related-table-for table-name field-name
    the-qry: rejoin [ "select " related/3 "," related/2 " from " related/1 " ORDER by " related/3 " ASC " ]
    gui-field-name: rejoin [ field-name "-field" ]
    f-obj: do mold (to-word gui-field-name)
    the-offset: 50x50
    if ((a: request-db-list/cache/offset/return-human-readable/one-click/no-new/size the-qry "Select a Value" the-offset 300x300 ) <> none) [
        f-obj/text: first a 
        show f-obj
    ]
]

foreach fld (skip the-field-details 1) [
    mod-field-name: rejoin [ to-string fld/1 "-field" ]
    
    ;the-field-data: do compose [ get in ( to-word field-name ) ( to-lit-word "text" ) ]
    related: query-db/get-related-table-for query-db/table fld/1
    append the-layout compose/deep reduce [ 
        'label (label-size) 'white 'brown 'right ( rejoin [ fld/1 ":" ] )
        ( to-set-word mod-field-name ) 'field [
            ;? (to-path rejoin [ :field-name "/text" ])
            if not validate-and-update-field (:mod-field-name )(fld/1) [
                focus (to-word mod-field-name )   
            ]
        ]
    ]    
    
    if related[
        append the-layout compose/deep [ 
            button 30x24 "..." [ requester-button ( query-db/table) ( fld/1)  ]
        ]    
    ] 
    
    
    append the-layout [
        return 
    ]

            
]
append the-layout reduce compose/deep [
    'button 120x24 "Modify Records-F6" [
        modify-records
        unview 
    ] 'keycode [ F6 ]
    'across
    'button "Cancel" [
        unview
    ]
    'do [ 
            focus (to-word rejoin [ reduce the-field-details/2/1 "-field" ] ) 
        ]
    'sensor 0x0 'keycode [ #"^(ESC)"] [
		    unview
		]
    ]
    
insert the-layout reduce compose/deep [
    'label 'white 'gray 'left (rejoin [ "Modifying " hm " records in table: " query-db/table ]) 'return 
]    

save join query-db/root-path %temp/modify-record-layout.datr the-layout
view/new layout load join query-db/root-path %temp/modify-record-layout.datr ; WORKS GOOD



