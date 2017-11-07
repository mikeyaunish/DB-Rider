REBOL [
    Title: "current-work" 
    Date: 27-Sep-2017 
    Name: "current-work.r" 
    Author: "Mike Yaunish" 
    File: %current-work.r 
    Version: 1.0 
    Purpose: {DB-Rider go script. For database:billing_complete and table:lineitem}
]
display-query-results {SELECT * FROM lineitem WHERE ID > '0' ORDER BY ID DESC LIMIT 40}
