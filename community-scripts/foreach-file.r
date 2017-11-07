;; ====================================================
;; Script: foreach-file.r
;; downloaded from: www.REBOL.org
;; on: 8-Sep-2017
;; at: 15:07:15.310337 UTC
;; owner: rebolek [script library member who can update
;; this script]
;; ====================================================
REBOL [
	Title: "Foreach-file"
        File: %foreach-file.r
	Author: "Rebolek"
	Date: 20-6-2006
	Version: 1.0.2
        Purpose: "Perform function on each file in selected directory recursively"
    History: [
        Version 1.0.3 { 9/14/2017 Modified by Mike Yaunish - added /file-extension }
        Version 1.0.4 { 9/17/2017 Modified by Mike Yaunish - added /only }
    ]
	library: [
		level: 'beginner
		platform: 'all
		type: [function tool]
		domain: [shell]
		tested-under: [View 1.3.2 on WinXP]
		license: 'public-domain
		support: none
        ]
] 

foreach-file: func [
	"Perform function on each file in selected directory recursively"
	dir [file! url!] "Directory to look in"
	act [function!] "Function to perform (filename is unput to fuction)"
	/file-extension ext-filter
	/directory "Perform function also on directories"
	/only "Do not follow subdirectories"
	/local f files
][
	files: attempt [read dir] 
	either none? files [return][
		foreach file files [
			f: join dir file 
			either dir? f [
				if directory [
					act f 
				]
				if (not only) [
    				either file-extension [
    				    foreach-file/directory/file-extension f :act ext-filter
    				][
    				    foreach-file/directory f :act    
    				]
    		    ]
			][
			    either file-extension [
    	            if find/last f ext-filter [
    				    act f     
    		        ]
    		    ][
    		        act f
    		    ]
			]
		]
	]
]

;Example
Comment [
    file-func: func [file][? file]
    foreach-file %./ :file-func
    foreach-file/file-extension %./ :file-func ".txt"
]
