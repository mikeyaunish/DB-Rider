REBOL [
    Title: "create-invoice" 
    Date: 28-Mar-2017 
    Name: "create-invoice.r" 
    Author: "Mike Yaunish" 
    File: %create-invoice.r 
    Version: 1.0 
    Purpose: {DB-Rider select script. For database:billing and table:lineitem}
]

selected: main-list/get-selected-checks
if (fn: create-invoice query-db selected) [
    browse fn    
]
