comment {DB-Rider field-actions for DATABASE:'billing_complete' TABLE:'invoicestatus'} 
on-display-record [
] 
on-new-record [
] 
"InvoiceNo" [
    assist-button [
    ] 
    on-return [
    ]
] 
"Status" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:invoicestatus FIELD:Status AUTO-GENERATED-CODE for field datatype:set. } 
        comment {***** NOTE: The comment above is a code marker flag. If it is modified or deleted at all then the this portion of code will be recreated and inserted into this script again.} 
        rd: request-set-for-field edit-db/table this-field 
        if rd [
            set-field this-field rd 
            set-focus next-field
        ] 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:invoicestatus FIELD:Status}
    ] 
    on-return [
    ]
] 
"Timestamp" [
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
