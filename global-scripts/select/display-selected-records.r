REBOL [
    Title: "display-selected-records" 
    Filename: %display-selected-records.r 
    Date: 15-Dec-2016 
    Author: "Mike Yaunish" 
    Version: 1.0 
    Purpose: {DB-Rider global-select script. For database:ALL and table:ALL}
]

the-field-details: query-db/get-field-details
print rejoin [ "Records Selected for table: '" query-db/table "'" ]
num-of-records-selected: do-to-selected/how-many [
    print "*****************************************************"
    foreach i the-field-details [
        field-value: get-field i/1  
        print [ pad/with i/1 20 #" " " = " field-value ] 
    ]
]
print "*****************************************************"
print [ "   "  num-of-records-selected " record(s) displayed" ]
