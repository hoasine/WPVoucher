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
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        JsonBody: JsonObject;
        JsonVoucherArray: JsonArray;
        JsonVoucherItem: JsonObject;
        JsonToken: JsonToken;
        ResponseCode: Integer;
        BodyText: Text;
        ApiKey: Text;
        BaseUrl: Text;
        CustomerPhone: Text;
        RequestJson: Text;
    begin
        if Transaction."Transaction No." = 0 then
            exit;
        if Transaction."Sale Is Return Sale" then
            exit;

        Clear(InfocodeEntry);
        InfocodeEntry.SetRange("Store No.", Transaction."Store No.");
        InfocodeEntry.SetRange("POS Terminal No.", Transaction."POS Terminal No.");
        InfocodeEntry.SetRange("Transaction No.", Transaction."Transaction No.");
        InfocodeEntry.SetRange("Infocode", 'TEXT');
        InfocodeEntry.SetFilter(Information, '<>%1', '');
        Clear(InfocodeEntry);
        InfocodeEntry.SetRange("Store No.", Transaction."Store No.");
        InfocodeEntry.SetRange("POS Terminal No.", Transaction."POS Terminal No.");
        InfocodeEntry.SetRange("Transaction No.", Transaction."Transaction No.");


        if not InfocodeEntry.FindSet() then
            exit;

        Clear(JsonVoucherArray);
        repeat
            if InfocodeEntry.Infocode = 'VOUCHERIN' then begin
                if InfocodeEntry.Information <> '' then begin
                    Clear(JsonVoucherItem);
                    JsonVoucherItem.Add('partnerVoucherCode', InfocodeEntry.Information);
                    JsonVoucherArray.Add(JsonVoucherItem);
                end;
            end;
        until InfocodeEntry.Next() = 0;
        if JsonVoucherArray.Count() = 0 then
            exit;
        CustomerPhone := '';
        if Transaction."Member Card No." <> '' then begin
            Clear(MembershipCard);
            if MembershipCard.Get(Transaction."Member Card No.") then
                CustomerPhone := MembershipCard."Contact No.";
        end;

        if CustomerPhone = '' then
            exit;

        BaseUrl := 'http://192.160.1.153:3508';

        Clear(JsonBody);
        JsonBody.Add('customerPhone', CustomerPhone);
        JsonBody.Add('vouchers', JsonVoucherArray);
        JsonBody.WriteTo(RequestJson);

        HttpContent.WriteFrom(RequestJson);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/json');

        if not HttpClient.Post(BaseUrl + '/api/teko/vouchers/use', HttpContent, HttpResponse) then begin
            Message('Teko API: Network error when sending voucher for Txn %1', Transaction."Transaction No.");
            exit;
        end;


        Clear(JsonBody);
        if JsonBody.ReadFrom(BodyText) then begin
            if JsonBody.Get('code', JsonToken) then
                ResponseCode := JsonToken.AsValue().AsInteger();

            if ResponseCode = 0 then begin
            end else begin

                Message('Teko Voucher Error [%1]: %2', ResponseCode, BodyText);
            end;
        end;
    end;
}