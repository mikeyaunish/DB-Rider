rebol [
    Title:   "do-to-selected"
    Filename: %do-to-selected.r
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

_db-record_: []         ; global variable
_current-row-num_: 0 ; global variable

do-to-selected: func [
        data-change-code
        /how-many
        /local set-field get-field new-value selected num-selected field-datatype linked-value related the-qry r fr sql-cmd field-name-word dat field-data hr delete-record duplicate-record _current-row-num_ modify-record rr 
    ] 
[
    selected: main-list/get-selected-checks
    if selected = [] [
         request "You haven't selected any records"
         either how-many [
            return 0
        ][
            exit   
        ]
         
    ]
    num-selected: length? selected
    bind data-change-code 'set-field
    set-field: func [ field-name new-value /linked-value ] [ 
        
        if (none? new-value) [
            request/ok rejoin [ "A value of NONE has been supplied to the field named:" field-name  newline "This will be ignored.The rest of the operations will still continue."]
            return
        ]
        field-datatype: query-db/get-field-datatype field-name
        if all [ 
            (field-datatype = "int")                       ; if field requires integer
            ((type? new-value) <> integer!)                ; and value supplied isn't an integer
            (query-db/get-related-table-for query-db/table field-name) ; and there is a related table for this field 
        ][ 
            linked-value: true                             ; then assume that the related table value is what is really ment.
        ]
        if linked-value [
            related: query-db/get-related-table-for query-db/table field-name
            either related <> none [
                the-qry: rejoin [ "select " related/2  " from " related/1 " WHERE " related/3 " = '" new-value "'" ]       
                r: query-db/run-sql the-qry
                if r = [] [ new-value: none ]
                fr: first r
                either (fr = [])  [
                    new-value: none
                ][
                    new-value: fr                   
                ]                
            ][
               new-value: none
            ]  
        ]
        sql-cmd: rejoin [ {update } query-db/table  { set `} field-name {`='} new-value {' WHERE `ID`='} _current-row-num_ {'} ]
        query-db/run-sql sql-cmd
    ]
    
    
    get-field: func [ field-name /human ] [
        field-datatype: second find-in-array-at query-db/get-field-details 1 field-name 
        field-name-word: to-word field-name
        dat: _db-record_/:field-name-word
        rvd: rebol-validate-data dat field-datatype 
        either ((first rvd) = 'false ) [
            field-data: copy ""
        ][
            field-data: second rvd ; rebol datatype correct value returned    
        ]
        either human [
            either (hr: query-db/get-human-readable-data field-name field-data)[
                return hr    
            ][
                return field-data
            ]
        ][
            return field-data    
        ]
    ]
        
    delete-record: does [
        query-db/run-sql  rejoin [ {DELETE FROM `} query-db/table {` WHERE `}  {ID`='} _db-record_/id {'} ]
    ]
    
    duplicate-record: func [ dupe-code [block!] ] [
        _current-row-num_: query-db/dupe-record query-db/table _db-record_/id
        do dupe-code
    ]
    

    
    modify-record: func [ change-code [block!] ] [
        _current-row-num_: _db-record_/id
        do change-code
    ]
    
    if (found? find ( to-string data-change-code ) "delete-record") [
        rr: request rejoin [ "Are you sure you want to delete " (length? selected) " records?" ]
        if ( rr <> true ) [ 
            user-msg "Delete operation ABORTED" 
            either how-many [ return 0 ] [ return ]
        ]
    ] 

    foreach s selected [
        if s <> "" [
            _db-record_: query-db/run-sql/return-block rejoin [ "Select * from " query-db/table " WHERE ID = " s ]    
            either ( _db-record_ = [] ) [
                my-request rejoin [ "Unable to retrieve record ID = '" s "'^/It may no longer exist." ]
                return
            ][
                _db-record_: first _db-record_
            ]
            do data-change-code
        ]
    ]
    if how-many [ return num-selected ]
]


