pageextension 73102 wpVoucherEntryExt extends "LSC Voucher Entries"
{
    layout
    {
        addlast(Control1200070000)
        {
            field("Voucher ID"; Rec."Voucher Id")
            {
                ApplicationArea = All;
            }
        }
    }
}