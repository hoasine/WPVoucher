page 73108 "Voucher Budget Buffer"
{
    PageType = ListPart;
    SourceTable = wpVoucherMaintenance;
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; }
                field("Total value"; Rec."Total value") { ApplicationArea = All; }
            }
        }
    }

    procedure SetTempData(var TempBudget: Record wpVoucherMaintenance temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if TempBudget.FindSet() then
            repeat
                Rec := TempBudget;
                Rec.Insert();
            until TempBudget.Next() = 0;

        CurrPage.Update(false);
    end;
}
