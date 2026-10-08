unit Unit6;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Generics.Collections,
  System.DateUtils, System.JSON, System.Math, System.Net.HttpClientComponent,
  System.Net.HttpClient, System.Net.URLClient, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls;

type
  TNotificationEntry = class
  public
    Title: string;
    Message: string;
    TypeName: string;
    Timestamp: TDateTime;
    EventKey: string;

    constructor
      Create(const ATitle, AMessage, ATypeName, AEventKey: string; ATimestamp: TDateTime);
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

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);

  private
    FItems: TObjectList<TNotificationEntry>;
    procedure AddNotification(const ATitle, AMessage, ATypeName, AEventKey: string; ATimestamp: TDateTime);
    procedure AddCleaningEventNotification(const AEvent: TCleaningEvent);
    procedure AddErrorNotification(const AMessage: string);
    procedure RefreshList;
    procedure SyncNotificationsFromCloud;
    function CloudPost(const AEndpoint: string; const ABody: string; out AResponse: string): Boolean;
    function GetJsonString(Obj: TJSONObject; const AName: string; const ADefault: string = ''): string;
    function GetJsonInt(Obj: TJSONObject; const AName: string; const ADefault: Integer = 0): Integer;
    function GetJsonInt64(Obj: TJSONObject; const AName: string; const ADefault: Int64 = 0): Int64;
    function GetJsonFloat(Obj: TJSONObject; const AName: string; const ADefault: Double = 0): Double;
    function GetValueAsString(AValue: TJSONValue): string;
    function UnixToDateTimeSafe(AUnix: Int64): TDateTime;
    function ExtractHistoryArray(AValue: TJSONValue): TJSONArray;
    function FindHistoryArray(ARecord: TJSONObject): TJSONArray;
    function ParseHistoryRecord(ARecord: TJSONObject; out AEvent: TCleaningEvent): Boolean;
    function ParseCleaningItem(AItem: TJSONObject; var AEvent: TCleaningEvent): Boolean;
    function FindEventTimestamp(ARecord: TJSONObject; AEvent: TCleaningEvent): TDateTime;
    function FindNumberRecursive(AValue: TJSONValue; const ANames: array of string; const ADefault: Double): Double;
    function FindStringRecursive(AValue: TJSONValue; const ANames: array of string; const ADefault: string): string;
    function EventAlreadyExists(const AEventKey: string): Boolean;
    function EscapeJson(const S: string): string;
    function CleaningStatusText(AStatus: Integer): string;
    function CleaningModeText(AMode: Integer): string;
    function FormatCleaningDuration(AMinutes: Integer): string;
    function FormatArea(AArea: Double): string;
    procedure ProcessResultValue(AValue: TJSONValue; var AAdded: Integer);
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

  DREAME_HISTORY_LIMIT = 50;
  DREAME_HISTORY_DAYS = 180;

  DREAME_STATUS_SIID = 4;
  DREAME_STATUS_EIID = 1;

  DREAME_DATA_VERSION = 3;

  // TNotificationEntry                                                         }

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

//FORM                                                                        }

procedure TForm6.FormCreate(Sender: TObject);
begin
  FItems := TObjectList<TNotificationEntry>.Create(True);

  ListView1.ViewStyle := vsReport;
  ListView1.ReadOnly := True;
  ListView1.RowSelect := True;
  ListView1.Columns.Clear;

  with ListView1.Columns.Add do
  begin
    Caption := 'Typ';
    Width := 100;
  end;

  with ListView1.Columns.Add do
  begin
    Caption := 'Tytuł';
    Width := 180;
  end;

  with ListView1.Columns.Add do
  begin
    Caption := 'Wiadomość';
    Width := 500;
  end;

  with ListView1.Columns.Add do
  begin
    Caption := 'Czas';
    Width := 160;
  end;
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  SyncNotificationsFromCloud;
end;

procedure TForm6.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FItems);
end;

// JSON                                                                        }

function TForm6.EscapeJson(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result,  #9, '\t', [rfReplaceAll]);
end;

function TForm6.GetValueAsString(AValue: TJSONValue): string;
begin
  Result := '';
  if AValue = nil then Exit;

  if AValue is TJSONString then
    Result := TJSONString(AValue).Value
  else
    Result := AValue.Value;
end;

function TForm6.GetJsonString(Obj: TJSONObject; const AName: string; const ADefault: string): string;
var
  V: TJSONValue;
begin
  Result := ADefault;
  if Obj = nil then Exit;
  V := Obj.GetValue(AName);
  if V <> nil then
    Result := GetValueAsString(V);
end;

function TForm6.GetJsonInt(Obj: TJSONObject; const AName: string; const ADefault: Integer): Integer;
var
  V: TJSONValue;
  S: string;
begin
  Result := ADefault;
  if Obj = nil then Exit;
  V := Obj.GetValue(AName);
  if V = nil then Exit;

  S := GetValueAsString(V);
  Result := StrToIntDef(S, ADefault);
end;

function TForm6.GetJsonInt64(Obj: TJSONObject; const AName: string; const ADefault: Int64): Int64;
var
  V: TJSONValue;
  S: string;
begin
  Result := ADefault;
  if Obj = nil then Exit;
  V := Obj.GetValue(AName);

  if V = nil then Exit;
  S := GetValueAsString(V);

  Result := StrToInt64Def(S, ADefault);
end;

function TForm6.GetJsonFloat(Obj: TJSONObject; const AName: string; const ADefault: Double): Double;
var
  V: TJSONValue;
  S: string;
  FS: TFormatSettings;
begin
  Result := ADefault;
  if Obj = nil then Exit;

  V := Obj.GetValue(AName);
  if V = nil then Exit;

  S := GetValueAsString(V);
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  if not TryStrToFloat(S, Result, FS) then
    Result := ADefault;
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

// HISTORIA - SZUKANIE TABLICY                                                 }

function TForm6.ExtractHistoryArray(AValue: TJSONValue): TJSONArray;
var
  Obj: TJSONObject;
  V: TJSONValue;
  S: string;
  Parsed: TJSONValue;
begin
  Result := nil;
  if AValue = nil then Exit;

  if AValue is TJSONArray then
  begin
    Result := TJSONArray(AValue);
    Exit;
  end;

  if AValue is TJSONString then
  begin
    S := TJSONString(AValue).Value;
    if S = '' then Exit;
    Parsed := nil;

    try
      Parsed := TJSONObject.ParseJSONValue(S);

      if Parsed is TJSONArray then
      begin
        Result := Parsed as TJSONArray;
        Parsed := nil;
      end;
    finally
      Parsed.Free;
    end;
    Exit;
  end;

  if AValue is TJSONObject then
  begin
    Obj := AValue as TJSONObject;
    V := Obj.GetValue('history');

    if V <> nil then
    begin
      Result := ExtractHistoryArray(V);

      if Result <> nil then
        Exit;
    end;

    V := Obj.GetValue('value');
    if V <> nil then
    begin
      Result := ExtractHistoryArray(V);

      if Result <> nil then Exit;
    end;

    V := Obj.GetValue('data');

    if V <> nil then
    begin
      Result := ExtractHistoryArray(V);
      if Result <> nil then Exit;
    end;

    V := Obj.GetValue('result');

    if V <> nil then
    begin
      Result := ExtractHistoryArray(V);
      if Result <> nil then Exit;
    end;

    V := Obj.GetValue('records');

    if V <> nil then Result := ExtractHistoryArray(V);
  end;
end;

function TForm6.FindHistoryArray(ARecord: TJSONObject): TJSONArray;
var
  V: TJSONValue;
begin
  Result := nil;
  if ARecord = nil then Exit;

  V := ARecord.GetValue('history');

  if V <> nil then
  begin
    Result := ExtractHistoryArray(V);
    if Result <> nil then Exit;
  end;

  V := ARecord.GetValue('value');

  if V <> nil then
  begin
    Result := ExtractHistoryArray(V);
    if Result <> nil then Exit;
  end;

  V := ARecord.GetValue('data');

  if V <> nil then
  begin
    Result := ExtractHistoryArray(V);
    if Result <> nil then Exit;
  end;

  V := ARecord.GetValue('result');

  if V <> nil then
  begin
    Result := ExtractHistoryArray(V);
    if Result <> nil then Exit;
  end;

  V := ARecord.GetValue('records');
  if V <> nil then Result := ExtractHistoryArray(V);
end;

// REKURENCYJNE WYSZUKIWANIE                                                   }

function TForm6.FindNumberRecursive(AValue: TJSONValue; const ANames: array of string; const ADefault: Double): Double;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  Pair: TJSONPair;
  V: TJSONValue;
  I: Integer;
  J: Integer;
  S: string;
  FS: TFormatSettings;
begin
  Result := ADefault;
  if AValue = nil then Exit;

  if AValue is TJSONObject then
  begin
    Obj := AValue as TJSONObject;
    for J := Low(ANames) to High(ANames) do
    begin
      V := Obj.GetValue(ANames[J]);

      if V <> nil then
      begin
        S := GetValueAsString(V);

        FS := TFormatSettings.Create;
        FS.DecimalSeparator := '.';

        if TryStrToFloat( S, Result, FS) then Exit;
      end;
    end;

    for I := 0 to Obj.Count - 1 do
    begin
      Pair := Obj.Pairs[I];

      if Pair = nil then Continue;

      V := Pair.JsonValue;
      Result := FindNumberRecursive(V, ANames, ADefault);

      if not SameValue(Result, ADefault, 0.0000001) then Exit;
    end;
  end
  else if AValue is TJSONArray then
  begin
    Arr := AValue as TJSONArray;

    for I := 0 to Arr.Count - 1 do
    begin
      Result := FindNumberRecursive(Arr.Items[I], ANames, ADefault);

      if not SameValue(Result, ADefault, 0.0000001) then Exit;
    end;
  end;
end;

function TForm6.FindStringRecursive(AValue: TJSONValue;
  const ANames: array of string; const ADefault: string): string;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  Pair: TJSONPair;
  V: TJSONValue;
  I: Integer;
  J: Integer;
begin
  Result := ADefault;
  if AValue = nil then Exit;

  if AValue is TJSONObject then
  begin
    Obj := AValue as TJSONObject;

    for J := Low(ANames) to High(ANames) do
    begin
      V := Obj.GetValue(ANames[J]);

      if V <> nil then
      begin
        Result := GetValueAsString(V);
        if Result <> '' then Exit;
      end;
    end;

    for I := 0 to Obj.Count - 1 do
    begin
      Pair := Obj.Pairs[I];
      if Pair = nil then Continue;

      Result := FindStringRecursive(Pair.JsonValue, ANames, ADefault);
      if Result <> '' then Exit;
    end;
  end
  else if AValue is TJSONArray then
  begin
    Arr := AValue as TJSONArray;

    for I := 0 to Arr.Count - 1 do
    begin
      Result := FindStringRecursive(Arr.Items[I], ANames, ADefault);
      if Result <> '' then Exit;
    end;
  end;
end;

// POJEDYNCZY ELEMENT PIID

function TForm6.ParseCleaningItem(AItem: TJSONObject; var AEvent: TCleaningEvent): Boolean;
var
  PIID: Integer;
  Value: TJSONValue;
  S: string;
  N: Double;
  UnixTime: Int64;
begin
  Result := False;

  if AItem = nil then Exit;

  PIID := GetJsonInt(AItem, 'piid', -1);
  if PIID < 0 then Exit;
  Value := AItem.GetValue('value');
  if Value = nil then Value := AItem.GetValue('val');
  if Value = nil then Exit;

  S := GetValueAsString(Value);

  case PIID of

    1:
      begin
        AEvent.Status := StrToIntDef(S, AEvent.Status);
        Result := True;
      end;

    2:
      begin
        AEvent.CleaningTime := StrToIntDef(S, AEvent.CleaningTime);
        Result := True;
      end;

    3:
      begin
        N := GetJsonFloat(AItem, 'value', AEvent.CleanedArea);
        AEvent.CleanedArea := N;
        Result := True;
      end;

    7:
      begin
        Result := True;
      end;

    8:
      begin
        UnixTime := StrToInt64Def(S, 0);

        if UnixTime > 0 then
        begin
          AEvent.Timestamp := UnixToDateTimeSafe(UnixTime);
          Result := AEvent.Timestamp > 0;
        end;
      end;

    13:
      begin
        AEvent.Completed := StrToIntDef(S, 0) = 1;
        Result := True;
      end;

    23:
      begin
        AEvent.CleaningMode := StrToIntDef(S, AEvent.CleaningMode);
        Result := True;
      end;

  end;
end;

// CZAS EVENTU

function TForm6.FindEventTimestamp(ARecord: TJSONObject; AEvent: TCleaningEvent): TDateTime;
var
  UnixTime: Int64;
  V: TJSONValue;
  S: string;
  N: Double;
begin
  Result := AEvent.Timestamp;

  if Result > 0 then Exit;
  if ARecord = nil then Exit;

  UnixTime := GetJsonInt64(ARecord, 'timestamp', 0);

  if UnixTime = 0 then
    UnixTime := GetJsonInt64(ARecord, 'time', 0);

  if UnixTime = 0 then
    UnixTime := GetJsonInt64(ARecord, 'createTime', 0);

  if UnixTime = 0 then
    UnixTime := GetJsonInt64(ARecord, 'create_time', 0);

  if UnixTime > 0 then
  begin
    Result := UnixToDateTimeSafe(UnixTime);
    if Result > 0 then Exit;
  end;

  V := ARecord.GetValue('timestamp');

  if V <> nil then
  begin
    S := GetValueAsString(V);

    if TryStrToFloat(S, N) then
    begin
      if N > 10000000000 then
        N := N / 1000;

      Result := UnixToDateTimeSafe(Round(N));
    end;
  end;
end;

// GŁÓWNY PARSER HISTORII                                                       }

function TForm6.ParseHistoryRecord(ARecord: TJSONObject; out AEvent: TCleaningEvent): Boolean;
var
  HistoryArr: TJSONArray;
  I: Integer;
  Item: TJSONObject;
  ParsedSomething: Boolean;
  UnixTime: Int64;
  EventSeconds: Int64;
begin
  Result := False;

  FillChar(AEvent, SizeOf(AEvent), 0);

  AEvent.Status := -1;
  AEvent.CleaningMode := -1;
  AEvent.Timestamp := 0;
  AEvent.CleaningTime := 0;
  AEvent.CleanedArea := 0;
  AEvent.Completed := False;
  AEvent.EventKey := '';

  if ARecord = nil then Exit;
  HistoryArr := FindHistoryArray(ARecord);

  try

    if HistoryArr <> nil then
    begin
      for I := 0 to HistoryArr.Count - 1 do
      begin
        if not (HistoryArr.Items[I] is TJSONObject) then Continue;

        Item := HistoryArr.Items[I] as TJSONObject;
        ParsedSomething := ParseCleaningItem(Item, AEvent);
      end;
    end
    else
    begin
      ParsedSomething := ParseCleaningItem(ARecord, AEvent);
    end;

    AEvent.Timestamp := FindEventTimestamp(ARecord, AEvent);
    if AEvent.Timestamp <= 0 then Exit;

    if AEvent.Status < 0 then
    begin
      AEvent.Status := GetJsonInt(ARecord, 'status', -1);
    end;

    if AEvent.Status < 0 then
    begin
      AEvent.Status := GetJsonInt(ARecord, 'taskStatus', -1);
    end;

    if AEvent.CleaningTime <= 0 then
    begin
      AEvent.CleaningTime := GetJsonInt(ARecord, 'cleaningTime', 0);

      if AEvent.CleaningTime <= 0 then
        AEvent.CleaningTime := GetJsonInt(ARecord, 'duration', 0);
    end;

    if AEvent.CleanedArea <= 0 then
    begin
      AEvent.CleanedArea := GetJsonFloat(ARecord, 'cleanedArea', 0);

      if AEvent.CleanedArea <= 0 then
        AEvent.CleanedArea := GetJsonFloat(ARecord, 'area', 0);
    end;

    if AEvent.CleaningMode < 0 then
    begin
      AEvent.CleaningMode := GetJsonInt(ARecord, 'cleaningMode', -1);

      if AEvent.CleaningMode < 0 then
        AEvent.CleaningMode := GetJsonInt(ARecord, 'mode', -1);
    end;

    EventSeconds := DateTimeToUnix(AEvent.Timestamp, False);
    if EventSeconds <= 0 then Exit;
    UnixTime := EventSeconds;

    AEvent.EventKey := Format('%d_%d_%d_%d', [UnixTime, AEvent.Status, AEvent.CleaningTime,
          Round(AEvent.CleanedArea * 10)]);
    Result := True;

  finally
   //
  end;
end;

// NOTYFIKACJE                                                                  }

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

procedure TForm6.AddNotification(const ATitle, AMessage, ATypeName,
          AEventKey: string; ATimestamp: TDateTime);
var
  Item: TNotificationEntry;
begin
  if AEventKey <> '' then
  begin
    if EventAlreadyExists(AEventKey) then Exit;
  end;

  Item := TNotificationEntry.Create(ATitle, AMessage, ATypeName, AEventKey, ATimestamp);
  FItems.Insert(0, Item);

  while FItems.Count > 200 do
    FItems.Delete(FItems.Count - 1);
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
      Result := 'Zakończenie sprzątania (' + IntToStr(AStatus) +')';
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
var
  FS: TFormatSettings;
begin
  Result := '';
  if AArea <= 0 then Exit;
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := ',';
  Result := FormatFloat('0.0', AArea, FS) + ' m²';
end;

procedure TForm6.AddCleaningEventNotification(const AEvent: TCleaningEvent);
var
  Msg: string;
  DurationText: string;
  AreaText: string;
  ModeText: string;
  TitleText: string;
begin
  TitleText := CleaningStatusText(AEvent.Status);
  Msg := TitleText + '.';
  DurationText := FormatCleaningDuration(AEvent.CleaningTime);
  AreaText := FormatArea(AEvent.CleanedArea);
  ModeText := CleaningModeText(AEvent.CleaningMode);

  if DurationText <> '' then
    Msg := Msg + ' Czas: ' + DurationText + '.';

  if AreaText <> '' then
    Msg := Msg + ' Powierzchnia: ' + AreaText + '.';

  if ModeText <> '' then
    Msg := Msg + ' Tryb: ' + ModeText + '.';

  AddNotification(TitleText, Msg, 'Sprzątanie', AEvent.EventKey, AEvent.Timestamp);
end;

procedure TForm6.AddErrorNotification(const AMessage: string);
begin
  AddNotification('Błąd', AMessage, 'Błąd',  '', Now);
end;

// HTTP                                                                        }

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

  try
    RequestBody := TStringStream.Create(ABody, TEncoding.UTF8);
    try
      HTTP.ConnectionTimeout := 15000;
      HTTP.ResponseTimeout := 30000;
      HTTP.CustomHeaders['Content-Type'] := 'application/json';
      HTTP.CustomHeaders['Accept'] := 'application/json';
      HTTP.CustomHeaders['User-Agent'] := Form1.USER_AGENT;
      HTTP.CustomHeaders['Authorization'] := Form1.AUTH_HEADER;
      HTTP.CustomHeaders['Tenant-Id'] := Form1.FTenantId;
      HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + Form1.FKeyToken;

      URL := Form1.GetBaseUrl(Form1.ComboBox2.Text) + AEndpoint;
      Response := HTTP.Post(URL, RequestBody);

      if Response = nil then
      begin
        AResponse := 'Brak odpowiedzi HTTP.';
        Exit;
      end;
      AResponse := Response.ContentAsString;
      if Response.StatusCode < 200 then Exit;
      if Response.StatusCode >= 300 then Exit;
      Result := True;

    finally
      RequestBody.Free;
    end;

  except
    on E: Exception do
    begin
      AResponse := 'HTTP ERROR: ' + E.ClassName +  ': ' + E.Message;
      Result := False;
    end;
  end;

  HTTP.Free;
end;

// REKURENCYJNE PRZETWARZANIE RESULT                                           }

procedure TForm6.ProcessResultValue(AValue: TJSONValue; var AAdded: Integer);
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
  Event: TCleaningEvent;
begin
  if AValue = nil then Exit;

  if AValue is TJSONArray then
  begin
    Arr := AValue as TJSONArray;

    for I := 0 to Arr.Count - 1 do
      ProcessResultValue(Arr.Items[I], AAdded);
      Exit;
  end;

  if not (AValue is TJSONObject) then Exit;
  Obj := AValue as TJSONObject;

  if ParseHistoryRecord(Obj, Event) then
  begin
    AddCleaningEventNotification(Event);
    Inc(AAdded);
    Exit;
  end;

  if Obj.GetValue('data') <> nil then
    ProcessResultValue(Obj.GetValue('data'), AAdded);

  if Obj.GetValue('result') <> nil then
    ProcessResultValue(Obj.GetValue('result'), AAdded);

  if Obj.GetValue('history') <> nil then
    ProcessResultValue(Obj.GetValue('history'), AAdded);

  if Obj.GetValue('records') <> nil then
    ProcessResultValue(Obj.GetValue('records'), AAdded);

  if Obj.GetValue('value') <> nil then
  begin
    if (Obj.GetValue('value') is TJSONArray) or
    (Obj.GetValue('value') is TJSONObject) then
      ProcessResultValue(Obj.GetValue('value'), AAdded);
  end;
end;

//SYNCHRONIZACJA Z CHMURĄ                                                     }

procedure TForm6.SyncNotificationsFromCloud;
var
  HTTPResponse: string;
  Body: string;
  ResponseJSON: TJSONObject;
  DataObj: TJSONObject;
  ResultValue: TJSONValue;
  UID: string;
  DID: string;
  StartUnix: Int64;
  Code: Integer;
  Msg: string;
  AddedCount: Integer;
begin
  FItems.Clear;
  if Form1.FKeyToken.IsEmpty then
  begin
    AddErrorNotification('Brak tokenu Dreame Cloud.');
    RefreshList;
    Exit;
  end;

  DID := Trim(Form1.FSelectedDid);

  if DID.IsEmpty then
  begin
    AddErrorNotification('Brak wybranego DID robota.');
    RefreshList;
    Exit;
  end;

  UID := Trim(Form1.FUserId);

  if UID.IsEmpty then
  begin
    AddErrorNotification('Brak UID użytkownika.');
    RefreshList;
    Exit;
  end;

  StartUnix := DateTimeToUnix(IncDay(Now, -DREAME_HISTORY_DAYS), False);

  Body := '{' + '"uid":"' + EscapeJson(UID) + '",' + '"did":"' + EscapeJson(DID) + '",' +
         '"from":' + IntToStr(StartUnix) + ',' + '"limit":' + IntToStr(DREAME_HISTORY_LIMIT) +
      ',' + '"siid":' + IntToStr(DREAME_STATUS_SIID) + ',' + '"country":"' + EscapeJson(
        Form1.ComboBox2.Text) + '",' + '"ver":' + IntToStr(DREAME_DATA_VERSION) +
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
    RefreshList;
    Exit;
  end;

  Form1.Memo1.Lines.Add('');
  Form1.Memo1.Lines.Add('RESPONSE:');
  Form1.Memo1.Lines.Add(HTTPResponse);

  ResponseJSON := TJSONObject.ParseJSONValue(HTTPResponse) as TJSONObject;

  if ResponseJSON = nil then
  begin
    AddErrorNotification('Dreame Cloud zwrócił nieprawidłowy JSON.');
    RefreshList;
    Exit;
  end;

  try
    Code := GetJsonInt(ResponseJSON, 'code', -1);

    if Code <> 0 then
    begin
      Msg := GetJsonString(ResponseJSON, 'msg', '');
      if Msg = '' then Msg := GetJsonString(ResponseJSON, 'message', 'nieznany błąd');

      AddErrorNotification('Dreame Cloud: ' + Msg);
      RefreshList;
      Exit;
    end;

    DataObj := ResponseJSON.GetValue('data') as TJSONObject;
    AddedCount := 0;

    if DataObj <> nil then
    begin
      ResultValue := DataObj.GetValue('result');

      if ResultValue <> nil then
      begin
        ProcessResultValue(ResultValue, AddedCount);
      end
      else
      begin
        ProcessResultValue(DataObj, AddedCount);
      end;
    end
    else
    begin
      ProcessResultValue(ResponseJSON, AddedCount);
    end;

    Form1.Memo1.Lines.Add(Format('Rozpoznanych eventów sprzątania: %d', [AddedCount]));

    if AddedCount = 0 then
    begin
      AddErrorNotification('Dreame Cloud odpowiedział poprawnie, ale parser nie znalazł wpisów historii sprzątania.');
      Form1.Memo1.Lines.Add('Parser nie znalazł poprawnego rekordu historii.');
      Form1.Memo1.Lines.Add('Sprawdź RESPONSE powyżej.');
    end;

  finally
    ResponseJSON.Free;
  end;

  RefreshList;
end;

// LISTA                                                                       }

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

      if Entry.Timestamp > 0 then
        Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Entry.Timestamp))
      else
        Item.SubItems.Add('');
        Item.Data := Entry;
    end;

  finally
    ListView1.Items.EndUpdate;
  end;
end;

// PRZYCISKI                                                                   }

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
