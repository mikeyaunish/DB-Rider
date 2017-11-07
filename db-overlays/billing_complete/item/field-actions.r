
"Company" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:item FIELD:Company GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select Name,ID from company ORDER by Name ASC " "Select a company") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:item FIELD:Company} 
    ]
] 
"Project" [
    assist-button [
        if ((a: request-db-list/one-click { select Description,ID from project ORDER by Description ASC } " Select a project") <> none) [set-field this-field last a] 
        set-focus next-field
    ]
] 
"Type" [
    assist-button [
        comment {***** ACTION:assist-button TABLE:item FIELD:Type GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.} 
        if ((a: request-db-list/one-click " select Name,ID from itemtype ORDER by Name ASC " "Select an item type") <> none) [set-field this-field last a] 
        set-focus next-field 
        comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:item FIELD:Type} 
    ]
]
