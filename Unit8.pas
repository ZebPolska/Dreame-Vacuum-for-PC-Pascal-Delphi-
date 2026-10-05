unit Unit8;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.DateUtils, System.JSON, System.Net.HttpClientComponent, System.Net.HttpClient,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls;

type
  TSystemMessageEntry = class
  public
    Title: string;
    Message: string;
    TypeName: string;
    Timestamp: TDateTime;
    constructor Create(const ATitle, AMessage, ATypeName: string);
  end;

  TForm8 = class(TForm)
    ListView1: TListView;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FItems: TObjectList<TSystemMessageEntry>;
    procedure AddMessage(const ATitle, AMessage, ATypeName: string);
    procedure RefreshList;
    procedure SyncMessagesFromCloud;
  public
  end;

var
  Form8: TForm8;

implementation

{$R *.dfm}

uses Unit1;

constructor TSystemMessageEntry.Create(const ATitle, AMessage, ATypeName: string);
begin
  inherited Create;
  Title := ATitle;
  Message := AMessage;
  TypeName := ATypeName;
  Timestamp := Now;
end;

procedure TForm8.FormCreate(Sender: TObject);
begin
  FItems := TObjectList<TSystemMessageEntry>.Create(True);
  ListView1.ViewStyle := vsReport;
  ListView1.Columns.Clear;
  ListView1.Columns.Add.Caption := 'Typ';
  ListView1.Columns[0].Width := 110;
  ListView1.Columns.Add.Caption := 'Tytuł';
  ListView1.Columns[1].Width := 180;
  ListView1.Columns.Add.Caption := 'Treść';
  ListView1.Columns[2].Width := 270;
  ListView1.Columns.Add.Caption := 'Czas';
  ListView1.Columns[3].Width := 120;
end;

procedure TForm8.FormShow(Sender: TObject);
begin
  FItems.Clear;
  SyncMessagesFromCloud;
  RefreshList;
end;

procedure TForm8.AddMessage(const ATitle, AMessage, ATypeName: string);
var
  Item: TSystemMessageEntry;
begin
  Item := TSystemMessageEntry.Create(ATitle, AMessage, ATypeName);
  FItems.Insert(0, Item);
end;

procedure TForm8.SyncMessagesFromCloud;
var
  HTTP: TNetHTTPClient;
  Response: IHTTPResponse;
  RequestBody: TStringStream;
  ResponseJSON, DataObj, PageObj, DeviceObj: TJSONObject;
  RecordsArr: TJSONArray;
  I: Integer;
  VDid: string;
  StatusCode: Integer;
  StatusText: string;
  BatteryLevel: Integer;
begin
  if Form1.FKeyToken.IsEmpty or Form1.FSelectedDid.IsEmpty then
  begin
    AddMessage('Brak danych', 'Robot nie jest zalogowany', 'System');
    Exit;
  end;

  HTTP := TNetHTTPClient.Create(nil);
  RequestBody := TStringStream.Create('{}', TEncoding.UTF8);

  try
    HTTP.CustomHeaders['Content-Type'] := 'application/json';
    HTTP.CustomHeaders['User-Agent'] := Form1.USER_AGENT;
    HTTP.CustomHeaders['Authorization'] := Form1.AUTH_HEADER;
    HTTP.CustomHeaders['Tenant-Id'] := Form1.FTenantId;
    HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + Form1.FKeyToken;

    Response := HTTP.Post(
      Form1.GetBaseUrl(Form1.Combobox2.Text) + '/dreame-user-iot/iotuserbind/device/listV2',
      RequestBody
    );

    if (Response <> nil) and (Response.StatusCode = 200) then
    begin
      ResponseJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      if Assigned(ResponseJSON) then
      try
        if ResponseJSON.GetValue<Integer>('code') = 0 then
        begin
          DataObj := ResponseJSON.GetValue('data') as TJSONObject;
          if Assigned(DataObj) then
          begin
            PageObj := DataObj.GetValue('page') as TJSONObject;
            if Assigned(PageObj) then
            begin
              RecordsArr := PageObj.GetValue('records') as TJSONArray;
              if Assigned(RecordsArr) then
              begin
                for I := 0 to RecordsArr.Count - 1 do
                begin
                  DeviceObj := RecordsArr.Items[I] as TJSONObject;
                  VDid := DeviceObj.GetValue<string>('did');

                  if VDid = Form1.FSelectedDid then
                  begin
                    StatusCode := DeviceObj.GetValue<Integer>('latestStatus');
                    case StatusCode of
                      0: StatusText := 'Brak danych statusu';
                      1: StatusText := 'Oczekiwanie';
                      2: StatusText := 'Gotowość';
                      3: StatusText := 'Bezczynny';
                      4: StatusText := 'Pauza';
                      5: StatusText := 'Powrót do bazy';
                      6: StatusText := 'Ładowanie';
                      9: StatusText := 'Mycie mopów';
                      10: StatusText := 'Sprzątanie';
                      12: StatusText := 'Sprzątanie + mopowanie';
                      22: StatusText := 'Auto-opróżnianie';
                    else
                      StatusText := 'Stan robota: ' + StatusCode.ToString;
                    end;

                    BatteryLevel := DeviceObj.GetValue<Integer>('battery');

                    if BatteryLevel < 20 then
                      AddMessage('Alarm', 'Niski poziom baterii: ' + IntToStr(BatteryLevel) + '%', 'Alarm');

                    AddMessage('Status', StatusText, 'System');
                    AddMessage('Bateria', 'Poziom baterii: ' + IntToStr(BatteryLevel) + '%', 'System');

                    Break;
                  end;
                end;
              end;
            end;
          end;
        end;
      finally
        ResponseJSON.Free;
      end;
    end
    else
    begin
      AddMessage('Błąd sieci', 'Brak odpowiedzi z serwera Dreame', 'Błąd');
    end;

  finally
    RequestBody.Free;
    HTTP.Free;
  end;
end;

procedure TForm8.RefreshList;
var
  I: Integer;
  LEntry: TSystemMessageEntry;
  Item: TListItem;
begin
  ListView1.Items.BeginUpdate;
  try
    ListView1.Items.Clear;

    for I := 0 to FItems.Count - 1 do
    begin
      LEntry := FItems[I];
      Item := ListView1.Items.Add;
      Item.Caption := LEntry.TypeName;
      Item.SubItems.Add(LEntry.Title);
      Item.SubItems.Add(LEntry.Message);
      Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', LEntry.Timestamp));
      Item.Data := LEntry;
    end;
  finally
    ListView1.Items.EndUpdate;
  end;
end;

procedure TForm8.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm8.Button2Click(Sender: TObject);
var
  SelectedItem: TListItem;
begin
  SelectedItem := ListView1.Selected;
  if Assigned(SelectedItem) then
  begin
    if Assigned(SelectedItem.Data) then
      FItems.Remove(TSystemMessageEntry(SelectedItem.Data));
    SelectedItem.Delete;
  end;
end;

end.
