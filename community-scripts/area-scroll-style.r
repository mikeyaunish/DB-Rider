REBOL [
	file: %area-scroll-style.r
	title: "Area with scrollers style"
	author: "Didier Cadieu (alias DideC)"
	email: [rejoin ["didec" to-char 64 "tiscali" #"." "fr"]]
	date: 29-july-2004
	version: 1.0.0
	purpose: {
		This is a new area style with possible vertical and/or horizontal scrollers.
		It allow selection of text outside the viewable area and have a read-only mode.
	}
	comment: {
		Scroller(s) fully follows text scrolling and face resizing if any.
		Now, you can select text with mouse also if it's outside the area : it scrolls.
		Possible read-only mode to act like an 'info style, but with better event handling.
		
		Note : except the management of scroller part, the feel/engage func could
			   replace the one in ctx-text. So all input style would allow selection
			   outside the area.
			   
		This style is intended to be used with Beta release of View 1.3 (1.2.16 - 1.2.47)
		because it uses the 'access object that was introduce in view1.2.16.
		There is a "compatibility" part that define the needed functions to allow the use
		in older version.
	}
	Copyright: {GNU Less General Public License (LGPL) - Copyright (C) Didier Cadieu 2004} 
	license: {
		http://www.gnu.org/copyleft/lesser.html
		
		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.
	}
	usage: {
		
		Use same VID specs than an 'area style with this facets more :
		
			area-scroll [vscroll] [hscroll] [scroller-width integer!] [read-only]
			
			vscroll        = add a vertical scroller in the rigth of the area.
			hscroll        = add an horizontal scroller in the bottom of the area. No effect if area is wrapped.
			scroller-width = followed by an integer! value, fixes the width
							 of the scroller(s).
			outer-edge     = put the edge arround the scrollers instead of just the area.
			read-only      = disabled editing of the text. You can still move
							 cursor, select and copy text, but you can't modify the text.
							 Read-only can be enabled/disabled after layout time
							 by adding or removing 'read-only flag to the face.
	}
	history: [
		1.0.0 29-07-2004 {first (real) public release.}
	]
	
    library: [
        level: 'advanced platform: 'all type: [module function] domain: [ui vid]
        tested-under: "View 1.2.8 and 1.2.46 WinXP" license: 'lgpl support: "email or altme"
    ]	
]

; *** The following allow to use the style in older versions that do not contains access object
if all [system/version/1 = 1 system/version/2 = 2 system/version/3 < 16] [
	if not find svv/vid-styles 'scroller [
		alert "Sorry, area-scroll needs 'scroller style not available in this Rebol/View version !" quit
	]

	ctx-access: context [
		field: context [
			clear-face*: func [face][
				if face/para [face/para/scroll: 0x0]
				if string? face/text [clear face/text]
				face/line-list: none
			]
			get-face*: func [face][face/text]
			reset-face*: func [face][
				if face/para [face/para/scroll: 0x0]
				face/text: copy ""
				face/line-list: none
			]
			set-face*: func [face value][
				if face/para [face/para/scroll: 0x0]
				face/text: form value
				face/line-list: none
			]
		]
		
		data-number: context [
			clear-face*: func [face][face/data: 0]
			get-face*: func [face][face/data]
			reset-face*: func [face][face/data: 0]
			set-face*: func [face value][
				if not number? value [
					make error! reform [face/style "must be set to a number"]
				]
				face/data: value
			]
		]
	]
	
	stylize/master [
		area: area with [
			access: ctx-access/field
		]
		scroller: scroller with [
			access: ctx-access/data-number
		]
	]

	edge-size?: func [
		{Return total size of face edge (both sides), even if missing edge.} 
		face [object!]
	][
		either face/edge [face/edge/size * 2] [0x0]
	]
] ; end of compatibility part with post 1.2.8 but pre 1.2.16 versions



; *** This function is the counterpart of scroll-para
fix-slider-para: func [
	{move a slider according text field scrolling.}
	tf {text face}
	sf {slider/scroller face}
	/redrag {also redrag the slider/scroller}
	/local tmp a st is ; a=axis, is=inner size, st=size of text
] [
	if none? tf/para [exit]
    is: tf/size - edge-size? tf
    tmp: min 1x1 is - tf/para/margin - tf/para/origin - st: size-text tf
	; Here we choose the axis. Can be done by comparing size or picking the axis in scroller
    ;a: either sf/size/x > sf/size/y [1][2]
    a: sf/axis
    sf/data: max 0 min 1 tf/para/scroll/:a / tmp/:a
	if redrag [sf/redrag min 1 is/:a / max 1 st/:a]
	show sf
]

area-style: stylize [
	area-scroll: area with [
		ar: vscroll: hscroll: slf: none
		scroll-width: 16			; default scroller width
		
		; *** New words to specify wanted scrollers, scroller width and read only.
		words: append any [words copy []] [
			vscroll [new/vscroll: true args]
			hscroll [new/hscroll: true args]
			scroller-width [if integer? args/2 [new/scroll-width: args/2] next args]
			read-only [flag-face new read-only args]
			outer-edge [flag-face new outer-edge args]
		]
		
		;*** Accessors interface: call the subface one and fix the slider
		access: make access [
			set-face*: func [face value][
				face: face/ar
				face/access/set-face* face value
				face/feel/adjust-sliders face
			]
			get-face*: func [face][face/ar/text]
			clear-face*: func [face][
				face: face/ar
				face/access/clear-face* face
				face/feel/adjust-sliders face
			]
			reset-face*: func [face][
				face: face/ar
				face/access/reset-face* face
				face/feel/adjust-sliders face
			]
			resize-face*: func[face size][
				face/size: size
				size: face/size - (2 * any [all [face/edge face/edge/size] 0x0])
				if face/vscroll [
					face/vscroll/offset/x: size/x: size/x - face/scroll-width
				]
				if face/hscroll [
					face/hscroll/offset/y: size/y: size/y - face/scroll-width
				]
				face/ar/size: size
				if face/vscroll [face/vscroll/resize/y size/y]
				if face/hscroll [face/hscroll/resize/x size/x]
				face/ar/feel/adjust-sliders face/ar			
			]
		]

		append init [
			slf: self
			pane: copy []
		
			if para/wrap? [hscroll: none]		; no horiz. scroller if word wrap enable
			; third color for read-only mode
			if all [block? colors 2 = length? colors] [append colors 180.180.180]
			; copy flags to avoid that View do it later
			flag-face self flags
			
			;*** Create the sub-face area
			append pane ar: make-face/spec/size 'area [
				related: copy []			; to store the scrollers face
				; *** Take parent-face facets
				text: slf/text
				data: slf/data
				line-list: slf/line-list
				para: slf/para
				edge: either flag-face? slf outer-edge [none][slf/edge]
				font: slf/font
				colors: slf/colors
				; area style always set new flags (see facets), we don't want that
				append init [flags: slf/flags slf/para: para]

				; *** Modify area feel to move/redrag the scroller when editing.
				; *** Also add scrolling of text while selecting until outside the area.
				feel: make ctx-text/edit bind [
					; bitset of unallowed key while in read-only mode.
					read-only-filter: union copy ctx-text/keys-to-insert charset "^H^-^~^M^X^V^T"

					;*** Manage area color according focus state and read-only mode
					redraw: func [face act pos][
						if all [in face 'colors block? face/colors] [
							face/color: either all [
								flag-face? face read-only 3 <= length? face/colors
							] [
								pick face/colors pick [1 3] face <> system/view/focal-face
							] [
								pick face/colors face <> system/view/focal-face
							]
						]
					]

					engage: func [face act event /local mov val] [
						switch act [
							down [
								either not-equal? face view*/focal-face [
									focus face 
									view*/caret: offset-to-caret face event/offset
								] [
									view*/highlight-start: 
									view*/highlight-end: none 
									view*/caret: offset-to-caret face event/offset
								]
								face/rate: none
								show face
							]
							over [
								if not-equal? view*/caret offset-to-caret face event/offset  [
									if not view*/highlight-start [view*/highlight-start: view*/caret] 
									view*/highlight-end: view*/caret: offset-to-caret face event/offset
									face/rate: none
									show face
								]
							]
							away [	; handle scrolling of area while selecting text.
								face/rate: 4
								mov: min event/offset max 0x0 event/offset - face/size
								val: face/size - face/para/margin - face/para/origin - (2 * any [all [face/edge face/edge/size] 0x0])
								face/para/scroll: min 0x0 max val - size-text face face/para/scroll - mov
								view*/highlight-end: view*/caret: offset-to-caret face confine event/offset face/para/margin face/para/origin face/size
								show face
								adjust-sliders face
							]
							up [	; stop scrolling if needed
								if face/rate [face/rate: none show face]
							]
							time [	; repeat scrolling of text while selecting text untill button is released.
								; the event/offset is relative to window here (relative to face in over/away event)
								mov: event/offset - face/parent-face/offset
								mov: min mov max 0x0 mov - face/size							
								val: face/size - face/para/margin - face/para/origin - (2 * any [all [face/edge face/edge/size] 0x0])
								face/para/scroll: min 0x0 max val - size-text face face/para/scroll - mov
								view*/highlight-end: view*/caret: offset-to-caret face confine event/offset - face/parent-face/offset face/para/margin face/para/origin face/size
								show face
								adjust-sliders face
							]
							key [
								; filter keys if in read-only mode
								if not all [flag-face? face read-only char? event/key find read-only-filter event/key] [
									edit-text face event get in face 'action
									adjust-sliders face
								]
							]
						]
					]
					
					;*** This is called from many place:
					;*** just make the scrollers following the carret
					adjust-sliders: func [face] [
						if block? face/related [
							foreach tmp face/related [fix-slider-para/redrag face tmp]
						]
					]
				] in ctx-text 'self
				
			] max 0x0 size - to-pair reduce [
				either vscroll [scroll-width][0]
				either hscroll [scroll-width][0]
			]
			
			font: color: colors: none
			if not flag-face? self outer-edge [edge: none]

			use [make-scroller sta] [	
				sta: size-text ar
				; *** Utility function to create scrollers
				make-scroller: func [siz idx /tmp s][
					s: make-face/size/spec 'scroller siz [
						related: ar
						action: func [face value][scroll-para face/related face]
					]
					append pane s
					append ar/related s
					s
				]

				;*** Create vertical scroller
				if vscroll [
					vscroll: make-scroller as-pair scroll-width ar/size/y 2
				]
				;*** Create horzontal scroller
				if hscroll [
					hscroll: make-scroller as-pair ar/size/x scroll-width 1
				]

				if empty? ar/related [ar/related: none]
				access/resize-face* self size
			]
		]
	]
]
