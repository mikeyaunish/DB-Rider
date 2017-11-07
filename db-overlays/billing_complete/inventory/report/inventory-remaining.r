rebol [] 
comment {This is a straight 'DO' of the inventory-remaining report in the lineitem table
         Put here for convenience }
do join query-db/overlay-path rejoin [ query-db/database "/lineitem/report/inventory-remaining.r"] 

