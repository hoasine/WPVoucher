namespace worldpos.Voucher.Configuration;

using Microsoft.Inventory.Item;
using worldpos.Voucher.Configuration;

table 70013 wpVoucheritemdiscstp
{
    Caption = 'Voucher Item Discount Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Voucher ID"; Code[20])
        {
            Caption = 'Voucher ID';
            TableRelation = wpVoucherMaintenance.ID;
        }
        field(2; "Type"; Enum wpItemDiscType)
        {
            Caption = 'Type';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = If (Type = const(Division)) "LSC Division".Code
            else
            If (Type = const("Item Category")) "Item Category".Code
            else
            If (Type = const("Retail Product Group")) "LSC Retail Product Group".Code
            else
            If (Type = const("Special Group")) "LSC Item Special Groups".Code
            else
            if (Type = const(Item)) Item."No.";

            trigger OnValidate()
            var
                lDivision: Record "LSC Division";
                lItemCategory: Record "Item Category";
                lRetailProductGroup: Record "LSC Retail Product Group";
                lSpecialGroup: Record "LSC Item Special Groups";
                lItem: Record Item;
            begin
                Rec.Description := '';
                case Type of
                    Type::Division:
                        begin
                            lDivision.Reset();
                            lDivision.SetRange("Code", "No.");
                            if lDivision.FindFirst() then
                                Rec.Description := lDivision.Description;
                        end;
                    Type::"Item Category":
                        begin
                            lItemCategory.Reset();
                            lItemCategory.SetRange("Code", "No.");
                            if lItemCategory.FindFirst() then
                                Rec.Description := lItemCategory.Description;
                        end;
                    Type::"Retail Product Group":
                        begin
                            lRetailProductGroup.Reset();
                            lRetailProductGroup.SetRange("Code", "No.");
                            if lRetailProductGroup.FindFirst() then
                                Rec.Description := lRetailProductGroup.Description;
                        end;
                    Type::"Special Group":
                        begin
                            lSpecialGroup.Reset();
                            lSpecialGroup.SetRange("Code", "No.");
                            if lSpecialGroup.FindFirst() then
                                Rec.Description := lSpecialGroup.Description;
                        end;
                    Type::Item:
                        begin
                            lItem.Reset();
                            lItem.SetRange("No.", "No.");
                            if lItem.FindFirst() then
                                Rec.Description := lItem.Description;
                        end;
                end;
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(5; Exclude; Boolean)
        {
            Caption = 'Exclude';
        }
    }
    keys
    {
        key(PK; "Voucher ID", Type, "No.")
        {
            Clustered = true;
        }
    }
}
