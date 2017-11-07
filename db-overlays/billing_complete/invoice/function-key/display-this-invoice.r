REBOL [
    Title: "display-this-invoice" 
    Date: 13-Sep-2017 
    Name: "display-this-invoice.r" 
    Author: "Mike Yaunish" 
    File: %display-this-invoice.r 
    Version: 1.0 
    Purpose: {DB-Rider function-key script. For database:billing_complete and table:invoice}
]


b: edit-db/run-sql/return-block rejoin [ {Select * FROM invoicestatus where ID = '} get-field "Status" {' } ]
either (b/1/Status = "Cancelled") [
    my-request "This invoice has been CANCELLED^/Nothing to see here."    
]
[
    do/args join edit-db/overlay-path rejoin [ edit-db/database "/lineitem/report/display-invoice.r"] get-field "ID" 
    close-edit-record-window
]
