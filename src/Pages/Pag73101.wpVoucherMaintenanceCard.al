namespace worldpos.Voucher.Document;

using worldpos.Voucher.Configuration;

page 73101 wpVoucherMaintenanceCard

{




    AdditionalSearchTerms = 'wp,voucher,taka,maintenance,setup';
    Caption = 'Voucher Maintenance Setup';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = wpVoucherMaintenance;
    SourceTableView = sorting(ID);
    DataCaptionFields = ID;
    PromotedActionCategories = 'New,Process,Reports,Navigate';





    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Voucher ID';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update(false);
                        SetEditable();

                    end;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Importance = Promoted;
                    Editable = IsPageEditable;
                }

                group(Period)
                {
                    field("Validation Period ID"; Rec."Validation Period ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ShowMandatory = true;
                        Editable = IsPageEditable;

                        trigger OnValidate()
                        begin
                            Rec.CalcFields("Starting Date", "Ending Date");
                        end;
                    }

                    field("Validation Description"; Rec."Validation Description")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                    }

                    field("Starting Date"; Rec."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                    }

                    field("Ending Date"; Rec."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                    }
                }

                field("Tender Type Code"; Rec."Tender Type Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPageEditable;
                }

                field("Tender Type Description"; Rec."Tender Type Description")
                {
                    ApplicationArea = Basic, Suite;
                }

                field("Voucher Budget ID"; Rec."VoucherBudgetID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPageEditable;
                }

                field("Enable Tracking"; Rec."Enable Tracking")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tracking Required';
                    Editable = IsPageEditable;
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    Editable = false;
                }
            }

            part(wpVoucherMember; wpVoucherMember)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Member Setup';
                SubPageLink = "Voucher ID" = field(ID);
                UpdatePropagation = Both;
                Editable = IsPageEditable;
            }

            part(wpVoucheritemdiscstp; wpVoucheritemdiscstp)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Setup';
                SubPageLink = "Voucher ID" = field(ID);
                UpdatePropagation = Both;
                Editable = IsPageEditable;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EnableVoucher)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enable';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;

                Enabled = not Rec.Enabled;

                trigger OnAction()
                begin
                    if Rec.Enabled then
                        exit;

                    Rec.Enabled := true;
                    Rec.Modify(true);

                    SetEditable();
                    CurrPage.Update(false);
                end;
            }

            action(DisableVoucher)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Disable';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;

                Enabled = Rec.Enabled;

                trigger OnAction()
                begin
                    if not Rec.Enabled then
                        exit;

                    Rec.Enabled := false;
                    Rec.Modify(true);

                    SetEditable();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(MSRPrefixSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'LSC Voucher Entries';
                Image = CreditCard;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "LSC Voucher Entries";
            }
        }
    }

    var
        IsPageEditable: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditable();
    end;

    trigger OnOpenPage()
    begin
        SetEditable();
    end;

    local procedure SetEditable()
    begin
        IsPageEditable := not Rec.Enabled;
        CurrPage.Editable(IsPageEditable);
    end;

}