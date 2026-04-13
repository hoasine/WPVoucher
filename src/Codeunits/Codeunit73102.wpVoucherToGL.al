
codeunit 73102 wpVoucherToGL
{
    trigger OnRun()

    begin
        UpdateVoucherToGLJournal();
    end;

    procedure UpdateVoucherToGLJournal()
    var
        tbSalesReceivables: Record "Sales & Receivables Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        JounalTemplate: Record "Gen. Journal Template";
        NoOfLines: Integer;
        TotalVoucherAmounr: Decimal;
        tbStore: Record "LSC Store";
        tbPosDataEntry: Record "LSC POS Data Entry Type";
        tbVoucherEntry: Record "LSC POS Data Entry";
        dateFilter: Date;
    begin
        IF tbSalesReceivables.Get() then begin
            if tbSalesReceivables."Voucher GL Date" <> 0D then begin
                dateFilter := tbSalesReceivables."Voucher GL Date";
            end else
                dateFilter := Today;
        end;

        clear(NoOfLines);
        Clear(TotalVoucherAmounr);
        TotalVoucherAmounr := 0;

        Clear(tbPosDataEntry);
        tbPosDataEntry.SetRange("Enable/ Activate Taka Voucher", true);
        if tbPosDataEntry.findset then BEGIN
            repeat
                Clear(tbVoucherEntry);
                tbVoucherEntry.SetRange("Entry Type", tbPosDataEntry.Code);
                tbVoucherEntry.SetRange("Status", tbVoucherEntry.Status::Active);
                tbVoucherEntry.CalcSums(Amount);
                TotalVoucherAmounr += tbVoucherEntry.Amount;
            until tbPosDataEntry.Next() = 0;
        END;

        if not JounalTemplate.get('GENERAL') then begin
            Message('Not found No Serial. GENERAL');
            exit;
        end;

        GenJournalLine.setrange("Journal Template Name", 'GENERAL');
        GenJournalLine.setrange("Journal Batch Name", 'DEFAULT');
        if GenJournalLine.findlast then
            NoOfLines := GenJournalLine."Line No."
        else
            NoOfLines := 10000;

        Clear(GenJournalLine);
        GenJournalLine."Journal Batch Name" := 'DEFAULT';
        GenJournalLine."Journal Template Name" := 'GENERAL';
        GenJournalLine."Posting Date" := dateFilter;
        GenJournalLine."Document Date" := dateFilter;
        GenJournalLine."VAT Reporting Date" := dateFilter;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Source Code" := 'GENJNL';
        GenJournalLine."VAT %" := 0;

        IF TotalVoucherAmounr <> 0 then begin
            GenJournalLine."Document No." := NoSeriesMgt.GetNextNo(JounalTemplate."No. Series", WorkDate, true);

            NoOfLines += 10000;
            GenJournalLine."Line No." := NoOfLines;
            GenJournalLine."Account No." := '641815';
            GenJournalLine.Amount := Round(TotalVoucherAmounr, 1);
            GenJournalLine."Amount (LCY)" := Round(TotalVoucherAmounr, 1);
            GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
            GenJournalLine."Bal. Account No." := '1310';
            GenJournalLine.Description := 'Activate Taka voucher';
            GenJournalLine.Correction := true;
            GenJournalLine.Insert();
        end;

        if NoOfLines > 0 then begin
            Clear(GenJournalLine);
            GenJournalLine.setrange("Journal Template Name", 'GENERAL');
            GenJournalLine.setrange("Journal Batch Name", 'DEFAULT');
            GenJournalLine.SetRange("Posting Date", dateFilter);
            GenJournalLine.SetFilter("Description", '%1', 'Activate Taka voucher');
            if GenJournalLine.findset then BEGIN
                repeat
                    Clear(GenJnlPostBatch);
                    GenJnlPostBatch.Run(GenJournalLine);
                    Commit;
                until GenJournalLine.Next() = 0;
            END;
        end;
    end;
}
