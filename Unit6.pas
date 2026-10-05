unit Unit6;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.DateUtils, System.JSON,
  System.Net.HttpClientComponent,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls;

type
  TNotificationEntry = class
  public
    Title: string;
    Message: string;
    TypeName: string;
    Timestamp: TDateTime;
    constructor Create(const ATitle, AMessage, ATypeName: string);
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
    procedure AddNotification(const ATitle, AMessage, ATypeName: string);
    procedure RefreshList;
    procedure SyncNotificationsFromCloud;
  public
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

uses Unit1;

constructor TNotificationEntry.Create(const ATitle, AMessage, ATypeName: string);
begin
  inherited Create;
  Title := ATitle;
  Message := AMessage;
  TypeName := ATypeName;
  Timestamp := Now;
end;

procedure TForm6.FormCreate(Sender: TObject);
begin
  FItems := TObjectList<TNotificationEntry>.Create(True);
  ListView1.ViewStyle := vsReport;
  ListView1.Columns.Clear;
  ListView1.Columns.Add.Caption := 'Typ';
  ListView1.Columns[0].Width := 110;
  ListView1.Columns.Add.Caption := 'Tytuł';
  ListView1.Columns[1].Width := 180;
  ListView1.Columns.Add.Caption := 'Wiadomość';
  ListView1.Columns[2].Width := 260;
  ListView1.Columns.Add.Caption := 'Czas';
  ListView1.Columns[3].Width := 120;
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  FItems.Clear;
  SyncNotificationsFromCloud;
  RefreshList;
end;

procedure TForm6.AddNotification(const ATitle, AMessage, ATypeName: string);
var
  Item: TNotificationEntry;
begin
  Item := TNotificationEntry.Create(ATitle, AMessage, ATypeName);
  FItems.Insert(0, Item);
end;

procedure TForm6.SyncNotificationsFromCloud;
var
  HTTP: TNetHTTPClient;
  Response: IHTTPResponse;
  RequestBody: TStringStream;
  ResponseJSON, DataObj, PageObj, DeviceObj: TJSONObject;
  RecordsArr: TJSONArray;
  I: Integer;
  VDid: string;
  StatusCode: Integer;
  StatusText, BatteryText: string;
begin
  if Form1.FKeyToken.IsEmpty or Form1.FSelectedDid.IsEmpty then
  begin
    AddNotification('Błąd', 'Brak danych logowania robota', 'Błąd');
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
                      0: StatusText := 'Nieznany';
                      1: StatusText := 'Oczekiwanie';
                      2: StatusText := 'Gotowość';
                      3: StatusText := 'Bezczynny';
                      4: StatusText := 'Pauza';
                      5: StatusText := 'Powrót do bazy';
                      6: StatusText := 'Ładowanie';
                      8: StatusText := 'Suszenie mopów';
                      9: StatusText := 'Mycie mopów';
                      10: StatusText := 'Mopowanie';
                      12: StatusText := 'Odkurzanie + mopowanie';
                      22: StatusText := 'Auto-opróżnianie';
                    else
                      StatusText := 'Status ' + StatusCode.ToString;
                    end;

                    BatteryText := Format('%d%%', [DeviceObj.GetValue<Integer>('battery')]);
                    AddNotification('Status robota', StatusText, 'Status');
                    AddNotification('Bateria', BatteryText, 'Bateria');

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
      AddNotification('Błąd sieci', 'Brak odpowiedzi z serwera Dreame', 'Błąd');
    end;

  finally
    RequestBody.Free;
    HTTP.Free;
  end;
end;

procedure TForm6.RefreshList;
var
  I: Integer;
  LEntry: TNotificationEntry;
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

procedure TForm6.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm6.Button2Click(Sender: TObject);
var
  SelectedItem: TListItem;
begin
  SelectedItem := ListView1.Selected;
  if Assigned(SelectedItem) then
  begin
    if Assigned(SelectedItem.Data) then
      FItems.Remove(TNotificationEntry(SelectedItem.Data));
    SelectedItem.Delete;
  end;
end;

end.