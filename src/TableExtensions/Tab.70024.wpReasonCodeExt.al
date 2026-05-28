tableextension 70024 wpReasonCodeExt extends "Reason Code"
{
    fields
    {
        field(5902; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;
            DataClassification = CustomerContent;
        }
        field(5903; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
    }
}