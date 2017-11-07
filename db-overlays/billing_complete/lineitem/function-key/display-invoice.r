REBOL [
    Title: "display-invoice" 
    Date: 14-Sep-2017 
    Name: "display-invoice.r" 
    Author: "Mike Yaunish" 
    File: %display-invoice.r 
    Version: 1.0 
    Purpose: {DB-Rider function-key script. For database:billing_complete and table:lineitem}
]
b: edit-db/run-sql/return-block rejoin [ {Select * FROM invoicestatus where InvoiceNo = '} get-field "Invoice" {' } ]
either (b/1/Status = "Cancelled") [
    my-request "This invoice has been CANCELLED^/Nothing to see here."    
]
[
    do/args join edit-db/overlay-path rejoin [ edit-db/database "/lineitem/report/display-invoice.r"] get-field "Invoice" 
    close-edit-record-window
]
