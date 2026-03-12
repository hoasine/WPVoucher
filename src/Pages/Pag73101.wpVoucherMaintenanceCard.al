namespace worldpos.Voucher.Document;

using worldpos.Voucher.Configuration;

page 73101 wpVoucherMaintenanceCard
{
    AdditionalSearchTerms = 'wp,voucher,taka,maintenance,setup';
    Caption = 'Voucher Maintenance Setup';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = wpVoucherMaintenance;
    SourceTableView = sorting(ID);
    DataCaptionFields = ID;
    PromotedActionCategories = 'New,Process,Reports,Navigate';

    layout
    {
        area(Content)
        {
            Group(General)
            {
                Caption = 'General';
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Voucher ID';
                    ToolTip = 'Specifies the ID for voucher maintenance.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        If Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the voucher allowance.';
                    Importance = Promoted;
                }
                // field("Applicable For"; Rec."Applicable For")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Applicable For';
                //     ToolTip = 'Specifies the type of the voucher that applicable for.';

                //     trigger OnValidate()
                //     begin
                //         checkApplicable();
                //     end;

                // }
                // field("Identification Type"; Rec."Identification Type")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Identification Type';
                //     ToolTip = 'Specifies the type of identification for the voucher.';
                // }

                group(Period)
                {
                    field("Validation Period ID"; Rec."Validation Period ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Validation Period ID';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the period for which the voucher is valid.';
                        trigger OnValidate()
                        begin
                            Rec.CalcFields("Starting Date", "Ending Date");
                        end;
                    }
                    field("Validation Description"; Rec."Validation Description")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Validation Description';
                        ToolTip = 'Specifies the description of the validation period for the voucher.';
                        Importance = Additional;
                    }
                    field("Starting Date"; Rec."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the allowance budget is valid.';
                        Importance = Promoted;
                    }
                    field("Ending Date"; Rec."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the allowance budget is valid';
                        Importance = Promoted;
                    }
                }
                field("Tender Type Code"; Rec."Tender Type Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tender Type';
                    ToolTip = 'Specifies the tender type code for the staff budget.';
                }
                field("Tender Type Description"; Rec."Tender Type Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tender Type Description';
                    ToolTip = 'Specifies the tender type description for the staff budget.';
                }
                field("Voucher Budget ID"; Rec."VoucherBudgetID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Voucher Budget ID';
                    ToolTip = 'Specifies the period for which the voucher is valid.';
                }
                field("Enable Tracking"; Rec."Enable Tracking")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tracking Required';
                    ToolTip = 'Specifies whether tracking is required for the voucher.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the voucher is enabled.';
                }
            }

            Part(wpVoucherMember; wpVoucherMember)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Member Setup';
                SubPageLink = "Voucher ID" = field(ID);
                UpdatePropagation = Both;
            }

            // Part(wpVoucherVendor; wpVoucherVendor)
            // {
            //     ApplicationArea = Basic, Suite;
            //     Caption = 'Vendor Setup';
            //     SubPageLink = "Voucher ID" = field(ID);
            //     UpdatePropagation = Both;
            // }
            // Part(wpVoucherRoleLines; wpVoucherRoleLines)
            // {
            //     ApplicationArea = Basic, Suite;
            //     Caption = 'Allowance';
            //     SubPageLink = "Voucher ID" = field(ID), "Date Filter" = field("Date Filter");
            //     UpdatePropagation = Both;
            //     Visible = isStaff;
            // }
            part(wpVoucheritemdiscstp; wpVoucheritemdiscstp)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Setup';
                SubPageLink = "Voucher ID" = field(ID);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(MSRPrefixSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'LSC Voucher Entries';
                Image = CreditCard;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "LSC Voucher Entries";
                ToolTip = 'LSC Voucher Entries';
            }
        }
    }

    // trigger OnAfterGetRecord()
    // begin
    //     checkApplicable();
    //     CurrPage.Update(false);
    // end;

    // trigger OnOpenPage()
    // begin
    //     checkApplicable();
    //     CurrPage.Update(false);
    // end;

    // local procedure checkApplicable()
    // begin
    //     if Rec."Applicable For" = Rec."Applicable For"::Staff then
    //         isStaff := true;

    //     if Rec."Applicable For" = Rec."Applicable For"::Member then
    //         isStaff := false;
    // end;

    // var
    //     isStaff: Boolean;
}