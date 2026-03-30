page 73107 "Issuance Management"
{
    ApplicationArea = All;
    Caption = 'Taka Voucher Issuance Management';
    SourceTable = "LSC Trans. Sales Entry";
    UsageCategory = ReportsAndAnalysis;
    PageType = List;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    SaveValues = false;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Scan infomation';
                field(ScanMember; ScanMemberFilter)
                {
                    Caption = 'Scan Member';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if ScanMemberFilter = '' then begin
                            exit;
                        end;

                        GetMemberInfo(ScanMemberFilter);
                    end;
                }
                field(ScanReceipt; ScanReceiptFilter)
                {
                    Caption = 'Scan Receipt';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if ScanMemberFilter = '' then begin
                            Message('Please scan the member card before scanning the receipt!');
                            exit;
                        end;

                        if ScanReceiptFilter = '' then
                            exit;

                        AddReceiptToTemp(ScanReceiptFilter);

                        Clear(ScanReceiptFilter);
                    end;
                }
            }
            group(Summary)
            {
                Caption = 'Summary Price';
                ShowCaption = false;

                group(Sum1)
                {
                    Caption = 'Member Infomation';

                    field(MemberDescription; MemberDescription)
                    {
                        Caption = 'Name';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(MembershipCard; MembershipCard)
                    {
                        Caption = 'Card No';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(MemberAccount; MemberAccount)
                    {
                        Caption = 'Member Account';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(MemberScheme; MemberScheme)
                    {
                        Caption = 'Member Scheme';
                        ApplicationArea = All;
                        Editable = false;
                    }
                }
                group(Sum2)
                {
                    Caption = 'Item Summary';
                    field(ReceiptCounted; ReceiptCountedFilter)
                    {
                        Caption = 'Receipt Counted';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(TotalItemValid; -TotalItemValid)
                    {
                        Caption = 'Item Valid';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(TotalQuantity; -TotalQuantity)
                    {
                        Caption = 'Total Item';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(TotalSaleAmount; -TotalSale)
                    {
                        Caption = 'Sale Amount';
                        ApplicationArea = All;
                        Editable = false;
                    }
                }
            }
            group(ReceiptList)
            {
                Caption = 'Receipt List';
                Editable = false;

                repeater(Control1)
                {
                    ShowCaption = false;
                    field("Receipt No."; Rec."Receipt No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Item No."; Rec."Item No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Item Status"; Rec."Voucher Status Temp")
                    {
                        ApplicationArea = All;
                        StyleExpr = VoucherStyle;
                    }
                    field("Barcode No."; Rec."Barcode No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Description"; Rec."Item Description")
                    {
                        ApplicationArea = All;
                    }
                    field("Division"; Rec."Division Code")
                    {
                        ApplicationArea = All;
                    }
                    field("Retail Product Group"; Rec."Retail Product Code")
                    {
                        ApplicationArea = All;
                    }
                    field("Quantity"; Rec."Quantity")
                    {
                        ApplicationArea = All;
                    }
                    field("Price"; Rec."Price")
                    {
                        ApplicationArea = All;
                    }
                    field("Dis Amount"; Rec."Discount Amount")
                    {
                        ApplicationArea = All;
                    }
                    field("Amount"; Rec."Total Rounded Amt.")
                    {
                        ApplicationArea = All;
                    }
                    field("Member Account"; "MemberAccount")
                    {
                        ApplicationArea = All;
                    }
                    field("Member Contact"; "MemberContact")
                    {
                        ApplicationArea = All;
                    }
                    field("Member Club"; "MemberClub")
                    {
                        ApplicationArea = All;
                    }
                    field("Member Scheme"; "MemberScheme")
                    {
                        ApplicationArea = All;
                    }

                }
            }
            part(VoucherBudgetPart; "Voucher Budget Buffer")
            {
                UpdatePropagation = Both;
                Editable = false;
                Visible = ShowVoucherBudgetPart;
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ClearData)
            {
                Caption = 'Clear Data';
                Image = ClearFilter;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;


                trigger OnAction()
                begin
                    ClearAllData(true);
                end;
            }
            action("&Update")
            {
                ApplicationArea = All;
                Caption = '&Get Taka Voucher';
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    RefilterVoucherBudget();

                    if TempVoucherBudget.Count = 0 then begin
                        ShowVoucherBudgetPart := false;
                        isValidated := false;
                        Message('No voucher budget applied for scanned receipts.');
                    end else begin
                        ShowVoucherBudgetPart := true;
                        CurrPage.VoucherBudgetPart.PAGE.SetTempData(TempVoucherBudget);
                        isValidated := true;

                        //Hiện thông báo có > 2 voucher setup active
                        if TempVoucherBudget.Count > 1 then begin
                            isMutipleVoucher := true;
                            Message('There are %1 voucher campaigns active. Please verify before issuing.', TempVoucherBudget.Count);
                        end else
                            isMutipleVoucher := false;
                    end;

                    CurrPage.Update(false);
                end;
            }

            action(MTDSales)
            {
                ApplicationArea = All;
                Caption = 'Issue Taka Voucher';
                Image = DateRange;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = isValidated and not isMutipleVoucher;
                trigger OnAction()
                begin
                    if not Confirm('Issue voucher?', false) then
                        exit;
                    IssueTakaVoucher();
                end;
            }
        }
    }

    local procedure IssueTakaVoucher()
    var
        VoucherPage: Page "Scan Taka Voucher";
        VoucherQty: Integer;
        VoucherAmount: Decimal;
        VoucherID: Code[20];
        MemberCard: Record "LSC Membership Card";
        TempScannedVouchers: Record "LSC POS Data Entry" temporary;
        memberVoucher: Record "wpMemberVoucher";
        MaxVoucherQty: Integer;
    begin
        if TempVoucherBudget.IsEmpty() then begin
            Message('No voucher campaign found.');
        end;


        TempVoucherBudget.FindFirst();
        VoucherID := TempVoucherBudget.ID;

        if not MemberCard.Get(ScanMemberFilter) then begin
            Message('Membership card not found.');
        end;


        GetAllowedVoucherQty(
            VoucherID,
            MemberCard."Club Code",
            MemberCard."Scheme Code",
            VoucherQty,
            VoucherAmount,
            TotalSale
            );

        if VoucherQty = 0 then begin
            Message('No voucher eligible for issuance.');
        end;

        memberVoucher.Reset();
        memberVoucher.SetRange("Voucher ID", VoucherID);
        memberVoucher.SetRange("Member Club", MemberCard."Club Code");
        memberVoucher.SetRange("Member Scheme", MemberCard."Scheme Code");
        if memberVoucher.FindFirst() then begin
            MaxVoucherQty := memberVoucher."Max Voucher Qty";
        end;
        VoucherPage.SetVoucherLimitAndAmount(VoucherQty, VoucherAmount, MaxVoucherQty);

        VoucherPage.SetVoucherID(VoucherID);

        VoucherPage.RunModal();

        if VoucherPage.WasIssued() then begin
            MarkRedeemedItem(VoucherID);
            VoucherPage.GetScannedVouchers(TempScannedVouchers);
            SaveIssueVoucherLog(VoucherID, TempScannedVouchers);
            Message('Voucher issuance completed successfully!');
            ClearAllData(false);
        end;
    end;

    local procedure SaveIssueVoucherLog(VoucherID: Code[20]; var TempScannedVouchers: Record "LSC POS Data Entry" temporary)
    var
        VoucherLog: Record wpIssueVoucherLog;
        VoucherLogLine: Record wpIssueVoucherLogLine;
        TempRec: Record "LSC Trans. Sales Entry" temporary;
        ReceiptBuffer: Record "Name/Value Buffer" temporary;
        LineNo: Integer;
    begin
        // unique receipts
        TempRec.Copy(Rec, true);
        TempRec.Reset();
        if TempRec.FindSet() then
            repeat
                if TempRec."Receipt No." <> '' then begin
                    ReceiptBuffer.Reset();
                    ReceiptBuffer.SetRange(Name, TempRec."Receipt No.");
                    if not ReceiptBuffer.FindFirst() then begin
                        ReceiptBuffer.Init();
                        ReceiptBuffer.ID := ReceiptBuffer.Count + 1;
                        ReceiptBuffer.Name := TempRec."Receipt No.";
                        ReceiptBuffer.Insert();
                    end;
                end;
            until TempRec.Next() = 0;

        VoucherLog.Init();
        VoucherLog."Voucher ID" := VoucherID;
        VoucherLog."Member Card" := CopyStr(MembershipCard, 1, MaxStrLen(VoucherLog."Member Card"));
        VoucherLog."Applied Date" := Today;
        VoucherLog."Applied Time" := Time;
        VoucherLog."User ID" := CopyStr(UserId, 1, MaxStrLen(VoucherLog."User ID"));
        VoucherLog."Receipt Count" := ReceiptBuffer.Count;
        VoucherLog."Voucher Count" := TempScannedVouchers.Count;
        VoucherLog.Insert(true);

        LineNo := 10000;

        ReceiptBuffer.Reset();
        if ReceiptBuffer.FindSet() then
            repeat
                VoucherLogLine.Init();
                VoucherLogLine."Entry No." := VoucherLog."Entry No.";
                VoucherLogLine."Line No." := LineNo;
                VoucherLogLine.Type := VoucherLogLine.Type::Receipt;
                VoucherLogLine."Document No." := CopyStr(ReceiptBuffer.Name, 1, MaxStrLen(VoucherLogLine."Document No."));
                VoucherLogLine.Insert(true);
                LineNo := LineNo + 10000;
            until ReceiptBuffer.Next() = 0;

        TempScannedVouchers.Reset();
        if TempScannedVouchers.FindSet() then
            repeat
                VoucherLogLine.Init();
                VoucherLogLine."Entry No." := VoucherLog."Entry No.";
                VoucherLogLine."Line No." := LineNo;
                VoucherLogLine.Type := VoucherLogLine.Type::Voucher;
                VoucherLogLine."Document No." := CopyStr(TempScannedVouchers."Entry Code", 1, MaxStrLen(VoucherLogLine."Document No."));
                VoucherLogLine.Insert(true);
                LineNo := LineNo + 10000;
            until TempScannedVouchers.Next() = 0;
    end;

    local procedure MarkRedeemedItem(VoucherID: Code[20])
    var
        salesEntry: Record "LSC Trans. Sales Entry";
        TempRec: Record "LSC Trans. Sales Entry" temporary;
    begin
        TempRec.Copy(Rec, true);
        TempRec.Reset();

        if not TempRec.FindSet() then
            exit;

        repeat
            if TempRec."Voucher Status Temp" = TempRec."Voucher Status Temp"::Valid then begin

                salesEntry.Reset();
                salesEntry.SetRange("Store No.", TempRec."Store No.");
                salesEntry.SetRange("POS Terminal No.", TempRec."POS Terminal No.");
                salesEntry.SetRange("Transaction No.", TempRec."Transaction No.");
                salesEntry.SetRange("Line No.", TempRec."Line No.");

                if salesEntry.FindFirst() then begin
                    salesEntry.LockTable();
                    salesEntry."Voucher Status" := 'Redeemed';
                    salesEntry."Voucher ID" := VoucherID;
                    salesEntry."Voucher Status Temp" := salesEntry."Voucher Status Temp"::Valid;
                    salesEntry.Modify(true);
                end;
            end;
        until TempRec.Next() = 0;
    end;




    procedure GetAllowedVoucherQty(VoucherID: Code[20]; MemberClub: Code[20]; MemberScheme: Code[20]; var VoucherQty: Integer;
        var VoucherAmount: Decimal; TotalSale: Decimal
    )
    var
        wpMemberVoucher: Record wpMemberVoucher;
    begin
        // Thử tìm member scheme trước.
        wpMemberVoucher.Reset();
        wpMemberVoucher.SetRange("Voucher ID", VoucherID);
        wpMemberVoucher.SetRange("Member Club", MemberClub);
        wpMemberVoucher.SetRange("Member Scheme", MemberScheme);

        // Không thấy thì gán "" = tất cả scheme
        if not wpMemberVoucher.FindFirst() then begin
            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", VoucherID);
            wpMemberVoucher.SetRange("Member Club", MemberClub);
            wpMemberVoucher.SetRange("Member Scheme", '');

            if not wpMemberVoucher.FindFirst() then begin
                VoucherQty := 0;
                VoucherAmount := 0;
                exit;
            end;
        end;

        if wpMemberVoucher."Total value" = 0 then begin
            VoucherQty := 0;
            VoucherAmount := 0;
            exit;
        end;

        VoucherQty := Round(Abs(TotalSale) / wpMemberVoucher."Total value", 1, '<');

        if wpMemberVoucher."Max Voucher Qty" > 0 then
            if VoucherQty > wpMemberVoucher."Max Voucher Qty" then
                VoucherQty := wpMemberVoucher."Max Voucher Qty";

        VoucherQty := Round(VoucherQty, 1, '<');
        VoucherAmount := wpMemberVoucher."Voucher Amount";
    end;

    local procedure ClearAllData(isConfrim: Boolean)
    begin
        if isConfrim = true then begin
            if not Confirm('Clear all scanned receipts?', false) then
                exit;
        end;

        Rec.Reset();
        Rec.DeleteAll();
        Clear(TotalSale);
        Clear(TotalQuantity);
        Clear(TotalItemValid);
        Clear(ScanReceiptFilter);
        Clear(ReceiptCountedFilter);
        Clear(MemberAccount);
        Clear(MembershipCard);
        Clear(MemberDescription);
        Clear(MemberContact);
        Clear(MemberClub);
        Clear(MemberScheme);
        Clear(ScanMemberFilter);
        Clear(TempVoucherBudget);
        Clear(MaxReceiptAllowed);
        Clear(isValidated);
        ShowVoucherBudgetPart := false;
        CurrPage.Update(false);

        if isConfrim = true then begin
            Message('All scanned receipt data has been cleared successfully.');
        end;

    end;

    local procedure CalcTotalSale()
    var
        TempRec: Record "LSC Trans. Sales Entry" temporary;
    begin
        TotalSale := 0;
        TotalQuantity := 0;
        TotalItemValid := 0;

        TempRec.Copy(Rec, true);
        if TempRec.FindSet() then
            repeat
                TotalQuantity += TempRec."Quantity";

                if TempRec."Voucher Status Temp" = TempRec."Voucher Status Temp"::Valid then begin
                    TotalSale += TempRec."Total Rounded Amt.";
                    TotalItemValid += TempRec."Quantity";
                end;
            until TempRec.Next() = 0;
    end;

    local procedure GetMemberInfo(memberCardNo: Code[20])
    var
        shipCard: Record "LSC Membership Card";
        memberContacttb: Record "LSC Member Contact";
    begin
        Clear(shipCard);
        shipCard.SetRange("Card No.", memberCardNo);

        if not shipCard.FindFirst() then
            Error(ShipCardNotFoundErr, shipCard);

        clear(memberContacttb);
        memberContacttb.SetRange("Contact No.", shipCard."Contact No.");

        if not memberContacttb.FindFirst() then
            Error(MembercontactNotFoundErr, memberContacttb);

        MemberDescription := memberContacttb."Name";
        MemberAccount := shipCard."Account No.";
        MembershipCard := memberCardNo;
        MemberContact := shipCard."Contact No.";
        MemberClub := shipCard."Club Code";
        MemberScheme := shipCard."Scheme Code";

        LoadMemberVoucherLimits();
    end;

    local procedure AddReceiptToTemp(ReceiptNo: Code[20])
    var
        TempRec: Record "LSC Trans. Sales Entry" temporary;
        logVoucherEntry: Record wpIssueVoucherLog;
        VoucherLevel: Enum "Item Voucher Level";
        wpVoucherStp: Record wpVoucherSetup;
        VoucherBudgetID: Code[20];
        quantityOfDay: Integer;
    begin
        if MaxReceiptAllowed > 0 then
            if ReceiptCountedFilter >= MaxReceiptAllowed then begin
                Message('This member (scheme: %1) is only allowed to scan %2 receipt(s). Already scanned: %3.',
                    MemberScheme, MaxReceiptAllowed, ReceiptCountedFilter);
                exit;
            end;

        TransHeader.Reset();
        TransHeader.SetRange("Receipt No.", ReceiptNo);
        if not TransHeader.FindFirst() then begin
            Message(ReceiptNotFoundErr, ReceiptNo);
            exit;
        end;

        //Kiểm tra member hợp lệ
        // if TransHeader."Member Card No." = '' then begin
        //     Message('Receipt:= %1 not found Member Card.', ReceiptNo, TransHeader."Member Card No.");
        //     exit;
        // end;

        //Kiểm tra member hợp lệ
        // if TransHeader."Member Card No." <> ScanMemberFilter then begin
        //     Message('Receipt:= %1 of Card No %2. Not valid', ReceiptNo, TransHeader."Member Card No.");
        //     exit;
        // end;

        // //Kiểm tra hóa đơn trong ngày
        // if TransHeader.Date <> Today then begin
        //     Message('Taka Voucher can only be redeemed on the same day. Receipt %1 is invalid.', ReceiptNo);
        //     exit;
        // end;

        // //Kiểm tra 1 khách hàng chỉ sử dụng 3 lần
        // Clear(logVoucherEntry);
        // logVoucherEntry.SetRange("Member Card", MembershipCard);
        // logVoucherEntry.SetRange("Applied Date", Today);
        // quantityOfDay := logVoucherEntry.Count();
        // wpVoucherStp.Get();
        // if quantityOfDay > wpVoucherStp."Quantity Exchange of Day" then begin
        //     Message('Customers who exceed %1 time can exchange in 1 day', wpVoucherStp."Quantity Exchange of Day");
        //     exit;
        // end;

        //Check receipt(in TEMP)
        TempRec.Copy(Rec, true);
        TempRec.SetRange("Receipt No.", ReceiptNo);
        if TempRec.FindFirst() then begin
            Message(ReceiptExistsErr);
            exit;
        end;

        SourceSalesEntry.Reset();
        SourceSalesEntry.SetRange("Receipt No.", ReceiptNo);
        // if not SourceSalesEntry.FindSet() then
        //     Error('No sales lines found for receipt %1.', ReceiptNo);

        // if (SourceSalesEntry."Refunded Store No." <> '') then begin //Loại trừ bill đã cancel
        //     Message('The bill %1 has been canceled. Please use another bill.', ReceiptNo);
        //     exit;
        // end;

        // if (SourceSalesEntry."Voucher Status" <> '') then begin //Loại trừ bill đã sử dụng
        //     Message('The bill %1 has already been used. Please use another bill.', ReceiptNo);
        //     exit;
        // end;

        repeat
            Rec.Init();
            Rec.TransferFields(SourceSalesEntry);

            if CheckItemVoucher(Today, Rec."Item No.", VoucherLevel, VoucherBudgetID) then begin
                Rec."Voucher Status Temp" := Rec."Voucher Status Temp"::Valid;
                AddVoucherBudgetToTemp(Rec."Item No.");
                CurrPage.VoucherBudgetPart.PAGE.SetTempData(TempVoucherBudget);
            end else
                Rec."Voucher Status Temp" := Rec."Voucher Status Temp"::Invalid;

            Rec.Insert(false);
        until SourceSalesEntry.Next() = 0;

        Rec.Reset();

        ReceiptCountedFilter += 1;

        isValidated := false;

        CalcTotalSale();

        //Tính lại amount của các item valid setup lần nữa để hàm AddVoucherBudgetToTemp lấy đúng
        TempRec.Copy(Rec, true);
        TempRec.Reset();
        if TempRec.FindSet() then
            repeat
                if TempRec."Voucher Status Temp" = TempRec."Voucher Status Temp"::Valid then
                    AddVoucherBudgetToTemp(TempRec."Item No.");
            until TempRec.Next() = 0;

        CurrPage.VoucherBudgetPart.PAGE.SetTempData(TempVoucherBudget);

        RefilterVoucherBudget();
        ShowVoucherBudgetPart := false;
        CurrPage.Update(false);
    end;

    var
        ScanReceiptFilter: Text[100];
        ScanMemberFilter: Text[100];
        SourceSalesEntry: Record "LSC Trans. Sales Entry";
        ReceiptExistsErr: Label 'Receipt already scanned.';
        ReceiptNotFoundErr: Label 'Receipt not found.';
        ShipCardNotFoundErr: Label 'Membership Card not found.';
        MembercontactNotFoundErr: Label 'Member contact of card not found.';
        TransHeader: Record "LSC Transaction Header";
        ReceiptCountedFilter: Integer;
        TotalSale: Decimal;
        TotalQuantity: Decimal;
        TotalItemValid: Decimal;
        VoucherStyle: Text;
        wpVoucherItem: Record wpVoucherItemDiscStp;
        VoucherVendor: Record wpVoucherVendor;
        MemberAccount: Text;
        MembershipCard: Text;
        MemberContact: Text;
        MemberClub: Text;
        MemberScheme: Text;
        MemberDescription: Text;
        ShowVoucherBudgetPart: Boolean;
        MaxReceiptAllowed: Integer;
        TempVoucherBudget: Record wpVoucherMaintenance temporary;
        isMutipleVoucher: Boolean;
        isValidated: Boolean;

    trigger OnAfterGetRecord()
    begin
        if Rec."Voucher Status Temp" = Rec."Voucher Status Temp"::Valid then
            VoucherStyle := 'Favorable'
        else
            VoucherStyle := 'Unfavorable';
    end;

    trigger OnOpenPage()
    begin
        ShowVoucherBudgetPart := false;
    end;

    procedure CheckItemVoucher(
    pDate: Date;
    pItemNo: Code[20];
    var AppliedLevel: Enum "Item Voucher Level";
    var VoucherBudgetID: Code[20]
): Boolean
    var
        Item: Record Item;
        wpVoucherMaintenance: Record wpVoucherMaintenance;
        wpMemberVoucher: Record wpMemberVoucher;
        ItemSpecialGroupLink: Record "LSC Item/Special Group Link";
        Exclude: Boolean;
        SkipVoucher: Boolean;
        ReceiptQtyLimit: Integer;
    begin
        if not Item.Get(pItemNo) then
            exit(false);

        wpVoucherMaintenance.Reset();
        wpVoucherMaintenance.SetRange(Enabled, true);
        wpVoucherMaintenance.SetRange("Starting Date", 0D, pDate);
        wpVoucherMaintenance.SetFilter("Ending Date", '>=%1|%2', pDate, 0D);

        if not wpVoucherMaintenance.FindSet() then
            exit(false);

        repeat
            SkipVoucher := false;
            ReceiptQtyLimit := 0;

            // Check qty receipt của scheme member này xem thỏa những voucher nào
            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", wpVoucherMaintenance.ID);
            wpMemberVoucher.SetRange("Member Club", MemberClub);

            if wpMemberVoucher.FindSet() then begin
                SkipVoucher := true;
                repeat
                    if (wpMemberVoucher."Member Scheme" = '') or
                       (wpMemberVoucher."Member Scheme" = MemberScheme) then begin
                        // tìm thấy voucher line thỏa
                        if wpMemberVoucher."Member Scheme" = MemberScheme then
                            ReceiptQtyLimit := wpMemberVoucher."Receipt Qty"
                        else
                            if ReceiptQtyLimit = 0 then
                                ReceiptQtyLimit := wpMemberVoucher."Receipt Qty";
                        SkipVoucher := false;
                    end;
                until wpMemberVoucher.Next() = 0;
            end else
                SkipVoucher := true; // không tìm thấy member setup của voucher nào phù hợp

            // bỏ qua voucher nếu qty rêcieptt scanned > qty receipt setup của scheme này
            if (not SkipVoucher) and (ReceiptQtyLimit > 0) then
                if ReceiptCountedFilter >= ReceiptQtyLimit then
                    SkipVoucher := true;

            if not SkipVoucher then begin
                Exclude := false;
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", wpVoucherMaintenance.ID);

                // Item
                if MatchRule(wpVoucherItem.Type::Item, pItemNo, Exclude) then begin
                    AppliedLevel := AppliedLevel::Item;
                    VoucherBudgetID := wpVoucherMaintenance.ID;
                    exit(not Exclude);
                end;

                // Special Group
                ItemSpecialGroupLink.SetRange("Item No.", pItemNo);
                if ItemSpecialGroupLink.FindSet() then
                    repeat
                        if MatchRule(wpVoucherItem.Type::"Special Group", ItemSpecialGroupLink."Special Group Code", Exclude) then begin
                            AppliedLevel := AppliedLevel::"Special Group";
                            VoucherBudgetID := wpVoucherMaintenance.ID;
                            exit(not Exclude);
                        end;
                    until ItemSpecialGroupLink.Next() = 0;

                // Product Group
                if MatchRule(wpVoucherItem.Type::"Retail Product Group", Item."LSC Retail Product Code", Exclude) then begin
                    AppliedLevel := AppliedLevel::"Retail Product Group";
                    VoucherBudgetID := wpVoucherMaintenance.ID;
                    exit(not Exclude);
                end;

                //Category
                if MatchRule(wpVoucherItem.Type::"Item Category", Item."Item Category Code", Exclude) then begin
                    AppliedLevel := AppliedLevel::"Item Category";
                    VoucherBudgetID := wpVoucherMaintenance.ID;
                    exit(not Exclude);
                end;

                //Division

                if MatchRule(wpVoucherItem.Type::Division, Item."LSC Division Code", Exclude) then begin
                    AppliedLevel := AppliedLevel::Division;
                    VoucherBudgetID := wpVoucherMaintenance.ID;
                    exit(not Exclude);
                end;

                // Vendor (optional filter)
                // if VendorFilterIsConfigured(wpVoucherMaintenance.ID) then begin
                //     if MatchVendor(wpVoucherMaintenance.ID, Item."Vendor No.", Exclude) then begin
                //         AppliedLevel := AppliedLevel::Vendor;
                //         VoucherBudgetID := wpVoucherMaintenance.ID;
                //         exit(not Exclude);
                //     end;

                //     // đã cấu hình vendor nhưng item vendor không match => voucher này fail, chuyển qua voucher khác
                //     // (không exit(false) ngay vì còn voucher khác trong vòng repeat)
                // end;



                if MatchRule(wpVoucherItem.Type::All, '', Exclude) then begin
                    AppliedLevel := AppliedLevel::All;
                    VoucherBudgetID := wpVoucherMaintenance.ID;
                    exit(not Exclude);
                end;
            end;

        until wpVoucherMaintenance.Next() = 0;

        exit(false);
    end;

    local procedure MatchRule(RuleType: Enum wpItemDiscType; RuleNo: Code[20]; var Exclude: Boolean): Boolean
    begin
        wpVoucherItem.SetRange(Type, RuleType);
        wpVoucherItem.SetRange("No.", RuleNo);

        if wpVoucherItem.FindLast() then begin
            Exclude := wpVoucherItem.Exclude;
            exit(true);
        end;

        exit(false);
    end;

    local procedure MatchVendor(VoucherID: Code[20]; VendorNo: Code[20]; var Exclude: Boolean): Boolean
    begin
        Exclude := false;

        if VendorNo = '' then
            exit(false);

        VoucherVendor.Reset();
        VoucherVendor.SetRange("Voucher ID", VoucherID);
        VoucherVendor.SetRange("Vendor No.", VendorNo);

        if VoucherVendor.FindFirst() then begin
            Exclude := VoucherVendor.Exclude;
            exit(true);
        end;

        exit(false);
    end;

    local procedure VendorFilterIsConfigured(VoucherID: Code[20]): Boolean
    begin
        VoucherVendor.Reset();
        VoucherVendor.SetRange("Voucher ID", VoucherID);
        exit(not VoucherVendor.IsEmpty());
    end;


    local procedure LoadMemberVoucherLimits()
    var
        wpVoucherMaint: Record wpVoucherMaintenance;
        wpMemberVoucher: Record wpMemberVoucher;
    begin
        MaxReceiptAllowed := 0;

        wpVoucherMaint.Reset();
        wpVoucherMaint.SetRange(Enabled, true);
        wpVoucherMaint.SetRange("Starting Date", 0D, Today);
        wpVoucherMaint.SetFilter("Ending Date", '>=%1|%2', Today, 0D);

        if not wpVoucherMaint.FindSet() then
            exit;

        repeat
            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", wpVoucherMaint.ID);
            wpMemberVoucher.SetRange("Member Club", MemberClub);

            if wpMemberVoucher.FindSet() then
                repeat
                    // Neu co scheme thi apply cho scheme do, neu khong co thi apply all
                    if (wpMemberVoucher."Member Scheme" = '') or
                       (wpMemberVoucher."Member Scheme" = MemberScheme) then
                        if wpMemberVoucher."Receipt Qty" > MaxReceiptAllowed then
                            MaxReceiptAllowed := wpMemberVoucher."Receipt Qty";
                until wpMemberVoucher.Next() = 0;

        until wpVoucherMaint.Next() = 0;
    end;

    local procedure RefilterVoucherBudget()
    var
        wpMemberVoucher: Record wpMemberVoucher;
        TempBudgetToRemove: Record wpVoucherMaintenance temporary;
        ReceiptQtyLimit: Integer;
        Found: Boolean;
    begin
        TempVoucherBudget.Reset();
        if not TempVoucherBudget.FindSet() then
            exit;

        repeat
            ReceiptQtyLimit := 0;
            Found := false;

            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", TempVoucherBudget.ID);
            wpMemberVoucher.SetRange("Member Club", MemberClub);

            if wpMemberVoucher.FindSet() then
                repeat
                    // Tim scheme truoc, neu khong co thi lay rong
                    if wpMemberVoucher."Member Scheme" = MemberScheme then begin
                        ReceiptQtyLimit := wpMemberVoucher."Receipt Qty";
                        Found := true;
                    end else
                        if (wpMemberVoucher."Member Scheme" = '') and (not Found) then begin
                            ReceiptQtyLimit := wpMemberVoucher."Receipt Qty";
                            Found := true;
                        end;
                until wpMemberVoucher.Next() = 0;

            if Found then begin
                if ReceiptCountedFilter > ReceiptQtyLimit then begin
                    TempBudgetToRemove.Init();
                    TempBudgetToRemove.TransferFields(TempVoucherBudget);
                    if not TempBudgetToRemove.Insert() then;
                end else begin
                    // NEW: Also remove if sale amount dropped below threshold
                    if TempVoucherBudget."Total value" > 0 then
                        if Abs(TotalSale) < TempVoucherBudget."Total value" then begin
                            TempBudgetToRemove.Init();
                            TempBudgetToRemove.TransferFields(TempVoucherBudget);
                            if not TempBudgetToRemove.Insert() then;
                        end;
                end;
            end;

        until TempVoucherBudget.Next() = 0;

        TempBudgetToRemove.Reset();
        if TempBudgetToRemove.FindSet() then
            repeat
                TempVoucherBudget.Reset();
                TempVoucherBudget.SetRange(ID, TempBudgetToRemove.ID);
                TempVoucherBudget.DeleteAll();
            until TempBudgetToRemove.Next() = 0;
    end;

    local procedure AddVoucherBudgetToTemp(pItemNo: Code[20])
    var
        Item: Record Item;
        wpVoucher: Record wpVoucherMaintenance;
        wpMemberVoucher: Record wpMemberVoucher;
        ItemSpecialGroupLink: Record "LSC Item/Special Group Link";
        MatchedMemberVoucher: Record wpMemberVoucher;
        MemberQualifies: Boolean;
        ReceiptQtyLimit: Integer;
        Exclude: Boolean;
        ItemQualifies: Boolean;
    begin
        if not Item.Get(pItemNo) then
            exit;

        wpVoucher.Reset();
        wpVoucher.SetRange(Enabled, true);
        wpVoucher.SetRange("Starting Date", 0D, Today);
        wpVoucher.SetFilter("Ending Date", '>=%1|%2', Today, 0D);
        if not wpVoucher.FindSet() then
            exit;

        repeat
            MemberQualifies := false;
            ReceiptQtyLimit := 0;
            ItemQualifies := false;
            Clear(MatchedMemberVoucher);

            // Check member & số lượng receip
            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", wpVoucher.ID);
            wpMemberVoucher.SetRange("Member Club", MemberClub);
            if wpMemberVoucher.FindSet() then
                repeat
                    // Đầu tiên check member, xem voucher setup có scheme không?
                    if (wpMemberVoucher."Member Scheme" = '') or (wpMemberVoucher."Member Scheme" = MemberScheme) then begin
                        MemberQualifies := true;
                        if wpMemberVoucher."Member Scheme" = MemberScheme then begin
                            ReceiptQtyLimit := wpMemberVoucher."Receipt Qty";
                            MatchedMemberVoucher := wpMemberVoucher;
                        end else
                            if MatchedMemberVoucher."Voucher ID" = '' then begin
                                ReceiptQtyLimit := wpMemberVoucher."Receipt Qty";
                                MatchedMemberVoucher := wpMemberVoucher;
                            end;
                    end;
                until wpMemberVoucher.Next() = 0;

            // Bước 2 check qty receipt đã count so với receipt qty của voucher setup 
            if MemberQualifies and (ReceiptQtyLimit > 0) then
                if ReceiptCountedFilter >= ReceiptQtyLimit then
                    MemberQualifies := false;
            // Bước 3 check Sale
            if MemberQualifies and (MatchedMemberVoucher."Total value" > 0) then
                if Abs(TotalSale) < MatchedMemberVoucher."Total value" then
                    MemberQualifies := false;

            // Bước 4 check item (lấy lại của anh Hòa)
            if MemberQualifies then begin
                Exclude := false;
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", wpVoucher.ID);

                if MatchRule(wpVoucherItem.Type::Item, pItemNo, Exclude) then
                    ItemQualifies := not Exclude;

                if not ItemQualifies then begin
                    ItemSpecialGroupLink.Reset();
                    ItemSpecialGroupLink.SetRange("Item No.", pItemNo);
                    if ItemSpecialGroupLink.FindSet() then
                        repeat
                            if MatchRule(wpVoucherItem.Type::"Special Group", ItemSpecialGroupLink."Special Group Code", Exclude) then
                                ItemQualifies := not Exclude;
                        until (ItemSpecialGroupLink.Next() = 0) or ItemQualifies;
                end;

                if not ItemQualifies then
                    if MatchRule(wpVoucherItem.Type::"Retail Product Group", Item."LSC Retail Product Code", Exclude) then
                        ItemQualifies := not Exclude;

                if not ItemQualifies then
                    if MatchRule(wpVoucherItem.Type::"Item Category", Item."Item Category Code", Exclude) then
                        ItemQualifies := not Exclude;

                if not ItemQualifies then
                    if MatchRule(wpVoucherItem.Type::Division, Item."LSC Division Code", Exclude) then
                        ItemQualifies := not Exclude;

                if not ItemQualifies then
                    if MatchRule(wpVoucherItem.Type::All, '', Exclude) then
                        ItemQualifies := not Exclude;
            end;

            // Thêm vào bảng tạm khi cả 4 bước trên thỏa
            if ItemQualifies then begin
                TempVoucherBudget.Reset();
                TempVoucherBudget.SetRange(ID, wpVoucher.ID);
                if TempVoucherBudget.IsEmpty() then begin
                    TempVoucherBudget.Init();
                    TempVoucherBudget.TransferFields(wpVoucher);
                    TempVoucherBudget."Total value" := MatchedMemberVoucher."Total value";
                    TempVoucherBudget."Max Voucher Qty" := MatchedMemberVoucher."Max Voucher Qty";
                    TempVoucherBudget.Insert();
                end;
            end;

        until wpVoucher.Next() = 0;
    end;

}
