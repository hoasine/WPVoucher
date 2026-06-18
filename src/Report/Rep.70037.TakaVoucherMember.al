report 70037 "Taka Voucher Member Summary"
{
    ApplicationArea = All;
    DefaultRenderingLayout = "TakaVoucherMembershipExcel";
    DataAccessIntent = ReadOnly;
    ExcelLayoutMultipleDataSheets = true;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    MaximumDatasetSize = 1000000;
    Caption = 'Taka Voucher Member Summary';

    dataset
    {
        dataitem(Data; Integer)
        {
            DataItemTableView = sorting(Number);

            column(Benefits; Benefits) { }
            column(MemberCodeName; MemberNames) { }
            column(QuantityOfMembers; TotalMember) { }
            column(VoucherAmount; Amount) { }
            column(TotalVCRedeem; RedeemedVoucher) { }
            column(TotalVCUsed; UsedVoucher) { }

            trigger OnPreDataItem()
            begin
                if DateRedeemedFilter = '' then
                    Error('Please select Date range!');

                BuildResultTable();
                SetRange(Number, 1, TempResult.Count);
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempResult.FindFirst()
                else
                    TempResult.Next();

                Benefits := TempResult.CampaignName;
                MemberNames := TempResult.MemberCards;
                TotalMember := TempResult.TotalMember;
                Amount := TempResult.Amount;
                RedeemedVoucher := TempResult.RedeemedVoucher;
                UsedVoucher := TempResult.UsedVoucher;
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
                        Caption = 'Voucher Type';
                        TableRelation = "LSC POS Data Entry Type";
                    }
                    field("Voucher Campaign"; DocumentNoFilter)
                    {
                        Caption = 'Voucher Campaign';
                        TableRelation = wpVoucherMaintenance.ID;
                    }
                    field("Date Redeemed"; DateRedeemedFilter)
                    {
                        Caption = 'Date Redeemed (Range)';
                        trigger OnValidate()
                        begin
                            ApplicationManagement.MakeDateFilter(DateRedeemedFilter);
                        end;
                    }
                }
            }
        }
    }

    rendering
    {
        layout(TakaVoucherMembershipExcel)
        {
            Type = Excel;
            LayoutFile = 'src/ReportLayouts/Excel/Rep.70037.TakaVoucherMemberSummary.xlsx';
            Caption = 'Taka Voucher Member Summary';
        }
    }

    var
        DocumentNoFilter: Code[20];
        VoucherTypeFilter: Code[20];
        DateRedeemedFilter: Text[100];
        Benefits: Text[100];
        MemberNames: Text[2048];
        TotalMember: Integer;
        Amount: Decimal;
        RedeemedVoucher: Integer;
        UsedVoucher: Integer;
        ApplicationManagement: Codeunit "Filter Tokens";
        TempResult: Record wpTempVoucherMemberResult temporary;

    local procedure BuildResultTable()
    var
        VoucherCampaign: Record wpVoucherMaintenance;
        PosEntry: Record "LSC POS Data Entry";
        StartDate: Date;
        EndDate: Date;
        RowNo: Integer;
        SeenDenomList: Text[2048];
        LineDenom: Decimal;
        DenomParts: List of [Text];
        DenomText: Text;
        DenomVal: Decimal;
    begin
        TempResult.DeleteAll();
        RowNo := 0;

        ParseDateFilter(DateRedeemedFilter, StartDate, EndDate);

        VoucherCampaign.Reset();
        if DocumentNoFilter <> '' then
            VoucherCampaign.SetRange(ID, DocumentNoFilter);

        if not VoucherCampaign.FindSet() then
            exit;

        repeat
            // --- Step 1: Collect distinct denominations from POS Data Entry directly ---
            // Works even when IssueLog is empty (bulk import / paper voucher case)
            SeenDenomList := '';

            // Status=2 (Redeemed): date filter on "Date Redeemed" ext field
            PosEntry.Reset();
            if VoucherTypeFilter <> '' then
                PosEntry.SetRange("Entry Type", VoucherTypeFilter);
            PosEntry.SetRange("Created by Receipt No.", VoucherCampaign.ID);
            PosEntry.SetRange("Status", 2);
            PosEntry.SetRange("Date Redeemed", StartDate, EndDate);
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

            // Status=3 (Used): date filter on "Date Applied" base field
            PosEntry.Reset();
            if VoucherTypeFilter <> '' then
                PosEntry.SetRange("Entry Type", VoucherTypeFilter);
            PosEntry.SetRange("Created by Receipt No.", VoucherCampaign.ID);
            PosEntry.SetRange("Status", 3);
            PosEntry.SetRange("Date Applied", StartDate, EndDate);
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

            // Fallback: no activity in date range -> show one row with face value, counts = 0
            if SeenDenomList = '' then
                SeenDenomList := Format(GetVoucherDenomination(VoucherCampaign.ID), 0, 9);

            // --- Step 2: One row per denomination ---
            DenomParts := SeenDenomList.Split('|');
            foreach DenomText in DenomParts do begin
                Evaluate(DenomVal, DenomText);
                BuildRowForDenom(
                    VoucherCampaign.ID,
                    VoucherCampaign.Description,
                    DenomVal,
                    StartDate, EndDate,
                    RowNo);
            end;

        until VoucherCampaign.Next() = 0;
    end;

    local procedure DenomAlreadySeen(SeenList: Text[2048]; Denom: Decimal): Boolean
    begin
        if SeenList = '' then
            exit(false);
        exit(StrPos('|' + SeenList + '|', '|' + Format(Denom, 0, 9) + '|') > 0);
    end;

    local procedure BuildRowForDenom(
        CampaignID: Code[20];
        CampaignName: Text[100];
        Denom: Decimal;
        StartDate: Date;
        EndDate: Date;
        var RowNo: Integer)
    var
        IssueLog: Record wpIssueLog;
        IssueLogLine: Record wpIssueLogLine;
        PosEntry: Record "LSC POS Data Entry";
        MemberNamesList: Text[2048];
        SeenCardsList: Text[2048];
        MemberCount: Integer;
        CurrentCard: Text[50];
        MemberName: Text[100];
        HasNonMember: Boolean;
        RedeemCount: Integer;
        UsedCount: Integer;
        IssueLogHasThisDenom: Boolean;
    begin
        MemberNamesList := '';
        SeenCardsList := '';
        MemberCount := 0;
        HasNonMember := false;
        RedeemCount := 0;
        UsedCount := 0;

        // --- Member names: from IssueLog (only available for normal UI flow) ---
        IssueLog.Reset();
        IssueLog.SetRange("Voucher ID", CampaignID);
        IssueLog.SetRange("Redeemp Date", StartDate, EndDate);

        if IssueLog.FindSet() then
            repeat
                // Check denomination by looking at first voucher line's POS amount
                IssueLogHasThisDenom := false;
                IssueLogLine.Reset();
                IssueLogLine.SetRange("Entry No.", IssueLog."Entry No.");
                IssueLogLine.SetRange(Type, 1);
                if IssueLogLine.FindFirst() then begin
                    PosEntry.Reset();
                    if VoucherTypeFilter <> '' then
                        PosEntry.SetRange("Entry Type", VoucherTypeFilter);
                    PosEntry.SetRange("Entry Code", IssueLogLine."Document No.");
                    PosEntry.SetRange("Created by Receipt No.", CampaignID);
                    if PosEntry.FindFirst() then
                        IssueLogHasThisDenom := (PosEntry.Amount = Denom);
                end;

                if IssueLogHasThisDenom then begin
                    CurrentCard := IssueLog."Member Card";
                    if CurrentCard <> '' then begin
                        if not CardAlreadySeen(SeenCardsList, CurrentCard) then begin
                            if SeenCardsList = '' then
                                SeenCardsList := CurrentCard
                            else
                                SeenCardsList := SeenCardsList + '|' + CurrentCard;
                            MemberCount += 1;
                            MemberName := GetMemberName(CurrentCard);
                            if MemberNamesList = '' then
                                MemberNamesList := MemberName
                            else
                                MemberNamesList := MemberNamesList + ';' + MemberName;
                        end;
                    end else
                        HasNonMember := true;
                end;
            until IssueLog.Next() = 0;

        if HasNonMember then begin
            MemberCount += 1;
            if MemberNamesList = '' then
                MemberNamesList := 'No Member'
            else
                MemberNamesList := MemberNamesList + ';No Member';
        end;

        // --- Counts: always from POS Data Entry (works even without IssueLog) ---
        // Status=2 Redeemed: filter by "Date Redeemed" + Denom
        PosEntry.Reset();
        if VoucherTypeFilter <> '' then
            PosEntry.SetRange("Entry Type", VoucherTypeFilter);
        PosEntry.SetRange("Created by Receipt No.", CampaignID);
        PosEntry.SetRange("Status", 2);
        PosEntry.SetRange("Date Redeemed", StartDate, EndDate);
        PosEntry.SetRange(Amount, Denom);
        RedeemCount := PosEntry.Count();

        // Status=3 Used: filter by "Date Applied" + Denom
        PosEntry.Reset();
        if VoucherTypeFilter <> '' then
            PosEntry.SetRange("Entry Type", VoucherTypeFilter);
        PosEntry.SetRange("Created by Receipt No.", CampaignID);
        PosEntry.SetRange("Status", 3);
        PosEntry.SetRange("Date Applied", StartDate, EndDate);
        PosEntry.SetRange(Amount, Denom);
        UsedCount := PosEntry.Count();

        RowNo += 1;
        TempResult.RowNo := RowNo;
        TempResult.CampaignID := CampaignID;
        TempResult.CampaignName := CampaignName;
        TempResult.MemberCards := MemberNamesList;
        TempResult.TotalMember := MemberCount;
        TempResult.Amount := Denom;
        TempResult.RedeemedVoucher := RedeemCount + UsedCount;
        TempResult.UsedVoucher := UsedCount;
        TempResult.Insert();
    end;

    local procedure CardAlreadySeen(SeenList: Text[2048]; CardNo: Text[50]): Boolean
    begin
        if SeenList = '' then
            exit(false);
        exit(StrPos('|' + SeenList + '|', '|' + CardNo + '|') > 0);
    end;

    local procedure GetMemberName(CardNo: Text[50]): Text[100]
    var
        MemberCard: Record "LSC Membership Card";
        MemberAccount: Record "LSC Member Account";
    begin
        MemberCard.Reset();
        MemberCard.SetRange("Card No.", CardNo);
        if not MemberCard.FindFirst() then
            exit(CardNo);

        MemberAccount.Reset();
        MemberAccount.SetRange("No.", MemberCard."Account No.");
        if not MemberAccount.FindFirst() then
            exit(MemberCard."Account No.");

        if MemberAccount.Description <> '' then
            exit(MemberAccount."No." + '\' + MemberAccount.Description);

        exit(MemberAccount."No.");
    end;

    local procedure GetVoucherDenomination(CampaignID: Code[20]): Decimal
    var
        PosEntry: Record "LSC POS Data Entry";
    begin
        PosEntry.Reset();
        if VoucherTypeFilter <> '' then
            PosEntry.SetRange("Entry Type", VoucherTypeFilter);
        PosEntry.SetRange("Created by Receipt No.", CampaignID);
        if PosEntry.FindFirst() then
            exit(PosEntry.Amount);
        exit(0);
    end;

    local procedure ParseDateFilter(FilterText: Text; var StartDate: Date; var EndDate: Date)
    var
        DotDotPos: Integer;
    begin
        DotDotPos := StrPos(FilterText, '..');
        if DotDotPos > 0 then begin
            Evaluate(StartDate, CopyStr(FilterText, 1, DotDotPos - 1));
            Evaluate(EndDate, CopyStr(FilterText, DotDotPos + 2));
        end else begin
            Evaluate(StartDate, FilterText);
            EndDate := StartDate;
        end;
    end;
}
