// namespace worldpos.Voucher.Configuration;

// using Microsoft.Purchases.Vendor;

// table 73102 wpVoucherVendor
// {
//     Caption = 'Voucher Vendor';
//     DataClassification = ToBeClassified;

//     fields
//     {
//         field(1; "Voucher ID"; Code[20])
//         {
//             Caption = 'Voucher ID';
//             TableRelation = wpVoucherMaintenance.ID;
//         }
//         field(10; "Vendor No."; Code[20])
//         {
//             Caption = 'Vendor No.';
//             TableRelation = Vendor."No.";
//         }
//         field(11; "Vendor Name"; Text[100])
//         {
//             Caption = 'Name';
//             FieldClass = FlowField;
//             CalcFormula = lookup(Vendor."Name" where("No." = field("Vendor No.")));
//         }
//         field(20; Description; Text[30])
//         {
//             Caption = 'Description';
//         }
//         field(21; Exclude; Boolean)
//         {
//             Caption = 'Exclude';
//         }
//     }
//     keys
//     {
//         key(PK; "Voucher ID", "Vendor No.")
//         {
//             Clustered = true;
//         }
//     }
// }
