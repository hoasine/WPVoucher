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
                column(brdnm; itemSpecialGrpDesc) { }

                column("DateCreated"; "Date Created") { }
                column("DateActived"; "Date Actived") { }
                column("VoucherAmount"; "Amount") { }
                column("ExpiringDate"; "Expiring Date") { }
                column("DateRedeemed"; "Date Redeemed") { }
                column("Brand"; "Brand") { }
                column("TransactionNo"; "TransactionNo") { }
                column("PosTerminal"; "PosTerminal") { }
                column("Qty"; "Qty") { }
                column("EntryCode"; "Entry Code") { }
                column("DocumentNo"; "Document No.") { }
                column("DateCreatedd"; DateCreatedFilter) { }

                trigger OnPreDataItem()
                begin
                    if DateCreatedFilter <> '' then
                        itemDataEntry.SetFilter("Date Created", DateCreatedFilter);

                    if VoucherTypeFilter <> '' then
                        Data.SetFilter("Code", VoucherTypeFilter);

                    if VoucherNoFilter <> '' then
                        itemDataEntry.SetFilter("Entry Code", VoucherNoFilter);

                    if DocumentNoFilter <> '' then
                        itemDataEntry.SetFilter("Document No.", DocumentNoFilter);

                    DatePrint := Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>');
                end;

                trigger OnAfterGetRecord()
                var
                    voucherEntries: Record "LSC Voucher Entries";
                begin
                    Clear(TransactionNo);
                    Clear(PosTerminal);
                    Qty := 0;

                    voucherEntries.SetRange("Voucher No.", "Entry Code");
                    voucherEntries.SetRange("Entry Type", 1); // Redeemed
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
                    field("Date Created"; DateCreatedFilter)
                    {
                        Caption = 'Date Created';
                        trigger OnValidate()
                        begin
                            ApplicationManagement.MakeDateFilter(DateCreatedFilter);
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
        itemSpecialGrpLink: Record "LSC Item/Special Group Link";
        itemSpecialGrpDesc: Text[30];
        DatePrint: Text[100];
        DateCreatedFilter: Text[100];
        DocumentNoFilter: Code[20];
        VoucherNoFilter: Code[20];
        VoucherTypeFilter: Code[20];
        TransactionNo: Integer;
        PosTerminal: Text[100];
        Qty: Integer;
        ApplicationManagement: Codeunit "Filter Tokens";
        Brand: Text[100];
}