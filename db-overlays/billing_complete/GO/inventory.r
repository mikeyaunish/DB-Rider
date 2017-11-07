REBOL [
    Title: "inventory" 
    Date: 14-Oct-2017 
    Name: "inventory.r" 
    Author: "Mike Yaunish" 
    File: %inventory.r 
    Version: 1.0 
    Purpose: {DB-Rider go script. For database:billing_complete and table:inventory}
]
display-query-results {SELECT * FROM inventory WHERE ID > '0'}
