table 58061 wpTempVoucherMemberResult
{
    TableType = Temporary;
    Caption = 'Temp Voucher Member Result';
    DataClassification = CustomerContent;

    fields
    {
        field(1; RowNo; Integer)
        {
            Caption = 'Row No.';
        }
        field(2; CampaignID; Code[20])
        {
            Caption = 'Campaign ID';
        }
        field(3; CampaignName; Text[100])
        {
            Caption = 'Campaign Name';
        }
        field(4; MemberCards; Text[2048])
        {
            Caption = 'Member Name';
        }
        field(5; TotalMember; Integer)
        {
            Caption = 'Total Member';
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(7; RedeemedVoucher; Integer)
        {
            Caption = 'Redeemed Voucher';
        }
        field(8; UsedVoucher; Integer)
        {
            Caption = 'Used Voucher';
        }
    }

    keys
    {
        key(PK; RowNo) { Clustered = true; }
    }
}
