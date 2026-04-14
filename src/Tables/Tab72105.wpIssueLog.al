namespace worldpos.Voucher.Configuration;

table 72105 wpIssueLog
{
    Caption = 'Issue Voucher Log';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Voucher ID"; Code[20])
        {
            Caption = 'Voucher ID';
        }
        field(20; "Member Card"; Code[20])
        {
            Caption = 'Member Card';
        }
        field(30; "Redeemp Date"; Date)
        {
            Caption = 'Redeemp Date';
        }
        field(40; "Redeemp Time"; Time)
        {
            Caption = 'Redeemp Time';
        }
        field(50; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(70; "Receipt Count"; Integer)
        {
            Caption = 'Receipt Count';
        }
        field(80; "Voucher Count"; Integer)
        {
            Caption = 'Voucher Count';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(Key2; "Member Card", "Redeemp Date")
        {
        }

        key(Key3; "Voucher ID", "Redeemp Date")
        {
        }
    }
}
