comment {DB-Rider field-actions for DATABASE:'billing_complete' TABLE:'lineitem'} 
"Company" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:lineitem FIELD:Company GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select Name,ID from company ORDER by Name ASC " "Select a company") <> none) [ set-field this-field last a ] 
        set-focus next-field
    ]
] 
"Invoice" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:lineitem FIELD:Invoice GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select ID,ID from invoice ORDER by ID ASC " "Select an item") <> none) [set-field this-field last a] 
        set-focus next-field
    ]
] 
"Item" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:lineitem FIELD:Item GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        the-qry: rejoin [
            { select Description,PartNo,ID from item WHERE ( Type = '} get-field "type"  "' AND Company = '" get-field "company" "') OR " 
            " ( Type = '" get-field "type"  "' AND Company = '0') " 
            "ORDER by Description,Price ASC "
        ] 
        if ((a: request-db-list/size/one-click the-qry "Select an item" 400x300) <> none) [
            set-field this-field last a 
            if ((b: edit-db/run-sql/return-block rejoin [" Select * from ITEM where ID = " last a]) <> []) [
                b: first b 
                set-field "Description" b/Description
            ]
        ] 
        set-focus "Quantity"
    ] 
    on-return [
        if ( (get-field "item")  <> "" ) [
            if ((b: edit-db/run-sql/return-block rejoin [" Select * from ITEM where ID = " get-field "item" ]) <> []) [
                b: first b 
                if ((get-field "Description") = "" ) [
                    set-field "Description" b/Description                
                ]
            ]
        ]
    ]
] 
"Description" [
    on-return [
        if all [ ( (get-field "description") = "" ) ( (get-field "item")  <> ""  )] [
            if ((item-record: edit-db/run-sql/return-block rejoin [" Select * from ITEM where ID = " get-field "item" ]) <> []) [
                print "going to set-field description"
                set-field "Description" item-record/1/Description
            ]
        ]
    ]
]  
"Type" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:lineitem FIELD:Type GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select Name,ID from itemtype ORDER by Name ASC " "Select an item type") <> none) [set-field this-field last a] 
        set-focus next-field
    ]
] 
"Date" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:lineitem FIELD:Date AUTO-GENERATED-CODE for field datatype:date. } 
        comment {***** NOTE: The comment above is a code marker flag. If it is modified or deleted at all then the this portion of code will be recreated and inserted into this script again.} 
        rd: request-date-for-field edit-db/table this-field 
        if rd [
            set-field this-field rd 
            set-focus next-field
        ] 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:lineitem FIELD:Date}
    ]
]
