report 73100 "Taka Voucher Report"
{
    ApplicationArea = All;
    DefaultRenderingLayout = "TakaVoucherExcelTemplate";
    DataAccessIntent = ReadOnly;
    ExcelLayoutMultipleDataSheets = true;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    MaximumDatasetSize = 1000000;
    Caption = 'Taka Voucher Isssued/Redeemed Report';

    dataset
    {
        dataitem(Data; "LSC POS Data Entry Type")
        {
            RequestFilterFields = "Code";
            DataItemTableView = sorting("Code");


            dataitem(itemDataEntry; "LSC POS Data Entry")
            {
                DataItemLinkReference = Data;

                column(USERID; UserId) { }
                column(COMPANYNAME; CompanyName) { }
                column(DatePrint; DatePrint) { }
                column(StartDateFilter; DateTarget) { }
                column(brdnm; itemSpecialGrpDesc) { }
                column(recDate; DateFormat) { }

                column("DateActived"; "Date Actived") { }
                column("VoucherAmount"; "Amount") { }
                column("ExpiringDate"; "Expiring Date") { }
                column("DateRedeemed"; "Date Redeemed") { }
                column("Brand"; "Brand") { }
                column("TransactionNo"; "TransactionNo") { }
                column("PosTerminal"; "PosTerminal") { }
                column("Qty"; "Qty") { }

                trigger OnPreDataItem()
                begin
                    // if DateFilter = '' then
                    //     Error('Please input Date!');

                    // itemDataEntry.SetFilter("Date Actived", DateFilter); //Issue
                    // itemDataEntry.SetFilter("Date Redeemed", DateFilter); //Redeemed

                    if VoucherNoFilter = '' then begin
                        itemDataEntry.SetFilter("Entry Code", VoucherNoFilter);
                    end;

                    if DocumentNoFilter = '' then begin
                        itemDataEntry.SetFilter("Document No.", DocumentNoFilter);
                    end;

                    DatePrint := Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>');
                end;

                trigger OnAfterGetRecord()
                var
                    voucherEntries: Record "LSC Voucher Entries";
                begin
                    Clear(voucherEntries);
                    voucherEntries.SetRange("Voucher No.", itemDataEntry."Entry Code");
                    voucherEntries.SetRange("Entry Type", 1); //Status Redeemp
                    if voucherEntries.FindFirst() then begin
                        TransactionNo := voucherEntries."Transaction No.";
                        PosTerminal := voucherEntries."POS Terminal No.";
                        Qty := 1;
                    end;
                end;
            }

            trigger OnPreDataItem()
            begin
                data.SetRange("Enable/ Activate Taka Voucher", true);

                if VoucherTypeFilter = '' then begin
                    Data.SetFilter("Code", VoucherTypeFilter);
                end;
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
                        TableRelation = "LSC POS Data Entry";
                    }
                    // field("Date"; DateFilter)
                    // {
                    //     trigger OnValidate()
                    //     begin
                    //         ApplicationManagement.MakeDateFilter(DateFilter);
                    //     end;
                    // }
                    field("Document No"; DocumentNoFilter)
                    {
                    }
                    field("Voucher No"; VoucherNoFilter)
                    {
                        TableRelation = "LSC Voucher Entries";
                    }
                    // field("Special Group (Brand)"; SpecialGroupFilter)
                    // {
                    //     TableRelation = "LSC Item Special Groups";
                    // }
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
            Caption = 'Taka Voucher Isssued/Redeemed Report';
            Summary = 'src/ReportLayouts/Excel/Rep.73100.TakaVoucherIsssuedRedeemedReport.xlsx';
        }
    }

    // procedure ParseDateRangeOfFilter(DateRange: Text): Text
    // var
    //     StartStr: Text[20];
    //     EndStr: Text[20];
    //     StartDate: Date;
    //     EndDate: Date;
    //     SeparatorPos: Integer;
    //     ResultText: Text;
    // begin
    //     SeparatorPos := StrPos(DateRange, '..');

    //     if SeparatorPos > 0 then begin
    //         // Có khoảng ngày
    //         StartStr := CopyStr(DateRange, 1, SeparatorPos - 1);
    //         EndStr := CopyStr(DateRange, SeparatorPos + 2);

    //         Evaluate(StartDate, StartStr); // chuyển sang kiểu Date
    //         Evaluate(EndDate, EndStr);

    //         ResultText := Format(StartDate, 0, '<Day,2>/<Month,2>/<Year4>')
    //             + '-' +
    //             Format(EndDate, 0, '<Day,2>/<Month,2>/<Year4>');
    //     end else begin
    //         // Chỉ có 1 ngày
    //         Evaluate(StartDate, DateRange);
    //         ResultText := Format(StartDate, 0, '<Day,2>/<Month,2>/<Year4>');
    //     end;

    //     exit(ResultText);
    // end;

    var
        itemSpecialGrpLink: Record "LSC Item/Special Group Link";
        itemSpecialGrpDesc: Text[30];
        DateFilter: text[100];
        ApplicationManagement: Codeunit "Filter Tokens";
        DatePrint: text[100];
        DateTarget: text[100];
        DateFormat: text[100];
        SpecialGroupFilter: text[100];
        DocumentNoFilter: text[100];
        VoucherNoFilter: text[100];
        Brand: text[100];
        TransactionNo: Integer;
        PosTerminal: text[100];
        VoucherTypeFilter: text[100];
        Qty: Integer;
}

