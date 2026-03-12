page 73104 wpVoucherItemDiscStp
{
    Caption = 'Voucher Item Discount Setup';
    PageType = ListPart;
    SourceTable = wpVoucheritemdiscstp;

    layout
    {
        area(Content)
        {
            repeater(VoucherItemDisc)
            {
                ShowCaption = false;
                field("Voucher ID"; Rec."Voucher ID")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the voucher discount type.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the voucher discount type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the voucher discount type.';
                }
                field(Exclude; Rec.Exclude)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the discount is excluded from the voucher type.';
                }
            }
        }
    }
}