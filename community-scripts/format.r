REBOL [
    Title: "Formatting functions"
    File: %format.r
    Author: "Eric Long"
    Email: kgd03011@nifty.ne.jp
    Date: 20-Feb-2000
    Category: [utility math]
    Version: 1.0.3
    Purpose: {
        A few functions for formatting.

        FORMAT aims to be a Reboloid replacement for sprintf.
        It converts data into strings, with rounding of decimal
        values, choice of scientific or fixed-point notation,
        padding to a given length, and right and left justification.
        FORMAT also handles blocks of data, with corresponding blocks
        of formatting options to be applied to successive items.

        QT is useful for printing out long blocks of words or numerical
        data, and QC formats and prints out tabular data stored in
        nested blocks.

        FULL-FORM returns a string representation of a decimal that will
        load back to exactly the original value. All values that correspond
        to an exact integer up to 2 ** 53 are represented as an integer.
    }
    Acknowledgements: {
        Many thanks to Larry Palmiter and Gerald Goertzel, who tested
        these functions and suggested many improvements. The idea of
        FULL-FORM is originally Larry's, and the development of the
        code was a collaboration among the three of us.

        Thanks to Carl for suggesting the best way to pass the options
        argument.
    }
]

comment {      ================ FORMAT REFORMAT ================

REFORMAT is a shortcut to reduce a block before applying FORMAT.

EXAMPLES:

>> format pi #.4
== "3.1416"

>> reformat/full [pi exp 1] #.15                 ; greater precision than FORM
== ["3.141592653589793" "2.718281828459045"]

>> format 2 ** 32 #.-6.8                         ; round to nearest million
== "4,295,000,000"                               ; insert commas option

>> reformat [pi exp 1 square-root 2] [#8.4 #6.2] ; width specified
== ["  3.1416" "  2.72" "  1.41"]

>> format 2 ** 40 #.5.1                          ; scientific notation
== "1.09951E+012"

>> reformat ["pi =" pi] #7.4.2                   ; auto-justification
== ["pi =   " " 3.1416"]

>> reformat ["very long string" 2 ** 32] #6.0.4  ; truncation of string
== ["string" "4294967296"]

>> reformat ["very long string" 2 ** 32] #4.0.6  ; ... plus auto-justification
== ["very" "4294967296"]

>> format $20 / 3 #.4                            ; money values handled
== "$6.6667"                                     ; just like number values

>> format now #0                                 ; inserts zeroes into dates
== "06-Feb-2000/13:19"                           ; and times for alignment
}

format: func [
    {Converts Rebol data into formatted strings.}
    item "value or block of values to format"
    options [block! any-string!]
        {single option, or block of options to be applied successively to
        a block of items (with last option used repeatedly if necessary).
        Formed options are parsed to integers: A.B.C
            A       width of formatted string
                    (negative for left justified)
            B       precision to right of decimal point
                    (negative for rounding to left of decimal point)
            C and 1 scientific notation
            C and 2 auto justification (number! and money! right justified)
            C and 4 truncate string values
            C and 8 insert commas
            C and 16 prefix value with '$'} ; Added by Mike Yaunish

    /full  "use extra precision in forming decimal values"
    /local n fraction exponent neg decimal
   scientific width left-j trunc commas
   ptr round-off-point format-path prefix
][
    either data-block? :item [
        ; process block
        if object? :item        [ item: next second item ]
        format-path: make path! [format]
        if full [insert tail :format-path 'full]
        if not block? options   [ options: reduce [options] ]
        n: to block! :item
        while [not tail? n][
            either data-block? item: first n [
                        ; recurse with all format values
                change/only n format-path :item head options
            ][
                        ; use current format value
                change/only n format-path :item first options
            ]
            n: next n
                            ; get next format values, or reuse the last one
            if 1 < length? options [ options: next options ]
        ]
    ][
        ; process single value
        if block? options     [ options: first options ]
        set [width decimal options] parse-integers/def options [0 0 0]
        if negative? width [width: - width  left-j: true]
        if not zero? 1 and options [scientific: true  decimal: abs decimal]
        if not zero? 2 and options [
            left-j: not any [number? :item  money? :item]
        ]
        if all [
            not zero? 4 and options
            not zero? width
            string? :item
        ][trunc: true]
        if not zero? 8 and options [commas: true]
        if not zero? 16 and options [
            prefix: "$"
        ]
        if money? :item [
            prefix: append item/1 "$"
            item: item/2
        ]

        either number? :item [
            ; format number value
            if negative? item [item: - item  neg: true]
            n: either full [full-form item][form item]

            ; find the power of ten
            either ptr: find n "E" [
                exponent: to integer! next ptr
                clear ptr
            ][
                exponent: 0
            ]
            either ptr: find n "." [
                remove ptr
            ][
                ptr: tail n
            ]
            exponent: exponent - 2 + index? ptr

            ; round off to the desired precision
            round-off-point: either scientific [
                while [ #"0" = pick n 1 ] [
                    exponent: exponent - 1
                    remove n
                ]
                decimal + 1
            ][
                decimal + exponent + 1
            ]
            either round-off-point < length? n [
                either negative? round-off-point [n: copy "0"][
                    fraction: copy skip n round-off-point
                    either zero? round-off-point [n: copy "0"][
                        clear skip n round-off-point
                    ]
                    if positive? to integer! .5 +
                            to decimal! head insert fraction "." [
                        n: to string! 1 + to integer! n
                    ]
                ]
            ][
                insert/dup tail n "0" round-off-point - length? n
            ]

            either scientific [
                if positive? decimal [insert next n "."]
                insert tail n "E"
                either negative? exponent [
                    insert tail n "-"
                    exponent: - exponent
                ][
                    insert tail n "+"
                ]
                exponent: form exponent
                insert/dup exponent "0" 3 - length? exponent
                insert tail n exponent
            ][
                either positive? decimal [
                    insert/dup n "0" decimal + 1 - length? n
                    insert skip tail n (- decimal) "."
                ][
                    if all [
                        negative? decimal
                        n <> "0"
                    ][
                        insert/dup tail n "0" (- decimal)
                    ]
                ]
            ]
            if commas [
                if not ptr: find n "." [ ptr: tail n ]
                ptr: skip ptr -3
                while [ not head? ptr ] [
                    insert ptr ","
                    ptr: skip ptr -3
                ]
            ]
            if prefix [insert n prefix]
            if neg [insert n "-"]
            ; number value now formatted
        ][
            either any [date? :item  time? :item][
                n: form item
                ; remove time zone data if any
                if ptr: find n "+" [ clear ptr ]
                ; add zeroes to line up columns
                if #"-" = second n [ insert n "0" ]
                ptr: either ptr: find n #"/" [next ptr][n]
                if #":" = second ptr [ insert ptr "0" ]
                ; remove seconds if any
                parse n [ thru ":" to ":" ptr: (clear ptr)]
            ][
                either any-word? :item [
                    n: mold :item
                ][
                    n: form :item
                ]
            ]
        ]
        ; pad with spaces
        either left-j [
            if trunc [n: copy/part n width]
            insert/dup tail n " " width - length? n
        ][
            if trunc [n: copy skip tail n (- width)]
            insert/dup n " " width - length? n
        ]
    ]
    head n
]

reformat: func [
    {Reduces and formats the items in a block}
    b        "block to format"
    options  [block! any-string!]
    {Formatting options. Do "help format" for more information}
    /full    "use extra precision in forming decimal values"
][
    either full [
        format/full reduce b options
    ][
        format reduce b options
    ]
]


comment {      ================ QT ================

EXAMPLES:

>> arr: copy [] repeat x 25 [append arr log-e x]
== [0 0.693147180559945 1.09861228866811 1.38629436111989 ...

>> qt arr
0.0000 0.6931 1.0986 1.3863 1.6094 1.7918 1.9459 2.0794 2.1972 2.3026 2.3979
2.4849 2.5649 2.6391 2.7081 2.7726 2.8332 2.8904 2.9444 2.9957 3.0445 3.0910
3.1355 3.1781 3.2189

>> qt/o arr #.2
0.00 0.69 1.10 1.39 1.61 1.79 1.95 2.08 2.20 2.30 2.40 2.48 2.56 2.64 2.71
2.77 2.83 2.89 2.94 3.00 3.04 3.09 3.14 3.18 3.22

>> qt/o arr #.2..2                               ; two extra spaces
0.00   0.69   1.10   1.39   1.61   1.79   1.95   2.08   2.20   2.30   2.40
2.48   2.56   2.64   2.71   2.77   2.83   2.89   2.94   3.00   3.04   3.09
3.14   3.18   3.22


>> arr: copy [] repeat x 20 [append arr exp x]
== [2.71828182845905 7.38905609893065 20.0855369231877 ...

>> qt arr
        2.7183         7.3891        20.0855        54.5982       148.4132
      403.4288      1096.6332      2980.9580      8103.0839     22026.4658
    59874.1417    162754.7914    442413.3920   1202604.2842   3269017.3725
  8886110.5205  24154952.7536  65659969.1373 178482300.9632 485165195.4098

>> qt/o arr #.0                                 ; /o refinement for options
        3         7        20        55       148       403      1097
     2981      8103     22026     59874    162755    442413   1202604
  3269017   8886111  24154953  65659969 178482301 485165195

>> qt/o arr #.2.1
2.72E+000 7.39E+000 2.01E+001 5.46E+001 1.48E+002 4.03E+002 1.10E+003
2.98E+003 8.10E+003 2.20E+004 5.99E+004 1.63E+005 4.42E+005 1.20E+006
3.27E+006 8.89E+006 2.42E+007 6.57E+007 1.78E+008 4.85E+008


>> arr: copy [] repeat x 26 [append arr x * x - 1e-5]
== [0.99999 3.99999 8.99999 15.99999 24.99999 35.99999 48.99999 63.99999 ...

>> qt arr                               ; automatic rounding to integer
  1   4   9  16  25  36  49  64  81 100 121 144 169 196 225 256 289 324 361
400 441 484 529 576 625 676


>> qt system
self     version  build    product  words    options  user     script
console  ports    network  schemes  error    standard

>> right-margin: 50
== 50
>> qt system
self     version  build    product  words
options  user     script   console  ports
network  schemes  error    standard

>> s: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
>> arr: copy [] repeat x 12 [append arr s]
== ["ABCDEFGHIJKLMNOPQRSTUVWXYZ" "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ...

>> qt arr                     ; long values truncated by default 3 to a line
ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP
ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP
ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP
ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP

>> qt/o arr #0.0.0             ; no truncation
ABCDEFGHIJKLMNOPQRSTUVWXYZ
ABCDEFGHIJKLMNOPQRSTUVWXYZ
ABCDEFGHIJKLMNOPQRSTUVWXYZ
.....

>> qt/o arr #5.0.4             ; truncation to five characters
VWXYZ VWXYZ VWXYZ VWXYZ VWXYZ VWXYZ VWXYZ VWXYZ
VWXYZ VWXYZ VWXYZ VWXYZ

>> qt/o arr #5.0.6             ; ... plus auto-justification
ABCDE ABCDE ABCDE ABCDE ABCDE ABCDE ABCDE ABCDE
ABCDE ABCDE ABCDE ABCDE
}

qt: func [
    {Quick table: prints out a simple block in aligned columns}
    b [any-block! object!]
    /o   options [block! any-string!]
    /local s rm width decimal out tmp-options max-width extra-width pad
][

    if object? b [
        b: first b
    ]
    rm: either value? 'right-margin [right-margin][77]
    if not options [
        either find b money! [
            options: #0.2.6
        ][
            options: #0.0.6
            if find b decimal! [
                foreach a b [
                    if all [decimal? :a not zero? a] [
                        if 10 < log-10 abs a [
                            options: #0.4.7 break  ; use scientific
                        ]
                        if 1e-4 < ((abs a) + 5e-5 // 1) [ ; if significantly
                            options: #0.4.6      ; different from an integer
                        ]
                    ]
                ]
        ]
        ]
    ]
    set [width decimal tmp-options extra-width]
        parse-integers/def options [0 0 6 0]
    extra-width: extra-width + 1
    options: to issue! rejoin [ width "." decimal "." tmp-options ]
    if zero? width [
        max-width: to integer! rm + extra-width / 3 - extra-width
        foreach a b [
            if not data-block? :a [
                width: maximum width  length? format :a options
            ]
            if width >= max-width [
                width: max-width
                break
            ]
        ]
    ]
    pad: head insert/dup copy "" " " extra-width
    s: 0
    options: to issue! rejoin [ width "." decimal "." tmp-options ]
    foreach a b [
        either data-block? :a [
            print "^/(nested)"
            qt/o a options
            s: 0
        ][
            s: s + length? out: format :a options
            if s > rm [
                print ""
                s: length? out
            ]
            prin out
            s: s + extra-width
            if positive? rm - s - extra-width [
                prin pad
            ]
        ]
    ]
    print ""
    exit
]

comment {      ================ QC ================

EXAMPLES:

>> arr: compose/deep [
[    ["pi" (pi)]
[    ["pi * pi" (pi * pi)]
[    ["exp pi" (exp pi)]
[    ["log-e pi" (log-e pi)]]
== [["pi" 3.14159265358979] ["pi * pi" 9.86960440108936] ["exp pi" ...

>> qc arr
pi        3.14
pi * pi   9.87
exp pi   23.14
log-e pi  1.14

>> qc arr #.4                    ; with optional options argument
pi        3.1416
pi * pi   9.8696
exp pi   23.1407
log-e pi  1.1447

>> qc arr #.4.2.2                ; two extra spaces
pi            3.1416
pi * pi       9.8696
exp pi       23.1407
log-e pi      1.1447

>> qc arr [#-10 #6.2]            ; passing block of options to FORMAT
pi           3.14
pi * pi      9.87
exp pi      23.14
log-e pi     1.14
}

unset!: (type?)

qc: func [
    {prints out nested blocks in aligned columns}
    b [any-block!]
    options [block! any-string! unset!] "optional options"
    /local  widths w max-width decimal tmp-options extra-width bb
][

    if not value? 'options [
       options: #20.2.6
    ]
    if not any-block? first b [
        qt/o b options
        exit
    ]
    if data-block? first first b [
        foreach a b [
            either value? 'options [qc a options][qc a]
            print ""
        ]
        exit
    ]
    if not block? options [
        set [max-width decimal tmp-options extra-width]
            parse-integers/def options [20 2 6 0]
        if zero? max-width [max-width: 20]
        options: to issue! rejoin [ 0 "." decimal "." tmp-options ]
        widths: array/initial length? b/1 4
        foreach bb b [
            while [(length? widths) < (length? :bb)] [
                append widths 4
            ]
            while [ not tail? :bb ] [
                w: minimum
                    maximum
                        length? format first :bb options
                        first widths
                    max-width
                if w > first widths [
                    change widths w
                ]
                bb: next :bb
                widths: next widths
            ]
            widths: head widths
        ]
        while [ not tail? widths ] [
            change widths to issue! rejoin [
                extra-width + first widths "."
                decimal "."
                tmp-options
            ]
            widths: next widths
        ]
        options: head widths
    ]
    foreach bb b [
        print format :bb options
    ]
]

comment {      ================ PARSE-INTEGERS ================

NOTE: Used by FORMAT, QT and QC to parse the options argument.
      Any datatype formable to a sequence of periods and integers
      may be used.

EXAMPLES:

>> parse-integers #20.3.-4
== [20 3 -4]
>> parse-integers 2.18
== [2 18]
>> parse-integers 2.100           ; trailing zeroes disappear when
== [2 1]                          ; decimal is formed
>> parse-integers #4....6
== [4 0 0 0 6]                    ; zero is default

>> parse-integers/def #4....6 [11 12 13 14 15 16 17 18 19 20]
== [4 12 13 14 6 16 17 18 19 20]
>> parse-integers/def 4....6 [11 12 13 14 15 16 17 18 19 20]
== [4 0 0 0 6 16 17 18 19 20]     ; zeroes appear when tuple is formed
}

parse-integers: func [
    {parse integers from the form of S}
    s
    /def defaults [block!]  "block of default values"
    /local item
][
    defaults: copy either def [defaults][[]]
    s: parse form s "."
    while [ not tail? s ] [
        defaults: either integer? item: load first s [
            either tail? defaults [
                insert tail defaults item
            ][
                change defaults item
            ]
        ][
            either tail? defaults [
                insert tail defaults 0
            ][
                next defaults
            ]
        ]
        s: next s
    ]
    head defaults
]

comment {      ================ DATA-BLOCK? ================

NOTE: Used by FORMAT, QT and QC

}
data-block?: func [
    {Returns TRUE if VALUE is a block, list, hash, paren or object}
    value [any-type!]
][
    all [
        value? 'value
        any [
            block? :value
            list? :value
            hash? :value
            paren? :value
            object? :value
        ]
    ]
]

comment {      ================ FULL-FORM ================

EXAMPLES:

>> form pi
== "3.14159265358979"
>> full-form pi
== "3.141592653589793"             ; forms to full precision

>> pi - to-decimal form pi
== 3.10862446895044E-15            ; cannot recover original value
>> pi - to-decimal full-form pi
== 0                               ; original value restored

>> full-form 2 ** 53 - 1
== "9007199254740991"
>> full-form 2 ** 53
== "9007199254740992"              ; greatest "integer"
>> full-form 2 ** 53 + 2
== "9.007199254740994E+15"         ; higher values in scientific notation

>> full-form 2 ** -1074            ; smallest positive decimal value
== "4.94065645841247E-324"         ; (excess precision here)
}

full-form: func [
    {returns full-precision form of number}
    n [number!]
    /local
    s digit exponent sign formed
    first-n diff form-it savs f-exp too-big big-int
][
    sign: either negative? n           ; save sign as string and
        [n: (- n) "-"][""]             ; make N positive

    too-big: positive? n - 1.79769313486231E+308   ; highest FORM-able number

    big-int: all [                     ; pseudo-integer, incrementable
        not negative? n - 1E+15        ; by 1, but FORM converts it to
        not positive? n - (2 ** 53)    ; scientific format
    ]

    if all [
        not big-int         ; always take control from 1E+15 to MAXINTEGER
        not too-big         ; if TOO-BIG, TO DECIMAL! FORM N overflows
        zero? n - to decimal! form n   ; otherwise if FORM is good enough
    ][return head insert form n sign]  ; ... use it

    first-n: n
    s: copy ""

    exponent: either any [
        positive? exponent: log-10 n   ; get rough value of exponent
        zero? exponent - (to integer! exponent)
    ][                                 ; get integer at or below rough value
        to integer! exponent
    ][
        -1 + to integer! exponent
    ]

    n: n / (10 ** exponent)    ; convert N so that  (N >= 1)  and  (N < 10)
    digit: to integer! n       ; get the integer portion

    if zero? digit [           ; in case LOG-10 rounded up to next integer,
        exponent: exponent - 1           ; making (N < 1) ...
        digit: to integer! n: n * 10     ; adjust and recalculate
    ]

    loop 16 [
        insert tail s digit                   ; append integer portion to N
        n: n - digit * 10                     ; increment N by factor of 10
        digit: to integer! n                  ; to get next integer portion
    ]

    insert next s "."        ; add decimal point to get representation of N

    f-exp: either negative? exponent [head insert form exponent "E" ][
        either positive? exponent                   ; make exponent string
            [head insert form exponent "E+"][""]
    ]
    form-it: func [][
        formed: copy f-exp               ; tack on exponent string to get
        insert formed s                  ; decimal representation of FIRST-N
        first-n - to decimal! formed     ; return the value for DIFF
    ]

    if not zero? diff: form-it [         ; if 16 loops didn't work ...
        savs: s
        if not too-big [
            s: string-add s "1"          ; first try incrementing,
            diff: form-it
        ]
        if not zero? diff [              ; and if that didn't work ...
            s: savs
            insert tail s digit          ; tack on 17th digit
        ]
    ]
    if zero? diff [                      ; return if we had the exact form
        return head insert  either big-int [
            head remove skip s 1         ; without decimal point if possible
        ][formed]           sign
    ]

    either positive? diff: form-it [     ; now see where we are
        while [ positive? diff ] [       ; increment till it works ...
            s: string-add s "1"
            diff: do form-it
        ]
    ][
        while [ negative? diff ] [       ; or decrement ...
            s: string-subtract/full-length s "1"
            diff: form-it
        ]
    ]
    head insert formed sign
]

comment {      ================ STRING-ADD ================

NOTE: Used by FULL-FORM

EXAMPLES:

>> string-add "123456789999999999875" "125"
== "123456790000000000000"

>> string-add "2.0000000000000000" "-125"
== "1.9999999999999875"              ; decimal point in longer arg ignored
}

string-add: func [
    {add two string representations of integers numerically -
    NOTE: decimal points in longer argument are ignored}
    a [string!] b [string!]
    /local c d neg
][
    a: copy a   b: copy b
    either #"-" = first a [
        either #"-" = first b [neg: true remove a remove b][
            remove a  return string-subtract b a
        ]
    ][
        if #"-" = first b [remove b  return string-subtract a b]
    ]
    if (length? a) < (length? b) [set [a b] reduce [b a]]
    insert/dup b "0" (length? a) - (length? b)
    a: tail a  b: tail b
    d: 0 while [ not head? b ] [
        a: back a  b: back b
        if #"." = first a [a: back a]
        c: (first a) + (first b) + d - 48
        d: either c > #"9" [c: c - 10  1][0]
        change a c
    ]
    if d > 0 [insert a "1"]
    if neg [insert a "-"]
    a
]

comment {      ================ STRING-SUBTRACT ================

NOTE: Used by FULL-FORM
}

string-subtract: func [
    {subtract two string representations of integers numerically -
    NOTE: decimal points in longer argument are ignored}
    a [string!] b [string!]
    /full-length
    /local c d neg
][
    a: copy a   b: copy b
    either #"-" = first a [
        either #"-" = first b [neg: true  remove a remove b][
            insert b "-"   return string-add a b
        ]
    ][
        if #"-" = first b [remove b  return string-add a b]
    ]
    if any [
        (length? a) < (length? b)
        all [(length? a) = (length? b)  a < b]
    ][set [a b] reduce [b a]  neg: not neg]
    insert/dup b "0" (length? a) - (length? b)
    a: tail a  b: tail b
    d: 0 while [ not head? b ] [
        a: back a  b: back b
        if #"." = first a [a: back a]
        c: to char! (first a) - (first b) - d + 48
        d: either c < #"0" [c: c + 10   1][0]
        change a c
    ]
    if not full-length [
        while [all [#"0" = first a  1 < length? a]][remove a]
    ]
    if neg [
        either #"-" = first a [remove a][insert a "-"]
    ]
    a
]

comment {      ================ PAREN-FORM ================

NOTE: This is the  fastest way to make a precise string representation
      of an arbitrary decimal

EXAMPLE:

>> paren-form pi
== "(3.14159265358979 + 3.10862446895044E-15)"
>> pi - do paren-form pi
== 0
}

paren-form: func [
    {returns a string precisely representing numerical value}
    n [number!]
    /local s diff
][
    diff: n - to decimal! s: form n
    either zero? diff [s][to string! reduce ["(" s " + " diff ")"]]
]
