rebol [] 

the-foundation: load %inventory-remaining.datr
the-foundation/report-name: "inventory-remaining.r"
the-foundation/setup: []


either ( ssa: system/script/args ) [
    run-report the-foundation [
        item-id: ssa 
    ]
][
    run-report the-foundation [
        inv-list: query-db/run-sql { SELECT Item,ID FROM inventory WHERE ID > '0' }
        request-list: copy []
        select-list: copy []
        foreach i inv-list [
            item-name: first first query-db/run-sql rejoin [ { Select Description from item where ID = '} i/1 {'} ]
            append request-list item-name
            append select-list reduce [ item-name i/1 ]
        ]
        
        if (request-result: request-list-enhanced/offset/one-click/list-size "Select a database" request-list screen-offset? report-field 300x200 ) [
            item-id: select select-list request-result
        ]
    ]    
]

 
