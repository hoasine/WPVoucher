table 73110 wpTempVoucherResult
{
    TableType = Temporary;
    Caption = 'Temp Voucher Result';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; RowNo; Integer) { }
        field(2; ReportDate; Date) { }
        field(3; CampaignID; Code[20]) { }
        field(4; CampaignName; Text[30]) { }
        field(5; Denomination; Decimal) { }
        field(6; Qty; Integer) { }
        field(7; TotalAmount; Decimal) { }
    }

    keys
    {
        key(PK; RowNo) { Clustered = true; }
    }
}