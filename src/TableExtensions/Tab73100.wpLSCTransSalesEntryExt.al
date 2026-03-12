tableextension 73107 LSCTransSalesEntryExt extends "LSC Trans. Sales Entry"
{
    fields
    {
        field(50100; "Voucher Status"; Enum "Voucher Status")
        {
            Caption = 'Item Status';
            DataClassification = CustomerContent;
        }
    }
}