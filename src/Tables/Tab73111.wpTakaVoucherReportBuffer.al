table 73111 "Taka Voucher Report Buffer"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Sheet Type"; Enum "Taka Voucher Sheet Type") { }
        field(2; "Line No."; Integer) { }
        field(3; "Entry Code"; Code[20]) { }
        field(4; "Row Date"; Date) { }
        field(5; "Expire Date"; Date) { }
        field(6; "Brand"; Code[50]) { }
        field(7; "Trans No"; Integer) { }
        field(8; "POS Terminal"; Text[100]) { }
        field(9; "Bill Value"; Decimal) { }
        field(10; "Voucher Qty"; Decimal) { }
    }

    keys
    {
        key(PK; "Sheet Type", "Line No.", "Row Date") { Clustered = true; }
    }
}