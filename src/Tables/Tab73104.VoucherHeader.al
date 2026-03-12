table 73104 "Voucher Header"
{
    Caption = 'Voucher Header';
    // LookupPageId = "Voucher Issuance Management";
    DataClassification = ToBeClassified;
    DataCaptionFields = "Start Date", "End Date", Status;

    fields
    {
        field(3; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = ToBeClassified;
        }
        field(4; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = ToBeClassified;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = "Open","Released","Posted";
            OptionCaption = 'Open,Released,Posted';
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }

    keys
    {

        key(PK; Status, "Start Date", "End Date") { }
    }
    var
        //NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesMgt: Codeunit "No. Series";

}
