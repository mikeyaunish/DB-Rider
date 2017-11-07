REBOL [
    Title: "remaining-inventory-for-this-item" 
    Date: 6-Nov-2017 
    Name: "remaining-inventory-for-this-item.r" 
    Author: "Mike Yaunish" 
    File: %remaining-inventory-for-this-item.r 
    Version: 1.0 
    Purpose: {DB-Rider select script. For database:billing_complete and table:item}
]
 
 
 hm: do-to-selected/how-many [
    inventory-id: get-field "ID"
]

if (hm > 0)[
    inventory-record: query-db/run-sql/return-block rejoin [ {SELECT * FROM inventory WHERE item = '} inventory-id {' ORDER BY ID DESC LIMIT 1} ]
    either (inventory-record = [])[
        my-request "The 'inventory' table does not contain^/any inventory for this particular item."
        return
    ][
        do/args join query-db/overlay-path rejoin [ query-db/database "/lineitem/report/inventory-remaining.r"] inventory-id
        close-edit-record-window
    ]
]
