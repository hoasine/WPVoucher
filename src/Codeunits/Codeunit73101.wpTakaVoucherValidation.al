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
        VoucherID: Code[20];
    begin
        VoucherEntry.Reset();
        VoucherEntry.SetRange("Voucher No.", DataEntry."Entry Code");
        if not VoucherEntry.FindFirst() then
            exit;

        VoucherID := VoucherEntry."Voucher Id";
        if VoucherID = '' then
            exit;

        if not ValidateTrans(Line."Receipt No.", VoucherID) then begin
            ErrorTxt := 'This voucher cannot be applied. No qualifying items found in the transaction.';
            IsHandled := true;
            ReturnValue := false;
        end;
    end;

    local procedure ValidateTrans(ReceiptNo: Code[20]; VoucherID: Code[20]): Boolean
    var
        TransLine: Record "LSC Pos Trans. Line";
        wpVoucherItem: Record wpVoucherItemDiscStp;
        ItemSpecialGroupLink: Record "LSC Item/Special Group Link";
        Item: Record Item;
        Exclude: Boolean;
    begin

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnAfterPostTransaction', '', false, false)]
    local procedure OnAfterPostTransaction(var TransactionHeader_p: Record "LSC Transaction Header")
    var
        TransInfoCodeEntry: Record "LSC Trans. Infocode Entry";
        PosDataEntry: Record "LSC POS Data Entry";
    begin
        TransInfoCodeEntry.Reset();
        TransInfoCodeEntry.SetRange("Transaction No.", TransactionHeader_p."Transaction No.");
        TransInfoCodeEntry.SetRange("Store No.", TransactionHeader_p."Store No.");
        TransInfoCodeEntry.SetRange("POS Terminal No.", TransactionHeader_p."POS Terminal No.");
        TransInfoCodeEntry.SetFilter("Information", '<>''''');

        if TransInfoCodeEntry.FindSet() then
            repeat
                PosDataEntry.Reset();
                PosDataEntry.SetRange("Entry Type", 'TK VOUCHER');
                PosDataEntry.SetRange("Entry Code", TransInfoCodeEntry.Information);

                if PosDataEntry.FindFirst() then begin
                    PosDataEntry.LockTable();
                    PosDataEntry.Status := PosDataEntry.Status::Used;
                    PosDataEntry."Date Applied" := Today;
                    PosDataEntry."Applied by Receipt No." := TransactionHeader_p."Receipt No.";
                    PosDataEntry.Modify(true);
                end;
            until TransInfoCodeEntry.Next() = 0;
    end;
}