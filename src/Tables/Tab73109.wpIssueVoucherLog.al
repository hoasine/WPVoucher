namespace worldpos.Voucher.Configuration;

using worldpos.Voucher.Document;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Document;
table 73109 "wpIssueVoucherLog"
{
    Caption = 'Issue Voucher Log';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Voucher ID"; Code[20])
        {
            Caption = 'Voucher ID';
            TableRelation = wpVoucherMaintenance.ID;
        }

        field(2; "Member Card"; Code[20])
        {
            Caption = 'Member Card';
            TableRelation = "LSC Membership Card"."Card No.";
        }
        field(3; "Receipt Applied"; Text[500])
        {
            Caption = 'Receipt Scanned';
        }
        field(4; "Voucher Applied"; Text[200])
        {
            Caption = 'Voucher Redeempted';
        }
        field(5; "Applied Date"; Date)
        {
            Caption = 'Applied Date';
        }
        field(9; "Replication Counter"; Integer)
        {
            Caption = 'Replication Counter';
            Editable = false;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                voucherLog: Record "wpIssueVoucherLog";
            begin
                if not ClientSessionUtility.UpdateReplicationCountersForTable(RecordId, "Replication Counter") then
                    exit;
                voucherLog.SetCurrentKey("Replication Counter");
                if voucherLog.FindLast then
                    "Replication Counter" := voucherLog."Replication Counter" + 1
                else
                    "Replication Counter" := 1;
            end;
        }
    }
    keys
    {
        key(PK; "Replication Counter")
        {
            Clustered = true;
        }
    }

    var
        ClientSessionUtility: Codeunit "LSC Client Session Utility";


}
