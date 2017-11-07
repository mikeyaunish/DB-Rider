comment {DB-Rider field-actions for DATABASE:'billing_complete' TABLE:'address'}
on-display-record [
]
"Street1" [
    assist-button [
    ]
    on-return [
    ]
]
"Street2" [
    assist-button [
    ]
    on-return [
    ]
]
"City" [
    assist-button [
    ]
    on-return [
        if ((get-field "city") = "") [
            set-field "city" "Calgary"
            set-focus next-field
        ]
    ]
]
"StateProv" [
    assist-button [
    ]
    on-return [
        if ((get-field "StateProv") = "") [
            set-field "StateProv" "Alberta"
            set-focus next-field
        ]
    ]
]
"PostalCode" [
    assist-button [
    ]
    on-return [
    ]
]
"Country" [
    assist-button [
    ]
    on-return [
        if ((get-field "country") = "") [
            set-field "country" "Canada"
            set-focus next-field
        ]
    ]
]
on-duplicate-record [
    source-record-actions [
    ]
    target-record-actions [
    ]
]
