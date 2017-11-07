
"Status" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:invoicestatus FIELD:Status AUTO-GENERATED-CODE for field datatype:set. } 
        comment {******** NOTE: The comment above is a code marker flag. If it is modified or deleted at all then the this code block will be recreated at the top of this code block.} 
        rd: request-set-for-field edit-db/table this-field 
        if rd [
            set-field this-field rd 
            set-focus next-field
        ] 
    ]
]
