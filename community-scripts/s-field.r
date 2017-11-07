rebol [
	title: "Enhanced secure field style"
	purpose: {To get a field where is possible to switch between normal and secure mode and which is able to remember the history (if not in secure mode)}
	author: 'oldes
	email: oliva.david@seznam.cz
	version: 0.1.3
	date: 16-12-2002 
	history: [
		16-12-2002 {Fixed bug in the init}
		13-Aug-2002 {Fixed problem with the shared history...thx to ReBolekB.}
		7-8-2002 {Style version - shorter and better}
		3-9-2001 {EnhancedField function}
	]
]

stylize/master [
	s-field: field with [
		data: make string! 50
		text: make string! 50
		history: make object! [
			data: copy make block! 100
			i: 0
			add: func[entry][
				i: 0
				if any [none? entry data/1 = entry empty? entry][return false]
				error? try [ remove find data entry ]
				insert head data copy entry
			]
			move: func[step face][
				if (not empty? data) and (none? flag-face? face 'hide) [
					i: (i + step)
					either i > length? data [i: length? data][if i < 1 [i: 1]]
						set-value face copy pick data i
				]
			]
		]
		set-value: func[face new /local f][
			either flag-face? face 'hide [
				face/data: copy new
				insert/dup clear face/text #"*" length? new
			][
				face/text: face/data: new
				system/view/highlight-start:
				system/view/caret: either found? f: find/tail new " " [f][head new]
				system/view/highlight-end: tail new
			]
			show face
			new
		]
        set-to-history: func [ face ]  [
 			face/data: face/text
			face/data: copy ""
		    face/history/add face/data	face/data: face/text 
    	]		
		
		on-submit: true ;if false, submit is not allowed!
		feel: make feel [
			engage: func [face act event][
    			switch act [
			        down [
			            either not-equal? face ctx-text/view*/focal-face [
			                focus face
			                ctx-text/view*/caret: offset-to-caret face event/offset
			            ] [
			                ctx-text/view*/highlight-start:
			                ctx-text/view*/highlight-end: none
			                ctx-text/view*/caret: offset-to-caret face event/offset
			            ]
			            show face
			        ]
			        over [
			            if not-equal? ctx-text/view*/caret offset-to-caret face event/offset [
			                if not ctx-text/view*/highlight-start [
								ctx-text/view*/highlight-start: ctx-text/view*/caret
							]
			                ctx-text/view*/highlight-end:
							ctx-text/view*/caret: offset-to-caret face event/offset
			                show face
			            ]
			        ]
			        key [
						switch/default event/key [
							#"^M" [
								if none? flag-face? face 'hide [
									face/data: face/text
								]
								if face/on-submit [
									ctx-text/view*/highlight-start:
									ctx-text/view*/highlight-end: none
									;ctx-text/view*/caret: face/text: copy ""
									; Modified by Mike Yaunish to not erase previous input.
									either flag-face? face 'hide [
										face/data: copy ""
									][	face/history/add face/data	face/data: face/text ]
									show face
								]
							]
							#"^S" [face/make-hidden none? flag-face? face 'hide]
							up   [face/history/move 1 face]
							down [face/history/move -1 face]
						] [
							ctx-text/edit-text face event get in face 'action
						]
					]
			    ]
			]
		]
		make-hidden: func[state][
			either state [
				if none? flag-face? self 'hide [
					data: copy text
					insert/dup clear text #"*" length? data
					flag-face self 'hide
				]
			][
				deflag-face self 'hide
				text: data
			]
			focus self
		]
		init: [
			history: make history []
		]
	]
]
