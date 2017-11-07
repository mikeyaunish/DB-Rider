rebol [
    Title:   "request-enum-for-field"
    Filename: %request-enum-for-field.r
    Author:  "Mike Yaunish"
    Copyright: "2017 - Mike Yaunish"
    Purpose: {support script for DB-Rider}    
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

request-enum-for-field: func [
        table-name field-name
        /offset the-offset
    ][
        either offset [
            request-enum-set-for-field/offset table-name field-name the-offset
        ][
            request-enum-set-for-field table-name field-name    
        ]
]

request-set-for-field: func [
        table-name field-name
        /offset the-offset
    ][
        either(offset) [
            request-enum-set-for-field/set-type/offset table-name field-name  the-offset
        ][
            request-enum-set-for-field/set-type table-name field-name    
        ]
]


request-enum-set-for-field: func [ ; defaults to use "enum" database type
        table-name field-name ; db-field-name format
        /set-type ; flag to use database "set" datatype
        /offset the-offset
        /local r fd enum-detail penum-detail enum-list zz req-offset lo-field-name
    ] [
    
    fd: edit-db/get-field-details/for-table/for-field table-name field-name
    enum-detail: fd/2
    penum-detail: parse enum-detail "(),"
    enum-list: collect zz [ foreach i (skip penum-detail 1) [ zz: trim/with i "'" ] ]
    if set-type [
        insert enum-list "" ; "set" datatype will accept a blank value
    ]
    either offset [
        req-offset: the-offset
    ][
        lo-field-name: rejoin [ "-" field-name ]
        req-offset: db-rider-context/edit-record-layout/offset + edit-db/current-mouse-position - 0x70
    ]
    
    if (r: request-list-enhanced/offset/one-click "Select Your Choice" enum-list req-offset)[
        return r   
    ]
    return false
]


