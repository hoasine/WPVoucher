tableextension 73102 wpPOSEntryExt extends "LSC POS Data Entry"
{
    fields
    {
        field(73100; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(73101; "Status"; Enum "Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(73102; "Date Actived"; Date)
        {
            Caption = 'Date Actived';
        }
        field(73104; "Date Redeemed"; Date)
        {
            Caption = 'Date Redeemed';
        }
        field(73105; "Date Procesed"; Date)
        {
            Caption = 'Date Procesed';
        }
    }
}