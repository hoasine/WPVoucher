tableextension 73107 LSCTransSalesEntryExt extends "LSC Trans. Sales Entry"
{
    fields
    {
        field(50100; "Voucher Status Temp"; Enum "Voucher Status") //Status temp voucher
        {
            Caption = 'Item Voucher Status Temp';
            DataClassification = CustomerContent;
        }
        field(50101; "Is Redeemption"; Boolean) // Đã đổi voucher
        {
            Caption = 'Is Redeemp';
            DataClassification = CustomerContent;
        }
        field(50102; "Voucher ID"; Code[20]) //Gán khi Redeemp Taka Voucher
        {
            Caption = 'Voucher ID';
            DataClassification = CustomerContent;
        }

        //Voucher Applied sau khi used. Nếu 1 recipt dùng nhiều voucher thì không thể gán Voucher No vào được
        //Mapping với Voucher Entries để lấy Voucher No
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