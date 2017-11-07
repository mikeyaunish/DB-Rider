REBOL [
    Title: "print-this" 
    Date: 25-Sep-2017 
    Name: "print-this.r" 
    Author: "Mike Yaunish" 
    File: %print-this.r 
    Version: 1.0 
    Purpose: {DB-Rider print script. For database:billing_complete and table:lineitem} 
    for-report-type: "display-invoice"
]
print-sheet/subset [ 2 1 10 last-row ]
