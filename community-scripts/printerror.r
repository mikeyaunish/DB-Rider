REBOL [
    Title:   "Error Object to Error Message Converter"
    Date:    14-Oct-1999
    Author:  "Bohdan Lechnowsky"
    Email:   amicom@sonic.net
    File:    %printerror.r
    Purpose: {
        To take DISARMed error objects and convert them back to
        their REBOL-runtime error messages.
    }
    History: {
        01-Oct-2017 Mike Yaunish 
            {added return-a-value.}
        28-Oct-1999 Bo
            {Fixed another binding problem.}
        20-Oct-1999 Bo
            {Fixed a binding problem.}
    }
    Category: [script utility general advanced]
]

printerror: func [
    error [object!]
    /return-a-value
    /local arg1 arg2 arg3 message rval
][  
    set [arg1 arg2 arg3][error/arg1 error/arg2 error/arg3]
    message: get in get in system/error error/type error/id
    if block? message [bind message 'arg1]
    either (return-a-value) [
        rval: reform reduce message
        append rval rejoin ["^/Near: " mold error/near]
        append rval rejoin ["^/Where: " mold error/where]
        return rval
    ][
        print reform reduce message
        print ["Near: " mold error/near]
        print ["Where: " mold error/where]
    ]
]
