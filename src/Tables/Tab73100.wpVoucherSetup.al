namespace worldpos.Voucher.Configuration;

using Microsoft.Foundation.NoSeries;

table 73100 wpVoucherSetup
{

    Caption = 'Voucher Setup';
    DrillDownPageId = wpVoucherSetup;
    LookupPageId = wpVoucherSetup;
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(20; "Voucher ID Nos."; Code[20])
        {
            Caption = 'Voucher ID Nos.';
            TableRelation = "No. Series".Code;
        }
        field(21; "VBudget ID Nos."; Code[20])
        {
            Caption = 'VBudget ID Nos.';
            TableRelation = "No. Series".Code;
        }
        field(22; "Quantity Exchange of Day"; Integer)
        {
            Caption = 'Quantity Exchange of Day.';
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        voucherSetup.Reset();
        if voucherSetup.Count = 1 then
            Error(ErrText1, voucherSetup.TableCaption);
    end;

    var
        voucherSetup: Record wpVoucherSetup;
        ErrText1: Label 'There can only be one %1 record in the system.';
}
