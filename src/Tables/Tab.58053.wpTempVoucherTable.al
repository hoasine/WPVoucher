table 58053 wpTempVoucherResult
{
    TableType = Temporary;
    Caption = 'Temp Voucher Result';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; RowNo; Integer) { }
        field(2; ReportDate; Date) { }
        field(3; CampaignID; Code[20]) { }
        field(4; CampaignName; Text[100]) { }
        field(5; Denomination; Decimal) { }
        field(6; Qty; Decimal) { }
        field(7; TotalAmount; Decimal) { }
        field(8; SumTotal; Decimal) { }
        field(9; ActualUsedHCM; Decimal) { }
        field(10; ActualUsedHN; Decimal) { }

        // dùng cho report 73100
        field(20; SheetType; Enum "Taka Voucher Sheet Type") { }
        field(21; EntryCode; Code[20]) { }
        field(22; RowDate; Date) { }
        field(23; ExpireDate; Date) { }
        field(24; Brand; Code[50]) { }
        field(25; ReceiptText; Text[500]) { }
        field(27; BillValue; Decimal) { }
        field(28; VoucherQty; Decimal) { }
    }

    keys
    {
        key(PK; RowNo)
        {
            Clustered = true;
        }

        key(Key2; SheetType, RowDate, RowNo)
        {
        }
    }
}