codeunit 70015 "Teko Voucher Integration"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Print Utility", 'OnBeforePrintSalesSlip', '', false, false)]
    local procedure OnBeforePrintSalesSlipTekoVoucher(
    var Transaction: Record "LSC Transaction Header";
    var PrintBuffer: Record "LSC POS Print Buffer";
    var PrintBufferIndex: Integer;
    var LinesPrinted: Integer;
    var IsHandled: Boolean;
    var ReturnValue: Boolean)
    var
        InfocodeEntry: Record "LSC Trans. Infocode Entry";
        MembershipCard: Record "LSC Membership Card";
        MemberContact: Record "LSC Member Contact";
        RetailSetup: Record "LSC Retail Setup";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        JsonBody: JsonObject;
        JsonVoucherArray: JsonArray;
        JsonVoucherItem: JsonObject;
        BaseUrl: Text;
        CustomerPhone: Text;
        RequestJson: Text;
        RequestId: Text;
        TransDateTime: DateTime;
        EpochDateTime: DateTime;
        DurationMs: BigInteger;
        UsedAtUnix: BigInteger;
        Store: Record "LSC Store";
        POSTerminal: Record "LSC POS Terminal";
        IsTempMember: Boolean;
    begin
        if Transaction."Transaction No." = 0 then
            exit;
        if Transaction."Sale Is Return Sale" then
            exit;

        Clear(InfocodeEntry);
        InfocodeEntry.SetRange("Store No.", Transaction."Store No.");
        InfocodeEntry.SetRange("POS Terminal No.", Transaction."POS Terminal No.");
        InfocodeEntry.SetRange("Transaction No.", Transaction."Transaction No.");
        InfocodeEntry.SetRange(Infocode, 'VOUCHERIN');

        if not InfocodeEntry.FindSet() then
            exit; // Không dùng voucher -> Bỏ qua
        TransDateTime := CreateDateTime(Transaction."Date", Transaction."Time");
        // Chuyển đổi từ giờ VN (UTC+7) sang UTC theo chuẩn Teko
        TransDateTime := TransDateTime - (7 * 60 * 60 * 1000);

        EpochDateTime := CreateDateTime(19700101D, 000000T);
        DurationMs := TransDateTime - EpochDateTime;
        UsedAtUnix := DurationMs DIV 1000;

        Clear(JsonVoucherArray);
        repeat
            if InfocodeEntry.Information <> '' then begin
                Clear(JsonVoucherItem);
                JsonVoucherItem.Add('partnerVoucherId', InfocodeEntry.Information);
                JsonVoucherItem.Add('usedAt', UsedAtUnix);
                JsonVoucherArray.Add(JsonVoucherItem);
            end;
        until InfocodeEntry.Next() = 0;

        if JsonVoucherArray.Count() = 0 then
            exit;

        CustomerPhone := '';
        IsTempMember := false;

        // Kiểm tra xem đây có phải là thẻ Thành Viên Tạm Thời không
        if Transaction."Member Card No." <> '' then begin
            if RetailSetup.Get() then begin
                // So sánh thẻ trên receipt với Retail Setup
                if (RetailSetup."Temp. Member Def. Card No." <> '') and (Transaction."Member Card No." = RetailSetup."Temp. Member Def. Card No.") then
                    IsTempMember := true;
            end;
        end;

        if IsTempMember then begin
            // Trường hợp 1: Temp Member
            CustomerPhone := '1111111111';
        end else if Transaction."Member Card No." = '' then begin
            // Trường hợp 2: No Member
            CustomerPhone := '1111111111';
        end else begin
            // Trường hợp 3: Happy Case
            Clear(MembershipCard);
            if MembershipCard.Get(Transaction."Member Card No.") then begin
                if MembershipCard."Account No." <> '' then begin
                    Clear(MemberContact);
                    MemberContact.SetCurrentKey("Account No.");
                    MemberContact.SetRange("Account No.", MembershipCard."Account No.");

                    if MemberContact.FindFirst() then
                        CustomerPhone := DelChr(MemberContact."Mobile Phone No.", '=', ' ');
                end;
            end;

            // Phòng nếu là thẻ thật nhưng thông tin liên hệ bị trống số điện thoại
            if CustomerPhone = '' then
                CustomerPhone := '1111111111';
        end;

        RequestId := Transaction."Store No." + '-' + Transaction."POS Terminal No." + '-' + Format(Transaction."Transaction No.");

        if not POSTerminal.Get(POSSESSION.TerminalNo) then
            Error('POS Terminal %1 not found.', POSSESSION.TerminalNo);

        if not Store.Get(POSTerminal."Store No.") then
            Error('Store %1 not found.', POSTerminal."Store No.");

        BaseUrl := Store."Voucher Service URL";
        if BaseUrl = '' then
            exit;

        if (not BaseUrl.StartsWith('http://')) and (not BaseUrl.StartsWith('https://')) then
            BaseUrl := 'http://' + BaseUrl;

        Clear(JsonBody);
        JsonBody.Add('requestId', RequestId);
        JsonBody.Add('customerPhone', CustomerPhone);
        JsonBody.Add('vouchers', JsonVoucherArray);
        JsonBody.WriteTo(RequestJson);

        HttpContent.WriteFrom(RequestJson);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/json');

        if not HttpClient.Post(BaseUrl + '/api/teko/vouchers/use', HttpContent, HttpResponse) then begin
        end;
    end;

    var
        POSSESSION: Codeunit "LSC POS Session";
}