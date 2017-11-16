
"Address" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:person FIELD:Address GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click { select Street1,City,ID from address ORDER by Street1,City ASC } "Select an address") <> none) [set-field this-field last a] 
        set-focus next-field 
    ]
] 
"Company" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:person FIELD:Company GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select Name,ID from company ORDER by Name ASC " "Select a company") <> none) [set-field this-field last a] 
        set-focus next-field 
    ]
]
