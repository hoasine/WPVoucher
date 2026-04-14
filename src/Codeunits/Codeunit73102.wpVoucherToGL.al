codeunit 73102 wpVoucherToGL
{
    trigger OnRun()
    begin
        UpdateVoucherToGLJournal();
    end;

    procedure UpdateVoucherToGLJournal()
    var
        tbwpVoucherMaintenance: Record wpVoucherMaintenance;
        tbSalesReceivables: Record "Sales & Receivables Setup";
        dateFilter: Date;
    begin
        if tbSalesReceivables.Get() then begin
            if tbSalesReceivables."Voucher GL Date" <> 0D then
                dateFilter := tbSalesReceivables."Voucher GL Date"
            else
                dateFilter := Today;
        end else
            dateFilter := Today;

        tbwpVoucherMaintenance.Reset();
        tbwpVoucherMaintenance.SetRange(Enabled, true);
        tbwpVoucherMaintenance.SetFilter("Starting Date", '<=%1', dateFilter);
        tbwpVoucherMaintenance.SetFilter("Ending Date", '>=%1|%2', dateFilter, 0D);

        if tbwpVoucherMaintenance.FindSet() then
            repeat
                if tbwpVoucherMaintenance."Reason Code" = '' then begin
                    exit;
                end;

                ProcessOneCampaign(tbwpVoucherMaintenance, dateFilter);
                Commit;
            until tbwpVoucherMaintenance.Next() = 0;
    end;

    local procedure ProcessOneCampaign(tbwpVoucherMaintenance: Record wpVoucherMaintenance; dateFilter: Date)
    var
        tbSalesReceivables: Record "Sales & Receivables Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        JounalTemplate: Record "Gen. Journal Template";
        tbPosDataEntry: Record "LSC POS Data Entry Type";
        tbPOSDataEntryLine: Record "LSC POS Data Entry";
        NoOfLines: Integer;
        TotalVoucherAmounr: Decimal;
    begin
        Clear(NoOfLines);
        Clear(TotalVoucherAmounr);

        tbPosDataEntry.Reset();
        tbPosDataEntry.SetRange("Enable/ Activate Taka Voucher", true);
        if tbPosDataEntry.FindSet() then
            repeat
                tbPOSDataEntryLine.Reset();
                tbPOSDataEntryLine.SetRange("Entry Type", tbPosDataEntry.Code);
                tbPOSDataEntryLine.SetRange("Status", tbPOSDataEntryLine.Status::Active);
                tbPOSDataEntryLine.SetRange("Document No.", tbwpVoucherMaintenance.ID);
                tbPOSDataEntryLine.SetRange("Date Actived", dateFilter);
                tbPOSDataEntryLine.SetRange("Date Procesed", 0D);
                tbPOSDataEntryLine.CalcSums(Amount);

                TotalVoucherAmounr += tbPOSDataEntryLine.Amount;
            until tbPosDataEntry.Next() = 0;

        if TotalVoucherAmounr = 0 then
            exit;

        if not JounalTemplate.Get('GENERAL') then
            Error('Not found No. Series GENERAL.');

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", 'GENERAL');
        GenJournalLine.SetRange("Journal Batch Name", 'DEFAULT');
        if GenJournalLine.FindLast() then
            NoOfLines := GenJournalLine."Line No."
        else
            NoOfLines := 10000;

        Clear(GenJournalLine);
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := 'DEFAULT';
        GenJournalLine."Journal Template Name" := 'GENERAL';
        GenJournalLine."Posting Date" := dateFilter;
        GenJournalLine."Document Date" := dateFilter;
        GenJournalLine."VAT Reporting Date" := dateFilter;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Source Code" := 'GENJNL';
        GenJournalLine."VAT %" := 0;
        GenJournalLine."Document No." := NoSeriesMgt.GetNextNo(JounalTemplate."No. Series", WorkDate(), true);

        NoOfLines += 10000;
        GenJournalLine."Line No." := NoOfLines;
        GenJournalLine."Account No." := '641815';
        GenJournalLine.Amount := Round(TotalVoucherAmounr, 1);
        GenJournalLine."Amount (LCY)" := Round(TotalVoucherAmounr, 1);
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
        GenJournalLine."Bal. Account No." := '1310';
        GenJournalLine.Description := StrSubstNo('Activate Taka voucher %1', tbwpVoucherMaintenance."Reason Code");
        GenJournalLine.Correction := true;
        GenJournalLine.Insert();

        GenJnlPostBatch.Run(GenJournalLine);

        MarkProcessed(tbwpVoucherMaintenance.ID, dateFilter);
    end;

    local procedure MarkProcessed(VoucherID: Code[20]; dateFilter: Date)
    var
        tbPosDataEntry: Record "LSC POS Data Entry Type";
        tbPOSDataEntryLine: Record "LSC POS Data Entry";
    begin
        tbPosDataEntry.Reset();
        tbPosDataEntry.SetRange("Enable/ Activate Taka Voucher", true);

        if tbPosDataEntry.FindSet() then
            repeat
                tbPOSDataEntryLine.Reset();
                tbPOSDataEntryLine.SetRange("Entry Type", tbPosDataEntry.Code);
                tbPOSDataEntryLine.SetRange("Status", tbPOSDataEntryLine.Status::Active);
                tbPOSDataEntryLine.SetRange("Document No.", VoucherID);
                tbPOSDataEntryLine.SetRange("Date Actived", dateFilter);
                tbPOSDataEntryLine.SetRange("Date Procesed", 0D);

                if tbPOSDataEntryLine.FindSet(true) then
                    repeat
                        tbPOSDataEntryLine."Date Procesed" := dateFilter;
                        tbPOSDataEntryLine.Modify(true);
                    until tbPOSDataEntryLine.Next() = 0;
            until tbPosDataEntry.Next() = 0;
    end;
}