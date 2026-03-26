// report 73100 "Taka Voucher Report"
// {
//     ApplicationArea = All;
//     // DefaultRenderingLayout = "MemberdayAllowanceDetail";
//     DataAccessIntent = ReadOnly;
//     ExcelLayoutMultipleDataSheets = true;
//     PreviewMode = PrintLayout;
//     UsageCategory = ReportsAndAnalysis;
//     MaximumDatasetSize = 1000000;
//     Caption = 'Taka Voucher Isssued/Redeemed Report';

//     dataset
//     {
//         dataitem(Data; voucher)
//         {
//             RequestFilterFields = ID;
//             DataItemTableView = sorting(ID);

//             dataitem(LSCTranSalesEntry; "LSC Trans. Sales Entry")
//             {
//                 DataItemLinkReference = Data;


//                 column(USERID; UserId)
//                 {
//                 }
//                 column(COMPANYNAME; CompanyName)
//                 {
//                 }
//                 column(DatePrint; DatePrint)
//                 {
//                 }
//                 column(StartDateFilter; DateTarget) { }
//                 column(suppliercd; suppliercd) { }
//                 column(supplier_Name; supplierName) { }
//                 column(brdnm; itemSpecialGrpDesc) { }
//                 column(terminalNo; "POS Terminal No.") { }
//                 column(recDate; DateFormat) { }
//                 // column("ExcludeVATAmount"; "Net Amount") { }
//                 // column("IncludeVATAmount"; "Total Rounded Amt.") { }
//                 column(allowanceInclVAT; -allowanceInclVAT) { }
//                 column(allowanceExclVAT; -allowanceExclVAT) { }
//                 column(allowInclVAT; -allowInclVAT) { }
//                 column(allowExcVAT; -allowExclVAT) { }
//                 column(SaleAmount; -"Total Rounded Amt.") { }
//                 column(VAT; -VAT) { }
//                 column(transNo; transNo) { }

//                 trigger OnPreDataItem()
//                 begin
//                     if Data."Applicable For" = Data."Applicable For"::Member then
//                         SetRange("wp Member Allowance ID", Data.ID);

//                     if Data."Applicable For" = Data."Applicable For"::Staff then
//                         SetRange("wp Staff Allowance ID", Data.ID);

//                     if DateFilter = '' then
//                         Error('Please input Date!');

//                     LSCTranSalesEntry.SetFilter(Date, DateFilter);
//                 end;

//                 trigger OnAfterGetRecord()
//                 var
//                     tbentryAllowance: Record "wpStaffAllowanceEntry";
//                     tbTranHeader: Record "LSC Transaction Header";
//                     allowaneIncTotal: Decimal;
//                     totalPayment: Decimal;
//                 begin
//                     DateTarget := ParseDateRangeOfFilter(DateFilter);
//                     DatePrint := FORMAT(Today(), 0, '<Day,2>/<Month,2>/<Year4>');

//                     if Data."Applicable For" = Data."Applicable For"::Member then
//                         SetRange("wp Member Allowance ID", Data.ID);

//                     if Data."Applicable For" = Data."Applicable For"::Staff then
//                         SetRange("wp Staff Allowance ID", Data.ID);

//                     Clear(vatPerc);
//                     Clear(suppliercd);
//                     Clear(supplierName);
//                     Clear(itemSpecialGrpDesc);
//                     Clear(allowanceInclVAT);
//                     Clear(allowanceExclVAT);

//                     posVATCode.Reset();
//                     posVATCode.SetRange("VAT Code", "VAT Code");
//                     if posVATCode.FindFirst() then
//                         vatPerc := posVATCode."VAT %";
//                     if vatPerc = 0 then vatPerc := 1;

//                     transNo := Format(LSCTranSalesEntry."Transaction No.");

//                     Clear(tbentryAllowance);
//                     tbentryAllowance.SetRange("Receipt No.", "Receipt No.");
//                     tbentryAllowance.SetRange("Store No.", "Store No.");
//                     if tbentryAllowance.FindSet() then
//                         allowaneIncTotal := -tbentryAllowance."Discount Amount";

//                     Clear(tbTranHeader);
//                     tbTranHeader.SetRange("Receipt No.", "Receipt No.");
//                     tbTranHeader.SetRange("Store No.", "Store No.");
//                     if tbTranHeader.FindSet() then
//                         totalPayment := tbTranHeader."Payment";

//                     // allowanceInclVAT := Round(((LSCTranSalesEntry."Total Rounded Amt." / totalPayment) * allowaneIncTotal));
//                     allowanceInclVAT := -Round((LSCTranSalesEntry."wp Staff Disc. Amount" + LSCTranSalesEntry."wp Member Disc. Amount"), 1);
//                     allowanceExclVAT := Round((allowanceInclVAT / (1 + vatPerc / 100)));

//                     allowInclVAT := allowanceInclVAT / 2;
//                     allowExclVAT := allowanceExclVAT / 2;

//                     VAT := (allowInclVAT - allowExclVAT);

//                     item.Reset();
//                     if item.get("Item No.") then begin
//                         // ✅ Kiểm tra vendor filter: nếu có filter mà vendor hiện tại không match thì bỏ qua record
//                         item.CalcFields("LSC Special Group Code");

//                         if VendorFilter <> '' then begin
//                             if (VendorFilter <> item."Vendor No.") then begin
//                                 CurrReport.Skip();
//                             end;
//                         end;

//                         if SpecialGroupFilter <> '' then begin
//                             if (SpecialGroupFilter <> item."LSC Special Group Code") then begin
//                                 CurrReport.Skip();
//                             end;
//                         end;

//                         suppliercd := item."Vendor No.";

//                         ExcludeVATAmount := "Total Rounded Amt." - "VAT Amount";
//                         DateFormat := FORMAT(Date, 0, '<Day,2>/<Month,2>/<Year4>');

//                         itemSpecialGrpLink.Reset();
//                         itemSpecialGrpLink.SetRange("Item No.", item."No.");
//                         itemSpecialGrpLink.SetAutoCalcFields("Special Group Name");
//                         if itemSpecialGrpLink.FindFirst() then
//                             itemSpecialGrpDesc := itemSpecialGrpLink."Special Group Name";

//                         vendor.Reset();
//                         if vendor.get(item."Vendor No.") then begin
//                             supplierName := vendor.Name;
//                         end;
//                     end;
//                 end;
//             }
//         }
//     }

//     // requestpage
//     // {
//     //     layout
//     //     {
//     //         area(Content)
//     //         {
//     //             group(Option)
//     //             {
//     //                 field("Date"; DateFilter)
//     //                 {
//     //                     trigger OnValidate()
//     //                     begin
//     //                         ApplicationManagement.MakeDateFilter(DateFilter);
//     //                     end;
//     //                 }
//     //                 field("Vendor"; VendorFilter)
//     //                 {
//     //                     TableRelation = "Vendor";
//     //                 }
//     //                 field("Special Group (Brand)"; SpecialGroupFilter)
//     //                 {
//     //                     TableRelation = "LSC Item Special Groups";
//     //                 }
//     //             }
//     //         }
//     //     }
//     // }

//     // rendering
//     // {
//     //     layout(MemberdayAllowanceDetail)
//     //     {
//     //         Type = Excel;
//     //         LayoutFile = 'src/ReportLayouts/Excel/Rep.70017.MemberdayAllowanceDetail.xlsx';
//     //         Caption = 'Memberday Allowance Detail';
//     //         Summary = 'src/ReportLayouts/Excel/Rep.70017.MemberdayAllowanceDetail.xlsx';
//     //     }
//     // }

//     // procedure ParseDateRangeOfFilter(DateRange: Text): Text
//     // var
//     //     StartStr: Text[20];
//     //     EndStr: Text[20];
//     //     StartDate: Date;
//     //     EndDate: Date;
//     //     SeparatorPos: Integer;
//     //     ResultText: Text;
//     // begin
//     //     SeparatorPos := StrPos(DateRange, '..');

//     //     if SeparatorPos > 0 then begin
//     //         // Có khoảng ngày
//     //         StartStr := CopyStr(DateRange, 1, SeparatorPos - 1);
//     //         EndStr := CopyStr(DateRange, SeparatorPos + 2);

//     //         Evaluate(StartDate, StartStr); // chuyển sang kiểu Date
//     //         Evaluate(EndDate, EndStr);

//     //         ResultText := Format(StartDate, 0, '<Day,2>/<Month,2>/<Year4>')
//     //             + '-' +
//     //             Format(EndDate, 0, '<Day,2>/<Month,2>/<Year4>');
//     //     end else begin
//     //         // Chỉ có 1 ngày
//     //         Evaluate(StartDate, DateRange);
//     //         ResultText := Format(StartDate, 0, '<Day,2>/<Month,2>/<Year4>');
//     //     end;

//     //     exit(ResultText);
//     // end;

//     // var
//     //     item: Record Item;
//     //     vendor: Record Vendor;
//     //     posVATCode: Record "LSC POS VAT Code";
//     //     itemSpecialGrpLink: Record "LSC Item/Special Group Link";
//     //     wpStaffAllowanceByVendor: Record wpStaffAllowanceByVendor;
//     //     POSFunctionalityProfile: Record "LSC POS Func. Profile";
//     //     vatPerc: Decimal;
//     //     suppliercd: Code[20];
//     //     supplierName: Text[100];
//     //     itemSpecialGrpDesc: Text[30];
//     //     allowanceInclVAT: Decimal;
//     //     allowanceExclVAT: Decimal;
//     //     allowInclVAT: Decimal;
//     //     allowExclVAT: Decimal;
//     //     VAT: Decimal;
//     //     costSharingAllIncVAT: Decimal;
//     //     costSharingExclVAT: Decimal;
//     //     DateFilter: text[100];
//     //     ExcludeVATAmount: Decimal;
//     //     ApplicationManagement: Codeunit "Filter Tokens";
//     //     DatePrint: text[100];
//     //     DateTarget: text[100];
//     //     DateFormat: text[100];
//     //     SpecialGroupFilter: text[100];
//     //     transNo: text[100];
//     //     VendorFilter: text[100];

// }

