namespace worldpos.Voucher.Configuration;
using System.Security.AccessControl;
using System.Security.User;

page 73100 wpVoucherSetup
{
    AdditionalSearchTerms = 'wp,voucher,allowance,setup';
    ApplicationArea = Basic, Suite;
    Caption = 'Voucher Setup';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = wpVoucherSetup;
    UsageCategory = Administration;
    PromotedActionCategories = 'New,Process,Reports,Navigate';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the voucher setup is enabled.';
                }
            }
            group("Number Series")
            {
                Caption = 'Number Series';
                field("Voucher ID Nos."; Rec."Voucher ID Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to voucher maintenance.';
                }
                field("VBudget ID Nos."; Rec."VBudget ID Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to voucher maintenance.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(Staff)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Voucher Entries';
                Image = Employee;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "LSC Voucher Entries";
                RunPageMode = View;
                ToolTip = 'Voucher Entries';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}