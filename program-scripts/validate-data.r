rebol [
    Title:   "validate-data"
    Filename: %validate-data.r
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

mysql-to-rebol-value: [
    "int"       [ to integer!  ]
    "tiny"      [ to integer!  ]
    "bigint"    [ to integer!  ]
    "mediumint" [ to integer!  ]
    "tinyint"   [ to integer!  ]
    "short"     [ to integer!  ]
    "int24"     [ to integer!  ]            
    "year"      [ to integer!  ]
    "varchar"    [ to string!]
    "tinyblob"   [ to string!]            
    "mediumblob" [ to string!]            
    "longblob"   [ to string!]            
    "blob"       [ to string!]            
    "tinytext"   [ to string!]            
    "text"       [ to string!]            
    "mediumtext" [ to string!]            
    "longtext"   [ to string!]            
    "enum"       [ to string!]            
    "set"        [ to string!]            
    "char"       [ to string!]            
    "decimal"   [ to decimal!  ]
    "long"      [ to decimal!  ]
    "double"    [ to decimal! ]                       
    "float"     [ to decimal! ]                       
    "time"       [ to time!  ]
    "timestamp"  [ to date!  ]
    "datetime"  [ to date!  ]
    "date"      [ to date!  ]
    "bit"       [ to string! ]
    "binary"    [ to string! ]
    "varbinary"    [ to string! ]
]

rebol-validate-data: func [ 
    the-data mysql-datatype 
    /local a len test-block fnd-pos short-datatype conv-block
] 
[
    either ( found? fnd-pos: find mysql-datatype "(" ) [
        len: ((index? fnd-pos) - 1 )
    ][
        len: length? mysql-datatype
    ]
    short-datatype: copy/part mysql-datatype len
    conv-block: select mysql-to-rebol-value short-datatype
    test-block: copy [ a: ]
    append test-block conv-block 
    append test-block [ the-data ]
    either (error? try test-block ) [ 
       return [ false ]
    ][ 
       return reduce [ true :a ]
    ] 
]


to-mysql-date: func [ d /local day-num month-num year-num pd ret-date ] [ 
    d: to-string d
    if not d [ return [ "false" "" "Can not validate DATE^/Valid format is: YYYY-MM-DD" ] ]
    pd: parse/all d " -" 
    ret-date: none
    case [
        all [((length? (to-string d)) < 3)((length? pd) = 1 )] [
            ; assume this is just a day number supplied
            either (pd/1 = "")[
                day-num: now/day
            ][
                day-num: to-integer d    
            ]
            
            either ( day-num < now/day ) [ ; you want the day in the next month
                either now/month = 12 [ 
                    month-num: 1 
                    year-num: now/year + 1 
                ][ 
                    month-num: now/month + 1  
                    year-num: now/year
                ]
            ][
                month-num: now/month
                year-num: now/year
            ]    
            ret-date: to-YYYY-MM-DD to-date reduce [ year-num month-num day-num ]
        ]  
        ((length? pd) = 2) [ ; just month-day supplied
            either ( pd/1 = "" )[ ; with a space in front of it - to signal "this month"
                ret-date: to-YYYY-MM-DD to-date reduce [ now/year now/month pd/2 ]
            ][
                ret-date: to-YYYY-MM-DD to-date reduce [ now/year pd/2 pd/2 ]
            ]
        ]
    ]
    if (ret-date = none ) [ ; none of the cases above matched.
        d: to-date d
        ret-date: to-YYYY-MM-DD d
    ]
    return ret-date
]

Round: func [
	"Rounds a Number At any given Place."
	[catch]
	Number [number!]	"Number to round."
	/At Place [integer!]	"Optional Places."
	][
	throw-on-error [
		Place: either none? Place [1] [10 ** Place]
		Number: Place * Number
		Number: Number + either positive? Number [0.5][-0.5]
		Number: Number - (Number // 1)
		Number / Place
	]
]

to-my-decimal: func [ t /local a r ] [
    either attempt [ r: to-decimal t ][
        return r               
    ][
       return 0        
    ]                
]   


validate-input-data: func [
    the-data 
    details-block [ block! ] { A block containing [ tablename fieldname ] }
    /with-sql-escape
    /unit-test unit-test-data
    /local v-convert to-v-integer dtype dtype-name null? key default field-details
    datatype-size dat low-limit hi-limit rmsg get-parens-vals a  valid-vals  full-val-size idat min-val max-val decimal-points decimal-format  pd ret-date day-num month-num year-num to-v-datetime pdat x y to-v-string len emsg  instr neg-time strlen rval full-field-details converter res
    
][
    
    v-convert: [ ; any translations that error out will be returned as "false"
        "tinyint"         [ to-v-number         the-data 1          full-field-details ] 
        "bool"            [ to-v-number         the-data 1          full-field-details ]
        "smallint"        [ to-v-number         the-data 2          full-field-details ]
        "mediumint"       [ to-v-number         the-data 3          full-field-details ]
        "int"             [ to-v-number         the-data 4          full-field-details ]
        "float"           [ to-v-number         the-data 4          full-field-details ]
        "bigint"          [ to-v-number         the-data 8          full-field-details ]
        "double"          [ to-v-number         the-data 8          full-field-details ]
        "decimal"         [ to-v-number/decimal the-data 8          full-field-details ]
        
        "date"            [ to-v-date           the-data            full-field-details ]
        "datetime"        [ to-v-datetime       the-data            full-field-details ]
        "timestamp"       [ to-v-datetime       the-data            full-field-details ]
        
        "varchar"         [ to-v-string         the-data 0          full-field-details ]
        "char"            [ to-v-string         the-data 0          full-field-details ]
        "tinytext"        [ to-v-string         the-data 255        full-field-details ]
        "text"            [ to-v-string         the-data 65535      full-field-details ]
        "mediumtext"      [ to-v-string         the-data 16777215   full-field-details ]
        "longtext"        [ to-v-string         the-data 4294967295 full-field-details ]
        "time"            [ to-v-time           the-data            full-field-details ]
        "year"            [ to-v-year           the-data            full-field-details ]
        "enum"            [ to-v-enum           the-data            full-field-details ]
        "set"             [ to-v-enum/set-type  the-data            full-field-details ]
;       * MISSING CONVERTERS *
;       "binary"
;       "tinybinary"
;       "blob"
;       "longblob"
    ]                                           

    to-long-datatype-name: func [ d ] [
        select [
           "tinyint"     "an integer (number)"
            "smallint"   "an integer (number)"
            "mediumint"  "an integer (number)"
            "int"        "an integer (number)"
            "float"      "a floating point integer (number)"
            "bigint"     "an integer (number)"
            "double"     "an integer (number)"
            "decimal"    "a decimal (number)"
        ] d
    ]
    to-v-year: func [ 
        dat details  
        /local datatype-size low-limit hi-limit rmsg
    ]
    [

        if any [ (dat = "") (dat = none ) ] [ ; NULL CHECK
            either (details/null? = "YES") [
                return [ "true" "" ]
            ][
                either (details/default = 'none) [
                    return [ "false" "" "The year MUST be specified."]
                ][
                    return reduce [ "true" details/default ]                        
                ]
            ]
        ]
        datatype-size: last parse details/datatype "()" 
        if ( not attempt [ dat: to-integer dat ])[
            return reduce [ "false" "" rejoin [ "This field requires a year" newline "You entered:{" dat "}"] ]
        ]
        if (datatype-size = "4") [
            low-limit: 1901
            hi-limit: 2155    
        ]            
        if (datatype-size = "2") [
            low-limit: 0
            hi-limit: 99
        ]
        either all [ (dat >= low-limit ) (dat <= hi-limit) ] [
            return reduce [ "true" dat ]
        ][
            rmsg: rejoin [ "Year can be between " low-limit " and " hi-limit ". You entered " dat ]
            return reduce [ "false" "" rmsg ]
        ]
    ]
    
    get-parens-vals: func [ v /local a ] [
        a: second parse v "()"
        replace/all a "'" ""
        parse a "," 
    ]
    
    to-v-enum: func [ dat details /set-type /local valid-vals len-valid-vals ] [

        valid-vals: get-parens-vals details/datatype
        if set-type [
            insert/only valid-vals "" 
        ]
        if (dat = "")[ ; NULL CHECK
            if (details/null? = "YES") [
                return [ "true" "" ]
            ]
        ]
        
        either ( find valid-vals dat ) [
            return reduce [ "true" dat ]
        ][
            len-valid-vals: length? valid-vals
            valid-vals: to-csv valid-vals #"'"
            return reduce [ "false" "" rejoin [ "This field will only accept ONE of the following^/" len-valid-vals " values: " valid-vals "^/You entered: '" dat "'" ] ]
        ]
    ]
    
    to-v-number: func [ 
        dat bytes details 
        /decimal 
        /local full-val-size idat min-val max-val decimal-points decimal-format 
    ]
    [
        if (dat = none) [
            either (details/null? = "YES") [
                return [ "true" "" ]
            ][
                return [ "false" "" "This field will not accept a NULL value" ]
            ]            
        ]
        
        if ((type? dat) = string! ) [
            if ( (trim copy dat) = "")[ ; NULL CHECK
                either (details/null? = "YES") [
                    return [ "true" "" ]
                ][
                    return [ "true" 0 ]
                ]
            ]
        ]
        
        dtype-name: first parse details/datatype "("
        dtype-name: to-long-datatype-name dtype-name
        either decimal [
            full-val-size: 3.403E+38
            if ( not attempt [ idat: to-decimal dat ])[
                return reduce [ "false" "" rejoin [ "This field requires " dytpe-name " value^/You entered:{" dat "}"] ]
            ]
            either (last parse details/datatype ")") = "unsigned" [
                min-val: 0
                max-val: full-val-size
            ][
                min-val: negate full-val-size
                max-val: full-val-size
            ]
        ][
            full-val-size: power 2 (bytes * 8)
            if ( not attempt [ idat: to-integer dat ])[
                return reduce [ "false" "" rejoin [ "This field requires " dtype-name " value^/You entered:{" dat "}"] ]
            ]
            either (last parse details/datatype ")") = "unsigned" [
                min-val: 0
                max-val: full-val-size - 1
            ][
                min-val: negate ( full-val-size / 2 )
                max-val: (( full-val-size / 2 )  - 1)
            ]
        ]
        either decimal [
            either (( idat ) >= min-val) [
                either (( idat ) <= max-val) [
                    decimal-points: second parse details/datatype "()"       
                    decimal-points: last parse decimal-points ","
                    decimal-format: rejoin [ "#." decimal-points ]
                    idat: format idat decimal-format
                    return reduce [ "true" idat ]
                ][
                    return reduce [ "false" "" rejoin [ "Value of " idat " is NOT equal to or less than " max-val ] ]        
                ]
            ][
                return reduce [ "false" "" rejoin [ "Value of " idat " is NOT equal to or larger than " min-val ] ]    
            ]            
        ][
            either (( idat ) >= min-val) [
                either (( idat ) <= max-val) [
                    return reduce [ "true" idat ]
                ][
                    return reduce [ "false" "" rejoin [ "Value of " idat " is NOT equal to or less than " max-val ] ]        
                ]
            ][
                return reduce [ "false" "" rejoin [ "Value of " idat " is NOT equal to or larger than " min-val ] ]    
            ]
        ]
    ]

    to-v-date: func [ dat details  
        /local day-num month-num year-num pd ret-date new-dat
    ]
    [ 
        if any [ (dat = "") (dat = none) ] [ ; NULL CHECK
            either (details/null? = "YES") [
                return [ "true" "" ]
            ][
                either (details/default = 'none) [
                    return [ "true" "0000-00-00" ]
                ][
                    return reduce [ "true" details/default ]                        
                ]
            ]
        ]
        dat: to-string dat
        pd: parse/all dat " -" 
        ret-date: none
        case [
            all [((length? (to-string dat)) < 3)((length? pd) = 1 )] [
                ; assume this is just a day number supplied
                either (pd/1 = "")[
                    day-num: now/day
                ][
                    day-num: to-integer dat    
                ]
                
                either ( day-num < now/day ) [ ; you want the day in the next month
                    either now/month = 12 [ 
                        month-num: 1 
                        year-num: now/year + 1 
                    ][ 
                        month-num: now/month + 1  
                        year-num: now/year
                    ]
                ][
                    month-num: now/month
                    year-num: now/year
                ]    
                ret-date: to-date rejoin [ pad year-num 4 "-"  pad month-num 2 "-" pad day-num 2 ] ; verifying date is valid
                ret-date: rejoin [ pad ret-date/year 4"-" pad ret-date/month 2 "-" pad ret-date/day 2] ; convert to YYYY-MM-DD
            ]  
            ((length? pd) = 2) [ ; just month-day supplied
                either ( pd/1 = "" )[ ; with a space in front of it - to signal "this month"
                    ret-date: rejoin [ pad now/year 4 "-" pad now/month 2 "-" pad pd/2 2]
                ][
                    ret-date: rejoin [ pad now/year 4"-" pad pd/1 2 "-" pad pd/2 2]
                ]
            ]
        ]
        if (ret-date = none ) [ ; none of the cases above matched.
            if ( not attempt [ new-dat: to-date dat ])[
                return reduce [ "false" "" rejoin [ "This field requires a date value^/The data entered: {" dat "} is not a valid date."] ]
            ]
            ret-date: rejoin [ pad new-dat/year 4 "-" pad new-dat/month 2 "-" pad new-dat/day 2]
        ]
        return reduce [ "true" ret-date ]
    ]

    to-v-datetime: func [ dat details  /local day-num month-num year-num pd ret-date pdat x y plen ] [ 
        if any [ (dat = none) (dat = "") ] [
            if (details/null? = "YES") [    
                return [ "true" "" ]
            ]
            return [ "false" ""  "Can not validate DATETIME^/Format is: YYYY-MM-DD HH:MM:SS" ]
        ]
        if (dat = " " ) [
            x: to-YYYY-MM-DD now/date
            y: now/time
            return [ "true" rejoin [ x " " y ] ]
        ]
        pdat: parse dat " "
        plen: length? pdat
        date-data: form copy/part pdat ( plen - 1)
        if date-data = "" [
            date-data: " " 
        ]
        x: to-v-date date-data details
        either ( x/1 = "true" ) [
            y: to-v-time pdat/:plen details 
            either ( y/1 = "true" ) [
                return reduce [ "true" rejoin [ x/2 " " y/2 ] ]
            ][
                return [ "false" "" "Can not validate DATETIME^/Format is: YYYY-MM-DD HH:MM:SS" ]
            ]
        ][
            return [ "false" "" "Can not validate DATETIME^/Format is: YYYY-MM-DD HH:MM:SS" ]
        ]
    ]
    
    to-v-string: func [ dat dat-length details ] [
        if dat = none [
            return reduce [ "true" "" ]
        ]
        dat: to-string dat
        if all [ ( dat = "" ) ( details/default <> 'none ) (details/null? = "NO") ] [
            dat: to-string details/default
        ]
        either ( dat-length = 0 )[
            len: second parse full-field-details/datatype "()"  ; Get the length from the datatype    
            either ( len = "") [ 
                len: 0 
            ][
                len: to-integer len        
            ]
        ][
            len: dat-length
        ]
        
        either (len = 0) [
            return [ "false" "" "The number of characters are NOT specified for this database field" ]
        ][
            either ( (length? dat) <= len ) [
                either with-sql-escape [
                    return reduce [ "true" sql-escape dat ]
                ][
                    return reduce [ "true" dat ]    
                ]
                
            ][
                emsg: rejoin [ "This field can only contain " len " character(s).^/You have tried to enter " (length? dat) " characters" ]
                return reduce [ "false" "" emsg ]
            ]
        ]
    ]
    
    to-v-time: func [ 
        dat details 
        /local to-db-time instr neg-time strlen rval digit time-str
    ] 
    [
        if ( (length? (to-string dat)) > 20 ) [ ; To avoid strange Rebol crash
            return [ "false" "" "value too long to be a valid time" ]
        ]

        to-db-time: func [ instr /local strlen rval neg-time ] [
            instr: to-string instr
            
            digit: charset [#"0" - #"9"]
            if ( parse instr [ some digit ] ) [ ; make sure this is all numbers
                neg-time: ""
                if ( (first instr) = #"-" ) [
                    neg-time: "-"
                    remove instr 1
                ]
                either (not found? find instr ":") [ ; assuming instr is formatted correctly for time
                    strlen: length? instr
                    case [
                        strlen < 3 [
                            append instr ":00:00" 
                        ]
                        strlen < 5 [
                            insert ( back back tail instr ) ":"
                            append tail instr ":00"
                        ]
                        strlen <= 7 [
                            insert (back back back (insert ( back back tail instr ) ":")) ":" 
                        ]
                    ]
                ][  ; fix up colon delimited time if not including seconds portion
                    instr: to-string to-time instr
                    if ( (length? instr) < 6) [
                        append instr ":00" 
                    ]
                ]
                insert instr neg-time    
            ]
            
            if ( not attempt [ time-str: to-time instr ])[
                return reduce [ "false" "" rejoin [ "This field requires a time value^/The data entered: {" instr "} is not a valid time."] ]
            ]
            if time-str > 838:59:59 [ ; if instr is not formatted correctly to-time will error out here.
                return reduce [ "false" "" rejoin [ "Database can not hold a time greater than 838:59:59. You entered " instr ] ]
            ]
            if time-str < -838:59:59 [
                return reduce [ "false" "" rejoin [ "Database can not hold a time less than -838:59:59. You entered " instr ] ]
            ]
            return time-str
        ]

        if any [(dat = "") (dat = none)][ ; NULL CHECK
            either (details/null? = "YES") [
                return [ "true" "" ]
            ][
                either (details/default = 'none) [
                    return [ "true" "00:00:00" ]
                ][
                    return reduce [ "true" details/default ]                        
                ]
            ]
        ]
        either (rval: to-db-time dat) [
            either any [ ((first rval) = "true" ) ((first rval) = "false" )] [
                return rval 
            ][
                return reduce ["true" rval ]        
            ]
        ][
            return reduce [ "false" "" rejoin ["{" dat "} is not a valid time format" ]]
        ]
    ]

    
    
    either (unit-test) [
        field-details: unit-test-data
    ][
        field-details: edit-db/get-field-details/for-table/for-field  details-block/1 details-block/2
    ]
    full-field-details: interleave [ fieldname datatype null? key default extra ] field-details
    dtype-name: first parse full-field-details/datatype "("
    either (converter: select v-convert dtype-name) [
        either capture-errors [
            either (error? try [res: do bind converter 'the-data] ) [ 
        	   return reduce [ "false" "" rejoin [ "Can not validate " dtype-name ] ]
        	][ 
               return reduce res  ; converter will set the results to "true" or "false" with accompanying reasons.
        	] 
        ][
            res: do bind converter 'the-data
        ]
    ][
        user-msg/edit rejoin [ "No validator available for datatype:" dtype-name ". Data being passed through." ]
        return reduce [ "true" the-data ]
    ]
]
