REBOL [
    Title: "Win-offset?"
    Date: 20-May-2003
    Version: 0.0.1
    File: %win-offset.r
    Author: "Romano Paolo Tenca"
    Purpose: {Patch for win-offset? and screen-offset?. Standard functions don't add edge sizes}
    Email: rotenca@libero.it
    Web: http://www.rebol.it/~romano
    Category: [3 vid view]
]
win-offset?: func [
    {Given any face, returns its window offset. Patched by Ana}
    face [object!]
    /window-edge
    /local xy
][
    xy: 0x0
    if face/parent-face [
        xy: face/offset
        while [face: face/parent-face][
            either face/parent-face [
                xy: xy + face/offset + either face/edge [face/edge/size][0]
            ][
                if window-edge [xy: xy + either face/edge [face/edge/size][0]]
            ]
        ]
    ]
    xy
]
screen-offset?: func [
    {Given any face, returns its screen absolute offset. Patched by Ana}
    face [object!]
    /local xy
][
    xy: face/offset
    while [face: face/parent-face][
        xy: xy + face/offset + either face/edge [face/edge/size][0]
    ]
    xy
]
                                         
