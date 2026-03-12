namespace worldpos.Voucher.Configuration;

using Microsoft.Inventory.Item;
using worldpos.Voucher.Configuration;

table 73105 MemberVoucher
{
    Caption = 'Member Voucher';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Voucher ID"; Code[20])
        {
            Caption = 'Voucher ID';
            TableRelation = wpVoucherMaintenance.ID;
        }
        field(2; "Member Club"; Code[20])
        {
            Caption = 'Member Club';
            TableRelation = "LSC Member Club".Code;
        }
        field(3; "Member Scheme"; Code[20])
        {
            Caption = 'Member Scheme';
            TableRelation = "LSC Member Scheme".Code WHERE("Club Code" = FIELD("Member Club"));
        }

        field(4; "Total value"; Decimal)
        {
            Caption = 'Total value';
        }
        field(7; "Voucher Amount"; Decimal)
        {
            Caption = 'Voucher Amount';
        }
        field(5; "Receipt Qty"; Decimal)
        {
            Caption = 'Receipt Qty';
        }
        field(6; "Max Voucher Qty"; Decimal)
        {
            Caption = 'Max Voucher Qty';
        }
    }
    keys
    {
        key(PK; "Voucher ID", "Member Club", "Member Scheme")
        {
            Clustered = true;
        }
    }
}
