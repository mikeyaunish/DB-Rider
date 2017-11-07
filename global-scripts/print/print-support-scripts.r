rebol [
    Title:   "print-support-scripts"
    Filename: %print-support-scripts.r
    Author:  "Mike Yaunish"
    Copyright: "2017 - Mike Yaunish"
    Purpose: {support scripts for DB-Rider}
]

replace-at: func [ 
        b [ block!] 
        i [integer!] { index location }
        v { new value } 
][        
    insert (remove at b i) v 
]    

expand-format-block: func [ 
    theblock [ block!]
    total-cols {total number of columns}
    total-rows { total number of rows }
    /local r c new-block new-block2 last-col last-row ret-block index-pos   
]
[
    last-col: total-cols
    last-row: total-rows
    new-block: copy []
    foreach r theblock [
        either (r/1 = "*") [ 
            for c 1 total-cols 1 [ ; process all wild card patterns in columns
                append/only new-block reduce [ c r/2 r/3 ]
            ]
        ][
            append/only new-block  reduce r
        ]                    
    ]   
    new-block2: copy []
    foreach r new-block [
        either (r/2 = "*") [
            for c 1 total-rows 1 [
                append/only new-block2 reduce [ r/1 c r/3 ] 
            ]
        ][
            append/only new-block2 r
        ]                    
    ]
    ret-block: array (total-cols * total-rows)
    foreach i new-block2 [ ; i/2 is row-num, i/1 is col-num
        index-pos: (((i/2 - 1) * total-cols) + i/1 )
        replace-at ret-block index-pos i/3
    ]
    
    new-line/all new-block2 true
    new-block2
    return ret-block
]



get-last-report-run-data: func [ 
    /no-make
    /local last-report-run lrr 
][
    either (exists?  lrr: join query-db/get-last-report-path %last-report-run.datr ) [
            last-report-run: load lrr
    ][
        either no-make [
            return none
        ][
            last-report-run: [ report-type "" report-name "" total-rows 0 ]
        ]
            
    ]   
]

last-report-run: get-last-report-run-data
last-report-name: last-report-run/report-name
remove/part ( back back tail last-report-name ) 2 


sub-block: func [ 
    ablock [ block!] 
    sub-block [ block! ] 
    /local str-col str-row end-col end-row res-block sub-rows
]
[
    ; sub-block = [ str-col str-row end-col end-row ]

    str-col: sub-block/1
    str-row: sub-block/2
    end-col: sub-block/3
    end-row: sub-block/4
    res-block: copy []
    sub-rows: ( copy/part (skip ablock (str-row - 1)) (end-row - str-row + 1 ))
    foreach lin sub-rows [
        append/only res-block to-block ( copy/part  ( skip lin ( str-col - 1 )) (end-col - str-col + 1) )
    ]
    return res-block
]

print-block: func [ ablock  
                        /sub-set sub-set-area [ block!] {consist of 4 integer values str-col str-row end-col end-row } 
                        /no-heading
                        /format format-block
                        /title title-string
                        /local last-col last-row full-title html-top html-btm table-top table-btm table-row-top table-row-top-header table-row-btm table-data-top table-data-btm outstr em first-rec row-num col-num data-flag index-pos fnd-format
                  ] 
[
    last-col: (length? first ablock ) 
    last-row: (( length? ablock ) - 1 ) ; removing the header row.
    if (not sub-set) [
        sub-set-area: copy []
    ]

    format-block: expand-format-block format-block last-col last-row
    full-title: rejoin [ {REPORT:} last-report-name { CREATED:} now/date {/} now/time { } ]
    if title [
        full-title: rejoin [ full-title title-string ]
    ]
            
    html-top: rejoin  [{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>} full-title {</title>
            <style type="text/css">
            <!--
            body,td,th {
            	font-family: Tahoma, Geneva, sans-serif;
            	font-size: 13px;
            }
            -->
            </style>
    </head>
    <body>}]
    
    html-btm: {</body>
    </html>}
    
    ; table withing table
    table-top: { <table width="100%" border="0" bgcolor="#EEEEEE" cellspacing="0" cellpadding="0">
    <tr>
        <td>
        <table width="100%" border="0" cellspacing="1" cellpadding="2">}
        
    table-btm: { </table>
        </td>
    </tr>
    </table> }
    table-row-top: { <tr bgcolor="#FFFFFF"> }
    
    either no-heading [
        table-row-top-header: { <tr bgcolor="#FFFFFF"> }            
    ][
        table-row-top-header: { <tr bgcolor="#EEEEEE"> }        
    ]

    table-row-btm: { <tr> }
    table-data-top: {<td>}
    table-data-btm: { </td> }
    outstr: copy []
    em: func [ str ] [
        append outstr str    
    ]
    em html-top
    em table-top
    first-rec: true
    last-row: length? ablock
    bind sub-set-area 'last-row
    sub-set-area: reduce sub-set-area 
    if sub-set[
        ablock: sub-block ablock sub-set-area 
    ]
    row-num: 0 
        
    ;ablock: skip ablock 1 ; leave the name headers out of the loop.   
    foreach record ablock [
        row-num: row-num + 1
        either first-rec [
            em table-row-top-header
            first-rec: false 
        ][
            em table-row-top 
                      
        ]
        col-num: 0
        
        foreach field record [
            col-num: col-num + 1
            data-flag: 1
            if (field = "" ) [
                data-flag: 0    
            ]
            either format [
                 ; i/2 is row-num, i/1 is col-num
                index-pos: (((row-num - 2) * last-col) + col-num )
                either ( ( fnd-format: pick format-block index-pos ) <> none ) [
                    em rejoin [ {<td } fnd-format  {>} ]
                ][
                    em table-data-top
                ]
            ][
                em table-data-top
            ]
            em field
            em table-data-btm        
        ]
        em table-row-btm
        em newline
    ]
    em table-btm
    em html-btm
    out-file: join query-db/get-common-export-path %print-out.html
    write  out-file outstr
    user-msg/query "sending printout to web browser"
    browse out-file
]

print-sheet: func [ 
        /subset subset-block { subset-block format = start-col start-row end-col end-row. Or 
                               variables like: [ 14 (last-row - 8)  27 last-row ] }
        /no-heading 
        /format format-block [block!] { 
            a block of blocks to format each cell in the report
            [ col-num row-num { <html-format> } ]
            IE:  [ [3 17 { bgcolor="#FFFFC0" }] ]
            * wildcard is allowed for col-num or row-num as well to indicate ALL rows or ALL columns
        }
        /title title-string [ string! ]
        /local the-block heading new-rec
    ]  
[

    if (not format) [ format-block: [] ]
    the-block: get-print-block
    
    if ( not no-heading ) [
        heading: get-listing-layout
        new-rec: copy ["ID"]
        foreach i heading [
            append new-rec i/heading
        ]
        ;? new-rec
        insert/only the-block new-rec        
    ]
    either subset [
        either no-heading [
            either title [
                print-block/sub-set/no-heading/format/title the-block subset-block format-block title-string                                
            ][
                print-block/sub-set/no-heading/format the-block subset-block format-block ;[ 14 (last-row - 8)  27 last-row ]                
            ]
        ][
            either title [
                print-block/sub-set/format/title the-block subset-block format-block title-string
            ][
                print-block/sub-set/format the-block subset-block format-block ;[ 14 (last-row - 8)  27 last-row ]                        
            ]
            
        ]

    ][
        either no-heading [
            either title [
                print-block/no-heading/format/title the-block format-block title-string
            ][
                print-block/no-heading/format the-block format-block    
            ]
            
        ][
            either title [
                print-block/format/title the-block format-block title-string
            ][
                print-block/format the-block format-block    
            ]
            
        ]

    ]
]    
