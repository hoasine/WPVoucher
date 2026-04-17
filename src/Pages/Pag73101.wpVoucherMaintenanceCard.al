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
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
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
                            CurrPage.Update();
                        end;
                    }

                    field("Validation Description"; Rec."Validation Description")
                    {
                        ApplicationArea = Basic, Suite;
                    }

                    field("Starting Date"; Rec."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                    }

                    field("Ending Date"; Rec."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
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
                field("Reason Code"; Rec."Reason Code")
                {
                    Caption = 'Ref to GL';
                    ApplicationArea = Basic, Suite;
                    Editable = IsPageEditable;
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
                Caption = 'Enable';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;

                Enabled = EnableButtonVisible;

                trigger OnAction()
                begin
                    Rec.CalcFields("Starting Date", "Ending Date");

                    if (Rec."Ending Date" <> 0D) and (Rec."Ending Date" < Today) then begin
                        Message('This voucher has already expired and cannot be enabled.');
                        exit;
                    end;

                    if (Rec."Reason Code" = '') then begin
                        Message('Please choose Ref to GL.');
                        exit;
                    end;

                    if Rec.ID = '' then
                        Error('Invalid data. Please check again!');

                    Rec.Enabled := true;
                    Rec.Modify(true);
                    CurrPage.Update(true);
                end;
            }

            action(DisableVoucher)
            {
                Caption = 'Disable';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;

                Enabled = DisableButtonVisible;

                trigger OnAction()
                begin
                    Rec.Enabled := false;
                    Rec.Modify(true);
                    CurrPage.Update(true);
                end;
            }
        }

        area(Navigation)
        {
            action(MSRPrefixSetup)
            {
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
        EnableButtonVisible: Boolean;
        DisableButtonVisible: Boolean;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Starting Date", "Ending Date");

        if Rec.Enabled and (Rec."Ending Date" <> 0D) and (Rec."Ending Date" < Today) then begin
            Rec.Enabled := false;
            Rec.Modify(false);
        end;

        if Rec.Enabled then begin
            CurrPage.Editable := false;
            IsPageEditable := false;
        end else begin
            CurrPage.Editable := true;
            IsPageEditable := true;
        end;

        EnableButtonVisible := not Rec.Enabled;
        DisableButtonVisible := Rec.Enabled;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Update();

        //Tạo mới
        if Rec.ID = '' then begin
            CurrPage.Editable := true;
            IsPageEditable := true;

            EnableButtonVisible := true;
            DisableButtonVisible := false;
        end;
    end;


}