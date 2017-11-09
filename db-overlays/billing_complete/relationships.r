[
    source-table "company" 
    source-field "BillAddress" 
    target-table "address" 
    target-field "ID" 
    human-readable-target-field ["Street1" "City"] 
    field-requester-prompt "Select an address"
] [
    source-table "company" 
    source-field "MainContact" 
    target-table "person" 
    target-field "ID" 
    human-readable-target-field ["FirstName" "LastName"] 
    field-requester-prompt "select a person"
] [
    source-table "company" 
    source-field "ShipAddress" 
    target-table "address" 
    target-field "ID" 
    human-readable-target-field ["Street1" "City"] 
    field-requester-prompt "Select an address"
] [
    source-table "inventory" 
    source-field "item" 
    target-table "item" 
    target-field "ID" 
    human-readable-target-field ["Description"] 
    field-requester-prompt "Select an item"
] [
    source-table "invoice" 
    source-field "Company" 
    target-table "company" 
    target-field "ID" 
    human-readable-target-field ["Name"] 
    field-requester-prompt "Select a company"
] [
    source-table "invoice" 
    source-field "Status" 
    target-table "invoicestatus" 
    target-field "ID" 
    human-readable-target-field ["Status" "Timestamp"] 
    field-requester-prompt "Select a status"
] [
    source-table "item" 
    source-field "Company" 
    target-table "company" 
    target-field "ID" 
    human-readable-target-field ["Name"] 
    field-requester-prompt "Select a company"
] [
    source-table "item" 
    source-field "Type" 
    target-table "itemtype" 
    target-field "ID" 
    human-readable-target-field ["Name"] 
    field-requester-prompt "Select an item type"
] [
    source-table "lineitem" 
    source-field "Company" 
    target-table "company" 
    target-field "ID" 
    human-readable-target-field ["Name"] 
    field-requester-prompt "Select a company"
] [
    source-table "lineitem" 
    source-field "Invoice" 
    target-table "invoice" 
    target-field "ID" 
    human-readable-target-field ["ID"] 
    field-requester-prompt "Select an item"
] [
    source-table "lineitem" 
    source-field "Item" 
    target-table "item" 
    target-field "ID" 
    human-readable-target-field ["Description"] 
    field-requester-prompt "Select an item"
] [
    source-table "lineitem" 
    source-field "Type" 
    target-table "itemtype" 
    target-field "ID" 
    human-readable-target-field ["Name"] 
    field-requester-prompt "Select an item type"
] [
    source-table "person" 
    source-field "Address" 
    target-table "address" 
    target-field "ID" 
    human-readable-target-field ["Street1" "City"] 
    field-requester-prompt "Select an address"
] [
    source-table "person" 
    source-field "Company" 
    target-table "company" 
    target-field "ID" 
    human-readable-target-field ["Name"] 
    field-requester-prompt "Select a company"
]
