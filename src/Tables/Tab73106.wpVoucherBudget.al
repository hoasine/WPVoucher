namespace worldpos.Voucher.Configuration;

using worldpos.Voucher.Document;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Setup;
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
        tbSalesReceivables: Record "Sales & Receivables Setup";
        noSeriesMgmt: Codeunit "No. Series";
    begin
        if Rec.ID = '' then begin
            tbSalesReceivables.Get();
            tbSalesReceivables.TestField("VBudget ID Nos.");
            "No. Series" := tbSalesReceivables."VBudget ID Nos.";
            Rec.ID := noSeriesMgmt.GetNextNo("No. Series");
        end;
    end;


    procedure AssistEdit(oldBudget: Record wpVoucherBudget): Boolean
    var
        tbSalesReceivables: Record "Sales & Receivables Setup";
        noSeriesMgmt: Codeunit "No. Series";
    begin
        tbSalesReceivables.Get();
        tbSalesReceivables.TestField("VBudget ID Nos.");
        if noSeriesMgmt.LookupRelatedNoSeries(tbSalesReceivables."VBudget ID Nos.", oldBudget."No. Series", "No. Series") then begin
            Rec.ID := noSeriesMgmt.GetNextNo("No. Series");
            exit(true);
        end;
    end;
}
