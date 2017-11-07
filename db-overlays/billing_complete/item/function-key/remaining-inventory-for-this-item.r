REBOL [
    Title: "remaining-inventory-for-this-item" 
    Date: 21-Oct-2017 
    Name: "remaining-inventory-for-this-item.r" 
    Author: "Mike Yaunish" 
    File: %remaining-inventory-for-this-item.r 
    Version: 1.0 
    Purpose: {DB-Rider function-key script. For database:billing_complete and table:item}
]

inventory-id: get-field "ID"
inventory-record: query-db/run-sql/return-block rejoin [ {SELECT * FROM inventory WHERE item = '} inventory-id {' ORDER BY ID DESC LIMIT 1} ]
if (inventory-record = [])[
    my-request "The 'inventory' table does not contain^/any inventory for this particular item."
    return
]
do/args join query-db/overlay-path rejoin [ query-db/database "/lineitem/report/inventory-remaining.r"] inventory-id
close-edit-record-window
