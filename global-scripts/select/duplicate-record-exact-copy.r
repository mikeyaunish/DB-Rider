rebol [
    Title: "duplicate-record-exact-copy" 
    Date: 15-Dec-2016 
    Filename: %duplicate-record-exact-copy.r
    Author: "Mike Yaunish" 
    Version: 1.0 
    Purpose: {DB-Rider global select script. For database:ALL and table:ALL}        
]

hm: do-to-selected/how-many [
    duplicate-record []
]

if (hm <> none) [
    rcd: " record " 
    if hm > 1 [
        rcd: " records "
    ]
    user-msg/query rejoin [ hm rcd "duplicated." ]    
]
