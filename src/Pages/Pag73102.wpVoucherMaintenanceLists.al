namespace worldpos.Voucher.Document;

using Microsoft.Foundation.NoSeries;
using worldpos.Voucher.Configuration;
using System.Text;
using Microsoft.Utilities;

page 73102 wpVoucherMaintenanceLists
{
    AdditionalSearchTerms = 'wp,voucher,budget,maintenance,setup,allowance';
    ApplicationArea = Basic, Suite;
    Caption = 'Voucher Maintenances';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = wpVoucherMaintenance;
    UsageCategory = Lists;
    SourceTableView = order(descending);
    DataCaptionFields = ID, Description;
    CardPageId = wpVoucherMaintenanceCard;
    Editable = false;
    PromotedActionCategories = 'New,Process,Reports,Setup';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Voucher ID';
                    ToolTip = 'Specifies the ID for voucher maintenance.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the voucher allowance.';
                }
                // field("Applicable For"; Rec."Applicable For")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Applicable For';
                //     ToolTip = 'Specifies the type of the voucher that applicable for.';
                // }
                // field("Identification Type"; Rec."Identification Type")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Identification Type';
                //     ToolTip = 'Specifies the type of identification for the voucher.';
                // }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which the allowance budget is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date to which the allowance budget is valid';
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


                // field("Member Type"; Rec."Member Type")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Member Type';
                // }
                // field("Member Value"; Rec."Member Value")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Member Value';
                // }
                // field("Receipt Qty"; Rec."Receipt Qty")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Receipt Qty';
                // }
                // field("Total value"; Rec."Total value")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Total value';
                // }
                // field("Max Voucher Qty"; Rec."Max Voucher Qty")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Max Voucher Qty';
                // }
            }

        }
    }

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

}