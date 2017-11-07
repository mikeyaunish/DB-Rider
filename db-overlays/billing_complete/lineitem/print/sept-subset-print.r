REBOL [
    Title: "sept-subset-print" 
    Date: 12-Sep-2017 
    Name: "sept-subset-print.r" 
    Author: "Mike Yaunish" 
    File: %sept-subset-print.r 
    Version: 1.0 
    Purpose: {DB-Rider print script. For database:billing_complete and table:lineitem} 
    for-report-type: "sept-invoice"
]
print-sheet/subset [ 2 1 12 ( last-row - 1 ) ]
