rebol [] 

printed-invoice-path: join query-db/get-user-scripts-path %printed-invoices/
invoice-list: read printed-invoice-path
invoice-list: collect zz [ 
    foreach i invoice-list [ 
        if ((copy/part (skip i ((length? i) - 5)) 5) = %.html) [
            zz: i
        ]
    ]
]
if ((a: request-list-enhanced/one-click "Select a file" invoice-list ) <> none) [ 
    browse join printed-invoice-path a
]



