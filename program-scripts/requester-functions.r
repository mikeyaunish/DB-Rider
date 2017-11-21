rebol [
    Title:   "requester-functions"
    Filename: %requester-functions.r
    Author:  "Mike Yaunish"
    Copyright: "2017 - Mike Yaunish"
    Purpose: {support scripts for DB-Rider}
    License: {
        BSD 3-Clause License

        Copyright (c) 2017, Mike Yaunish
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, this
          list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

        * Neither the name of the copyright holder nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
        AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
        IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
        FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
        DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
        SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
        CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
        OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
        OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.	
    }        
]

request-multi-item-ctx: context [
    set 'request-multi-item func [ ; request-multi-item:
        user-message [ string! ]
        item-list [ block! ] 
        /offset where [pair!]  "xy -- Offset of window on screen"
        /preselect preselected [ block! ]
        /buttons buttons-block [ block! ] {A block of  <string>, <return value>, <Fkey> triplet.
		            <string> = 'button text'
		            <return value> = 'what requester returns when button clicked'
		            <FKEY> = 'string for function key you want attached to button'
		}        
        
        /local my-styles collection-list collected return-value 
        rmi-main-list-data ndx data-flag l usr-msg rmi-main-list 
        collect-text scroll-tface modify-field check-selected bb
        max-x max-y titl last-buttons
    ] 
    [
        my-styles: patched/styles

        collection-list: copy []    
        collected: copy []
        return-value: none
        
        bb: array/initial 2 reduce ["" "" ""] ; create an empty array to make layout happy.
		either buttons [
            either ((type? first  buttons-block) = block! ) [
                ; need to copy just the number of blocks provided.
                insert bb buttons-block
                remove/part (skip bb (length? buttons-block) ) (length? buttons-block)

            ][ ; just one button described not a block of blocks or  "bblock"
                bb/1/1: buttons-block/1
                bb/1/2: buttons-block/2
                bb/1/3: buttons-block/3
            ]
            foreach i bb [
                if all [ ((type? i/3 ) = string!) (i/3 <> "") ][
                    i/3: to-lit-word i/3
                ]
            ]
            last-buttons: compose/deep [
                return
                button ( bb/1/1 ) [ 
                    collected: copy []
                    foreach i collection-list [ append collected rmi-main-list-data/:i/2/text ]
                    return-value: reduce [ (bb/1/2) collected ]
                    hide-popup 
                ] keycode (bb/1/3)
                button ( bb/2/1 ) [ 
                    collected: copy []
                    foreach i collection-list [ append collected rmi-main-list-data/:i/2/text ]
                    return-value: reduce [ (bb/2/2) collected ]
                    hide-popup 
                ] keycode (bb/2/3)
            ]
        ][
            last-buttons: ""    
        ]        
        
        rmi-main-list-data: copy []
        ndx: 0
        if ( not preselect ) [
            preselected: copy []
        ]
        foreach i item-list [
            ndx: ndx + 1
            either (found? find preselected i ) [
                data-flag: true
            ][
                data-flag: false
            ]
            append rmi-main-list-data compose/deep [
                [[data (data-flag) type "check" ID (ndx) trigger-func 'check-selected  ] [text (i)]]
            ]
        ]
        multi-lay-block: compose [
            styles my-styles
            across
            usr-msg: text 198x32 black wrap user-message font-size 14
            return 
            rmi-main-list: my-list 180x255 columns [
               check green 30x25 [
                  rmi-main-list/update-check face 
               ]
               field yellow 150x25 center []
            ]
            data rmi-main-list-data 
            rowbar ["X " "         Item  " ]
            line-colors reduce [220.220.220 white]
            rowbar-height 28
            slider-width 20
            row-highlight
            return 
            label "Selected Items:"
            return
            collect-text: text 200x75 wrap black white font-size 14 
            return
            button "OK" 94x24 [
                collected: copy []
                foreach i collection-list [ append collected rmi-main-list-data/:i/2/text ]
                return-value: collected
    	        hide-popup            
            ]
            button "Cancel" 94x24 [
                return-value: none
                hide-popup
            ]
            (last-buttons)
            do [
                scroll-tface: func [txt bar][
                    txt/para/scroll/y: negate bar/data * (max 0 txt/user-data - txt/size/y)
                    show txt
                ]
                unsorted-rmi-main-list-data: copy rmi-main-list-data
                modify-field: func [ val /subtract /local parsed i ] [ ; defaults to adding a word
                    either subtract [
                        remove find collection-list val
                    ][
                         append collection-list val
                    ]
                    collect-text/text: copy ""
                    foreach i collection-list [
                        append collect-text/text rejoin [ unsorted-rmi-main-list-data/:i/2/text {, }  ]
                    ]    
                    remove/part back back tail collect-text/text 2
                    show collect-text
                ]
                if preselect [
                    collection-list: copy []
                    collect-text/text: copy ""
                    foreach i preselected [
                        if ( found? fnd-it: find item-list i ) [
                            ndx: index? fnd-it
                            append collection-list ndx
                            append collect-text/text rejoin [ i {, }  ]
                        ]
                    ]    
                    remove/part back back tail collect-text/text 2
                    show collect-text
                ]
                check-selected: func [ v ] [
                    ndx: v/1
                    either (v/2 = true) [
                        modify-field ndx
                    ][
                        modify-field/subtract ndx
                    ]
                ]
                set 'scroll-multi-list func [ direction ] [ ; scroll-multi-list:
                    f: rmi-main-list
                    if f/pane/3 [
    				    either ( negative? direction ) [
    				        f/pane/3/data: min 1 (f/pane/3/data + f/pane/3/step)
                            scr-v-function f/pane/3
                            show f/pane/3
    				    ][
    				        f/pane/3/data: max 0 (f/pane/3/data - f/pane/3/step)
                            scr-v-function f/pane/3 
                            show f/pane/3
    				    ]
    				]
                    show rmi-main-list
                ]            
            ]
        ] ; end of layout
        multi-lay: layout multi-lay-block
        either offset [
            max-x: system/view/screen-face/size/x - multi-lay/size/x - 35
            max-y: system/view/screen-face/size/y - multi-lay/size/y - 35
            where: to-pair  reduce [ (max 10 ( min where/x max-x )) (max 30 ( min where/y max-y )) ]
        ][
            where: system/view/screen-face/size - multi-lay/size / 2
        ]
        over-multi-list?: false
        rmi-event-handler: func [face event] [
            switch event/type [
                scroll-line [ 
                    if (over-multi-list?) [
                        either ( positive? event/offset/y ) [
                		   scroll-multi-list -1
                		][
                		   scroll-multi-list 1
                		] 
                    ]
                ]
                move [
                    either (within? event/offset rmi-main-list/offset rmi-main-list/size) [
                        over-multi-list?: true
                    ][
                        over-multi-list?: false
                    ]
                ]
            ]
            return event
        ]
        insert-event-func :rmi-event-handler
        titl: "Multi Item Selection"
    	inform/title/offset multi-lay titl where
    	remove-event-func :rmi-event-handler
    	return return-value
    ]
]


open-new-context: context [ 
    fo-layout: layout [
        do [
            roset: 20x3
            btn-size: 47x18
            btn-green: 51.204.0
        ]
        backcolor white
        image %../images/open-new-v13.png 
        
        ; Import JUST
        at ( 106x27 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "import" ] ]
        at ( 106x47 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "import" ] ]
        ; Import ALL
        at ( 106x75 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "common-import" ] ]
        at ( 106x95 + roset ) button btn-green btn-size "NEW" [ req-return [ show-folder/new "common-import" ] ]
        
        ; Export JUST
        at ( 267x27 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "export" ] ]
        at ( 267x47 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "export" ] ]
        
        ; Export ALL
        at ( 267x75 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "common-export" ] ]
        at ( 267x95 + roset ) button btn-green btn-size "NEW" [ req-return [ show-folder/new "common-export" ] ]
        
        ; Go 
        at ( 432x75 + roset ) button btn-green btn-size "OPEN"  [ req-return [ show-folder "go" ] ]
        at ( 432x95 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "go" ] ] 
        
        ; Relationship
        at ( 490x25 + roset ) button btn-green (btn-size + 22X0) "TEXT EDIT"   [ req-return [ edit-a-file "relationship-text" ] ]
        at ( 490x45 + roset ) button btn-green (btn-size + 22X0) "GUI EDIT"   [ req-return [ edit-a-file "relationship-gui" ] ] 
        
        ; User Scripts
        at ( 673x25 + roset ) button btn-green btn-size "OPEN"  [ req-return [ show-folder "user-scripts" ] ]
        at ( 673x45 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "user-scripts" ] ] 
        
        ; Actions
        at ( 723x83 + roset ) button btn-green btn-size "OPEN" [ req-return [ edit-a-file "actions" ] ]
                                                             
        ; Select JUST
        at ( 105x284 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "select" ] ]
        at ( 105x304 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "select" ] ] 
        
        ; Select ALL
        at ( 105x331 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "global-select" ] ]
        at ( 105x351 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "global-select" ] ] 

        ; Report JUST
        at ( 95x402 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "report" ] ]
        at ( 95x422 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "report" ] ] 

        ; -Print JUST
        at ( 243x486 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "print" ] ]
        at ( 243x506 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "print" ] ] 
        
        ; Test JUST
        at ( 482x486 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "test" ] ]
        at ( 482x506 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "test" ] ] 
        
        ; QUERY WINDOW Function Keys
        at ( 711x485 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "global-function-key" ] ]  
        at ( 711x505 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "global-function-key" ] ] 

        ; EDIT WINDOW Function Keys
        at ( 711x534 + roset ) button btn-green btn-size "OPEN" [ req-return [ show-folder "function-key" ] ]
        at ( 711x554 + roset ) button btn-green btn-size "NEW"  [ req-return [ show-folder/new "function-key" ] ] 
        
        ; Column Layout
        at ( 711x275 + roset ) button btn-green btn-size "OPEN" [ req-return [ edit-a-file "layout" ] ]
                                                              
        do [
            the-result: none
            req-return: func [ s ] [
                the-result: s 
                hide-popup
            ]
        ]
        
    ] 

    set 'request-file-open-new func [/no-hide] ; request-file-open-new:
    [
        the-result: none
        inform/title/offset fo-layout "File Open/New" 20x50
        save/png (join query-db/get-test-path %request-file-open-new.png) to-image open-new-context/fo-layout
        return the-result
        
        hide-popup 
    ]

    set 'do-request-file-open-new func [ /local rfon ] [ ; do-request-file-open-new:
        if (rfon: request-file-open-new) [
            do rfon   
        ]
    ]
]

edit-db-connection: func [ 
    db-obj 
    /is-connected 
    /local clear-window build-return-obj conn-config-layout the-request-list connections-list request-result new-con db-list a open-database table-list refresh-fields
    host-field username-field password-field database-field table-field mr saved-connection connection-filename ts my-msg return-val test-ok? test-run?
    connection-layout sf rf db-dd show? good-tables tbl x b table-dd ok-button connection-box save-connection-button edc-sensor engage test-db-connection
][
    either is-connected [
        test-ok?: true    
    ][
        test-ok?: false
    ]
    
    clear-window: does [
        clear-fields conn-config-layout
        show conn-config-layout
    ]
    build-return-obj: func [ /full ] [
        if (test-ok? = false) [
            return []
        ]
        if ( (trim table-field/text) = "" ) [
            my-request "Please select a table before continuing"
            return none
        ]
        either full [
            db-obj/host: copy        host-field/text
            db-obj/host: copy        host-field/text     
            db-obj/user: copy        username-field/text 
            db-obj/pass: copy        password-field/data 
            db-obj/database: copy    database-field/text 
            db-obj/table: copy       table-field/text    
            return db-obj
            
        ][
            return reduce [ 
                'host       host-field/text
                'user       username-field/text
                'pass       password-field/data
                'database   database-field/text
                'table      table-field/text
            ]       
        ]
    ]
    
    connection-layout: layout/offset [
        across
        button 150x24 "Load Connection" [
            sf: request-file/file/filter/keep/title/only db-obj/get-database-connections-path "*.datr"  "Select File to Open" "Open"
            if not sf [ return ]
            rf: load sf
            host-field/text:     copy rf/host
            username-field/text: copy rf/user
            password-field/text: copy pad/with "" length? rf/pass #"*"
            password-field/data: copy rf/pass
            
            database-field/text: copy rf/database
            table-field/text:    copy rf/table
             show [ host-field username-field password-field database-field table-field  ]     
        ]
        save-connection-button: button 150x24 "Save Connection" [
            if ( saved-connection: build-return-obj ) [
                rf: request-text/title rejoin [ "Enter name the database connection you are saving." ]
                if any [ ( rf = none) (rf = "" ) ] [
                    return
                ]
                rf: set-extension/with rf ".datr"
                save join db-obj/get-database-connections-path rf  saved-connection
                my-request rejoin [ "Database connection named: '" rf "'^/ successfully saved with this data;^/" mold saved-connection ]
            ]
        ]
    ] 8x8
    
    inform/title/offset conn-config-layout: layout [
        across
        space 8x8
        return
        area yellow wrap 350x60 {Enter the 'Host', 'Username', 'Password' and 'Database' name. You must click on the 'Test Database Connection' button, then select a table before you can View or Save the connecion. }
        return
        label "Host:"              110x24 right         host-field: field [refresh-fields ] return
        label "Username:"          110x24 right     username-field: field return
        label "Password:"          110x24 right     password-field: field hide return
        label "Database:"          110x24 right     space 0x8 database-field: field [
            test-db-connection
        ] 
        space 8x8
        db-dd: button drop-down-img 24x24 [
            the-request-list: copy []
            db-list: db-obj/run-sql "show databases"
            foreach db-name db-list [ insert the-request-list db-name ]
            sort the-request-list
            request-result: request-list-enhanced/offset/one-click "Select a database" the-request-list screen-offset? face
            if request-result [
                db-obj/database: database-field/text: request-result 
                db-obj/table: table-field/text: ""
                refresh-fields
            ]
        ] return
        label ""                   110x24 right     
        button 198x24 "Test Database Connection" [ test-db-connection ]
        return
        label "Table:"             110x24 right   space 0x8 table-field: field  space 8x8 
        table-dd: button drop-down-img 24x24  [
            the-request-list: copy []
            table-list: db-obj/run-sql  rejoin [ "show tables from " db-obj/database ]    
            foreach table-name table-list [ insert the-request-list table-name ]
            sort the-request-list
            request-result: request-list-enhanced/offset/one-click "Select a table" the-request-list screen-offset? face          
            if request-result [
                db-obj/table: table-field/text: request-result 
                enable-face ok-button
                enable-face save-connection-button
                refresh-fields
            ]
        ]
        return
        
        ok-button: button 178x24 "OK - View This Table" [
            if (return-val: build-return-obj/full ) [
                hide-popup       
            ]
            
        ]
        button "Cancel" 178x24 [
            hide-popup
        ]
        return

        connection-box: box 365x81 effect [
            draw [
                pen snow
                fill-pen 185.185.185
                box
            ]
        ]
        
        sensor 0x0 keycode [ #"^(ESC)"] [ hide-popup ]

        edc-sensor: sensor 0x0 rate 100 feel [
            engage: func [face action event] [
                if action = 'time [
                    edc-sensor/rate: none
                    if test-ok? = false [
                        disable-face table-dd 
                        disable-face db-dd
                        disable-face ok-button
                        disable-face save-connection-button    
                    ]
                ]
            ]
        ]        
        
        do [
            connection-box/pane: connection-layout
            host-field/text: copy db-obj/host
            username-field/text: copy db-obj/user
            password-field/text: copy pad/with "" length? db-obj/pass #"*"
            password-field/data: copy db-obj/pass
            database-field/text: copy db-obj/database
            table-field/text: copy db-obj/table
            show [ host-field username-field password-field ]
            return-val: copy []
            edc-sensor/rate: 100
            refresh-fields: does [
                if host-field/text = "" [
                    host-field/text: copy db-obj/host
                ]    
                if username-field/text = "" [
                    username-field/text: copy db-obj/user
                ]
                if password-field/text = "" [
                    password-field/text: copy pad/with "" length? db-obj/pass #"*"
                    password-field/data: copy db-obj/pass
                ]
                
                show [ host-field username-field password-field database-field table-field ]
            ]
            test-db-connection: does [
                db-obj/host: copy host-field/text
                db-obj/user: copy username-field/text
                db-obj/pass: copy password-field/data
                db-obj/database: copy database-field/text
                if any [
                    ( host-field/text = "" )
                    ( username-field/text = "" )   
                    ( password-field/text = "" )   
                    ( database-field/text = "" )
                ][
                    my-request "Testing a database connection requires ^/ALL 4 fields of information;^/Host, Username, Password and Database "
                    return                
                ]
                if not is-connected [
                    db-obj: make db-rider-context/db-obj db-obj
                    if (not db-obj/init) [
                        test-ok?: false
                        my-request "Connection to database has FAILED."
                        disable-face table-dd 
                        disable-face db-dd
                        disable-face ok-button
                        disable-face save-connection-button
                        return
                    ]
                ]
                a: db-obj/run-sql/reopen  "show tables" database-field/text
                either a [
                    good-tables: copy []
                    foreach i a [
                        tbl: first i
                        x: db-obj/run-sql rejoin [ "describe " tbl ]
                        if (find first x "ID" ) [
                            if ( find first x "PRI" ) [
                                append/only good-tables reduce [ tbl ]
                            ]
                        ]
                    ]
                    b: difference a good-tables
                    if (b <> []) [
                        test-ok?: false
                        my-request rejoin [ "Connection to database tables has FAILED.^/ The following tables don't have a primary key named:'ID'" newline mold b ]
                        disable-face table-dd 
                        disable-face db-dd
                        disable-face ok-button
                        disable-face save-connection-button
                        return
                    ] ; otherwise fall through to success.
                ][
                    test-ok?: false
                    my-request "Connection to database has FAILED."
                    disable-face table-dd 
                    disable-face db-dd
                    disable-face ok-button
                    disable-face save-connection-button
                    return
                ]
                
                either a [
                    either ( database-field/text <> "" ) [
                        open-database: database-field/text
                    ][
                        open-database: "<none provided>"
                    ]
                    test-ok?: true
                    my-request rejoin [ "Successfully connected to the database with" newline
                                        "the following settings:"                      newline
                                        "-------------------------------------------" newline
                                        "  SERVER: " db-obj/host newline
                                        "USERNAME: " db-obj/user newline
                                        "PASSWORD: <password-provided>" newline
                                        "DATABASE: " open-database
                    ]
                    table-list: db-obj/run-sql  rejoin [ "show tables from " db-obj/database ]    
                    if not ( find-in-array-at table-list 1 table-field/text ) [
                        table-field/text: copy first first table-list     
                    ]
                    db-obj/table: table-field/text
                    enable-face ok-button
                    enable-face save-connection-button
                    refresh-fields
                    enable-face table-dd 
                    enable-face db-dd
                    show [ table-dd db-dd  ] 
                ][
                    test-ok?: false
                    my-request "Connection to database has FAILED."
                    disable-face table-dd 
                    disable-face db-dd
                    disable-face ok-button
                    disable-face save-connection-button
                ]
            ] 
        ]
        
    ] "Edit Database Connection" 30x30
    return return-val
]

request-db-list: func [ 
    sql-stmnt [string! block! ] req-title [string!]
    /no-match-msg msg [ string! ] 
    /offset the-offset 
    /cache
	/return-human-readable
	/one-click
	/size requester-size
	/no-new
	/flush
    /local a b c trim-sql-stmnt remove-cached-record fnd process-sql-request sql-result
           block1 block2 sql-len req-msg get-last-id the-table-in-stmnt cache-loader last-id-cached 
           last-id-now modified-sql-stmnt changed-res sort-block res last-id
           index-selected  cache-res refinements args times-thru x query-block lenri b1-str z fz  
           get-query-results saved-cache-results display-requester dqr qr ret-new-target request-db-list-cache 
           rdlc merge-cache-blocks name-block id-block
][
    request-db-list-cache: [] ; This is a LOCAL PERSISTENT VARIABLE used throughout this function 
    if flush [
        clear request-db-list-cache
        if (exists? (rdlc: join query-db/get-settings-path %request-db-list-cache.datr))  [
            delete rdlc
        ]
        return
    ]
    get-last-id: func [sql-stmnt /local x the-table-in-stmnt ] [
        the-table-in-stmnt: select ( parse sql-stmnt none ) "from" 
        x: run-sql-cmd rejoin [{SELECT id FROM `}the-table-in-stmnt{` ORDER BY id DESC LIMIT 1}]
        return first first x
    ]        
    if not offset [ 
        the-offset: db-rider-context/edit-record-layout/offset + edit-db/current-mouse-position - 0x70
    ]
    query-block: copy []
    either (type? sql-stmnt) <> block! [
        append query-block sql-stmnt                
    ][
        query-block: copy sql-stmnt
    ]
    if not no-match-msg [
        msg: copy {}       
    ]  
    remove-cached-record: func [ the-cached-query ] [
        if (fnd: select request-db-list-cache the-cached-query) [
            remove/part skip request-db-list-cache (( index? find request-db-list-cache the-cached-query) - 1 ) 3 
        ]           
    ] 
    
    merge-cache-blocks: func [ 
        cb 
        /local name-block id-block i j k
    ][
        name-block: copy []
        id-block: copy []
        foreach i cb [
            foreach j i/1 [
                append name-block j
            ]
            foreach k i/2 [
                append/only id-block k
            ]
        ]
        return reduce [ name-block id-block ]
    ]
           
    process-sql-request: func [ the-sql-stmnt the-msg /return-any /local sql-result block1 block2 sql-len ] [
        sql-result: run-sql-cmd the-sql-stmnt
        block1: copy []
        block2: copy []
        sql-len: length? sql-result
        if sql-len < 1 [ 
            either return-any [
                return none
            ][        
                if  no-match-msg [
                    req-msg: copy the-msg                                                       
                    my-request req-msg 
                ]
                return none                
            ]
        ]
        
        foreach ri sql-result [
            lenri: length? ri
            
            b1-str: copy ""
            for x 1 (lenri - 1) 1 [
                append b1-str rejoin [ (trim (to-string ri/:x)) " " ]        
            ]
            trim b1-str
            append block1 b1-str
            append/only block2 reduce [(last ri)]
        ]        
        
        return reduce [ block1 block2 ] ; block1 contains text for listing, block2 contains ID's of listings
    ]        
    
    cache-loader: func [ trim-sql-stmnt /cache /local res z ] [
        either cache [ ; using the cache or activating it.
            either ( request-db-list-cache <> [] ) [ ; cache exists
                either (fnd: select request-db-list-cache trim-sql-stmnt) [
                    z: first skip fz: find request-db-list-cache trim-sql-stmnt 2
                    last-id-cached: to-integer z
                    
                    last-id-now:  to-integer get-last-id trim-sql-stmnt
                    if (last-id-cached < last-id-now) [
                        
                        modified-sql-stmnt: copy trim-sql-stmnt ; Make a copy that can be modified.
                        either (found? find modified-sql-stmnt "WHERE") [
                            insert remove/part (find modified-sql-stmnt "WHERE") 5 rejoin [ " WHERE ID > " last-id-cached " AND " ] ; Modify WHERE query to limit results                                     
                        ][ ; WHERE statement NOT found in query string                           
                            either (found? find modified-sql-stmnt "ORDER") [
                                insert  (find modified-sql-stmnt "ORDER") rejoin [ " WHERE ID > " last-id-cached " " ] ; Modify query to limit results                                     
                            ][
                                append modified-sql-stmnt  rejoin [ " WHERE ID > " last-id-cached " " ] ; Modify query to limit results                                         
                            ] 
                        ]
                        changed-res: process-sql-request/return-any modified-sql-stmnt msg
                        if changed-res <> none [ ; Check if the SQL statement even returns any new data.
                            remove-cached-record trim-sql-stmnt
                            ; Need to add and sort the results here.
                            sort-block: copy []
                            for i 1 (length? fnd/1) 1 [
                                insert/only sort-block reduce [ fnd/1/:i first fnd/2/:i ]
                            ]  
                            for i 1 (length? changed-res/1) 1 [
                                insert/only sort-block reduce [ changed-res/1/:i first changed-res/2/:i ]
                            ]  
                            sort sort-block 
                            block1: copy  []
                            block2: copy  []
                            for i 1 (length? sort-block) 1  [ 
                                append block1 sort-block/:i/1
                                append/only block2 skip sort-block/:i 1 
                            ]
                            res: reduce [ block1 block2 ]                             
                            insert request-db-list-cache reduce [ trim-sql-stmnt res last-id-now ] ; Adding SQL and RESULTS to cache
                            
                            save join query-db/get-settings-path %request-db-list-cache.datr request-db-list-cache ; Save it to disk
                            fnd: copy res
                         ]
                    ]        
                    return fnd 
                ][ ; ***** not found in cache running full query to fill cache 
                    res: process-sql-request trim-sql-stmnt msg ; NOT FOUND IN CACHE
                    either res [
                        last-id: get-last-id trim-sql-stmnt 
                        insert request-db-list-cache reduce [ trim-sql-stmnt res last-id ] ; Adding SQL and RESULTS to cache
                        save join query-db/get-settings-path %request-db-list-cache.datr request-db-list-cache ; Save it to disk
                        return res 
                    ][
                        return none                       
                    ]                
                ]                
            ][ ; cache variable is empty
            	if (exists? (join query-db/get-settings-path %request-db-list-cache.datr))  [
            		request-db-list-cache: load join query-db/get-settings-path %request-db-list-cache.datr
            		return cache-loader/cache trim-sql-stmnt
            	]	    
                res: process-sql-request trim-sql-stmnt msg
                either res [
                    last-id: get-last-id trim-sql-stmnt
                    insert request-db-list-cache reduce [ trim-sql-stmnt res last-id ] ; Adding SQL and RESULTS to cache
                    save join query-db/get-settings-path %request-db-list-cache.datr request-db-list-cache ; Save it to disk
                    
                    return res 
                ][
                    return none                       
                ]                
            ]     
        ][ ; NO cache specified - just load the request from scratch
            res: process-sql-request trim-sql-stmnt msg
            either res [ 
                return res
            ][
                return none       
            ]        
        ]
    ] ; END cache-loader function   
    
    get-query-results: func [ 
        query-block 
        /no-cache
        /local sql-stmnt trim-sql-stmnt cache-res saved-cache-results
    ][
        saved-cache-results: copy []
        foreach sql-stmnt query-block [
            trim-sql-stmnt: trim sql-stmnt
            either no-cache [
              cache-res: cache-loader trim-sql-stmnt 
              
            ][
              cache-res: either cache [ cache-loader/cache trim-sql-stmnt ] [ cache-loader trim-sql-stmnt ]  
            ]
            
            either (sql-stmnt = last query-block)[ ; This is the last query-block statement - run it
                if cache-res [
                    append/only saved-cache-results cache-res    
                ]
                cache-res: merge-cache-blocks saved-cache-results
            ][
                if cache-res [
                    append/only saved-cache-results cache-res    
                ]
            ]
        ]
        return cache-res
    ]
       
    display-requester: func [cache-res /no-new /local refinements args index-selected ] [
        either cache-res [
            refinements: [return-index offset buttons ]
            either no-new [
                args: [ req-title cache-res/1 the-offset ["REFRESH" -1 "" ] ]
            ][
                args: [ req-title cache-res/1 the-offset [ ["REFRESH" -1 "" ] ["NEW-F5" -2 "F5"] ] ]    
            ]
            
            if one-click [ 
                append refinements 'one-click 
            ]
            if size [ 
                append refinements 'list-size 
                append args 'requester-size 
            ]
            index-selected: do refine-function/args request-list-enhanced  refinements (reduce args )
            if (index-selected = none )[
                return none
            ]
            if (index-selected < 0) [
                return index-selected 
            ]
            either index-selected [
            	either return-human-readable [
               		return reduce [ cache-res/2/:index-selected  cache-res/1/:index-selected ] 
            	][
            		return cache-res/2/:index-selected              	    
            	]
            ][
                 return none       
            ]
            return cache-res
        ][
            return none
        ]    
    ]
    
    either no-new [
        dqr: display-requester/no-new get-query-results query-block    
    ][
        dqr: display-requester get-query-results query-block
    ]
    while [( dqr = -1 )] [
        if ( request-db-list-cache <> [] ) [ ; cache exists
           foreach q query-block [
                remove-cached-record trim q 
            ]
        ]
        hide-popup
        qr: get-query-results/no-cache query-block 
        either (no-new) [
            dqr: display-requester/no-new qr
        ][
            dqr: display-requester qr
        ]
        
    ]
    if (dqr = -2) [
        ret-new-target: do bind F5-field-actions-block 'record-face ; which runs new-target-record
        return none ; Nothing returned because everything taken care of with 
                    ; new-target-record combined with reprocess-action
    ]
    return dqr
]

do-requested-script: func [ 
    the-folder [ file! block! ]
    request-text [ string! ]
    /pre-do pre-do-block [ block! ] 
    /add-selection add-this [ block! ] 
    /add-button add-button-blk [ block! ]; format = [ <button-text> [ <run-block> ] ]
    /offset the-offset
    /local made-block-list request-result script-to-run rle-btn-blk made-list-block err the-error do-safe-msg req-offset
]
[
    made-list-block: make-script-list/exclude-extension the-folder
    if add-selection [
        insert made-list-block/1 add-this/1 
        append made-list-block/2 add-this
    ]
    rle-btn-blk: copy []
    either offset [
        req-offset: the-offset
    ][
        req-offset: screen-offset? face
    ]
    either add-button [
        append/only rle-btn-blk reduce [ add-button-blk/1 "_btn1_" "F5"  ] 
        if ((length? add-button-blk) = 4) [
            append/only rle-btn-blk reduce [ add-button-blk/3 "_btn2_" "F6"  ]     
        ]
        request-result: request-list-enhanced/offset/list-size/one-click/buttons request-text made-list-block/1 req-offset 300x200 rle-btn-blk
    ][
        request-result: request-list-enhanced/offset/list-size/one-click request-text made-list-block/1 req-offset 300x200    
    ]
    if request-result = "_btn1_" [
        do add-button-blk/2
        return
    ]
    if request-result = "_btn2_" [
        do add-button-blk/4
        return
    ]
    
    if request-result <> none [
        script-to-run: select made-list-block/2 request-result 
        if pre-do [ 
            bind pre-do-block 'request-result       
            do-safe pre-do-block rejoin [ replace (to-string last split-path the-folder) "/" "" " *PRE-DO* action in call to function named 'do-requested-script'"]
        ] 
        do-safe-msg:  to-string last split-path script-to-run
        do-safe script-to-run reduce [ do-safe-msg script-to-run ]
    ]    
]

win-offset?: func [
    {Given any face, returns its window offset. Patched by Ana}
    face [object!]
    /window-edge
    /local xy
][
    xy: 0x0
    if face/parent-face [
        xy: face/offset
        while [face: face/parent-face][
            either face/parent-face [
                xy: xy + face/offset + either face/edge [face/edge/size][0]
            ][
                if window-edge [xy: xy + either face/edge [face/edge/size][0]]
            ]
        ]
    ]
    xy
]
screen-offset?: func [
    {Given any face, returns its screen absolute offset. Patched by Ana}
    face [object!]
    /local xy
][
    xy: face/offset
    while [face: face/parent-face][
        xy: xy + face/offset + either face/edge [face/edge/size][0]
    ]
    xy
]



run-relationship-editor: func [
    /local relationships-file rel-block 
     table-list the-request-list request-result new-val the-table sc preselect-list word-field-name ndx fnd-blk hrtf new-data 
    field-requester delete-current-entry save-current-entry new-editor-layout edit-relationship-item create-listing-layout
    ; internal functions listed in line above
    
]
[ 
    
    relationships-file: join (clean-path query-db/overlay-path) rejoin [ query-db/database  "/relationships.r" ]
    either exists? relationships-file [
        rel-block: load relationships-file
    ][
        user-msg/query rejoin [ "Relationships file: " to-string skip relationships-file (length? query-db/root-path )" does NOT yet exist^/One will be created for you." ]
        rel-block: []
    ]
    
    field-requester: func [ 
        field-name 
        /local table-list the-request-list request-result new-val the-table sc preselect-list word-field-name
    ] 
    [
      	case [
      	    any [ (field-name = "source-table") (field-name = "target-table") ][
                table-list: run-sql-cmd  rejoin [ "Show Tables FROM " query-db/database ]
                the-request-list: copy []
                foreach table-name table-list [ insert the-request-list table-name ]
                sort the-request-list
                request-result: request-list-enhanced/offset/one-click "Select A Table" the-request-list screen-offset? editor-box
                either request-result <> none [
      	            new-val: request-result
      	        ][
      	            return
      	        ]
      	    ]
      	    any [ (field-name = "target-field") (field-name = "source-field") (field-name = "human-readable-target-field") ] [
      	        
      	        either field-name = "source-field" [
      	            the-table: source-table-field/text
      	        ][
      	            the-table: target-table-field/text ; both target-field and human-readable-target-field use this table
      	        ]
      	        
      	        if the-table = "" [
      	            my-request "Need a SOURCE-TABLE defined before available fields can be determined."
      	            return
      	        ]
      	        sc: run-sql-cmd rejoin [ { SHOW columns from } the-table { in } query-db/database ]
      	        if sc = [] [
      	            my-request rejoin ["Can't retrieve source-field for the source-table =" the-table ]
      	            return
      	        ]    
      	        the-request-list: copy []
      	        foreach fld-name sc [ insert the-request-list fld-name/1 ]
      	        sort the-request-list
      	        either ( field-name = "human-readable-target-field" ) [
      	            preselect-list: parse human-readable-target-field-field/text ","
      	            request-result: request-multi-item/offset/preselect "Select one or more fields" the-request-list screen-offset? editor-box preselect-list
      	            if (not request-result) [ return ]
      	            request-result: replace/all (to-csv request-result) {"} {} ; "
      	        ][
      	            request-result: request-list-enhanced/offset/one-click "Select A Field" the-request-list screen-offset? editor-box    
      	        ]
      	        
      	        either request-result <> none [
      	            new-val: request-result
      	        ][
      	            return
      	        ]
      	    ]
      	 ]; END OF case
      	 word-field-name: (to-word (rejoin [ field-name "-field" ]))
      	 complex-set [ to-word rejoin [ field-name "-field" ] to-word "text" ] new-val
      	 show get word-field-name
    ]

    delete-current-entry: func [ /local x ndx relationships-file ] [
        ndx: 0
        foreach i rel-block [
            ndx: ndx + 1
            if all [ ( i/source-table = source-table-field/text) ( i/source-field = source-field-field/text) ] [
                remove skip rel-block (ndx - 1) 
                create-listing-layout  
                redraw-virtual listing-box listing-layout
                relationships-file: join (clean-path query-db/overlay-path) rejoin [ query-db/database  "/relationships.r" ]
                save relationships-file rel-block
                edit-relationship-item [
                    source-table ""
                    source-field ""
                    target-table ""
                    target-field ""
                    human-readable-target-field ""
                    field-requester-prompt ""
                ]                
                return
            ]
        ]
    ]

    save-current-entry: func [ /local ndx j rel-item fnd-blk hrtf new-data ] [
        ndx: 0
        fnd-blk: copy []
        foreach rel-item rel-block [
            ndx: ndx + 1
            if all [( rel-item/source-table = source-table-field/text ) ( rel-item/source-field = source-field-field/text ) ] [
                append fnd-blk ndx                        
            ]
        ]     
        
        hrtf: parse human-readable-target-field-field/text {,}
        new-data: reduce [
            'source-table                   source-table-field/text
            'source-field                   source-field-field/text
            'target-table                   target-table-field/text
            'target-field                   target-field-field/text
            'human-readable-target-field    hrtf
            'field-requester-prompt         field-requester-prompt-field/text
        ]
        
        
        either ((length? fnd-blk) = 1 ) [
            replace-in-block rel-block new-data (first fnd-blk)
            create-listing-layout  
            redraw-virtual listing-box listing-layout
        ][
            either ((length? fnd-blk) = 0 ) [ ; This is a new entry
                append/only rel-block new-data
                create-listing-layout  
                redraw-virtual listing-box listing-layout
                            
            ][
                my-request rejoin [ "Problem with saving relationship block! fnd-blk = " fnd-blk ]
                return 
            ]
        ]
        relationships-file: join (clean-path query-db/overlay-path) rejoin [ query-db/database  "/relationships.r" ]
        save relationships-file rel-block
    ]

    new-editor-layout: func [ 
        rblock /redraw-it 
        /local htrf-parsed ndx hrtf tta new-editor-lay
    ]
    [
        
        either ((type? rblock/human-readable-target-field) = block! ) [
            hrtf: replace/all (to-csv rblock/human-readable-target-field) {"} {} ; "
        ][
            hrtf: copy ""
        ]
        new-editor-lay: compose/deep [
            across
            space 0x10
            label white gray 425x24 center "RELATIONSHIP SETTINGS"
            return
            space 0x6
            label white blue 180x24 right "source-table" text "="  space 0x6      source-table-field: info 200x24 white black (to-string rblock/source-table ) button 30x24 "^^" [ field-requester "source-table"  ]   return
            label white blue 180x24 right "source-field" text "="  space 0x6      source-field-field: info 200x24 white black (to-string rblock/source-field ) space 0x16 button 30x24 "^^" [ field-requester "source-field"  ]  return

            space 0x6 
            label white brown 180x24 right "target-table" text "="       target-table-field: info 200x24 white black (to-string rblock/target-table )  button 30x24 "^^" [ field-requester "target-table"  ]  return
            label white brown 180x24 right "target-field" text "="  space 0x6     target-field-field: info 200x24 white black (to-string rblock/target-field )  button 30x24 "^^" [ field-requester "target-field"  ]  return
            label white brown 180x24 right "human-readable-target-field(s)" text "="  space 0x6  human-readable-target-field-field: info 200x24 white black (hrtf )  button 30x24 "^^" [ field-requester "human-readable-target-field"  ] return

            return
            space 0x6 
            label white blue 180x24 right "field-requester-prompt" text "=" 
            space 8x20
            field-requester-prompt-field: field (to-string rblock/field-requester-prompt ) [ save-current-entry create-new-entry ]
            return
            space 3x3
            
            button 423x24 "SAVE ENTRY" [
                save-current-entry
                create-new-entry
            ] return  
            button 210x24 "DELETE ENTRY" [
                delete-current-entry
            ]
            button 210x24 center "CREATE NEW ENTRY" [
                create-new-entry
            ] 
            do [
                focus source-table-field
                create-new-entry: func [] [
                    edit-relationship-item [
                    source-table ""
                    source-field ""
                    target-table ""
                    target-field ""
                    human-readable-target-field ""
                    field-requester-prompt ""
                ]
                ]
            ]
        ]
        if redraw-it [
            redraw-virtual editor-box new-editor-lay    
        ]
        return new-editor-lay
    ]
    edit-relationship-item: func [  rblock ] [
        new-editor-layout/redraw-it rblock
    ]
    
    
    listing-layout: copy []
    
    create-listing-layout: func [ /local x i ] [ ; listing-layout is a global variable to the "run-editor" context
       listing-layout: copy [
            across space 1x10
            label white gray 200x24 center "CURRENT RELATIONSHIPS"
            space 1x3
            return
        ]
        sort rel-block
        foreach i rel-block [
            x: copy i
            append listing-layout compose/deep [
                button 200x24 left (rejoin [ to-string  i/source-table " / " to-string i/source-field ] ) [
                     edit-relationship-item [ (x) ]
                ] return 
            ]
        ]
    ]
    
    main-lay: layout [
        across
        listing-box: box 255x347 space 4x4
        editor-box:  box 483x347 white blue
    ]  
    
    empty-relationship-block: [
	    source-table "" 
		source-field ""
		target-table ""
		target-field ""
		human-readable-target-field ""
		field-requester-prompt ""
    ] 
    
    create-listing-layout    
    editor-lay: new-editor-layout empty-relationship-block
    view-virtual/no-view main-lay editor-box editor-lay
    view-virtual/new-window/title main-lay listing-box listing-layout "Edit Relationship"
]

request-text-editor: func [ db-obj /local return-val fn ] [ 
    return-val: copy ""
    inform/offset layout [
        across
        space 8x8
        label "" 70x24
        text "Select the text editor program that you want to use with DB-Rider"
        return
        label "Editor Program:" right 120x24  space 0x8
        editor-field: field 400x24 space 8x8
        editor-dd: button drop-down-img 24x24 [
            if (fn: request-file ) [
                editor-field/text: form to-local-file first fn
                show editor-field
            ]
        ]
        return 
        label "Editor Name:" right 120x24 space 0x8
        editor-name: field 400x24  space 8x8
        name-dd: button drop-down-img 24x24 [
            e-list: first make-script-list/exclude-extension/with join query-db/get-settings-path %editor-list/ ".datr"
            if (request-result: request-list-enhanced/offset/one-click "select a editor" e-list screen-offset? face ) [
                editor-name/text: to-string request-result
                show editor-name
            ]
        ]
        return
        label "" 70x24
        button "OK" 100x24 [
            save join  db-obj/get-settings-path %text-editor.datr reduce [ editor-field/text editor-name/text ]
            load-text-editor-info db-obj
            hide-popup
        ]
        button "CANCEL" 100x24 [
            hide-popup
        ]
        do [
           editor-field/text: copy db-obj/text-editor
           editor-name/text: copy db-obj/text-editor-name
        ]
    ] 100x100
] 
