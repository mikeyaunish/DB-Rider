REBOL [
    Title: "display-invoice" 
    Date: 4-Nov-2017 
    Name: "display-invoice.r" 
    Author: "Mike Yaunish" 
    File: %display-invoice.r 
    Version: 1.0 
    Purpose: {DB-Rider function-key script. For database:billing_complete and table:invoicestatus}
]


b: edit-db/run-sql/return-block rejoin [ {Select * FROM invoicestatus where InvoiceNo = '} get-field "InvoiceNo" {' } ]
either (b/1/Status = "Cancelled") [
    my-request "This invoice has been CANCELLED^/Nothing to see here."    
]
[
    do/args join edit-db/overlay-path rejoin [ edit-db/database "/lineitem/report/display-invoice.r"] get-field "InvoiceNo" 
    close-edit-record-window
]
