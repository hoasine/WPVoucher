namespace worldpos.Voucher.Configuration;

using worldpos.Voucher.Document;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Document;

table 73106 wpVoucherBudget
{
    Caption = 'Voucher Budget';
    // DrillDownPageId = wpVoucherMaintenanceCard;
    // LookupPageId = wpVoucherMaintenanceCard;
    LookupPageID = "Voucher Budget List";
    DataClassification = ToBeClassified;
    DataCaptionFields = ID;

    fields
    {
        field(1; ID; Code[20])
        {
            Caption = 'Voucher Budget ID';
        }
        field(2; "No. Series"; Code[20])
        {

        }
        field(3; "Budget Amount"; Decimal)
        {
            Caption = 'Budget Amount';
        }
        field(4; "Budget Status"; Option)
        {
            Caption = 'Budget Status';
            OptionMembers = "Open","Released";
            OptionCaption = 'Open,Released';
            DataClassification = ToBeClassified;
        }
        field(5; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(6; "Email Approve"; text[100])
        {
            Caption = 'Email Approve';
        }

    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        wpVoucherStp: Record wpVoucherSetup;
        noSeriesMgmt: Codeunit "No. Series";
    begin
        if Rec.ID = '' then begin
            wpVoucherStp.Get();
            wpVoucherStp.TestField("VBudget ID Nos.");
            "No. Series" := wpVoucherStp."VBudget ID Nos.";
            Rec.ID := noSeriesMgmt.GetNextNo("No. Series");
        end;
    end;


    procedure AssistEdit(oldBudget: Record wpVoucherBudget): Boolean
    var
        wpStaffAllowStp: Record wpVoucherSetup;
        noSeriesMgmt: Codeunit "No. Series";
    begin
        wpStaffAllowStp.Get();
        wpStaffAllowStp.TestField("VBudget ID Nos.");
        if noSeriesMgmt.LookupRelatedNoSeries(wpStaffAllowStp."VBudget ID Nos.", oldBudget."No. Series", "No. Series") then begin
            Rec.ID := noSeriesMgmt.GetNextNo("No. Series");
            exit(true);
        end;
    end;
}
