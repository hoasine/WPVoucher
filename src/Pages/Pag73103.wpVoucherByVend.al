
page 73103 wpVoucherVendor
{
    Caption = 'Voucher By Vendor';
    PageType = ListPart;
    SourceTable = wpVoucherVendor;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Voucher ID"; Rec."Voucher ID")
                {
                    Caption = 'Voucher ID';
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor No.';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the vendor who eligible for voucher budget.';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        Rec.CalcFields("Vendor Name");
                    end;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies the name of the vendor who eligible for voucher budget.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the staff vendor allowance budget.';
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