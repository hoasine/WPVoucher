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

            column(STT; STT) { }
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

                STT := TempResult.SumTotal; // SumTotal stores the real DateSlot (day number)
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
                Variance := TempResult.TotalAmount - ActualUsedBoth;
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
                        ApplicationArea = All;
                    }
                    field("Document No."; DocumentNoFilter)
                    {
                        Caption = 'Voucher Campaign';
                        TableRelation = wpVoucherMaintenance.ID;
                        ApplicationArea = All;
                    }
                    field("Date Actived"; DateActivedFilter)
                    {
                        Caption = 'Date Actived (Range)';
                        ApplicationArea = All;
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
        STT: Integer;

    local procedure BuildResultTable()
    var
        VoucherCampaign: Record wpVoucherMaintenance;
        PosEntry: Record "LSC POS Data Entry";
        StartDate: Date;
        EndDate: Date;
        CurrentDate: Date;
        RowNo: Integer;
        DateSlot: Integer;       // STT = day slot number (same for all campaigns on same day)
        MaxDenomSlots: Integer;  // how many denom slots needed for this date
        SlotIdx: Integer;
        SeenDenomList: Text[2048];
        CampaignDenomMap: array[500] of Text[2048]; // denom list per campaign slot
        CampaignIDArr: array[500] of Code[20];
        CampaignNameArr: array[500] of Text[100];
        CampaignCount: Integer;
        LineDenom: Decimal;
        DenomParts: List of [Text];
        DenomText: Text;
        DenomVal: Decimal;
        QtyCount: Integer;
        i: Integer;
        CampDenomParts: List of [Text];
        CampDenomText: Text;
        CampDenomVal: Decimal;
    begin
        TempResult.DeleteAll();
        RowNo := 0;
        DateSlot := 0;

        ParseDateFilter(StartDate, EndDate);
        DateTarget := Format(StartDate, 0, '<Day,2>/<Month,2>/<Year4>') + '-' +
                      Format(EndDate, 0, '<Day,2>/<Month,2>/<Year4>');

        CurrentDate := StartDate;
        while CurrentDate <= EndDate do begin
            DateSlot += 1;
            // DateSlot will be adjusted after we know MaxDenomSlots for this date
            // We use a base slot here and advance it by MaxDenomSlots at end of date

            // --- Pass 1: collect campaigns and their denom lists for this date ---
            CampaignCount := 0;
            MaxDenomSlots := 1; // minimum 1 slot per date

            VoucherCampaign.Reset();
            VoucherCampaign.SetRange("Starting Date", 0D, Today);
            VoucherCampaign.SetFilter("Ending Date", '>=%1|%2', Today, 0D);
            if DocumentNoFilter <> '' then
                VoucherCampaign.SetRange(ID, DocumentNoFilter);

            if VoucherCampaign.FindSet() then
                repeat
                    CampaignCount += 1;
                    CampaignIDArr[CampaignCount] := VoucherCampaign.ID;
                    CampaignNameArr[CampaignCount] := VoucherCampaign.Description;

                    // Collect denom list for this campaign+date
                    SeenDenomList := '';
                    PosEntry.Reset();
                    ApplyUsedVoucherFilter(PosEntry, VoucherCampaign.ID, CurrentDate);
                    if PosEntry.FindSet() then
                        repeat
                            LineDenom := PosEntry.Amount;
                            if not DenomAlreadySeen(SeenDenomList, LineDenom) then begin
                                if SeenDenomList = '' then
                                    SeenDenomList := Format(LineDenom, 0, 9)
                                else
                                    SeenDenomList := SeenDenomList + '|' + Format(LineDenom, 0, 9);
                            end;
                        until PosEntry.Next() = 0;

                    CampaignDenomMap[CampaignCount] := SeenDenomList;

                    // Track max denom slots needed across all campaigns for this date
                    if SeenDenomList <> '' then begin
                        DenomParts := SeenDenomList.Split('|');
                        if DenomParts.Count > MaxDenomSlots then
                            MaxDenomSlots := DenomParts.Count;
                    end;
                until VoucherCampaign.Next() = 0;

            // --- Pass 2: write rows slot by slot ---
            // Each SlotIdx gets its own STT = DateSlot + SlotIdx - 1
            // So slot 1 of day 3 = STT 3, slot 2 of day 3 = STT 4, etc.
            for SlotIdx := 1 to MaxDenomSlots do begin
                for i := 1 to CampaignCount do begin
                    DenomVal := 0;
                    QtyCount := 0;

                    if CampaignDenomMap[i] <> '' then begin
                        CampDenomParts := CampaignDenomMap[i].Split('|');
                        if SlotIdx <= CampDenomParts.Count then begin
                            CampDenomParts.Get(SlotIdx, CampDenomText);
                            Evaluate(CampDenomVal, CampDenomText);
                            DenomVal := CampDenomVal;

                            PosEntry.Reset();
                            ApplyUsedVoucherFilter(PosEntry, CampaignIDArr[i], CurrentDate);
                            PosEntry.SetRange(Amount, DenomVal);
                            QtyCount := PosEntry.Count();
                        end;
                        // If SlotIdx > this campaign's denom count -> DenomVal=0, QtyCount=0 (empty slot)
                    end;

                    RowNo += 1;
                    TempResult.Init();
                    TempResult.RowNo := RowNo;  // unique PK
                    TempResult.SumTotal := DateSlot + SlotIdx - 1; // STT: slot1=DateSlot, slot2=DateSlot+1...
                    TempResult.ReportDate := CurrentDate;
                    TempResult.CampaignID := CampaignIDArr[i];
                    TempResult.CampaignName := CampaignNameArr[i];
                    TempResult.Denomination := DenomVal;
                    TempResult.Qty := QtyCount;
                    TempResult.TotalAmount := DenomVal * QtyCount;
                    if DenomVal > 0 then begin
                        TempResult.ActualUsedHCM :=
                            GetActualUsed(CampaignIDArr[i], CurrentDate, 'HCM', DenomVal);
                        TempResult.ActualUsedHN :=
                            GetActualUsed(CampaignIDArr[i], CurrentDate, 'HN', DenomVal);
                    end else begin
                        TempResult.ActualUsedHCM := 0;
                        TempResult.ActualUsedHN := 0;
                    end;
                    TempResult.Insert();
                end;
            end;

            // Advance DateSlot by extra slots used (MaxDenomSlots-1 already counted above)
            DateSlot += MaxDenomSlots - 1;

            CurrentDate := CalcDate('<+1D>', CurrentDate);
        end;
    end;

    /// <summary>
    /// Get actual used amount for a store + date + denomination.
    /// Added Denom parameter so HCM/HN amounts are correctly scoped per denomination.
    /// </summary>
    local procedure GetActualUsed(
        CampaignID: Code[20];
        ForDate: Date;
        StoreCode: Code[20];
        Denom: Decimal
    ): Decimal
    var
        PosEntry: Record "LSC POS Data Entry";
        VoucherEntry: Record "LSC Voucher Entries";
        TotalActual: Decimal;
        WriteOff: Decimal;
    begin
        TotalActual := 0;

        PosEntry.Reset();
        ApplyUsedVoucherFilter(PosEntry, CampaignID, ForDate);
        PosEntry.SetRange("Created in Store No.", StoreCode);
        PosEntry.SetRange(Amount, Denom); // scope to this denomination only

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

    local procedure ApplyUsedVoucherFilter(
        var PosEntry: Record "LSC POS Data Entry";
        CampaignID: Code[20];
        ForDate: Date)
    begin
        if VoucherTypeFilter <> '' then
            PosEntry.SetRange("Entry Type", VoucherTypeFilter);
        PosEntry.SetRange("Created by Receipt No.", CampaignID);
        PosEntry.SetRange("Date Applied", ForDate);
        PosEntry.SetRange(Applied, true);
        PosEntry.SetFilter("Applied by Receipt No.", '<>%1', '');
    end;

    local procedure DenomAlreadySeen(SeenList: Text[2048]; Denom: Decimal): Boolean
    begin
        if SeenList = '' then
            exit(false);
        exit(StrPos('|' + SeenList + '|', '|' + Format(Denom, 0, 9) + '|') > 0);
    end;

    local procedure ParseDateFilter(var StartDate: Date; var EndDate: Date)
    begin
        if StrPos(DateActivedFilter, '..') > 0 then begin
            Evaluate(StartDate, CopyStr(DateActivedFilter, 1, StrPos(DateActivedFilter, '..') - 1));
            Evaluate(EndDate, CopyStr(DateActivedFilter, StrPos(DateActivedFilter, '..') + 2));
        end else begin
            Evaluate(StartDate, DateActivedFilter);
            EndDate := StartDate;
        end;
    end;
}
