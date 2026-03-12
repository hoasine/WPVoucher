codeunit 73100 VoucherBudgetBuffer
{
    var
        TempBudget: Record wpVoucherMaintenance temporary;

    procedure AddIfNotExists(BudgetID: Code[20])
    var
        Budget: Record wpVoucherMaintenance;
    begin
        if BudgetID = '' then
            exit;

        TempBudget.Reset();
        TempBudget.SetRange(ID, BudgetID);
        if TempBudget.FindFirst() then
            exit;

        if not Budget.Get(BudgetID) then
            exit;

        TempBudget.Init();
        TempBudget.TransferFields(Budget);
        TempBudget.Insert();
    end;

    procedure CopyTo(var Target: Record wpVoucherMaintenance temporary)
    begin
        Target.DeleteAll();
        Target.Copy(TempBudget, true);
    end;

    procedure Clear()
    begin
        TempBudget.DeleteAll();
    end;
}
