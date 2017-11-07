;; ===========================================
;; Script: menu-system.r
;; downloaded from: www.REBOL.org
;; on: 26-Jun-2013
;; at: 22:19:16.814527 UTC
;; owner: christian [script library member who
;; can update this script]
;; ===========================================
;; ===============================================
;; email address(es) have been munged to protect
;; them from spam harvesters.
;; If you were logged on the email addresses would
;; not be munged
;; ===============================================
REBOL [
    Title:   "Menu-System"
    Name:    'Menu-System
    File:    %menu-system.r
    
    Version: 0.2.0
    Date:    12-Jun-2005 
        
    Author:  "Christian Ensel"
    Email:   %christian--ensel--gmx--de
    
    Owner:   "Christian Ensel"
    Rights:  {
        Copyright (c) 2005 Christian Ensel
        All rights reserved.

        Redistribution and use in source and binary forms, with or without 
        modification, are permitted provided that the following conditions 
        are met:

        •  Redistributions of source code must retain the above copyright
           notice, this list of conditions and the following disclaimer.
        •  Redistributions in binary form must reproduce the above copyright 
           notice, this list of conditions and the following disclaimer in the
           documentation and/or other materials provided with the distribution.
        •  Neither the name of the copyright holder nor the names its 
           contributors may be used to endorse or promote products derived 
           from this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
        "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
        LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
        A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
        OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
        SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
        LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
        DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
        THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
        OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."                                 
    }
    
    Purpose: {
        Easy to use VID compatible REBOL menu system (early Beta).
        Have menus in your REBOL apps, finally.
    }
    
    Todo: {
        • The SCROLLER-ITEM stuff is actually more of a prove of concept, 
          but it seems like integrating other VID-Styles should be possible.
          I'd really like to see FIELD-ITEM, or maybe even a generic VID-ITEM.
          Minor drawback: disabling SCROLLER-ITEM doesn't work, but that really
          shouldn't be too hard to accomplish.
        • Some functions like ADJUST-xy and LAYOUT-xy have to changed to 
          methods in FEEL or ACCESS.
        • I'd like to get rid of MENU/ITEMS. Keeping it in sync with
          MENU/LIST/PANE is annoying, one simple loop thru the latter should 
          do and won't be noticable slower.
        • There's a bug in closing windows: REBOL.exe remains, with all
          windows closed, waiting in the event loop. Looks like somewhere 
          there's one WAIT. But *where*?
    }
    
    History: {
        0.2.0 • Mostly all code is now truly OOP due to leaving FACE/TYPE 
                intact (now always is 'FACE for future VID compatibility)
                (hence the jump in the version number) 
              • Rebolish default style inbuild
              • For the fun of it: Derived SLIDER-ITEM from MENU-ITEM,
                and - tada! - it works!
        0.1.8 • Further major code cleaning and more consistent OOP, way too
                much to list here.
              • Totally rewritten styling scheme, now uses flat PROPERTIES
              • Inserting new items to an existing menu is now possible thanks
                to "abusing" LAYOUT-MENU to create a single-item menu, whose
                item is then inserted by INSERT-ITEM.
                It's a bit odd though, because it doesn't inherit styles if none
                we're supllied.
              • For top-level menus (root-menus) it's now possible to refer
                to their items by index. This doesn't work for menu-bars though.
        0.1.7 • Menu-accessor method object added
              • Experimental removing and reinserting of items works.  
              • Global functions to menu-accessors added
              • Dialect is more consistent and allows specification of 
                normal and hovered enabled and disabled states.
              • A couple of layout and style inheritence problems fixed.
              • Overall code cleaning.
        0.1.6 • Shortcut keys are now dialected as TAG! instead of ISSUE!,
                TAG! is way more flexible.
              • Styling with LAYOUT-MENU/STYLE works.
              • Styling MENU-BAR and DROP-MENU with MENU-STYLE works.
              • Correction of layout algorithm, still somewhat problematic.                
        0.1.5 • MENU-BAR style now with full keyboard support, but still
                "menubar" and "baritems" aren't configurable.
              • DROP-MENU now works again.
        0.1.4 • Experimental MENU-BAR VID style now works.
                It isn't configurable much and there are some really annoying bugs.
              • Drop-Menu is broken for now.
        0.1.3 • Experimental DROP-MENU VID-style.
        0.1.2 • Dialect changes.
        0.1.1 • Dialect changes.
        0.1.0 • Refactored earlier prototype.
    }
    
    Credits: {
        Originally this script evolved from trying to understand the inner
        workings of Cyphre's menu system sketch, without that I would by
        no means have come as far as shown here.
    }
    
    Library: [
        level:      'intermediate
        platform:   'all
        type: [module demo]
        code: 'module
        domain: [user-interface vid gui]
        tested-under: [view 1.2.119.3.1 on "WinXP"]
        support: none
        license: 'BSD
        see-also: none
    ]
]

ctx-menus: context [

    ;############################################# helper functions and alike ##
    ;

    shadow-image: use [reset image] [
        reset: system/options/binary-base
        system/options/binary-base: 64
        image: load 64#{
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+g
vaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1QQUCzYGyPaalQAAAINJ
REFUeNrd0qEOwjAUBdADDIJDIYaZWPjJfSZuAo2bQiybKKZLmqUzRcE1TZO+U3Ef
P59DwUyHCwKGqgBocFou+wLghhptKVDjjGMpkOb6LeAPgCqzJE1SVS4vjJgR1sAj
WZJhAxgj8sS0Bvp4tkvPmcxxeEC/yzy4Lx1vAAFT/Oz9ASj/FhDibXHbAAAAAElF
TkSuQmCC
}
        system/options/binary-base: reset
        image
    ]

    cast: func [value cases] [switch type?/word :value cases]

    text-size?: func ["Returns a face's text size or 0x0." face [object!] /local size result] [ 
        size: face/size
        face/size: 10000x10000                                                  
        result: size-text face
        face/size: size
        result
    ]
    
    image-size?: func ["NONE-safe image/size shortcut" image [image! none!]] [
        any [all [image image/size] 0x0]
    ]
    
    instance-of: func [
        "Returns TRUE if entity is of required class (NONE otherwise)."
        entity [object! none!] class [word!]
    ][
        all [
            object? entity
            'face = get in entity 'type
            found? find any [get in entity 'class []] class
        ]
    ]
    
    ;############################################################# MENU-ITEMS ##
    ;
        
    ;============================================================= new-detail ==
    ;
    ;   Detail faces are the inner faces of menu-item, each item uses five
    ;   of them: 
    ;
    ;       - MARK:    The radio- or check-mark
    ;       - ICON:    The item's icon image
    ;       - BODY:    The item's body text and/or image
    ;       - KEY:     The item's shortcut-key text
    ;       - ARROW:   The item's arrow (only for item's with sub-menu)  
    ;
    
    new-detail: func ["Returns an uninitilized item detail."] [
        make system/view/vid/vid-face [                                         ;-- Notice that details have no feel, all item actions are triggered by
            class: make block! [item-detail]                                        ;   item's feel/detect.
            edge: color: effect: effects: none                                      
            offset: size: 0x0
            feel: make face/feel [
                redraw: func [detail offset /local item] [
                    item: detail/parent-face
                    if detail/effects [
                        detail/effect: pick detail/effects item <> item/menu/actor
    ]   ]   ]   ]   ]
        
    ;============================================================== item-feel ==
    ;
    ;   The ITEM-FEEL is the central method object for all item related 
    ;   functions.
    ;
    
    item-feel: make face/feel [
        
        detect: func [item event] [
            if within? event/offset win-offset? item item/size [
                item/menu/feel/visit item/menu item
                item/feel/enter item
                event
            ]
        ]

        redraw: func [
            "Draws an item."                                                    ;-- Cares for normal and hovered en- and disabled states. 
            item [object!] offset [pair!]
        /local
            state color
        ][
            state:         pick [2 1] item = item/menu/actor
            state: state + pick [2 0] item/state    
            
            item/color:            item/properties/item.colors/:state
            item/icon/image:       item/properties/item.icon.images/:state
            item/icon/effect:      item/properties/item.icon.images/:state
            item/body/font:        item/properties/item.body.font
            item/body/font/color:  item/properties/item.body.font/colors/:state
            item/body/para:        item/properties/item.body.para
            item/key/font:         item/properties/item.key.font
            item/key/font/color:   item/properties/item.key.font/colors/:state
            item/key/para:         item/properties/item.key.para
            item/edge:             item/properties/item.edge
            item/edge/color:       item/properties/item.edge/colors/:state
            item/edge/effect:      item/properties/item.edge/effects/:state
            item/effect:           item/properties/item.effects/:state
            
            if not empty? item/properties/item.body.images [
                item/body/effect: compose/deep [
                    draw [
                        image                                           ;-- Images are left-aligned as well as texts are
                            (as-pair 0 item/body/size/y - (second image-size? item/properties/item.body.images/:state) / 2)
                            (item/properties/item.body.images/:state)
                    ]
                ]
            ]
            
            color: any [item/key/font/color item/body/font/color black]         ;-- Hardcoded default here?!?
            
            item/feel/draw-mark  item color                                     ;-- They know what they're doing
            item/feel/draw-arrow item color                                     ;
        ]

        draw-mark: func [item [object!] color [tuple!]] [
            item/mark/effect: all [
                item/mark/state
                case [
                    instance-of item/mark 'radio [
                        compose/deep [
                            draw [pen (color) fill-pen (color) circle 7x8 3]
                    ]   ]
                    instance-of item/mark 'check [
                        compose/deep [
                            draw [
                            pen (color) line-width 2 line-cap square line-join bevel
                            line 3x8 6x11 12x5
        ]   ]   ]   ]   ]   ]
    
        draw-arrow: func [item [object!] color [tuple!]] [
            item/arrow/effect: all [
                item/sub
                compose/deep [
                    draw [
                        pen (color) fill-pen (color) polygon
                            (as-pair item/arrow/size/x -  8 item/arrow/size/y / 2 - 1)
                            (as-pair item/arrow/size/x - 11 item/arrow/size/y / 2 - 4)
                            (as-pair item/arrow/size/x - 11 item/arrow/size/y / 2 + 2)
                            (as-pair item/arrow/size/x -  8 item/arrow/size/y / 2 - 1)
        ]   ]   ]   ]
        
        visit: func [                                                           ;-- Show that we're visited
            "Visits item (draws it's hover state)." item [object!]
        ][  
            show item                                                           
        ]
        
        enter: func [
            "Enters item (shows it's sub-menu)."
            item [object!]
        /new                                                                    ;-- NEW is used to differentiate between wandering through menus with   
            "Returns immediately from showing."                                 ;   mouse and keyboard. Whilst hovering items with sub-menus with the
                                                                                ;   mouse, sub-menus are opened immediatly, whereas when navigating a menu  
                                                                                ;   with the keyboard, that doesn't open sub-menus (to not steal the 
                                                                                ;   keyboard focus).    
                                                                                ;
        ][
            if all [                                                            ;-- Show the own sub-menu, for enabled item's with sub-menus 
                item/sub                                                        ;   not already popped up only
                not item/state
                none? find system/view/pop-list item/sub
            ][ 
                either new [
                    show-menu/new find-window item item/sub                     ;-- Keyboard entered sub-menu
                ][
                    show-menu     find-window item item/sub                     ;-- Mouse opened sub-menu
                ]
            ] 
        ]
        
        leave: func [                                                           
            "Leaves item (draws it's unhovered state and closes it's sub-menu)."      
            item [object!]                                                      
        ][                                                                         
            all [item/sub item/sub/feel/close item/sub]
            show item
        ] 
        
        engage-mark: func [item /local items] [
            case [
                instance-of item/mark 'radio [
                    if off = item/mark/state [
                        item/mark/state: true
                                        
                        items: item/menu/list/pane
                        foreach sibling items [
                            if all [
                                instance-of sibling 'menu-item
                                sibling <> item
                                item/mark/group = get in sibling/mark 'group
                            ][
                                sibling/mark/state: false
                                show sibling/mark
                ]   ]   ]   ]
                instance-of item/mark 'check [
                    item/mark/state: not item/mark/state
                ]
        ]   ]
   
        engage: func [
            item action event 
            /local root popup start end items state
        ][
            if all [action = 'up none? item/sub not item/state] [           ;-- We act only on 'UP events for nothing but enabled items without sub-menus.                                                     
                
                if any [
                    instance-of item/mark 'radio
                    instance-of item/mark 'check
                ][
                    item/feel/engage-mark item
                ]
                
                either not event/shift [                                        ;-- SHIFT enables multi-selection, otherwise the whole menu closes.
                    root: item/menu/feel/root-of item/menu
                    root/feel/close root
                ][
                    show item
                ]
                
                if item/properties/item.action [                                        ;-- Trigger the items action by doing an anonymous function build    
                    do func [item] bind item/properties/item.action in item 'self item  ;   from the item's action block. Should I allow for functions here, too?
                ]
            ]
            none
        ]
    ]
    
    ;=========================================================== baritem-feel ==
    ;
    
    baritem-feel: make item-feel [
        super: item-feel
        over: none 
        engage: none
        redraw: func [item offset] [
            item/color: pick item/menu/colors item <> item/menu/actor    
        ]
        detect: func [item event /local actor] [
            case [
                none? item/menu/actor [
                    item/menu/state: 'down-to-enter
                    item/menu/feel/visit item/menu item
                    focus/no-show item/menu
                ]
                'down-to-enter = item/menu/state [
                    item/menu/feel/visit item/menu item
                    focus/no-show item/menu
                    if 'down = event/type [
                        item/menu/state: 'hover-to-enter
                        item/feel/enter item
                    ]
                ]
                'hover-to-enter = item/menu/state [
                    if 'move = event/type [ 
                        item/menu/feel/visit item/menu item
                        item/feel/enter item
            ]   ]   ]
            none
        ]
        enter: func [
            "Enters item (shows it's sub-menu)."
            item [object!]
        /new
            "Returns immediately from showing."
        ][
            if all [                                                            ;-- Show the own sub-menu, if there's one and if it's not
                item/sub                                                        ;   popped up already 
                none? find system/view/pop-list item/sub
            ][ 
                either new [
                    show-menu/offset/new find-window item/menu item/sub (win-offset? item) + (0x1 * item/size)                     ;-- Keyboard entered sub-menu
                ][
                    show-menu/offset find-window item/menu item/sub (win-offset? item) + (0x1 * item/size)                    ;-- Mouse opened sub-menu
    ]   ]   ]   ]
    
    ;=============================================================== new-item ==
    ;
    new-item: func ["Returns a uninitialised menu item."] [                     ;-- No deep copying required.
        make system/standard/face [
            class:  make block! [menu-item]
            item:   none                                                        ;-- ITEM is set to SELF, this makes client code easier (or harder ...) 
            menu:   none                                                        ;-- MENU is always the menu the item belongs to, it is *not* the 
                                                                                ;   sub-menu an item may have (thats in SUB).
            var:    none                                                        ;-- VAR holds the word by which we later refer to the item.
            text: font: image: state: none                                      ;-- All these are unused in favour of the detail faces.
                                                                                ;   (see comments to pane). 
            edge: color: effect: none                                           ;-- All these are set depending on items properties and activation-states
                                                                                ;   away/over enabled/disabled  
            state: no                                                           ;-- The enabled/disabled state. There is no explicit OVER state, that is handled
                                                                                ;   in REDRAW dynamically.
            properties: none                                                    ;-- All the item related properties. ###### SHOULDN'T THEY BE INHERITED????? #######
            feel: item-feel                                                     ;-- See detailed comments on ITEM-FEEL.
            data: none                                                          ;-- The item's sub-menu's description, if any.
            sub: none                                                           ;-- The item's sub-menu object itself, if any.
            mark: icon: body: key: arrow: none                                  ;-- Just some shortcuts to the details in item's pane. 
            pane: reduce [                                                      
                mark:  make new-detail [group: none]                            ;-- GROUP is used for mark-items. Each menu starts which one initial group,
                icon:  new-detail []                                            ;   implicit groups are set up by menu-dividers and additional, more complex
                body:  new-detail []                                            ;   groups can be explicitly specified in the setup dialect. 
                key:   new-detail []             
                arrow: new-detail []                                      
    ]   ]   ]
    
    ;============================================================= build-item ==
    ;
    build-item: func [
        "Builds an item, together with all it's sub-faces."
        item [object!]     "a new item" 
        menu [object!]     "the menu the item resides in"
        word [word! none!] "the item's identifier"
        desc [block!]      "the item's description"
    ][     
        item/item: item/self
        
        item/menu: menu
        item/var:  word
        item/data: desc
        
        menu: menu/properties
        item/properties: make object! [
            item.action:       menu/item.action
            item.effects:      menu/item.effects  
            item.colors:       menu/item.colors   
            item.icon.images:  []
            item.icon.effects: []
            item.body.font:    menu/item.body.font
            item.body.para:    menu/item.body.para
            item.body.images:  []
            item.key.font:     menu/item.key.font 
            item.key.para:     menu/item.key.para
            item.edge:         menu/item.edge     
        ] 
        item/body/font: item/properties/item.body.font
        item/body/para: item/properties/item.body.para
        item/key/font:  item/properties/item.key.font
        item/key/para:  item/properties/item.key.para
        item/edge:      item/properties/item.edge
        
        item
    ]
    
    
    ;========================================================== build-divider ==
    ;
    ;   DIVIDER needs to be reworked, I guess. Currently, there are absolutely
    ;   no config properties.
    ;
    build-divider: func [
        "Builds a menu divider."        
        parent [object!] "the divider's parent menu"
    ][     
        make face [
            class: make block! [menu-divider]
            var: none
            menu: parent
            properties: none
            color: 172.168.153                                                  ;-- Win XP Silver; hardcoded for now
            edge: make face/edge [                                              ;-- Ditto, look like Win XP Silver.
                size:  1x2
                color: image: effect: none
            ]
        ]
    ]
 
    
    ;=========================================================== layout-items ==
    ;
    set 'layout-items func [
        "Layouts items."
        menu [object!]
        desc [block!]
    /local
        value item properties size
    ][
        parse desc [
            some [
                [   ['divider | 'bar | '---] (                                        
                        item: build-divider menu
                        menu/list/pane: insert menu/list/pane item
                        insert tail menu/items reduce [none item]
                        properties: item/properties
                    )
                |   set value opt set-word! (
                        value: all [:value to word! value]
                    )
                    [   'item (
                            item: build-item new-item menu value desc
                            menu/list/pane: insert menu/list/pane item
                            insert tail menu/items reduce [item/var item]
                            properties: item/properties
                        )
                    |   'slider (
                            item: build-slider new-slider menu value desc
                            menu/list/pane: insert menu/list/pane item
                            insert tail menu/items reduce [item/var item]
                            properties: item/properties
                        )
                    ]
                    
                    any [
                        set value string! (
                            item/body/text: value
                        )
                    |   set value tag! (
                            item/key/text: to string! value
                        )
                    |   ['action set value block! | set value block!] (
                            properties/item.action: value
                        )
                    |   ['icon | 'icons] set value [image! | word! | file! | path! | block!] (
                            properties/item.icon.images: cast value [
                                word!  [get value]
                                file!  [load value]
                                image! [value]
                                path!  [do value]
                                block! [value]
                            ]
                            if not block? properties/item.icon.images [
                                properties/item.icon.images: compose [
                                    (properties/item.icon.images) (properties/item.icon.images)
                                    (properties/item.icon.images) (properties/item.icon.images)
                                ]
                            ]
                            properties/item.icon.images: reduce properties/item.icon.images
                            item/icon/image: properties/item.icon.images
                        ) 
                    |   ['image | 'images] set value [image! | file! | word! | path! | block!] (
                            properties/item.body.images: cast value [
                                file!  [load value]
                                word!  [get value]
                                path!  [do value]
                                image! [value]
                                block! [value]
                            ]
                            if not block? properties/item.body.images [
                                properties/item.body.images: compose [
                                    (properties/item.body.images) (properties/item.body.images)
                                    (properties/item.body.images) (properties/item.body.images)
                                ]
                            ]
                            properties/item.body.images: reduce properties/item.body.images    
                            item/body/image: properties/item.body.images/1
                        )
                    |   'colors set value ['none | none! | block!]  (
                            if any [none? value 'none = value] [value: []]
                            properties/item.colors: reduce value
                        )
                    |   'effects set value ['none | none! | block!] (
                            if any [none? value 'none = value] [value: []]
                            properties/item.effects: compose [(value)]
                        )
                    |   'font set value [block!] (
                            item/body/font: properties/item.body.font: make properties/item.body.font value
                            item/key/font:  properties/item.key.font:  make properties/item.key.font  value
                        )
                    |   'para set value [block!] (
                            item/body/para: properties/item.body.para: make properties/item.body.para value
                            item/key/para:  properties/item.key.para:  make properties/item.key.para  value
                        )
                    |   'body [
                            'font set value [block!] (
                                item/body/font: properties/item.body.font: make properties/item.body.font value
                            )
                        |   'para set value [block!] (
                                item/body/para: properties/item.body.para: make properties/item.body.para value
                            )
                        ]
                    |   'key [
                            'font set value [block!] (
                                item/key/font:  properties/item.key.font: make properties/item.key.font value
                            )
                        |   'para set value [block!] (
                                item/key/para:  properties/item.key.para: make properties/item.key.para value
                            )
                        ] 
                    |   'edge set value ['none | none! | block!] (
                            if any [none? value 'none = value] [value: [size: 0x0]]
                            item/edge: properties/item.edge: make properties/item.edge value                       
                        )
                    |   set value ['radio | 'check] (
                            append item/class 'mutual-item
                            append item/mark/class value
                            item/mark/state: off
                        )
                        any [
                            'of [opt 'group] set value [lit-word!] (
                                item/mark/group: value
                            )
                        |   set value [
                                'on  | 'true  | 'yes | true |
                                'off | 'false | 'no  | false
                            ](
                                item/mark/state: do value
                            )
                        ]
                    |   'menu copy value block! (
                            item/data: first value                              ;-- Remember a sub-menu's description
                            item/sub: layout-menu/parent item/data item         ;-- And set up the sub-menu's faces
                        )
                    |   'effects set value ['none | none! | block!] (
                            if any [none? value 'none = value] [value: []]
                            properties/item.effects: compose [(value)]
                        )
                    |   set value ['disable | 'enable] (
                            item/state: value = 'disable
                        )             
                    ]
                ]
            ]
        ]
        menu
    ] 
    

    ;=========================================================== adjust-items ==            ;-- This is more of a MENU function!
    ;
    ;   ADJUST-ITEMS' job is to establish consistent item sizes within one
    ;   menu. It makes all items the same width (which may be a fixed width
    ;   or the width of the widest item). It further aligns the details of
    ;   one item to be in column with the corresponding details of other items.
    ;
    
    adjust-items: func [
        "Adjust the menu-items widths and returns total size consumed by items."
        items [block!]
    /local
        item      mark      icon      body      key      arrow     
        item-size mark-size icon-size body-size key-size arrow-size size
    ][
        ;-- Measure the items to find the maximums
        ;
        ;   Two pass: First loop adjusts the height of items while collecting
        ;   information about their widths.
        ;   The second loop applies the maximas to align the detail faces.
        ;
        item-size: mark-size: icon-size: body-size: key-size: arrow-size: 0x0
        foreach item items [
            set [mark icon body key arrow] reduce bind [mark icon body key arrow] in item 'self  
            item-size/y: 0
            edge-size: edge-size? item
            
            if instance-of item 'menu-item [
                 mark-size: 16x16
                 icon-size: max  icon-size  icon/size: image-size? item/properties/item.icon.images/1                             ;-- Images need to be same size! I'm checking against icon image 1 only! 
    ;            body-size: max  body-size  body/size: max 6x4 + text-size? body image-size? item/properties/item.body.images/1   ;-- Images need to be same size! I'm checking against body image 1 only!
    
                 body-size: max  body-size  body/size:
                    max 
                        either body/text [6x4 + text-size? body] [0x0]
                        either item/properties/item.body.images/1 [
                            image-size? item/properties/item.body.images/1                       ;-- Images need to be same size! I'm checking against body image 1 only!
                        ][  
                            0x0
                        ]
                 
                 key-size: max   key-size   key/size: either key/text [6x4 + text-size? key] [0x0]  
                arrow-size: 16x16
                
                item/size/y: body/size/y: 
                key/size/y: first maximum-of reduce [
                    icon/size/y body/size/y key/size/y
                ] 
                 mark/size/y: arrow/size/y: 16
                item-size: first maximum-of reduce [icon-size body-size key-size] 
                
                 mark/offset/y: max item/size/y -  mark/size/y / 2 0
                arrow/offset/y: max item/size/y - arrow/size/y / 2 0
                 icon/offset/y: max item/size/y -  icon/size/y / 2 0 
            ]
            
            if instance-of item 'menu-divider [ ]                                                ;-- For now, dividers are somewhat static, so currently this is a no-op.   
            
            if instance-of item 'slider-item [
                body/size: item/slider/size
                item-size: first maximum-of reduce [icon-size body-size key-size] 
                body-size: max body-size 6x4 + item/slider/size 
            ]
            
            item/size/y: item/size/y + second edge-size? item   
        ]
        
        ;-- Apply those maximums to the smaller ones
        ;
        item-offset: 0x0 
        item-size/x: mark-size/x + icon-size/x + body-size/x + key-size/x + arrow-size/x + 2
        foreach item items [
            set [mark icon body key arrow] reduce bind [mark icon body key arrow] in item 'self  
            item/offset/y: item-offset/y
            item/size/x: item-size/x + first edge-size? item
            
            if instance-of item 'menu-item [
                mark/size/x: 16
                icon/size/x: icon-size/x
                body/size/x: body-size/x
                 key/size/x:  key-size/x   
               arrow/size/x: 16
                           
                mark/offset/x: 0
                icon/offset/x:  mark/offset/x + mark/size/x
                body/offset/x:  icon/offset/x + icon/size/x 
                 key/offset/x:  body/offset/x + body/size/x 
               arrow/offset/x:   key/offset/x +  key/size/x
                
                item/size/y: item/size/y + second edge-size? item  
            ]

            if instance-of item 'menu-divider [
                item/size/x: item-size/x 
                item/size/y: 5                                              ;-- This will change with dividers become arrow configurable
            ]

            if instance-of item 'slider-item [
                item/slider/offset/x: item/body/offset/x + 3
                item/slider/offset/y: item/body/size/y - item/slider/size/y / 2
            ]

            item-offset/y: item/offset/y + item/size/y
        ]
        item-size  
    ]
    
    ;############################################################ SLIDER-ITEM ##
    ;
    
    new-slider: func ["Returns an uninitialized slider item." /local slider] [
        make new-item [
            class: append class 'slider-item
            pane:  append pane slider: use [sld] [layout/tight [sld: slider 120x18] sld] 
        ]
    ]
    
    build-slider: func [
        "Builds a slider item."
        slider [object!]     "a new slider" 
        menu   [object!]     "the menu the slider resides in"
        word   [word! none!] "the slider's identifier"
        desc   [block!]      "the slider's description"
    /local
        sld
    ][
        build-item slider menu word desc
    ]
    
    ;################################################################### MENU ##
    ;

    ;============================================================== draw-knob ==
    ;    
    draw-knob: func [menu dir /local knob color y] [
        knob: select reduce ['less menu/less 'more menu/more] dir
        color: menu/properties/item.key.font/colors/1
        y: pick [[5 8] [8 5]] dir = 'less
        knob/effect: compose/deep [
            draw [
                pen (color) fill-pen (color)
                polygon
                    (as-pair knob/size/x / 2     y/1)
                    (as-pair knob/size/x / 2 - 3 y/2)
                    (as-pair knob/size/x / 2 + 3 y/2)
                    (as-pair knob/size/x / 2     y/1)
            ]
        ]
    ]
    
    ;============================================================== knob-feel ==
    ;
    knob-feel: make face/feel [
	    over: func [knob over? offset] [
            knob/rate: all [over? knob/parent-face/parent-face/properties/menu.rate]
            show knob                                                                                 ;************ Is this necessary? ***************
        ]
        engage: func [knob action event /local menu] [
            if event/type = 'time [
                menu: knob/parent-face/parent-face
                menu/feel/scroll menu knob
            ]
        ]
    ]
    
    
    ;============================================================ menu-access ==
    ;
    
    menu-access: make system/view/vid/vid-face/access [
    
        get-face: set-face: clear-face: reset-face: none                        ;-- I'd rather use these, but haven't the slightest idea of what
                                                                                ;   e.g. get-face menu should be used for. I therefore come with my own methods ...
                                                                                
        exec: func [                                                    
            "Sets or get item values (i.e. executes code in item's context)."  
            menu [object!]              "The menu to act on"
            path [path! word! integer!] "Path to an item anywhere down in the tree"  
            code [word! path! block!]   "Code executed in item's context"
        /local
            item 
        ][  
            if not block? code [code: reduce [code]]
            if      word? path [path: to path! path]
            if   integer? path [path: to path! path]
            
            item: first path: copy path
            item: either not error? try [to integer! item] [
                pick menu/list/pane to integer! item
            ][
                select menu/items to word! item
            ]
            either empty? head system/words/remove path [
                do bind :code in item 'self
            ][
                item/sub/access/exec item/sub path code
            ]
        ]
    
        insert: func [
            "Attaches an item into an existing menu."
            root   [object!]                    "The menu root"
            path   [path! word! integer! none!] "Path to an item to add to it's sub-menu"  
            entity [object!]                    "Menu or menu item already layouted"
        /head   "Add item at the head of the menu."
        /before "Inserts item before the specified successor." succ [word! object!]
        /after  "Inserts item after the specified predecessor" pred [word! object!]
        /tail   "Inserts item at the tail of the menu (default)."
        /as 
            var  [word! none!] "Word by which to refer to the item."   
        /local
            new menu items virtual
        ][
            menu: either path [root/access/exec root path [self/sub]] [root]
            
            menu/list/pane: case [
                head   [                  menu/list/pane     ]
                before [             find menu/list/pane succ: either object? succ [succ] [select menu/items succ]]
                after  [        next find menu/list/pane pred: either object? pred [pred] [select menu/items pred]]
            /default
                       [system/words/tail menu/list/pane     ]
            ]
            menu/items: case [
                head   [                  menu/items     ]
                before [        back find menu/items succ]    
                after  [        next find menu/items pred]
            /default
                       [system/words/tail menu/items     ]
            ]
            
            case [
                object! = type? entity [
                    case [
                        any [
                            instance-of entity 'menu-item 
                            instance-of entity 'menu-divider
                        ][
                            var: any [:var get in entity 'var]
                            system/words/insert menu/list/pane entity
                            system/words/insert menu/items reduce [var entity]
                            entity/menu: menu
                        ]
                        instance-of entity 'menu [
                            virtual: entity 
                            entity: virtual/access/remove virtual 1
                            
                            var: any [:var get in entity 'var]
                            system/words/insert menu/list/pane entity
                            system/words/insert menu/items reduce [var entity]
                            entity/menu: menu
                        ]
                    ]
                ]
                block! = type? entity [ "N/A" ]
            ]
            
            menu/list/pane: system/words/head menu/list/pane
            menu/items:     system/words/head menu/items
            
            adjust-menu menu
        ]
        
        remove: func [
            "Detaches an item from the menu and returns it."
            root [object!]              "The menu to remove from"
            path [path! word! integer!] "Path to an item anywhere down in the tree"  
        /local
            item 
        ][
            
            item: root/access/exec root path [self]
            system/words/remove           find item/menu/list/pane item
            system/words/remove/part back find item/menu/items     item 2
            item/menu: none
            item
        ]

        set 'get-menu func [
            "Returns a value of menu item."
            root [object!]              "The menu to act on"
            path [path! word! integer!] "Path to an item anywhere down in the tree"  
            word [word! path! block!]   "Word in item"            
        ][
            root/access/exec root path word
        ]
        
        set 'set-menu func [
            "Returns a value of menu item."
            root [object!]              "The menu to act on"
            path [path! word! integer!] "Path to an item anywhere down in the tree"  
            code [block!]               "Word: Value"            
        ][
            root/access/exec root path code
        ]
        
        set 'remove-menu func [
            "Detaches an item from the menu and returns it."
            root [object!]              "The menu to remove from"
            path [path! word! integer!] "Path to an item anywhere down in the tree"  
        ][
            root/access/remove root path
        ]
            
        set 'insert-menu func [
            [catch]
            "Attaches an item into an existing menu."
            root [object!]                    "The menu root"
            path [path! word! integer! none!] "Path to an item to add to it's sub-menu"  
            item [object!]                    "Menu item already layouted"
        /head   "Add item at the head of the menu."
        /before "Inserts item before the specified successor." succ [word! object!]
        /after  "Inserts item after the specified predecessor" pred [word! object!]
        /tail   "Inserts item at the tail of the menu (default)."
        /as 
            var  [word! none!] "Word by which to refer to the item." 
        ][
            var: any [:var get in item 'var]
            case [
                head    [root/access/insert/head/as   root path item var]
                before  [root/access/insert/before/as root path item var]
                after   [root/access/insert/after/as  root path item var]
               /default [root/access/insert/as        root path item var]
            ]
        ]
        
    ]
    
    ;========================================================= menubar-access ==
    ;
    
    menubar-access: make menu-access [

        super: menu-access

        remove: func [                                                          ;-- This change in the methods signature is to reflect the fact, that
            "Detaches an item (sub-item only) from the menu and returns it."    ;   adding menubar-items currently isn't possible 
            menubar [object!] "The menubar to remove from"
            path    [path!]
        ][
            menubar/access/super/remove menubar path                       
        ]
        
        insert: func [
            "Attaches an item into an existing menu."
            root [object!]                    "The menu root"
            path [path! word! integer! none!] "Path to an item to add to it's sub-menu"  
            item [object!]                    "Menu item already layouted"
        /head   "Add item at the head of the menu."
        /before "Inserts item before the specified successor." succ [word! object!]
        /after  "Inserts item after the specified predecessor" pred [word! object!]
        /tail   "Inserts item at the tail of the menu (default)."
        /as 
            var  [word! none!] "Word by which to refer to the item."   
        /local
            new menu items virtual
        ][
            if none? path [
                throw make error! "Inserting top-level items to menubars isn't implemented yet!"
            ]
                
            var: any [:var get in item 'var]
            case [
                head    [root/access/super/insert/head/as   root path item var]
                before  [root/access/super/insert/before/as root path item var]
                after   [root/access/super/insert/after/as  root path item var]
               /default [root/access/super/insert/as        root path item var]
            ]
        ]
    ]
    
    
    ;============================================================== menu-feel ==
    ;
    ;   The MENU-FEEL is the central method object for all menu related 
    ;   functions.
    ;
    ;   There are, for convience, some shorthands to them build directly into
    ;   menu objects. But users who use them should be aware of losing the
    ;   benefits of additional behaviour that comes with derived / overloaded
    ;   methods.
    ;
    
    menu-feel: make system/view/popface-feel-win-away [
        
        super: none

        redraw: func [
            "Draws a menu."
            menu [object!] offset [pair!]
        ][
            menu/panel/color:   menu/properties/menu.color
            menu/panel/effect:  menu/properties/menu.effect
            menu/panel/edge:    menu/properties/menu.edge
        ]
        
        
        inside-menu?: func [menu event] [
            within? event/offset win-offset? menu menu/size
        ]
        
        inside-menu-tree?: func [menu event] [
            any [
                menu/feel/inside-menu? menu event
                all [
                    menu/parent
                    menu/feel/inside-menu-tree? menu/parent/menu event
                ]
            ]
        ]
        
        pop-detect: func [menu event] [
            case [
                menu/feel/inside-menu-tree? menu event [
                    if find [down up move time key alt-down alt-up scroll-line] event/type [
                        event
                    ]
                ]
                true [
                    either not find [up move time scroll-line key] event/type [
                        menu: menu/feel/root-of menu
                        menu/feel/close menu
                    ][
                        event
                    ]
                ]
            ]
        ] 

        close: func [                                                           ;-- CLOSE actually impements a custom HIDE-POPUP, if you like, call it a hack.
            "Closes a menu (and all of it's items' sub-menus)."                 ;   I simply couldn't cope with that one.
            menu [object!]
        /local                                                                  ;-- NO-SHOW hinders multiple window refreshing closing nested menus. 
            /no-show                                                            ;   Hidden, callers shouldn't have to care about that.                                                                     
        ][
            if all [menu/actor menu/actor/sub] [
                menu/actor/sub/feel/close/no-show menu/actor/sub                ;-- MENU/ACTOR/SUB may have a different FEEL
                                                                                ;   (even though, for now, none are implemented).
            ]
            if find system/view/pop-list menu [
                unfocus menu                                                                                                     ;   
                remove find menu/parent-face/pane menu                          ;-- Most likely to be a window, but I hope it can also be another non-menu popup :-)    
                remove find system/view/pop-list menu
                menu/actor: none
                unless no-show [show menu/parent-face]
            ]
            if menu/parent [focus/no-show menu/parent/menu]
        ]
        
        visit: func [                                                           ;-- Visiting items may require revealing these items, which definitly is 
            "Visits menu item, making it the new actor."                        ;   a job under responsibility of menus. 
            menu [object!] item [object!]                                       ;   Hence visiting items is implemented here instead on item level only.
        ][ 
            if menu/actor <> item [
                menu/feel/leave menu                                                     
                menu/feel/reveal menu item 
                menu/actor: item
                item/feel/visit item
            ]
        ]
        
        leave: func ["Leaves menu actor, if any." menu [object!] /local item] [ ;-- Leaving an item should never be called explicitly, since it's done
            if item: menu/actor [                                               ;   implicitly by visiting another
                menu/actor: none
                item/feel/leave item                                            ;-- Only if there was an actor, there is a item to leave (and to redraw).
            ]
        ]
        
        root-of: func ["Returns menu's root menu." menu] [
            forever [
                if none? menu/parent [break/return menu]
                menu: menu/parent/menu
            ]
            
        ]
        
        first-of: func ["Returns first item." menu [object!]] [
            foreach item menu/list/pane [
                if instance-of item 'menu-item [break/return item]
            ]
        ]

        prev-page-of: func ["Returns previous item." menu [object!] /local extra other] [
            
            extra: any [menu/actor menu/feel/last-of menu]                           
            
            foreach item next find reverse copy menu/list/pane extra [          ;-- This results in other being the last visble item or
                if instance-of item 'menu-item [                                     ;   none, if extra itself is the last visible one.
                    if     menu/feel/visible? menu item [other: item]
                    if not menu/feel/visible? menu item [break/return other]
                ]
            ]
            
            either other [
                other                                                           ;-- Returns first item on page
            ][
                menu/actor: extra
                while [
                    all [
                        menu/actor <> menu/feel/first-of menu
                        menu/feel/visible? menu extra
                    ]
                ][
                    menu/feel/visit  menu menu/feel/prev-of menu
                ]
                menu/actor
            ]                                             
        ]
        
        next-page-of: func ["Returns next item." menu [object!] /local extra other] [
            
            extra: any [menu/actor menu/feel/first-of menu] 
            
            foreach item next find menu/list/pane extra [                       ;-- This results in other being the last visble item or
                if instance-of item 'menu-item [                                     ;   none, if extra itself is the last visible one.
                    if     menu/feel/visible? menu item [other: item]
                    if not menu/feel/visible? menu item [break/return other]
                ]
            ]
            
            either other [
                other                                                           ;-- Returns last item on page
            ][
                menu/actor: extra
                while [
                    all [
                        menu/actor <> menu/feel/last-of menu
                        menu/feel/visible? menu extra
                    ]
                ][
                    menu/feel/visit  menu menu/feel/next-of menu
                ]
                menu/actor
            ] 
        ]
        
        prev-of: func ["Returns previous item." menu [object!] /wrap "Wrap at menu's top."] [
            either none? menu/actor [
                menu/feel/last-of menu
            ][
                any [
                    foreach item next find reverse copy menu/list/pane menu/actor [
                        if instance-of item 'menu-item [break/return item]
                    ]
                    either wrap [menu/feel/last-of menu] [menu/feel/first-of menu]
                ]
            ]
        ]
        
        next-of: func ["Returns next item." menu [object!] /wrap "Wrap at menu's top."] [
            either none? menu/actor [
                menu/feel/first-of menu
            ][
                any [
                    foreach item next find menu/list/pane menu/actor [
                        if instance-of item 'menu-item [break/return item]
                    ]
                    either wrap [menu/feel/first-of menu] [menu/feel/last-of menu]
                ]
            ]
        ]

        next-char-of: func [
            "Returns next item starting with char (or NONE)." 
            menu [object!] char [char!] /local items
        ][
            items: either menu/actor [
                items: next find menu/list/pane menu/actor
                append copy items copy/part menu/list/pane items
            ][
                menu/list/pane
            ]
            foreach item items [
                if all [
                    instance-of item 'menu-item
                    item/body/text
                    equal? uppercase char uppercase item/body/text/1
                ][ 
                    break/return item
                ]
            ]
        ]
        
        last-of: func ["Returns menu's last item." menu [object!]] [
            foreach item reverse copy menu/list/pane [
                if instance-of item 'menu-item [break/return item]
            ]
        ]

        visible?: func ["Returns TRUE if is fully visible." menu [object!] item [object!]] [
            not any [
                menu/list/offset/y + item/offset/y < 0                                  ;-- Item is (partially) above the clipping region 
                menu/list/offset/y + item/offset/y + item/size/y > menu/clip/size/y     ;-- Item is (partially) below the clipping region
            ]
        ]

        show-less?: func [menu [object!]] [menu/list/offset/y < 0]
        show-more?: func [menu [object!]] [menu/list/offset/y + menu/list/size/y > menu/panel/size/y]
        hide-less?: func [menu [object!]] [menu/list/offset/y >= - menu/less/size/y]
        hide-more?: func [menu [object!]] [menu/list/offset/y + menu/list/size/y <= (menu/clip/size/y + menu/more/size/y)]
        show-less: func  [menu [object!]] [
            if not menu/less/show? [
                menu/clip/offset/y: menu/clip/offset/y + menu/less/size/y
                menu/clip/size/y:   menu/clip/size/y   - menu/less/size/y
                menu/list/offset/y: menu/list/offset/y - menu/less/size/y
                show menu/less
            ]
        ]
        show-more: func [menu [object!]] [
            if not menu/more/show? [
                menu/clip/size/y: menu/clip/size/y - menu/more/size/y
                show menu/more
            ]
        ]
        hide-less: func [menu [object!]] [
            if menu/less/show? [
                menu/clip/offset/y: menu/clip/offset/y - menu/less/size/y       ;-- Move clip to top and
                menu/clip/size/y:   menu/clip/size/y   + menu/less/size/y       ;   grow it.
                menu/less/rate: none
                hide menu/less
            ]
        ]
        hide-more: func [menu [object!]] [
            if menu/more/show? [
                menu/clip/size/y: menu/clip/size/y + menu/more/size/y           ;-- Grow clip.
                menu/list/offset/y: menu/list/offset/y + menu/more/size/y
                menu/more/rate: none
                hide menu/more
            ]
        ]
        
        scroll: func [menu [object!] knob [object!]] [
            case [
                menu/less = knob [
                    menu/list/offset/y: menu/list/offset/y + menu/steps
                    menu/feel/show-more menu
                    if menu/feel/hide-less? menu [menu/feel/hide-less menu]
                ]
                menu/more = knob [
                    menu/list/offset/y: menu/list/offset/y - menu/steps
                    menu/feel/show-less menu
                    if menu/feel/hide-more? menu [menu/feel/hide-more menu]
                ]
            ]                        
            show menu/panel
        ]
    
        reveal: func [
            "Reveals the item (by scrolling the smallest amount necessary)." 
            menu [object!] item [object!]
        /no-show
            "Don't show the changes."
        /local
            delta clip list
        ][
            delta: 0x0 clip: menu/clip list: menu/list
            
            if any [
                if 0 > delta/y:   list/offset/y
                                + item/offset/y [                               ;-- Item is (maybe only partially) above the clipping region 
                    menu/feel/show-more menu
                    list/offset/y: list/offset/y - delta/y
                    if menu/feel/hide-less? menu [menu/feel/hide-less menu]
                    true
                ]
                if 0 < delta/y:   list/offset/y 
                                + item/offset/y 
                                + item/size/y 
                                - clip/size/y [                                 ;-- Item is (maybe onle partially) below the clipping region   
                    menu/feel/show-less menu
                    list/offset/y: list/offset/y - delta/y
                    if menu/feel/hide-more? menu [menu/feel/hide-more menu]
                    true
                ]
            ][
                if not no-show [show menu/panel]
            ]
        ]              
        
        map-key: func [
            "Returns mapped EVENT/KEY."
            menu [object!] event [event!] /local key
        ][
            key: event/key
            if event/control [
                key: any [select [up page-up home home down page-down end end] key key]   ;-- Control key increases key effect.
            ]
            key
        ]
            
        engage: func [menu action event /local actor item key] [
            if event/type = 'key [
                actor: menu/actor  
                key:   menu/feel/map-key menu event
                
                case [
                    'right = key [
                        if all [actor actor/sub] [
                            actor/feel/enter/new actor 
                            item: actor/sub/feel/first-of actor/sub
                            item/menu/feel/visit item/menu item
                            wait []
                        ]
                    ]
                    #" "       = key  or 
                   (#"^M"      = key) [
                        if actor [
                            either actor/sub [
                                actor/feel/enter actor
                            ][
                                actor/feel/engage actor 'up event
                            ]
                        ]
                    ]
                    escape     = key  or
                   ('left      = key) or 
                   ('backspace = key) [menu/feel/close menu]
                    'home      = key  [menu/feel/visit menu menu/feel/first-of     menu]
                    'page-up   = key  [menu/feel/visit menu menu/feel/prev-page-of menu]
                    'up        = key  [menu/feel/visit menu menu/feel/prev-of/wrap menu]
                    'down      = key  [menu/feel/visit menu menu/feel/next-of/wrap menu]
                    'page-down = key  [menu/feel/visit menu menu/feel/next-page-of menu]
                    'end       = key  [menu/feel/visit menu menu/feel/last-of      menu]
                    /default [
                        use [item] [if item: menu/feel/next-char-of menu key [menu/feel/visit menu item]] 
                    ]
                ]
            ]
        ]
    ]
    
    
    ;=========================================================== menubar-feel ==
    ;
    ;   The MENUBAR-FEEL remaps cursor keys a bit to adjust them to the needs
    ;   of horizontally layouted menubar-items.
    ;
    
    menubar-feel: make menu-feel [
        super: menu-feel
        detect: func [menubar event][
            menubar/feel/super/pop-detect menubar event
        ]
        redraw: none
        close: func [menubar] [
            if menubar/actor [
                if menubar/actor/sub [
                    menubar/actor/sub/feel/close menubar/actor/sub
                ]
                menubar/feel/leave menubar
                menubar/state: 'click-to-enter
                unfocus
            ]
        ]
        reveal: none
        next-page-of: :last-of
        prev-page-of: :first-of
        map-key: func [                                                         ;** Overwriting feel/super/map-key, menubars behave different than menus. Hack?
            "Returns mapped EVENT/KEY."
            menu [object!] event [event!] /local key
        ][
            key: any [
                select [left up up right down right] event/key
                event/key
            ]
            if event/control [
                key: any [select [up page-up home home down page-down end end] key key]   ;-- Control key increases key effect.
            ]
            key
        ]
        pop-detect: none
        over: none
        reveal: none
    ]

    ;=============================================================== new-menu ==
    ;
    new-menu: func ["Returns an uninitilized menu."] [
        make system/view/vid/vid-face [
            class: make block! [menu]
            flags: [field]

            feel:   menu-feel
            access: menu-access
            
            color: edge: data: groups: properties: parent: actor: none
            
            steps: 4                                                            ;-- Dialect this!
                                                              
            items: make block! []                                               ;-- ITEMS holds the menu's items, the block consits
                                                                                ;   of ID / ITEM pairs for easy selection of items. Get rid of that!
            
            shadow: panel: less: clip: list: more: none                         ;-- Accessors for the various sub-faces of a menu.
                                                                                ;   The actual items are to be found in LIST's pane,
            pane: reduce [                                                      ;   but clients should use ITEMS.  
                shadow: make face  [
                    color: edge: none
                    image: shadow-image
                    effect: [extend alphamul 32]
                ]
                panel: make face  [
                    color: none
                    edge: none
                    effect: none
                    pane: reduce [
                        less: make face [color: edge: none feel: knob-feel]
                        clip: make face [
                            color: edge: none
                            pane: reduce [
                                list: make face [color: edge: none pane: make block! []]
                            ]
                        ]
                        more: make face [color: edge: none feel: knob-feel]
    ]   ]   ]   ]   ]
    
    ;============================================================= build-menu ==
    ;
    build-menu: func [
        "Builds a menu and it's sub-faces."
        item [object! none!] "the menu's parent item or NONE"
        desc [block!]        "the menu description" 
    /local
        menu parent
    ][
        menu:        new-menu 
        menu/parent: item
        menu/data:   desc
        
        menu/properties: either parent: all [menu/parent menu/parent/menu/properties] [
            context [
                menu.image:        parent/menu.image    
                menu.effect:       parent/menu.effect   
                menu.spacing:      parent/menu.spacing  
                menu.edge:         parent/menu.edge     
                menu.rate:         parent/menu.rate     
                menu.color:        parent/menu.color        
                item.action:       parent/item.action   
                item.effects:      parent/item.effects  
                item.colors:       parent/item.colors   
                item.icon.images:  none                                         ;-- no inheritence
                item.icon.effects: none                                         ;
                item.body.images:  none                                         ;
                item.body.font:    parent/item.body.font
                item.key.font:     parent/item.key.font 
                item.body.para:    parent/item.body.para
                item.key.para:     parent/item.key.para 
                item.edge:         parent/item.edge     
            ]
        ][
            context [
                menu.image:        none
                menu.effect:       [gradient 1x1 white silver]
                menu.spacing:      2x2
                menu.edge:         make system/standard/face/edge [size: 2x2 color: silver effect: 'bevel]
                menu.rate:         64
                menu.color:        white
                item.action:       none
                item.effects:      reduce [none [gradient 1x1 white 255.64.64] none [gradient 1x1 white silver]]
                item.colors:       reduce [none silver none none]
                item.icon.images:  none
                item.icon.effects: none                              
                item.body.images:  none
                item.body.font:    make system/standard/face/font [offset: 2x0 align: 'left valign: 'center colors: reduce [black black gray gray] shadow: none]
                item.key.font:     make system/standard/face/font [offset: 2x0 align: 'left valign: 'center colors: reduce [black black gray gray] shadow: none]
                item.body.para:    make system/standard/face/para [origin: 5x2 margin: indent: 0x0 wrap?: no]
                item.key.para:     make system/standard/face/para [origin: 5x2 margin: indent: 0x0 wrap?: no]
                item.edge:         make system/standard/face/edge [size:   2x2 colors: reduce [none 255.192.192 none none] effects: reduce [none 'ibevel none 'ibevel]]
            ]
        ]
        
        menu
    ]
    

    ;============================================================ layout-menu ==
    ;
    set 'layout-menu func [
        "Returns a menu (face) built from style/content description dialect."
        desc [block!] "Dialect block of styles, attributes, and layouts"
    /parent
        "Bind menu to an item as it's sub-menu."
        item [object!] "A menu-item face"
    /style
        "Base menu on existing style sheet."
        sheet [block!] "A style sheet of menu and item styles."
    /local
        menu value properties         
        mark-size icon-size body-size key-size arrow-size
        item-offset item-size size                        
    ][
        menu: build-menu item desc      
        properties: menu/properties
        
        if style [insert desc sheet]                              ;-- Include the stylesheet applied and then
                                                                           ;   go and look for style refinements      
        
        menu/panel/edge: menu/properties/menu.edge
        menu/panel/color: menu/properties/menu.color
        menu/panel/image: menu/properties/menu.image 
        
        parse desc [                                                            
            any [
                'menu 'style some [
                    'color set value [word! | tuple!] (
                        properties/menu.color: cast value [
                            word!  [get value]
                            tuple! [value]
                        ]
                    )
                |   'spacing set value [integer! | pair!] (
                        properties/menu.spacing: to pair! value
                    )
                |   'edge set value ['none | none! | block!] ( 
                        if any [none? value 'none = value] [value: [size: 0x0]]
                        properties/menu.edge: make properties/menu.edge value
                    )
                |   ['backdrop | 'image] set value [word! | file! | image!] (
                        properties/menu.image: cast value [
                            word!  [get value]
                            file!  [load value]
                            image! [value]           
                        ]
                    )
                |   'effect set value ['none | none! | word! | lit-word! | block!] (
                        if any [none? value 'none = value] [value: none]
                        properties/menu.effect: all [value compose [(value)]] 
                    )
                ]
            |   'item 'style some [
                    'colors set value ['none | none! | block!] (
                        if any [none? value 'none = value] [value: []]
                        properties/item.colors: reduce value
                    )
                |   'effects set value ['none | none! | block!] (
                        if any [none? value 'none = value] [value: []]
                        properties/item.effects: compose [(value)]
                    )
                |   'font set value [block!] (
                        properties/item.body.font: make properties/item.body.font value
                        properties/item.key.font:  make properties/item.key.font  value
                    )
                |   'para set value [block!] (
                        properties/item.body.para: make properties/item.body.para value
                        properties/item.key.para:  make properties/item.key.para  value
                    )
                |   'body [
                        'font set value [block!] (
                            properties/item.body.font: make properties/item.body.font value
                        )
                    |   'para set value [block!] (
                            properties/item.body.para: make properties/item.body.para value
                        )
                    ]
                |   'key [
                        'font set value [block!] (
                            properties/item.key.font: make properties/item.key.font value
                        )
                    |   'para set value [block!] (
                            properties/item.key.para: make properties/item.key.para value
                        )
                    ]
                |   'edge set value ['none | none! | block!] (
                        if any [none? value 'none = value] [value: [size: 0x0]]
                        properties/item.edge: make properties/item.edge value                      
                    )
                |   'action set value block! (
                        properties/item.action: value
                    )
                ]
            ]
            desc:
            to end
        ]
        
        layout-items menu desc
        menu/list/pane: head menu/list/pane
        
        menu
    ]        
    
    
    ;============================================================ adjust-menu ==
    ;
    ;   ADJUST-MENU calculates all values (offsets and such) that are subject
    ;   to change between to shows of the menu.
    ;
    ;   COMMENT: Currently, the responsibilities of ADJUST-MENU and SHOW-MENU aren't defined very clear, 
    ;    here's room for improvements.
    ;
    
    adjust-menu: func ["Adjusts the menus size and returns its size." menu [object!]] [
        menu/panel/edge:  menu/properties/menu.edge
        menu/panel/image: menu/properties/menu.image
        
        adjust-items menu/list/pane
    ]
    
    
    ;############################################# PUBLIC INTERFACE FUNCTIONS ##
    ;
    
    ;============================================================== show-menu ==
    ;
    ;   The SHOW-MENU actually does all the work of showing a previously set up
    ;   menu. Client scripts that only use MENUBAR and/or DROP-MENU don't
    ;   need to call this, they just LAYOUT-MENU their menus and feed those
    ;   VID-Styles with them.
    ;
    
    set 'show-menu func [
        "Shows a menu."
        window [object!]
        menu [object!]
    /offset                                                                     ;-- This is of use only for top-level menus, positions of further nested
        "Prescribes where to open the menu."                                    ;   menu are calculated automatically depending of WIN-OFFSET of the parent item
        at [pair!]                                                              ;   they're bound to.
    /size
        "Restrict menu's size"
        max-size [pair!]
    /new
        "Opens a new window and returns immediately."                           ;-- Works like in VIEW.
    /local   
        value
        item divider item-offset menu-size shadow-size   
    ][
        shadow-size: 4x4                                                        ;-- For now, prescribe that shadows have to be 4x4 pixels wide!
          max-size: any [max-size window/size]  
          menu-size: adjust-menu menu
        
        menu/less/size: menu/more/size: 1x0 * menu-size/x + 0x12                ;-- Preparation of the less- and more-knobs, we'll may need them.
        draw-knob menu 'less                                                    ; 
        draw-knob menu 'more                                                    ;   This is somewhat strange, but may it be.
        
        menu/list/offset: 0x0                                                   ;-- Let's see how big the menu want's to be get.
        menu/list/size:   second span? menu/list/pane                           ;
        menu/clip/size/x: menu/list/size/x
        menu/panel/offset: menu/shadow/offset: 0x0
        menu/less/offset: menu/clip/offset: menu/more/offset: menu/properties/menu.spacing
        
        either menu/list/size/y                                                 ;-- If it's bigger than it's allowed to get,
             + (second edge-size? menu/panel)                                   ;   we need the more button            
             + (2 * menu/properties/menu.spacing/y) 
             + shadow-size/y
             > max-size/y [
            menu/less/show?: not menu/more/show?: yes
            menu/clip/size/y:    max-size/y                                    ;-- of course this is only correct for offset/y = 0 and max-size/y = window/size/y
                               - (second edge-size? menu/panel)
                               - (2 * menu/properties/menu.spacing/y) 
                               - shadow-size/y
        ][
            menu/less/show?: menu/more/show?: no
            menu/clip/size/y: menu/list/size/y
        ]   

        menu/more/offset/y: menu/clip/offset/y + menu/clip/size/y
        
        menu/panel/size: (2 * menu/properties/menu.spacing) + menu/clip/size + edge-size? menu/panel
        if menu/less/show?   [menu/panel/size/y: menu/panel/size/y + menu/less/size/y] 
        if menu/more/show? [menu/panel/size/y: menu/panel/size/y + menu/more/size/y] 
        
        menu/shadow/size: menu/panel/size + shadow-size                          
        
        at: any [                                                               ;-- Calculating offset: Where are we supposed to open?
            at                                                                  ;    
            if menu/parent [                                                    ;   If caller made no suggestion, we position the menu at the right edge
                at: win-offset? menu/parent                                     ;   vertically centered with the actor.
                at/x: at/x + menu/parent/size/x                                 ;
                if menu/parent/menu/edge [                                      
                    at/x: at/x + menu/parent/menu/edge/size/x
                ]
                if menu/panel/edge [
                    at/y: at/y - menu/panel/edge/size/y
                ]
                at/y: at/y + (menu/parent/size/y - menu/list/pane/1/size/y / 2)
                at/y: max 0 at/y
                at
            ]
            0x0
        ]
        menu/size: menu/shadow/size 
        
        if at/x + menu/size/x > window/size/x [                                 ;-- Right border check --
            either menu/parent [
                at/x: max 0 at/x - menu/panel/size/x - menu/parent/size/x
            ][
                at/x: max 0 window/size/x - menu/size/x
            ]
        ]
        if at/y + menu/size/y > window/size/y [                                 ;-- Bottom border check --
            at/y: max 0 window/size/y - menu/size/y
        ]
        if at/y + menu/size/y > window/size/y [                                 ;-- Size check, again --
            menu/size/y: menu/shadow/size/y: window/size/y
            menu/panel/size/y: menu/size/y - 4
            menu/clip/size/y: menu/panel/size/y - 4 - menu/more/size/y
            menu/more/show?: yes
            menu/more/offset/y: menu/clip/size/y
        ] 
        menu/offset: at
        
        show-popup/window/away menu window                                      ;-- Finally, let's start the show 
        focus/no-show menu
        unless new [wait []]
    ]

    
    ;############################################################# VID-Styles ##
    ;

    ;=============================================================== MENU-BAR ==
    ;
    ;   The VID-style MENU-BAR. Supports easy integration of menus into a 
    ;   VID layout.
    ;
    ;   Regarding customization: MENU-BAR is, by it's nature, available for
    ;   styling through the usual VID dialect.
    ;
    ;   Whereas menubar-items currently are not!
    ;
    ;   But doing the menubar/properties/menubar.foo
    ;   and           menuitem/properties/menuitem.bar thing here, too,
    ;   should work just fine.
    
    stylize/master [
        menu-bar: face with [
            flags: [field]
            class: make block! [menu-bar]
            parent: none
            data: none
            state: 'click-to-enter
            sheet: none
            list:  self                                                         ;-- To make all the menu/list/pane paths from menubar/feel/super/... work.
            set: get: func [                                                    ;-- Updating e.g. text of menubar-items is problematic, but it would be useful for e.g. disabling these                                          
                "Set or get item values (executes code in item's context)."  
                path [path! word!]  "Path to an item anywhere down in the tree"  
                code [block!] "Code executed in item's context"
            /local
                item
            ][  
                item: select items first path: to path! :path
                either empty? next path [
                    do bind :code in item 'self
                    show item
                ][
                    item/sub/set next path :code
                ]
            ]
            colors: reduce [none 178.180.191]
            font: make font [name: "Tahoma" size: 14 color: black offset: space: 0x0 shadow: none]
            color: none edge: none actor: none items: none
            words: [
                menu       [new/data:  first next args next args]
                menu-style [new/sheet: first next args next args]
            ]
            init: [
                pane:  copy []
                list:  self                                                     ;** To make all the menu/list/pane paths from menubar/feel/super/... work. Hack?
                items: copy []
                feel:   ctx-menus/menubar-feel 
                access: ctx-menus/menubar-access 
                if all [sheet data] [insert data sheet]
                use [value menu-bar specs item item-offset actor specs] [
                    menu-bar: self
                    parse data [
                    
                        copy specs to set-word! (specs: any [specs copy []])
                        
                        some [
                            set value set-word! 'item (
                                insert tail pane item: make new-item [
                                    item:   self
                                    class:  append class 'menu-item
                                    menu:   menu-bar
                                    var:    to word! value
                                    font:   menu-bar/font
                                    para:   make system/standard/face/para [
                                        origin: 5x4 margin: none wrap?: no
                                    ]
                                    feel:   ctx-menus/baritem-feel
                                ]
                                insert tail menu-bar/items reduce [item/var item]
                            )
                        
                            any [
                                set value string! (
                                    item/text: value
                                )
                            |   'menu set value block! (
                                    item/data: insert value specs 
                                    item/sub: layout-menu value
                                    item/sub/parent: item                       ;-- Is this hack potentially dangerous? 
                                )
                            ]
                            
                        ]
                    ]
                    
                    item-offset: 0x0
                    foreach item pane [
                        item/size: add text-size? item edge-size? item
                        if all [item/para item/para/origin] [
                            item/size: item/size + (2 * item/para/origin)
                        ]
                        item-offset: item/size + item/offset: 1x0 * item-offset
                    ]
                    
                ]
                size: add second span? pane edge-size? self
            ]
            multi: make multi [
                file: func [face blk] [
                    if pick blk 1 [
                        face/data: load first blk
                    ]
                ]
            ]
        ]
    ]
      
    ;============================================================== DROP-MENU ==
    ;
    ;   Much like menu-bars, but different in that the DROP-MENU actually is
    ;   nothing but a shorthand for binding a menu to a button, with the
    ;   one speciality that it auto-inserts the chosen items body-text
    ;   into the containing field.
    ;
    ;   The insertion is done in the item's action block, hence, DROP-MENU
    ;   is currently still experimental, as it would be difficult if possible
    ;   for clients to modify that behaviour.
    ;
    
    stylize/master [
        drop-menu: field with [
            style: none
            size: 100x21 
            font: make face/font [offset: 2x6 colors: reduce [black black] name: "Tahoma" size: 14 align: 'left]
            edge: make face/edge [size: 1x1 effect: none color: 178.180.191]
            para: make face/para [wrap?: no margin: 22x5]
            feel: make feel [
                redraw: func [face act pos] bind [
                    if all [in face 'colors block? face/colors] [
                        face/color: pick face/colors face <> focal-face
                    ] 
                    if all [in face/font 'colors block? face/colors] [
                        face/font/color: pick face/font/colors face <> focal-face
                    ]
                ] in system/view 'self
                engage: func [face act event] bind [
                    switch act [
                        down [
                            either equal? face focal-face [unlight-text] [focus/no-show face] 
                            caret: offset-to-caret face event/offset 
                            show face
                        ] 
                        over [
                            if not-equal? caret offset-to-caret face event/offset [
                                if not highlight-start [highlight-start: caret] 
                                highlight-end: caret: offset-to-caret face event/offset 
                                show face
                            ]
                        ] 
                        key [
                            either event/key = 'down [
                                face/pane/action
                            ][    
                                ctx-text/edit-text face event get in face 'action
                            ]
                        ]
                    ]
                ] in system/view 'self
            ]
            menu: none
            words: [
                menu [new/data: first next args next args]
                menu-style [new/style: first next args next args]
            ]
            init: [
                if all [style data] [insert data style]
                use [anchor parent] [
                    
                    parent: anchor: self
                    if not string? text [text: either text [form text] [copy ""]] 
                    colors: reduce [white yellow + 64.64.64] 
                    pane: make-face/spec 'btn [
                        effect: [extend 14 draw [pen 0.0.0 fill-pen 0.0.0 polygon 5x7 11x7 8x10]]
                        size: 17x17
                        offset: 1x0 * parent/size - 20x-1
                        set in parent 'menu layout-menu parent/data
                        action: [
                            unfocus
                            show-menu/offset find-window parent parent/menu (win-offset? parent) + (0x1 * parent/size) - 1x2
                        ]
                    ]
                ]
            ]
        ]
        
    ]

]

