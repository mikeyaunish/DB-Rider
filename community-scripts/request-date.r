;; ===========================================
;; Script: request-date.r
;; downloaded from: www.REBOL.org
;; on: 19-Oct-2006
;; at: 13:56:23 UTC
;; owner: didec [script library member who can
;; update this script]
;; ===========================================
REBOL [
	title: "request-date object/func optimization and enhancment"
	file: %request-date.r
	Author: "Didier Cadieu"
	email: to-email rejoin ["Didec" #"@" "wanadoo.fr"]	; (f.ck the bot)
	date: 23-dec-2003
	version: 1.1
	purpose: {
		This is an enhanced replacement for the original request-date function,
		the embedded date picker in view (datepicker).

		- Clean, correct and optimize the code.
		- add day names at top of window (use system/locales/days).
		- add first-day-of-week value to choose starting with Sunday
		  or Monday.
		  (I think this value should be part of system/locales)
		- add Today button at bottom.
		- Today is shown with red circle in calendar.

		- New refinment:  'request-date/date a-date  to initialize the calendar.
		  This date is shown with red square in calendar, and is
		  retuned instead of none if the window is closed.

		WARNING ! It needs View 1.2.8+ to work
	}

	library: [
		level: 'advanced
		platform: 'all
		type: [function module tool demo]
		domain: [gui patch ui]
		tested-under: [View 1.2.8 on [win2k winXP] View 1.2.41 on [Win2k WinXP]]
		support: none
		license: 'public-domain
		see-also: none
	]
]

;***** MOD function will be included in View 1.3
; Here is a quick define for older version
;if not value? 'mod [mod: func [a b][a // b]]


req-funcs: make req-funcs [
	req-date: make object! [
		base: date-lay: last-f: mo-box: today-draw: this-draw: result: none
		cell-size: 24x24

		; NEW WORD: DETERMINE FIRST DAY OF WEEK (1=monday or 7=sunday)
		; THE BETTER WILL BE TO ADD THIS WORD TO system/locales
		; IT COULD BE INITIALIZE ACCORDING TO THE O.S. VALUE (if possible).
		first-day-of-week: 7

		; THE COMPUTATION WAS CHANGED TO MANAGE FIRST-DAY-OF-WEEK
		; AND AVOID HAVING AN EMPTY FIRST LINE
		calc-month: func [/local month bas tod d][
			bas: base
			month: bas/month
			bas/day: 1
			bas: bas - (mod bas/weekday 14 - first-day-of-week) + mod first-day-of-week 7
			tod: now/date
			foreach face skip date-lay/pane 11 [
				either bas/month <> month [face/text: none] [
					face/text: bas/day
					d: copy either bas = tod [today-draw][[]]
					if bas = result [append d this-draw]
					face/effect: compose/only [draw (d)]
				]
				bas: bas + 1
			]
			mo-box/text: md base
			show [date-lay mo-box]
		]

		md: func [date][join pick system/locale/months date/month [" " date/year]]

		init: func [/local cell-feel offs fon cs2][
			if none? base [base: now/date]
			fon: make face/font [valign: 'middle align: 'center]
			cell-feel: make face/feel [
				over: func [f a] [
					f/color: either all [a f/text] [yellow] [f/color2]
					show f
				]
				engage: func [f a e] [
					if all [a = 'down f/text] [
						either f/data [base: f/data][base/day: f/text]
						f/color: f/color2 result: base hide-popup
					]
				]
			]

			cs2: cell-size  / 2
			today-draw: reduce ['pen red 'circle cs2 - 1 cs2/x - 3 'circle cs2 cs2/x - 3]
			this-draw: reduce ['pen red 'box 1x1 cell-size - 2x2]

			date-lay: layout [
				size cell-size * 7x9
				origin 0x0 space 0
				across
				arrow left cell-size [base/month: base/month - 1 calc-month]
				mo-box: box cell-size * 5x1 md base font [size: 12]
				arrow right cell-size [base/month: base/month + 1 calc-month]
				return
				offs: at
				at cell-size * 0x8
				box rejoin ["Today: " now/date] cell-size * 7x1 with [
					color2: color font: fon
					effect: compose/only [draw (today-draw)] feel: cell-feel
					data: now/date
				]
				keycode [#"^["] [result: none hide-popup] 				
			]

			last-f: func [num][
				append date-lay/pane make face [
					offset: offs size: cell-size feel: edge: none
					text: copy/part pick system/locale/days num 2
				]
				offs/x: offs/x + cell-size/x
			]
			last-f first-day-of-week
			repeat slot 6 [last-f first-day-of-week // 7 + slot 2]
			offs: offs + cell-size * 0x1

			last-f: none
			repeat slot 42 [
				append date-lay/pane make face [
					offset: offs size: cell-size color: color2: white
					font: fon feel: cell-feel data: edge: none
				]
				offs/x: offs/x + cell-size/x
				if zero? slot // 7 [offs: offs + cell-size * 0x1]
			]
			calc-month
		]

		set 'request-date func [
			"Requests a date."
			/date dat [date!] "Initial date to show"
			/offset xy [pair!]
			/yyyy-mm-dd
		][
			; ON CLOSE WITHOUT SELECTION, IF /DATE, RETURN "DAT" ELSE RETURN NONE
			base: any [result: either date [dat][none] now/date]
			either none? date-lay [init][calc-month]
			either offset [inform/offset date-lay xy] [inform date-lay]
            either yyyy-mm-dd [
                either result [
    			    return rejoin [ result/year "-" result/month "-" result/day ]
    			][
    			    return none
    		    ]
			][
			    result
			]
		]
	]
]
