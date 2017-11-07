REBOL [
    Title: "remaining-inventory-for-this-item" 
    Date: 21-Oct-2017 
    Name: "remaining-inventory-for-this-item.r" 
    Author: "Mike Yaunish" 
    File: %remaining-inventory-for-this-item.r 
    Version: 1.0 
    Purpose: {DB-Rider function-key script. For database:billing_complete and table:inventory}
]

do/args join query-db/overlay-path rejoin [ query-db/database "/lineitem/report/inventory-remaining.r"] get-field "item" 
close-edit-record-window
