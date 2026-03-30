table 73110 wpTKVIsssuedRedeemedReport
{
    Caption = 'wpTKVIsssuedRedeemedReport';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = wpIssueVoucherLog."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Type; Enum wpIssueVoucherLogLineType)
        {
            Caption = 'Type';
        }
        field(20; "Document No."; Code[50])
        {
            Caption = 'Document No.';
        }
    }

    keys
    {
        key(PK; "Entry No.", "Line No.")
        {
            Clustered = true;
        }

        key(Key2; Type, "Document No.")
        {
        }
    }
}