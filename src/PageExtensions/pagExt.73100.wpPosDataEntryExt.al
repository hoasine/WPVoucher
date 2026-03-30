pageextension 73100 wpPosDataEntryExt extends "LSC POS Data Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("Document No."; Rec."Document No.")
            {
                ApplicationArea = All;
            }
            field(Status; Rec.Status)
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addlast("Navigation")
        {
            action("Import POS Data Entry")
            {
                Visible = ActiveVoucherVisible;
                ApplicationArea = All;
                Caption = 'Import POS Data Entry';
                Image = ImportExcel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    ImportPOSDataEntryPreview();
                end;
            }

            action("Download Excel Template")
            {
                Visible = ActiveVoucherVisible;
                ApplicationArea = All;
                Caption = 'Download Excel Template';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    DownloadExcelTemplate();
                end;
            }
            action("Activate by Document")
            {
                Visible = ActiveVoucherVisible;
                ApplicationArea = All;
                Caption = 'Activate Voucher';
                Image = ActivateDiscounts;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    ActivateVoucherByDocument();
                end;
            }
            // action("Activate Voucher")
            // {
            //     Enabled = ActiveVoucherVisible;
            //     ApplicationArea = All;
            //     Caption = 'Activate Voucher';
            //     Image = ActivateDiscounts;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;

            //     trigger OnAction()
            //     var
            //         ConfirmTxt: Label 'Do you want to reprocess voucher entry?';
            //         SelectedEntries: Record "LSC POS Data Entry";
            //         CreatedCnt: Integer;
            //         SkippedCnt: Integer;
            //     begin
            //         if Rec.IsEmpty then
            //             exit;

            //         if not Confirm(ConfirmTxt, false) then
            //             exit;

            //         CurrPage.SetSelectionFilter(SelectedEntries);
            //         if SelectedEntries.IsEmpty then begin
            //             Message('Please select at least one line.');
            //             exit;
            //         end;

            //         if SelectedEntries.FindSet() then
            //             repeat
            //                 if InsertVoucherEntryFromPOSEntry(SelectedEntries) then
            //                     CreatedCnt += 1
            //                 else
            //                     SkippedCnt += 1;
            //             until SelectedEntries.Next() = 0;

            //         Message('Done. Created: %1. Skipped: %2.', CreatedCnt, SkippedCnt);
            //     end;
            // }
        }
    }

    local procedure DownloadExcelTemplate()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        SheetName: Label 'POS Data Entry';
        FileName: Label 'POSDataEntryTemplate';
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();

        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn('Document No', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Entry Type', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Entry Code', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Amount', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Created in Store No.', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Expiring Date', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Currency Code', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);

        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn('EVENT-A', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('TAKA', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('500ST20816', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(500000, false, '#,##0', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn('HCM01', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(CalcDate('<1Y>', Today), false, 'dd/mm/yyyy', false, false, false, '', TempExcelBuffer."Cell Type"::Date);
        TempExcelBuffer.AddColumn('VND', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);

        TempExcelBuffer.CreateNewBook(SheetName);
        TempExcelBuffer.WriteSheet(SheetName, CompanyName, UserId);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename(FileName);
        TempExcelBuffer.OpenExcel();
    end;

    local procedure InsertVoucherEntryFromPOSEntry(PosEntry: Record "LSC POS Data Entry"): Boolean
    var
        VoucherEntry: Record "LSC Voucher Entries";
        NextLineNo: Integer;
    begin
        VoucherEntry.Reset();
        VoucherEntry.SetRange("Voucher No.", PosEntry."Entry Code");
        if VoucherEntry.FindFirst() then begin
            PosEntry."Date Actived" := Today;
            PosEntry.Status := PosEntry.Status::Active;
            PosEntry.Modify();
            exit(false);
        end;

        VoucherEntry.Init();
        VoucherEntry."Voucher No." := PosEntry."Entry Code";
        VoucherEntry."Store No." := PosEntry."Created in Store No.";
        VoucherEntry."Receipt Number" := PosEntry."Created by Receipt No.";
        VoucherEntry."Line No." := PosEntry."Created by Line No.";
        VoucherEntry.Unposted := false;
        VoucherEntry."Entry Type" := VoucherEntry."Entry Type"::Issued;
        VoucherEntry.Date := PosEntry."Date Created";
        VoucherEntry.Time := Time;
        VoucherEntry.Amount := PosEntry.Amount;
        VoucherEntry."Remaining Amount Now" := PosEntry.Amount;
        VoucherEntry."Currency Code" := PosEntry."Currency Code";
        VoucherEntry."Store Currency Code" := PosEntry."Currency Code";
        VoucherEntry."Currency Factor" := 1;
        VoucherEntry."One Time Redemption" := true;
        VoucherEntry."Voucher Type" := PosEntry."Entry Type";

        VoucherEntry.Insert(true);
        PosEntry.Status := PosEntry.Status::Active;
        PosEntry.Modify();
        exit(true);
    end;

    local procedure ImportPOSDataEntryPreview()
    var
        TempImport: Record "POS Data Entry Import" temporary;
        PreviewPage: Page "wp POS Entry Import Preview";
    begin
        ReadExcelSheet();
        LoadExcelToTempPreview(TempImport);

        PreviewPage.LoadTempData(TempImport);
        PreviewPage.RunModal();

        Clear(TempExcelBuffer);
    end;

    local procedure ReadExcelSheet()
    var
        FileMgt: Codeunit "File Management";
        IStream: InStream;
        FromFile: Text[100];
        UploadExcelMsg: Text[200];
    begin
        UploadExcelMsg := 'Select Excel file';

        if not UploadIntoStream(UploadExcelMsg, '', '', FromFile, IStream) then
            Error('No Excel file found!');

        if FromFile = '' then
            Error('No Excel file found!');

        FileName := FileMgt.GetFileName(FromFile);

        ValidateImportFile(FileName);

        SheetName := TempExcelBuffer.SelectSheetsNameStream(IStream);

        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBookStream(IStream, SheetName);
        TempExcelBuffer.ReadSheet();
    end;

    local procedure ValidateImportFile(SelectedFileName: Text)
    begin
        if CopyStr(LowerCase(SelectedFileName), StrLen(SelectedFileName) - 4, 5) <> '.xlsx' then
            Error('Invalid file type. Only .xlsx files are allowed.');
    end;

    local procedure LoadExcelToTempPreview(var TempImport: Record "POS Data Entry Import" temporary)
    var
        CheckEntry: Record "LSC POS Data Entry";
        RowNo: Integer;
        MaxRowNo: Integer;
    begin
        TempImport.Reset();
        TempImport.DeleteAll();

        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast() then
            MaxRowNo := TempExcelBuffer."Row No."
        else
            exit;

        gCU_ConfigProgressBar.Init(MaxRowNo, 1000, 'Importing POS Data Entry preview...');

        for RowNo := 2 to MaxRowNo do begin
            Clear(TempImport);
            TempImport.Init();

            TempImport."Line No." := RowNo - 1;
            TempImport."Document No." := CopyStr(GetExcelValueAsText(RowNo, 1), 1, MaxStrLen(TempImport."Document No."));
            TempImport."Entry Type" := CopyStr(GetExcelValueAsText(RowNo, 2), 1, MaxStrLen(TempImport."Entry Type"));
            TempImport."Entry Code" := CopyStr(GetExcelValueAsText(RowNo, 3), 1, MaxStrLen(TempImport."Entry Code"));
            TempImport.Amount := GetExcelValueAsDecimal(RowNo, 4);
            TempImport."Created in Store No." := CopyStr(GetExcelValueAsText(RowNo, 5), 1, MaxStrLen(TempImport."Created in Store No."));
            TempImport."Expiring Date" := GetExcelValueAsDate(RowNo, 6);
            TempImport."Currency Code" := CopyStr(GetExcelValueAsText(RowNo, 7), 1, MaxStrLen(TempImport."Currency Code"));

            ValidatePreviewRow(TempImport);

            CheckEntry.Reset();
            CheckEntry.SetRange("Entry Type", TempImport."Entry Type");
            CheckEntry.SetRange("Entry Code", TempImport."Entry Code");
            if CheckEntry.FindFirst() then
                AddErrorMessage(TempImport, 'Entry already exists in POS Data Entry.');

            if (TempImport."Entry Type" <> Rec."Entry Type") then begin
                AddErrorMessage(TempImport, 'Entry Type is incorrect.');
            end;

            TempImport.Insert();

            gCU_ConfigProgressBar.Update(StrSubstNo(RecordsXofYMsg, RowNo, MaxRowNo));
        end;

        gCU_ConfigProgressBar.Close();
    end;

    local procedure ValidatePreviewRow(var TempImport: Record "POS Data Entry Import" temporary)
    begin
        if TempImport."Entry Type" = '' then
            AddErrorMessage(TempImport, 'Entry Type is empty.');

        if TempImport."Entry Code" = '' then
            AddErrorMessage(TempImport, 'Entry Code is empty.');

        if TempImport."Created in Store No." = '' then
            AddErrorMessage(TempImport, 'Store No. is empty.');

        if TempImport.Amount = 0 then
            AddErrorMessage(TempImport, 'Amount is empty or zero.');
    end;

    local procedure AddErrorMessage(var TempImport: Record "POS Data Entry Import" temporary; NewError: Text[250])
    begin
        if TempImport."Error Message" = '' then
            TempImport."Error Message" := NewError
        else
            TempImport."Error Message" := CopyStr(TempImport."Error Message" + ' | ' + NewError, 1, MaxStrLen(TempImport."Error Message"));
    end;

    local procedure GetExcelValueAsText(RowID: Integer; ColumnID: Integer): Text
    var
        ValueTxt: Text;
    begin
        ValueTxt := '';

        TempExcelBuffer.Reset();
        if TempExcelBuffer.Get(RowID, ColumnID) then
            ValueTxt := TempExcelBuffer."Cell Value as Text";

        exit(ValueTxt);
    end;

    local procedure GetExcelValueAsDecimal(RowID: Integer; ColumnID: Integer): Decimal
    var
        ValueDec: Decimal;
        CellText: Text;
    begin
        ValueDec := 0;

        TempExcelBuffer.Reset();
        if TempExcelBuffer.Get(RowID, ColumnID) then begin
            CellText := TempExcelBuffer."Cell Value as Text";
            if CellText <> '' then
                if not Evaluate(ValueDec, CellText) then
                    Error('Cannot convert "%1" to Decimal at row %2 col %3.', CellText, RowID, ColumnID);
        end;

        exit(ValueDec);
    end;

    local procedure GetExcelValueAsDate(RowID: Integer; ColumnID: Integer): Date
    var
        ValueDate: Date;
        CellText: Text;
    begin
        ValueDate := 0D;

        TempExcelBuffer.Reset();
        if TempExcelBuffer.Get(RowID, ColumnID) then begin
            CellText := TempExcelBuffer."Cell Value as Text";
            if CellText <> '' then
                if not Evaluate(ValueDate, CellText) then
                    Error('Cannot convert "%1" to Date at row %2 col %3.', CellText, RowID, ColumnID);
        end;

        exit(ValueDate);
    end;

    local procedure ActivateVoucherByDocument()
    var
        DocBuffer: Record "POS Entry Document Buffer" temporary;
        POSDataEntry: Record "LSC POS Data Entry";
        DocPage: Page "POS Entry Document List";
        SelectedDoc: Code[20];
        ActivatedCount: Integer;
        ConfirmText: Label 'Do you want activate all POS Data Entries of document %1?';
    begin

        POSDataEntry.Reset();
        if POSDataEntry.FindSet() then
            repeat
                if POSDataEntry."Document No." <> '' then begin
                    if not DocBuffer.Get(POSDataEntry."Document No.") then begin
                        DocBuffer.Init();
                        DocBuffer."Document No." := POSDataEntry."Document No.";
                        DocBuffer."Total Voucher" := 1;
                        DocBuffer.Insert();
                    end else begin
                        DocBuffer."Total Voucher" += 1;
                        DocBuffer.Modify();
                    end;
                end;
            until POSDataEntry.Next() = 0;

        DocPage.LoadData(DocBuffer);
        DocPage.LookupMode(true);
        if DocPage.RunModal() = Action::LookupOK then begin
            DocPage.GetRecord(DocBuffer);
            SelectedDoc := DocBuffer."Document No.";

            if not Confirm(ConfirmText, false, SelectedDoc) then
                exit;

            //ActivatedCount := ActivateAllFromDocument(SelectedDoc);

            ActivateAllFromDocument(SelectedDoc);
        end;
    end;

    var
        ActiveVoucherVisible: Boolean;
        FileName: Text[100];
        SheetName: Text[100];
        TempExcelBuffer: Record "Excel Buffer" temporary;
        gCU_ConfigProgressBar: Codeunit "Config. Progress Bar";
        RecordsXofYMsg: Label 'Processing %1 of %2 records';

    local procedure ActivateAllFromDocument(DocumentNo: Code[20]) ActivatedCount: Integer
    var
        PosEntry: Record "LSC POS Data Entry";
        CreatedCnt: Integer;
        SkippedCnt: Integer;
    begin

        PosEntry.SetRange(Status, PosEntry.Status::" ");
        PosEntry.SetRange("Document No.", DocumentNo);

        if PosEntry.FindSet() then
            repeat
                if InsertVoucherEntryFromPOSEntry(PosEntry) then
                    CreatedCnt += 1
                else
                    SkippedCnt += 1;
            until PosEntry.Next() = 0;

        Message(
            'Document %1 processed.\Created: %2\Skipped: %3',
            DocumentNo,
            CreatedCnt,
            SkippedCnt);
    end;

    trigger OnAfterGetCurrRecord()
    var
        POSDataEntryType: Record "LSC POS Data Entry Type";
    begin
        ActiveVoucherVisible := false;

        if Rec."Entry Type" = '' then
            exit;

        if not POSDataEntryType.Get(Rec."Entry Type") then
            exit;

        ActiveVoucherVisible := POSDataEntryType."Enable/ Activate Taka Voucher";
    end;
}



