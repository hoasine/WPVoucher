report 73101 "Taka Voucher Campaign Summary"
{
    ApplicationArea = All;
    DefaultRenderingLayout = "TakaVoucherCampaignExcel";
    DataAccessIntent = ReadOnly;
    ExcelLayoutMultipleDataSheets = true;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    MaximumDatasetSize = 1000000;
    Caption = 'Taka Voucher Campaign Summary';

    dataset
    {
        dataitem(Data; Integer)
        {
            DataItemTableView = sorting(Number);

            column(ReportDate; ReportDate) { }
            column(DatePrint; DatePrint) { }
            column(CampaignName; CampaignName) { }
            column(CampaignID; CampaignID) { }
            column(Denomination; Denomination) { }
            column(DateActived; DateActived) { }
            column(Qty; Qty) { }
            column(TotalAmount; TotalAmount) { }

            trigger OnPreDataItem()
            begin
                if DateActivedFilter = '' then
                    Error('Please select Date Actived range!');

                BuildResultTable();
                SetRange(Number, 1, TempResult.Count);
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempResult.FindFirst()
                else
                    TempResult.Next();

                ReportDate := TempResult.ReportDate;
                DatePrint := Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>');
                CampaignID := TempResult.CampaignID;
                CampaignName := TempResult.CampaignName;
                Denomination := TempResult.Denomination;
                DateActived := TempResult.ReportDate;
                Qty := TempResult.Qty;
                TotalAmount := TempResult.TotalAmount;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Option)
                {
                    field("Voucher Type"; VoucherTypeFilter)
                    {
                        TableRelation = "LSC POS Data Entry Type";
                        Caption = 'Voucher Type';
                    }
                    field("Document No."; DocumentNoFilter)
                    {
                        Caption = 'Voucher Campaign';
                        TableRelation = wpVoucherMaintenance.ID;
                    }
                    field("Date Actived"; DateActivedFilter)
                    {
                        Caption = 'Date Actived (Range)';
                        trigger OnValidate()
                        begin
                            ApplicationManagement.MakeDateFilter(DateActivedFilter);
                        end;
                    }
                }
            }
        }
    }

    rendering
    {
        layout(TakaVoucherCampaignExcel)
        {
            Type = Excel;
            LayoutFile = 'src/ReportLayouts/Excel/Rep.73101.TakaVoucherCampaignSummary.xlsx';
            Caption = 'Taka Voucher Campaign Summary';
        }
    }

    var
        DocumentNoFilter: Code[20];
        DateActivedFilter: Text[100];
        VoucherTypeFilter: Code[20];
        DatePrint: Text[100];
        ReportDate: Date;
        CampaignName: Text[30];
        CampaignID: Code[20];
        Denomination: Decimal;
        DateActived: Date;
        Qty: Integer;
        TotalAmount: Decimal;
        ApplicationManagement: Codeunit "Filter Tokens";
        TempResult: Record wpTempVoucherResult temporary; // temp table below

    local procedure BuildResultTable()
    var
        VoucherSetup: Record wpVoucherMaintenance;
        PosEntry: Record "LSC POS Data Entry";
        StartDate: Date;
        EndDate: Date;
        CurrentDate: Date;
        RowNo: Integer;
        Denom: Decimal;
        QtyCount: Integer;
    begin
        TempResult.DeleteAll();
        RowNo := 0;

        // Parse date range
        if StrPos(DateActivedFilter, '..') > 0 then begin
            Evaluate(StartDate, CopyStr(DateActivedFilter, 1, StrPos(DateActivedFilter, '..') - 1));
            Evaluate(EndDate, CopyStr(DateActivedFilter, StrPos(DateActivedFilter, '..') + 2));
        end else begin
            Evaluate(StartDate, DateActivedFilter);
            EndDate := StartDate;
        end;

        // Filter campaigns
        if DocumentNoFilter <> '' then
            VoucherSetup.SetRange(ID, DocumentNoFilter);

        if VoucherSetup.FindSet() then
            repeat
                // Get denomination from first POS entry for this campaign
                Denom := 0;
                PosEntry.Reset();
                PosEntry.SetRange("Entry Type", 'TK VOUCHER');
                PosEntry.SetRange("Document No.", VoucherSetup.ID);
                if PosEntry.FindFirst() then
                    Denom := PosEntry.Amount;

                // Loop each date in range
                CurrentDate := StartDate;
                while CurrentDate <= EndDate do begin
                    // Count activated vouchers for this campaign + date
                    PosEntry.Reset();
                    PosEntry.SetRange("Entry Type", 'TK VOUCHER');
                    PosEntry.SetRange("Document No.", VoucherSetup.ID);
                    PosEntry.SetRange("Date Actived", CurrentDate);
                    QtyCount := PosEntry.Count();

                    //Querry: voucher ID, date => Amount con lai. => Total Amount - Write Off Amount = Actual Amount
                    RowNo += 1;
                    TempResult.RowNo := RowNo;
                    TempResult.ReportDate := CurrentDate;
                    TempResult.CampaignID := VoucherSetup.ID;
                    TempResult.CampaignName := VoucherSetup.Description;
                    TempResult.Denomination := Denom;
                    TempResult.Qty := QtyCount;
                    TempResult.TotalAmount := Denom * QtyCount;
                    TempResult.Insert();

                    CurrentDate := CalcDate('<+1D>', CurrentDate);
                end;
            until VoucherSetup.Next() = 0;
    end;
}