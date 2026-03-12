page 73105 wpVoucherMember
{
    Caption = 'Voucher Member Setup';
    PageType = ListPart;
    SourceTable = MemberVoucher;

    layout
    {
        area(Content)
        {
            repeater(MemberVoucherSetup)
            {
                ShowCaption = false;
                field("Voucher ID"; Rec."Voucher ID")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Member Club"; Rec."Member Club")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the voucher Member Club.';
                }
                field("Member Scheme"; Rec."Member Scheme")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the voucher Member Scheme.';
                }
                field("Total value"; Rec."Total value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the voucher Total value.';
                }
                field("Voucher Amount"; Rec."Voucher Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the discount is excluded from the Voucher Amount.';
                }
                field("Receipt Qty"; Rec."Receipt Qty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the voucher Receipt Qty.';
                }
                field("Max Voucher Qty"; Rec."Max Voucher Qty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the discount is excluded from the Max Voucher Qty.';
                }
            }
        }
    }
}