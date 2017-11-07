REBOL [
    Title: "quick-print-invoice" 
    Date: 27-Sep-2017 
    Name: "quick-print-invoice.r" 
    Author: "Mike Yaunish" 
    File: %quick-print-invoice.r 
    Version: 1.0 
    Purpose: {DB-Rider print script. For database:billing_complete and table:lineitem} 
    for-report-type: "display-invoice"
]
print-sheet/subset [ 4 1 12 last-row ]
