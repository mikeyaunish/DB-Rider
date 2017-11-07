REBOL [
    Title: "invoice-status" 
    Date: 12-Sep-2017 
    Name: "invoice-status.r" 
    Author: "Mike Yaunish" 
    File: %invoice-status.r 
    Version: 1.0 
    Purpose: {DB-Rider go script. For database:billing_complete and table:invoicestatus}
]
display-query-results {SELECT * FROM invoicestatus WHERE ID > '0' ORDER BY ID DESC}
