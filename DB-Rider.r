REBOL [
    Title:   "DB-Rider"
    Filename: %DB-Rider.r
    Author:  "Mike Yaunish"
    Copyright: "2017 - Mike Yaunish"
    Version: 0.7.0
    Maturity: 'alpha-release
    Home: https://github.com/mikeyaunish/DB-Rider.git
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
	History: [
        03-Nov-2017 0.7.0 "First public Alpha release"
	]
]

capture-errors: true  ; Global variable 
root-path: what-dir
do join root-path %program-scripts/do-safe.r
do join root-path %community-scripts/foreach-file.r

do-all-scripts-in-folder: func [ the-path [ file! ] recovery-path [ file! ]  /local filelist f file-op ] [
    file-op: func [ file ] [
        if not ( do-safe file "doing all scripts in a given folder" )[
            change-dir recovery-path ; switch back directory because errors leave you hanging.
        ]
    ]
    foreach-file/file-extension/only the-path :file-op ".r"
]

do-all-scripts-in-folder join root-path %community-scripts/ root-path
do-all-scripts-in-folder join root-path %program-scripts/ root-path
do-safe join root-path %menu/menu-config.r  reduce [ "menu-config.r script" join root-path %menu/menu-config.r ]
drop-down-img: load %images/drop-down6.gif
redrawing-virtual: false

db-rider-context: context [
    F5-field-actions-block: [] ; global in this context to be able to handle request-db-list and F5 calling of F5-field-actions-func
    close-handler: func [f e] [
        if ( e/type = 'close ) [
            remove-event-func :close-handler
            remove-event-func :edit-event-handler
            hide duplicate-text
            db-visit-history: copy []
        ]
        return e
    ]
    db-visit-history: copy []
    set-field-history: copy []
    virtual-box-size: 630x380
    results: copy []
    db-obj: make object! [
        schema-file: copy ""
        connection-name: copy ""
        user: copy ""
        host: copy ""
        database: copy ""
        table: copy ""
        pass: copy ""
        related-field-list: copy []
        listing-layout: copy []
        root-path: clean-path %./
        overlay-path: clean-path %db-overlays/
        last-date: now/date
        text-editor: copy "" 
        text-editor-name: copy ""
        text-editor-command-line: copy []
        last-table: copy ""
        last-database: copy ""
        last-query-string: copy ""
        current-report-name: copy ""
        _field-details_: copy []
        last-fd-table: copy ""
        primary-index-name: ""
        primary-index-offset: 0
        current-record-number: 1
        previous-record-number: 0
        current-edit-field-name: ""
        current-edit-row: 0
        current-edit-field-data: ""
        current-mouse-position: 0x0
        displayed-db-table: ""
        capture-errors: true
        connection-changed?: false
        connected?: false
        report-layout-status: 0
        report-layout-error: false
        extended-totals-error: false
        records-to-display: "15"
        on-new-record-code: []
        internal-folders: [ 
            "report" "print" "select" "go" "export" "import"
            "test" "function-key" "common-import" "common-export" "global-select"
            "global-function-key" "user-scripts" 
        ]
        mysql-port: make object! [] ; port placeholder - assigned correctly after port is opened.
        create-folder-structure: func [ 
            db-name [ string! ]
            table-name [ string! ]
            /local folder-list folde full-path
        ]
        [
            folder-list: [
                "export" "function-key" "import" "print" "report" "select" "user-scripts"
            ]
            foreach folder folder-list [
                full-path: join query-db/overlay-path rejoin [ db-name "/" table-name "/" folder "/" ]
                if (not exists? full-path) [
                    make-dir/deep full-path
                ]
            ]    
            if (not exists? db-export-path: join query-db/get-database-path "export/" )[ ; " UltraEdit match quote problem = UMQP
                make-dir/deep db-export-path
            ]
        ]        
        create-full-path-code-string: func [ 
            full-path [ block! ]  
            the-code [ string!] 
            /local res-code i tab-depth
        ] 
        [
            res-code: copy ""
            tab-depth: ((length? full-path) - 1 )
            insert res-code rejoin [ 
                newline 
                ( pad/with "" ((tab-depth + 1 )* 4 ) #" " ) trim the-code 
            ]
            foreach i reverse full-path [
                res-code: rejoin [ 
                    newline 
                    ( pad/with "" (tab-depth * 4 ) #" " ) mold i  { [ } 
                        reduce res-code newline 
                        ( pad/with "" ((tab-depth )* 4 ) #" " )
                    {]} 
                ]
                tab-depth: tab-depth - 1
            ]
            return res-code 
        ]
        insert-code-into-field-actions: func [ 
            source-code [ string!]  location-block [block!]  the-code [ string!] id-string [ string! ]
            /local i entry-exists? search-at common-actions linked-actions non-linked-actions last-actions
        ]
        [
            entry-exists?: true
            any-change?: true
            
            do-safe [ source-code: load source-code ] "Function: insert-code-into-field-actions^/Error has blocked field actions from load"
            search-at: source-code
            foreach i location-block [
                either (found? search-at: select search-at i ) [
                ][
                    entry-exists?: false
                ]
                if (not entry-exists? ) [ break ]
            ]
            either entry-exists? [
                either (not found? find (mold search-at) id-string ) [
                    insert search-at load the-code    
                ][
                    any-change?: false
                ]
            ][
                ; Insert a new entry right after the comment line at the top of the script
                insert (skip source-code 2)  load create-full-path-code-string location-block the-code 
            ]
            return reduce [ any-change? source-code ]
        ]
        create-field-actions-initial-code: func [ 
            db-obj [ object! ]
            the-table-name [ string! ]
            /local ret-code i field-details first-actions last-actions
        ] 
        [
;************************************
;***** START static string formatting 
common-actions: {on-display-record [
]
on-new-record [
]
}
linked-actions: { [
    assist-button [
    ]
    on-return [
    ]
    on-new-target-record [
        source-record-actions [
        ]
        target-record-actions [
        ]
    ]
]
}
non-linked-actions: { [
    assist-button [
    ]
    on-return [
    ]
]
}
last-actions: {on-duplicate-record [
    source-record-actions [
    ]
    target-record-actions [
    ]
]
}         
;***** END static string formatting 
;**********************************
            rel-field-list: db-obj/get-related-field-list
            ret-code: rejoin [ "comment {DB-Rider field-actions for DATABASE:'" db-obj/database {' TABLE:'} the-table-name "'" "}" newline]         
            append ret-code common-actions
            field-details: db-obj/get-field-details/for-table the-table-name
            foreach i skip field-details 1 [
                either (find-in-array-at rel-field-list 1 i/1) [
                    append ret-code rejoin [ {"} i/1 {"}  linked-actions ]    
                ][
                    append ret-code rejoin [ {"} i/1 {"}  non-linked-actions ]    
                ]
            ]
            append ret-code last-actions    
            return ret-code
        ]
        update-datatype-assist-actions: func [
            /reload /local fd the-field-name the-dataype
        ][
            create-datatype-code: func [ 
                data-type table-name field-name 
                /local semicolon identifier-message code-body identifier-string header-string code
            ] 
            [
                semicolon: {;}
                identifier-message: rejoin [ "         comment {***** NOTE: The comment above is a code marker flag. If it is modified or deleted at all then the this portion of code will be recreated and inserted into this script again.}" ]
                case [
                    data-type = "date" [
    ; ************ (date) START GENERATED CODE ******************************************************************
        code-body: rejoin  [ {
        rd: request-date-for-field edit-db/table this-field
        if rd [
            set-field this-field rd
            set-focus next-field
        ]
    } ]

        identifier-string: rejoin [ {***** ACTION:assist-button TABLE:} table-name { FIELD:} the-field-name { AUTO-GENERATED-CODE for field datatype:} data-type {. } ]
        header-string: rejoin [ "comment {" identifier-string "}" newline identifier-message  ]
        code:  rejoin [{    
        } header-string code-body "      comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:" table-name { FIELD:} field-name "}" {
            }]
    ; *********** (date) END GENERATED CODE ******************************************************************
                    ]
                    data-type = "enum" [
    ; ************ (enum) START GENERATED CODE ******************************************************************
        code-body: rejoin  [ {
        rd: request-enum-for-field edit-db/table this-field
        if rd [
            set-field this-field rd
            set-focus next-field
        ]
    } ]

        identifier-string: rejoin [ {***** ACTION:assist-button TABLE:} table-name { FIELD:} the-field-name { AUTO-GENERATED-CODE for field datatype:} data-type {. } ]
        header-string: rejoin [ "comment {" identifier-string "}" newline identifier-message  ]
        code:  rejoin [{
        } header-string code-body "      comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:" table-name { FIELD:} field-name "}" {
            }]
    ; *********** (enum) END GENERATED CODE ******************************************************************
                    ]
                    data-type = "set" [
    ; ************(set) START GENERATED CODE ******************************************************************
        code-body: rejoin  [ {
        rd: request-set-for-field edit-db/table this-field
        if rd [
            set-field this-field rd
            set-focus next-field
        ]
    } ]

        identifier-string: rejoin [ {***** ACTION:assist-button TABLE:} table-name { FIELD:} the-field-name { AUTO-GENERATED-CODE for field datatype:} data-type {. } ]
        header-string: rejoin [ "comment {" identifier-string "}" newline identifier-message  ]
        code:  rejoin [{   
        } header-string code-body "      comment {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:" table-name { FIELD:} field-name "}" {
            }]
    ; *********** (set) END GENERATED CODE ******************************************************************
                    ]
                ] ; END case
                return reduce [ code identifier-string ]
            ] ; END create-datatype-code

            table-list: query-db/run-sql  rejoin [ "show tables from " query-db/database ]

            foreach table-name table-list [
                table-name: first table-name
                fd: query-db/get-field-details/for-table table-name
                foreach i fd [
                    the-field-name: copy ""
                    case [
                        (i/2 = "date") [
                            the-datatype: "date"
                            the-field-name: i/1

                        ]
                        ((copy/part i/2 4)= "enum") [
                            the-datatype: "enum"
                            the-field-name: i/1
                        ]
                        ((copy/part i/2 3)= "set") [
                            the-datatype: "set"
                            the-field-name: i/1
                        ]
                    ]
                    if (the-field-name <> "") [ ; using the-field-name as a flag to activate creation of code
                        code-vals: create-datatype-code the-datatype table-name the-field-name
                        the-code: first code-vals
                        id-string: second code-vals
                        field-actions-file: query-db/get-field-actions-filename/for-table table-name
                        either (exists? field-actions-file) [
                            field-actions: read field-actions-file
                            last-insert: copy ""
                        ][
                            make-dir/deep mdd: first split-path field-actions-file
                            field-actions: create-field-actions-initial-code edit-db table-name
                        ]
                        field-actions: insert-code-into-field-actions field-actions reduce [ the-field-name 'assist-button ] the-code id-string 
                        either (field-actions/1) [
                            save field-actions-file field-actions/2
                        ][
                        ]
                    ]
                ]
            ]
        ] ; END update-datatype-assist actions
        get-field-actions-filename: func [ /for-table table-name /local the-table-name ] [
            either for-table [
                the-table-name: table-name
            ][
                the-table-name: table
            ]
            join (clean-path overlay-path) rejoin [ database "/" the-table-name "/field-actions.r" ]
        ]
        flash-field: func [ fld ] [
            fld/colors/1: 200.10.10
            show fld
            wait 0.05
            fld/colors/1: 255.255.255
            show fld
        ]
        get-global-path: does [
            join  root-path "global-scripts/"
        ]
        get-global-select-path: does [
            join  get-global-path "select/"
        ]
        get-global-report-path: does [
            join  get-global-path "report/"
        ]
        get-table-path: does [
            join (clean-path overlay-path) rejoin [ database "/" table "/" ]
        ]
        get-database-path: does [
            join (clean-path overlay-path) rejoin [ database "/" ]
        ]
        get-listing-layout-filename: does [
            join (clean-path get-table-path) "listing-layout.r"
        ]
        get-select-path: does [
            join (clean-path get-table-path) "select/" 
        ]
        get-last-select-path: does [
            clean-path get-table-path
        ]
        get-import-path: does [
            join (clean-path get-table-path) "import/"
        ]
        get-common-import-path: does [
            join (clean-path overlay-path) rejoin [ database "/import/" ]
        ]
        get-global-import-path: does [
            join  get-global-path "import/"
        ]
        get-export-path: does [
            join (clean-path get-table-path) "export/"
        ]
        get-common-export-path: does [
            join (clean-path overlay-path) rejoin [ database "/export/" ]
        ]
        get-global-export-path: does [
            join  get-global-path "export/"
        ]
        get-go-path: does [
            join (clean-path overlay-path) rejoin [ database  "/GO/" ]
        ]
        get-last-go-path: does [
            join (clean-path overlay-path) rejoin [ database  "/" ]
        ]
        get-settings-path: does [
            join root-path %settings/
        ]
        get-query-path: does [
            join (clean-path overlay-path) rejoin [ database  "/query/" ]
        ]
        get-function-key-path: does [
            join (clean-path get-table-path) "function-key/" 
        ]
        get-global-function-key-path: does [
             join  get-global-path %function-key/
        ]
        get-database-connections-path: does [
            join  root-path %settings/database-connections/
        ]
        get-print-path: does [
            join (clean-path get-table-path) "print/" 
        ]
        get-last-print-path: does [
            get-table-path
        ]
        get-user-scripts-path: does [
            join (clean-path get-table-path) "user-scripts/" 
        ]
        get-test-path: does [
            clean-path  rejoin [ root-path "test/" ]
        ]
        get-report-path: does [
            join (clean-path get-table-path) "report/" 
        ]
        get-last-report-path: does [
            get-table-path
        ]
        
        init: func [
            /local t fallback-database fallback-table table-list a-listing vl
        ][ 
            fallback-database: copy last-database
            fallback-table: copy last-table
            table-list: run-sql "show tables"
            if (table-list = false) [
                return false
            ]
            if table-list = []  [ 
                my-request rejoin [ "The database " database " does NOT contain" newline "any tables. The last valid query will be re-loaded."  ]
                database: copy fallback-database
                table: copy fallback-table
                return false
            ]
            _table-list_: copy table-list
            do-all-global-scripts
            if ( last-database <> database ) [
                listing-layout: copy []
            ]
            _field-details_: copy []
            foreach t table-list [
                table-name: first t
                fd: run-sql rejoin ["show columns from "  table-name ]
                append _field-details_ reduce [ to-word table-name fd ]
                listing-layout-filename: join (clean-path overlay-path) rejoin [ database "/" t "/listing-layout.r" ]
                
                either exists? listing-layout-filename [
                    a-table-word: to-word first t
                    if ( not valid-listing-layout? listing-layout-filename ) [ return false ]
                    a-listing: load listing-layout-filename
                    append query-db/listing-layout reduce [ a-table-word a-listing ]
                ][
                    create-folder-structure database table-name
                ]
            ]
            related-field-list: copy []
            return true
        ]
        
        valid-listing-layout?: func [ 
            the-listing-layout [ file! block! ]
            /report
            /local vl err-msg user-err-msg the-listing
        ]
        [
            either((type? the-listing-layout) = block!) [
                the-listing: the-listing-layout
            ][
                the-listing: load the-listing-layout
            ]
            
            err-filename: either(report) [
                replace copy query-db/current-report-name ".r" ".datr"
            ][
                the-listing-layout
            ]
            
            either ((vl: validate-listing-layout the-listing) = true )[
                return true
            ][
                user-err-msg: copy "ERRORS: "
                llfn: split-path get-listing-layout-filename
                err-msg: copy rejoin [ "ERROR WITH: listing layout^/      FILE: '" llfn/2 "'^/    FOLDER: '" llfn/1 "'^/-----------------------------------------------------------------------------^/" ]
                first-line-with-error: vl/1/1
                foreach i vl [
                    append err-msg rejoin [ "Layout line #" i/1 " problem with '" i/2 "'^/" ] 
                    append user-err-msg rejoin [ "Layout line  #" i/1 " problem with '" i/2 "'. " ] 
                ]
                
                res: my-request/buttons  err-msg [ "  Edit File  " ] 
                user-msg/query user-err-msg
                if (res = "  Edit File  ") [
                    pos-in-file: find-position-in-file/rebol-script err-filename "" "layout" 
                    line-num: ((first pos-in-file) + first-line-with-error )
                    edit-text-file/position err-filename reduce [ line-num 1 ]
                ]
                return false
            ]
        ]

        validate-listing-layout: func [ 
            a-listing-layout 
            /local rules line-num error-report v h d f ii e s p a valid-list-template parse-result the-value
        ]
        [
            rules:  [ 
                set h 'heading string! 
                set d 'data block! 
                set f 'format into [ 
                    set ii [ 'info | 'field ]  integer! 
                    set e 'edge into [
                        set s set-word!
                        set p pair!
                    ]  
                    set a some [ word! ]
                ]
            ]    
            line-num: 0
            error-report: copy []
            foreach i a-listing-layout [
                ++ line-num
                h: d: f: ii: e: s: p: a: none
                valid-list-template: [ "heading" "data" "format" "info" "edge" "size" "size value" "left/right/middle alignment" ] 
                parse-result: parse i rules
                
                valid-list: copy []
                foreach v [ h d f ii e s p a ] [
                    the-value: get :v 
                    if the-value <> none [
                        append valid-list the-value
                    ]
                ]
                if (not parse-result) [
                    append/only error-report reduce [ line-num (pick valid-list-template ((length? valid-list) + 1 )) ]
                ]
            ]
            either error-report = [] [
                return true
            ][
                return error-report
            ]
        ]        
        
        edit-text-file: func [ 
            filename [ file! ] 
            /position line-col-pos [ block! ]
            /find-this find-string [ string! ] 
            /local quote-char cmd line-number column-number editor-program 
        ]
        [ 
            
            if (value? 'query-db ) [
                editor-program: query-db/text-editor
                file-to-edit: to-local-file clean-path filename
                quote-char: {"} ;"
                
                either query-db/text-editor-command-line = [] [
                    cmd: rejoin [ editor-program " " quote-char file-to-edit quote-char ]
                ][
                    bind query-db/text-editor-command-line/plain-edit    'filename
                    bind query-db/text-editor-command-line/position-edit 'filename
                    
                    either position [
                        line-number: line-col-pos/1      ; line-number   variable local to editor config file
                        column-number: line-col-pos/2    ; column-number variable local to editor config file
                        cmd: rejoin reduce query-db/text-editor-command-line/position-edit   
                    ][
                        either(find-this) [
                            found-at: find infile: read/binary filename find-string
                            either found-at [
                                search-in: (copy/part infile (index? found-at ))
                                num-lines: num-occurrences  search-in "^/"
                                last-line-break: find/reverse tail search-in "^/"
                                num-lines: num-lines + 1
                                line-number: num-lines
                                column-number: (index? found-at) - (index? last-line-break) 
                                cmd: rejoin reduce query-db/text-editor-command-line/position-edit       
                            ][
                                cmd: rejoin reduce query-db/text-editor-command-line/plain-edit
                            ]
                        ][
                            cmd: rejoin reduce query-db/text-editor-command-line/plain-edit
                        ]
                    ]
                ]
                call cmd                        
            ]
        ]
        
        get-related-field-list: does [
            if any [ (last-table <> table) (last-database <> database ) ( related-field-list = []) ] [ ; Then we've had a major switch of table or database
                relationships-file: join (clean-path overlay-path) rejoin [ database  "/relationships.r" ]
                either exists? relationships-file [
                    related-field-list: parse-related-field-list relationships-file
                    if ((modified? relationships-file) > last-checked-relationships/get )[
                        update-relationship-assist-actions
                    ]
                ][
                ]
            ]
            return related-field-list
        ]
        update-relationship-assist-actions: func [
            /reload
            /local semicolon quote open-curly close-curly tta code-body
        ]
        [
            create-code: func [
                e
                /local semicolon quote open-curly close-curly tta code-body header-string code
            ][
                semicolon: ";"  
                quote: {"} ; " balancing quote here for syntax hilighting.
                open-curly: "{"
                close-curly: "}"
                if ((type? e/human-readable-target-field) = block! ) [
                    e/human-readable-target-field: replace/all (to-csv e/human-readable-target-field) {"} {} ; "
                ]
;************ (request-db-list) START GENERATED CODE STATIC TEXT FORMATTING *******************************************
                 code-body: rejoin [
                 {
        if ((a: request-db-list/one-click } open-curly { select } e/human-readable-target-field {,} e/target-field { from } e/target-table { ORDER by } e/human-readable-target-field { ASC } close-curly { } quote e/field-requester-prompt quote { ) <> none) [ set-field this-field last a  ]
        set-focus next-field
        }
            ]
;*********** (request-db-list) END GENERATED CODE STATIC TEXT FORMATTING **********************************************

            header-string: rejoin [ "comment {***** ACTION:assist-button TABLE:" e/source-table { FIELD:} e/source-field  " GENERATED_CODE from relationship file. Do Not Modify this comment line. Modify the code below all you want.}"  ]
            code:  rejoin [{    
        } header-string code-body "comment  {***** END_OF_GENERATED_CODE ACTION:assist-button TABLE:" e/source-table { FIELD:} e/source-field "}" {
    }]
                return reduce [ code header-string ]
            ]
            ; END create-code ***********************************************
            relationships-file: join (clean-path overlay-path) rejoin [ database  "/relationships.r" ]
            if ( exists? relationships-file ) [
                if any [ ( (modified? relationships-file) > last-checked-relationships/get ) ( reload ) ] [
                    either reload [
                    ][
                    ]
                    rf: load relationships-file
                    last-checked-relationships/set
                    foreach rfe rf [
                        if (rfe/source-table = table) [
                            code-vals: create-code rfe
                            the-code: first code-vals
                            id-string: second code-vals
                            field-actions-file: get-field-actions-filename
                            either (exists? field-actions-file) [
                                field-actions: read field-actions-file
                                last-insert: copy ""
                            ][
                                make-dir/deep mdd: first split-path field-actions-file table
                                Field-Actions: Create-Field-Actions-Initial-Code edit-db table
                            ]
                            field-actions: insert-code-into-field-actions field-actions reduce [ rfe/source-field 'assist-button ] the-code id-string 
                            either (field-actions/1) [
                                save field-actions-file field-actions/2
                            ][
                            ]
                        ]
                    ]
                ]
            ]
        ] ; END update-relationship-assist-actions
        last-checked-relationships: func [ /get /set ]  [
            last-checked-file: join (clean-path overlay-path) rejoin [ database  "/last-checked-relationships.datr" ]
            if get [
                either (exists? last-checked-file) [
                    return load last-checked-file
                ][
                    return to-date 1000-01-01
                ]
            ]
            if set [
                save last-checked-file now
            ]
        ]
        set-table-name: func [ new-table-name ] [
            if new-table-name <> table [
                table: copy new-table-name
                primary-index-name: copy ""
            ]
        ]
        primary-index?: func [ /name /offset
                               /local results mysql-port item fd pi-name pi-oset
                               ; Global to this context: primary-index-name primary-index-offset
        ]
        [
            if (primary-index-name = "") [ ; run sql query only if primary-index-name hasn't already been fetched.
                results: run-sql rejoin [ { show index from } table ]
                foreach item results [ ; Check for PRIMARY and UNIQUE values for proper primary key
                    if all [ (item/3 = "PRIMARY") (item/2 = "0" ) ] [
                        primary-index-name: item/5
                        break
                    ]
                ]
                fd: get-field-details
                for i 1 (length? fd) 1  [
                    if fd/:i/1 = primary-index-name [
                        primary-index-offset: :i
                        break
                    ]
                ]
            ]
            if offset [
                return primary-index-offset
            ]
            return primary-index-name
        ]
        get-field-details: func [
            /for-table table-name  [string!]
            /for-field afield-name [string!]
            /for-all
            /return-field-num 
        ][
            if not for-all [
                either for-table [

                    a-table: to-word table-name
                ][
                    a-table: to-word table
                ]
            ]
            either any [ (for-table) ( not for-all) ] [
                if ( not do-safe [ r: _field-details_/:a-table ] "get-field-details function^/Can't get valid information." ) [
                    return []
                ]
            ][
                if ( not do-safe [ r: _field-details_ ] "get-field-details function. Can't get valid information." ) [
                    return []
                ]
            ]                
            if for-field [
                either return-field-num [
                    r: second (find-in-array-at/with-index r 1 afield-name)
                ][
                    r: find-in-array-at r 1 afield-name    
                ]
            ]
            return r
        ]
        get-table-list: func [
            /local r fe
        ][
            return _table-list_
        ]
        get-field-datatype: func [ field-name /for-table table-name ] [
            either for-table [
                a-table: to-string table-name
            ][
                a-table: to-string table
            ]
            first parse ( second find-in-array-at ( get-field-details/for-table a-table ) 1 field-name) "("
        ]
        get-human-readable-data: func [
            src-fld-name src-fld-data
            /local human-read f i hr-res
        ][
            the-related-field-list: get-related-field-list
            forskip the-related-field-list 2 [
                if (table = first the-related-field-list ) [
                    if (found? f: find second the-related-field-list src-fld-name) [ 
                        i: f/2
                        if i/3 = none [ return "" ]
                        sel-str: trim i/3
                        replace/all sel-str " " ","
                        hr-sql-cmd: rejoin [ "select " sel-str " from " i/1 " WHERE " i/2 " = " "'" src-fld-data "'"  ]
                        hr-res: run-sql hr-sql-cmd
                        either hr-res = [] [
                           return ""
                        ][
                            return trim form first hr-res
                        ]
                    ]
                ]
            ]
            return "" ; no human readable found for this table
        ]
        run-sql: func [ sql-statement /limit hi-limit /return-block /debug /reopen reopen-database
                        /local r limit-count sql-cmd  res-block rec-blk record ;field-details
                        ; Global in context: last-table table last-database
        ][
            if all [ (table = "") (( first parse sql-statement " " ) = "select" ) ] [
                my-request rejoin [ "No table has been specified" newline "Please select a table." ]
                return []
            ]tab
            last-query-string: copy sql-statement
            r: copy []
            either reopen [
                last-database: ""
                open-database: copy reopen-database
            ][
                open-database: copy database
            ]
            either (last-database <> database )  [
                if last-table <> "" [ ; Test if this is original open of table
                    close mysql-port ; Close and reopen port
                ]
                sql-cmd: rejoin [ mysql:// user ":" pass "@"  host "/" open-database ]
                ds: do-safe [ mysql-port: open sql-cmd ] "Database Query"
                either not ds [
                    return false
                ][
                    if (open-database <> "") [
                        database: copy open-database
                    ]
                ]
            ][
            ]
            if limit [
               append sql-statement rejoin [ " LIMIT " hi-limit ]
            ]
            if error? err: try [ ; TRY #1
                r: send-sql mysql-port sql-statement
                true ; make the try happy
            ][
                the-error: disarm :err
                either the-error/id = 'not-open [ trailer-msg: "^/WILL RETRY OPENING OF PORT" ] [ trailer-msg: "" ]
                my-request rejoin [ {run-sql - PHASE 1 ERROR^/} dump-error-obj the-error {^/Original SQL Statement:} sql-statement trailer-msg ]
                if the-error/id = 'not-open [ last-database: copy "" last-table: copy "" ] ; Force a re-open
                return []
            ]
            last-table: copy table
            last-database: copy database
            if return-block [ ; need to parse out 'select and 'from values.
                sql-blk: parse sql-statement none
                either ( found? fnd-pos: find sql-blk "from" )[
                    fd: get-field-details/for-table first next fnd-pos
                    selected: trim first delim-extract sql-statement "select" "from"
                    if selected <> "*" [
                        selected-items: parse selected ","
                        fd: copy []
                        foreach i selected-items [
                           append/only fd to-block i
                        ]
                    ]
                ][
                    my-request "run-sql/return-block ERROR: SQL statement doesn't contain a valid FROM table "
                    return
                ]

                res-block: copy []
                len-r: length? r
                for r-index 1 len-r 1 [
                    fd-index: 0
                    rec-blk: copy []
                    foreach data-item r/:r-index [
                        ++ fd-index
                        append rec-blk compose [ ( to-word fd/:fd-index/1 ) (data-item) ]
                    ]
                    append/only res-block copy rec-blk

                ]
                return res-block
            ]
            return r
        ]
        dupe-record: func [
            table-name id-num
            /local sql-cmd-head sql-cmd-tail 
            ; Global to this context field-details
        ][
            sql-cmd-head: copy rejoin [  "insert into " table-name "( " ]
            sql-cmd-tail: copy " select "
            fd: edit-db/get-field-details
            foreach f (skip fd 1) [
                append sql-cmd-head rejoin [ f/1 ", " ]
                append sql-cmd-tail rejoin [ f/1 ", " ]
            ]
            remove/part skip tail sql-cmd-head -2 2
            remove/part skip tail sql-cmd-tail -2 2
            append sql-cmd-head " )"
            append sql-cmd-tail rejoin [ " from " table-name " WHERE ID='" id-num "'" ]
            full-sql-cmd: rejoin [ sql-cmd-head sql-cmd-tail ]
            run-sql full-sql-cmd
            return first first run-sql {SELECT LAST_INSERT_ID()}
        ]
        create-new-record: func [
            table-name
            /local values-str sql-cmd new-row f-details i
        ][
            run-sql rejoin [ {INSERT INTO } database "." table-name { () VALUES()}  ]
            new-row: run-sql {SELECT LAST_INSERT_ID()}
            if all [ ( new-row <> [[]]) ( new-row <> [["0"]] )] [
                new-row: first first new-row
                return to-integer new-row
            ]
            auto-increment: last first query-db/get-field-details
            either(auto-increment = "auto_increment") [
                my-request rejoin [ "Unable to create new record^/Problem with creating a new record^/New Record ID = " new-row ] 
            ][
                my-request rejoin [ "auto_increment has not been set for the 'ID' field.^/This need to be done for table: '" query-db/table "' before it ^/can be used by DB-Rider" ]
            ]
            return none
        ]
        insert-new-record: func [ 
            table-name record-values [ object! ] 
            /field-xref-block field-xref
            /local ivalues-str sql-cmd new-row f-details get-field-value i
        ][
            f-details: get-field-details/for-table table-name
            get-field-value: func [ rec-vals field-name ] [
                either field-xref-block [
                    either xref-name: select field-xref (to-word field-name) [
                        either ret-val: select rec-vals (to-lit-word xref-name ) [
                            return ret-val
                        ][
                            my-request rejoin [ "insert-new-record ERROR. Cross reference name of:" xref-name " not present in record-values block." newline
                                "A value of NONE will be used for field name: " field-name
                            ]
                            return none
                        ]
                    ][
                        return none
                    ]
                ][ ; No xref block used. Record field names match database exactly
                    either ret-val: select rec-vals (to-lit-word field-name ) [
                        return ret-val
                    ][
                        return none ; Not found in record-values
                    ]
                ]

                return none
            ]
            ivalues-str: copy {VALUES (}
            for i 1 (length? f-details) 1 [
                either ( i = primary-index?/offset ) [ ; find the primary index position and make it NULL
                    append ivalues-str "NULL"
                ][
                    current-field-name: f-details/:i/1
                    field-val: get-field-value record-values current-field-name
                    either field-val [
                        verified-field-value: verify-set-field table-name current-field-name field-val
                        append ivalues-str rejoin [ {'} verified-field-value {'} ] ; insert value from record supplied
                    ][
                        append ivalues-str rejoin [ {'} f-details/:i/5 {'} ] ; insert default value
                    ]

                ]
                either i = (length? f-details) [
                    break
                ][
                    append ivalues-str {, }
                ]
            ]
            append ivalues-str {)}
            sql-cmd: rejoin [ {INSERT INTO `} table-name {` } ivalues-str ]
            run-sql sql-cmd
            new-row: first first run-sql {SELECT LAST_INSERT_ID()}
            return to-integer new-row
        ]

        show-record: func [ table-name row-id /no-history-field  /local old-field ] [
            old-table: copy edit-db/table
            old-record-number: edit-db/current-record-number
            either no-history-field [
                old-field: ""
            ][
                old-field: edit-db/current-edit-field-name
            ]

            edit-db/set-table-name table-name
            append/only db-visit-history reduce [ edit-db/database old-table old-record-number old-field duplicate-text/show? ] ; *** This should pick primary index data only
            edit-mysql-record edit-db row-id
        ]

        verify-set-field: func [ table-name field-name new-value /local res-val ] [
            if (none? new-value) [
                request/ok rejoin [ "A value of NONE has been supplied to the field named:" field-name  newline "This will be ignored.The rest of the operations will still continue."]
                return
            ]
            field-datatype: get-field-datatype/for-table  field-name table-name
            either all [
                (field-datatype = "int")                                 ; if field requires integer
                ((type? new-value) <> integer!)                          ; and value supplied isn't an integer
                (edit-db/get-related-table-for table-name field-name)    ; and there is a related table for this field
            ][
                related: edit-db/get-related-table-for table-name field-name
                either related <> none [
                    the-qry: rejoin [ "select " related/2  " from " related/1 " WHERE " related/3 " = '" new-value "'" ]
                    r: run-sql the-qry
                    either ( r = [] ) [ ; There is no target record linked to this field
                        new-record-id: create-new-record related/1
                        new-record-field-datatype: get-field-datatype/for-table related/3 related/1
                        validated: validate-input-data new-value reduce [ table-name field-name ]
                        either (validated/1 = "true" )[
                            validated-data: validated/2
                        ][
                            my-request "verify-set-field ERROR. Can't validate data"
                            validated-data: ""
                        ]
                        sql-cmd: rejoin [ {update } related/1  { set `} related/3 {`='} sql-escape form validated-data {' WHERE `ID`='} new-record-id {'} ]
                        run-sql sql-cmd
                        res-val: new-record-id
                    ][
                        fr: first r
                        either (fr = [])  [
                            res-val: none
                        ][
                            res-val: fr
                        ]
                    ]
                ][
                   my-request rejoin [ "verify-set-field ERROR with table-name=" table-name " field-name=" field-name ]
                   res-val: none
                ]
            ][
                validated: validate-input-data new-value reduce [ table-name field-name ]
                either (validated/1 = "true" )[
                    new-value: validated/2
                ][
                    my-request [ "verify-set-field ERROR. Can't validate data. table-name=" table-name " field-name=" field-name ]
                    validated-data: ""
                ]
                return new-value
            ]
            return res-val
        ]
        get-related-table-for: func [ ; get-related-table-for:
            table-name
            field-name
            /local fl f2 fl-len x y z aa
        ][
            fl: get-related-field-list
            fl-len: length? fl
            for x 1 fl-len 2 [
                if fl/:x = table-name [
                    y: x + 1
                    item-len: length? fl/:y
                    for z 1 item-len 2 [
                        if fl/:y/:z = field-name [
                            aa: z + 1
                            return fl/:y/:aa
                        ]
                    ]
                ]
            ]
            return none
        ]
        set 'to-human func [ ; to-human:
            field-name [ string! ]
            /table-and-id table-id-block [ block! {Block containing table-name, field-id-number} ]
            /local related the-qry r fr the-ID sel-str
        ][
            either table-and-id [
                related: query-db/get-related-table-for table-id-block/1 field-name
                the-ID: table-id-block/2
            ][
                related: query-db/get-related-table-for query-db/table field-name
                the-ID: get to-get-word field-name
            ]
            either all [ (related <> none) (the-id <> "") (the-id <> 0 ) (the-id <> none) ][
                sel-str: trim related/3
                replace sel-str " " ","
                the-qry: rejoin [ "select " sel-str  " from " related/1 " WHERE " related/2 " = '" the-ID "' LIMIT 1" ]
                r: query-db/run-sql the-qry
                if r = [] [
                    return to-string the-ID
                ]
                fr: first r
                either (fr = [])  [
                    return to-string the-ID
                ][
                    return replace/all (to-csv/with fr " ") {"} {} ; " match quote
                ]
            ][
                if ( the-id = none )  [
                    the-id: copy ""
                ]
                return to-string the-ID
            ]
        ]
        set 'do-all-global-scripts func [ /local i full-path-and-file saved-cur-dir ] [ ; do-all-global-scripts:
            do-all-scripts-in-folder get-global-path root-path
        ]
    ]; ******************************************** End of db-obj ***************************************************************

    show-related-record: func [ 'field-id table-name key-field field-face ] [ 
        
        duplicate-flag: duplicate-text/show?
        hide duplicate-text
        field-name: to-string field-id
        lo-field-name: rejoin [ "-" field-name ]
        the-field-data: do compose [ get in ( to-word lo-field-name ) ( to-lit-word "text" ) ]
        old-table: copy edit-db/table
        old-record-number: edit-db/current-record-number
        edit-db/set-table-name table-name ; SELECT NEW TABLE
        t-sql-cmd: rejoin [ {select * from } edit-db/table " where " key-field "='" the-field-data "'" ]
        the-data: edit-db/run-sql t-sql-cmd
        either the-data = [] [
            edit-db/set-table-name old-table
            z: my-request/face/buttons rejoin [ {The record that is related to the field named '} to-string field-id {'^/does NOT exist.^/SQL command =[} t-sql-cmd {]} ] field-face "Edit the Target Table"
            if z = "Edit the Target Table" [
                edit-db/set-table-name table-name ; SELECT NEW TABLE
                append/only db-visit-history reduce [ edit-db/database old-table old-record-number field-name duplicate-flag ] ; *** This should pick primary index data only
                edit-mysql-record edit-db 1
            ]
         ][
             append/only db-visit-history reduce [ edit-db/database old-table old-record-number field-name duplicate-flag ] ; *** This should pick primary index data only
             edit-mysql-record edit-db ( to-integer the-data/1/1 ) ; **** This should be made more generic.
        ]
        
        display-record/current
    ]
    block-to-string: func [ the-block [block!] ] [
        str: to-string mold the-block
        copy/part skip str 1 ( (length? str) - 2 )
    ]
    set-gui-field: func [ 
        field-name [any-type!] ; layout-field-name format
        value [any-type!] 
        /local copy-value sql-cmd 
    ]
    [
        field-name: to-string field-name
        copy-value: copy to-string value
        complex-set/no-check  [ to-lit-word field-name  'text ] copy-value
        show get to-lit-word field-name
        the-name: to-set-word to-string field-name
    ]

    run-function-key: func [ fkey-name [string!] /local fk fkerr ] [
        field-alias: get to-word rejoin [ fkey-name "-field" ]
        run-filename: join edit-db/get-function-key-path rejoin [ field-alias/text ".r" ]
        
        either exists? run-filename  [
            do-safe [ rf: load run-filename
                      do bind rf 'record-face
            ] reduce  [ "Function key script" run-filename ]
        ][
            my-request rejoin [ {no fkey action file available for } fkey-name ]
        ]
    ]
    load-last-saved-fkey: does [
        f1-field/text: ""
        f2-field/text: ""
        if (exists?  fkeyfile: join edit-db/get-function-key-path %last-f1-key.datr ) [
            f1-field/text: load fkeyfile
        ]
        if (exists?  fkeyfile: join edit-db/get-function-key-path %last-f2-key.datr ) [
            f2-field/text: load fkeyfile
        ]
		show f1-field
  	    show f2-field
    ]
    menu-data: [
        m-file: item "File"
              menu [
                           item "Database Connection" [ edit-db-connection edit-db ]
                  new:     item "New" [ do-request-file-open-new ]
                           item "Open" [ do-request-file-open-new ]
                           ---
                  exit:    item  "Close" [  close-edit-record-window ]
              ]
        m-edit: item "Edit"
            menu [
                item "Field Actions" [
                    fa: to-file edit-db/get-field-actions-filename
                        if ( not exists? fa) [
                             the-path: first split-path fa
                             if not exists? the-path [
                                 make-dir/deep the-path
                             ]
                             write fa edit-db/create-field-actions-initial-code edit-db edit-db/table
                        ]
                        edit-db/edit-text-file fa
                ]
                item "Relationships" [
                    run-relationship-editor
                ]
                item "Function Keys" [
                    if ( not exists? edit-db/get-function-key-path ) [ make-dir edit-db/get-function-key-path ]
                    call rejoin ["start " to-local-file edit-db/get-function-key-path ]
                ]
            ]
        m-settings: item "Settings" 
            menu [
                mcapture-errors: item "Capture Errors" check on [ 
                    either capture-errors [
                        capture-errors: false
                        user-msg/query "capture errors is OFF"
                    ][
                        capture-errors: true
                        user-msg/query "capture errors is ON"
                    ]
                ]
                item "Flush request-db-list cache" [
                    request-db-list/flush "" ""                
                    user-msg/query "request-db-list cache cleared."
                ]
            ]
    ]
    
    edit-record-layout: layout ; ---------------------------- START OF EDIT RECORD LAYOUT -----------------------------------------------
    [ 
        backdrop 100.100.100
        
        at 0x0 box 220.220.220 625x29 ; backdrop for menu area
        at 2x2 app-menu: menu-bar menu menu-data menu-style winxp-style snow
        across
        origin 10x35
        space 0x4
        label white "Database:"
        database-name-field: field 100x24
        space 8x4
        db-button: button 24x24 drop-down-img [
            requester-location: screen-offset? face
            db-list: edit-db/run-sql  "show databases"
            the-request-list: copy []
            foreach db-name db-list [ insert the-request-list db-name ]
            request-result: request-list-enhanced/offset/one-click "Select Database" the-request-list requester-location
            if request-result <> none [
                database-name-field/text: request-result
                show database-name-field
                table-name-field/text: ""
                show table-name-field
            ]
        ]
        space 0x4
        label white "Table:"

        table-name-field: field 100x24
        space 8x4
        table-button: button 24x24 drop-down-img [
            requester-location: screen-offset? face
            table-list: edit-db/run-sql  rejoin [ "show tables from " database-name-field/text ]
            the-request-list: copy []
            foreach table-name table-list [ insert the-request-list table-name ]
            if (request-result: request-list-enhanced/offset/one-click "Select Table" the-request-list requester-location) [
                table-name-field/text: request-result
                show table-name-field
                edit-db/database: database-name-field/text
                edit-db/set-table-name table-name-field/text
                edit-mysql-record edit-db -1
            ]
        ]
        duplicate-text: text 140x24 bold red white as-is "  DUPLICATE RECORD  " with [ show?: false ]
        space 8x4
        return
        space 0x4
        label "Link Depth:"  space 4x4 tables-deep-field: field 24x24
        back-track-button: button 105x24 "Back Track-F12" [
            save-current-field
            if (length? db-visit-history) < 1 [
                my-request/face  "Can not 'Back Track' to a previous table^/because no previous tables have been visited." face  ; " match quote
                return
            ]
            a: last db-visit-history
            db-name: a/1
            table-name: a/2
            record-id: ( to-integer a/3)
            edit-db/database: db-name
            edit-db/set-table-name table-name
            remove back tail db-visit-history ; remove last entry from stack
            either ( a/4 = "" ) [ ; a/4 = field-name that F12 started from
                either a/5 [      ; duplicate flag is on
                    edit-mysql-record/duplicate-flag edit-db record-id
                ][
                    hide duplicate-text
                    edit-mysql-record edit-db record-id
                ]
            ][
                next-field-name: get-next-field-name a/4
                either a/5 [ ; duplicate flag is ON
                    edit-mysql-record/reprocess-field-assist-button/duplicate-flag/focus-to-field edit-db (to-integer a/3) a/4 a/4
                ][
                    edit-mysql-record/reprocess-field-assist-button/focus-to-field edit-db (to-integer a/3) a/4 a/4
                ]
            ]
        ] keycode [ F12 ]
        button 100x24 "New Record-F6" [
            save-current-field
            add-and-display-record
            if all [ ( edit-db/on-new-record-code <> [] ) ( edit-db/on-new-record-code <> none) ] [
                do-safe [ do bind reduce edit-db/on-new-record-code 'record-face ]
                reduce [  
                    rejoin [ "field-actions.r for^/     TABLE: '" edit-db/table "'^/CODE BLOCK: 'on-new-record'^/******************* START OF CODE *******************^/" mold edit-db/on-new-record-code newline "******************** END OF CODE *******************" ]
                    join edit-db/get-table-path "field-actions.r"
                    "on-new-record"
                ]
            ]
        ] keycode [	F6 ]
        button 60x24 "Delete" [
            p-ndx-name: edit-db/primary-index?
            p-ndx-data: do compose [ get in ( to-word rejoin [ "-" p-ndx-name ] ) ( to-lit-word "text" ) ]
            rr: request rejoin [ "Are you sure you want to delete this record?" ]
            either ( rr <> true ) [
                user-msg "Delete operation ABORTED"
            ][
                scmd: rejoin [ {DELETE FROM `} edit-db/table {` WHERE `} p-ndx-name {`='} p-ndx-data {'} ]
                edit-db/run-sql scmd
                display-record/down
            ]
        ]
        dup-record: button 100x24 "Duplicate-F8" [
            save-current-field
            if all [ (on-duplicate-record-code <> [])(on-duplicate-record-code <> none ) ] [
                if (sa: select on-duplicate-record-code 'source-record-actions)[
                    do-safe [ do bind reduce sa 'record-face ]
                    reduce [
                        rejoin [ "'field-actions.r' script^/     TABLE: '" edit-db/table "'^/    ACTION: 'on-duplicate-record/source-record-actions'^/"  ]
                        join edit-db/get-table-path "field-actions.r" 
                        reduce ["on-duplicate-record" "source-record-actions"] 
                    ]
                ]
            ]
            new-row: edit-db/dupe-record edit-db/table edit-db/current-record-number
            display-record/specific/duplicate (to-integer new-row)
            if all [ (on-duplicate-record-code <> []) (on-duplicate-record-code <> none) ] [
                if (ta: select on-duplicate-record-code 'target-record-actions)[
                    do-safe [ do bind reduce ta 'record-face ]
                    reduce [
                        rejoin [ "'field-actions.r' script^/     TABLE: '" edit-db/table "'^/    ACTION: 'on-duplicate-record/target-record-actions'^/"  ]
                        join edit-db/get-table-path "field-actions.r" 
                        reduce ["on-duplicate-record" "target-record-actions"] 
                    ]
                ]
            ]
        ]  keycode [ F8 ]
        label white blue center 140x24 "New Target Record-F5"
        return
        virtual-box: box ( virtual-box-size + 16x16) ; accomodate scroll bars
        return
        across
        label "Record ID:" 105x24 right
        space 0x4
        record-number-display: field "" 50x24 [
            display-record/specific ( to-integer record-number-display/text )
            record-number-display/text: edit-db/current-record-number
            show record-number-display
        ]
        space 1x4
        button 30x24 " < " [
            display-record/down/save-the-current-field
        ] #"^k"
        space 6x6
        button 30x24 " > " [
            display-record/up/save-the-current-field
        ] #"^l"
        space 6x12
        button 60x24 "refresh" [
            edit-db/update-datatype-assist-actions/reload
            edit-db/update-relationship-assist-actions/reload
            edit-db/related-field-list: copy  []
            display-record/current
        ]
        space 6x6
        return
        label "Message:" 105x24 right
        edit-user-msg-field: field 500x24
        return
        label "Rebol Command:" 105x24 right
        rcmd: s-field 500x24 with [
            on-submit: func[/local value] [
                either capture-errors [
                    if error? err: try [
                        do rcmd/text
                        true 
                    ][
                        the-error: disarm :err
                        show-error-details the-error "Manually entered Rebol command" ""
                    ]
                ][
                    do rcmd/text
                ]
                true
            ]
        ]
        return
        space 0x0
        f1: button 35x24 "F1 =" [
            run-function-key "f1"
        ] keycode [ f1 ]
        f1-field: field 245x24
        space 8x4
        button 24x24 drop-down-img [ ; F1 button script attached
            the-request-list: first (make-script-list/exclude-extension reduce [ edit-db/get-function-key-path ])
            if not (request-result: request-script-name "function-key" the-request-list edit-db screen-offset? face ) [
                return
            ]
            f1-field/text: request-result
            show f1-field
            save (join edit-db/get-function-key-path %last-f1-key.datr ) f1-field/text
        ]
        space 0x0
        f2: button 35x24 "f2 =" [
            run-function-key "f2"
        ] keycode [ f2 ]
        f2-field: field 245x24
        space 6x4
        button 24x24 drop-down-img [ ; f2 button script attached
            the-request-list: first (make-script-list/exclude-extension reduce [ edit-db/get-function-key-path ])
            if not (request-result: request-script-name "function-key" the-request-list edit-db screen-offset? face ) [
                return
            ]
            f2-field/text: request-result
            show f2-field
            save (join edit-db/get-function-key-path %last-f2-key.datr ) f2-field/text
        ]
		space 0x0
		sensor 0x0 keycode [ #"^(ESC)"] [
            close-edit-record-window
		]
        time-sensor: sensor 0x0 rate 100 feel [
            engage: func [face action event] [
                if action = 'time [
                    either ( (length? db-visit-history) > 0 )[
                        enable-face back-track-button
                    ][
                        disable-face back-track-button
                    ]
                    time-sensor/rate: none
                    show face
                    see-face get system/view/focal-face/var
                ]
            ]
        ]		
        do [ ; edit-record-layout setup ``
            insert-event-func :close-handler
            set 'close-edit-record-window does [ ; close-edit-record-window:
                hide duplicate-text
                db-visit-history: copy []
                unview/only edit-record-layout
            ]
            over-virtual-box?: false
            edit-event-handler: func [face event ] [
                if (event/face/text = "Edit Record") [
                    db-rider-context/set-field-history: copy []
                    switch event/type [
                        scroll-line [ 
                            if (over-virtual-box?) [
                                either ( positive? event/offset/y ) [
                        		   scroll-virtual-list -1
                        		][
                        		   scroll-virtual-list 1
                        		] 
                            ]
                        ]
                        move [
                            edit-db/current-mouse-position: event/offset
                            either (within? event/offset virtual-box/offset virtual-box/size) [
                                over-virtual-box?: true
                            ][
                                over-virtual-box?: false
                            ]
                        ]
                    ]
                ]
                return event
            ]
        ]
    ] ; ----------------------------  END OF EDIT RECORD LAYOUT ------------------------------------------------

    add-and-display-record: does  [
        display-record/specific (to-integer edit-db/create-new-record edit-db/table)
    ]
    
    save-current-field: func [ /local db-field-name ] [
        if system/view/focal-face [
            db-field-name: remove to-string system/view/focal-face/var
            either (find-in-array-at edit-db/get-field-details 1 db-field-name)[
                set-field db-field-name select get system/view/focal-face/var 'text        
            ][
            ]
        ]
    ]
    
    display-record: func [ 
        /up 
        /down 
        /first-record 
        /current 
        /duplicate 
        /save-the-current-field 
        /specific specific-record 
        /local focus-to
    ]
    [
        focus-to: "NOTVALID"
        either duplicate [
            show duplicate-text
        ][
            hide duplicate-text
        ]
        last-record: false

        if save-the-current-field [
            save-current-field        
        ]
        either up [
            new-record-position: edit-db/run-sql rejoin [ {select * from } edit-db/table  { where } edit-db/primary-index?/name  { > } edit-db/current-record-number { order by } copy edit-db/primary-index?  { ASC limit 1} ]
            if new-record-position = [] [
                first-record: true
            ]
        ][
            either down [
                new-record-position: edit-db/run-sql rejoin [ {select * from } edit-db/table  { where } edit-db/primary-index?  { < } edit-db/current-record-number { order by } edit-db/primary-index?  { DESC limit 1} ]
                if new-record-position = [] [
                    last-record: true
                ]
            ][
                if specific [
                    sql-cmd: rejoin [ {select * from } edit-db/table  { where } edit-db/primary-index?  { = } specific-record { order by } edit-db/primary-index?  { ASC limit 1} ]
                    new-record-position: edit-db/run-sql sql-cmd
                    if new-record-position = [] [
                        my-request [ "Can not find record selected^SQL command:" sql-cmd ]
                        return
                    ]
                ]
                if current [
                    sql-cmd: rejoin [ {select * from } edit-db/table  { where } edit-db/primary-index?  { = } edit-db/current-record-number { order by } edit-db/primary-index?  { ASC limit 1} ]
                    new-record-position: edit-db/run-sql sql-cmd
                ]
            ]

        ]
        if first-record [
            new-record-position: edit-db/run-sql rejoin [ {select * from } edit-db/table  { order by } edit-db/primary-index?  { ASC limit 1} ]
        ]
        if last-record [
            new-record-position: edit-db/run-sql rejoin [ {select * from } edit-db/table  { order by } edit-db/primary-index?  { DESC limit 1} ]
        ]
        if (new-record-position = [])[ ; then there aren't any records in this table
            my-request rejoin [ "This table doesn't contain any records." newline " A new blank record has been created for you." ]
            new-rec: edit-db/create-new-record edit-db/table
            new-record-position: reduce [ reduce [:new-rec]]
        ]
        new-record-position: ( to-integer new-record-position/1/1 )
        try-new-face: true
        while [ try-new-face ] [
            either ( system/view/focal-face = none ) [
                focus-to: none
            ][
                focus-to: remove copy to-string system/view/focal-face/var ; provide db-field-name format
            ]
            record-face: create-face/focus-to-field edit-db new-record-position focus-to
            either ( record-face = none )[ 
                request/ok  rejoin [ "display-record: Unable to retreive row-id:" error-record ]
                return
            ][
                try-new-face: false
            ]
        ]
        redraw-virtual virtual-box record-face
    ]
    to-rebol-string: func [ s ] [
        either(s) [
            to-string s
        ][
            ""
        ]
    ]
    process-field: func [ 
        'field-id pf-edit-db row-id orig-field-data field-datatype code-block
        /update
        /local sql-cmd sql-result primary-changed? hr-data field-val good-field-data
    ]
    [
        primary-changed?: false
        db-field-name: to-string field-id
        field-name: to-string field-id
        lo-field-name: rejoin [ "-" db-field-name ] ; layout field name 
        field-changed?: do compose [ get in ( to-word lo-field-name ) 'dirty? ]
        if update [ field-changed?: true ]
        if field-changed? [
            complex-set [ to-word :lo-field-name to-word "dirty?" ] false
        ]
        either update [
            the-field-data: orig-field-data
        ][
            the-field-data: do compose [ get in ( to-word lo-field-name ) 'text ]    
        ]
                        
        if field-changed? = true [ ; If field has changed it is automatically saved.
            d**: field-details: edit-db/get-field-details/for-table/for-field  edit-db/table field-name
            validated: validate-input-data (reduce the-field-data) reduce [ edit-db/table field-name ]
            either (validated/1 = "true" )[
               validated-data: validated/2
               if ((to-rebol-string validated-data) <>  (to-string the-field-data)) [
                  set-gui-field lo-field-name (to-rebol-string validated-data)
                  if not update [
                      user-msg/edit  rejoin [ "Field data modified. Data you entered ='" to-string the-field-data "' . Data changed to ='" to-string validated-data "'" ]
                  ]
               ]
            ][ ; data supplied is NOT VALID
                f-obj: do mold (to-word lo-field-name)
                edit-db/flash-field :f-obj
                old-field-data: pf-edit-db/run-sql rejoin [ {SELECT } field-id { FROM } pf-edit-db/table { WHERE ID = '} row-id {'} ]
                either ( old-field-data = [] ) [
                    f-obj/text: orig-field-data 
                ][
                    f-obj/text: first first old-field-data
                ]
                if (f-obj/line-list <> none) [ ; check for CRASH conditions
                    f-obj/line-list: none
                ]
                show f-obj            
                set-focus field-id    
                if (not unit-testing) [
                    my-request rejoin [ 
                        validated/3 
                        "^/The new data you entered has been CHANGED BACK"
                        "^/The input is NOT valid for the field name: '" field-id 
                        "'.^/The input needs to be of type ='" field-datatype "'."  
                    ]
                ]
                exit
            ]
            sql-cmd: rejoin [ {update } pf-edit-db/table  { set `} db-field-name {`='} sql-escape form validated-data {' WHERE `ID`='} row-id {'} ]
            pf-edit-db/run-sql sql-cmd
            ; update human readable text if it exists
            either value? to-word rejoin [ "hr-" db-field-name ] [
               hr-data: to-string edit-db/get-human-readable-data db-field-name validated-data
               complex-set/no-check  [ to-lit-word rejoin [ "hr-" db-field-name ]  'text ] hr-data
               show get to-lit-word rejoin [ "hr-" db-field-name ]
            ][
            ]

             if primary-changed? [
                display-record/specific ( to-integer the-field-data )
             ]
        ]
        if code-block <> [] [ ; run the "on-return" code
            field-actions-func :field-id row-id orig-field-data code-block "on-return"
        ]
    ]
    make-reprocess-assist-code: func [
        orig-code
        current-field-value
        the-field-name
        the-row-number
        /local orig-code-text new-text text-to-replace
    ][
        orig-code-text: mold orig-code 
        text-to-replace: delim-extract/include-delimiters/first orig-code-text {request-db-list} {)} ; "
        new-text: rejoin [ {reduce [ "} current-field-value {" ] ) } ]
        replace orig-code-text text-to-replace new-text
        the-code:  compose/deep [
            if redrawing-virtual [
                ; ************ START SETUP CODE FOR ALL FIELD ACTIONS
                this-field: form the-field-name 
                next-field: get-next-field-name this-field
                edit-db/current-edit-field-name: this-field
                edit-db/current-edit-row: the-current-id: ( reduce the-row-number)
                edit-db/current-edit-field-data: ( reduce current-field-value )
                ; ************ END  SETUP CODE FOR ALL FIELD ACTIONS
                ( do orig-code-text )
            ]
        ]
        return the-code
    ]
    create-face: func  [
        cfedit-db [object!]
        row-number [integer!] {row-number 0 is last record, row-number -1 is first record }
        /relative 
        /focus-to-field focus-field-name ; db-field-name format
        /reprocess-field-assist-button reprocess-field-name
        /local the-field-details primary-index-name the-data tcmd comparison new-num dtype-conversion
    ]
    [ 
        time-sensor/rate: 100
        if ( not found? find system/view/screen-face/feel/event-funcs :edit-event-handler ) [
          insert-event-func :edit-event-handler              
        ]
        either reprocess-field-assist-button [
            check-reprocess-field-assist-button: true
        ][
            check-reprocess-field-assist-button: false
        ]
        tstr: now/time/precise
        the-field-details: cfedit-db/get-field-details
        record-data: copy []
        results: copy [ ; This is the resulting face created by this function
            styles vstyle
            across
            space 4x4
        ]
        primary-index-name: cfedit-db/primary-index?
        if/else (row-number = 0) [
              scmd: rejoin [ "select * from " cfedit-db/table " order by " primary-index-name " DESC" ]
              the-data: cfedit-db/run-sql/limit scmd 1
        ][
            if/else (row-number = -1) [
              scmd: rejoin [ "select * from " cfedit-db/table " order by " primary-index-name " ASC" ]
              the-data: cfedit-db/run-sql/limit scmd 1
            ][
                if/else row-number < cfedit-db/current-record-number [
                    comparison: " = "
                    order-by: rejoin [ " order by " primary-index-name " DESC" ]
                ][
                    order-by: rejoin [ " order by " primary-index-name " ASC" ]
                    comparison: " >= "
                ]
                if ( not relative ) [
                    comparison: " = "
                    order-by: copy ""
                ]
                tcmd: rejoin [ {select * from } cfedit-db/table " where " primary-index-name comparison row-number order-by ]
                the-data: cfedit-db/run-sql/limit tcmd 1
            ]
        ]
        if the-data = [] [ ; Then end of data has been reached
            the-data: cfedit-db/run-sql/limit rejoin [ {select * from } cfedit-db/table " where " primary-index-name " >= '1'"  ] 1
            if the-data = [] [
                either any [ (row-number = 1) (row-number = -1)] [
                    my-request rejoin [ "This table doesn't contain any records." newline " A new blank record has been created for you." ]
                    add-and-display-record
                    return results
                ][
                    my-request  rejoin [ "Create-face: Unable to retreive row-id: " row-number " or the first record. This is a unrecoverable error." ]
                    return results
                ]
            ]
        ]
        cfedit-db/previous-record-number: cfedit-db/current-record-number
        repeat count (length? the-field-details) [
            if ( found? find the-field-details/:count primary-index-name ) [
                primary-index-location: count
                break
            ]
        ]
        cfedit-db/current-record-number: to-integer the-data/1/:primary-index-location
        row-number: cfedit-db/current-record-number
        cfedit-db/get-related-field-list ; this fills in the cfedit-db/related-field-list
        either ( exists? field-actions-file: cfedit-db/get-field-actions-filename  ) [
            do-safe [ field-actions: load field-actions-file ] 
            reduce [
                "field-actions.r" 
                cfedit-db/get-field-actions-filename    
            ]
        ][
            make-dir/deep first split-path field-actions-file
            field-actions: load cfedit-db/create-field-actions-initial-code cfedit-db cfedit-db/table
        ]
        on-display-record-code: select field-actions 'on-display-record
        on-duplicate-record-code: select field-actions 'on-duplicate-record
        query-db/on-new-record-code: edit-db/on-new-record-code: select field-actions 'on-new-record
        if ( not field-actions) [
            field-actions: copy []
        ]
        field-actions-list: copy []
        forskip field-actions 2 [ append field-actions-list first field-actions ]
        field-actions: head field-actions ;set things back
        field-number: 1
        field-details-len: length? the-field-details
        for ndx 1 field-details-len 1 [
            db-field-name: copy the-field-details/:ndx/1
            field-name: copy rejoin [ "-" db-field-name ]
            field-type: copy the-field-details/:ndx/2
            dtype-conversion: :to-string   
            field-data: the-data/1/:ndx
            field-data: copy  either field-data [ to-string field-data ] [ "" ]
            ; process-field corrects for the datatype when writing data.
            append/only record-data field-data
            field-id: to-set-word  field-name
            field-id make object! []
            field-datatype: the-field-details/:ndx/2
            field-action: copy []
            code-block: copy []
            assist-button: copy []
            assist-button-action: copy [[]]
            F5-button-action: copy [[]]
            human-readable-button: copy []
            spacer: [ space 24x4 ]
            spacer44: [ space 4x4 ]
            assist-button-code: none
            on-return-code: none
            on-new-target-record-code: []
            if (found-pos: find field-actions-list (to-string db-field-name)) [ ; Then field action is required
                field-actions-block: pick field-actions ((index? found-pos) * 2 )
                
                on-return-code: select field-actions-block 'on-return
                assist-button-code: select field-actions-block 'assist-button
                on-new-target-record-code: select field-actions-block 'on-new-target-record
                either any [ (assist-button-code = none) (assist-button-code = []) ] [
                   assist-button-action: [[]]
                ][
                    assist-button: [ space 0x4 button "..." blue white 20x21 ]
                    assist-button-action:  compose reduce [
                        (reduce  [
                            (to-set-word "F5-field-actions-block") reduce [ 'F5-field-actions-func :db-field-name :row-number :field-data :assist-button-code :on-new-target-record-code ]
                            'field-actions-func :db-field-name :row-number :field-data :assist-button-code "assist-button"
                        ]) 
                    ]
                    if ( find to-string assist-button-code "request-db-list" ) [
                        F5-button-action:  compose reduce [ (reduce  [ 'F5-field-actions-func :field-name :row-number :field-data :assist-button-code :on-new-target-record-code ]) ]    
                    ]
                    spacer: [ space 4x4 ]
                ]
            ]
            if check-reprocess-field-assist-button [
                if field-name = reprocess-field-name [
                    reprocess-code: make-reprocess-assist-code assist-button-code field-data field-name row-number
                    check-reprocess-field-assist-button: false
                ]
            ]
            field-action-block: compose  [ process-field (:db-field-name) cfedit-db (:row-number) (:field-data) (:field-datatype) ( reduce [ on-return-code ]) ]
            label-type: [ label white brown left font-name font-fixed 130x21 ]
            hr-action-block: copy []
            if ( found? table-fnd: find cfedit-db/related-field-list cfedit-db/table ) [ ; Check for table entry
                if ( found? entry-fnd: find table-fnd/2 (to-string db-field-name) ) [ ; Check for field name entry - to display related field information.
                    hr-action-block: reduce [ 'show-related-record (:db-field-name) entry-fnd/2/1 entry-fnd/2/2 'face ]
                    hr-value: to-string cfedit-db/get-human-readable-data db-field-name field-data
                    if hr-value = none [
                        hr-value: ""
                    ]
                    hr-field-id: to-set-word rejoin [ "hr" field-name ]
                    hr-field-id make object! []
                    human-readable-button: reduce [ :hr-field-id 'button 'left 'no-wrap blue white 200x21 hr-value ]
                ]
            ]
            field-name-label: copy db-field-name
            if ((length? field-name-label) > 15 )[ field-name-label: rejoin [ (copy/part field-name-label 15) ".." ] ]; truncate long field names
            field-size: 220x21
            either ( db-field-name = "ID" ) [
                field-type: to-block { text bold 0.0.0 225.225.225 }
                field-size: field-size - 1x1
            ][
                field-type: to-block { vfield }
            ]
            append results compose/deep [ ; Create the labels and fields here.
                (:spacer)
                (label-type) (to-string field-name-label)  [ (hr-action-block) ]
                (assist-button) (assist-button-action)
                (:spacer44 )
                (:field-id) (field-type) (field-size) (field-data) [ (field-action-block) ] with [ user-data: [ assist-button (assist-button-action) F5-button (F5-button-action) ] ]
                (human-readable-button) [ (hr-action-block) ]
                return
            ]
            ++ field-number
        ]
        record-number-display/text: cfedit-db/current-record-number
        show record-number-display
        table-name-field/text: cfedit-db/table
        database-name-field/text: cfedit-db/database
        show table-name-field
        show database-name-field
        rec-num: 2
        if focus-to-field [
            if focus-field-name [ 
                new-num: find-in-array-at/with-index the-field-details 1 focus-field-name
                if ( new-num ) [
                    rec-num: new-num/2
                ]
            ]
        ]
        focus-here: to-word rejoin [ "-" the-field-details/:rec-num/1 ]
        do-for-face: compose [ 
            focus (:focus-here) 
        ] ; initial value for do-for-face
        if all [ ( on-display-record-code <> [] ) ( on-display-record-code <> none ) ] [
            append do-for-face compose/deep [ do-safe [ (on-display-record-code) ] [ "on-display-record code" (cfedit-db/get-field-actions-filename) "on-display-record" ]  ]
        ]
        either reprocess-field-assist-button [

            addition: reduce [ 'do reprocess-code ]
            edit-db/current-edit-field-name: "" ; Set this back to empty after reprocess
        ][
            addition: reduce [
                'do :do-for-face ; set focus to first field automatically or where focus-to-field has indicated
            ]
        ]
        append results addition
        addition: compose [
            key keycode 'F4 [
                if system/view/focal-face [
                    if (found? find (first system/view/focal-face) 'user-data )[
                        if (found? find  system/view/focal-face/user-data 'assist-button ) [
                            if (system/view/focal-face/user-data/assist-button <> []) [
                                if (found? find  system/view/focal-face/user-data 'F5-button ) [
                                    F5-field-actions-block: system/view/focal-face/user-data/F5-button
                                ]
                                do bind system/view/focal-face/user-data/assist-button 'record-face  ; SAFE // field-actions-func is catching errors for this action
                            ]
                        ]
                    ]
                ]
            ]
            key keycode 'F5 [
                if system/view/focal-face [
                    if (found? find (first system/view/focal-face) 'user-data )[
                        if (found? find  system/view/focal-face/user-data 'F5-button ) [
                            if (system/view/focal-face/user-data/F5-button <> []) [
                                do bind system/view/focal-face/user-data/F5-button 'record-face ; SAFE caught by function assigned to F5-button
                            ]
                        ]
                    ]
                ]
            ]
        ]
        append results :addition
        results
    ] ; ******************************************End of CREATE-FACE ****************************************************************************************************
    init-face: func [
        iedit-db
        row-id
        /new-window
        /focus-to-field focus-field-name ; db-field-name format
        /reprocess-field-assist-button reprocess-field-name
    ][
        either focus-to-field [
            either reprocess-field-assist-button [
                record-face: create-face/focus-to-field/reprocess-field-assist-button iedit-db row-id focus-field-name reprocess-field-name
            ][
                record-face: create-face/focus-to-field iedit-db row-id focus-field-name
            ]
        ][
            either reprocess-field-assist-button [
                record-face: create-face/reprocess-field-assist-button iedit-db row-id reprocess-field-name
            ][
                record-face: create-face iedit-db row-id
            ]
        ]
        either new-window [
            view-virtual/new-window/offset/title  edit-record-layout virtual-box record-face 100x28 "Edit Record" ; **** offset to be programmable
        ][
           view-virtual/offset/title edit-record-layout virtual-box record-face 0x0 "Edit Record" ; **** offset to be programmable
           redraw-virtual virtual-box record-face                         ;refresh when not a new window
        ]
        load-last-saved-fkey
        tables-deep-field/text: (length? db-visit-history)
        show tables-deep-field
        if  duplicate-text/show? [
            show duplicate-text
        ]
    ]
; ******************************************************************************************
;   Functions that are availble to all 'field-actions.r' scripts, for any record displayed
; ******************************************************************************************
    set 'to-db-field-name: func [ field-name /local copy-field-name ] [
        copy-field-name: copy field-name
        if ((first field-name) = #"-" ) [
            remove copy-field-name
        ]
        return copy-field-name
    ]
    set 'new-target-record func [ ; new-target-record:
            on-new-target-record-code [ block! ]
            /fieldname the-field-name {will accept layout field-name format or database field-name format}
            /local source-table target-table-fnd new-row target-table db-field-name field-to-find source-table-path this-field-name
    ]
    [
        if fieldname [
            db-field-name: to-db-field-name the-field-name
        ]
        source-table: find edit-db/related-field-list edit-db/table
        either source-table [
            field-to-find: to-db-field-name edit-db/current-edit-field-name
            target-table-fnd:  find (second source-table) field-to-find
            either target-table-fnd [
                target-table: first second target-table-fnd
            ][
                my-request rejoin  [ "Can not create a target record" newline "that is related to the field named '" db-field-name "'" ]
                return
            ]
        ][
            my-request rejoin  [ "Can not create a target record" newline "that is related to the field named '" db-field-name "'" ]
            return                        
        ]
        new-row: edit-db/create-new-record target-table
        either new-row [
            either fieldname [
                set-field db-field-name new-row
            ][
                set-field this-field new-row
            ]
            source-table-path: edit-db/get-table-path
            edit-db/show-record target-table new-row
            ; We are now at the *** TARGET TABLE ***
            if all [  ( on-new-target-record-code <> [] )  ( on-new-target-record-code <> none ) ] [
                this-field-name: trim/with ( copy the-field-name ) "-"
                if select on-new-target-record-code 'target-record-actions [
                    do-safe [ do bind reduce on-new-target-record-code/target-record-actions 'record-face ]
                    reduce [
                            rejoin [ "'field-actions.r' script^/     TABLE: '" source-table/1 "'^/     FIELD: '" this-field-name "'^/    ACTION: 'on-new-target-record/target-record-actions'^/"  ]
                            join source-table-path "field-actions.r"
                            reduce [ rejoin [ {"} this-field-name {"} ] "on-new-target-record" "target-record-actions" ] 
                    ] 
                ]
            ]
        ][
            return none
        ]
        return new-row
    ]
    set 'edit-mysql-record func [ ; edit-mysql-record:
        mysql-conn-descr [ object! ]
        row-id
        /focus-to-field focus-field-name ; db-field-name format
        /reprocess-field-assist-button reprocess-field-name
        /duplicate-flag
        /new-window
    ]
    [
        if focus-to-field [
        ]
        either duplicate-flag [
            duplicate-text/show?: true
        ][
            duplicate-text/show?: false
        ]
        row-id: to-integer row-id
        either new-window [
            edit-db: make mysql-conn-descr [] ; make a copy available in this context.
            either focus-to-field [
                init-face/new-window/focus-to-field edit-db row-id focus-field-name
            ][
                init-face/new-window edit-db row-id
            ]
        ][
           edit-db: mysql-conn-descr ;make edit-db Global to this context
           either focus-to-field [
                init-face/focus-to-field edit-db row-id focus-field-name
            ][
                either reprocess-field-assist-button [
                    init-face/reprocess-field-assist-button edit-db row-id reprocess-field-name
                ][
                    init-face edit-db row-id
                ]
            ]
        ]
    ]

    get-code-sample-line: func [ the-code /local i ] [
        the-code: mold/flat/only the-code
        the-code: parse/all the-code "^/"
        foreach i the-code [
            if (i <> "")[
                return i 
            ]
        ]       
    ]
    
    set 'F5-field-actions-func func [ ; F5-field-actions-func:
        'field-id
        Row-ID
        orig-field-data
        field-actions-code
        on-new-target-record-code
        /local f5-ret this-field-name
    ][ 
        edit-db/current-edit-field-name: to-string field-id
        edit-db/current-edit-row: Row-ID
        edit-db/current-edit-field-data: orig-field-data
        either all [ ( on-new-target-record-code <> [] ) ( on-new-target-record-code <> none ) ] [
                if select on-new-target-record-code 'source-record-actions [
                    this-field-name: trim/with form field-id "-"
                    do-safe [ do Bind reduce on-new-target-record-code/source-record-actions 'record-face ] 
                    reduce [
                        rejoin [ "'field-actions.r' script^/     TABLE: '" edit-db/table "'^/     FIELD: '" this-field-name "'^/    ACTION: 'on-new-target-record/source-record-actions'^/"  ]
                        join edit-db/get-table-path "field-actions.r"
                        reduce [ rejoin [ {"} this-field-name {"} ] "on-new-target-record" "source-record-actions" ] 
                    ]  
                ]
        ][
            on-new-target-record-code: copy [] ; to make the new-target-record function happy below
        ]
        
        do-safe [ f5-ret: new-target-record/fieldname on-new-target-record-code edit-db/current-edit-field-name ]
        reduce [
            rejoin [ "'field-actions.r' script^/     TABLE: '" edit-db/table "'^/     FIELD: '" this-field-name "'^/    ACTION: 'on-new-target-record/target-record-actions'^/"  ]
            join edit-db/get-table-path "field-actions.r"
            reduce [ rejoin [ {"} this-field-name {"} ] "on-new-target-record" "target-record-actions" ] 
        ]
        
        return reduce [ to-string f5-ret ]
    ]
    set 'field-actions-func func [ ; field-actions-func:
        'field-id 
        Row-ID 
        orig-field-data 
        field-actions-code 
        code-block-name [ string! ]
    ][ 
        this-field: form field-id                           ; global variable to this context
        next-field: get-next-field-name this-field
        edit-db/current-edit-field-name: this-field
        edit-db/current-edit-row: the-current-id: Row-ID
        edit-db/current-edit-field-data: orig-field-data
        ; ************ END  SETUP CODE FOR ALL FIELD ACTIONS

        if field-actions-code [
            do-safe [ do bind field-actions-code 'record-face ] 
            reduce [ 
                rejoin [ "'field-actions.r' script^/     TABLE: '" edit-db/table "'^/     FIELD: '" this-field "'^/    ACTION: '" code-block-name "'^/"  ]
                join edit-db/get-table-path "field-actions.r" 
                reduce [ rejoin [ {"} this-field {"} ] code-block-name ] 
            ]
        ]
    ]
    set 'set-focus func [ ; set-focus:
        field-name [string!]
        /next-field
        /local  rec-num fi fd item-no
    ]
    [
        if next-field [
            field-name: get-next-field-name field-name
        ]
        either field-name [
            field-name: rejoin [ "-" field-name ] 
            focus get to-lit-word field-name
        ][
            return ; field name of none means just ignore it.
        ]
    ]
    set 'get-next-field-name func [ ; get-next-field-name:
        field-name
        /local fi fd rec-num item-no
    ]
    [
        fd: edit-db/get-field-details
        fi: none
        fi: find-deep/index? fd field-name
        if ( fi = none ) [
            return none ; set-focus has failed - maybe on purpose. If table-name has changed.
        ]
        either ( (length? fd) = fi ) [
            rec-num: 1
            while [ fd/:rec-num/4 = "PRI" ] [ ; find first NON-PRIMARY INDEX field
                ++ rec-num
            ]
            item-no: rec-num
        ][
            item-no: fi + 1
        ]
        return fd/:item-no/1
    ]
    set 'set-field func [ ; set-field:
        [catch]
        field-name  ; accepts db-field-name format
        value 
        /local copy-value the-name j field-details fdfn field-datatype on-return-code faf fa fnd fnd-on set-field-lo-field-name set-field-again-string z prestr

    ][
        throw-on-error [
            field-name: to-string field-name
            if (found? find set-field-history field-name) [
                append set-field-history field-name
                set-field-history: map-each z set-field-history [ 
                    either (z = field-name) [prestr: ">> "] [ prestr: ""]
                    rejoin [ prestr z "^/" ] 
                ]
                throw make error! rejoin [ {Infinite 'set-field' loop detected on field name: '} field-name "'.^/Here is the sequence of set-field names:^/^/" set-field-history  ]
                return 
            ]
            append set-field-history field-name
            if (field-name = "ID") [ return ]
            set-field-lo-field-name: rejoin [ "-" field-name ]
            copy-value: copy to-string value
            complex-set/no-check  [ (to-lit-word set-field-lo-field-name ) 'text ] copy-value
            show get to-lit-word set-field-lo-field-name
            the-name: to-set-word to-string set-field-lo-field-name
            field-details: edit-db/get-field-details
            fdfn: (find-deep field-details field-name)
            if ( not fdfn) [ return ]
            
            field-datatype: pick fdfn 2
            

            on-return-code: copy []
            if exists? ( faf: edit-db/get-field-actions-filename )[
                fa: load faf
                if ( found? fnd: select fa to-string field-name )[
                    if ( fnd-on: select fnd 'on-return )[
                        on-return-code: fnd-on 
                    ]
                ]
            ]
            set-field-again-string: rejoin [ {set-field "} field-name {"} ]
            if any [ 
                (found? find mold on-return-code set-field-again-string ) 
                (found? find mold on-return-code "set-field this-field" ) 
             ][ 
                on-return-code: [] ; to avoid being caught by the infinite loop catcher and allow a field to set itself ONCE
            ]
            process-field/update :field-name edit-db edit-db/current-record-number value field-datatype on-return-code
        ]
    ]
    
    set 'get-field func [ ; get-field:
        [catch]
        db-field-name [ string! ] 
        /human
        /local lo-field-name
    ]
    [
        either(human) [
            lo-field-name: rejoin [ "hr-" db-field-name ]
        ][
            lo-field-name: rejoin [ "-" db-field-name ]
        ]

        if error? try [
            return (do compose [ get in ( to-word lo-field-name ) 'text ] )
            true ; make the try happy
        ][
            throw make error! rejoin [ {Field "} db-field-name {" does NOT exist} ] 
        ]                    
    ]
    
    set 'last-date func [ /set sval [date!] ] [ ; last-date:
        either set [
            edit-db/last-date: sval
        ][
            edit-db/last-date
        ]
    ]
    set 'run-sql-cmd func [ ; run-sql-cmd:
        sql-stmnt
        /return-block
        /local a
    ][
        either return-block [
            a: edit-db/run-sql/debug/return-block sql-stmnt
        ][
            a: edit-db/run-sql/debug sql-stmnt
        ]
        return a
    ]
] ; End of db-rider-context


print-script-template: [
    Title:   (s-title)
    Date:    (s-date)
    Name:    (s-name)
    Author:  (s-author)
    File:    (s-filename)
    Version: 1.0
    Purpose: (s-purpose)
    for-report-type: (s-report-type)
]

normal-script-template: [
    Title:   (s-title)
    Date:    (s-date)
    Name:    (s-name)
    Author:  (s-author)
    File:    (s-filename)
    Version: 1.0
    Purpose: (s-purpose)
]


unit-testing: false
db-rider-crash: false
light-gray: 185.185.185
light-yellow: 255.255.204
raw-list-data: copy []

load-text-editor-info: func [ 
    db-obj 
    /local tec dat text-editor-name
]
[
    if (exists? tec: join db-obj/get-settings-path %text-editor.datr ) [
        db-obj/text-editor: first dat: load tec
        text-editor-name: second dat
        db-obj/text-editor-name: text-editor-name
        either (text-editor-name = "" ) [
            db-obj/text-editor-command-line: copy []
        ][
            db-obj/text-editor-command-line: load join db-obj/get-settings-path rejoin [ "editor-list/" text-editor-name ".datr" ] 
        ]
        return true
    ]
    return false
]

set-text-editor: func [ db-obj /local tec dat ] [
    load-text-editor-info db-obj
    request-text-editor db-obj         
]

use [ a b ] [ ; modify focus-action for the vstyles below
    a: find/tail second :focus [[hilight-all face]]
    b: to-string a 
    if not found? find b "face/focus-action" [ ; check if face/focus-action already installed
        insert find/tail second :focus [[hilight-all face]] bind [
        if all [in face 'focus-action block? face/focus-action face ][               
                do face/focus-action face
        ]                                                                      
        ] fourth second :focus ; (pick out a local word 'face in the func body)
    ]
]

vstyle: stylize [ ; style to support virtual field to always be seen when it is the active face
    vfield: field with [ focus-action: func [ fa ] [ see-face fa ] ]
]



menu-data: []
winxp-menu: layout-menu/style copy menu-data winxp-style: [
    menu style edge [
        size: 1x1 color: 178.180.191 effect: none]
        color white
        spacing 2x2 
        effect none
        item style font [name: "font-sans-serif" size: 14 colors: reduce [black black silver silver]]
        colors [none 187.183.199] 
        effects none
        edge [size: 1x1 colors: reduce [none 178.180.191] effects: []]
        action [print item/body/text]
]

menu-data: [
    mfile: item "File"
        menu [
            item "Database Connection" [
                new-conn: edit-db-connection/is-connected query-db 
                if new-conn <> [] [
                    query-db/connection-name: "query-db"
                    query-db/user: new-conn/user
                    query-db/pass: new-conn/pass
                    query-db/host: new-conn/host
                    query-db/table: new-conn/table
                    database-field/text: query-db/database: new-conn/database
                    show database-field
                    either query-db/init [
                        query-db/connection-changed?: true
                        if ( query-db/table = "" ) [
                            query-db/table: first first query-db/run-sql "show tables"
                        ]
                        display-query-results rejoin [ "select * FROM " query-db/table " WHERE ID > '0' LIMIT 15 " ]
                    ][
                        my-request rejoin [ 
                            "Unable to open the database connection with the following attributes:" newline
                            "connection-name = " mold query-db/connection-name newline
                            "host = " mold query-db/host newline
                            "user = " mold query-db/user newline
                            "password = " mold query-db/pass newline
                            "database = " mold query-db/database newline
                            "table = " mold query-db/table newline
                        ]
                    ]
                ]
            ]
            item "New" [
                do-request-file-open-new
            ]
            item "Open" [
                 do-request-file-open-new
            ]
            item "Import" [
                 do-requested-script/add-button reduce [ query-db/get-import-path query-db/get-common-import-path query-db/get-global-import-path ] "Pick an import action" [ 
                    "New Script" [ show-folder/new "import" ] 
                    "Edit Script" [ show-folder "import" ]
                 ]
            ]
            item "Export" [
                do-requested-script/add-button reduce [ query-db/get-export-path query-db/get-common-export-path query-db/get-global-export-path ] "Pick an export action" [ 
                    "New Script" [ show-folder/new "export" ] 
                    "Edit Script" [ show-folder "export" ]
                 ]
            ]
            item "Print" [ 
                print-sheet
            ]
            item "Halt" [ halt ]
            item  "Exit" [ quit ]
         ]
    medit: item "Edit"
        menu [
            mactions: item "Field Actions" [
                fa: to-file query-db/get-field-actions-filename
                    if not exists? fa [
                        the-path: first split-path fa
                        if not exists? the-path [
                            make-dir/deep the-path
                        ]
                        write fa query-db/create-field-actions-initial-code query-db query-db/table                        
                    ]
                    edit-db/edit-text-file fa
            ]
            item "Listing Layout" [
                query-db/edit-text-file query-db/get-listing-layout-filename
            ]      
            mfolder-import: item "Import"
                menu [
                    item "For This Table" [ show-folder "import" ]
                    item "For All Tables" [ show-folder "common-import" ]
                    item "Globally"       [ show-folder "global-import" ]
                ]
            mfolder-import: item "Export"
                menu [
                    item "For This Table" [ show-folder "export" ]
                    item "For All Tables" [ show-folder "common-export" ]
                    item "Globally"       [ show-folder "global-export" ]
                ]    
            mgo-folder: item "Go"
                menu [
                    item "For This Database" [ show-folder "go" ]
                ]    
            mselect-folder: item "Select"
                menu [
                    item "For This Table" [ show-folder "select" ]
                    item "Globally" [ show-folder "global-select" ]
                ]    
            mreport-folder: item "Report"
                menu [
                    item "For This Table" [ show-folder "report" ]
                ]    
            mprint-folder: item "Print"
                menu [
                    item "For This Table" [ show-folder "print" ]
                ] 
            item "User Scripts" [ 
                the-request-list: first (make-script-list reduce [ query-db/get-user-scripts-path ])
                if not (request-result: request-script-name/prompt "user-scripts" the-request-list edit-db screen-offset? face "Pick a user script to edit") [
                    return
                ]
                query-db/edit-text-file join query-db/get-user-scripts-path request-result
                
            ]                
            item "Test Scripts" [ show-folder "test" ]                        
            item "Global Scripts" [ show-folder "global" ]
            
            mrelationships: item "Relationships"
                menu [
                    item "Plain Text Edit" [
                            query-db/related-field-list: copy  [] ; force the list to update once editing is done
                            relationships-file: join (clean-path query-db/overlay-path) rejoin [ query-db/database  "/relationships.r" ]
                            query-db/edit-text-file relationships-file
                    ]
                    item "GUI Editor" [
                        run-relationship-editor 
                    ]
                ] 
            mfunction-key: item "Function Keys"
                menu [
                    item "For Query Window"[
                        show-folder "global-function-key"
                    ]
                    item "For Edit Window"[
                        show-folder "function-key"
                    ]
                ]
        ]
    mreload: item "Refresh"
        menu [
             item "Layout"
                menu [
                    item "Refresh Layout" [
                        update-main-listing/refresh query-db/run-sql query-field/text
                    ]   
                    item "Reset To Default" [
                        query-db/related-field-list: copy [] ; force reload of relationship file
                        update-main-listing/default query-db/run-sql query-field/text
                        update-main-listing/refresh query-db/run-sql query-field/text
                    ]
                ]
            item "Relationship Actions" [
                query-db/update-relationship-assist-actions/reload
            ]
            item "Datatype Actions" [
                query-db/update-datatype-assist-actions/reload
            ]
            item "Global Scripts" [
                do-all-global-scripts
            ]
            item "User Scripts" [
                do-all-scripts-in-folder query-db/get-user-scripts-path query-db/root-path
            ]
            mflush-cache: item "Flush request-db-list cache" [
                request-db-list/flush "" ""                
                user-msg/query "request-db-list cache cleared."
            ]
        ]
    msettings: item "Settings"
        menu [
            mtext-editor: item "Text Editor" [
                set-text-editor query-db
            ]
            mtext-records: item "Records to Display" [
                if (res: request-text/title/default "Enter the # of records to display. Blank = NO LIMIT" to-string query-db/records-to-display )[
                    query-db/records-to-display: res
                    query-db/connection-changed?: true
                ]
                
            ]
            mcapture-errors: item "Capture Errors" check on [ 
                either capture-errors [
                    capture-errors: false
                    user-msg/query "capture errors is OFF"
                ][
                    capture-errors: true
                    user-msg/query "capture errors is ON"
                ]
            ]
        ]
        
    mhelp: item "Help"
        menu [
            item "About" [
                my-request rejoin [ 
                    "DB-Rider Version 0.7.0" newline 
                    "BSD 3-Clause License" newline
                    "Copyright (c) 2017, Mike Yaunish" newline
                    newline
                    "MySQL Version = " first query-db/run-sql "select version()" newline
                    "MySQL    User = " first query-db/run-sql "select user()" newline
                    newline
                    "DB-Rider Folder:" query-db/root-path
                ] 
            ]
        ]
]

my-styles: patched/styles

; THESE FUNCTIONS BELOW ARE EXPOSED TO  the 'field-actions' context
show-folder: func [ 
        folder-name 
        /new 
        /using db-obj
        /local rf valid-folder-list file-extension text-script
    ] [
    either(using) [
        the-db: db-obj
    ][
        the-db: query-db
    ]
    
    either (found? find the-db/internal-folders folder-name) [
        folder-path: get in the-db ( to-lit-word rejoin [ "get-" folder-name "-path" ] )

    ][
        return ; not an internal-folder
    ]
    if ( not exists? folder-path ) [ make-dir/deep folder-path ]
    either new [ 
        if (folder-name = "report") [
            do-safe [ create-report-from-current-query ] "create-report-from-current-query function"
            return
        ]            
        either (folder-name = "print" ) [
            if ( not print-script-details: request-print-script the-db/get-print-path) [ return ]
            rf: print-script-details/1
            s-report-type: print-script-details/2
        ][
            rf: request-text/title rejoin [ "Enter name of NEW '"folder-name "' script." ]
        ]
        if rf [
            s-title: copy set-extension/exclude rf
            s-date: now/date
            s-name: set-extension/with rf ".r"
            s-author: copy system/user/name
            s-filename: to-file set-extension/with rf ".r"
            s-purpose: rejoin [ "DB-Rider " folder-name " script. For database:" the-db/database " and table:" the-db/table ]
            switch/default folder-name [
                "print" [
                    the-script: compose print-script-template 
                ]
            ]
            [ ;switch default
                the-script: compose normal-script-template
            ]
            text-script: rejoin [ "REBOL " mold the-script ]
            switch folder-name [
                "print" [
                    append text-script rejoin [ newline "print-sheet" ]
                ]
                "go" [
                    append text-script rejoin [ newline "display-query-results {" query-field/text "}" ]
                ]
                "select" [
                    print-code: copy ""
                    the-field-details: query-db/get-field-details
                    foreach i the-field-details [
                        append print-code rejoin [ {^- print rejoin [ "} pad/with i/1 20 #" " {  = " get-field "} i/1 {" ]} newline ]
                    ]
                    append print-code {^- print "-------------------------------------------------"}
                    append text-script rejoin [
                        newline 
;*****************************************************
;***** START SELECT SCRIPT // Static String Formatting                         
{ 
num-of-records-selected: do-to-selected/how-many [
}
print-code
{    
    modify-record [
        comment "insert code here to modify each record"
        comment "use the get-field and set-field functions"
    ]
]
}
;***** END SELECT SCRIPT // Static String Formatting                         
;*****************************************************
                    ]
                    append text-script {print [ "Select script has worked with:" num-of-records-selected "records" ]}
                ]
            ]
            rf: join  folder-path ( to-file s-name )
            write rf text-script
        ]
    ][
        file-extension: "*.r"
        if any [ (folder-name = "report" ) (folder-name = "global-report" ) ] [
            file-extension: "*.*"
        ]
        rf: request-file/file/filter/keep/title/only folder-path file-extension  "Select File to Open" "Open"
        if ( rf = "") [ rf: none ]
    ]
    if rf [
        the-db/edit-text-file rf
    ]
]  

request-script-name: func  [ 
    script-category [ string! ] 
    request-list [ block! ] 
    the-db-obj [ object! ] 
    offset-position [ pair! ]
    /size list-size [ pair! ]
    /prompt prompt-string [ string! ] 
    /local request-result
]
[
    offset-position: offset-position - 0x80    
    if not size [ list-size: 300x200 ]
    if not prompt [ prompt-string: rejoin [ "Choose a '" script-category "' script"]  ]
    request-result: request-list-enhanced/offset/list-size/one-click/buttons prompt-string request-list offset-position list-size [ [ "New Script" "new-script" "F5" ] [ "Edit Script" "edit-script" "F6" ] ]
    case  [
        request-result = "new-script" [
            show-folder/new/using script-category the-db-obj
            return none
        ]
        request-result = "edit-script" [
            show-folder/using script-category the-db-obj
            return none
        ]
        request-result = none [
            return none
        ]
    ]        
    return request-result
]
     

edit-a-file: func [ edit-type [string!] /local ans relationships-file x fa the-path ] [
    case [
        edit-type = "relationship-text" [
            query-db/related-field-list: copy  [] ; force the related-field-list to update
            relationships-file: join (clean-path query-db/overlay-path) rejoin [ query-db/database  "/relationships.r" ]
            query-db/edit-text-file relationships-file
        ]
        edit-type = "relationship-gui" [
            run-relationship-editor
        ]
        edit-type = "layout" [
            query-db/edit-text-file query-db/get-listing-layout-filename                                                       
        ]
        edit-type = "actions" [
            fa: to-file edit-db/get-field-actions-filename
            if (not exists? fa) [
                the-path: first split-path fa
                if not exists? the-path [
                    make-dir/deep the-path
                ]
                write fa query-db/create-field-actions-initial-code query-db query-db/table                
            ]
            edit-db/edit-text-file fa
        ]        
    ] 
]

make-script-list: func [ 
        the-path [ block! file! ] 
        { creates list of scripts in a path or block of paths
          and will create the target directory if it doesn't already exist
        }
        /exclude-extension
        /with string-extension [ string! ] 
        /local script-list blk full-path-list file-list file-name
]
[   
    script-list: copy []
    full-path-list: copy []
    file-list: copy []
    if not with [
        string-extension: ".r" 
    ]
    if ((type? the-path) = file!) [
        blk: copy []
        insert blk the-path
        the-path: copy blk
    ]
    foreach a-path the-path [
        if ( not exists? a-path ) [ make-dir/deep a-path ]    
        file-list: read a-path
        foreach file-name file-list [ 
            if ( (find/last file-name string-extension) = to-file string-extension ) [
                insert full-path-list join a-path file-name
                if exclude-extension [
                    file-name: to-string (set-extension/exclude file-name)  
                ]
                insert full-path-list file-name
                insert script-list file-name
            ]
        ]            
    ]
    sort script-list
    return reduce [ script-list full-path-list ]
]

make-row-template: func [ /local fd res-blk small-size big-size total-size gad-size related x ] [           
    fd: query-db/get-field-details        
    res-blk: copy [ 
        (to-set-word rejoin [ "record-selected-" ID ]) check 20x20
        button 65x20  to-string ( ID )[ edit-mysql-record/new-window query-db (ID) ]
    ]
    small-size: 75x20
    big-size: 200x20

    total-size: 100x20
    foreach i fd [
        if (i/1 <> "ID") [
            either any [ ( found? find i/2 "varchar" ) ( found? find i/2 "blob" ) ][
                gad-size: big-size       
            ][
                gad-size: small-size       
            ]
            related: query-db/get-related-table-for query-db/table i/1
            either ( related = none ) [
                x: compose/deep [ label no-wrap white blue  (gad-size) to-string ( to-paren to-word i/1 ) ]
            ][
                x: compose/deep [ label no-wrap white blue no-wrap (gad-size) to-string ( to-paren to-word i/1 ) ]       
            ]                
            append res-blk x
        ]                
    ]
    return res-blk
]        

load-last-print-field: func [ /local lpf lpd fnd-at ] 
[
    either (exists?  lpf: join query-db/get-last-print-path %last-print.datr) [
        lpd: load lpf
        fnd-at: false
        either ( fnd-at: find-in-array-at lpd 2 report-field/text ) [
            print-field/text: fnd-at/print
            
        ][
            print-field/text: ""
        ]
    ][
        print-field/text: ""
    ]
    show print-field
]

load-new-environment: func [ /local lsd lgd lts ]
[
    report-field/text: ""
    print-field/text: ""
    select-field/text: ""
    if (exists?  join query-db/get-last-report-path %last-report.datr ) [
        report-field/text: load join query-db/get-last-report-path %last-report.datr    
    ]
    load-last-print-field
    either (exists? lsd: join query-db/get-last-select-path %last-select.datr) [
        select-field/text: load lsd
    ][
        make-dir/deep query-db/get-select-path
        save (join query-db/get-last-select-path %last-select.datr) select-field/text
    ]
    either (exists? lgd: join query-db/get-last-go-path %last-go.datr) [
        go-field/text: load lgd
    ][
        go-field/text: ""
    ]
    either (exists? lts: join query-db/get-test-path %last-test-script.datr) [
        test-field/text: load lts
    ][
        test-field/text: ""
    ]
    if ( exists? query-db/get-user-scripts-path ) [
        do-all-scripts-in-folder query-db/get-user-scripts-path query-db/root-path
    ]
    show test-field
    show go-field       
    show report-field           
    show select-field
    show print-field
]

get-query-value: func [ 
    value-field-name
    /offset the-offset 
    /both 
    /local fd rval ret related the-qry a rd field-type
]
[
    if not offset [
        the-offset: 50x50
    ]
    fd: query-db/get-field-details
    ret: copy ""
    foreach i fd [
        if i/1 = value-field-name [
            ret: copy i
            break       
        ]        
    ]      
    related: query-db/get-related-table-for query-db/table value-field-name
    either related <> none [
        the-qry: rejoin [ "select " related/3 "," related/2 " from " related/1 " ORDER by " related/3 " ASC " ]
        either ((a: request-db-list/cache/offset/return-human-readable/one-click/no-new/size the-qry "Select a Value" the-offset 300x300 ) <> none) [ 
              either both [
                return a       
              ][
                return first first a           
              ]             
              
            ][ 
                return none 
            ]
    ][
        field-type: first parse ret/2 "("
        switch field-type [
            "date" [ 
                rval: copy [] 
                either ( rd: request-date/yyyy-mm-dd/offset the-offset )[
                    append/only rval reduce [ to-mysql-date rd ] 
                ][
                    return none
                ]
                append rval ""
                return rval
            ]
            "set" [
                if (rd: request-set-for-field/offset query-db/table value-field-name the-offset ) [
                    return reduce [ to-block rd "" ]
                ]
            ]
            "enum" [
                if (rd: request-enum-for-field/offset query-db/table value-field-name the-offset) [
                    return reduce [ to-block rd "" ]
                ]
            ]
        ]
        
    ]
    return none                
]                        
query-context: context [
    query-history-list: copy []
    the-db-dir: copy "" 
    old-query-field-text: copy ""
    the-db-query: copy ""
    last-db-queried: copy ""
    update-mysql-query-history-fields: func [qstr] [
        update-query-field
        update-query-history qstr
        if ( not exists? query-db/get-query-path ) [ make-dir/deep query-db/get-query-path ]
        save (join query-db/get-query-path %last-query.datr) qstr
    ]
    rollo-it: func [ dataset target-field /local next-pos ] [
        either found? fnd: find dataset target-field/text [
            either ( (index? fnd) = ( length? dataset) ) [
                next-pos: 1
            ][
                next-pos: (index? fnd) + 1
            ]
        ][
            next-pos: 1
        ]
        target-field/text: copy pick dataset next-pos
        show target-field
    ]
    is-database?: func [ the-dir ] [
        exists? join ( to-file the-dir)  "indexed-columns"
    ]
    show-new-face: func [ new-face-info ] [
        new-face: copy new-face-info
        f-im: scroll-face/arrows layout/offset
        0x0 v-layout-size
        v-layout/pane: f-im
        show v-layout
    ]
    clear-all-query-fields: does [
        
        go-field/text: copy ""
        field-name1/text: copy "" operand-field1/text: copy "" value-field1/text: copy "" and-or1/text: copy ""
        field-name2/text: copy "" operand-field2/text: copy "" value-field2/text: copy ""  and-or2/text: copy ""
        field-name3/text: copy "" operand-field3/text: copy "" value-field3/text: copy ""   
        order-by-field/text:  copy ""  limit-field/text:  copy "" select-field/text: copy ""
    ]        
    show-all-query-fields: does [
        show [ go-field field-name1 operand-field1 value-field1 and-or1 ]
        show [ field-name2 operand-field2 value-field2 and-or2 ]
        show [ field-name3 operand-field3 value-field3 order-by-field limit-field select-field ]
    ]        
    update-mysql-query-layout-fields: func [ 
            the-query 
            /local   lmt-val fnd-limit full-query postfix a x and-or-pos and-or-name
    ][
        either (found? fnd-limit: find the-query "LIMIT")[
                lmt-val: second parse fnd-limit none
                limit-field/text: lmt-val
                the-query: copy/part the-query ((index? fnd-limit) - 2) 
        ][
            limit-field/text: ""
        ]
        if (found? fnd-at: find the-query "ORDER BY") [ ; Strip out 'postfix' type stuff
            full-query: copy the-query
            the-query: copy/part the-query ((index? fnd-at) - 2) 
            postfix: parse fnd-at none
            order-by-field/text: postfix/3
            order-by-direction/state: case [
                (last postfix) = "ASC" [ true ]
                (last postfix) = "DESC" [ false ]
            ]
        ]
        table-field/text: trim first delim-extract the-query  "FROM" "WHERE" 
        show table-field        
        query-db/table: copy table-field/text ; update the database connection 
        field-name1/text: copy "" operand-field1/text: copy "" value-field1/text: copy "" and-or1/text: copy ""
        field-name2/text: copy "" operand-field2/text: copy "" value-field2/text: copy ""  and-or2/text: copy ""
        field-name3/text: copy "" operand-field3/text: copy "" value-field3/text: copy ""
        pack-quoted-values the-query ; makes sure the quoted values remain in one piece 
                                     ; until needed below at the-query/4 usage
        a: find the-query "WHERE"
        the-query: parse a none
        x: 1
        forskip the-query 4 [
            either (x < 4) [ ; only deal with first 3
                if the-query/1 <> "WHERE" [
                    and-or-pos: ( x - 1 )
                    and-or-name: to-set-path reduce [ to-word rejoin ["and-or" and-or-pos] to-word "text"  ]
                    do reduce [ and-or-name the-query/1 ]                           
                ]
                field-name: to-set-path reduce [ to-word rejoin ["field-name" x] to-word "text"  ]
                do reduce [ field-name the-query/2 ]
                op-field: to-set-path reduce [ to-word rejoin ["operand-field" x] to-word "text"  ]
                do reduce [ op-field the-query/3 ]
                v-field: to-set-path reduce [ to-word rejoin ["value-field" x] to-word "text"  ]
                if (the-query/4 <> none) [
                    unquoted: trim/with (unpack-quoted-value the-query/4) {"'"}
                    if (unquoted = "") [
                        unquoted: copy "''"
                    ]
                    do reduce [ v-field unquoted ]
                ]
                if the-query/1 = "WHERE" [ andor-field: "" ]
                ++ x
            ][
                user-msg/query "Not all query fields where able to be displayed on the graphical interface." 
            ]
        ]
        update-compare-text 1 query-db/table field-name1/text value-field1/text
        update-compare-text 2 query-db/table field-name2/text value-field2/text
        update-compare-text 3 query-db/table field-name2/text value-field3/text
        show [ field-name1 operand-field1 value-field1 and-or1 ]
        show [ field-name2 operand-field2 value-field2 and-or2 ]
        show [ field-name3 operand-field3 value-field3 ]
        show [ order-by-field order-by-direction limit-field ]
    ]
    update-display-with-query: func [qry results-block /no-view ] [ 
        either ( no-view ) [
            update-main-listing/no-view results-block           
        ][
            update-main-listing results-block           
        ]
        update-record-count (length? results-block)
    ]
    select-panel: layout/offset [
        across
        space 1x0
        origin 0x0
        tog: check 24x24  [
            either tog/data = true [
                main-list/set-checks/set-all        
            ][
                main-list/set-checks/set-all/off
            ]               
        ]
        box 6x24 175.175.175
        label white gray 86x24 "Select Action:" select-field: field 200x24
        select-field-button: button 24x24 drop-down-img [
            the-request-list: first make-script-list/exclude-extension reduce [ query-db/get-global-select-path query-db/get-select-path ]
            if not (request-result: request-script-name "select" the-request-list query-db screen-offset? face ) [
                return
            ]            
            select-field/text: request-result
            show select-field
            save (join query-db/get-last-select-path %last-select.datr) select-field/text
        ] 
        space 4x4        
        select-run: button "Run" 40x24 light-gray [
            save (join query-db/get-last-select-path %last-select.datr) select-field/text
            if (not exists? script-to-run: (join query-db/get-select-path rejoin [ select-field/text ".r" ] ))[
                if ( not exists? script-to-run: (join query-db/get-global-select-path rejoin [ select-field/text ".r" ]))[
                    my-request rejoin [ "Script named:'" select-field/text "' does not exist." ]
                    return 
                ]  
            ]
            do-safe script-to-run rejoin [ "Select script named '" last split-path script-to-run "'" ]
            tog/data: false
            show tog
        ]
    ] 1x6 
    query-panel: layout/offset [
        do 
        [ 
            field-name-size: 150x24
            operand-size: 100x24
            value-size: 200x24
            and-or-size: 100x24
            ctext-size: 200x24
            assist-size: 75x24
            execute-prestring: ""
            get-operand-list: does [ return [ "=" ">" "<" "<=" "<>" ">=" ] ]
        ] 
        origin 8x8
        across
        space 0x0
        label right white light-gray 200x24 "Database :"
        database-field: field "" white ( field-name-size - 24x0) [ 
            update-query-field 
        ]
        space 4x4
        database-field-button: button 24x24 drop-down-img [
            current-database: copy query-db/database
            db-list: query-db/run-sql  "show databases"
            the-request-list: copy []
            foreach db-name db-list [ insert the-request-list db-name ]
            sort the-request-list
            request-result: request-list-enhanced/offset/one-click "Select a database" the-request-list screen-offset? face
            if all [ (request-result <> current-database) ] [
                if request-result <> none [
                    database-field/text: request-result
                    show database-field
                    table-field/text: ""
                    show table-field
                    clear-all-query-fields
                    show-all-query-fields
                    update-main-listing/clear-listing []
                    if request-result <> current-database [
                        query-db/database: copy request-result
                        table-list: query-db/run-sql "show tables"
                        query-db/table: copy table-list/1/1
                        query-db/connection-changed?: true
                        init-res: query-db/init ; new database has been selected - initialize it.        
                        
                        query-db/listing-layout: copy [] ; force the reload of listing layout
                        either init-res = false [
                            database-field/text: copy query-db/database
                            show database-field    
                            display-query-results ""    
                        ][
                            display-query-results ""    
                        ]
                    ]       
                ]
                update-query-field 
            ]
        ] 
        space 0x0
        label right white light-gray 100x24 "Table :"
        table-field: field  "" white ( field-name-size - 24x0) [ update-query-field ]
        space 4x4
        table-field-button: button 24x24 drop-down-img [
            table-list: query-db/run-sql  rejoin [ "show tables from " database-field/text ]
            the-request-list: copy []
            foreach table-name table-list [ insert the-request-list table-name ]
            sort the-request-list
            if (request-result: request-list-enhanced/offset/one-click "Select a table" the-request-list screen-offset? face) [
                table-field/text: request-result
                show table-field
                query-db/database: (copy database-field/text)
                query-db/set-table-name (copy table-field/text)
                clear-all-query-fields
                show-all-query-fields
                query-db/update-relationship-assist-actions 
                edit-db/update-relationship-assist-actions
                update-query-field 
                query-db/connection-changed?: true
                either query-db/records-to-display = "" [
                    display-query-results rejoin [ "select * FROM " table-field/text " WHERE ID > '0' "]
                ][
                    display-query-results rejoin [ "select * FROM " table-field/text " WHERE ID > '0' LIMIT " query-db/records-to-display ]    
                ]
                
            ]
        ] 
        label right white light-gray 158x24
        space 4x4
        return
        label center white gray field-name-size "FIELD NAME"
        label center white gray operand-size "OPERAND"
        label center white gray value-size "COMPARE VALUE"
        label center white gray and-or-size "AND/OR" 
        label center white gray ctext-size "HUMAN READABLE VALUE" return
        across
        space 0x0
        field-name1: field  white ( field-name-size - 24x0) [ update-query-field ] with [ user-data: [ f4-button [ b1-1/action face "" ] ] ]
        space 4x4
        b1-1: button 24x24 drop-down-img [
            request-result: request-list-enhanced/offset/one-click "Select a field" get-field-list screen-offset? face
            if request-result <> none [
                field-name1/text: request-result
                show field-name1
                update-query-field
            ]
            focus field-name1
        ]
        space 0x0
        operand-field1: field center ( operand-size - 24x0 ) [ update-query-field ] with [ user-data: [ f4-button [ b2-1/action face "" ] ] ]
        space 4x4
        b2-1: button 24x24 drop-down-img [
            request-result: request-list-enhanced/offset/one-click "Select an operand" get-operand-list screen-offset? face
            if request-result <> none [
                operand-field1/text: request-result
                show operand-field1
                update-query-field
            ]
            focus operand-field1
        ]
        space 0x0
        ; Compare Value #1
        value-field1: field ( value-size - 24x0) [ 
            update-compare-text 1 query-db/table field-name1/text value-field1/text
            update-query-field 
        ] with [ 
            user-data: [ f4-button [ b3-1/action face "" ] ] 
        ]
        space 4x4
        ; compare value #1 requester button
        b3-1: button 24x24 drop-down-img [
            request-result: get-query-value/offset/both field-name1/text screen-offset? face
            if request-result <> none [
                either((first request-result) = [] ) [
                    value-field1/text: ""
                ][
                    value-field1/text: first first request-result
                ]
                info1/text: request-result/2
                show value-field1
                show info1
                update-query-field
            ]
            focus value-field1
        ]
        space 0x0
        and-or1: field ( and-or-size - 24x0 ) [ update-query-field ] with [ user-data: [ f4-button [ b4-1/action face "" ] ] ]
        space 4x4
        b4-1: button 24x24 drop-down-img [ rollo-it [ "AND" "OR" "" ] and-or1  update-query-field ]
        info1: info 220.220.220
        return
        space 0x0
        field-name2: field  white ( field-name-size - 24x0) [ update-query-field ] with [ user-data: [ f4-button [ b1-2/action face "" ] ] ]
        space 4x4
        b1-2: button 24x24 drop-down-img [
            request-result: request-list-enhanced/offset/one-click "Select a field" get-field-list screen-offset? face
            if request-result <> none [
                field-name2/text: request-result
                show field-name2
                update-query-field
            ]
            focus field-name2
        ]
        space 0x0
        operand-field2: field center ( operand-size - 24x0 ) [ update-query-field ] with [ user-data: [ f4-button [ b2-2/action face "" ] ] ]
        space 4x4
        b2-2: button 24x24 drop-down-img [
            request-result: request-list-enhanced/offset/one-click "Select an operand" get-operand-list screen-offset? face
            if request-result <> none [
                operand-field2/text: request-result
                show operand-field2
                update-query-field
            ]
            focus operand-field2
        ]
        space 0x0
        value-field2: field ( value-size - 24x0) [ 
            update-compare-text 2 query-db/table field-name2/text value-field2/text
            update-query-field 
        ] with [ user-data: [ f4-button [ b3-2/action face "" ] ] ]
        space 4x4
        b3-2: button 24x24 drop-down-img [
            request-result: get-query-value/offset/both field-name2/text screen-offset? face
            if request-result <> none [
                either((first request-result) = [] ) [
                    value-field2/text: ""
                ][
                    value-field2/text: first first request-result
                ]
                info2/text: request-result/2
                show value-field2
                show info2
                update-query-field
            ]
            focus value-field2
        ]
        space 0x0
        and-or2: field ( and-or-size - 24x0 ) [ update-query-field ] with [ user-data: [ f4-button [ b4-2/action face "" ] ] ]
        space 4x4
        b4-2: button 24x24 drop-down-img [ rollo-it [ "AND" "OR" "" ] and-or2  update-query-field ]
        info2: info 220.220.220
        return
        space 0x0
        field-name3: field  white ( field-name-size - 24x0) [ update-query-field ] with [ user-data: [ f4-button [ b1-3/action face "" ] ] ]
        space 4x4
        b1-3: button 24x24 drop-down-img [
            request-result: request-list-enhanced/offset/one-click "Select a field" get-field-list screen-offset? face
            if request-result <> none [
                field-name3/text: request-result
                show field-name3
                update-query-field
            ]
            focus field-name3
        ]
        space 0x0
        operand-field3: field center ( operand-size - 24x0 ) [ update-query-field ] with [ user-data: [ f4-button [ b2-3/action face "" ] ] ]
        space 4x4
        b2-3: button 24x24 drop-down-img [
            request-result: request-list-enhanced/offset/one-click "Select an operand" get-operand-list screen-offset? face
            if request-result <> none [
                operand-field3/text: request-result
                show operand-field3
                update-query-field
            ]
            focus operand-field3
        ]
        space 0x0
        value-field3: field ( value-size - 24x0) [ 
            update-compare-text 3 query-db/table field-name3/text value-field3/text
            update-query-field 
        ] with [ user-data: [ f4-button [ b3-3/action face "" ] ] ]
        space 108x4
        b3-3: button 24x24 drop-down-img [
            request-result: get-query-value/offset/both field-name3/text screen-offset? face
            if request-result <> none [
                either((first request-result) = [] ) [
                    value-field3/text: ""
                ][
                    value-field3/text: first first request-result
                ]
                info3/text: request-result/2
                show value-field3
                show info3
                update-query-field
            ]
            focus value-field3
        ]
        space 0x12
        info3: info 220.220.220
        return
        space 0x0
        label white gray 69x24  "ORDER BY:" order-by-field: field 120x24 
        space 4x2
        order-by-field-button: button 24x24 drop-down-img [
            request-result: request-list-enhanced/offset/one-click "Select a field" get-field-list screen-offset? face
            if request-result <> none [
                order-by-field/text: request-result
                show order-by-field
                update-query-field
            ]
            focus limit-field
        ]
        space 4x2
        order-by-direction: toggle light-gray "Descending"  "Ascending" [
            update-query-field
        ]
        space 0x0
        label white gray 40x24 "LIMIT:" space 2x4 limit-field: field 120x24 [ 
            update-query-field 
            focus field-name1
        ]
        button light-gray "clear limit" [ limit-field/text: copy "" show limit-field update-query-field ]
        return
        space 0x0       
        label white gray 45x24 "Query:" 
        query-field: info 220.220.220 582x24 [ 
            either query-field/text = old-query-field-text [
                display-query-results query-field/text 
            ][
                clear-all-query-fields
                show-all-query-fields
                old-query-field-text: copy query-field/text
                display-query-results query-field/text 
            ]
        ] space 8x0
        query-history-button: button 30x23 light-gray "..." [
            qlist: find-in-array-at/all query-history-list 1 query-db/database
            query-list: copy []
            foreach i qlist [
                append query-list second i 
            ]
            request-query: request-list-enhanced/offset/list-size/one-click "Select a Query" query-list 50x50 800x200       
            if request-query [
                clear-all-query-fields
                show-all-query-fields
                update-mysql-query-layout-fields request-query
                update-query-field
            ]
        ]        
        space 0x0
        execute-button: button 150.170.150 "Execute (F5)" keycode 'f5 [ 
            display-query-results query-field/text
        ]
        return
    ] 5x5

    query-layout: layout [
        styles my-styles
        
        do [ 
            update-query-history: func [ str ] [
                insert/only head query-history-list reduce [ query-db/database str ]
            ]
            update-query-field: func [ /local old-query-field-text ] [
                old-query-field-text:  copy to-string query-field/text
                query-field/text: build-mysql-query-string-from-gui-fields
                show query-field
            ]
            update-compare-text: func [ 
                info-button-num table-name field-name field-id 
                /local show-val info-button-name
            ][
                
                if ( field-name = none ) [
                    return ; bad data supplied to this function
                ]
                field-id: to-string field-id
                show-val: to-human/table-and-id field-name reduce [ table-name field-id ]    
                info-button-name: rejoin ["info" info-button-num ]
                if ( show-val = field-id ) [
                    show-val: ""    
                ]
                do reduce [ to-set-path reduce [ to-word info-button-name  to-word "text" ] show-val  ]
                show get to-word info-button-name    
            ]
            extract-query-row: func [ row-num 
                /local the-field-name the-operand value-field compare-value
            ]
            [
                the-field-name: get to-lit-word rejoin [ "field-name" row-num ] 
                the-operand:    get to-lit-word rejoin [ "operand-field" row-num ] 
                value-field:    get to-lit-word rejoin [ "value-field" row-num ] 
                either all [ ( the-field-name/text <> "" ) ( the-operand/text <> "" ) ] [ ; Then first line is good
                    either any [ (value-field/text = " ") (value-field/text = "") (value-field/text = "''")  ]  [
                        value-field/text: copy "''"
                        show value-field
                        compare-value: ""
                    ][
                        compare-value: value-field/text 
                    ]
                    return rejoin [ the-field-name/text " " the-operand/text { '} compare-value {' } ]
                ][
                    return false
                ]
            ]    
            build-mysql-query-string-from-gui-fields: func [ 
                /no-errors 
                /local q-string q-string-postfix row1 row2 row3
            ]  
            [
                q-string-postfix: copy ""
                if ( order-by-field/text <> "" ) [
                    append q-string-postfix rejoin [ "ORDER BY " order-by-field/text either order-by-direction/state [ " ASC" ] [ " DESC" ]  ]  
                ]
                if ( limit-field/text <> "" ) [
                    append q-string-postfix rejoin [ " LIMIT " limit-field/text ]
                ]
                q-string: rejoin [ "SELECT * FROM " table-field/text " WHERE " ]
                
                if ( row1: extract-query-row 1 )[
                    append q-string  row1
                    if all [ ( and-or1/text <> "" ) ( row2: extract-query-row 2 ) ] [
                        append q-string rejoin [ and-or1/text " "  row2 ]
                        if all [ ( and-or2/text <> "" )  ( row3: extract-query-row 3 ) ] [
                            append q-string rejoin [ and-or2/text " " row3 ] 
                        ]
                    ]
                ]
                return rejoin [ q-string q-string-postfix ]
            ]
            get-field-list: func [ /local fd i ret ] [
                fd: query-db/get-field-details
                ret: copy []
                foreach i fd [ append ret first i ] 
                return sort ret
            ]
            main-list-original-size: 892x350
            main-list-data: copy []
        ] ; ************* END of layout 'do'*********************
        across 
        at 0x0 app-menu: menu-bar menu menu-data menu-style winxp-style 
        return
        space 0x0
        label white gray 105x24 right  "GO DIRECTLY TO:" go-field: field 200x23 snow
        go-field-button: button 23x23 drop-down-img {} [ 
            do-requested-script/pre-do/add-button/offset query-db/get-go-path "Pick a GO action" [
                clear-all-query-fields
                show-all-query-fields 
                go-field/text: request-result
                show go-field
                save (join query-db/get-last-go-path %last-go.datr) go-field/text
                query-db/connection-changed?: true
            ] [ "New Script" [ show-folder/new "go" ] "Edit Script" [ show-folder "go" ] ] (screen-offset? face)
        ] 
        space 8x4        
        button "Run" 40x23  light-gray [
            if all [ (go-field/text <> "") (go-field/text <> "none" ) ] [
                save (join query-db/get-last-go-path %last-go.datr) go-field/text
                go-filename: rejoin [ go-field/text ".r" ]
                do-safe join query-db/get-go-path go-filename rejoin [ "Go script named '" go-filename "'" ]
            ]
        ]
        return
        qpanel: box 793x227 effect [
            draw [
                pen snow
                fill-pen 175.175.175
                box
            ]
        ]
        return 
        at 20x299
        space 10x0
        spanel: box 390x35 175.175.175
        button "Add Record" 100x35 light-gray [
            if (new-row: query-db/create-new-record query-db/table) [
                edit-mysql-record/new-window query-db new-row
            ]
        ]
        space 0x0
        label white light-gray right 120x35 "records displayed:" 
        record-count:  label 35x35 white light-gray "000"
        button "refresh" 100x35 light-gray [
            refresh-query-listing 
        ]
        return
        box 26x4 175.175.175
        space 0x6
        return
        main-list: my-list main-list-original-size columns [
           check 25x25 [ 
                main-list/update-check face
            ]
        ]
        data main-list-data 
        rowbar ["X"]
        line-colors reduce [220.220.220 white]
        rowbar-height 32
        slider-width 20
        row-highlight
        return               
        space 0x0
        report-label: label white gray 58x23 "REPORT:" report-field: field 200x23
        report-field-button: button 23x23 drop-down-img [ 
            the-request-list: first ( make-script-list/exclude-extension reduce [ query-db/get-report-path ] )
            if not (request-result: request-script-name "report" the-request-list query-db screen-offset? face ) [
                return
            ]
            report-field/text: request-result
            show report-field
            save (join query-db/get-last-report-path %last-report.datr) report-field/text
            run-report-button
        ] 
        report-run-button: button "Run" 40x23 light-gray [
            run-report-button
        ]
        space 10x0
        report-rerun-button: button "ReRun" 50x23 light-gray  [
            
            if ( last-report-run: get-last-report-run-data/no-make ) [                 
                either (last-report-run/report-name = ( to-string rejoin [ report-field/text ".r" ]) ) [
                    rerun-report: load (join query-db/get-report-path last-report-run/report-foundation)
                    rerun-report/report-name: last-report-run/report-name 
                    rerun-report/setup: last-report-run/setup
                    run-report rerun-report last-report-run/arguments
                ][
                    my-request rejoin [ "Can't rerun report" newline "NO MATCH with last-report-run/report-name=" last-report-run/report-name newline "and report-field/text=" to-string report-field/text ]
                ]
            ]
        ]        
        space 0x0 print-label: label white gray 76x24 "Print Action:" print-field: field 200x24
        print-field-button: button 24x24 drop-down-img [ 
            run-data: get-last-report-run-data
            the-request-list: get-rebol-scripts-for-report-type query-db/get-print-path run-data/report-type
            
            if not (request-result: request-script-name "print" the-request-list query-db screen-offset? face ) [
                return
            ]            
            print-field/text: request-result
            show print-field 
            run-print-button
        ] 
        space 4x4        
        print-run-button: button "Run" 40x24 light-gray [
            run-print-button
        ]
        return 
        space 0x0
        user-msg-label: label white gray 65x24 "User Msg:" space 4x4 query-user-msg-field: field 830x24 return
        space 0x0 reb-cmd-label: label white gray 65x24 "REB CMD:"
        space 0x0
        reb-cmd-field: s-field 400x24 with [
            on-submit: func[ /local value] [
                do-reb-cmd
            ]
        ]
        space 6x0
        reb-cmd-button: button "Run" 40x24 light-gray [
            do-reb-cmd
        ]
        space 0x0
        test-scripts-label: label white gray right 42x24 "TEST:"
        test-field: field 150x24
        test-field-button: button 24x24 drop-down-img [
            the-request-list: first ( make-script-list/exclude-extension query-db/get-test-path  )
            if not (request-result: request-script-name/size "test" the-request-list query-db screen-offset? face 300x700) [
                return
            ]
            test-field/text: request-result
            save (join query-db/get-test-path %last-test-script.datr) test-field/text
            show test-field 
            run-test-script-button
        ]
        space 15x0 
        test-scripts-run-button: button  52x24 light-gray "Run-F9" [
            run-test-script-button
            change-dir query-db/root-path
        ] keycode 'F9
        space 3x0
        f2-button: button  30x24 light-gray "f2" [
            do-safe join query-db/get-global-function-key-path %f2.r "script named f2.r"
        ] keycode 'F2

        f3-button: button 30x24 light-gray "f3" [
            do-safe join query-db/get-global-function-key-path %f3.r "script named f3.r"
        ] keycode 'F3

        f6-button: button  30x24 light-gray "f6" [
            do-safe join query-db/get-global-function-key-path %f6.r "script named f6.r"
        ] keycode 'F6
        
        f7-button: button  0x0 light-gray "" [
            do-safe join query-db/get-global-function-key-path %f7.r "script named f7.r"
        ] keycode 'F7
        do [ 
            set 'do-reb-cmd  does [ ; do-reb-cmd:
                do-safe [ do reb-cmd-field/text ] "Running rebol command"
            ]
            set 'scroll-main-list func [ direction /local f ] [ 
                f: main-list
                if f/pane/3 [
                    if (f/pane/3/var = 'scr-v) [
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
                ]
                show main-list
            ]     
            do-all-global-scripts
            set 'refresh-query-listing does [ ; refresh-query-listing:
                update-main-listing/refresh query-db/run-sql query-field/text
            ]
            set 'run-this-report func [ table-name report-name ] [ ; run-this-report:
                query-db/table: copy table-name
                report-field/text: report-name
                show report-field
                save (join query-db/get-last-report-path %last-report.datr) report-field/text
                run-report-button
            ]
            set 'user-msg func [ s /edit /query /no-flash ] [ ; user-msg:
                s: to-string s
                if query [
                    query-user-msg-field/text: copy s 
                    show query-user-msg-field   
                    if ( not no-flash ) [
                        query-db/flash-field query-user-msg-field
                    ]    
                ]
                if edit [
                    edit-user-msg-field/text: copy s 
                    show edit-user-msg-field           
                    if (not no-flash) [
                        query-db/flash-field edit-user-msg-field                        
                    ]
                ]
                
            ]
            run-test-script-button: func [ /local err the-error ] [ 
                do-safe (join query-db/get-test-path  rejoin [ test-field/text ".r" ] ) "Test script"
                change-dir query-db/root-path
            ]
            run-report-button: func [ /local script-to-run err the-error ] [
                main-list/sorted-by: 0
                save (join query-db/get-last-report-path %last-report.datr) report-field/text
                clear-all-query-fields
                show-all-query-fields 
                if (not exists? script-to-run: (join query-db/get-report-path rejoin [ report-field/text ".r" ]))[
                    my-request "Script named:" report-field/text ".r does not exist"
                    return 
                ]
                do script-to-run
                
                load-last-print-field
            ]
            run-print-button: func [ /local err the-error ]  [
                save-last-print-field 
                do-safe (join query-db/get-print-path  rejoin [ print-field/text ".r" ] ) "print script"
            ]
            save-last-print-field: func [ /local lpfile lpd fnd-at ndx ] 
            [
                if ((trim print-field/text) = "" ) [ return ]
                lpfile: join query-db/get-last-print-path %last-print.datr
                lpd: copy []
                either (exists? lpfile ) [
                    lpd: load lpfile
                    fnd-at: false
                    fnd-at: find-in-array-at/with-index lpd 2 report-field/text
                    either ( fnd-at ) [
                        ndx: fnd-at/2
                        replace-in-block lpd/:ndx print-field/text 4
                    ][
                        append/only lpd reduce [ 'report report-field/text 'print print-field/text ] 
                    ]
                ][
                    append/only lpd reduce [ 'report report-field/text 'print print-field/text ] 
                ]
                save lpfile lpd
            ]            
            qpanel/pane: query-panel 
            spanel/pane: select-panel
            last-mark: 00:00:00
            double-click-time: 0:00:00.30
            focus field-name1
            order-by-direction/state: true ; True = ASC False = DESC
            show order-by-direction 
        ]
        key keycode 'F4 [ 
            if system/view/focal-face [
                if all [ (found? find (first system/view/focal-face) 'user-data ) ( system/view/focal-face/user-data <> none ) ] [
                    if (found? find  system/view/focal-face/user-data 'f4-button ) [
                        if (system/view/focal-face/user-data/f4-button <> []) [
                            do system/view/focal-face/user-data/f4-button               
                        ]       
                    ]
                ]       
            ]
        ]
    ] 900x500
    ; ************ END of query-layout ******************

    make-new-listing-face: func [
        db-results row-template
        /local records-displayed the-layout field-list rec fieldname
    ]
    [
        records-displayed: copy []
        the-layout: copy [ backdrop brown space 4x4 across ]
        field-details: query-db/get-field-details
        len-dbr: length? db-results
        len-fd: length? field-details
        for i 1 len-dbr 1 [
            for j 1 len-fd 1 [
                var-name: to-set-word to-string field-details/:j/1
                do-safe reduce [ :var-name db-results/:i/:j ] "Setting a variable name"
            ]                   
            either (value? 'ID) [
                append records-displayed ID           
            ][                    
                append records-displayed 1 
            ]
            append the-layout compose/deep row-template
            append the-layout 'return
        ]        
        return reduce [ the-layout records-displayed ]
    ]
    set 'update-record-count func [ n ] [ ; update-record-count:
        record-count/text: n
        show record-count
    ]        
    validate-sql-cmd: func [ 
            scmd [string!] 
            /local next-word rules  p mark table-name where-field limit-size order-field sort-direction parse-results
    ][
        scmd: trim/lines scmd
        append scmd " " ; to allow 'order by' to work properly.
        next-word: func [ s ] [
            either (( length? p: parse s " " ) > 1) [
                return first p     
            ][
                return ""
            ]
        ]
        rules: [ 
            "SELECT" 
            "*"      
            "FROM " copy table-name thru #" " mark: ( 
                table-name: trim table-name
            )
            "WHERE " 
            
            copy where-field thru #" " mark: (
                where-field: trim where-field 
            )
            any [ [ ">" | "<" | "<>" | "<=" | ">="  | "=" ]
                copy discard thru #" " mark: ( 
                )
            ]
            any [ {'}
                copy discard thru {'}  mark:
                (
                )
            ]
            any [ {"}
                copy discard thru {"} mark:
                (
                )
            ]
            any [ 
                "ORDER BY " 
                copy order-field to #" "   
            ]
            any [
                copy sort-direction [ "ASC" | "DESC" ] 
                ( 
                )         
            ]
            any [
                "LIMIT " copy limit-size to end 
                (
                    limit-size: trim limit-size
                )               
            ]
            any [
                skip to end        
            ]
        ]
        table-name: where-field: order-field: sort-direction: limit-size:  none
        parse-results: parse scmd rules 
        return reduce [ 'table table-name 'where where-field 'order order-field 'direction sort-direction 'limit limit-size  ]
    ] 
    set 'display-query-results func [ ; display-query-results:    
        the-query /no-view /no-build-query-fields 
        /local row-template s-results my-gadgets main-list-size fd new-qry validated-sql main-list-diff
        new-face-info results-layout records-on-view
        ; GLOBAL last-db-queried  displayed-db-table 
    ] 
    [
        if (the-query = "" ) [
            either (exists? join query-db/get-query-path %last-query.datr) [
                the-query: load (join query-db/get-query-path %last-query.datr)
            ][  ; Assuming this is a very first run of a new database
                fd: query-db/get-field-details/for-all
                either fd = [] [
                    my-request rejoin [ "There are NOT any tables to open " newline "within this database." ]
                    return
                ][
                    query-db/update-datatype-assist-actions/reload 
                    query-db/table: to-string first fd
                    new-qry: rejoin [ {SELECT * FROM } first fd { WHERE ID > 0  limit 15 } ]
                    display-query-results new-qry
                    return            
                ]
            ]
        ]
        validated-sql: validate-sql-cmd the-query 
        if not find-in-array-at query-db/get-table-list 1 validated-sql/table [
            my-request rejoin [ {The table name:} mold validated-sql/table { is not a valid table name.} newline {Change the table name and try the query again.} ]
            return 
        ]
        if not find-in-array-at query-db/get-field-details/for-table validated-sql/table 1 validated-sql/where [
            either (validated-sql/where = "ID") [
                my-request rejoin [ {The table named:'} validated-sql/table  {' does not contain a field named: 'ID'} newline {DB-Rider requires all tables to contain a primary key field named:'ID'} ]
            ][
                my-request rejoin [ {The 'WHERE' field name:} mold validated-sql/where { does not exist.} newline {Change the field name and try the query again.} ]    
            ]
            return
        ]
        if validated-sql/order <> none [
            if not find-in-array-at query-db/get-field-details/for-table validated-sql/table 1 validated-sql/order [
                my-request rejoin [ {The 'ORDER' field name:} mold validated-sql/order { does not exist.} newline {Change the field name and try the query again.} ]
                return
            ]
        ]
        
        update-mysql-query-layout-fields the-query               
        row-template: copy make-row-template
        query-db/displayed-db-table: reduce [ query-db/database query-db/table ] ; keep track of which layout is used
        s-results: query-db/run-sql the-query
        new-face-info: make-new-listing-face s-results row-template
        results-layout: copy new-face-info/1
        records-on-view: copy new-face-info/2
        database-field/text: copy query-db/database
        update-mysql-query-history-fields the-query    
        either (last-db-queried = "") [
            last-db-queried: copy query-db/database
            update-main-listing s-results
            update-record-count (length? s-results)
            if ( not no-view ) [
                my-gadgets: make gadget-mover []
                my-gadgets/init query-layout [ 
                    print-label print-field print-field-button print-run-button 
                    user-msg-label query-user-msg-field
                    reb-cmd-label reb-cmd-field
                    f3-button f2-button f6-button
                    test-scripts-label test-field test-field-button test-scripts-run-button
                    report-label report-field report-field-button report-run-button report-rerun-button reb-cmd-button
                ]
                main-list-diff: query-layout/size - main-list-original-size
                view-resizable/offset query-layout 
                    [ ; this is the code-block that is run on resize
                        main-list-size: query-layout/size - main-list-diff
                        main-list/resize-list main-list-size
                        my-gadgets/show-moved-gadgets query-layout
                    ] 
                    to-pair reduce [ (query-layout/size/x + 8) 588 ] ; minimum window size ADD 8 to X because the value returned by query-layout is short 8 pixels
                    3x60       ; main window offset-value
                    "DB-Rider" 
            ]
        ][
            either ( no-view ) [
                update-display-with-query/no-view the-query s-results
            ][
                update-record-count (length? s-results)
                update-display-with-query the-query s-results
            ]            
        ]
        
    ] ; ***  END display-query-results func
]  ; *** End of query Context

to-computer: func [ table-name field-name field-value /local related the-qry r fr ] [
    related: query-db/get-related-table-for table-name field-name
    either related <> none [
        the-qry: rejoin [ "select " related/2  " from " related/1 " WHERE " related/3 " = '" field-value "'" ]       
        r: query-db/run-sql the-qry
        if r = [] [ return none ]
        fr: first r
        either (fr = [])  [
            return none
        ][
            return first fr                   
        ]                
    ][
       return none
    ]  
]

start-db-rider: func [ 
    /safe-start
    /local  ldc connection-name host user pass database table tec new-db dat tedata
     
] 
[
    either all [ (exists? ldc: join what-dir %settings/last-db-connection.datr) (not safe-start) ] [ 
        edit-db: query-db: make db-rider-context/db-obj do load ldc 
        if ( not load-text-editor-info query-db ) [
            set-text-editor query-db    
        ]
    ][ ; last-db-connection.datr file missing indicates a new install of DB-Rider
        either all [ (safe-start) ( exists? ldc: join what-dir %settings/last-db-connection.datr) ] [
            edit-db: query-db: make db-rider-context/db-obj do load ldc 
        ][
            edit-db: query-db: make db-rider-context/db-obj [ ; Make the edit-db available immediately.        
                connection-name: "query-db"
                host: "localhost"
                user: ""
                pass: ""
                database: ""
                table: ""
            ]
        ]
        new-db: edit-db-connection query-db
        either new-db <> [] [
            query-db/host: new-db/host
            query-db/user: new-db/user
            query-db/pass: new-db/pass
            query-db/database: new-db/database
            query-db/table: new-db/table
            if ( not load-text-editor-info query-db ) [
                set-text-editor query-db    
            ]      
        ][
            my-request "Database connection has not been defined^/closing DB-Rider"
            quit            
        ]
    ]
    over-mainlist?: false
    query-event-handler: func [face event] [
        switch event/type [
            scroll-line [ 
                if all [ (over-mainlist?) (event/face/text = "DB-Rider") ] [
                    either ( positive? event/offset/y ) [
                       scroll-main-list -1
                    ][
                       scroll-main-list 1
                    ] 
                ]
            ]
            move [
                either (within? event/offset main-list/offset main-list/size) [
                    over-mainlist?: true
                ][
                    over-mainlist?: false
                ]
            ]
        ]
        return event
    ]
    insert-event-func :query-event-handler
    query-db/connection-name: "query-db"
    edit-db/connection-name: "edit-db"
    scroll-virtual-list: does [] ; placeholder until edit-record is initialized.
    either query-db/init [
        do join query-db/get-global-path %print/print-support-scripts.r        
        change-dir what-dir
        query-db/connected?: true
        query-db/connection-changed?: true
        either ( query-db/table <> "" ) [
            display-query-results "" ; force the reload of the last query for this database/table combo.    
        ][
            display-query-results rejoin [ "select * FROM " query-db/table " WHERE ID > '0' LIMIT 15 " ] 
        ]
    ][
        my-request "Initialization of the database connection has failed.^/The DB-Rider program is closing."
        remove-event-func :query-event-handler
        quit
    ]
]

either ( system/script/args = "safe-start" ) [
    start-db-rider/safe-start
][
    start-db-rider    
]

quit
