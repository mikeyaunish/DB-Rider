comment {DB-Rider field-actions for DATABASE:'billing_complete' TABLE:'invoice'} 
on-display-record [
] 
on-new-record [
] 
"Status" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:invoice FIELD:Status GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click { select Status,Timestamp,ID from invoicestatus ORDER by Status,Timestamp ASC } "Select a status") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:invoice FIELD:Status}
    ] 
    on-return [
    ]
] 
"Company" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:invoice FIELD:Company GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select Name,ID from company ORDER by Name ASC " "Select a company") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:invoice FIELD:Company}
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
on-duplicate-record [
    source-record-actions [
    ] 
    target-record-actions [
    ]
]
