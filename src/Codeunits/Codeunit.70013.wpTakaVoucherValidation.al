codeunit 70013 "wpTakaVoucherValidation"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Infocode Utility", 'OnBeforeTypeApplyToEntry', '', false, false)]
    local procedure OnBeforeTypeApplyToEntry(Input: Text; MgrKeyActive: Boolean; Training: Boolean; var TSError: Boolean; var Line: Record "LSC Pos Trans. Line"; var Trans: Record "LSC POS Transaction"; var InfoCodeRec: Record "LSC Infocode"; var ErrorTxt: Text; var IsHandled: Boolean; var ReturnValue: Boolean)
    var
        VoucherEntry: Record "LSC Voucher Entries";
        PosDataEntry: Record "LSC POS Data Entry";
        PosDataEntryType: Record "LSC POS Data Entry Type";
        TransLine: Record "LSC Pos Trans. Line";
        TransLineTender: Record "LSC Pos Trans. Line";
        VoucherID: Code[20];
        MemberCardNo: Code[20];
        TransHeader: Record "LSC Transaction Header";
        itemValidList: text[500];
        totalAmountItemValid: Decimal;
        totalAmountTender: Decimal;
        calAmountCurrent: Decimal;
        voucherNo: text[50];
    begin
        voucherNo := Input;

        // Lấy Pos data entry
        PosDataEntry.Reset();
        PosDataEntry.SetRange("Entry Code", voucherNo);
        if not PosDataEntry.FindFirst() then begin
            ErrorTxt := 'Not found POS Data Entry Table.';
            exit;
        end;

        //Kiểm tra nếu không phải Takavoucher thì exit
        Clear(PosDataEntryType);
        PosDataEntryType.SetRange(Code, PosDataEntry."Entry Type");
        PosDataEntryType.SetRange("Enable/ Activate Taka Voucher", true);
        if not PosDataEntryType.FindSet() then begin
            exit;
        end;

        Clear(VoucherEntry);
        VoucherEntry.Reset();
        VoucherEntry.SetRange("Entry Type", VoucherEntry."Entry Type"::Issued);
        VoucherEntry.SetRange("Voucher No.", voucherNo);
        if not VoucherEntry.FindFirst() then begin
            ErrorTxt := 'Not found Voucher Entry Table.';
            exit;
        end;

        // check voucher phải ở status redeemp
        if PosDataEntry.Status <> PosDataEntry.Status::Redeemed then begin
            case PosDataEntry.Status of
                PosDataEntry.Status::Active:
                    ErrorTxt := StrSubstNo('Voucher %1 has not been redeemed yet ', voucherNo);
                PosDataEntry.Status::" ":
                    ErrorTxt := StrSubstNo('Voucher %1 is not activated.', voucherNo);
                else
                    //ErrorTxt := StrSubstNo('Voucher %1 cannot be used (Status: %2).', voucherNo, PosDataEntry.Status);
                    begin
                    voucherNo := PosDataEntry."Entry Code";
                    Clear(TransHeader);
                    TransHeader.SetRange("Receipt No.", PosDataEntry."Applied by Receipt No.");
                    if TransHeader.FindFirst() then
                        Message('Voucher: %1 already used\Receipt: %2\POS: %3\Transaction Date: %4\Transaction Time: %5',
                            voucherNo,
                            PosDataEntry."Applied by Receipt No.",
                            TransHeader."POS Terminal No.",
                            Transheader.Date,
                            TransHeader.Time)
                    else
                        Message('Voucher: %1 already used\Receipt: %2\POS: (not found)\Transaction Time: (not found)',
                            voucherNo,
                            PosDataEntry."Applied by Receipt No.");
                    IsHandled := true;
                    ReturnValue := false;
                    exit;
                end;
            end;
            IsHandled := true;
            ReturnValue := false;
            exit;
        end;

        // Kiểm tra voucher có thuộc chương trình VoucherID setup không
        VoucherID := PosDataEntry."Created by Receipt No.";
        if VoucherID = '' then begin
            ErrorTxt := 'Not found Voucher ID.';
            exit;
        end;

        // // Check member này có dùng được voucher này không
        // MemberCardNo := Trans."Member Card No.";
        // if MemberCardNo = '' then begin
        //     ErrorTxt := 'Please input Member Card before using voucher.';
        //     IsHandled := true;
        //     ReturnValue := false;
        //     exit;
        // end;

        // if MemberCardNo <> '' then begin
        //     if not VoucherBelongsToMember(DataEntry."Entry Code", MemberCardNo) then begin
        //         ErrorTxt := StrSubstNo('Voucher %1 does not belong to this member.', DataEntry."Entry Code");
        //         IsHandled := true;
        //         ReturnValue := false;
        //         exit;
        //     end;
        // end;

        //Lấy tổng giá trị item hiện có
        totalAmountItemValid := 0;
        Clear(TransLine);
        TransLine.Reset();
        TransLine.SetRange("Receipt No.", Line."Receipt No.");
        TransLine.SetRange("Entry Status", TransLine."Entry Status"::" ");
        TransLine.SetRange("Entry Type", TransLine."Entry Type"::Item);
        if TransLine.FindSet() then
            repeat
                if ValidateTrans(TransLine.Number, VoucherID) then begin
                    itemValidList := itemValidList + TransLine.Number + ';';
                    totalAmountItemValid := totalAmountItemValid + TransLine.Amount;

                    // TransLine."Is Used VC" := true;
                    // TransLine."Voucher ID of Used" := VoucherID;
                    // TransLine.Modify();
                end;
            until TransLine.Next() = 0;

        if totalAmountItemValid = 0 then begin
            ErrorTxt := 'Tất cả Item không đủ điều kiện đổi voucher';
            IsHandled := true;
            ReturnValue := false;
        end;

        //Lấy tổng giá trị voucher đã applied
        totalAmountTender := 0;
        Clear(TransLineTender);
        TransLineTender.Reset();
        TransLineTender.SetRange("Receipt No.", Line."Receipt No.");
        TransLineTender.SetFilter("Line No.", '<>%1', Line."Line No.");//Number payment = tender code taka voucher
        TransLineTender.SetRange("Entry Status", TransLineTender."Entry Status"::" ");
        TransLineTender.SetRange("Entry Type", TransLineTender."Entry Type"::Payment);
        TransLineTender.CalcSums(TransLineTender.Amount);
        totalAmountTender := TransLineTender.Amount;

        totalAmountTender := totalAmountTender + VoucherEntry."Remaining Amount Now";

        // 	tender - amount 	
        //  TH1 	 500-300 	 cal > 0 => Lấy reaming - cal 
        //  TH2  	 500-500 	 cal = 0 => lấy giá trị reaming voucher 
        //  TH3 	 500-700 	 cal < 0 => lấy giá trị reaming voucher 
        //  TH3  	 Amount = 0 	 Không đủ điều kiện 

        calAmountCurrent := totalAmountTender - totalAmountItemValid;
        if calAmountCurrent <= 0 then begin
            Line.Amount := VoucherEntry."Remaining Amount Now";
        end else if calAmountCurrent > 0 then begin //Chỉ lấy amount đủ cho item đủ điều kiện
            Line.Amount := VoucherEntry."Remaining Amount Now" - calAmountCurrent;
        end;
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnAfterVoidLine', '', false, false)]
    // local procedure wp_OnVoidLine(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line")
    // var
    //     lposTranLine: Record "LSC POS Trans. Line";
    //     lposTranLineUpdate: Record "LSC POS Trans. Line";
    // begin
    //     //kiêm tra nếu còn 1 voucher nào apply thì vẫn giữ nguyên
    //     lposTranLine.Reset();
    //     lposTranLine.SetRange("Receipt No.", POSTransaction."Receipt No.");
    //     lposTranLine.SetRange("Entry Type", POSTransLine."Entry Type"::Payment);
    //     lposTranLine.SetRange("Entry Status", POSTransLine."Entry Status"::" ");
    //     lposTranLine.SetRange("Number", POSTransLine."Number");
    //     if not lposTranLine.FindSet() then begin
    //         lposTranLineUpdate.Reset();
    //         lposTranLineUpdate.SetRange("Receipt No.", POSTransaction."Receipt No.");
    //         lposTranLineUpdate.SetRange("Entry Type", POSTransLine."Entry Type"::Item);
    //         lposTranLineUpdate.SetRange("Entry Status", POSTransLine."Entry Status"::" ");
    //         if lposTranLineUpdate.FindSet() then begin
    //             repeat
    //                 lposTranLineUpdate."Is Used VC" := false;
    //                 lposTranLineUpdate."Voucher ID of Used" := '';
    //                 lposTranLineUpdate.Modify();
    //             until lposTranLineUpdate.Next() = 0;
    //         end;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'SalesEntryOnBeforeInsertV2', '', false, false)]
    // local procedure wp_OnInsertSalesTransaction(var pPOSTransLineTemp: Record "LSC POS Trans. Line" temporary; var pTransSalesEntry: Record "LSC Trans. Sales Entry")
    // begin
    //     pTransSalesEntry."Is Used VC" := pPOSTransLineTemp."Is Used VC";
    //     pTransSalesEntry."Voucher ID of Used" := pPOSTransLineTemp."Voucher ID of Used";
    // end;

    local procedure VoucherBelongsToMember(EntryCode: Code[20]; MemberCardNo: Code[20]): Boolean
    var
        IssueLog: Record wpIssueLog;
        IssueLogLine: Record wpIssueLogLine;
    begin
        // Find the log line that contains this entry code
        IssueLogLine.Reset();
        IssueLogLine.SetRange("Document No.", EntryCode);
        if not IssueLogLine.FindFirst() then
            exit(false); // voucher not found in any log

        // Get the header and check member card
        IssueLog.Reset();
        IssueLog.SetRange("Entry No.", IssueLogLine."Entry No.");
        if not IssueLog.FindFirst() then
            exit(false);

        exit(IssueLog."Member Card" = MemberCardNo);
    end;

    local procedure ValidateTrans(itemCode: Code[20]; VoucherID: Code[20]): Boolean
    var
        wpVoucherItem: Record wpVoucherItemDiscStp;
        ItemSpecialGroupLink: Record "LSC Item/Special Group Link";
        Item: Record Item;
        HasInclude: Boolean;
    begin
        if not Item.Get(itemCode) then
            exit(false);

        HasInclude := false;

        // 1. Check Item
        wpVoucherItem.Reset();
        wpVoucherItem.SetRange("Voucher ID", VoucherID);
        wpVoucherItem.SetRange(Type, wpVoucherItem.Type::Item);
        wpVoucherItem.SetRange("No.", itemCode);
        if wpVoucherItem.FindLast() then begin
            if wpVoucherItem.Exclude then
                exit(false);
            HasInclude := true;
        end;

        // 2. Check Special Group
        ItemSpecialGroupLink.Reset();
        ItemSpecialGroupLink.SetRange("Item No.", itemCode);
        if ItemSpecialGroupLink.FindSet() then
            repeat
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", VoucherID);
                wpVoucherItem.SetRange(Type, wpVoucherItem.Type::"Special Group");
                wpVoucherItem.SetRange("No.", ItemSpecialGroupLink."Special Group Code");
                if wpVoucherItem.FindLast() then begin
                    if wpVoucherItem.Exclude then
                        exit(false);
                    HasInclude := true;
                end;
            until ItemSpecialGroupLink.Next() = 0;

        // 3. Check Retail Product Group
        wpVoucherItem.Reset();
        wpVoucherItem.SetRange("Voucher ID", VoucherID);
        wpVoucherItem.SetRange(Type, wpVoucherItem.Type::"Retail Product Group");
        wpVoucherItem.SetRange("No.", Item."LSC Retail Product Code");
        if wpVoucherItem.FindLast() then begin
            if wpVoucherItem.Exclude then
                exit(false);
            HasInclude := true;
        end;

        // 4. Check Item Category
        wpVoucherItem.Reset();
        wpVoucherItem.SetRange("Voucher ID", VoucherID);
        wpVoucherItem.SetRange(Type, wpVoucherItem.Type::"Item Category");
        wpVoucherItem.SetRange("No.", Item."Item Category Code");
        if wpVoucherItem.FindLast() then begin
            if wpVoucherItem.Exclude then
                exit(false);
            HasInclude := true;
        end;

        // 5. Check Division
        wpVoucherItem.Reset();
        wpVoucherItem.SetRange("Voucher ID", VoucherID);
        wpVoucherItem.SetRange(Type, wpVoucherItem.Type::Division);
        wpVoucherItem.SetRange("No.", Item."LSC Division Code");
        if wpVoucherItem.FindLast() then begin
            if wpVoucherItem.Exclude then
                exit(false);
            HasInclude := true;
        end;

        exit(HasInclude);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnBeforeInsertPaymentEntryV2', '', false, false)]
    local procedure OnBeforeInsertPaymentEntryV2(var POSTransaction: Record "LSC POS Transaction"; var POSTransLineTemp: Record "LSC POS Trans. Line" temporary; var TransPaymentEntry: Record "LSC Trans. Payment Entry")
    var
        TransInfoCodeEntry: Record "LSC POS Trans. Infocode Entry";
        PosDataEntry: Record "LSC POS Data Entry";
        PosFuncProfile: Record "LSC POS Func. Profile";
        Global_g: Codeunit "LSC POS Session";
    begin
        TransInfoCodeEntry.Reset();
        TransInfoCodeEntry.SetRange("Receipt No.", POSTransaction."Receipt No.");
        TransInfoCodeEntry.SetRange("Store No.", POSTransaction."Store No.");
        TransInfoCodeEntry.SetRange("POS Terminal No.", POSTransaction."POS Terminal No.");
        TransInfoCodeEntry.SetFilter("Information", '<>''''');

        if TransInfoCodeEntry.FindSet() then
            repeat
                PosDataEntry.Reset();
                PosDataEntry.SetRange("Entry Code", TransInfoCodeEntry.Information);
                if PosDataEntry.FindFirst() then begin
                    PosDataEntry.LockTable();
                    PosDataEntry.Status := PosDataEntry.Status::Used;
                    PosDataEntry.Modify(true);
                end;
            until TransInfoCodeEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Trans. Server Utility", 'OnBeforeApplyFiltersOnDataEntrySendAtEndOfTransaction', '', false, false)]
    local procedure OnBeforeApplyFiltersOnDataEntrySendAtEndOfTransaction(InfoCode: Record "LSC Infocode"; var DataEntry: Record "LSC POS Data Entry"; var IsHandled: Boolean)
    begin
        //Kiểm tra voucher no có hay không 
        //Kiểm tra nó có thuộc Taka voucher | Pos data type active voucher = true

        DataEntry.Status := DataEntry.Status::Used;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Trans. Server Utility", 'OnBeforeGetDataEntry', '', false, false)]
    local procedure OnBeforeGetDataEntry(
    Type: Code[10];
    "Code": Code[20];
    var DataEntry: Record "LSC POS Data Entry";
    var ErrorText: Text;
    var IsHandled: Boolean;
    var OK: Boolean)
    var
        PosDataEntryType: Record "LSC POS Data Entry Type";
        PosDataEntry: Record "LSC POS Data Entry";
        ReceiptNo: Code[20];
        PosNo: Text[3];
    begin
        Clear(PosDataEntryType);
        PosDataEntryType.SetRange(Code, Type);
        PosDataEntryType.SetRange("Enable/ Activate Taka Voucher", true);
        if not PosDataEntryType.FindFirst() then
            exit;

        if not PosDataEntry.Get(Type, Code) then
            exit;

        if PosDataEntry.Applied <> true then
            exit;

        ReceiptNo := PosDataEntry."Applied by Receipt No.";
        PosNo := CopyStr(ReceiptNo, 8, 3);

        Message('Voucher: %1 already used\Receipt: %2\POS: %3',
            Code,
            ReceiptNo,
            PosNo);

        IsHandled := true;
        OK := false;
    end;
}

