pageextension 73103 wpSalesReceivablesSetup extends "Sales & Receivables Setup"
{
    layout
    {
        addbefore("Number Series")
        {
            group("Taka Voucher Setup")
            {
                Caption = 'Taka Voucher Setup';
                field("Voucher ID Nos."; Rec."Voucher ID Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to voucher maintenance.';
                }
                field("VBudget ID Nos."; Rec."VBudget ID Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to VBudget.';
                }
                field("Quantity Exchange of Day"; Rec."Quantity Exchange of Day")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to Quantity Exchange of day.';
                }

                field("Voucher GL Date"; Rec."Voucher GL Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to Voucher GL Date.';
                }
                field("Redeemp Same Member"; Rec."Redeemp Same Member")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Allow same member card redemption';
                }
            }
        }
    }
}