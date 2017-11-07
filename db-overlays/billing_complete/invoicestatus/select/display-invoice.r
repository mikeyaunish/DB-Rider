REBOL [
    Title: "display-invoice" 
    Date: 6-Nov-2017 
    Name: "display-invoice.r" 
    Author: "Mike Yaunish" 
    File: %display-invoice.r 
    Version: 1.0 
    Purpose: {DB-Rider select script. For database:billing_complete and table:invoicestatus}
]
 
hm: do-to-selected/how-many [
    invoice-number: get-field "InvoiceNo"
]

if (hm > 0)[
    do/args join query-db/overlay-path rejoin [ query-db/database "/lineitem/report/display-invoice.r"] invoice-number    
]
