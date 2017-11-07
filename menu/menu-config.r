rebol []

do %menu-system.r

menu-data: []

winxp-menu: layout-menu/style copy menu-data winxp-style: [
    menu style edge [
        size: 1x1 color: 178.180.191 effect: none]
        color white
        spacing 2x2 
        effect none
        item style font [name: "font-sans-serif" size: 14 colors: reduce [black black silver silver]]
        colors [none 187.183.199] 
        effects none
        edge [size: 1x1 colors: reduce [none 178.180.191] effects: []]
        action [print item/body/text]
]

 
