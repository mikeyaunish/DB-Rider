rebol [
    Title:   "request-date-for-field"
    Filename: %request-date-for-field.r
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


request-date-for-field: func [ 
        table-name field-name 
        /local default-date-string field-val field-date req-date req-offset lo-field-name
][
    if ( not (default-date-string: pick (edit-db/get-field-details/for-table/for-field table-name field-name ) 5)) [
        default-date-string: "1000-01-01"
    ]
    lo-field-name: rejoin [ "-" field-name ] 
    field-val: get in ( do (to-word lo-field-name )) (to-lit-word "text" )
    field-date: attempt [ to-date field-val ]
    either any [ (field-date = none) ( field-date = (to-date default-date-string))] [
        req-date: now/date
    ][
        req-date: field-date
    ]
    req-offset: db-rider-context/edit-record-layout/offset + edit-db/current-mouse-position
    return request-date/offset/date req-offset req-date  
]

