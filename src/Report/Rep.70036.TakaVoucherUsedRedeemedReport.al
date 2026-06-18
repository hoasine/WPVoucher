report 70036 "Taka Voucher Report"
{
    ApplicationArea = All;
    DefaultRenderingLayout = "TakaVoucherExcelTemplate";
    DataAccessIntent = ReadOnly;
    ExcelLayoutMultipleDataSheets = true;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    MaximumDatasetSize = 1000000;
    Caption = 'Taka Voucher Used/Redeemed Report';

    dataset
    {
        dataitem(Redeem; wpTempVoucherResult)
        {
            DataItemTableView = sorting(SheetType, RowDate, RowNo)
                                where(SheetType = const(Redeem));
            UseTemporary = true;

            column(Date; RowDate) { }
            column(Brand; Brand) { }
            column(ReceiptNo; ReceiptText) { }
            column(BillValue; BillValue) { }
            column(VoucherQty; Format(Round(VoucherQty, 0.01))) { }
            column(ExpireDate; ExpireDate) { }

            trigger OnPreDataItem()
            begin
                Redeem.SetRange(SheetType, Redeem.SheetType::Redeem);
            end;
        }

        dataitem(Used; wpTempVoucherResult)
        {
            DataItemTableView = sorting(SheetType, RowDate, RowNo)
                                where(SheetType = const(Used));
            UseTemporary = true;

            column(DateUsed; RowDate) { }
            column(BrandUsed; Brand) { }
            column(TransNoUsed; ReceiptText) { }
            column(BillValueAmount; BillValue) { }
            column(VoucherQtyUsed; Format(Round(VoucherQty, 0.01))) { }

            trigger OnPreDataItem()
            begin
                Used.SetRange(SheetType, Used.SheetType::Used);
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
                    field("Date Redeemed/Applied"; DateFilterInput)
                    {
                        Caption = 'Date Redeemed / Used';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ApplicationManagement.MakeDateFilter(DateFilterInput);
                        end;
                    }
                    field("Special Group"; SpecialGroupFilter)
                    {
                        Caption = 'Special Group Code';
                        ApplicationArea = All;
                        TableRelation = "LSC Item Special Groups"."Code";
                    }
                    field("Document No"; DocumentNoFilter)
                    {
                        Caption = 'Document No.';
                        ApplicationArea = All;
                        TableRelation = wpVoucherMaintenance.ID;
                    }
                    field("Voucher No"; VoucherNoFilter)
                    {
                        Caption = 'Voucher No.';
                        ApplicationArea = All;
                        TableRelation = "LSC POS Data Entry"."Entry Code";
                    }
                }
            }
        }
    }

    rendering
    {
        layout(TakaVoucherExcelTemplate)
        {
            Type = Excel;
            LayoutFile = 'src/ReportLayouts/Excel/Rep.70036.TakaVoucherIsssuedRedeemedReport.xlsx';
            Caption = 'Taka Voucher Issued/Redeemed Report';
            Summary = 'src/ReportLayouts/Excel/Rep.70036.TakaVoucherIsssuedRedeemedReport.xlsx';
        }
    }

    trigger OnPreReport()
    begin
        FilterDateStart := 0D;
        FilterDateEnd := 0D;

        if DateFilterInput <> '' then begin
            if StrPos(DateFilterInput, '..') > 0 then begin
                Evaluate(FilterDateStart, CopyStr(DateFilterInput, 1, StrPos(DateFilterInput, '..') - 1));
                Evaluate(FilterDateEnd, CopyStr(DateFilterInput, StrPos(DateFilterInput, '..') + 2));
            end else begin
                Evaluate(FilterDateStart, DateFilterInput);
                FilterDateEnd := FilterDateStart;
            end;
        end;

        NextLineNo := 1;

        Redeem.Reset();
        Redeem.DeleteAll();

        Used.Reset();
        Used.DeleteAll();

        FillRedeemBufferFromIssueLog();
        FillUsedBufferFromPosEntry();
    end;

    local procedure FillRedeemBufferFromIssueLog()
    var
        EntryType: Record "LSC POS Data Entry Type";
        PosEntry: Record "LSC POS Data Entry";
        IssueLogLine: Record "wpIssueLogLine";
        ProcessedEntries: List of [Text];
        DedupeKey: Text;
        EntryNo: Integer;
    begin
        EntryType.Reset();
        EntryType.SetRange("Enable/ Activate Taka Voucher", true);
        if VoucherTypeFilter <> '' then
            EntryType.SetFilter("Code", VoucherTypeFilter);
        if not EntryType.FindSet() then
            exit;

        repeat
            IssueLogLine.Reset();
            IssueLogLine.SetFilter("Type", '1');

            if VoucherNoFilter <> '' then
                IssueLogLine.SetFilter("Document No.", VoucherNoFilter);

            if IssueLogLine.FindSet() then
                repeat
                    EntryNo := IssueLogLine."Entry No.";
                    if EntryNo <> 0 then begin
                        DedupeKey := Format(EntryNo);

                        if not ProcessedEntries.Contains(DedupeKey) then begin
                            PosEntry.Reset();
                            PosEntry.SetRange("Entry Type", EntryType.Code);
                            PosEntry.SetRange("Entry Code", IssueLogLine."Document No.");

                            if DocumentNoFilter <> '' then
                                PosEntry.SetFilter("Document No.", DocumentNoFilter);

                            if DateFilterInput <> '' then
                                PosEntry.SetFilter("Date Redeemed", DateFilterInput)
                            else
                                PosEntry.SetFilter("Date Redeemed", '<>%1', 0D);

                            if PosEntry.FindFirst() then begin
                                ProcessedEntries.Add(DedupeKey);
                                ExpandVoucherRows(PosEntry."Entry Code", PosEntry."Date Redeemed", PosEntry."Expiring Date", Redeem.SheetType::Redeem, Redeem);
                            end;
                        end;
                    end;
                until IssueLogLine.Next() = 0;

        until EntryType.Next() = 0;
    end;

    local procedure FillUsedBufferFromPosEntry()
    var
        EntryType: Record "LSC POS Data Entry Type";
        PosEntry: Record "LSC POS Data Entry";
        ProcessedEntries: List of [Text];
        DedupeKey: Text;
    begin
        EntryType.Reset();
        EntryType.SetRange("Enable/ Activate Taka Voucher", true);
        if VoucherTypeFilter <> '' then
            EntryType.SetFilter("Code", VoucherTypeFilter);
        if not EntryType.FindSet() then
            exit;

        repeat
            PosEntry.Reset();
            PosEntry.SetRange("Entry Type", EntryType.Code);
            PosEntry.SetRange("Applied", true);

            if VoucherNoFilter <> '' then
                PosEntry.SetFilter("Entry Code", VoucherNoFilter);

            if DocumentNoFilter <> '' then
                PosEntry.SetFilter("Document No.", DocumentNoFilter);

            if DateFilterInput <> '' then
                PosEntry.SetFilter("Date Applied", DateFilterInput)
            else
                PosEntry.SetFilter("Date Applied", '<>%1', 0D);

            if PosEntry.FindSet() then
                repeat
                    if PosEntry."Applied by Receipt No." <> '' then begin
                        DedupeKey := PosEntry."Applied by Receipt No.";

                        if not ProcessedEntries.Contains(DedupeKey) then begin
                            ProcessedEntries.Add(DedupeKey);
                            ExpandVoucherRows(PosEntry."Entry Code", PosEntry."Date Applied", PosEntry."Expiring Date", Used.SheetType::Used, Used);
                        end;
                    end;
                until PosEntry.Next() = 0;

        until EntryType.Next() = 0;
    end;


    local procedure ExpandVoucherRows(
        EntryCode: Code[20];
        RowDate: Date;
        ExpireDate: Date;
        SheetType: Enum "Taka Voucher Sheet Type";
        var OutputBuffer: Record wpTempVoucherResult temporary)
    var
        IssueLogLine: Record "wpIssueLogLine";
        IssueLogLine2: Record "wpIssueLogLine";
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        IssueLogRec: Record "wpIssueLog";
        PosEntryForVoucher: Record "LSC POS Data Entry";
        PosEntryUsed: Record "LSC POS Data Entry";
        TempGroupBuffer: Record wpTempVoucherResult temporary;
        VoucherID: Code[20];
        VoucherCount: Integer;
        TotalBillValue: Decimal;
        EntryNo: Integer;
        ReceiptNoList: Text[500];
        POSList: Text[500];
        ReceiptNoEntry: Text[20];
        POSTerminalEntry: Text[20];
        SpecialGrpCode: Code[50];
        AppliedReceiptNo: Code[50];
    begin
        VoucherCount := 0;
        TotalBillValue := 0;
        EntryNo := 0;
        VoucherID := '';
        AppliedReceiptNo := '';
        ReceiptNoList := '';
        POSList := '';

        PosEntryForVoucher.Reset();
        PosEntryForVoucher.SetRange("Entry Code", EntryCode);
        if PosEntryForVoucher.FindFirst() then begin
            VoucherID := PosEntryForVoucher."Created by Receipt No.";
            AppliedReceiptNo := PosEntryForVoucher."Applied by Receipt No.";
        end;

        if SheetType = SheetType::Used then begin
            if AppliedReceiptNo = '' then
                exit;

            PosEntryUsed.Reset();
            PosEntryUsed.SetRange("Entry Type", PosEntryForVoucher."Entry Type");
            PosEntryUsed.SetRange("Applied by Receipt No.", AppliedReceiptNo);
            PosEntryUsed.SetRange(Applied, true);
            VoucherCount := PosEntryUsed.Count();
            if VoucherCount = 0 then
                VoucherCount := 1;

            TransSalesEntry.Reset();
            TransSalesEntry.SetRange("Receipt No.", AppliedReceiptNo);
            if TransSalesEntry.FindFirst() then begin
                ReceiptNoList := CopyStr(Format(TransSalesEntry."Receipt No."), 1, 500);
                POSList := CopyStr(TransSalesEntry."POS Terminal No.", 1, 500);
            end;

            TransSalesEntry.Reset();
            TransSalesEntry.SetRange("Receipt No.", AppliedReceiptNo);
            if TransSalesEntry.FindSet() then
                repeat
                    if TransSalesEntry.Quantity < 0 then
                        TotalBillValue += TransSalesEntry."Price";
                until TransSalesEntry.Next() = 0;

            TransSalesEntry.Reset();
            TransSalesEntry.SetRange("Receipt No.", AppliedReceiptNo);
            if TransSalesEntry.FindSet() then
                repeat
                    if TransSalesEntry.Quantity < 0 then begin
                        SpecialGrpCode := GetSpecialGroupCode(TransSalesEntry."Item No.");

                        if (SpecialGroupFilter = '') or (SpecialGrpCode = SpecialGroupFilter) then
                            AddOrUpdateGroupBuffer(TempGroupBuffer, SpecialGrpCode, TransSalesEntry."Price");
                    end;
                until TransSalesEntry.Next() = 0;

            if not TempGroupBuffer.FindFirst() then begin
                if SpecialGroupFilter <> '' then
                    exit;
                if TotalBillValue = 0 then
                    exit;

                TempGroupBuffer.Init();
                TempGroupBuffer.RowNo := 1;
                TempGroupBuffer.Brand := '';
                TempGroupBuffer.BillValue := 0;
                TempGroupBuffer.VoucherQty := VoucherCount;
                TempGroupBuffer.Insert();
            end;

            ApplyLargestRemainder(TempGroupBuffer, TotalBillValue, VoucherCount);
            InsertOutputRows(OutputBuffer, TempGroupBuffer, SheetType, EntryCode, RowDate, ExpireDate, ReceiptNoList, POSList);
            exit;
        end;

        IssueLogLine.Reset();
        IssueLogLine.SetFilter("Type", '1');
        IssueLogLine.SetRange("Document No.", EntryCode);
        if not IssueLogLine.FindFirst() then begin
            IssueLogLine.Reset();
            IssueLogLine.SetRange("Document No.", EntryCode);
            if not IssueLogLine.FindFirst() then
                exit;
        end;
        EntryNo := IssueLogLine."Entry No.";

        IssueLogRec.Reset();
        IssueLogRec.SetRange("Entry No.", EntryNo);
        if IssueLogRec.FindFirst() then
            VoucherCount := IssueLogRec."Voucher Count";
        if VoucherCount = 0 then
            VoucherCount := 1;

        TempGroupBuffer.Reset();
        TempGroupBuffer.DeleteAll();
        TotalBillValue := 0;

        IssueLogLine2.Reset();
        IssueLogLine2.SetRange("Entry No.", EntryNo);
        IssueLogLine2.SetFilter("Type", '0');
        IssueLogLine2.SetAscending("Line No.", true);

        if IssueLogLine2.FindSet() then
            repeat
                TransSalesEntry.Reset();
                TransSalesEntry.SetRange("Receipt No.", IssueLogLine2."Document No.");
                if TransSalesEntry.FindFirst() then begin
                    ReceiptNoEntry := Format(TransSalesEntry."Receipt No.");
                    POSTerminalEntry := TransSalesEntry."POS Terminal No.";
                    AddTextToList(ReceiptNoList, ReceiptNoEntry);
                    AddTextToList(POSList, POSTerminalEntry);
                end;

                TransSalesEntry.Reset();
                TransSalesEntry.SetRange("Receipt No.", IssueLogLine2."Document No.");
                if TransSalesEntry.FindSet() then
                    repeat
                        if TransSalesEntry.Quantity < 0 then
                            TotalBillValue += TransSalesEntry."Price";
                    until TransSalesEntry.Next() = 0;

                TransSalesEntry.Reset();
                TransSalesEntry.SetRange("Receipt No.", IssueLogLine2."Document No.");
                if TransSalesEntry.FindSet() then
                    repeat
                        if TransSalesEntry.Quantity < 0 then begin
                            SpecialGrpCode := GetSpecialGroupCode(TransSalesEntry."Item No.");

                            if (SpecialGroupFilter = '') or (SpecialGrpCode = SpecialGroupFilter) then
                                AddOrUpdateGroupBuffer(TempGroupBuffer, SpecialGrpCode, TransSalesEntry."Price");
                        end;
                    until TransSalesEntry.Next() = 0;

            until IssueLogLine2.Next() = 0;

        if not TempGroupBuffer.FindFirst() then begin
            if SpecialGroupFilter <> '' then
                exit;
            if TotalBillValue = 0 then
                exit;

            TempGroupBuffer.Init();
            TempGroupBuffer.RowNo := 1;
            TempGroupBuffer.Brand := '';
            TempGroupBuffer.BillValue := 0;
            TempGroupBuffer.VoucherQty := VoucherCount;
            TempGroupBuffer.Insert();
        end;

        ApplyLargestRemainder(TempGroupBuffer, TotalBillValue, VoucherCount);
        InsertOutputRows(OutputBuffer, TempGroupBuffer, SheetType, EntryCode, RowDate, ExpireDate, ReceiptNoList, POSList);
    end;

    local procedure AddTextToList(var TargetText: Text[500]; NewValue: Text[20])
    begin
        if NewValue = '' then
            exit;

        if StrPos(TargetText, NewValue) > 0 then
            exit;

        if TargetText = '' then
            TargetText := CopyStr(NewValue, 1, MaxStrLen(TargetText))
        else
            TargetText := CopyStr(TargetText + ';' + NewValue, 1, MaxStrLen(TargetText));
    end;

    local procedure GetSpecialGroupCode(ItemNo: Code[20]): Code[50]
    var
        RetailItem: Record "Item";
        SpecialGrpCode: Code[50];
    begin
        SpecialGrpCode := '';

        RetailItem.Reset();
        RetailItem.SetRange("No.", ItemNo);
        if RetailItem.FindFirst() then begin
            RetailItem.CalcFields("LSC Special Group Code");
            SpecialGrpCode := RetailItem."LSC Special Group Code";
        end;

        if SpecialGrpCode = '' then
            SpecialGrpCode := 'NO_GROUP';

        exit(SpecialGrpCode);
    end;

    local procedure AddOrUpdateGroupBuffer(
        var TempGroupBuffer: Record wpTempVoucherResult temporary;
        BrandCode: Code[50];
        BillValue: Decimal)
    var
        NewRowNo: Integer;
    begin
        TempGroupBuffer.Reset();
        TempGroupBuffer.SetRange(Brand, BrandCode);
        if TempGroupBuffer.FindFirst() then begin
            TempGroupBuffer.BillValue += BillValue;
            TempGroupBuffer.Modify();
            exit;
        end;

        TempGroupBuffer.Reset();
        if TempGroupBuffer.FindLast() then
            NewRowNo := TempGroupBuffer.RowNo + 1
        else
            NewRowNo := 1;

        TempGroupBuffer.Init();
        TempGroupBuffer.RowNo := NewRowNo;
        TempGroupBuffer.Brand := BrandCode;
        TempGroupBuffer.BillValue := BillValue;
        TempGroupBuffer.Insert();
    end;

    local procedure InsertOutputRows(
        var OutputBuffer: Record wpTempVoucherResult temporary;
        var TempGroupBuffer: Record wpTempVoucherResult temporary;
        SheetType: Enum "Taka Voucher Sheet Type";
        EntryCode: Code[20];
        RowDate: Date;
        ExpireDate: Date;
        ReceiptNoList: Text[500];
        POSList: Text[500])
    begin
        TempGroupBuffer.Reset();
        if not TempGroupBuffer.FindSet() then
            exit;

        repeat
            OutputBuffer.Init();
            OutputBuffer.RowNo := NextLineNo;
            OutputBuffer.SheetType := SheetType;
            OutputBuffer.EntryCode := EntryCode;
            OutputBuffer.RowDate := RowDate;
            OutputBuffer.ExpireDate := ExpireDate;
            OutputBuffer.Brand := TempGroupBuffer.Brand;
            OutputBuffer.ReceiptText := ReceiptNoList;
            OutputBuffer.BillValue := TempGroupBuffer.BillValue;
            OutputBuffer.VoucherQty := TempGroupBuffer.VoucherQty;
            OutputBuffer.Insert();
            NextLineNo += 1;
        until TempGroupBuffer.Next() = 0;
    end;


    local procedure ApplyLargestRemainder(
        var TempGroupBuffer: Record wpTempVoucherResult temporary;
        TotalBillValue: Decimal;
        VoucherCount: Integer)
    var
        VoucherCountDec: Decimal;
        AssignedTotal: Decimal;
        RawQty: Decimal;
        FloorQty: Decimal;
        RemainderSlots: Integer;
        DoneDistributing: Boolean;
    begin
        VoucherCountDec := VoucherCount * 1.0;
        AssignedTotal := 0;

        TempGroupBuffer.Reset();
        if TempGroupBuffer.FindSet() then
            repeat
                if TotalBillValue <> 0 then begin
                    RawQty := (TempGroupBuffer.BillValue / TotalBillValue) * VoucherCountDec;
                    FloorQty := (Round(RawQty * 100, 1, '<')) / 100;
                end else
                    FloorQty := VoucherCountDec;

                TempGroupBuffer.VoucherQty := FloorQty;
                TempGroupBuffer.Modify();
                AssignedTotal += FloorQty;
            until TempGroupBuffer.Next() = 0;

        RemainderSlots := Round((VoucherCountDec - AssignedTotal) / 0.01, 1);
        if RemainderSlots <= 0 then
            exit;

        TempGroupBuffer.Reset();
        TempGroupBuffer.SetCurrentKey(BillValue);
        TempGroupBuffer.Ascending(false);
        DoneDistributing := false;

        if TempGroupBuffer.FindSet() then
            repeat
                if not DoneDistributing then begin
                    TempGroupBuffer.VoucherQty += 0.01;
                    TempGroupBuffer.Modify();
                    RemainderSlots -= 1;
                    if RemainderSlots <= 0 then
                        DoneDistributing := true;
                end;
            until TempGroupBuffer.Next() = 0;
    end;

    var
        DateFilterInput: Text[100];
        DocumentNoFilter: Code[20];
        SpecialGroupFilter: Code[50];
        VoucherNoFilter: Code[20];
        VoucherTypeFilter: Code[20];
        FilterDateStart: Date;
        FilterDateEnd: Date;
        NextLineNo: Integer;
        ApplicationManagement: Codeunit "Filter Tokens";
}
