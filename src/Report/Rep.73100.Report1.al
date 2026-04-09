report 73100 "Taka Voucher Report"
{
    ApplicationArea = All;
    DefaultRenderingLayout = "TakaVoucherExcelTemplate";
    DataAccessIntent = ReadOnly;
    ExcelLayoutMultipleDataSheets = true;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    MaximumDatasetSize = 1000000;
    Caption = 'Taka Voucher Issued/Redeemed Report';

    dataset
    {
        dataitem(Data; "LSC POS Data Entry Type")
        {
            RequestFilterFields = "Code";
            DataItemTableView = sorting("Code");

            dataitem(itemDataEntry; "LSC POS Data Entry")
            {
                DataItemLinkReference = Data;
                DataItemLink = "Entry Type" = FIELD(Code);

                column(USERID; UserId) { }
                column(COMPANYNAME; CompanyName) { }
                column(DatePrint; DatePrint) { }
                column("DateCreated"; "Date Created") { }
                column("DateActived"; "Date Actived") { }
                column("VoucherAmount"; "Amount") { }
                column("ExpiringDate"; "Expiring Date") { }
                column("DateRedeemed"; DateRedeemedExt) { }   // from ext
                column("DateApplied"; "Date Applied") { }     // from base
                column("TransactionNo"; TransactionNo) { }
                column("PosTerminal"; PosTerminal) { }
                column("Qty"; Qty) { }
                column("EntryCode"; "Entry Code") { }
                column("DocumentNo"; "Document No.") { }
                column("StatusValue"; StatusValue) { }
                column("DateFilterUsed"; DateFilterUsed) { }

                trigger OnPreDataItem()
                begin
                    // Apply filters that belong to itemDataEntry here
                    if VoucherNoFilter <> '' then
                        itemDataEntry.SetFilter("Entry Code", VoucherNoFilter);

                    if DocumentNoFilter <> '' then
                        itemDataEntry.SetFilter("Document No.", DocumentNoFilter);

                    // Status filter: only Redeemed(2) and Used(3)
                    // Use integer values directly to avoid enum reference issues
                    itemDataEntry.SetFilter("Status", '2|3');

                    // Parse date range upfront
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

                    DatePrint := Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>');
                end;

                trigger OnAfterGetRecord()
                var
                    voucherEntries: Record "LSC Voucher Entries";
                    DateToCheck: Date;
                begin
                    Clear(TransactionNo);
                    Clear(PosTerminal);
                    Qty := 0;
                    DateRedeemedExt := "Date Redeemed";  // ext field (field 73104)
                    StatusValue := "Status".AsInteger();

                    // Status 3 Used -> check Date Applied (base table)
                    // Status 2 Redeemed -> check Date Redeemed (ext table field 73104)
                    if StatusValue = 3 then
                        DateToCheck := "Date Applied"
                    else
                        DateToCheck := "Date Redeemed";  // ext field

                    DateFilterUsed := DateToCheck;

                    // Skip if date not in range
                    if (FilterDateStart <> 0D) and (FilterDateEnd <> 0D) then
                        if (DateToCheck < FilterDateStart) or (DateToCheck > FilterDateEnd) then
                            CurrReport.Skip();

                    // Skip if date is empty (1753 = BC empty date)
                    if DateToCheck = 0D then
                        CurrReport.Skip();

                    voucherEntries.SetRange("Voucher No.", "Entry Code");
                    voucherEntries.SetRange("Entry Type", 1);
                    if voucherEntries.FindFirst() then begin
                        TransactionNo := voucherEntries."Transaction No.";
                        PosTerminal := voucherEntries."POS Terminal No.";
                        Qty := 1;
                    end;
                end;
            }

            trigger OnPreDataItem()
            begin
                Data.SetRange("Enable/ Activate Taka Voucher", true);

                // VoucherTypeFilter applied here on the OUTER dataitem where it belongs
                if VoucherTypeFilter <> '' then
                    Data.SetFilter("Code", VoucherTypeFilter);
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
                    field("Date Redeemed/Applied"; DateFilterInput)
                    {
                        Caption = 'Date Redeemed / Used';
                        trigger OnValidate()
                        begin
                            ApplicationManagement.MakeDateFilter(DateFilterInput);
                        end;
                    }
                    field("Document No"; DocumentNoFilter)
                    {
                        Caption = 'Document No.';
                    }
                    field("Voucher No"; VoucherNoFilter)
                    {
                        Caption = 'Voucher No.';
                        TableRelation = "LSC Voucher Entries";
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

    var
        DatePrint: Text[100];
        DateFilterInput: Text[100];
        FilterDateStart: Date;
        FilterDateEnd: Date;
        DocumentNoFilter: Code[20];
        VoucherNoFilter: Code[20];
        VoucherTypeFilter: Code[20];
        TransactionNo: Integer;
        PosTerminal: Text[100];
        Qty: Integer;
        StatusValue: Integer;
        DateFilterUsed: Date;
        DateRedeemedExt: Date;
        ApplicationManagement: Codeunit "Filter Tokens";
}