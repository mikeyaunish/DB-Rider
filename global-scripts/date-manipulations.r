rebol [
    Title:   "date-manipulations"
    Filename: %date-manipulations.r
    Author:  "Mike Yaunish"
    Copyright: "2017 - Mike Yaunish"
    Purpose: {support scripts for DB-Rider}     
]

date-to-weekdaystr-day-month: func [ d ] [
    d: attempt [ to-date d ]
    either(d) [
        return rejoin [ (uppercase copy/part ( pick system/locale/days d/weekday ) 3) "-" d/day "-" (uppercase copy/part ( pick system/locale/months d/month ) 3) ]    
    ][
        return ""
    ]
]

get-next-weekday-date: func [ aweekday [ integer! ] /local week-modifier add-to-date  ] [
    week-modifier: 0
    if ( aweekday < now/weekday) [ week-modifier: 7 ]
    add-to-date: (week-modifier - ( now/weekday - aweekday))
    return ( now/date + add-to-date )
]
