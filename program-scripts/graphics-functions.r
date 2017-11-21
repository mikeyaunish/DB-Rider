rebol [
    Title: "graphics-functions"
    Filename: %graphic-functions.r 
    Author: "Modified by Mike Yaunish from Carl Sassenrath's examples"
]

gadget-mover: make object! [
    gadget-move-list: copy []
    init: func [ 
        the-layout 
        the-gadget-list { block with like [ gadget-name pair-values ] where pair value x is locked and y follows the window resize }
    ][
        populate-list the-layout the-gadget-list
    ]
    populate-list: func [ alayout gadget-list /local g gad-offset new-val ] [
            foreach g gadget-list [
                gad-offset: select (get g) 'offset
                new-val: ( to-pair reduce [ gad-offset/x (  gad-offset/y - alayout/size/y )] )
                append gadget-move-list reduce [ g new-val ]
            ]
    ]
    show-moved-gadgets: func [ smg-layout ]  [
        foreach [ gad-name inset-val ] gadget-move-list [
            complex-set/no-check [ gad-name 'offset ]  ( to-pair reduce [ inset-val/x (smg-layout/size/y + inset-val/y ) ] )
            show get gad-name
        ]
    ]
]

get-text-size: func [
    the-text [string!]
    fontsize [integer!]
][
    layout [t: text the-text font-size fontsize ]
    size-text t
]

set 'within-diff? func [ af ab ; within-diff:
                         /local res offset size target-diff ta
][ ; af = a-face ab = absolute opening
    res: make object! [ offset: 0x0 size: 0x0 ]
    target-diff: func [ target starting ending 
                        /local ta
    ][
        either target < starting [
            return (  starting - target  )   ; target below + value
        ][  
            either target > ending [
                return ( ending - target) ; target beyond - value
            ][
                return 0                   ; target on     0 value 
            ]
        ]
    ] 
    ta: make object! [ offset: af/offset size: (af/offset + af/size) ] ; Target absolute
    res/offset/x: target-diff ta/offset/x ab/offset/x  ab/size/x 
    res/offset/y: target-diff ta/offset/y ab/offset/y  ab/size/y 
    res/size/x: target-diff ta/size/x ab/offset/x  ab/size/x 
    res/size/y: target-diff ta/size/y ab/offset/y  ab/size/y  
    return res
]

do [
    use [ a b ] [
        a: find/tail second :focus [[hilight-all face]]
        b: to-string a 
        if not found? find b "face/focus-action" [ ; check if face/focus-action already installed
            insert find/tail second :focus [[hilight-all face]] bind [
            if all [in face 'focus-action block? face/focus-action face ][               
                    do face/focus-action face
            ]                                                                      
            ] fourth second :focus ; (pick out a local word 'face in the func body)
        ]
    ]
]

context [ ; virtual-layout
    virtual-margin: 16x16
    
    scroll-face: func [
        {Returns vertically & horizontally scrollable version of input face.}
        at      {Face to attach scroll-face bar to}
        v       {Visible size of the attach-to face}
        /arrows {Include arrows}
        /size   {Change size of scroll bar/arrows}
        s       {New size for scroll bar/arrows}
        ;/local l a f
        /local a f ; take l out of local and make it global to this context
    ][
        if not size [s: 16]
        virtual-margin: to-pair reduce [ s s ]
        attach-to-size: v  ; global to this context
        real-size: at/size ; global to this context 
        ml: layout/offset ;ml is global to this context
        [
            backdrop 0.0.0
            across
            space 0
            size (v + (s * 1x1))
            origin 0x0
            at 0x0
            box (v)
            slider (v * 0x1 + (s * 1x0)) []
            return
            at (v * 0x1)
            slider (v * 1x0 + (s * 0x1)) []
            at (v * 1x1)
            box gray (s * 1x1)
        ] 0x0

        set 'scroll-virtual-list func [ direction /local scroll-step f aa bb ] [ ; scroll-virtual-list:
            f: ml/pane
            scroll-step: 48
            either ( direction  = -1) [
                aa: (v/y - f/2/size/y)
                bb: ( f/2/offset/y + ( scroll-step * direction ))
                f/2/offset/y: max aa bb
                
            ][
                f/2/offset/y: min 0 ( f/2/offset/y + ( scroll-step * direction ))
            ]
            f/2/offset/y: min 0 f/2/offset/y 
            f/3/data: negate f/2/offset/y / (f/2/size/y - v/y )
            show ml
        ]


        if arrows
        [
            arrow-up: func [ /local f ]  [
                 f: face/parent-face/pane
                 f/2/offset/y: min 0 f/2/offset/y + 15
                 f/3/data: negate f/2/offset/y / (f/2/size/y - v/y)
                 show face/parent-face
            ]
            ml/pane/3/size/y: ml/pane/3/size/y - (s * 2)
            ml/pane/4/size/x: ml/pane/4/size/x - (s * 2)
            arrow: layout/offset
            [
                arrow up (s * 1x1) [
                    f: face/parent-face/pane
                    f/2/offset/y: min 0 f/2/offset/y + 15
                    f/3/data: negate f/2/offset/y / (f/2/size/y - v/y)
                    show face/parent-face  
                ]
                arrow down (s * 1x1) [
                    f: face/parent-face/pane
                    f/2/offset/y: max v/y - f/2/size/y f/2/offset/y - 15
                    f/3/data: negate f/2/offset/y / (f/2/size/y - v/y)
                    show face/parent-face
                ]
            ] 0x0
            arrow-lr: layout/offset
            [
                arrow left (s * 1x1) [
                    f: face/parent-face/pane
                    f/2/offset/x: min 0 f/2/offset/x + 15
                    f/4/data: negate f/2/offset/x / (f/2/size/x - v/x)
                    show face/parent-face
                ]
                arrow right (s * 1x1) [
                    f: face/parent-face/pane
                    f/2/offset/x: max v/x - f/2/size/x f/2/offset/x - 15
                    f/4/data: negate f/2/offset/x / (f/2/size/x - v/x)
                    show face/parent-face
                ]
            ] 0x0
            arrow/pane/1/offset: ml/pane/3/offset * 1x0 + (ml/pane/3/size * 0x1)
            arrow/pane/2/offset: ml/pane/3/offset * 1x0 + (ml/pane/3/size * 0x1 + (s * 0x1))
            arrow-lr/pane/1/offset: ml/pane/4/offset * 0x1 + (ml/pane/4/size * 1x0)
            arrow-lr/pane/2/offset: ml/pane/4/offset * 0x1 + (ml/pane/4/size * 1x0 + (s * 1x0))
            append ml/pane arrow/pane
            append ml/pane arrow-lr/pane
        ]
        ml/pane/2: at
        ml/pane/3/action:
            func [f a] compose
                [
                    f/parent-face/pane/2/offset/y: (negate at/size/y - v/y) * f/data
                    show f/parent-face
                ]
            ml/pane/3/redrag v/y / at/size/y
            
        ml/pane/4/action:
            func [f a] compose
                [
                    f/parent-face/pane/2/offset/x: (negate at/size/x - v/x) * f/data
                    show f/parent-face
                ]
            ml/pane/4/redrag v/x / at/size/x
        return ml
    ]


    set 'view-virtual func [ ; view-virtual:
            primary-layout virt-box virtual-layout 
            /scroller-size scr-size
            /no-view 
            /new-window 
            /title titl
            /offset oset
            /local virt-box-size virtual-space 
    ][

        if ( not scroller-size ) [ scr-size: 18 ]
        virtual-margin: to-pair reduce [ scr-size scr-size ]
        virt-box-size: virt-box/size - virtual-margin
        if virtual-layout = none [
            request/ok "Virtual Layout given a bad layout of NONE."
            return
        ]
        if not offset [ 
            oset: primary-layout/offset 
        ]
        
        virtual-space: scroll-face/arrows/size layout/offset virtual-layout 0x0 virt-box-size scr-size
        virt-box/pane: virtual-space
        if not no-view [
            either new-window [
                view/offset/new/title primary-layout oset titl
            ][
                view/offset/title primary-layout oset titl
            ]
        ]
    ]

    set 'redraw-virtual func [ virt-box new-layout ; redraw-virtual: 
        /local f-im virt-box-size ; redrawing-virtual global to db-rider-context
    ][ 
            virt-box-size: virt-box/size - virtual-margin
            redrawing-virtual: true ; This is to trigger the do block only once.
            f-im: scroll-face/arrows/size layout/offset new-layout 0x0 virt-box-size virtual-margin/x
            redrawing-virtual: false
            virt-box/pane: f-im
            show virt-box
    ]


    set 'see-face func [ a-face ; see-face:
            /local f scroll-padding virtual-opening add-to-offset over-size abso scroll-offset rel-pos diff over-sized? offset size scroll-addition v
        ][ ; Move virtual face so face can be seen
           ; use the ml layout global to this context
        if any [ (error? try [ value? ml/pane/9/parent-face/pane] ) (a-face/var = "ID") ] [ 
            return 
        ] ; This is to accomodate a do [ focus xx ] in the virtual layout.
        f: ml/pane/9/parent-face/pane
        
        scroll-padding: 60x24
        over-sized?: false
        virtual-opening: ml/pane/9/parent-face/pane/2/parent-face/size - virtual-margin
        add-to-offset: 0x0 ; used to modify offset so you can see the active field   
        over-size: 0x0
        scroll-offset: f/2/offset
        rel-pos: virtual-opening - a-face/offset - a-face/size - scroll-offset
        abso: copy [
            offset 0x0
            size 0x0
        ]
        diff: make object! [ offset: 0x0 size: 0x0 ]
        
        abso/offset: negate scroll-offset 
        abso/size: abso/offset + virtual-opening
        
        
        if any [ (a-face/size/x > virtual-opening/x) (a-face/size/y > virtual-opening/y) ] [
        over-sized?: true
        ]
        diff: within-diff? a-face abso        
        
        either ( (absolute diff/offset/x) > (absolute diff/size/x) ) [
            scroll-addition: 0
            if diff/offset/x <> 0 [ scroll-addition: ( (diff/offset/x / absolute diff/offset/x) * scroll-padding/x ) ]
            add-to-offset/x: diff/offset/x  + scroll-addition
            
        ][
            scroll-addition: 0
            if diff/size/x <> 0 [scroll-addition: ( (diff/size/x / absolute diff/size/x) * scroll-padding/x )]
            add-to-offset/x: diff/size/x + scroll-addition
        ]           
    
        either ( (absolute diff/offset/y) > (absolute diff/size/y) ) [
            scroll-addition: 0 
            if diff/offset/y <> 0 [scroll-addition: ( (diff/offset/y / absolute diff/offset/y) * scroll-padding/y ) ]
            add-to-offset/y: diff/offset/y + scroll-addition
        ][
            scroll-addition: 0 
            if diff/size/y <> 0  [ scroll-addition: ( (diff/size/y / absolute diff/size/y) * scroll-padding/y ) ]
            add-to-offset/y: diff/size/y + scroll-addition
        ]           
        
        if over-sized? [ 
            either add-to-offset/x > 0 [
                add-to-offset/x: diff/offset/x  + scroll-padding/x
            ][
                add-to-offset/x: diff/offset/x
            ]
        ]
        
        f/2/offset/x: f/2/offset/x + add-to-offset/x
        f/2/offset/y: f/2/offset/y + add-to-offset/y
        
        if (( (negate f/2/offset/x) + virtual-opening/x) > real-size/x ) [ ; check for scrolling past right edge
            f/2/offset/x: negate real-size/x - virtual-opening/x
        ]

        if (( (negate f/2/offset/y) + virtual-opening/y) > real-size/y ) [ ; check for scrolling past bottom edge
            f/2/offset/y: negate real-size/y - virtual-opening/y
        ]
        f/2/offset/x: min f/2/offset/x 0 ; limit the offset to left edge
        f/2/offset/y: min f/2/offset/y 0 ; limit the offset to top edge
        v: attach-to-size
        f/4/data: negate f/2/offset/x / max (f/2/size/x - v/x) 1 ; update sliders
        f/3/data: negate f/2/offset/y / max (f/2/size/y - v/y) 1

        show ml/pane/9/parent-face
    ]
] ; end of virtual-layout context 
