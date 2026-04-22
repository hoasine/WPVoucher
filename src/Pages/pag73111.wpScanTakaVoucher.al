page 73111 "Scan Taka Voucher"
{
    PageType = Card;
    Caption = 'Scan Taka Voucher';
    SourceTable = "LSC POS Data Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(ScanGroup)
            {
                Caption = 'Scan Voucher';

                field(ScanVoucher; ScanVoucherCode)
                {
                    Caption = 'Scan Voucher Code';
                    ApplicationArea = All;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if ScanVoucherCode = '' then
                            exit;
                        ProcessVoucher(ScanVoucherCode);
                        Clear(ScanVoucherCode);
                        CurrPage.Update(false);
                    end;
                }

                field(ScannedCount; ScannedCount)
                {
                    Caption = 'Scanned';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }

                field(VoucherLimit; VoucherLimit)
                {
                    Caption = 'Actual Voucher';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field(MaxVoucherQty; MaxVoucherQty - MaxVoucherAllowed)
                {
                    Caption = 'Max Voucher Qty';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
            }

            group(ScannedListGroup)
            {
                Caption = 'Scanned Vouchers';

                repeater(ScannedLines)
                {
                    ShowCaption = false;
                    Editable = false;

                    field("Entry Code"; Rec."Entry Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Entry Code';
                    }
                    field("Amount"; Rec.Amount)
                    {
                        ApplicationArea = All;
                        Caption = 'Amount';
                    }
                    field("Document No."; Rec."Document No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Document No.';
                    }
                    field("Expiring Date"; Rec."Expiring Date")
                    {
                        ApplicationArea = All;
                        Caption = 'Expiring Date';
                    }
                    field("Date Applied"; Rec."Date Applied")
                    {
                        ApplicationArea = All;
                        Caption = 'Date Applied';
                    }
                    field(StatusField; Rec.Status)
                    {
                        ApplicationArea = All;
                        Caption = 'Status';
                        StyleExpr = StatusStyle;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteSelected)
            {
                Caption = 'Delete';
                Image = Delete;
                ApplicationArea = All;
                Promoted = true;
                Scope = Repeater;

                trigger OnAction()
                var
                    TempRec: Record "LSC POS Data Entry";
                begin
                    CurrPage.SetSelectionFilter(TempRec);

                    if TempRec.IsEmpty then
                        Error('Please select at least one line.');

                    if not Confirm('Delete selected lines?', false) then
                        exit;

                    if TempRec.FindSet() then
                        repeat
                            Rec.Get(TempRec."Entry Type", TempRec."Entry Code");
                            Rec.Delete();
                            ScannedCount -= 1;
                        until TempRec.Next() = 0;

                    CurrPage.Update(false);
                end;
            }

            action(IssueVoucher)
            {
                Caption = 'Issue Voucher';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    PosEntry: Record "LSC POS Data Entry";
                    VoucherEntry: Record "LSC Voucher Entries";
                begin
                    if ScannedCount = 0 then begin
                        Message('Please scan at least one voucher before issuing.');
                        exit;
                    end;

                    if ScannedCount < VoucherLimit then begin
                        if not Confirm('Only %1 of %2 vouchers scanned. Issue anyway?', false, ScannedCount, VoucherLimit) then
                            exit;
                    end else begin
                        if not Confirm('Issue %1 voucher(s) for this member? This cannot be undone.', false, ScannedCount) then
                            exit;
                    end;

                    Rec.Reset();
                    if Rec.FindSet() then
                        repeat
                            PosEntry.Reset();
                            PosEntry.SetRange("Entry Code", Rec."Entry Code");
                            if PosEntry.FindFirst() then begin
                                PosEntry.LockTable();
                                PosEntry.Status := PosEntry.Status::Redeemed;
                                PosEntry."Date Redeemed" := Today;
                                PosEntry.Modify(true);
                                VoucherEntry.Reset();
                                VoucherEntry.SetRange("Voucher No.", PosEntry."Entry Code");
                                if not VoucherEntry.FindFirst() then begin
                                    VoucherEntry.Init();
                                    VoucherEntry."Voucher No." := PosEntry."Entry Code";
                                    VoucherEntry."Store No." := PosEntry."Created in Store No.";
                                    VoucherEntry."Receipt Number" := PosEntry."Created by Receipt No.";
                                    VoucherEntry."Line No." := PosEntry."Created by Line No.";
                                    VoucherEntry.Unposted := false;
                                    VoucherEntry."Entry Type" := VoucherEntry."Entry Type"::Issued;
                                    VoucherEntry.Date := Today;
                                    VoucherEntry.Time := Time;
                                    VoucherEntry.Amount := PosEntry.Amount;
                                    VoucherEntry."Remaining Amount Now" := PosEntry.Amount;
                                    VoucherEntry."Currency Code" := PosEntry."Currency Code";
                                    VoucherEntry."Store Currency Code" := PosEntry."Currency Code";
                                    VoucherEntry."Currency Factor" := 1;
                                    VoucherEntry."One Time Redemption" := true;
                                    VoucherEntry."Voucher Type" := PosEntry."Entry Type";
                                    if VoucherID <> '' then
                                        VoucherEntry."Voucher Id" := VoucherID;
                                    VoucherEntry.Insert(true);
                                end else begin
                                    if VoucherID <> '' then begin
                                        VoucherEntry.LockTable();
                                        VoucherEntry."Voucher Id" := VoucherID;
                                        VoucherEntry.Modify(true);
                                    end;
                                end;
                            end;

                        until Rec.Next() = 0;

                    IsIssued := true;
                    CurrPage.Close();
                end;


            }
        }
    }

    var
        ScanVoucherCode: Code[30];
        VoucherLimit: Integer;
        VoucherAmount: Decimal;
        ScannedCount: Integer;
        StatusStyle: Text;
        IsIssued: Boolean;
        VoucherID: Code[20];
        MaxVoucherQty: Integer;
        MaxVoucherAllowed: Integer;

    procedure SetVoucherLimitAndAmount(pLimit: Integer; pAmount: Decimal; pMax: Integer; pMaxVoucherAllowed: Integer)
    begin
        VoucherLimit := pLimit;
        VoucherAmount := pAmount;
        MaxVoucherQty := pMax;
        MaxVoucherAllowed := pMaxVoucherAllowed;
    end;

    procedure WasIssued(): Boolean
    begin
        exit(IsIssued);
    end;

    local procedure ProcessVoucher(VoucherCode: Code[30])
    var
        PosEntry: Record "LSC POS Data Entry";
    begin
        if ScannedCount >= VoucherLimit then begin
            Message('Only %1 voucher(s) allowed. Already scanned %2.', VoucherLimit, ScannedCount);
            exit;
        end;


        PosEntry.Reset();
        PosEntry.SetRange("Entry Code", VoucherCode);
        if not PosEntry.FindFirst() then begin
            Message('Voucher %1 not found.', VoucherCode);
            exit;
        end;

        if PosEntry."Document No." <> VoucherID then begin
            Message('Voucher %1 (%2) is not included in promotion program %3.', VoucherCode, PosEntry."Document No.", VoucherID);
            exit;
        end;


        if PosEntry.Status = PosEntry.Status::Redeemed then begin
            Message('Voucher %1 is already redeemed.', VoucherCode);
            exit;
        end;


        if PosEntry.Amount <> VoucherAmount then begin
            Message('Only applies to amount of %1.', VoucherAmount);
            exit;
        end;

        if PosEntry.Status <> PosEntry.Status::Active then begin
            Message('Voucher %1 is not active (current status: %2).', VoucherCode, PosEntry.Status);
            exit;
        end;

        Rec.Reset();
        Rec.SetRange("Entry Code", VoucherCode);
        if not Rec.IsEmpty() then begin
            Rec.Reset();
            Message('Voucher %1 already scanned in this session.', VoucherCode);
            exit;
        end;

        Rec.Reset();
        Rec.Init();
        Rec.TransferFields(PosEntry);
        Rec.Insert();

        ScannedCount += 1;
    end;

    procedure SetVoucherID(pVoucherID: Code[20])
    begin
        VoucherID := pVoucherID;
    end;

    procedure GetScannedVouchers(var TempScanned: Record "LSC POS Data Entry" temporary)
    begin
        TempScanned.Reset();
        TempScanned.DeleteAll();

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                TempScanned := Rec;
                TempScanned.Insert();
            until Rec.Next() = 0;
    end;


    trigger OnAfterGetRecord()
    begin
        if Rec.Status = Rec.Status::Redeemed then
            StatusStyle := 'Favorable'
        else
            StatusStyle := 'StandardAccent';
    end;
}