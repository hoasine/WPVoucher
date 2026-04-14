namespace worldpos.Voucher.Configuration;

using worldpos.Voucher.Document;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Setup;
using Microsoft.Purchases.Document;

table 73101 wpVoucherMaintenance
{
    Caption = 'Voucher Maintenance Setup';
    DrillDownPageId = wpVoucherMaintenanceCard;
    LookupPageId = wpVoucherMaintenanceLists;
    DataClassification = ToBeClassified;
    DataCaptionFields = ID, Description;

    fields
    {
        field(1; ID; Code[20])
        {
            Caption = 'Voucher ID';
            NotBlank = true;
        }
        field(10; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(20; Enabled; Boolean)
        {
            Caption = 'Enabled';
            trigger OnValidate()
            begin
                ToEnabled();
            end;
        }
        field(50; "Validation Period ID"; Code[10])
        {
            Caption = 'Validation Period ID';
            Numeric = true;
            TableRelation = "LSC Validation Period";

            trigger OnValidate()
            begin
                Rec.CalcFields("Validation Description");
                Rec.CalcFields("Starting Date");
                Rec.CalcFields("Ending Date");
                if (Rec."Starting Date" = 0D) or (Rec."Ending Date" = 0D) then
                    Error('Starting Date or Ending Date must not be blank.');
            end;
        }
        field(51; "Validation Description"; Text[30])
        {
            CalcFormula = Lookup("LSC Validation Period".Description where(ID = field("Validation Period ID")));
            Caption = 'Validation Description';
            Editable = false;
            FieldClass = FlowField;

        }
        field(52; "Starting Date"; Date)
        {
            CalcFormula = Lookup("LSC Validation Period"."Starting Date" where(ID = field("Validation Period ID")));
            Caption = 'Starting Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Ending Date"; Date)
        {
            CalcFormula = Lookup("LSC Validation Period"."Ending Date" where(ID = field("Validation Period ID")));
            Caption = 'Ending Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Tender Type Code"; Code[10])
        {
            Caption = 'Tender Type Code';
            TableRelation = "LSC Tender Type Setup".Code;

            trigger OnValidate()
            begin
                Rec.CalcFields("Tender Type Description");
            end;
        }
        field(61; "Tender Type Description"; Text[30])
        {
            CalcFormula = Lookup("LSC Tender Type Setup".Description where(Code = field("Tender Type Code")));
            Caption = 'Tender Type Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "VoucherBudgetID"; Code[20])
        {
            Caption = 'Voucher Budget ID';
            TableRelation = "wpVoucherBudget".ID;
        }
        field(70; "Enable Tracking"; Boolean)
        {
            Caption = 'Enable Tracking';
        }
        field(80; "No. Series"; Code[20]) { }
        field(100; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }

        field(101; "Receipt Qty"; Decimal)
        {
            Caption = 'Receipt Qty';
        }
        field(102; "Total value"; Decimal)
        {
            Caption = 'Total value';
        }
        field(103; "Max Voucher Qty"; Decimal)
        {
            Caption = 'Max Voucher Qty';
        }
        field(503; "Member Type"; Option)
        {
            Caption = 'Member Type';
            OptionCaption = 'Scheme,Club';
            OptionMembers = Scheme,Club;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Member Type" <> xRec."Member Type" then
                    "Member Value" := '';
            end;
        }
        field(26; "Member Value"; Code[10])
        {
            Caption = 'Member Value';
            TableRelation = IF ("Member Type" = CONST(Scheme)) "LSC Member Scheme"
            ELSE
            IF ("Member Type" = CONST(Club)) "LSC Member Club";
            DataClassification = CustomerContent;
        }
        field(105; "Reason Code"; Code[20])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code".Code where(Description = CONST('TAKAVC'));
        }

    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(Key2; Enabled, ID) { }
    }

    procedure AssistEdit(oldBudget: Record wpVoucherMaintenance): Boolean
    var
        tbSalesReceivables: Record "Sales & Receivables Setup";
        noSeriesMgmt: Codeunit "No. Series";
    begin
        tbSalesReceivables.Get();
        tbSalesReceivables.TestField("Voucher ID Nos.");
        if noSeriesMgmt.LookupRelatedNoSeries(tbSalesReceivables."Voucher ID Nos.", oldBudget."No. Series", "No. Series") then begin
            Rec.ID := noSeriesMgmt.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    local procedure ToEnabled()
    begin
        // if Rec."Identification Type" = rec."Identification Type"::" " then Error('Identification Type must not be blank.');
        Rec.TestField("Validation Period ID");
        Rec.TestField("Tender Type Code");
    end;

    trigger OnInsert()
    var
        tbSalesReceivables: Record "Sales & Receivables Setup";
        noSeriesMgmt: Codeunit "No. Series";
        ph: Record "Purchase Header";
    begin
        if Rec.ID = '' then begin
            tbSalesReceivables.Get();
            tbSalesReceivables.TestField("Voucher ID Nos.");
            "No. Series" := tbSalesReceivables."Voucher ID Nos.";
            Rec.ID := noSeriesMgmt.GetNextNo("No. Series");
        end;
    end;
}
