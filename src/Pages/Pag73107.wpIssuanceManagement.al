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
                    ClearAllTempData();
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
                    if TempVoucherBudget.Count = 0 then begin
                        ShowVoucherBudgetPart := false;
                        Message('No voucher budget applied for scanned receipts.');
                    end else begin
                        ShowVoucherBudgetPart := true;

                        CurrPage.VoucherBudgetPart.PAGE.SetTempData(TempVoucherBudget);
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
        VoucherID: Code[20];
        MemberCard: Record "LSC Membership Card";
    begin
        if TempVoucherBudget.IsEmpty() then
            Error('No voucher campaign found.');

        TempVoucherBudget.FindFirst();
        VoucherID := TempVoucherBudget.ID;

        if not MemberCard.Get(ScanMemberFilter) then
            Error('Membership card not found.');

        VoucherQty :=
            GetAllowedVoucherQty(
                VoucherID,
                MemberCard."Club Code",
                MemberCard."Scheme Code",
                TotalSale);

        if VoucherQty = 0 then
            Error('No voucher eligible for issuance.');

        VoucherPage.SetVoucherLimit(VoucherQty);
        VoucherPage.RunModal();

        if VoucherPage.WasIssued() then begin
            Message('Voucher issuance completed successfully!');
            ClearAllData();
        end;
    end;

    procedure GetAllowedVoucherQty(VoucherID: Code[20]; MemberClub: Code[20]; MemberScheme: Code[20]; TotalSale: Decimal): Integer
    var
        MemberVoucher: Record MemberVoucher;
        VoucherQty: Decimal;
    begin

        MemberVoucher.Reset();
        MemberVoucher.SetRange("Voucher ID", VoucherID);
        MemberVoucher.SetRange("Member Club", MemberClub);
        MemberVoucher.SetRange("Member Scheme", MemberScheme);

        if not MemberVoucher.FindFirst() then
            exit(0);

        if MemberVoucher."Total value" = 0 then
            exit(0);

        VoucherQty :=
            Round(Abs(TotalSale) / MemberVoucher."Total value", 1, '<');

        if MemberVoucher."Max Voucher Qty" > 0 then
            if VoucherQty > MemberVoucher."Max Voucher Qty" then
                VoucherQty := MemberVoucher."Max Voucher Qty";

        exit(VoucherQty);
    end;

    local procedure ClearAllData()
    begin
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
        ShowVoucherBudgetPart := false;
        CurrPage.Update(false);
    end;

    local procedure ClearAllTempData()
    begin
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

        ShowVoucherBudgetPart := false;

        CurrPage.Update(false);

        Message('All scanned receipt data has been cleared successfully.');
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
    end;

    local procedure AddReceiptToTemp(ReceiptNo: Code[20])
    var
        TempRec: Record "LSC Trans. Sales Entry" temporary;
        VoucherLevel: Enum "Item Voucher Level";
        VoucherBudgetID: Code[20];
    begin


        TransHeader.Reset();
        TransHeader.SetRange("Receipt No.", ReceiptNo);
        // TransHeader.SetRange("Member Card No.", ScanMemberFilter); //Check Member
        if not TransHeader.FindFirst() then
            Error(ReceiptNotFoundErr, ReceiptNo);

        //Kiểm tra hóa đơn trong ngày
        if TransHeader.Date <> Today then
            Error('Hóa đơn %1 khác ngày áp dụng. (Chỉ cho phép hóa đơn đổi voucher trong ngày)', ReceiptNo);

        //Kiểm tra 1 khách hàng chỉ sử dụng 3 lần



        //Check receipt(in TEMP)
        TempRec.Copy(Rec, true);
        TempRec.SetRange("Receipt No.", ReceiptNo);
        if TempRec.FindFirst() then
            Error(ReceiptExistsErr, ReceiptNo);

        SourceSalesEntry.Reset();
        SourceSalesEntry.SetRange("Receipt No.", ReceiptNo);
        if not SourceSalesEntry.FindSet() then
            Error('No sales lines found for receipt %1.', ReceiptNo);

        repeat
            Rec.Init();
            Rec.TransferFields(SourceSalesEntry);

            if CheckItemVoucher(Today, Rec."Item No.", VoucherLevel, VoucherBudgetID) then begin

                Rec."Voucher Status Temp" := Rec."Voucher Status Temp"::Valid;

                AddVoucherBudgetToTemp(VoucherBudgetID);
                CurrPage.VoucherBudgetPart.PAGE.SetTempData(TempVoucherBudget);
            end else
                Rec."Voucher Status Temp" := Rec."Voucher Status Temp"::Invalid;

            Rec.Insert(false);
        until SourceSalesEntry.Next() = 0;

        Rec.Reset();

        ReceiptCountedFilter += 1;

        CalcTotalSale();

        CurrPage.Update(false);
    end;

    var
        ScanReceiptFilter: Text[100];
        ScanMemberFilter: Text[100];
        SourceSalesEntry: Record "LSC Trans. Sales Entry";
        ReceiptExistsErr: Label 'Receipt %1 already scanned.';
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
        ShowVoucherBudgetPart: Boolean;
        TempVoucherBudget: Record wpVoucherMaintenance temporary;

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
        wpVoucherBudget: Record wpVoucherMaintenance;
        ItemSpecialGroupLink: Record "LSC Item/Special Group Link";
        Exclude: Boolean;
    begin
        if not Item.Get(pItemNo) then
            exit(false);

        wpVoucherBudget.Reset();
        wpVoucherBudget.SetRange(Enabled, true);
        wpVoucherBudget.SetRange("Starting Date", 0D, pDate);
        wpVoucherBudget.SetFilter("Ending Date", '>=%1|%2', pDate, 0D);

        if not wpVoucherBudget.FindSet() then
            exit(false);

        repeat
            Exclude := false;
            wpVoucherItem.Reset();
            wpVoucherItem.SetRange("Voucher ID", wpVoucherBudget.ID);

            // Item
            if MatchRule(wpVoucherItem.Type::Item, pItemNo, Exclude) then begin
                AppliedLevel := AppliedLevel::Item;
                VoucherBudgetID := wpVoucherBudget.ID;
                exit(not Exclude);
            end;

            // Special Group
            ItemSpecialGroupLink.SetRange("Item No.", pItemNo);
            if ItemSpecialGroupLink.FindSet() then
                repeat
                    if MatchRule(
                        wpVoucherItem.Type::"Special Group",
                        ItemSpecialGroupLink."Special Group Code",
                        Exclude)
                    then begin
                        AppliedLevel := AppliedLevel::"Special Group";
                        VoucherBudgetID := wpVoucherBudget.ID;
                        exit(not Exclude);
                    end;
                until ItemSpecialGroupLink.Next() = 0;

            // Product Group
            if MatchRule(
                wpVoucherItem.Type::"Retail Product Group",
                Item."LSC Retail Product Code",
                Exclude)
            then begin
                AppliedLevel := AppliedLevel::"Retail Product Group";
                VoucherBudgetID := wpVoucherBudget.ID;
                exit(not Exclude);
            end;

            // Category
            if MatchRule(
                wpVoucherItem.Type::"Item Category",
                Item."Item Category Code",
                Exclude)
            then begin
                AppliedLevel := AppliedLevel::"Item Category";
                VoucherBudgetID := wpVoucherBudget.ID;
                exit(not Exclude);
            end;

            // Division
            if MatchRule(
                wpVoucherItem.Type::Division,
                Item."LSC Division Code",
                Exclude)
            then begin
                AppliedLevel := AppliedLevel::Division;
                VoucherBudgetID := wpVoucherBudget.ID;
                exit(not Exclude);
            end;

            // Vendor (optional filter)
            // if VendorFilterIsConfigured(wpVoucherBudget.ID) then begin
            //     if MatchVendor(wpVoucherBudget.ID, Item."Vendor No.", Exclude) then begin
            //         AppliedLevel := AppliedLevel::Vendor;
            //         VoucherBudgetID := wpVoucherBudget.ID;
            //         exit(not Exclude);
            //     end;

            //     // đã cấu hình vendor nhưng item vendor không match => voucher này fail, chuyển qua voucher khác
            //     // (không exit(false) ngay vì còn voucher khác trong vòng repeat)
            // end;

            // All
            if MatchRule(
                wpVoucherItem.Type::All,
                '',
                Exclude)
            then begin
                AppliedLevel := AppliedLevel::All;
                VoucherBudgetID := wpVoucherBudget.ID;
                exit(not Exclude);
            end;

        until wpVoucherBudget.Next() = 0;

        exit(false);
    end;


    // local procedure AddVoucherBudgetToTemp(VoucherBudgetID: Code[20])
    // var
    //     Budget: Record wpVoucherMaintenance;
    // begin
    //     // đã tồn tại trong temp → bỏ qua
    //     TempVoucherBudget.Reset();
    //     TempVoucherBudget.SetRange(ID, VoucherBudgetID);
    //     if TempVoucherBudget.FindFirst() then
    //         exit;

    //     // lấy từ bảng thật
    //     if not Budget.Get(VoucherBudgetID) then
    //         exit;

    //     TempVoucherBudget.Init();
    //     TempVoucherBudget.TransferFields(Budget);
    //     TempVoucherBudget.Insert();
    // end;

    local procedure AddVoucherBudgetToTemp(VoucherBudgetID: Code[20])
    var
        Budget: Record wpVoucherMaintenance;
    begin
        Budget.Reset();
        Budget.SetRange(ID, VoucherBudgetID);

        // match member scheme
        Budget.SetRange("Member Type", Budget."Member Type"::Scheme);
        Budget.SetRange("Member Value", MemberScheme);

        if not Budget.FindFirst() then begin
            Budget.Reset();
            Budget.SetRange(ID, VoucherBudgetID);
            Budget.SetRange("Member Type", Budget."Member Type"::Club);
            Budget.SetRange("Member Value", MemberClub);

            if not Budget.FindFirst() then
                exit;
        end;

        // prevent duplicate
        TempVoucherBudget.Reset();
        TempVoucherBudget.SetRange(ID, Budget.ID);
        if TempVoucherBudget.FindFirst() then
            exit;

        TempVoucherBudget.Init();
        TempVoucherBudget.TransferFields(Budget);
        TempVoucherBudget.Insert();
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
}



