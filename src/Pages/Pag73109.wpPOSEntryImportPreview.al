page 73121 "wp POS Entry Import Preview"
{
    PageType = List;
    SourceTable = "POS Data Entry Import";
    SourceTableTemporary = true;
    Caption = 'Taka Voucher Import';
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Import Options';

                field(SelectedVoucherID; SelectedVoucherID)
                {
                    ApplicationArea = All;
                    Caption = 'Voucher ID';
                    // TableRelation = wpVoucherMaintenance.ID where(Enabled = const(true));
                    TableRelation = wpVoucherMaintenance.ID;
                    ShowMandatory = true;
                    ToolTip = 'Select Voucher ID before accepting data.';


                    trigger OnValidate()
                    begin
                        ApplyVoucherIDToPreview();
                    end;
                }
            }

            repeater(General)
            {
                field("Line No."; Rec."Line No.")
                {
                    Caption = 'Number Rec.';
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                }
                field("Entry Code"; Rec."Entry Code")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Created in Store No."; Rec."Created in Store No.")
                {
                    ApplicationArea = All;
                }
                field("Expiring Date"; Rec."Expiring Date")
                {
                    ApplicationArea = All;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    StyleExpr = ErrorStyle;
                }
                field(Imported; Rec.Imported)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SubmitData)
            {
                Caption = 'Accept Data';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    if SelectedVoucherID = '' then
                        Error('Please select Voucher ID before accepting data.');

                    if HasImportError() then
                        Error('Cannot import data because one or more lines contain errors. Please review and fix all error lines first.');

                    SubmitToPOSDataEntry();
                end;
            }
        }
    }

    var
        ErrorStyle: Text;
        SelectedVoucherID: Code[20];
        gCU_ConfigProgressBar: Codeunit "Config. Progress Bar";
        RecordsXofYMsg: Label 'Submitting %1 of %2 records';

    trigger OnAfterGetRecord()
    begin
        if Rec."Error Message" <> '' then
            ErrorStyle := 'Unfavorable'
        else
            ErrorStyle := 'Favorable';
    end;

    local procedure HasImportError(): Boolean
    var
        TempCheck: Record "POS Data Entry Import" temporary;
    begin
        TempCheck.Copy(Rec, true);
        TempCheck.Reset();
        TempCheck.SetFilter("Error Message", '<>%1', '');

        exit(TempCheck.FindFirst());
    end;

    local procedure ApplyVoucherIDToPreview()
    begin
        if SelectedVoucherID = '' then
            exit;

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                Rec."Document No." := SelectedVoucherID;
                Rec.Modify();
            until Rec.Next() = 0;

        CurrPage.Update(false);
    end;

    procedure LoadTempData(var TempImport: Record "POS Data Entry Import" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if TempImport.FindSet() then
            repeat
                Rec := TempImport;
                Rec.Insert();
            until TempImport.Next() = 0;
    end;

    procedure SetVoucherID(pVoucherID: Code[20])
    begin
        SelectedVoucherID := pVoucherID;
    end;

    local procedure SubmitToPOSDataEntry()
    var
        POSDataEntry: Record "LSC POS Data Entry";
        ExistingPOSDataEntry: Record "LSC POS Data Entry";
        ImportedCnt: Integer;
        SkippedCnt: Integer;
        NextLineNo: Integer;
        TotalCount: Integer;
        CurrentCount: Integer;
    begin
        if not Confirm('Do you want to submit data into POS Data Entry?', false) then
            exit;

        POSDataEntry.Reset();
        POSDataEntry.SetRange("Document No.", SelectedVoucherID);
        if POSDataEntry.FindLast() then
            NextLineNo := POSDataEntry."Created by Line No." + 1000
        else
            NextLineNo := 1000;

        Rec.Reset();
        TotalCount := Rec.Count();

        gCU_ConfigProgressBar.Init(TotalCount, 1000, 'Submitting POS Data Entry...');

        if Rec.FindSet() then
            repeat
                CurrentCount += 1;

                if Rec."Error Message" = '' then begin
                    ExistingPOSDataEntry.Reset();
                    ExistingPOSDataEntry.SetRange("Entry Type", Rec."Entry Type");
                    ExistingPOSDataEntry.SetRange("Entry Code", Rec."Entry Code");

                    if ExistingPOSDataEntry.FindFirst() then
                        SkippedCnt += 1
                    else begin
                        POSDataEntry.Init();
                        POSDataEntry."Document No." := SelectedVoucherID;
                        POSDataEntry."Entry Type" := Rec."Entry Type";
                        POSDataEntry."Entry Code" := Rec."Entry Code";
                        POSDataEntry.Amount := Rec.Amount;
                        POSDataEntry."Created by Receipt No." := SelectedVoucherID;
                        POSDataEntry."Created by Line No." := NextLineNo;
                        POSDataEntry.Applied := false;
                        POSDataEntry."Applied by Receipt No." := '';
                        POSDataEntry."Date Created" := Today;
                        POSDataEntry."Created in Store No." := Rec."Created in Store No.";
                        POSDataEntry."Expiring Date" := Rec."Expiring Date";
                        POSDataEntry."Currency Code" := Rec."Currency Code";

                        POSDataEntry.Insert(false);

                        NextLineNo += 1000;

                        Rec.Imported := true;
                        Rec.Modify();

                        ImportedCnt += 1;
                    end;
                end else
                    SkippedCnt += 1;

                gCU_ConfigProgressBar.Update(StrSubstNo(RecordsXofYMsg, CurrentCount, TotalCount));
            until Rec.Next() = 0;

        gCU_ConfigProgressBar.Close();

        Message('Submit Taka voucher completed. Imported: %1. Skipped: %2.', ImportedCnt, SkippedCnt);
        CurrPage.Update(false);
    end;
}