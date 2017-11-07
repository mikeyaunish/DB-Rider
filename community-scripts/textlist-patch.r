REBOL [
    Title: "Korrigiert Text-list, Demo"
    Date: 27-Jan-2001/23:39:17+1:00
    Name: "text-list'"
    Version: 0.9
    File: %textlist-patch1.r
    Home: http://jove.prohosting.com/~screbol/
    Author: "volker"
    Owner: "volker"
    Rights: "gpl"
    Needs: [view 0.10.38]
    Tabs: none
    Usage: none
    Purpose: none
    Comment: none
    History: [27-Jan-2000 ""]
    Language: "german"
]
patched: context [
    l: last-shown-lines: styles: text-list': update-slider:
    none
    [
    ]
    [
        %tlp2.r
    ]
    styles: stylize [
        text-list': text-list with [
            "add size-change scrolling"
            last-shown-lines: -1
            update-slider: does [
                either 0 = length? data [sld/redrag 1] [
                    sld/redrag lc / length? data]
            ]
            append init [
                sub-area/feel/redraw: does [
                    l: length? data
                    if l <> last-shown-lines [
                        last-shown-lines: l
                        update-slider
                    ]
                ]
            ]
            "leere liste erlauben."
            words/data:
            func [new args] [
                if not empty? second args [
                    new/text: first new/texts: second args
                ]
                next args
            ]
        ]
    ]
]
