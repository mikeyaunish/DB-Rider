rebol [
    Title: "delete-record" 
    Date: 15-Dec-2016 
    Filename: %delete-record.r
    Author: "Mike Yaunish" 
    Version: 1.0 
    Purpose: {DB-Rider global select script. For database:ALL and table:ALL}    
]

hm: do-to-selected/how-many [
    delete-record
]

either ( hm = 0 ) [
    user-msg/query "Nothing deleted"
][
    user-msg/query rejoin [ "Deleted " hm " records." ]
    display-query-results "" ; This reruns last query - refreshing the listing layout
]
