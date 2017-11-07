rebol []

REBOL [
    Title: "disable face"
    Date: 12-Dec-2001/7:23:24+1:00
    Version: 1.0.0
    File: %disable-face.r
    Author: "Volker Nitsch"
    Usage: "see demo"
    Purpose: "disable and enable face"
    Email: nitsch-lists@netcologne.de
    Web: http://www.escribe.com/internet/rebol/index.html?by=OneThread&t=%5BREBOL%5D%20Changing%20VID%20Styles
    todo: "seperate handling of field/info"
]
disable-face: func [face' /local style offset size pane color font para text data image effect ] [
    if 'disabler = face'/parent-face/style [return]
    change find face'/parent-face/pane face' (
        make-face/spec get-style 'image [
            style: 'disabler
            offset: face'/offset size: face'/size
            pane: reduce [
                face'
                make system/words/face [
                    size: face'/size
                    color: font: para: text: data: image: none
                    effect: [ merge contrast -50 ]
                ]
            ]
        ]
    )
    face'/offset: 0x0
    show face'/parent-face
]
enable-face: func [face'] [
    if 'disabler <> face'/parent-face/style [return]
    face': face'/parent-face
    face'/pane/1/offset: face'/offset
    change find face'/parent-face/pane face' face'/pane/1
    show face'/parent-face
]
