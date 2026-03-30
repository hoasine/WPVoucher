codeunit 73101 "wpTakaVoucherValidation"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Infocode Utility", 'OnBeforeDataEntryCheckAmount', '', false, false)]
    local procedure OnBeforeDataEntryCheckAmount(
    MgrKeyActive: Boolean;
    RLineAmount: Decimal;
    var Line: Record "LSC Pos Trans. Line";
    var Trans: Record "LSC POS Transaction";
    var DataEntry: Record "LSC POS Data Entry";
    var DataEntryType: Record "LSC POS Data Entry Type";
    var ErrorTxt: Text;
    var IsHandled: Boolean;
    var ReturnValue: Boolean)
    var
        VoucherEntry: Record "LSC Voucher Entries";
        PosDataEntry: Record "LSC POS Data Entry";
        VoucherID: Code[20];
        MemberCardNo: Code[20];
    begin
        // Lấy Pos data entry
        PosDataEntry.Reset();
        PosDataEntry.SetRange("Entry Code", DataEntry."Entry Code");
        if not PosDataEntry.FindFirst() then
            exit;

        // check voucher phải ở status redeemp
        if PosDataEntry.Status <> PosDataEntry.Status::Redeemed then begin
            case PosDataEntry.Status of
                PosDataEntry.Status::Active:
                    ErrorTxt := StrSubstNo('Voucher %1 has not been issued yet ', DataEntry."Entry Code");
                PosDataEntry.Status::" ":
                    ErrorTxt := StrSubstNo('Voucher %1 is not activated.', DataEntry."Entry Code");
                else
                    ErrorTxt := StrSubstNo('Voucher %1 cannot be used (Status: %2).', DataEntry."Entry Code", PosDataEntry.Status);
            end;
            IsHandled := true;
            ReturnValue := false;
            exit;
        end;

        VoucherEntry.Reset();
        VoucherEntry.SetRange("Voucher No.", DataEntry."Entry Code");
        if not VoucherEntry.FindFirst() then
            exit;

        VoucherID := VoucherEntry."Voucher Id";
        if VoucherID = '' then
            exit;

        // Check coi member này có dùng được voucher này không

        MemberCardNo := Trans."Member Card No.";

        if MemberCardNo = '' then begin
            ErrorTxt := 'Please input Member Card before using voucher.';
            IsHandled := true;
            ReturnValue := false;
            exit;
        end;

        if MemberCardNo <> '' then begin
            if not VoucherBelongsToMember(DataEntry."Entry Code", MemberCardNo) then begin
                ErrorTxt := StrSubstNo('Voucher %1 does not belong to this member.', DataEntry."Entry Code");
                IsHandled := true;
                ReturnValue := false;
                exit;
            end;
        end;

        // Item check
        if not ValidateTrans(Line."Receipt No.", VoucherID) then begin
            ErrorTxt := 'This voucher cannot be applied. No qualifying items found in the transaction.';
            IsHandled := true;
            ReturnValue := false;
        end;
    end;

    local procedure VoucherBelongsToMember(EntryCode: Code[20]; MemberCardNo: Code[20]): Boolean
    var
        IssueLog: Record wpIssueVoucherLog;
        IssueLogLine: Record wpIssueVoucherLogLine;
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

    local procedure ValidateTrans(ReceiptNo: Code[20]; VoucherID: Code[20]): Boolean
    var
        TransLine: Record "LSC Pos Trans. Line";
        wpVoucherItem: Record wpVoucherItemDiscStp;
        ItemSpecialGroupLink: Record "LSC Item/Special Group Link";
        Item: Record Item;
        Exclude: Boolean;
        PosDataEntry: Record "LSC POS Data Entry";
    begin




        PosDataEntry.Reset();
        PosDataEntry."Entry Code" := '';

        TransLine.Reset();
        TransLine.SetRange("Receipt No.", ReceiptNo);
        // Filter item line
        TransLine.SetRange("Entry Type", TransLine."Entry Type"::Item);
        if not TransLine.FindSet() then
            exit(false);

        repeat
            if Item.Get(TransLine.Number) then begin

                // Item level
                Exclude := false;
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", VoucherID);
                wpVoucherItem.SetRange(Type, wpVoucherItem.Type::Item);
                wpVoucherItem.SetRange("No.", TransLine.Number);
                if wpVoucherItem.FindLast() then begin
                    Exclude := wpVoucherItem.Exclude;
                    if not Exclude then
                        exit(true);
                end;

                // Special Group
                ItemSpecialGroupLink.Reset();
                ItemSpecialGroupLink.SetRange("Item No.", TransLine.Number);
                if ItemSpecialGroupLink.FindSet() then
                    repeat
                        wpVoucherItem.Reset();
                        wpVoucherItem.SetRange("Voucher ID", VoucherID);
                        wpVoucherItem.SetRange(Type, wpVoucherItem.Type::"Special Group");
                        wpVoucherItem.SetRange("No.", ItemSpecialGroupLink."Special Group Code");
                        if wpVoucherItem.FindLast() then begin
                            Exclude := wpVoucherItem.Exclude;
                            if not Exclude then
                                exit(true);
                        end;
                    until ItemSpecialGroupLink.Next() = 0;

                // Retail Product Group
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", VoucherID);
                wpVoucherItem.SetRange(Type, wpVoucherItem.Type::"Retail Product Group");
                wpVoucherItem.SetRange("No.", Item."LSC Retail Product Code");
                if wpVoucherItem.FindLast() then begin
                    Exclude := wpVoucherItem.Exclude;
                    if not Exclude then
                        exit(true);
                end;

                // Item Category
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", VoucherID);
                wpVoucherItem.SetRange(Type, wpVoucherItem.Type::"Item Category");
                wpVoucherItem.SetRange("No.", Item."Item Category Code");
                if wpVoucherItem.FindLast() then begin
                    Exclude := wpVoucherItem.Exclude;
                    if not Exclude then
                        exit(true);
                end;

                // Division
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", VoucherID);
                wpVoucherItem.SetRange(Type, wpVoucherItem.Type::Division);
                wpVoucherItem.SetRange("No.", Item."LSC Division Code");
                if wpVoucherItem.FindLast() then begin
                    Exclude := wpVoucherItem.Exclude;
                    if not Exclude then
                        exit(true);
                end;

                // All
                wpVoucherItem.Reset();
                wpVoucherItem.SetRange("Voucher ID", VoucherID);
                wpVoucherItem.SetRange(Type, wpVoucherItem.Type::All);
                wpVoucherItem.SetRange("No.", '');
                if wpVoucherItem.FindLast() then begin
                    Exclude := wpVoucherItem.Exclude;
                    if not Exclude then
                        exit(true);
                end;
            end;
        until TransLine.Next() = 0;



        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnBeforeInsertPaymentEntryV2', '', false, false)]
    local procedure OnBeforeInsertPaymentEntryV2(var POSTransaction: Record "LSC POS Transaction"; var POSTransLineTemp: Record "LSC POS Trans. Line" temporary; var TransPaymentEntry: Record "LSC Trans. Payment Entry")
    var
        TransInfoCodeEntry: Record "LSC POS Trans. Infocode Entry";
        PosDataEntry: Record "LSC POS Data Entry";
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
                    // PosDataEntry."Date Applied" := Today;
                    // PosDataEntry."Applied by Receipt No." := TransactionHeader_p."Receipt No.";
                    PosDataEntry.Modify(true);
                end;
            until TransInfoCodeEntry.Next() = 0;
    end;


    //Check status voucher member, redeemp, expiredate
}

