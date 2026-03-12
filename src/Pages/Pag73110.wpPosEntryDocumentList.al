page 73110 "POS Entry Document List"
{
    PageType = List;
    SourceTable = "POS Entry Document Buffer";
    ApplicationArea = All;
    Caption = 'Select Document';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }

                field("Total Voucher"; Rec."Total Voucher")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure LoadData(var TempDocBuffer: Record "POS Entry Document Buffer" temporary)
    begin
        Rec.Copy(TempDocBuffer, true);
    end;
}