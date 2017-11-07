REBOL [
    Title: "remaining-inventory-for-this-item" 
    Date: 21-Oct-2017 
    Name: "remaining-inventory-for-this-item.r" 
    Author: "Mike Yaunish" 
    File: %remaining-inventory-for-this-item.r 
    Version: 1.0 
    Purpose: {DB-Rider select script. For database:billing_complete and table:inventory}
]
 
num-of-records-selected: do-to-selected/how-many [
    item-id: get-field "item" 
]

either ( num-of-records-selected > 1 )[
    my-request "Inventory for only 1 item can be displayed at a time.^/The first item selected will been displayed."
    do/args join query-db/overlay-path rejoin [ query-db/database "/lineitem/report/inventory-remaining.r"] item-id
][
    do/args join query-db/overlay-path rejoin [ query-db/database "/lineitem/report/inventory-remaining.r"] item-id
]



user-msg/query rejoin[ "Select script has worked with:" num-of-records-selected "records" ]
