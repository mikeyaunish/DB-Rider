rebol [
    Title:   "print-functions"
    Filename: %print-functions.r
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

request-print-script: func [ 
    print-path 
    /local l ret-val
][
    ret-val: none
    l: layout [
        across
        label 150x24 right "Print script name:" print-script-name: field 
        return
        label 150x24 right "Works with report type:" 
        space 0x4 print-script-type: field space 4x4 
        button 24x24 drop-down-img [
            report-list: copy []
            report-list: get-available-reports query-db/get-report-path
            insert/only report-list [ "*All Reports*" "All" ]
            item-list: copy []
            foreach i report-list [
                append item-list i/1
            ]
            preselect-list: parse print-script-type/text ","
            if (req-res: request-list-enhanced/offset/list-size/one-click "Select a report type that your print script will work with." item-list screen-offset? face 300x200) [
                print-script-type/text: pick find-in-array-at report-list 1 req-res 2
                show print-script-type
            ]
        ] keycode 'F4
        return
        label 150x24 " " 
        button "OK" [
            ret-val: reduce [ print-script-name/text print-script-type/text ]
            hide-popup
        ]
        button "Cancel" [
            hide-popup
        ]
        do [
            focus print-script-name
        ]
    ]
    inform l
    return ret-val
    
]
