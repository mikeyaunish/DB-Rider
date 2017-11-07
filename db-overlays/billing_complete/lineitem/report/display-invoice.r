rebol [] 

the-foundation: load %display-invoice.datr
the-foundation/report-name: "display-invoice.r"


run-report the-foundation [
    either (system/script/args) [
        invoice-num: system/script/args
    ][
        either ((a: request-db-list/one-click { SELECT InvoiceNo, InvoiceNo FROM invoicestatus WHERE Status = 'Created' OR Status = 'Re-Created' } "Select an item" ) <> none) [ 
            invoice-num: last a  
        ][
            return
        ]
    ]        
] 
