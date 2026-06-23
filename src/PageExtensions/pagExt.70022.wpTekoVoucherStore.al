pageextension 70022 wpTekoVoucherStore extends "LSC Store Card"
{
    layout
    {
        addbefore("Numbering")
        {
            group("Voucher Integration")
            {
                field("Voucher Service URL"; Rec."Voucher Service URL")
                {
                    ApplicationArea = All;
                    Caption = 'Voucher Service URL';
                }
            }
        }
    }
}