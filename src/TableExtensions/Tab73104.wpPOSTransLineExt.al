tableextension 73104 POSTransLineExt extends "LSC POS Trans. Line"
{
    fields
    {
        field(50103; "Is Used VC"; Boolean)
        {
            Caption = 'Is Used VC';
            DataClassification = CustomerContent;
        }
        field(50104; "Voucher ID of Used"; Code[20]) //Gán khi Used Taka Voucher
        {
            Caption = 'Voucher ID of Used';
            DataClassification = CustomerContent;
        }
    }
}