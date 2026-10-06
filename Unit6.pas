unit Unit6;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Generics.Collections,
  System.DateUtils, System.JSON, System.Math, System.Net.HttpClientComponent,
  System.Net.HttpClient, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls;

type
  TNotificationEntry = class
  public
    Title: string;
    Message: string;
    TypeName: string;
    Timestamp: TDateTime;
    EventKey: string;
    constructor Create(const ATitle, AMessage, ATypeName, AEventKey: string; ATimestamp: TDateTime);
  end;

  TCleaningEvent = record
    EventKey: string;
    Timestamp: TDateTime;

    Status: Integer;
    CleaningTime: Integer;
    CleanedArea: Double;

    CleaningMode: Integer;
    Completed: Boolean;
  end;

  TForm6 = class(TForm)
    ListView1: TListView;
    Button1: TButton;
    Button2: TButton;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    FItems: TObjectList<TNotificationEntry>;

    procedure AddNotification(const ATitle, AMessage, ATypeName, AEventKey: string; ATimestamp: TDateTime);
    procedure RefreshList;
    procedure SyncNotificationsFromCloud;
    function CloudPost(const AEndpoint: string; const ABody: string; out AResponse: string): Boolean;
    function GetJsonString(Obj: TJSONObject; const AName: string; const ADefault: string = ''): string;
    function GetJsonInt(Obj: TJSONObject; const AName: string; const ADefault: Integer = 0): Integer;
    function GetJsonInt64(Obj: TJSONObject; const AName: string; const ADefault: Int64 = 0): Int64;
    function GetJsonFloat(Obj: TJSONObject; const AName: string; const ADefault: Double = 0): Double;
    function UnixToDateTimeSafe(AUnix: Int64): TDateTime;
    function ExtractHistoryArray(AValue: TJSONValue): TJSONArray;
    function ParseHistoryRecord(ARecord: TJSONObject; out AEvent: TCleaningEvent): Boolean;
    function EventAlreadyExists(const AEventKey: string): Boolean;
    function ResolveCloudUid(const ADid: string): string;
    function EscapeJson(const S: string): string;
    function CleaningStatusText(AStatus: Integer): string;
    function CleaningModeText(AMode: Integer): string;
    function FormatCleaningDuration(AMinutes: Integer): string;
    function FormatArea(AArea: Double): string;
    procedure AddCleaningEventNotification(const AEvent: TCleaningEvent);
    procedure AddErrorNotification(const AMessage: string);

  public
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

uses
  Unit1;

const
  DREAME_EVENT_ENDPOINT = '/dreame-user-iot/iotuserdata/getDeviceData';
  DREAME_DEVICE_LIST_ENDPOINT = '/dreame-user-iot/iotuserbind/device/listV2';
  DREAME_HISTORY_LIMIT = 50;
  DREAME_HISTORY_DAYS = 180;
  DREAME_STATUS_SIID = 4;
  DREAME_STATUS_EIID = 1;
  DREAME_PIID_STATUS           = 1;
  DREAME_PIID_CLEANING_TIME    = 2;
  DREAME_PIID_CLEANED_AREA     = 3;
  DREAME_PIID_TASK_STATUS      = 7;
  DREAME_PIID_CLEANING_START   = 8;
  DREAME_PIID_CLEAN_LOG_STATUS = 13;
  DREAME_PIID_CLEANING_MODE    = 23;
  DREAME_DATA_VERSION = 3;


constructor TNotificationEntry.Create(const ATitle, AMessage, ATypeName, AEventKey: string; ATimestamp: TDateTime);
begin
  inherited Create;
  Title := ATitle;
  Message := AMessage;
  TypeName := ATypeName;
  EventKey := AEventKey;

  if ATimestamp > 0 then
    Timestamp := ATimestamp
  else
    Timestamp := Now;
end;

procedure TForm6.FormCreate(Sender: TObject);
begin
  FItems := TObjectList<TNotificationEntry>.Create(True);
  ListView1.ViewStyle := vsReport;
  ListView1.Columns.Clear;

  with ListView1.Columns.Add do
  begin
    Caption := 'Typ';
    Width := 90;
  end;

  with ListView1.Columns.Add do
  begin
    Caption := 'Tytuł';
    Width := 140;
  end;

  with ListView1.Columns.Add do
  begin
    Caption := 'Wiadomość';
    Width := 330;
  end;

  with ListView1.Columns.Add do
  begin
    Caption := 'Czas';
    Width := 150;
  end;
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  SyncNotificationsFromCloud;
  RefreshList;
end;

function TForm6.EscapeJson(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
end;

procedure TForm6.AddNotification(const ATitle, AMessage, ATypeName, AEventKey: string; ATimestamp: TDateTime);
var
  Item: TNotificationEntry;
begin
  if AEventKey <> '' then
  begin
    if EventAlreadyExists(AEventKey) then Exit;
  end;

  Item := TNotificationEntry.Create(ATitle, AMessage, ATypeName, AEventKey, ATimestamp);
  FItems.Add(Item);
end;

function TForm6.EventAlreadyExists(const AEventKey: string): Boolean;
var
  I: Integer;
begin
  Result := False;

  if AEventKey = '' then Exit;

  for I := 0 to FItems.Count - 1 do
  begin
    if SameText(FItems[I].EventKey, AEventKey) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TForm6.CloudPost(const AEndpoint: string; const ABody: string; out AResponse: string): Boolean;
var
  HTTP: TNetHTTPClient;
  Response: IHTTPResponse;
  RequestBody: TStringStream;
  URL: string;
begin
  Result := False;
  AResponse := '';

  HTTP := TNetHTTPClient.Create(nil);
  RequestBody := TStringStream.Create(ABody, TEncoding.UTF8);

  try
    HTTP.ConnectionTimeout := 10000;
    HTTP.ResponseTimeout := 15000;
    HTTP.CustomHeaders['Content-Type'] := 'application/json';
    HTTP.CustomHeaders['User-Agent'] := Form1.USER_AGENT;
    HTTP.CustomHeaders['Authorization'] := Form1.AUTH_HEADER;
    HTTP.CustomHeaders['Tenant-Id'] := Form1.FTenantId;
    HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + Form1.FKeyToken;

    URL := Form1.GetBaseUrl(Form1.ComboBox2.Text) + AEndpoint;
    Response := HTTP.Post(URL, RequestBody);

    if Response = nil then Exit;
    AResponse := Response.ContentAsString;

    if Response.StatusCode <> 200 then Exit;
    Result := True;

  except
    on E: Exception do
    begin
      AResponse := 'HTTP ERROR: ' + E.Message;
      Result := False;
    end;
  end;

  RequestBody.Free;
  HTTP.Free;
end;

function TForm6.GetJsonString(Obj: TJSONObject; const AName: string; const ADefault: string): string;
var
  V: TJSONValue;
begin
  Result := ADefault;
  if Obj = nil then Exit;

  V := Obj.GetValue(AName);
  if V <> nil then Result := V.Value;
end;

function TForm6.GetJsonInt(Obj: TJSONObject; const AName: string; const ADefault: Integer): Integer;
var
  V: TJSONValue;
begin
  Result := ADefault;

  if Obj = nil then Exit;
  V := Obj.GetValue(AName);

  if V = nil then Exit;
  Result := StrToIntDef(V.Value, ADefault);
end;

function TForm6.GetJsonInt64(Obj: TJSONObject; const AName: string; const ADefault: Int64): Int64;
var
  V: TJSONValue;
begin
  Result := ADefault;

  if Obj = nil then Exit;
  V := Obj.GetValue(AName);

  if V = nil then Exit;
  Result := StrToInt64Def(V.Value, ADefault);
end;

function TForm6.GetJsonFloat(Obj: TJSONObject; const AName: string; const ADefault: Double): Double;
var
  V: TJSONValue;
  S: string;
begin
  Result := ADefault;
  if Obj = nil then Exit;

  V := Obj.GetValue(AName);
  if V = nil then Exit;

  S := V.Value;
  S := StringReplace(S, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);

  try
    Result := StrToFloat(S);
  except
    Result := ADefault;
  end;
end;


function TForm6.UnixToDateTimeSafe(AUnix: Int64): TDateTime;
begin
  Result := 0;
  if AUnix <= 0 then Exit;

  try
    Result := UnixToDateTime(AUnix, False);
  except
    Result := 0;
  end;
end;

function TForm6.ResolveCloudUid(const ADid: string): string;
var
  ResponseText: string;
  Body: string;
  Root: TJSONObject;
  DataObj: TJSONObject;
  PageObj: TJSONObject;
  Records: TJSONArray;
  I: Integer;
  DeviceObj: TJSONObject;
  V: TJSONValue;
  DidValue: string;
begin
  Result := '';
  if not Form1.FUserId.IsEmpty then
  begin
    Result := Form1.FUserId;
    Exit;
  end;

  Body := '{}';

  if not CloudPost(DREAME_DEVICE_LIST_ENDPOINT, Body, ResponseText) then Exit;
  Root := TJSONObject.ParseJSONValue(ResponseText) as TJSONObject;
  if Root = nil then Exit;

  try
    DataObj := Root.GetValue('data') as TJSONObject;
    if DataObj = nil then Exit;

    PageObj := DataObj.GetValue('page') as TJSONObject;
    if PageObj = nil then Exit;

    Records := PageObj.GetValue('records') as TJSONArray;
    if Records = nil then Exit;

    for I := 0 to Records.Count - 1 do
    begin
      if not (Records.Items[I] is TJSONObject) then Continue;
      DeviceObj := Records.Items[I] as TJSONObject;
      DidValue := GetJsonString(DeviceObj, 'did', '');

      if (ADid <> '') and (not SameText(DidValue, ADid)) then Continue;
      V := DeviceObj.GetValue('uid');

      if (V <> nil) and (V.Value <> '') then
      begin
        Result := V.Value;
        Exit;
      end;

      V := DeviceObj.GetValue('masterUid');

      if (V <> nil) and (V.Value <> '') then
      begin
        Result := V.Value;
        Exit;
      end;

      V := DeviceObj.GetValue('deviceInfo');

      if V is TJSONObject then
      begin
        V := TJSONObject(V).GetValue('uid');

        if (V <> nil) and (V.Value <> '') then
        begin
          Result := V.Value;
          Exit;
        end;

        V := TJSONObject(DeviceObj.GetValue('deviceInfo')).GetValue('masterUid');

        if
          (V <> nil) and (V.Value <> '') then
        begin
          Result := V.Value;
          Exit;
        end;
      end;
    end;

  finally
    Root.Free;
  end;
end;

function TForm6.ExtractHistoryArray(AValue: TJSONValue): TJSONArray;
var
  Obj: TJSONObject;
  V: TJSONValue;
  S: string;
begin
  Result := nil;
  if AValue = nil then Exit;

  if AValue is TJSONArray then
  begin
    Result := TJSONArray(AValue).Clone as TJSONArray;
    Exit;
  end;

  if AValue is TJSONString then
  begin
    S := AValue.Value;

    try
      Result := TJSONObject.ParseJSONValue(S) as TJSONArray;
    except
      Result := nil;
    end;

    Exit;
  end;

  if AValue is TJSONObject then
  begin
    Obj := AValue as TJSONObject;
    V := Obj.GetValue('history');

    if V = nil then
      V := Obj.GetValue('value');

    if V <> nil then
    begin
      Result := ExtractHistoryArray(V);
      if Result <> nil then Exit;
    end;

    V := Obj.GetValue('data');

    if V <> nil then
      Result := ExtractHistoryArray(V);
  end;
end;

function TForm6.ParseHistoryRecord(ARecord: TJSONObject; out AEvent: TCleaningEvent): Boolean;
var
  V: TJSONValue;
  HistoryArr: TJSONArray;
  I: Integer;
  Item: TJSONObject;
  PIID: Integer;
  Value: TJSONValue;
  S: string;
  UnixTime: Int64;
  FoundTime: Boolean;
begin
  Result := False;

  FillChar(AEvent, SizeOf(AEvent), 0);
  AEvent.Status := -1;
  AEvent.CleaningMode := -1;
  AEvent.Timestamp := 0;

  FoundTime := False;

  if ARecord = nil then Exit;

  V := ARecord.GetValue('history');

  if V = nil then
    V := ARecord.GetValue('value');

  if V = nil then Exit;

  HistoryArr := ExtractHistoryArray(V);
  if HistoryArr = nil then Exit;

  try
    for I := 0 to HistoryArr.Count - 1 do
    begin
      if not (HistoryArr.Items[I] is TJSONObject) then Continue;

      Item := HistoryArr.Items[I] as TJSONObject;
      PIID := GetJsonInt(Item, 'piid', -1);

      Value := Item.GetValue('value');

      if Value = nil then
        Value := Item.GetValue('val');

      if Value = nil then Continue;
      S := Value.Value;

      case PIID of

        DREAME_PIID_STATUS:
          begin
            AEvent.Status := StrToIntDef(S, -1);
          end;

        DREAME_PIID_CLEANING_TIME:
          begin
            AEvent.CleaningTime := StrToIntDef(S, 0);
          end;

        DREAME_PIID_CLEANED_AREA:
          begin
            AEvent.CleanedArea := GetJsonFloat(Item, 'value', 0);
          end;

        DREAME_PIID_TASK_STATUS:
          begin
            // brak
          end;

        DREAME_PIID_CLEANING_START:
          begin
            UnixTime := StrToInt64Def(S, 0);

            if UnixTime > 0 then
            begin
              AEvent.Timestamp := UnixToDateTimeSafe(UnixTime);
              FoundTime := AEvent.Timestamp > 0;
            end;
          end;

        DREAME_PIID_CLEAN_LOG_STATUS:
          begin
            AEvent.Completed := StrToIntDef(S, 0) = 1;
          end;

        DREAME_PIID_CLEANING_MODE:
          begin
            AEvent.CleaningMode := StrToIntDef(S, -1);
          end;
      end;
    end;

    if AEvent.Status < 0 then Exit;

    if not FoundTime then
    begin
      UnixTime := GetJsonInt64(ARecord, 'timestamp', 0);

      if UnixTime = 0 then
        UnixTime := GetJsonInt64(ARecord, 'time', 0);

      if UnixTime = 0 then
        UnixTime := GetJsonInt64(ARecord, 'createTime', 0);

      if UnixTime > 0 then
      begin
        AEvent.Timestamp := UnixToDateTimeSafe(UnixTime);
        FoundTime := AEvent.Timestamp > 0;
      end;
    end;

    if not FoundTime then Exit;

    AEvent.EventKey := Format(
        '%d_%d_%d_%d', [ DateTimeToUnix(AEvent.Timestamp, False),
          AEvent.Status, AEvent.CleaningTime, Round(AEvent.CleanedArea * 10)]);
    Result := True;

  finally
    HistoryArr.Free;
  end;
end;

function TForm6.CleaningStatusText(AStatus: Integer): string;
begin
  case AStatus of
    0:
      Result := 'Sprzątanie zakończone';
    1:
      Result := 'Sprzątanie zakończone';
    2:
      Result := 'Sprzątanie zakończone ręcznie';
    3:
      Result := 'Sprzątanie zakończone błędem';

  else
    Result := 'Zakończenie sprzątania (' + AStatus.ToString + ')';
  end;
end;

function TForm6.CleaningModeText(AMode: Integer): string;
begin
  case AMode of
    0:
      Result := 'Odkurzanie';
    1:
      Result := 'Mopowanie';
    2:
      Result := 'Odkurzanie + mopowanie';
    3:
      Result := 'Mopowanie po odkurzaniu';
  else
    Result := '';
  end;
end;


function TForm6.FormatCleaningDuration(AMinutes: Integer): string;
var
  H: Integer;
  M: Integer;
begin
  Result := '';

  if AMinutes <= 0 then Exit;

  H := AMinutes div 60;
  M := AMinutes mod 60;

  if H > 0 then
    Result := Format('%d godz. %d min.', [H, M])
  else
    Result := Format('%d min.', [M]);
end;

function TForm6.FormatArea(AArea: Double): string;
begin
  if AArea <= 0 then
  begin
    Result := '';
    Exit;
  end;

  Result := FormatFloat('0.0', AArea) + ' m?';
end;

procedure TForm6.AddCleaningEventNotification(const AEvent: TCleaningEvent);
var
  Msg: string;
  DurationText: string;
  AreaText: string;
  ModeText: string;
begin
  Msg := CleaningStatusText(AEvent.Status) + '.';
  DurationText :=FormatCleaningDuration(AEvent.CleaningTime);
  AreaText := FormatArea(AEvent.CleanedArea);
  ModeText := CleaningModeText(AEvent.CleaningMode);

  if DurationText <> '' then
    Msg := Msg + ' Czas: ' + DurationText + '.';

  if AreaText <> '' then
    Msg := Msg + ' Powierzchnia: ' + AreaText + '.';

  if ModeText <> '' then
    Msg := Msg + ' Tryb: ' + ModeText + '.';

  AddNotification(CleaningStatusText(AEvent.Status),
    Msg, 'Sprzątanie', AEvent.EventKey, AEvent.Timestamp);
end;


procedure TForm6.AddErrorNotification(const AMessage: string);
begin
  AddNotification('Błąd', AMessage, 'Błąd', '', Now);
end;

procedure TForm6.SyncNotificationsFromCloud;
var
  HTTPResponse: string;
  Body: string;
  ResponseJSON: TJSONObject;
  DataObj: TJSONObject;
  ResultArr: TJSONArray;
  I: Integer;
  RecordObj: TJSONObject;
  Event: TCleaningEvent;
  UID: string;
  DID: string;
  StartUnix: Int64;
begin
  FItems.Clear;

  if Form1.FKeyToken.IsEmpty then
  begin
    AddErrorNotification('Brak tokenu Dreame Cloud.');
    Exit;
  end;

  DID := Trim(Form1.FSelectedDid);

  if DID.IsEmpty then
  begin
    AddErrorNotification('Brak wybranego DID robota.');
    Exit;
  end;

  UID := ResolveCloudUid(DID);

  if UID.IsEmpty then
  begin
    AddErrorNotification('Dreame Cloud nie zwrócił UID użytkownika.');
    Exit;
  end;

  StartUnix := DateTimeToUnix(IncDay(Now, -DREAME_HISTORY_DAYS), False);

  Body := '{' + '"uid":"' + EscapeJson(UID) + '",' + '"did":"' + EscapeJson(DID) +
      '",' + '"from":' + IntToStr(StartUnix) + ',' +  '"limit":' + IntToStr(DREAME_HISTORY_LIMIT) +
      ',' + '"siid":' + IntToStr(DREAME_STATUS_SIID) + ',' + '"country":"' +
      EscapeJson(Form1.ComboBox2.Text) + '",' + '"ver":' + IntToStr(DREAME_DATA_VERSION) +
      ',' + '"eiid":' + IntToStr(DREAME_STATUS_EIID) + '}';

  Form1.Memo1.Lines.Add('');
  Form1.Memo1.Lines.Add('=== POWIADOMIENIA DREAME ===');
  Form1.Memo1.Lines.Add('UID: ' + UID);
  Form1.Memo1.Lines.Add('DID: ' + DID);
  Form1.Memo1.Lines.Add('REQUEST:');
  Form1.Memo1.Lines.Add(Body);

  if not CloudPost(DREAME_EVENT_ENDPOINT, Body, HTTPResponse) then
  begin
    AddErrorNotification('Nie udało się pobrać historii sprzątania z Dreame Cloud.');
    Form1.Memo1.Lines.Add('HTTP ERROR:');
    Form1.Memo1.Lines.Add(HTTPResponse);
    Exit;
  end;

  Form1.Memo1.Lines.Add('');
  Form1.Memo1.Lines.Add('RESPONSE:');
  Form1.Memo1.Lines.Add(HTTPResponse);

  ResponseJSON := TJSONObject.ParseJSONValue(HTTPResponse) as TJSONObject;

  if ResponseJSON = nil then
  begin
    AddErrorNotification('Dreame Cloud zwrócił nieprawidłowy JSON.');
    Exit;
  end;

  try
    if GetJsonInt(ResponseJSON, 'code', -1) <> 0 then
    begin
      AddErrorNotification('Dreame Cloud: ' + GetJsonString(ResponseJSON, 'msg', 'nieznany błąd'));
      Exit;
    end;

    DataObj := ResponseJSON.GetValue('data') as TJSONObject;

    if DataObj = nil then
    begin
      AddErrorNotification('Dreame Cloud: brak obiektu data.');
      Exit;
    end;

    ResultArr := DataObj.GetValue('result') as TJSONArray;

    if ResultArr = nil then
    begin
      AddErrorNotification('Dreame Cloud: brak data.result dla historii sprzątania.');
      Exit;
    end;

    Form1.Memo1.Lines.Add(Format('Otrzymano rekordów eventów: %d', [ResultArr.Count]));

    for I := 0 to ResultArr.Count - 1 do
    begin
      if not (ResultArr.Items[I] is TJSONObject) then Continue;

      RecordObj := ResultArr.Items[I] as TJSONObject;

      if ParseHistoryRecord(RecordObj, Event) then
      begin
        AddCleaningEventNotification(Event);
      end;
    end;

    if FItems.Count = 0 then
    begin
      AddErrorNotification('Dreame Cloud zwrócił data.result, ale nie znaleziono poprawnych wpisów historii.');
    end;

  finally
    ResponseJSON.Free;
  end;
end;


procedure TForm6.RefreshList;
var
  I: Integer;
  Entry: TNotificationEntry;
  Item: TListItem;
begin
  ListView1.Items.BeginUpdate;

  try
    ListView1.Items.Clear;

    for I := 0 to FItems.Count - 1 do
    begin
      Entry := FItems[I];
      Item := ListView1.Items.Add;
      Item.Caption := Entry.TypeName;
      Item.SubItems.Add(Entry.Title);
      Item.SubItems.Add(Entry.Message);
      Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Entry.Timestamp));
      Item.Data := Entry;
    end;

  finally
    ListView1.Items.EndUpdate;
  end;
end;

procedure TForm6.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm6.Button2Click(Sender: TObject);
var
  SelectedItem: TListItem;
  Entry: TNotificationEntry;
begin
  SelectedItem := ListView1.Selected;

  if not Assigned(SelectedItem) then Exit;

  if Assigned(SelectedItem.Data) then
  begin
    Entry := TNotificationEntry(SelectedItem.Data);
    FItems.Remove(Entry);
  end;

  SelectedItem.Delete;
end;

end.
