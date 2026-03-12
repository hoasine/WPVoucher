page 73106 "Voucher Budget List"
{
    ApplicationArea = All;
    Caption = 'Voucher Budget List';
    PageType = List;
    SourceTable = "wpVoucherBudget";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Voucher ID';
                    ToolTip = 'Specifies the ID for voucher maintenance.';
                    // Visible = false;
                    Enabled = false;

                    trigger OnAssistEdit()
                    begin
                        If Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Budget Amount"; Rec."Budget Amount")
                {
                    ApplicationArea = All;
                }
                field("Budget Status"; Rec."Budget Status")
                {
                    ApplicationArea = All;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = All;
                }
                field("Email Approve"; Rec."Email Approve")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        // area(Creation)
        // {
        //     group(Staff)
        //     {
        //         Caption = 'Staff';
        //         Visible = EnableAULocalization;
        //         action("BinSetup")
        //         {
        //             ApplicationArea = All;
        //             Caption = 'Staff list';
        //             Image = Setup;
        //             RunObject = Page "LSC Staff List";
        //             // RunPageLink = "Tender Type Code" = field(Code);
        //         }

        //     }
        // }
        // area(Promoted)
        // {
        //     group(Category_Process)
        //     {
        //         actionref(BinSetup_Promoted; BinSetup)
        //         {
        //         }
        //     }
        // }
    }
}

