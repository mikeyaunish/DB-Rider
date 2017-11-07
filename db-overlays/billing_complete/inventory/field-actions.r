comment {DB-Rider field-actions for DATABASE:'billing_complete' TABLE:'inventory'} 
on-display-record [
] 
on-new-record [
] 
"date" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:inventory FIELD:date AUTO-GENERATED-CODE for field datatype:date. } 
        comment {***** NOTE: The comment above is a code marker flag. If it is modified or deleted at all then the this portion of code will be recreated and inserted into this script again.} 
        rd: request-date-for-field edit-db/table this-field 
        if rd [
            set-field this-field rd 
            set-focus next-field
        ] 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:inventory FIELD:date}
    ] 
    on-return [
    ]
] 
"item" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:inventory FIELD:item GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click { select Description,ID from item ORDER by Description ASC } "Select an item") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:inventory FIELD:item}
    ] 
    on-return [
    ] 
    on-new-target-record [
        source-record-actions [
        ] 
        target-record-actions [
        ]
    ]
] 
"quantity" [
    assist-button [
    ] 
    on-return [
    ]
] 
on-duplicate-record [
    source-record-actions [
    ] 
    target-record-actions [
    ]
]
