report 73100 "Taka Voucher Report"
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
        dataitem(Redeem; "Taka Voucher Report Buffer")
        {
            DataItemTableView = sorting("Sheet Type", "Row Date", "Line No.")
                                where("Sheet Type" = const(Redeem));

            UseTemporary = true;
            column(Date; "Row Date") { }
            column(Brand; "Brand") { }
            column(TransNo; "Trans No") { }
            column(POS; "POS Terminal") { }
            column(BillValue; "Bill Value") { }
            column(VoucherQty; Format(Round("Voucher Qty", 0.01))) { }
            column(ExpireDate; "Expire Date") { }
            //column(Redeem_EntryCode; "Entry Code") { }
            //column(Redeem_DateFilter; DateFilterInput) { }

            trigger OnPreDataItem()
            begin

                Redeem.SetRange("Sheet Type", Redeem."Sheet Type"::Redeem);
            end;
        }

        dataitem(Used; "Taka Voucher Report Buffer")
        {
            DataItemTableView = sorting("Sheet Type", "Row Date", "Line No.")
                                where("Sheet Type" = const(Used));
            UseTemporary = true;

            column(DateUsed; "Row Date") { }
            column(BrandUsed; "Brand") { }
            column(TransNoUsed; "Trans No") { }
            column(PosUsed; "POS Terminal") { }
            column(BillValueAmount; "Bill Value") { }
            column(VoucherQtyUsed; Format(Round("Voucher Qty", 0.01))) { }
            //column(Used_EntryCode; "Entry Code") { }
            //column(Used_DateFilter; DateFilterInput) { }

            trigger OnPreDataItem()
            begin
                Used.SetRange("Sheet Type", Used."Sheet Type"::Used);
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
            LayoutFile = 'src/ReportLayouts/Excel/Rep.73100.TakaVoucherIsssuedRedeemedReport.xlsx';
            Caption = 'Taka Voucher Issued/Redeemed Report';
            Summary = 'src/ReportLayouts/Excel/Rep.73100.TakaVoucherIsssuedRedeemedReport.xlsx';
        }
    }

    trigger OnPreReport()
    begin
        FilterDateStart := 0D;
        FilterDateEnd := 0D;
        //Filter Date đổ vào buffer
        if DateFilterInput <> '' then begin
            if StrPos(DateFilterInput, '..') > 0 then begin
                Evaluate(FilterDateStart, CopyStr(DateFilterInput, 1, StrPos(DateFilterInput, '..') - 1));
                Evaluate(FilterDateEnd, CopyStr(DateFilterInput, StrPos(DateFilterInput, '..') + 2));
            end else begin
                Evaluate(FilterDateStart, DateFilterInput);
                FilterDateEnd := FilterDateStart;
            end;
        end;

        //Fill buffer cho 2 sheet
        NextLineNo := 1;
        Redeem.Reset();
        Redeem.DeleteAll();
        Used.Reset();
        Used.DeleteAll();
        FillBuffer(2); // Redeem sheet
        FillBuffer(3); // Used sheet
    end;

    local procedure FillBuffer(StatusFilter: Integer)
    var
        EntryType: Record "LSC POS Data Entry Type";
        PosEntry: Record "LSC POS Data Entry";
        IssueLogLine: Record "wpIssueLogLine";
        ProcessedEntries: List of [Text];
        DateToCheck: Date;
        SheetType: Enum "Taka Voucher Sheet Type";
        ShouldSkip: Boolean;
        StatusEnum: Enum "Status";
        EntryNo: Integer;
        DedupeKey: Text;
    begin
        if StatusFilter = 2 then begin
            SheetType := SheetType::Redeem;
            StatusEnum := StatusEnum::Redeemed;
        end else begin
            SheetType := SheetType::Used;
            StatusEnum := StatusEnum::Used;
        end;

        EntryType.Reset();
        EntryType.SetRange("Enable/ Activate Taka Voucher", true);
        if VoucherTypeFilter <> '' then
            EntryType.SetFilter("Code", VoucherTypeFilter);
        if not EntryType.FindSet() then
            exit;

        repeat
            PosEntry.Reset();
            PosEntry.SetRange("Entry Type", EntryType.Code);
            PosEntry.SetRange("Status", StatusEnum);
            if VoucherNoFilter <> '' then
                PosEntry.SetFilter("Entry Code", VoucherNoFilter);
            if DocumentNoFilter <> '' then
                PosEntry.SetFilter("Document No.", DocumentNoFilter);

            if PosEntry.FindSet() then
                repeat
                    ShouldSkip := false;
                    DateToCheck := 0D;
                    DedupeKey := '';

                    //Lấy date theo từng sheet
                    if StatusFilter = 2 then begin
                        // nếu status = 2 (redeem) thì lấy date redeem
                        DateToCheck := PosEntry."Date Redeemed";

                        EntryNo := 0;
                        IssueLogLine.Reset();
                        //Type = 1 là Entry Code
                        IssueLogLine.SetFilter("Type", '1');
                        IssueLogLine.SetRange("Document No.", PosEntry."Entry Code");
                        if IssueLogLine.FindFirst() then
                            EntryNo := IssueLogLine."Entry No.";

                        if EntryNo = 0 then
                            ShouldSkip := true
                        else
                            DedupeKey := Format(EntryNo);
                    end else begin
                        // nếu status = 3 (used) thì lấy date applied
                        DateToCheck := PosEntry."Date Applied";

                        if PosEntry."Applied by Receipt No." = '' then
                            ShouldSkip := true
                        else
                            DedupeKey := PosEntry."Applied by Receipt No.";
                    end;

                    //skip nếu date = ''
                    if not ShouldSkip then
                        if DateToCheck = 0D then
                            ShouldSkip := true;

                    //filter date
                    if not ShouldSkip then
                        if (FilterDateStart <> 0D) and (FilterDateEnd <> 0D) then
                            if (DateToCheck < FilterDateStart) or
                               (DateToCheck > FilterDateEnd) then
                                ShouldSkip := true;

                    //duplicate check 
                    if not ShouldSkip then begin
                        if ProcessedEntries.Contains(DedupeKey) then
                            ShouldSkip := true
                        else
                            ProcessedEntries.Add(DedupeKey);
                    end;

                    if not ShouldSkip then begin
                        if StatusFilter = 2 then
                            ExpandVoucherRows(PosEntry."Entry Code", DateToCheck,
                                PosEntry."Expiring Date", SheetType, Redeem)
                        else
                            ExpandVoucherRows(PosEntry."Entry Code", DateToCheck,
                                PosEntry."Expiring Date", SheetType, Used);
                    end;

                until PosEntry.Next() = 0;

        until EntryType.Next() = 0;
    end;

    //hàm này lấy voucher, receipt
    //lấy tất cả receipt cho vào mảng (lấy từ bảng log Line có Type = 0)
    //Lấy tất cả voucher (lấy từ bảng log Line có type =1)
    //RowCount = MAX(receiptCount, voucherCount)
    //Lặp mỗi dòng (for i, nếu i < receiptCount -> lấy receipt[i] hoặc lặp đến receipt cuối cùng);
    local procedure ExpandVoucherRows(
    EntryCode: Code[20];
    RowDate: Date;
    ExpireDate: Date;
    SheetType: Enum "Taka Voucher Sheet Type";
    var OutputBuffer: Record "Taka Voucher Report Buffer"
)
    var
        IssueLogLine: Record "wpIssueLogLine";
        IssueLogLine2: Record "wpIssueLogLine";
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        RetailItem: Record "Item";
        IssueLogRec: Record "wpIssueLog";
        PosEntryForVoucher: Record "LSC POS Data Entry";
        PosEntryUsed: Record "LSC POS Data Entry";         //Tách thêm biến này để đếm riêng cho phần Used
        TempGroupBuffer: Record "Taka Voucher Group Buffer" temporary;
        ExcludedDivisions: List of [Code[20]];
        ExcludedItems: List of [Code[20]];
        VoucherID: Code[20];
        VoucherCount: Integer;
        TotalBillValue: Decimal;
        EntryNo: Integer;
        FirstTransNo: Integer;
        FirstPOS: Text[100];
        FirstReceiptFound: Boolean;
        SpecialGrpCode: Code[50];
        AppliedReceiptNo: Code[50];
    begin
        VoucherCount := 0;
        TotalBillValue := 0;
        EntryNo := 0;
        FirstReceiptFound := false;
        FirstTransNo := 0;
        FirstPOS := '';
        VoucherID := '';
        AppliedReceiptNo := '';

        //Lấy voucher ID
        PosEntryForVoucher.Reset();
        PosEntryForVoucher.SetRange("Entry Code", EntryCode);
        if PosEntryForVoucher.FindFirst() then begin
            VoucherID := PosEntryForVoucher."Created by Receipt No.";
            AppliedReceiptNo := PosEntryForVoucher."Applied by Receipt No.";
        end;

        //Gọi hàm LoadExclusions để lấy những exclude item, division
        if VoucherID <> '' then
            LoadExclusions(VoucherID, ExcludedDivisions, ExcludedItems);

        //VoucherCount = số voucher dùng chung trên 1 receipt
        //Lấy bằng cách query pos data entry check field applied by receipt no
        if SheetType = SheetType::Used then begin
            if AppliedReceiptNo = '' then
                exit;
            // Count nhiều voucher trên 1 receipt
            PosEntryUsed.Reset();
            PosEntryUsed.SetRange("Entry Type", PosEntryForVoucher."Entry Type");
            PosEntryUsed.SetRange("Applied by Receipt No.", AppliedReceiptNo);
            PosEntryUsed.SetFilter("Status", '3');
            VoucherCount := PosEntryUsed.Count();
            if VoucherCount = 0 then
                VoucherCount := 1;

            //Lấy TransNo + POS từ receipt
            TransSalesEntry.Reset();
            TransSalesEntry.SetRange("Receipt No.", AppliedReceiptNo);
            if TransSalesEntry.FindFirst() then begin
                FirstTransNo := TransSalesEntry."Transaction No.";
                FirstPOS := TransSalesEntry."POS Terminal No.";
            end;

            //Repeat tất cả item lines của receipt này từ bảng TransSaleEntry, so sánh với
            //bảng wpItemVoucher xem có line nào exclude không
            TransSalesEntry.Reset();
            TransSalesEntry.SetRange("Receipt No.", AppliedReceiptNo);
            if TransSalesEntry.FindSet() then
                repeat
                    if not IsLineExcluded(TransSalesEntry,
                        ExcludedDivisions, ExcludedItems) then
                        TotalBillValue += TransSalesEntry."Price";
                until TransSalesEntry.Next() = 0;

            TransSalesEntry.Reset();
            TransSalesEntry.SetRange("Receipt No.", AppliedReceiptNo);
            if TransSalesEntry.FindSet() then
                repeat
                    if not IsLineExcluded(TransSalesEntry,
                        ExcludedDivisions, ExcludedItems) then begin
                        SpecialGrpCode := '';
                        RetailItem.Reset();
                        RetailItem.SetRange("No.", TransSalesEntry."Item No.");
                        if RetailItem.FindFirst() then begin
                            RetailItem.CalcFields("LSC Special Group Code");
                            SpecialGrpCode := RetailItem."LSC Special Group Code";
                        end;
                        if SpecialGrpCode = '' then
                            SpecialGrpCode := 'NO_GROUP';

                        if (SpecialGroupFilter = '') or
                           (SpecialGrpCode = SpecialGroupFilter) then begin
                            TempGroupBuffer.Reset();
                            TempGroupBuffer.SetRange("Brand", SpecialGrpCode);
                            if TempGroupBuffer.FindFirst() then begin
                                TempGroupBuffer."Bill Value" += TransSalesEntry."Price";
                                TempGroupBuffer.Modify();
                            end else begin
                                TempGroupBuffer.Init();
                                TempGroupBuffer."Brand" := SpecialGrpCode;
                                TempGroupBuffer."Bill Value" := TransSalesEntry."Price";
                                TempGroupBuffer.Insert();
                            end;
                        end;
                    end;
                until TransSalesEntry.Next() = 0;

            if not TempGroupBuffer.FindFirst() then begin
                if SpecialGroupFilter <> '' then
                    exit;
                TempGroupBuffer.Init();
                TempGroupBuffer."Brand" := '';
                TempGroupBuffer."Bill Value" := 0;
                TempGroupBuffer."Voucher Qty" := VoucherCount;
                TempGroupBuffer.Insert();
            end;

            ApplyLargestRemainder(TempGroupBuffer, TotalBillValue, VoucherCount);

            TempGroupBuffer.Reset();
            if not TempGroupBuffer.FindSet() then
                exit;
            repeat
                OutputBuffer.Init();
                OutputBuffer."Sheet Type" := SheetType;
                OutputBuffer."Line No." := NextLineNo;
                OutputBuffer."Entry Code" := EntryCode;
                OutputBuffer."Row Date" := RowDate;
                OutputBuffer."Expire Date" := ExpireDate;
                OutputBuffer."Brand" := TempGroupBuffer."Brand";
                OutputBuffer."Trans No" := FirstTransNo;
                OutputBuffer."POS Terminal" := FirstPOS;
                OutputBuffer."Bill Value" := TempGroupBuffer."Bill Value";
                OutputBuffer."Voucher Qty" := TempGroupBuffer."Voucher Qty";
                OutputBuffer.Insert();
                NextLineNo += 1;
            until TempGroupBuffer.Next() = 0;

            exit;
        end;

        //Redeem Sheet
        //Tìm EntryNo từ bảng LogLine có Type = 1
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

        // Lấy VoucherCount
        IssueLogRec.Reset();
        IssueLogRec.SetRange("Entry No.", EntryNo);
        if IssueLogRec.FindFirst() then
            VoucherCount := IssueLogRec."Voucher Count";
        if VoucherCount = 0 then
            VoucherCount := 1;

        //Loop receipt lines (log line type = 0)
        TempGroupBuffer.Reset();
        TempGroupBuffer.DeleteAll();
        TotalBillValue := 0;

        IssueLogLine2.Reset();
        IssueLogLine2.SetRange("Entry No.", EntryNo);
        IssueLogLine2.SetFilter("Type", '0');
        IssueLogLine2.SetAscending("Line No.", true);

        if IssueLogLine2.FindSet() then
            repeat
                //Lấy TransNo + POS
                TransSalesEntry.Reset();
                TransSalesEntry.SetRange("Receipt No.", IssueLogLine2."Document No.");
                if TransSalesEntry.FindFirst() then
                    if not FirstReceiptFound then begin
                        FirstTransNo := TransSalesEntry."Transaction No.";
                        FirstPOS := TransSalesEntry."POS Terminal No.";
                        FirstReceiptFound := true;
                    end;
                //Tính total bill
                TransSalesEntry.Reset();
                TransSalesEntry.SetRange("Receipt No.", IssueLogLine2."Document No.");
                if TransSalesEntry.FindSet() then
                    repeat
                        if not IsLineExcluded(TransSalesEntry,
                            ExcludedDivisions, ExcludedItems) then
                            TotalBillValue += TransSalesEntry."Price";
                    until TransSalesEntry.Next() = 0;
                TransSalesEntry.Reset();
                TransSalesEntry.SetRange("Receipt No.", IssueLogLine2."Document No.");
                if TransSalesEntry.FindSet() then
                    repeat
                        if not IsLineExcluded(TransSalesEntry,
                            ExcludedDivisions, ExcludedItems) then begin
                            SpecialGrpCode := '';
                            RetailItem.Reset();
                            RetailItem.SetRange("No.", TransSalesEntry."Item No.");
                            if RetailItem.FindFirst() then begin
                                RetailItem.CalcFields("LSC Special Group Code");
                                SpecialGrpCode := RetailItem."LSC Special Group Code";
                            end;
                            if SpecialGrpCode = '' then
                                SpecialGrpCode := 'NO_GROUP';

                            //Check Special Group Filter ở đây
                            if (SpecialGroupFilter = '') or
                               (SpecialGrpCode = SpecialGroupFilter) then begin
                                TempGroupBuffer.Reset();
                                TempGroupBuffer.SetRange("Brand", SpecialGrpCode);
                                if TempGroupBuffer.FindFirst() then begin
                                    TempGroupBuffer."Bill Value" +=
                                        TransSalesEntry."Price";
                                    TempGroupBuffer.Modify();
                                end else begin
                                    TempGroupBuffer.Init();
                                    TempGroupBuffer."Brand" := SpecialGrpCode;
                                    TempGroupBuffer."Bill Value" :=
                                        TransSalesEntry."Price";
                                    TempGroupBuffer.Insert();
                                end;
                            end;
                        end;
                    until TransSalesEntry.Next() = 0;

            until IssueLogLine2.Next() = 0;

        //Skip nếu không có SpecialGroup Filter
        if not TempGroupBuffer.FindFirst() then begin
            if SpecialGroupFilter <> '' then
                exit;
            TempGroupBuffer.Init();
            TempGroupBuffer."Brand" := '';
            TempGroupBuffer."Bill Value" := 0;
            TempGroupBuffer."Voucher Qty" := VoucherCount;
            TempGroupBuffer.Insert();
        end;

        //Pass total bill value
        ApplyLargestRemainder(TempGroupBuffer, TotalBillValue, VoucherCount);

        TempGroupBuffer.Reset();
        if not TempGroupBuffer.FindSet() then
            exit;
        repeat
            OutputBuffer.Init();
            OutputBuffer."Sheet Type" := SheetType;
            OutputBuffer."Line No." := NextLineNo;
            OutputBuffer."Entry Code" := EntryCode;
            OutputBuffer."Row Date" := RowDate;
            OutputBuffer."Expire Date" := ExpireDate;
            OutputBuffer."Brand" := TempGroupBuffer."Brand";
            OutputBuffer."Trans No" := FirstTransNo;
            OutputBuffer."POS Terminal" := FirstPOS;
            OutputBuffer."Bill Value" := TempGroupBuffer."Bill Value";
            OutputBuffer."Voucher Qty" := TempGroupBuffer."Voucher Qty";
            OutputBuffer.Insert();
            NextLineNo += 1;
        until TempGroupBuffer.Next() = 0;
    end;

    //hàm này để loại trừ các dòng có Division hoặc Item nằm trong bảng wpVoucherItemDiscStp với 
    //Exclude = true
    local procedure LoadExclusions(
    VoucherID: Code[20];
    var ExcludedDivisions: List of [Code[20]];
    var ExcludedItems: List of [Code[20]]
)
    var
        ItemDiscStp: Record "wpVoucherItemDiscStp";
    begin
        Clear(ExcludedDivisions);
        Clear(ExcludedItems);

        ItemDiscStp.Reset();
        ItemDiscStp.SetRange("Voucher ID", VoucherID);
        ItemDiscStp.SetRange("Exclude", true);
        if not ItemDiscStp.FindSet() then
            exit;

        repeat
            case ItemDiscStp.Type of
                2: // Division
                    if not ExcludedDivisions.Contains(ItemDiscStp."No.") then
                        ExcludedDivisions.Add(ItemDiscStp."No.");
                6: // Item
                    if not ExcludedItems.Contains(ItemDiscStp."No.") then
                        ExcludedItems.Add(ItemDiscStp."No.");
            end;
        until ItemDiscStp.Next() = 0;
    end;

    //hàm này check coi trans sale entry này có line nào exclude không?
    local procedure IsLineExcluded(
        var TSEntry: Record "LSC Trans. Sales Entry";
        var ExcludedDivisions: List of [Code[20]];
        var ExcludedItems: List of [Code[20]]
    ): Boolean
    begin
        // Check Division
        if ExcludedDivisions.Contains(TSEntry."Division Code") then
            exit(true);

        // Check Item 
        if ExcludedItems.Contains(TSEntry."Item No.") then
            exit(true);

        exit(false);
    end;

    local procedure ApplyLargestRemainder(
    var TempGroupBuffer: Record "Taka Voucher Group Buffer";
    TotalBillValue: Decimal;
    VoucherCount: Integer
)
    var
        VoucherCountDec: Decimal;
        AssignedTotal: Decimal;
        RawQty: Decimal;
        FloorQty: Decimal;
        RemainderSlots: Integer;
        DoneDistributing: Boolean;
    begin
        VoucherCountDec := VoucherCount * 1.0;  //force Decimal

        AssignedTotal := 0;

        //Round group qty tới 2 chữ số
        TempGroupBuffer.Reset();
        if TempGroupBuffer.FindSet() then
            repeat
                if TotalBillValue <> 0 then begin
                    RawQty := (TempGroupBuffer."Bill Value" / TotalBillValue) * VoucherCountDec;
                    // Round qty
                    FloorQty := (Round(RawQty * 100, 1, '<')) / 100;
                end else
                    FloorQty := VoucherCountDec;

                TempGroupBuffer."Voucher Qty" := FloorQty;
                TempGroupBuffer.Modify();
                AssignedTotal += FloorQty;
            until TempGroupBuffer.Next() = 0;

        //Round đến số gần nhất có 2 chữ số ví dụ 0.0199 -> 0.02
        RemainderSlots := Round((VoucherCountDec - AssignedTotal) / 0.01, 1);
        if RemainderSlots <= 0 then
            exit;

        // Nếu còn 0.01 ví dụ (qty 1 / 3 mỗi receipt 0.33) thì chia 0.03
        //cho receipt có giá trị lớn nhất
        TempGroupBuffer.Reset();
        TempGroupBuffer.SetCurrentKey("Bill Value");
        TempGroupBuffer.Ascending(false);
        DoneDistributing := false;

        if TempGroupBuffer.FindSet() then
            repeat
                if not DoneDistributing then begin
                    TempGroupBuffer."Voucher Qty" += 0.01;
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
        TempBuffer: Record "Taka Voucher Report Buffer" temporary;
        NextLineNo: Integer;
        ApplicationManagement: Codeunit "Filter Tokens";
}