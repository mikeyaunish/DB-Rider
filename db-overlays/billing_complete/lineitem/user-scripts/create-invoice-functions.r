REBOL [
    Title: "create-invoice" 
    Date: 28-Mar-2017 
    Name: "create-invoice.r" 
    Author: "Mike Yaunish" 
    File: %create-invoice.r 
    Version: 1.0 
    Purpose: {DB-Rider select script. For database:billing and table:lineitem}
]

invoice-header: does [ rejoin [ {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>} page-name {</title>
<style type="text/css">
<!--
body,td,th {
	font-family: Arial, Helvetica, sans-serif;
	font-size: small;
}
tt {
	font-family: "Courier New", Courier, mono;
	font-size: 13px;
}
.pagebreak {
	page-break-after: always;
}
-->
</style></head>
<body>
}]
]

invoice-footer: {</body></html>}

word-count: func [ haystack [string!]  needle [string!] /local count findpos ] [
    count: 0
    find-pos: haystack
    while [ found? find-pos: find find-pos needle ] [
        ++ count
        find-pos: next find-pos
    ]
    return count
]

company-data: [
    home-country "Canada"
    gst-number 1234
]

get-hardware-details: func [ line-item-detail /local quote-no part-no remove-it ][
    quote-no: 0
    part-no: ""
    details: ""
    remove-it: func [source removing /local a ] [
        if found? ( a: find source removing ) [
            remove/part (skip source ((index? a) - 1)) length? removing
        ]
        return source
    ]
    if found? (a: find line-item-detail "Q:") [ quote-no: to-integer (first parse ( skip a 3 ) none) ]
    if found? (b: find line-item-detail "PN:") [ part-no: first parse ( skip b 3 ) none ]
    details: remove-it line-item-detail rejoin [ "Q: " quote-no ]
    details: remove-it details rejoin [ "PN: " part-no ]
    return reduce [ 'quote-no quote-no 'part-no part-no 'details details ]
]


get-rate-for-task: func [ task-name comment /local consult-rate ] [
    consult-rate: 0
    switch/default task-name [
        "Hardware" [
            hard-details: get-hardware-details comment
            if any [ ( hard-details/quote-no = 0) (hard-details/part-no = "") (hard-details/details = "" ) ] [
                 request/ok rejoin [ "Problem with HARDWARE line item comments. quote-no = " hard-details/quote-no " part-no = " hard-details/part-no "details = " hard-details/details ]
                 return [-1]
            ]
            rec-no: db-select %quote/ compose [ number = (hard-details/quote-no) and part-no = (hard-details/part-no) ]
            either ((length? rec-no ) = 1) [
                record: db-pick %quote rec-no/1
                return reduce [ 'sell record/sell 'ship record/shipping-handling 'part-no hard-details/part-no 'comment ( trim hard-details/details ) ]
            ][ ; This should handle multiple misses as well - some how?? ****
                request/ok rejoin [ "Hardware quote NOT found. Quote = " hard-details/quote-no " Part No. = " hard-details/part-no ]
                return [-1]
            ]
        ]
        "none" [
            request/ok "A billing rate of 0 has been indicated by the timesheet line item."
            return [0] 
        ]

    ][ ; DEFAULT
           if ( found? consult-rate: find/tail task-name "Consult" ) [ return reduce [to-integer consult-rate] ]
    ]
    return [-1] ; This is for an unknown rate
]



get-invoice-info: func [ timesheet-record ] [
    return-value: copy []
    append return-value reduce [ 'invoice-date now/date ]
    append return-value "none"
    append return-value reduce [ 'ship-to-needed false ] ; **** Prompt for this info as well. ****
    return-value
]

blank-line-item: {<tr VALIGN=TOP>
                <td ALIGN=CENTER>&nbsp;</td>
                <td ALIGN=CENTER>&nbsp;</td>
                <td ALIGN=LEFT>&nbsp;  </td>
                <td ALIGN=RIGHT>&nbsp; </td>
                <td ALIGN=RIGHT>&nbsp; </td>
                </tr>
}

to-money-number: func [the-value /with ] [
    if the-value = "" [ return "" ]
    return replace to-string to-money the-value "$" ""
]

set-invoice-status: func [ invoice-number /printed /posted ] [
    if pending [
        db-append invoice-db [ invoice-number 1-Jan-2001 1-Jan-2001 "printed" ]
        return
    ]
    if posted [
        to-change-row-id: db-pick invoice-db [ number = invoice-number ]
        either ( ( length? to-change-row-id ) = 1 ) [
            db-change invoice-db ( first to-change-row-id ) [ status = "posted" ]
        ][
            request/ok "ERROR: Problem changing status of invoice to 'posted', records ={" mold to-change-row-id "}"
            return
        ]
    ]
]

create-invoice: func [
    report-db rec-ids
    /with-ship-to  ; **** This flag will be automatically set if any Hardware is in any line-items ****
    /local  invoice-line-items line-count-for-page

][

    client-data-filename: join report-db/get-user-scripts-path %client-data.dblock
    invoices-data-filename: join report-db/get-user-scripts-path %invoices.datr
    invoice-directory: join report-db/get-user-scripts-path %printed-invoices/    
    the-date: 1 the-year: 2 the-month: 3 the-day: 4 the-client: 5 the-project: 6 the-task: 7 the-hours: 8 the-minutes: 9 the-duration: 10 the-chargeable: 11 the-description: 12 the-row-id: 13
    recreate: false
    tax-rate: .05 
    if rec-ids = [] [
       return none
    ]	 
    timesheet-line-items: copy []
    foreach i rec-ids [
        append/only timesheet-line-items first report-db/run-sql/return-block rejoin [ "Select * from lineitem WHERE ID = " ( i ) ]
    ]        

    the-msg: copy ""
    over-written-invoices: copy []
    
    current-ids: copy []
    line-items-already-invoiced: copy []
    company-list: copy []
    existing-invoices: copy []
    foreach line-item-to-chk timesheet-line-items [
       if (line-item-to-chk/Invoice = none) [ line-item-to-chk/Invoice: 0 ] 
       if (line-item-to-chk/Invoice <> 0)  [
           the-msg: rejoin [ the-msg  line-item-to-chk/ID ", " ]
    	   append over-written-invoices line-item-to-chk/Invoice 
    	   append/only current-ids  line-item-to-chk/ID
    	   append/only line-items-already-invoiced reduce [ line-item-to-chk/ID line-item-to-chk/Invoice ]
    	   append company-list line-item-to-chk/Company 
       ]	    	    
    ]
    company-list: unique company-list
    if ((length? company-list) > 1) [
        request/ok "More than one company has been selected - unable to create a valid invoice"
        return none
    ]
    if (current-ids <> []) [
        recreate: true
        prefix-msg: "Line item:"
        verb: " is "
        if ((length? line-items-already-invoiced) > 1 ) [
            prefix-msg: "Line items:"
            verb: " are "
        ]
        over-written-invoices: unique over-written-invoices
        ans: my-request/buttons rejoin [ prefix-msg current-ids verb "already ^/allocated to invoice #:" over-written-invoices "^/If you continue the existing invoice will be cancelled.^/Do you want to continue to create a new invoice?" ] "  Cancel  "
        either not ( ans = "OK" ) [ 
            return none 
        ][
            existing-invoices: copy []
            foreach i line-items-already-invoiced [
                    append existing-invoices i/2 
                ]
            existing-invoices: unique existing-invoices 
            if ((length? existing-invoices) > 1 ) [
                a: my-request/buttons rejoin [ "Warning! More than one existing invoice number is being cancelled.^/The following invoice numbers will be affected^/" existing-invoices "^/Do you still want to continue?" ] " Cancel "
                if not (a = "OK") [
                    return none
                ]
            ]
            foreach i existing-invoices [
                sql-cmd: rejoin [ {update invoicestatus set Status ='Cancelled', Timestamp ='} get-timestamp {'  WHERE InvoiceNo ='} i {'} ] 
                report-db/run-sql sql-cmd               
            ]
        ]
    ]	    

    sample-lineitem: first report-db/run-sql/return-block rejoin [ "Select * from lineitem WHERE ID = " (first rec-ids) ]
    
    invoice-info: get-invoice-info sample-lineitem ; **** This should be modified to handle multiple Customers ****
    
    company: first report-db/run-sql/return-block rejoin [ "Select * from company WHERE ID = " (sample-lineitem/Company) ]

    printed-account-number: company/ID
    printed-invoice-date: invoice-info/invoice-date
    
	report-db/run-sql  rejoin [ {insert into invoice values ('','} "0" {','} company/ID {')} ] 
	the-invoice-no: first first report-db/run-sql { select LAST_INSERT_ID() } ; determine the ID inserted   	    
	
	printed-invoice-number: the-invoice-no
	   
	page-ending-no-pagebreak: [ {<center><u><font size=+1>Thank you for your patronage</font></u></center><br><u><font size=+1></font></u>} ]
	page-ending-with-pagebreak: [ {<center><u><font size=+1>Thank you for your patronage</font></u></center><br class="pagebreak"></font></u>} ]
	
    a: report-db/create-new-record "invoicestatus"
    last-insert-id: a
    
    either recreate [
        new-status: "Re-Created"
        foreach cancelled-inv-num over-written-invoices [
            u: run-sql-cmd rejoin [ {UPDATE invoicestatus SET `Status` = 'Cancelled' WHERE InvoiceNo = } cancelled-inv-num ]    
        ]        
    ][
        new-status: "Created"    	
    ]	    	    
    sql-cmd: rejoin [ {update invoicestatus set Status ='} new-status {' WHERE ID ='} a {'} ]
    b: report-db/run-sql sql-cmd
    
    u: run-sql-cmd rejoin [ {UPDATE invoicestatus SET InvoiceNo = '} the-invoice-no {' WHERE ID = } last-insert-id ]
	u: run-sql-cmd rejoin [ {UPDATE invoice SET status = '} last-insert-id {' WHERE ID = } the-invoice-no ] 
 
    printed-salesperson: ""
    
    printed-salesperson: "&nbsp;"       
    
    printed-gst-number: to-string company-data/gst-number
    printed-sold-to-info: copy ""
    printed-ship-to-info: copy ""
    BRK: "<br>" ; Short form? for HTML break
    SPACE-BRK: "&nbsp;<br>"
    
    bill-address: report-db/run-sql/return-block rejoin [ "Select * from address WHERE ID = " ( company/BillAddress ) ]
    either ( bill-address <> [] ) [
        bill-address: first bill-address 
    ][
        my-request rejoin [ {There is no billing address defined for the^/company named:'} company/Name {'.^/The invoice can not be created.} ]
        return none
    ]
    contact-id: first report-db/run-sql/return-block rejoin [ "Select MainContact from company where ID = " company/id ]
    either(contact-id/MainContact) [
        contact-person: first report-db/run-sql/return-block rejoin [ "Select * from person WHERE ID = " ( contact-id/MainContact ) ]
    ][
        contact-person: ""
    ]
    

    append printed-sold-to-info rejoin [ "Attn: " contact-person/FirstName " " contact-person/LastName BRK ]
    append printed-sold-to-info rejoin [                      company/Name BRK ]
    append printed-sold-to-info rejoin [                  bill-address/Street1 BRK ]
    if (bill-address/street2 > "") [ append printed-sold-to-info rejoin [ bill-address/Street2 BRK ] ]
    
    append printed-sold-to-info rejoin [ bill-address/City ", " bill-address/StateProv BRK ]
    append printed-sold-to-info rejoin [ bill-address/PostalCode BRK ]
    
    
    if bill-address/Country <> company-data/home-country [
        append printed-sold-to-info rejoin [ bill-address/Country BRK ]
    ]
    
    
      
    either any [(company/ShipAddress = 0) (company/ShipAddress = none) ] [
    	ship-address: "same"
    ][   	    
        ship-address-id: first report-db/run-sql/return-block rejoin [ "Select * from address WHERE ID = " ( company/ShipAddress ) ]               
        
        ship-address-id: ship-address-id/id 
    	ship-address: first report-db/run-sql/return-block rejoin [ "Select * from address WHERE ID = " ship-address-id ]               	    
        
        append printed-ship-to-info rejoin [ "Attn: " contact-person/FirstName " " contact-person/LastName BRK ]
        append printed-ship-to-info rejoin [                     company/name BRK ]
        if (ship-address/street2 > "") [ append printed-ship-to-info rejoin [ ship-address/Street2 BRK ] ]
        append printed-ship-to-info rejoin [ ship-address/City ", " ship-address/StateProv BRK ]
        append printed-ship-to-info rejoin [ ship-address/PostalCode BRK ]
        if  ship-address/Country <> company-data/home-country [
            append printed-ship-to-info rejoin [ bill-address/Country BRK ]
        ]
    ][
        printed-ship-to-info: "Same <br>"; Use the <br> to keep track of lines.
    ]
    
    number-of-sold-to-lines: word-count printed-sold-to-info BRK
    number-of-ship-to-lines: word-count printed-ship-to-info BRK
    spare-lines: copy ""
    insert/dup spare-lines SPACE-BRK (7 - number-of-ship-to-lines )
    append printed-ship-to-info spare-lines
    spare-lines: copy ""
    insert/dup spare-lines SPACE-BRK (7 - number-of-sold-to-lines )
    append printed-sold-to-info spare-lines
    physical-lines-this-page: 0
    max-line-items-per-page: 18  
    data-line-ratio: .9047 ; The amount of a full line extra text takes up 
    invoice-line-items: [ "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ] ; maximum number of pages.(20)
    line-count-for-page: array/initial 40 0 ; maximum number of pages.(40)
    for i 1 40 1 [  
        change at line-count-for-page i 0
    ]
    invoice-line-items/1: copy ""
    invoice-line-items/2: copy ""
    invoice-line-items/3: copy ""

    subtotal: 0
    
    page-number: 1
    chars-per-line-for-qty: 10         ; These specify how many chars. make a full line for this column.
    chars-per-line-for-item: 12
    chars-per-line-for-description: 55 
    last-page-number: 1
    the-line-item-list: copy []
    
    line-item-cnt: 0 ; *** Just for testing ***
    printed-payment-terms: copy "Payment due upon receipt."
    printed-po-number: {&nbsp}
    po-numbers: copy []
    
    check-for-po: func [ the-item ]  [
		the-product: first report-db/run-sql/return-block rejoin [ "Select * from item WHERE ID = " ( the-item/Item ) ]
		if the-product/PoNo > "" [
			append po-numbers the-product/PoNo
		]
	]	    
    
    
    foreach line-item timesheet-line-items [
        the-duration: copy ""
        the-date: copy ""
        the-description: copy ""
        
        the-client: copy company/Name
        ++ line-item-cnt
        the-description: copy line-item/Description
        
        the-item: first report-db/run-sql/return-block rejoin [ "Select * from item WHERE ID = " ( line-item/Item ) ]
        item-type: first report-db/run-sql/return-block rejoin [ "Select * from itemtype WHERE ID = " ( line-item/Type ) ]
        
   		switch/default item-type/name [
			"Service" [ ; service
				print-item: copy (to-string to-date line-item/Date)
				the-description: copy  line-item/Description
		   	]
		   	"Product" [ 
		   		print-item: copy the-item/PartNo
		   		the-description: copy line-item/Description
		   		check-for-po line-item
		   	]
		   	"Quote" [ 
		   		print-item: copy the-item/PartNo				   	   	    
		   		the-description: copy line-item/Description
		   	    check-for-po line-item
		   	]
		   	"Shipping" [
		   	    print-item: copy the-item/PartNo				   	   	    
		   		the-description: copy line-item/Description
		   	]
		   	"Terms" [
		   	   printed-payment-terms: copy line-item/Description
		   	   
		   	]	    
		][
			my-request rejoin [ {Problem with the lineitem with ID number ="} id-num {".^/ Lineitem type of: "} lineitem-type {" is invalid} ]
		]	    	    	
        the-duration-value: to-decimal line-item/Quantity
        the-unit-price: to-decimal the-item/price

        
        either item-type/Name <> "Service" [
            duration-postfix: copy ""
        ][
            either the-duration-value = 1 [
                duration-postfix: copy " Hr."
            ][
                duration-postfix: copy " Hrs."
            ]
        ]
        the-duration: copy rejoin [ to-string the-duration-value duration-postfix ]
        
        qty-line-count: split-string-on-spaces/with the-duration chars-per-line-for-qty "<br>"
        item-line-count: split-string-on-spaces/with the-date  chars-per-line-for-item "<br>"
        description-line-count: split-string-on-spaces/with the-description chars-per-line-for-description "<br>"
        
        lines-added: max qty-line-count ( max item-line-count description-line-count)
        new-lines-added: 1
        if (lines-added > 1) [
            new-lines-added: 1 + (( lines-added - 1) * data-line-ratio )
        ]
        
        if ( line-count-for-page/:page-number + new-lines-added  ) > max-line-items-per-page [
            ++ page-number
        ]
        change at line-count-for-page page-number ( line-count-for-page/:page-number + ( lines-added * data-line-ratio )  )
        
        
        line-item-total: ( the-unit-price * the-duration-value )
        subtotal: subtotal + line-item-total

        if (item-type/Name <> "Terms") [
            append invoice-line-items/:page-number to-string reduce [
                {
                    <tr VALIGN=TOP>
                    <td ALIGN=CENTER> } the-duration                    {</td>
                    <td ALIGN=CENTER> } print-item                      {</td>
                    <td ALIGN=LEFT>   } the-description                     {</td>
                    <td ALIGN=RIGHT>  } to-money-number the-unit-price  {</td>
                    <td ALIGN=RIGHT>  } to-money-number line-item-total {</td>
                    </tr>
                }
            ]
            append the-line-item-list line-item/ID
        ]
		u: run-sql-cmd rejoin [ {UPDATE lineitem SET Invoice = '} the-invoice-no {' WHERE ID = } line-item/id ]        
        
    ] ; *************  End of line-item loop
    

    printed-subtotal: ""
    printed-gst: ""
    printed-total-cost: ""

    printed-shade-colour: "DDDDDD"
    invoice-template: load  join report-db/get-user-scripts-path %rebol-invoice-template2.html
    printed-invoice-line-items: copy ""
    printed-po-number: copy ""
    page-name: rejoin [ "Invoice_" the-invoice-no ]
    all-pages: invoice-header
    total-pages: page-number - 1 
    if ((length? po-numbers) > 0 ) [
    	foreach i po-numbers [
    	   append printed-po-number rejoin [ to-string i "," ]
    	]	    
    	remove back tail printed-po-number ; remove last extra comma
    ]	
    
    ; Process all pages before the last page (if there are any)
    for the-page-number 1 total-pages  1 [ ; fix any short pages because lines wouldn't fit on page.
        printed-page-numbers: rejoin reduce [ (the-page-number) " of " (total-pages + 1 ) ]
        blank-lines-needed: to-integer ( max-line-items-per-page - line-count-for-page/:the-page-number )
        for i 1 blank-lines-needed 1 [ append invoice-line-items/:the-page-number blank-line-item ]
        printed-invoice-line-items: copy invoice-line-items/:the-page-number
        append all-pages reduce invoice-template
        append all-pages reduce page-ending-with-pagebreak
    ]
	printed-page-numbers: rejoin reduce [ (total-pages + 1 ) " of " (total-pages + 1 ) ]
	

    printed-subtotal: subtotal  
    printed-gst: gst: round/at ( printed-subtotal * tax-rate ) 2
    
    printed-total-cost: subtotal + to-decimal gst 

    blank-lines-needed: to-integer ( max-line-items-per-page - line-count-for-page/:page-number )
    for i 1 blank-lines-needed 1 [ append invoice-line-items/:page-number blank-line-item ]
    printed-invoice-line-items: copy invoice-line-items/:page-number
    append all-pages reduce invoice-template
    append all-pages reduce page-ending-no-pagebreak
    append all-pages invoice-footer

    
    
    target-file-name: to-file rejoin [ invoice-directory page-name ".html" ]
    write target-file-name all-pages
    
    return target-file-name 
    
]

