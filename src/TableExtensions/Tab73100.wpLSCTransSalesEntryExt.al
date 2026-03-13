tableextension 73107 LSCTransSalesEntryExt extends "LSC Trans. Sales Entry"
{
    fields
    {
        field(50100; "Voucher Status Temp"; Enum "Voucher Status")
        {
            Caption = 'Item Voucher Status Temp';
            DataClassification = CustomerContent;
        }
        field(50101; "Voucher Status"; Text[100])
        {
            Caption = 'Voucher Status';
            DataClassification = CustomerContent;
        }
        field(50102; "Voucher ID"; Code[20])
        {
            Caption = 'Voucher ID';
            DataClassification = CustomerContent;
        }
    }
}