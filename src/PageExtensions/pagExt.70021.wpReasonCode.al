pageextension 70021 wpReasonCode extends "Reason Codes"
{
    layout
    {
        addafter("Code")
        {
            field("Account No."; Rec."Account No.")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Bal. Account No."; Rec."Bal. Account No.")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}