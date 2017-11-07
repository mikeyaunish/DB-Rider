; DATABASE:billing TABLE:person


"Address" [
    assist-button [
        ;***** ACTION:assist-button TABLE:person FIELD:Address GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.
        if ((a: request-db-list/one-click/size { select Street1,City,ID from address ORDER by Street1,City ASC } "Select an address" 300x300 ) <> none) [ set-field this-field last a  ]
        set-focus next-field
        ;***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:person FIELD:Address
    ]
]
"Company" [
    assist-button [
        ;***** ACTION:assist-button TABLE:person FIELD:Company GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.
        if ((a: request-db-list/one-click { select Name,ID from company ORDER by Name ASC } "Select a company" ) <> none) [ set-field this-field last a  ]
        set-focus next-field
        ;***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:person FIELD:Company
    ]
]
