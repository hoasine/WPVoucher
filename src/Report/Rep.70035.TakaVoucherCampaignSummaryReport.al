report 70035 "Taka Voucher Campaign Summary"
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
            column(DateTarget; DateTarget) { }
            column(CampaignName; CampaignName) { }
            column(CampaignID; CampaignID) { }
            column(Denomination; Denomination) { }
            column(DateActived; DateActived) { }
            column(Qty; Qty) { }
            column(Total; TotalAmount) { }
            column(HCM; ActualUsedHCM) { }
            column(HN; ActualUsedHN) { }
            column(All; ActualUsedBoth) { }
            column(Variance; Variance) { }

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
                ActualUsedHCM := TempResult.ActualUsedHCM;
                ActualUsedHN := TempResult.ActualUsedHN;
                ActualUsedBoth := TempResult.ActualUsedHCM + TempResult.ActualUsedHN;
                Variance := TempResult.TotalAmount - ActualUsedBoth
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
            LayoutFile = 'src/ReportLayouts/Excel/Rep.70035.TakaVoucherCampaignSummary.xlsx';
            Caption = 'Taka Voucher Campaign Summary';
        }
    }


    var
        DocumentNoFilter: Code[20];
        DateActivedFilter: Text[100];
        VoucherTypeFilter: Code[20];
        DatePrint: Text[100];
        DateTarget: Text[100];
        ReportDate: Date;
        CampaignName: Text[30];
        CampaignID: Code[20];
        Denomination: Decimal;
        DateActived: Date;
        Qty: Integer;
        TotalAmount: Decimal;
        ApplicationManagement: Codeunit "Filter Tokens";
        TempResult: Record wpTempVoucherResult temporary;
        Variance: Decimal;
        ActualUsedHCM: Decimal;
        ActualUsedHN: Decimal;
        ActualUsedBoth: Decimal;

    local procedure BuildResultTable()
    var
        voucherCampaing: Record wpVoucherMaintenance;
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

        if StrPos(DateActivedFilter, '..') > 0 then begin
            Evaluate(StartDate, CopyStr(DateActivedFilter, 1,
                StrPos(DateActivedFilter, '..') - 1));
            Evaluate(EndDate, CopyStr(DateActivedFilter,
                StrPos(DateActivedFilter, '..') + 2));
        end else begin
            Evaluate(StartDate, DateActivedFilter);
            EndDate := StartDate;
        end;

        DateTarget := Format(StartDate, 0, '<Day,2>/<Month,2>/<Year4>') + '-' + Format(EndDate, 0, '<Day,2>/<Month,2>/<Year4>');

        voucherCampaing.Reset();
        voucherCampaing.SetRange("Starting Date", 0D, Today);
        voucherCampaing.SetFilter("Ending Date", '>=%1|%2', Today, 0D);
        if DocumentNoFilter <> '' then
            voucherCampaing.SetRange(ID, DocumentNoFilter);

        if voucherCampaing.FindSet() then
            repeat
                Denom := 0;

                CurrentDate := StartDate;
                while CurrentDate <= EndDate do begin
                    PosEntry.Reset();
                    PosEntry.SetRange("Entry Type", VoucherTypeFilter);
                    PosEntry.SetRange("Created by Receipt No.", voucherCampaing.ID);
                    PosEntry.SetRange("Date Applied", CurrentDate);
                    PosEntry.SetFilter("Status", '3');
                    QtyCount := PosEntry.Count();

                    if (QtyCount > 0) then begin
                        if PosEntry.FindSet() then
                            Denom := PosEntry.Amount;//lấy giá trị amount đã applied
                    end;

                    RowNo += 1;
                    TempResult.RowNo := RowNo;
                    TempResult.ReportDate := CurrentDate;
                    TempResult.CampaignID := voucherCampaing.ID;
                    TempResult.CampaignName := voucherCampaing.Description;
                    TempResult.Denomination := Denom;
                    TempResult.Qty := QtyCount;
                    TempResult.TotalAmount := Denom * QtyCount;
                    TempResult.ActualUsedHCM :=
                        GetActualUsed(voucherCampaing.ID, CurrentDate, 'HCM');
                    TempResult.ActualUsedHN :=
                        GetActualUsed(voucherCampaing.ID, CurrentDate, 'HN');
                    TempResult.Insert();

                    CurrentDate := CalcDate('<+1D>', CurrentDate);
                end;

            until voucherCampaing.Next() = 0;
    end;

    local procedure GetActualUsed(
    CampaignID: Code[20];
    ForDate: Date;
    StoreCode: Code[20]
): Decimal
    var
        PosEntry: Record "LSC POS Data Entry";
        VoucherEntry: Record "LSC Voucher Entries";
        TotalActual: Decimal;
        WriteOff: Decimal;
    begin
        TotalActual := 0;

        PosEntry.Reset();
        PosEntry.SetRange("Entry Type", VoucherTypeFilter);
        PosEntry.SetRange("Created by Receipt No.", CampaignID);
        PosEntry.SetRange("Date Applied", ForDate);
        PosEntry.SetRange("Created in Store No.", StoreCode);
        PosEntry.SetFilter("Status", '3');

        if not PosEntry.FindSet() then
            exit(0);

        repeat
            WriteOff := 0;
            VoucherEntry.Reset();
            VoucherEntry.SetRange("Voucher No.", PosEntry."Entry Code");
            VoucherEntry.SetFilter("Entry Type", '=Redemption');
            if VoucherEntry.FindFirst() then
                WriteOff := VoucherEntry."Write Off Amount";

            TotalActual += PosEntry.Amount - WriteOff;

        until PosEntry.Next() = 0;

        exit(TotalActual);
    end;
}