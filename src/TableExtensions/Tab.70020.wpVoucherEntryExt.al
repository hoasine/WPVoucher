tableextension 70020 wpVoucherEntryExt extends "LSC Voucher Entries"
{
    fields
    {
        field(73100; "Voucher Id"; Code[20])//Kiểm tra voucher cùng 
        {
            Caption = 'Voucher Id';
            DataClassification = CustomerContent;
        }
    }
}