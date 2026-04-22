table 73102 "Taka Voucher Group Buffer"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Brand"; Code[50]) { }
        field(2; "Bill Value"; Decimal) { }
        field(3; "Voucher Qty"; Decimal) { }
    }

    keys
    {
        key(PK; "Brand") { Clustered = true; }
        key(BillValue; "Bill Value") { }
    }
}