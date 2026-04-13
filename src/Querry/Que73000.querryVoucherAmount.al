query 73000 "querryVoucherAmount"
{
    elements
    {
        dataitem(posDataEntry; "LSC POS Data Entry")
        {
            DataItemTableFilter = Status = const(3);

            filter(documentFilter; "Document No.")
            {
            }
            filter(dateFilter; "Date Applied")
            {
            }
            dataitem(voucherEntry; "LSC Voucher Entries")
            {
                DataItemLink = "Voucher No." = posDataEntry."Entry Code";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = "Entry Type" = filter('=Redemption');

                column(amountWriteOff; "Write Off Amount")
                {
                    Method = Sum;
                    ReverseSign = true;
                }
            }
        }
    }
}

