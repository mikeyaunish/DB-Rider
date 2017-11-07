comment {DB-Rider field-actions for DATABASE:'billing_complete' TABLE:'company'} 
"DefaultItem" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:company FIELD:DefaultItem GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click { select Description,ID from item ORDER by Description ASC } "Select an item") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:company FIELD:DefaultItem}
    ]
] 
"BillThru" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:company FIELD:BillThru GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select Name,ID from company ORDER by Name ASC " "Select a company") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:company FIELD:BillThru}
    ]
] 
on-display-record [
] 
"Name" [
    assist-button [
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
"MainContact" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:company FIELD:MainContact GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click { select FirstName,LastName,ID from person ORDER by FirstName,LastName ASC } "select a person") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:company FIELD:MainContact}
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
"BillAddress" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:company FIELD:BillAddress GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click { select Street1,City,ID from address ORDER by Street1,City ASC } "Select an address") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:company FIELD:BillAddress}
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
"ShipAddress" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:company FIELD:ShipAddress GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click { select Street1,City,ID from address ORDER by Street1,City ASC } "Select an address") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:company FIELD:ShipAddress}
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
on-new-target-record [
    source-record-actions [
    ] 
    target-record-actions [
    ]
]
