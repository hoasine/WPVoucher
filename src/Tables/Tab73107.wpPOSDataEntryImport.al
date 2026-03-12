table 73107 "POS Data Entry Import"
{
    Caption = 'POS Data Entry Import';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Document No."; Code[50])
        {
            Caption = 'Document No.';
        }
        field(3; "Entry Type"; Code[20])
        {
            Caption = 'Entry Type';
        }
        field(4; "Entry Code"; Code[50])
        {
            Caption = 'Entry Code';
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(10; "Created in Store No."; Code[20])
        {
            Caption = 'Created in Store No.';
        }
        field(11; "Expiring Date"; Date)
        {
            Caption = 'Expiring Date';
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(13; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(14; "Imported"; Boolean)
        {
            Caption = 'Imported';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}