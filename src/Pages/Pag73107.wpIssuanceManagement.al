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
            group("Voucher Campaign")
            {
                field(SelectedVoucher; SelectedVoucherID)
                {
                    Caption = 'Voucher Campaign';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    TableRelation = wpVoucherMaintenance.ID WHERE(Enabled = CONST(true));

                    trigger OnValidate()
                    var
                        SavedID: Code[20];
                        voucherId: Record wpVoucherMaintenance;
                    begin

                        allowScanReceipt := SelectedVoucherID <> '';

                        SavedID := SelectedVoucherID;
                        if SavedID = '' then
                            exit;

                        if not voucherId.Get(SavedID) then begin
                            SelectedVoucherID := '';
                            Error('Voucher Campaign %1 not found.', SavedID);
                        end;

                        if not voucherId.Enabled then begin
                            SelectedVoucherID := '';
                            Error('Voucher Campaign %1 is not enabled.', SavedID);
                        end;

                        if (ScanMemberFilter <> '') or (ReceiptCountedFilter > 0) then
                            if not Confirm('Changing voucher campaign will clear all scanned data. Continue?', false) then begin
                                SelectedVoucherID := SavedID;
                                exit;
                            end;

                        voucherId.CalcFields("Starting Date", "Ending Date");
                        if voucherId."Starting Date" > Today() then begin
                            SelectedVoucherID := '';
                            Error('Voucher Campaign %1 has not started yet.', SavedID);
                        end;
                        if (voucherId."Ending Date" <> 0D) and (voucherId."Ending Date" < Today()) then begin
                            SelectedVoucherID := '';
                            Error('Voucher Campaign %1 has already expired.', SavedID);
                        end;

                        VoucherDescription := voucherId.Description;
                        ValidationDescription := voucherId."Validation Description";
                        StartingDate := voucherId."Starting Date";
                        EndingDate := voucherId."Ending Date";

                        ClearAllData(false);
                        SelectedVoucherID := SavedID;

                        CurrPage.Update(false);
                    end;
                }
                field(VoucherDescription; VoucherDescription)
                {
                    Caption = 'Description';
                    ApplicationArea = All;
                    Editable = false;
                }


                // field(StartingDate; StartingDate)
                // {
                //     Caption = 'Starting Date';
                //     ApplicationArea = All;
                //     Editable = false;
                // }

                // field(EndingDate; EndingDate)
                // {
                //     Caption = 'Ending Date';
                //     ApplicationArea = All;
                //     Editable = false;
                // }

            }


            group(Options)
            {
                Caption = 'Scan infomation';

                field(ScanMember; ScanMemberFilter)
                {
                    Caption = 'Scan Member';
                    ApplicationArea = All;
                    Editable = allowScanReceipt;
                    // ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if ScanMemberFilter = '' then
                            exit;
                        GetMemberInfo(ScanMemberFilter);
                    end;
                }

                field(ScanReceipt; ScanReceiptFilter)
                {
                    Caption = 'Scan Receipt';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    Editable = allowScanReceipt;

                    trigger OnValidate()
                    begin
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
                    //field(TotalSaleAmount; -TotalSale)
                    field(TotalSaleAmount; TotalSale)
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
                    field("Member Account"; MemberAccount)
                    {
                        ApplicationArea = All;
                    }
                    field("Member Contact"; MemberContact)
                    {
                        ApplicationArea = All;
                    }
                    field("Member Club"; MemberClub)
                    {
                        ApplicationArea = All;
                    }
                    field("Member Scheme"; MemberScheme)
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DeleteReceiptRow)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Image = Delete;
                Scope = Repeater;

                trigger OnAction()
                begin
                    DeleteReceiptFromGrid(Rec."Receipt No.");
                end;
            }

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

            action(MTDSales)
            {
                ApplicationArea = All;
                Caption = 'Issue Taka Voucher';
                Image = DateRange;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = isValidated;

                trigger OnAction()
                begin
                    if not Confirm('Issue voucher?', false) then
                        exit;
                    IssueTakaVoucher();
                end;
            }
        }
    }

    local procedure DeleteReceiptFromGrid(ReceiptNo: Code[20])
    var
        TempWork: Record "LSC Trans. Sales Entry" temporary;
    begin
        if ReceiptNo = '' then
            exit;

        if not Confirm('Delete all lines for receipt %1?', false, ReceiptNo) then
            exit;

        // Xóa tất cả dòng của receipt đang chọn khỏi temp grid
        Rec.Reset();
        Rec.SetRange("Receipt No.", ReceiptNo);
        if not Rec.IsEmpty() then
            Rec.DeleteAll();

        // RẤT QUAN TRỌNG: bỏ filter sau khi DeleteAll
        Rec.Reset();

        // cập nhật số receipt đã scan
        if ReceiptCountedFilter > 0 then
            ReceiptCountedFilter -= 1;

        // reset trạng thái validate
        isValidated := false;

        // tính lại tổng
        CalcTotalSale();
        CheckAndSetValidated();

        // rebuild lại voucher budget từ dữ liệu còn lại trên lưới
        TempWork.Copy(Rec, true);
        TempWork.Reset();
        CurrPage.Update(false);
    end;

    local procedure IssueTakaVoucher()
    var
        VoucherPage: Page "Scan Taka Voucher";
        VoucherQty: Integer;
        VoucherAmount: Decimal;
        VoucherID: Code[20];
        MemberCard: Record "LSC Membership Card";
        TempScannedVouchers: Record "LSC POS Data Entry" temporary;
        memberVoucher: Record wpMemberVoucher;
        voucherMaxQty: Integer;
    begin
        VoucherID := SelectedVoucherID;

        if VoucherID = '' then begin
            Message('Please select a voucher campaign first.');
            exit;
        end;

        if IsMemberType = true then begin
            if not MemberCard.Get(MembershipCard) then begin
                Message('Membership card not found.');
                exit;
            end;

            if not IsMemberAllowed(VoucherID, MemberCard."Club Code", MemberCard."Scheme Code") then begin
                Message('This member is not eligible for this voucher.');
                exit;
            end;
        end;

        GetAllowedVoucherQty(VoucherID, voucherMaxQty, VoucherQty, VoucherAmount, TotalSale);

        if VoucherQty = 0 then begin
            Message('No voucher eligible for issuance.');
            exit;
        end;

        //Set số voucher được phép phát hành vào page scan voucher
        VoucherPage.SetVoucherLimitAndAmount(VoucherQty, VoucherAmount, voucherMaxQty, MaxVoucherAllowed);
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
        BufferID: Integer;
    begin

        BufferID := 1;

        //Check coi này phải là unique receipt chưa
        TempRec.Copy(Rec, true);
        TempRec.Reset();
        if TempRec.FindSet() then
            repeat
                if TempRec."Receipt No." <> '' then begin
                    ReceiptBuffer.Reset();
                    ReceiptBuffer.SetRange(Name, TempRec."Receipt No.");
                    if not ReceiptBuffer.FindFirst() then begin
                        ReceiptBuffer.Init();
                        ReceiptBuffer.ID := BufferID;
                        ReceiptBuffer.Name := TempRec."Receipt No.";
                        ReceiptBuffer.Insert();

                        BufferID += 1;
                    end;
                end;
            until TempRec.Next() = 0;

        VoucherLog.Init();
        VoucherLog."Voucher ID" := VoucherID;
        VoucherLog."Member Card" := CopyStr(MembershipCard, 1, MaxStrLen(VoucherLog."Member Card"));
        VoucherLog."Redeemp Date" := Today;
        VoucherLog."Redeemp Time" := Time;
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
                LineNo += 10000;
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
                LineNo += 10000;
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
                    salesEntry."Is Redeemption" := true;
                    salesEntry."Voucher ID" := VoucherID;
                    salesEntry."Voucher Status Temp" := salesEntry."Voucher Status Temp"::Valid;
                    salesEntry.Modify(true);
                end;
            end;
        until TempRec.Next() = 0;
    end;

    procedure GetAllowedVoucherQty(VoucherID: Code[20]; var voucherMaxQty: Integer;
        var VoucherQty: Integer; var VoucherAmount: Decimal; TotalSale: Decimal)
    var
        wpMemberVoucher: Record wpMemberVoucher;
    begin
        if not GetVoucherMemberSetup(wpMemberVoucher) then begin
            VoucherQty := 0;
            VoucherAmount := 0;
            exit;
        end;

        if wpMemberVoucher."Total value" = 0 then begin
            VoucherQty := 0;
            VoucherAmount := 0;
            exit;
        end;

        VoucherQty := Round(Abs(TotalSale) / wpMemberVoucher."Total value", 1, '<');

        if wpMemberVoucher."Max Voucher Qty" > 0 then
            if VoucherQty > (wpMemberVoucher."Max Voucher Qty" - MaxVoucherAllowed) then // trừ cho max voucher trong 1 ngày
                VoucherQty := (wpMemberVoucher."Max Voucher Qty" - MaxVoucherAllowed);

        voucherMaxQty := wpMemberVoucher."Max Voucher Qty";
        VoucherQty := Round(VoucherQty, 1, '<');
        VoucherAmount := wpMemberVoucher."Voucher Amount";
    end;

    local procedure ClearAllData(isConfrim: Boolean)
    begin
        if isConfrim then
            if not Confirm('Clear all scanned receipts?', false) then
                exit;

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
        Clear(IsMemberType);
        Clear(MaxReceiptAllowed);
        Clear(isValidated);
        Clear(SelectedVoucherID);
        CurrPage.Update(false);

        if isConfrim then
            Message('All scanned receipt data has been cleared successfully.');
    end;

    local procedure CalcTotalSale()
    var
        TempRec: Record "LSC Trans. Sales Entry" temporary;
        PaymentEntry: Record "LSC Trans. Payment Entry";
        ReceiptBuffer: Record "Name/Value Buffer" temporary;
        wpVoucherMaintenance: Record wpVoucherMaintenance;
        ReceiptNo: Code[20];
        ReceiptSales: Decimal;
        ExcludedAmount: Decimal;
        store: Code[10];
        posNumber: Code[10];
        transNo: Integer;
        BufferID: Integer;
    begin
        TotalSale := 0;
        TotalQuantity := 0;
        TotalItemValid := 0;
        BufferID := 1;

        if not wpVoucherMaintenance.Get(SelectedVoucherID) then begin
            Message('Not found Voucher ID:=%1.', SelectedVoucherID);
            exit;
        end;

        TempRec.Copy(Rec, true);
        TempRec.Reset();
        if TempRec.FindSet() then
            repeat
                if TempRec."Receipt No." <> '' then begin
                    ReceiptBuffer.Reset();
                    ReceiptBuffer.SetRange(Name, TempRec."Receipt No.");
                    if not ReceiptBuffer.FindFirst() then begin
                        ReceiptBuffer.Init();
                        ReceiptBuffer.ID := BufferID;
                        ReceiptBuffer.Name := TempRec."Receipt No.";
                        ReceiptBuffer.Insert();
                        BufferID += 1;
                    end;
                end;
            until TempRec.Next() = 0;

        ReceiptBuffer.Reset();
        if ReceiptBuffer.FindSet() then
            repeat
                ReceiptNo := ReceiptBuffer.Name;
                ReceiptSales := 0;
                ExcludedAmount := 0;
                Clear(store);
                Clear(posNumber);
                Clear(transNo);

                TempRec.Reset();
                TempRec.SetRange("Receipt No.", ReceiptNo);
                if TempRec.FindSet() then begin


                    store := TempRec."Store No.";
                    posNumber := TempRec."POS Terminal No.";
                    transNo := TempRec."Transaction No.";

                    repeat
                        TotalQuantity += TempRec.Quantity;
                        if TempRec."Voucher Status Temp" = TempRec."Voucher Status Temp"::Valid then begin
                            ReceiptSales += Abs(TempRec."Total Rounded Amt.");
                            TotalItemValid += TempRec.Quantity;
                        end;
                    until TempRec.Next() = 0;

                    PaymentEntry.Reset();
                    PaymentEntry.SetRange("Store No.", store);
                    PaymentEntry.SetRange("POS Terminal No.", posNumber);
                    PaymentEntry.SetRange("Transaction No.", transNo);
                    PaymentEntry.SetRange("Tender Type", wpVoucherMaintenance."Tender Type Code");
                    if PaymentEntry.FindSet() then
                        repeat
                            ExcludedAmount += Abs(PaymentEntry."Amount Tendered");
                        until PaymentEntry.Next() = 0;
                end;

                ReceiptSales := ReceiptSales - ExcludedAmount;
                if ReceiptSales < 0 then
                    ReceiptSales := 0;
                TotalSale += ReceiptSales;

            until ReceiptBuffer.Next() = 0;
    end;


    local procedure GetMemberInfo(memberCardNo: Code[20])
    var
        shipCard: Record "LSC Membership Card";
        memberContacttb: Record "LSC Member Contact";
    begin
        shipCard.Reset();
        shipCard.SetRange("Card No.", memberCardNo);
        if not shipCard.FindFirst() then
            Error(ShipCardNotFoundErr, memberCardNo);

        memberContacttb.Reset();
        memberContacttb.SetRange("Contact No.", shipCard."Contact No.");
        if not memberContacttb.FindFirst() then
            Error(MembercontactNotFoundErr);

        MemberDescription := memberContacttb.Name;
        MemberAccount := shipCard."Account No.";
        MembershipCard := memberCardNo;
        MemberContact := shipCard."Contact No.";
        MemberClub := shipCard."Club Code";
        MemberScheme := shipCard."Scheme Code";
        IsMemberType := true;

        if not LoadVoucherLimits() then begin
            MemberDescription := '';
            MemberAccount := '';
            MembershipCard := '';
            MemberContact := '';
            MemberClub := '';
            MemberScheme := '';
            IsMemberType := false;
            exit;
        end;
    end;

    local procedure AddReceiptToTemp(ReceiptNo: Code[20])
    var
        TempRec: Record "LSC Trans. Sales Entry" temporary;
        logVoucherEntry: Record wpIssueVoucherLog;
        logVoucherEntryLine: Record wpIssueVoucherLogLine;
        VoucherLevel: Enum "Item Voucher Level";
        tbSalesReceivables: Record "Sales & Receivables Setup";
        VoucherBudgetID: Code[20];
        quantityOfDay: Integer;
        ReceiptLimit: Integer;
        wpVoucherMaintenance: Record wpVoucherMaintenance;
    begin
        if SelectedVoucherID = '' then begin
            Message('Please select a Voucher Campaign first.');
            exit;
        end;

        ReceiptLimit := 0;

        if not wpVoucherMaintenance.Get(SelectedVoucherID) then begin
            Message('Not found Voucher ID:=%1.', SelectedVoucherID);
            exit;
        end;

        if not wpVoucherMaintenance.Enabled then begin
            Message('Voucher %1 with status:= Disable. Please check again in Voucher Maintenance Page', SelectedVoucherID);
            exit;
        end;

        if wpVoucherMaintenance."Starting Date" > Today then begin
            Message('Voucher ID:=%1 Start Date and End Date have expired', SelectedVoucherID);
            exit;
        end;

        if (wpVoucherMaintenance."Ending Date" <> 0D) and
           (wpVoucherMaintenance."Ending Date" < Today) then begin
            Message('Voucher ID:=%1 Start Date and End Date have expired', SelectedVoucherID);
            exit;
        end;

        if not LoadVoucherLimits() then
            exit;

        if (MaxReceiptAllowed > 0) and (ReceiptCountedFilter >= MaxReceiptAllowed) then begin
            Message(
                'This member is only allowed to scan %1 receipt(s). Already scanned: %2.',
                MaxReceiptAllowed, ReceiptCountedFilter);
            exit;
        end;

        TransHeader.Reset();
        TransHeader.SetRange("Receipt No.", ReceiptNo);
        if not TransHeader.FindFirst() then begin
            Message(ReceiptNotFoundErr, ReceiptNo);
            exit;
        end;

        //Loại trừ bill trong ngày
        if TransHeader.Date <> Today then begin
            Message('Taka Voucher can only be redeemed on the same day. Receipt %1 is invalid.', ReceiptNo);
            exit;
        end;

        //Loại trừ bill return
        if TransHeader."Sale Is Return Sale" then begin
            Message('The bill %1 already returned. Please use another bill.', ReceiptNo);
            exit;
        end;

        //Loại trừ bill cancel
        if TransHeader."Sale Is Cancel Sale" then begin
            Message('The bill %1 already canceled. Please use another bill.', ReceiptNo);
            exit;
        end;

        //loại trừ bill đã redeemp
        logVoucherEntryLine.Reset();
        logVoucherEntryLine.SetRange("Document No.", ReceiptNo);
        if logVoucherEntryLine.FindSet() then begin
            Message('The bill %1 has already been used. Please use another bill.', ReceiptNo);
            exit;
        end;

        // Kiểm tra member hợp lệ
        if IsMemberType = true then begin
            if TransHeader."Member Card No." = '' then begin
                Message('Receipt %1 has no Member Card.', ReceiptNo);
                exit;
            end;

            //Giới hạn số lần redeemp trong ngày
            logVoucherEntry.Reset();
            logVoucherEntry.SetRange("Member Card", MembershipCard);
            logVoucherEntry.SetRange("Redeemp Date", Today);
            quantityOfDay := logVoucherEntry.Count();
            tbSalesReceivables.Get();
            if tbSalesReceivables."Quantity Exchange of Day" <> 0 then
                if quantityOfDay > tbSalesReceivables."Quantity Exchange of Day" then begin
                    Message('Customer exceeded %1 exchange(s) allowed per day.', tbSalesReceivables."Quantity Exchange of Day");
                    exit;
                end;

            if tbSalesReceivables."Redeemp Same Member" = true then begin
                if TransHeader."Member Card No." <> MembershipCard then begin
                    Message('Receipt %1 belongs to Card No %2. Not valid.', ReceiptNo, TransHeader."Member Card No.");
                    exit;
                end;
            end;

        end else begin
            if TransHeader."Member Card No." <> '' then begin
                Message('Non-Member only applies to receipts without a member card.', ReceiptNo);
                exit;
            end;
        end;

        TempRec.Copy(Rec, true);
        TempRec.SetRange("Receipt No.", ReceiptNo);
        if TempRec.FindFirst() then begin
            Message(ReceiptExistsErr);
            exit;
        end;

        SourceSalesEntry.Reset();
        SourceSalesEntry.SetRange("Receipt No.", ReceiptNo);
        if not SourceSalesEntry.FindSet() then begin
            Message('No sales lines found for receipt %1.', ReceiptNo);
            exit;
        end;

        //Loại trừ bill gốc đã cancel
        if (SourceSalesEntry."Refunded Store No." <> '') then begin
            Message('The bill %1 has been canceled. Please use another bill.', ReceiptNo);
            exit;
        end;

        repeat
            Rec.Init();
            Rec.TransferFields(SourceSalesEntry);

            if CheckItemVoucher(Today, Rec."Item No.", VoucherLevel, VoucherBudgetID) then
                Rec."Voucher Status Temp" := Rec."Voucher Status Temp"::Valid
            else
                Rec."Voucher Status Temp" := Rec."Voucher Status Temp"::Invalid;

            Rec.Insert(false);
        until SourceSalesEntry.Next() = 0;

        Rec.Reset();
        ReceiptCountedFilter += 1;
        CalcTotalSale();
        CheckAndSetValidated();
        CurrPage.Update(false);
    end;

    //Kiểm tra lại đủ điều kiện redeemp
    local procedure CheckAndSetValidated()
    var
        wpMemberVoucher: Record wpMemberVoucher;
        VoucherQty: Integer;
        VoucherAmount: Decimal;
        ReceiptQtyLimit: Integer;
        voucherMaxQty: Integer;
    begin
        isValidated := false;

        if SelectedVoucherID = '' then
            exit;
        if ReceiptCountedFilter = 0 then
            exit;

        //Kiểm tra có setup Non-Member hay Member Club
        if not GetVoucherMemberSetup(wpMemberVoucher) then
            exit;

        ReceiptQtyLimit := wpMemberVoucher."Receipt Qty";
        if (ReceiptQtyLimit > 0) and (ReceiptCountedFilter > ReceiptQtyLimit) then begin
            exit;
        end;

        if wpMemberVoucher."Total value" > 0 then
            if Abs(TotalSale) < wpMemberVoucher."Total value" then
                exit;

        GetAllowedVoucherQty(SelectedVoucherID, voucherMaxQty, VoucherQty, VoucherAmount, TotalSale);

        if VoucherQty = 0 then
            exit;

        isValidated := true;
    end;

    local procedure GetVoucherMemberSetup(var wpMemberVoucher: Record wpMemberVoucher): Boolean
    begin
        // Member
        if IsMemberType = true then begin
            // 1. Club + Scheme
            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", SelectedVoucherID);
            wpMemberVoucher.SetRange(Type, wpMemberVoucher.Type::Member);
            wpMemberVoucher.SetRange("Member Club", MemberClub);
            wpMemberVoucher.SetRange("Member Scheme", MemberScheme);
            if wpMemberVoucher.FindFirst() then begin
                if wpMemberVoucher.Exclude = true then begin
                    Message('Scheme Code:=%1 are not eligible to apply for Taka Voucher.', MemberScheme);
                    exit(false);
                end;

                if wpMemberVoucher.Exclude = false then
                    exit(true);
            end;

            // 2. Club + blank Scheme
            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", SelectedVoucherID);
            wpMemberVoucher.SetRange(Type, wpMemberVoucher.Type::Member);
            wpMemberVoucher.SetRange("Member Club", MemberClub);
            wpMemberVoucher.SetRange("Member Scheme", '');
            if wpMemberVoucher.FindFirst() then begin
                if wpMemberVoucher.Exclude = true then begin
                    Message('Club Code:=%1 are not eligible to apply for Taka Voucher.', MemberClub);
                    exit(false);
                end;

                if wpMemberVoucher.Exclude = false then
                    exit(true);
            end;

            Message('Taka Voucher has not been set up for Member type');
            exit(false);
        end else begin
            // Non-member
            wpMemberVoucher.Reset();
            wpMemberVoucher.SetRange("Voucher ID", SelectedVoucherID);
            wpMemberVoucher.SetRange(Type, wpMemberVoucher.Type::"Non Member");
            if wpMemberVoucher.FindFirst() then begin
                if wpMemberVoucher.Exclude = true then begin
                    Message('Non-Members are not eligible to apply for Taka Voucher.', MemberClub);
                    exit(false);
                end;

                if wpMemberVoucher.Exclude = false then
                    exit(true);
            end;

            Message('Taka Voucher for Non-Member type has not been set up yet');
            exit(false);
        end;
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
        ReceiptQtyLimit: Integer;
    begin
        if not Item.Get(pItemNo) then
            exit(false);

        wpVoucherItem.Reset();
        wpVoucherItem.SetRange("Voucher ID", SelectedVoucherID);

        //Item
        if MatchRule(wpVoucherItem.Type::Item, pItemNo, Exclude) then begin
            AppliedLevel := AppliedLevel::Item;
            VoucherBudgetID := SelectedVoucherID;
            exit(not Exclude);
        end;

        ItemSpecialGroupLink.Reset();
        ItemSpecialGroupLink.SetRange("Item No.", pItemNo);
        if ItemSpecialGroupLink.FindSet() then
            repeat
                //Special Group"
                if MatchRule(wpVoucherItem.Type::"Special Group",
                             ItemSpecialGroupLink."Special Group Code",
                             Exclude) then begin
                    AppliedLevel := AppliedLevel::"Special Group";
                    VoucherBudgetID := SelectedVoucherID;
                    exit(not Exclude);
                end;
            until ItemSpecialGroupLink.Next() = 0;

        //Product Group
        if MatchRule(wpVoucherItem.Type::"Retail Product Group",
                     Item."LSC Retail Product Code", Exclude) then begin
            AppliedLevel := AppliedLevel::"Retail Product Group";
            VoucherBudgetID := SelectedVoucherID;
            exit(not Exclude);
        end;

        //Category
        if MatchRule(wpVoucherItem.Type::"Item Category",
                     Item."Item Category Code", Exclude) then begin
            AppliedLevel := AppliedLevel::"Item Category";
            VoucherBudgetID := SelectedVoucherID;
            exit(not Exclude);
        end;

        //Division
        if MatchRule(wpVoucherItem.Type::Division,
                     Item."LSC Division Code", Exclude) then begin
            AppliedLevel := AppliedLevel::Division;
            VoucherBudgetID := SelectedVoucherID;
            exit(not Exclude);
        end;

        //ALL
        if MatchRule(wpVoucherItem.Type::All, '', Exclude) then begin
            AppliedLevel := AppliedLevel::All;
            VoucherBudgetID := SelectedVoucherID;
            exit(not Exclude);
        end;

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

    local procedure LoadVoucherLimits(): Boolean
    var
        wpVoucherMaint: Record wpVoucherMaintenance;
        wpMemberVoucher: Record wpMemberVoucher;
        logVoucherEntry: Record wpIssueVoucherLog;
        logVoucherEntryLine: Record wpIssueVoucherLogLine;
    begin
        MaxReceiptAllowed := 0;

        if SelectedVoucherID = '' then
            exit(false);

        if not GetVoucherMemberSetup(wpMemberVoucher) then begin
            exit(false);
        end;

        if wpMemberVoucher."Total value" = 0 then begin
            Message('Check field:=Total Value in Voucher Maintenance!');
            exit(false);
        end;

        if wpMemberVoucher."Voucher Amount" = 0 then begin
            Message('Check field:=Voucher Amount in Voucher Maintenance !');
            exit(false);
        end;

        //Giới hạn số voucher được redeemo trong ngày theo từng campaigns
        if IsMemberType = true then begin
            //Giới hạn số lần redeemp trong ngày
            logVoucherEntry.Reset();
            logVoucherEntry.SetRange("Member Card", MembershipCard);
            logVoucherEntry.SetRange("Redeemp Date", Today);
            logVoucherEntry.SetRange("Voucher ID", SelectedVoucherID);
            logVoucherEntry.CalcSums("Voucher Count");
            if logVoucherEntry."Voucher Count" >= wpMemberVoucher."Max Voucher Qty" then begin
                Message('The customer has exceeded %1/%2 the number of vouchers allowed for the day.', logVoucherEntry."Voucher Count", wpMemberVoucher."Max Voucher Qty");
                exit(false);
            end else
                MaxVoucherAllowed := logVoucherEntry."Voucher Count"
        end;

        if wpMemberVoucher."Receipt Qty" > MaxReceiptAllowed then
            MaxReceiptAllowed := wpMemberVoucher."Receipt Qty";

        exit(true);
    end;

    local procedure IsMemberAllowed(VoucherID: Code[20]; MemberClub: Code[20]; MemberScheme: Code[20]): Boolean
    var
        wpMemberVoucher: Record wpMemberVoucher;
        IsAllowed: Boolean;
    begin
        IsAllowed := false;

        wpMemberVoucher.Reset();
        wpMemberVoucher.SetRange("Voucher ID", VoucherID);

        if wpMemberVoucher.FindSet() then
            repeat
                if
                   ((wpMemberVoucher."Member Club" = '') or
                    (wpMemberVoucher."Member Club" = MemberClub))
                and
                   ((wpMemberVoucher."Member Scheme" = '') or
                    (wpMemberVoucher."Member Scheme" = MemberScheme))
                then begin

                    //  Ưu tiên check bị loại trước
                    if wpMemberVoucher.Exclude then
                        exit(false);

                    if not wpMemberVoucher.Exclude then
                        IsAllowed := true;
                end;

            until wpMemberVoucher.Next() = 0;

        exit(IsAllowed);
    end;


    var
        ScanReceiptFilter: Text[100];
        ScanMemberFilter: Text[100];
        IsMemberType: Boolean;
        SourceSalesEntry: Record "LSC Trans. Sales Entry";
        ReceiptExistsErr: Label 'Receipt already scanned.';
        ReceiptNotFoundErr: Label 'Receipt %1 not found.';
        ShipCardNotFoundErr: Label 'Membership Card %1 not found.';
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
        MaxReceiptAllowed: Integer;
        MaxVoucherAllowed: Integer;
        SelectedVoucherID: Code[20];
        isValidated: Boolean;
        ShowVoucherBudgetPart: Boolean;

        VoucherDescription: Text[100];
        ValidationDescription: Text[100];
        StartingDate: Date;
        EndingDate: Date;

        allowScanMember: Boolean;
        allowScanReceipt: Boolean;


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
}