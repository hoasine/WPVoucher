tableextension 73105 wpSalesReceivablesSetup extends "Sales & Receivables Setup"
{
    fields
    {
        field(7105; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(7106; "Voucher GL Date"; Date)
        {

        }
        field(7107; "Voucher ID Nos."; Code[20])
        {
            Caption = 'Voucher ID Nos.';
            TableRelation = "No. Series".Code;
        }
        field(7108; "VBudget ID Nos."; Code[20])
        {
            Caption = 'VBudget ID Nos.';
            TableRelation = "No. Series".Code;
        }
        field(7109; "Quantity Exchange of Day"; Integer)
        {
            Caption = 'Quantity Exchange of Day.';
        }
        field(7110; "Redeemp Same Member"; Boolean)
        {
            Caption = 'Redeemp Same Member';
            ToolTip = 'Allow same member card redemption';
        }
    }
}