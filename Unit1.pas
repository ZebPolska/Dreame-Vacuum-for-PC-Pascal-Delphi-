unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.Iphlpapi, Winapi.Winsock, Winapi.ShellAPI, Winapi.WinInet,
  System.SysUtils, System.Variants, System.Classes, System.Generics.Collections, System.Diagnostics,
  System.Hash, System.JSON, System.DateUtils, System.StrUtils, System.Math, System.Threading, System.Types,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Net.URLClient,  System.NetEncoding,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus,
  Data.Bind.Components, Data.Bind.ObjectScope, REST.Client, Unit2;

  type
  TShortcutStringObj = class
  public
    ShortcutID: string;
    constructor Create(const AID: string);
  end;

  type
  TZoneData = class
  public
    ZoneId: Integer;
    RawConfigJSON: string; // Zawiera całą strukturę XY, mapy i parametrów AIoT
    constructor Create(AId: Integer; const AConfig: string);
  end;

 type
  TRobotDane = record
    Did: string;
    Model: string;
    Shard: string;
  end;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Button3: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    MainMenu1: TMainMenu;
    Plik1: TMenuItem;
    Zakoczdziaanieprogramu1: TMenuItem;
    Oprogrmie1: TMenuItem;
    Label15: TLabel;
    Memo1: TMemo;
    Timer1: TTimer;
    Panel3: TPanel;
    Label5: TLabel;
    Button6: TButton;
    Button7: TButton;
    Panel8: TPanel;
    Panel4: TPanel;
    ComboBox1: TComboBox;
    EdycjaMapy1: TMenuItem;
    Button2: TButton;
    Oprnijpojemnikteraz1: TMenuItem;
    Znajdrobota1: TMenuItem;
    Uruchompraniemopwteraz1: TMenuItem;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Ustawienia1: TMenuItem;
    WybrJzyka1: TMenuItem;
    Label1: TLabel;
    ZakontoDreame1: TMenuItem;
    Ustawieniakonta1: TMenuItem;
    N3: TMenuItem;
    Funkcje1: TMenuItem;
    N4: TMenuItem;
    Wiadomocizrobota1: TMenuItem;
    Informacje1: TMenuItem;
    N1: TMenuItem;
    Powiadomienia1: TMenuItem;
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Zakoczdziaanieprogramu1Click(Sender: TObject);
    procedure Oprogrmie1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure EdycjaMapy1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Oprnijpojemnikteraz1Click(Sender: TObject);
    procedure Znajdrobota1Click(Sender: TObject);
    procedure Uruchompraniemopwteraz1Click(Sender: TObject);
    procedure ComboBox1KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox3KeyPress(Sender: TObject; var Key: Char);
    procedure Memo1KeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox3Change(Sender: TObject);
    procedure WybrJzyka1Click(Sender: TObject);
    procedure ZakontoDreame1Click(Sender: TObject);
    procedure Ustawieniakonta1Click(Sender: TObject);
    procedure Informacje1Click(Sender: TObject);
    procedure Wiadomocizrobota1Click(Sender: TObject);
    procedure Powiadomienia1Click(Sender: TObject);
  public
      FSelectedShard: string; // Przechowa dynamiczny shard robota (np. '10000', '10100' itd.)
      RobotyLista: array of TRobotDane; // Tutaj zapiszemy wszystkie roboty lista
    const
      SALT_KEY       = 'RAylYC%fmSKp7%Tq';
      USER_AGENT     = 'Dreamehome/2.1.25 (PC; Windows 10; Scale/u.00)';
      AUTH_HEADER    = 'Basic ZHJlYW1lX2FwcHYxOkFQXmR2QHpAU1FZVnhOODg=';
      TENANT_DEFAULT = '000000';
    var
      FKeyToken: string;     // Pobrany z chmury access_token
      FTenantId: string;     // Identyfikator dzierżawcy tenant_id
      FUserId: string;       // Identyfikator użytkownika uid
      FSelectedDid: string;  // Pobrany unikalny identyfikator robota (did)
      FSelectedModel: string;
      S_Status, S_Batt :String;

    function HashPassword20(const RawPass: string): string;
    function GetBaseUrl(const Country: string): string;
    procedure PerformGetDevices;
    procedure SendRobotAction(const Did: string; Siid, Aiid: Integer; const ParametersJSON: string);
    procedure UpdateRobotStatus;
    procedure PobierzSkrotyZChmury;
   end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Unit3, Unit4, Unit5, Unit6, Unit7, Unit8, Unit9, Unit10;

constructor TShortcutStringObj.Create(const AID: string);
begin
  ShortcutID := AID;
end;

procedure ExecuteCommand(const Cmd: string);
begin
  ShellExecute(0, 'open', 'cmd.exe', PChar('/c ' + Cmd), nil, SW_HIDE);
end;

{ Dynamiczne generowanie URL na bazie wybranego regionu }
function TForm1.GetBaseUrl(const Country: string): string;
var
  CleanCountry: string;
begin
  CleanCountry := Country.ToLower.Trim;


  if (CleanCountry = 'pl') or (CleanCountry = '') then
  begin
    // adres URL chmury Dreame dla Europy z protokołem HTTPS i dedykowanym portem
    Result := 'https://eu.iot.dreame.tech:13267';
  end
  else
  begin
    // Dla kont z innych kontynentów (np. us, cn) buduje adres z odpowiednim przedrostkiem
    Result := 'https://' + CleanCountry + '.iot.dreame.tech:13267';
  end;
end;

function TForm1.HashPassword20(const RawPass: string): string;
begin
  Result := THashMD5.GetHashString(RawPass + SALT_KEY).ToLower;
end;

procedure TForm1.Informacje1Click(Sender: TObject);
begin
  Application.MessageBox('Opcja niedostępna /w fazie testów/', 'Dreame Unofficial', MB_OK);
  Exit;
  Form7.Show;
end;

procedure TForm1.Memo1KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm1.PerformGetDevices;
var
  HTTP: TNetHTTPClient;
  Response: IHTTPResponse;
  TargetURL: string;
  RequestBody: TStringStream;
  ResponseJSON, DataObj, PageObj: TJSONObject;
  RecordsArr: TJSONArray;
  I: Integer;
  DeviceVal: TJSONValue;
  DeviceObj, DevInfoObj: TJSONObject;
  NameStr, ModelStr, DidStr, IpStr, MacStr, ShardVal: string;
  begin
  Memo1.Lines.Add('=LISTA URZĄDZEŃ=');

  HTTP := TNetHTTPClient.Create(nil);
  // Serwer Dreame dla listV2 w metodzie POST wymaga przesłania pustego obiektu JSON w body

  RequestBody := TStringStream.Create('{}', TEncoding.UTF8);

  try
    TargetURL := GetBaseUrl(Combobox2.Text) + '/dreame-user-iot/iotuserbind/device/listV2';

    // Konfiguracja nagłówków przesyłowych
    HTTP.CustomHeaders['Content-Type'] := 'application/json';
    HTTP.CustomHeaders['User-Agent'] := USER_AGENT;
    HTTP.CustomHeaders['Authorization'] := AUTH_HEADER;
    HTTP.CustomHeaders['Tenant-Id'] := FTenantId;

    HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + FKeyToken;
    Response := HTTP.Post(TargetURL, RequestBody);

    if Response.StatusCode = 200 then
    begin
      ResponseJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      try
        if Assigned(ResponseJSON) and (ResponseJSON.GetValue<integer>('code') = 0) then
        begin
          DataObj := ResponseJSON.GetValue('data') as TJSONObject;
          if Assigned(DataObj) then
          begin
            PageObj := DataObj.GetValue('page') as TJSONObject;
            if Assigned(PageObj) then
            begin
              RecordsArr := PageObj.GetValue('records') as TJSONArray;
              if Assigned(RecordsArr) and (RecordsArr.Count > 0) then
              begin
                Memo1.Lines.Add(Format('Odnaleziono urządzeń: %d', [RecordsArr.Count]));

                for I := 0 to RecordsArr.Count - 1 do
                begin
                  DeviceVal := RecordsArr.Items[I];
                  if not (DeviceVal is TJSONObject) then Continue;
                  DeviceObj := DeviceVal as TJSONObject;

                  // Wyciąganie danych z JSON
                  DidStr := '';
                  if DeviceObj.Get('did') <> nil then DidStr := DeviceObj.GetValue<string>('did');

                  // Model w Dreamehome 2.0 znajduje się wewnątrz podobiektu deviceInfo
                  ModelStr := '';
                  if DeviceObj.Get('deviceInfo') <> nil then
                  begin
                    DevInfoObj := DeviceObj.GetValue('deviceInfo') as TJSONObject;
                    if (DevInfoObj <> nil) and (DevInfoObj.Get('model') <> nil) then
                      ModelStr := DevInfoObj.GetValue<string>('model');
                  end;

                  // Fallback (gdyby model był jednak w głównym obiekcie)
                  if (ModelStr = '') and (DeviceObj.Get('model') <> nil) then
                    ModelStr := DeviceObj.GetValue<string>('model');

                  IpStr := 'Brak';
                  if DeviceObj.Get('localip') <> nil then IpStr := DeviceObj.GetValue<string>('localip');

                  MacStr := 'Brak';
                  if DeviceObj.Get('mac') <> nil then MacStr := DeviceObj.GetValue<string>('mac');

                  // --- TNAZWA ROBOTA ---
                  NameStr := 'Nieznany robot';
                  if DeviceObj.Get('displayName') <> nil then
                      NameStr := DeviceObj.GetValue<string>('displayName')
                      else if DeviceObj.Get('name') <> nil then
                      NameStr := DeviceObj.GetValue<string>('name');

                  NameStr := '';
                  if DeviceObj.Get('name') <> nil then NameStr := DeviceObj.GetValue<string>('name');

                  // DYNAMICZNE WYCIĄGANIE SHARD ID DLA URZĄDZENIA
                  ShardVal := '10000'; // Wartość domyślna
                  if DeviceObj.Get('shardId') <> nil then
                    ShardVal := DeviceObj.GetValue<string>('shardId')
                  else if (DeviceObj.Get('deviceInfo') <> nil) and ((DeviceObj.GetValue('deviceInfo') as TJSONObject).Get('shardId') <> nil) then
                    ShardVal := (DeviceObj.GetValue('deviceInfo') as TJSONObject).GetValue<string>('shardId');

                  // Przypisanie pierwszego odnalezionego urządzenia i jego parametrów do pamięci programu
                  if DidStr <> '' then
                  begin
                    SetLength(RobotyLista, Length(RobotyLista) + 1);
                    RobotyLista[High(RobotyLista)].Did := DidStr;
                    RobotyLista[High(RobotyLista)].Model := ModelStr;
                    RobotyLista[High(RobotyLista)].Shard := ShardVal;
                  end;

                  // Dodanie oryginalnego modelu do listy wizualnej
                  TThread.Synchronize(nil,
                  procedure
                    begin
                      ComboBox3.Items.Add(ModelStr);
                      Memo1.Lines.Add('Wczytano: ' + ModelStr);
                    end);

                  NameStr := ModelStr;
                  Memo1.Lines.Add('Nazwa: ' + NameStr);

                  if ModelStr = 'dreame.vacuum.r2469x' then
                      Memo1.Lines.Add('Model: L10s Ultra Gen 2')
                  else
                      Memo1.Lines.Add('Model: ' + ModelStr);
                end;

                //TUTAJ USTAWIA INDEKS
                TThread.Synchronize(nil,
                procedure
                begin
                  if ComboBox3.Items.Count > 0 then
                  begin
                    ComboBox3.ItemIndex := 0;
                    //Form1.ComboBox3Change(Form1.ComboBox3); // Aktywacja pierwszego robota
                  end;
                end);

              end

              else
                Memo1.Lines.Add('Na koncie nie znaleziono odkurzaczy.');
            end;
          end;
        end;

        TThread.Synchronize(nil, procedure
                begin
                  Form1.ComboBox3Change(Form1.ComboBox3);
                end);

        UpdateRobotStatus;

      finally
        ResponseJSON.Free;
      end;
    end
    else
    begin
      Memo1.Lines.Add('Błąd sieciowy HTTP: ' + Response.StatusCode.ToString);
      Memo1.Lines.Add(Response.ContentAsString);
    end;

  finally
    RequestBody.Free;
    HTTP.Free;
  end;
end;

procedure TForm1.SendRobotAction(const Did: string; Siid, Aiid: Integer; const ParametersJSON: string);
var
  HTTP: TNetHTTPClient;
  Response: IHTTPResponse;
  TargetURL: string;
  RequestBody: TStringStream;
  RootObj, InnerDataObj, ActionParamsObj: TJSONObject;
  InArray: TJSONArray;
  DynamicId: Int64;
  StringifiedData: string;
begin
  if Did.IsEmpty then Exit;

  HTTP := TNetHTTPClient.Create(nil);

  // Identyfikator żądania musi być w sekundach (10 cyfr)
  DynamicId := DateTimeToUnix(Now);

  RootObj := TJSONObject.Create;
  try
    // 1. Zewnętrzny kontener kopertowy API Dreame Cloud
    RootObj.AddPair('did', Did);
    RootObj.AddPair('id', TJSONNumber.Create(DynamicId));

    // 2. Budowa wewnętrznego obiektu RPC, który zostanie spłaszczony do formatu String
    InnerDataObj := TJSONObject.Create;
    try
      InnerDataObj.AddPair('did', Did);
      InnerDataObj.AddPair('id', TJSONNumber.Create(DynamicId));
      InnerDataObj.AddPair('method', 'action');

      // 3. Parametry sprzętowe AIoT
      ActionParamsObj := TJSONObject.Create;
      ActionParamsObj.AddPair('did', Did);
      ActionParamsObj.AddPair('siid', TJSONNumber.Create(Siid));
      ActionParamsObj.AddPair('aiid', TJSONNumber.Create(Aiid));

      if (ParametersJSON <> '') and (ParametersJSON <> '[]') then
        InArray := TJSONObject.ParseJSONValue(ParametersJSON) as TJSONArray
      else
        InArray := TJSONArray.Create; // Pusta tablica [] dla Start/Pause/Baza

      ActionParamsObj.AddPair('in', InArray);
      InnerDataObj.AddPair('params', ActionParamsObj);

      // Konwersja całej struktury wewnętrznej na płaski ciąg tekstowy (Stringified JSON) bez spacji
      StringifiedData := InnerDataObj.ToJSON.Replace(' ', '');
    finally
      InnerDataObj.Free;
    end;

    // 4. Przypisanie tekstu JSON jako wartość pola "data" w głównej kopercie
    RootObj.AddPair('data', StringifiedData);

    RequestBody := TStringStream.Create(RootObj.ToJSON, TEncoding.UTF8);
    TargetURL := GetBaseUrl(Combobox2.Text) + '/dreame-iot-com-10000/device/sendCommand';

    // Konfiguracja nagłówków autoryzacyjnych standardu DreameHome
    HTTP.CustomHeaders['Content-Type'] := 'application/json';
    HTTP.CustomHeaders['User-Agent'] := USER_AGENT;
    HTTP.CustomHeaders['Authorization'] := AUTH_HEADER;
    HTTP.CustomHeaders['Tenant-Id'] := FTenantId;

    // Wymagany prefiks "bearer " przed surowym tokenem dostępu
    HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + FKeyToken;

    Response := HTTP.Post(TargetURL, RequestBody);

  finally
    RootObj.Free;
    HTTP.Free;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);

begin
  UpdateRobotStatus;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  LocalDid, PayloadAbort: string;
begin
  if FSelectedDid.IsEmpty then Exit;
  LocalDid := FSelectedDid;

  Form1.Panel8.Caption := 'Reset Zadania (Abort)';
  PayloadAbort := '[]';

  TTask.Run(procedure
  begin
    TThread.Synchronize(TThread.CurrentThread, procedure
    begin
      Form1.Memo1.Lines.Add('=ABORT=');
    end);

     SendRobotAction(LocalDid, 4, 2, PayloadAbort);
  end);
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  HTTP: TNetHTTPClient;
  Response: IHTTPResponse;
  Params: TStringList;
  ResponseJSON: TJSONObject;
  TargetURL: string;
  NetFunc: function(lpdwFlags: Pointer; dwReserved: DWORD): BOOL; stdcall;
begin
  Memo1.Lines.Clear;
  SetLength(RobotyLista, 0);


  // Dynamiczne pobranie funkcji sprawdzania sieci z systemu Windows
  @NetFunc := GetProcAddress(GetModuleHandle('wininet.dll'), 'InternetGetConnectedState');
  if Assigned(NetFunc) and (not NetFunc(nil, 0)) then
  begin
    ShowMessage('Brak połączenia z internetem! Sprawdź sieć.');
    Exit;
  end;



  HTTP := TNetHTTPClient.Create(nil);
  Params := TStringList.Create;
  try
    TargetURL := GetBaseUrl(Combobox2.Text) + '/dreame-auth/oauth/token';

    Params.Add('platform=IOS');
    Params.Add('scope=all');
    Params.Add('grant_type=password');
    Params.Add('username=' + Edit1.Text);
    Params.Add('password=' + HashPassword20(Edit2.Text));
    Params.Add('type=account');

    HTTP.CustomHeaders['User-Agent'] := USER_AGENT;
    HTTP.CustomHeaders['Authorization'] := AUTH_HEADER;
    HTTP.CustomHeaders['Tenant-Id'] := TENANT_DEFAULT;

    Response := HTTP.Post(TargetURL, Params);

    if Response.StatusCode = 200 then
    begin
      ResponseJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      try
        if Assigned(ResponseJSON) and (ResponseJSON.Count > 0) then
        begin
          FKeyToken := ResponseJSON.GetValue<string>('access_token');
          FUserId := ResponseJSON.GetValue<string>('uid');
          if not ResponseJSON.TryGetValue<string>('tenant_id', FTenantId) then
            FTenantId := TENANT_DEFAULT;
          if FTenantId.IsEmpty then FTenantId := TENANT_DEFAULT;

          Memo1.Lines.Add('Autoryzacja tokena OK.');

          // Pobranie listy urządzeń
          PerformGetDevices;
          // Pobranie listy skrótów
          //PobierzSkrotyZChmury;
        end;

      finally
        ResponseJSON.Free;
        Button3.Enabled := False;
        Button2.Enabled := True;
        Button6.Enabled := True;
        Button7.Enabled := True;

        Edit1.Enabled := False;
        Edit2.Enabled := False;
        Combobox2.Enabled := False;
        Powiadomienia1.Enabled := True;
        Informacje1.Enabled := True;
        Wiadomocizrobota1.Enabled := True;
        ZakontoDreame1.Enabled := False;
        Ustawieniakonta1.Enabled := True;
        WybrJzyka1.Enabled := True;


          Znajdrobota1.Enabled := True;
          Oprnijpojemnikteraz1.Enabled := True;
          Uruchompraniemopwteraz1.Enabled := True;
          EdycjaMapy1.Enabled := True;
      end;
    end
    else
    begin
      //Memo1.Lines.Add('Błąd logowania (HTTP ' + Response.StatusCode.ToString + ')');
      Memo1.Lines.Add('Błąd logowania.');
      Memo1.Lines.Add('Jeśli nie masz konta Dreame:');
      Memo1.Lines.Add('Załóż oficjalne konto Dreame.');
    end;
  finally
    Params.Free;
    HTTP.Free;
  end;
end;

procedure TForm1.Button6Click(Sender: TObject);
var
  LocalDid, PayloadStrefowyAIoT: string;
  LIdx, TargetShortcutID: Integer;
  OuterArray: TJSONArray;
  Item1, Item10: TJSONObject;
begin
  if FSelectedDid.IsEmpty then Exit;

  LocalDid := FSelectedDid;
  LIdx := ComboBox1.ItemIndex;

  // Brak wybranej strefy -> Zwykły Start robota)
  if (LIdx < 0) or (ComboBox1.Text = 'Wybierz Strefę do sprzątania') then
  begin
    Form1.Panel8.Caption := 'Start Standardowy';
    TTask.Run(procedure
    begin
      SendRobotAction(LocalDid, 2, 1, '[]');
    end);
    Exit;
  end;

  // URUCHOMIENIE SKRÓTU
  Form1.Panel8.Caption := 'Czyszczenie ...';

  // Pobieramy ID wybranego profilu chmurowego z TZoneData
  TargetShortcutID := TZoneData(ComboBox1.Items.Objects[LIdx]).ZoneId;

  OuterArray := TJSONArray.Create;
  try
    // Element 1: piid: 1, value: 25 -> Rozkaz wykonania zapisanego profilu/skrótu chmurowego
    Item1 := TJSONObject.Create;
    Item1.AddPair('piid', TJSONNumber.Create(1));
    Item1.AddPair('value', TJSONNumber.Create(25));
    OuterArray.AddElement(Item1);

    // Element 2: piid: 10 -> Przekazanie ID skrótu jako string w cudzysłowie
    Item10 := TJSONObject.Create;
    Item10.AddPair('piid', TJSONNumber.Create(10));
    Item10.AddPair('value', TJSONString.Create(TargetShortcutID.ToString));
    OuterArray.AddElement(Item10);

    PayloadStrefowyAIoT := OuterArray.ToJSON;
  finally
    // OuterArray automatycznie zwolni Item1 i Item10 z pamięci
    OuterArray.Free;
  end;

  TTask.Run(procedure
  begin
    TThread.Synchronize(TThread.CurrentThread, procedure
    begin
      Form1.Memo1.Lines.Add('Polecenie: Czyszczenie Strefowe' );
      Form1.Memo1.Lines.Add('Strefa: ' + ComboBox1.Text);
      Form1.Memo1.Lines.Add(' ');

    end);

    // Wysłanie precyzyjnego pakietu (SIID 4, AIID 1) do wykonania profilu
    SendRobotAction(LocalDid, 4, 1, PayloadStrefowyAIoT);
  end);
end;


procedure TForm1.Button7Click(Sender: TObject);
var
  LocalDid: string;
begin
  if FSelectedDid.IsEmpty then Exit;
  LocalDid := FSelectedDid;

    Form1.Panel8.Caption := 'Powrót do bazy / Ładowanie';

  TTask.Run(procedure
  begin
    TThread.Synchronize(nil, procedure
    begin
      Memo1.Lines.Add('Polecenie: Powrót / ładowanie');
    end);

    SendRobotAction(LocalDid, 3, 1, '[]');
  end);
end;

procedure TForm1.ComboBox1KeyPress(Sender: TObject; var Key: Char);
begin
   Key := #0;
end;

procedure TForm1.ComboBox3Change(Sender: TObject);
var
  WybranyIndeks: Integer;
begin
  WybranyIndeks := ComboBox3.ItemIndex;

  // Twój warunek: Jeśli wybrano prawidłowego robota z listy...
  if (WybranyIndeks >= 0) and (WybranyIndeks < Length(RobotyLista)) then
  begin
    // Ustawiamy "current" (aktualne) zmienne globalne bez zmian w strukturze programu!
    FSelectedDid   := RobotyLista[WybranyIndeks].Did;
    FSelectedModel := RobotyLista[WybranyIndeks].Model;
    FSelectedShard := RobotyLista[WybranyIndeks].Shard;

    // Czyścimy stare strefy i pobieramy nowe dla TEGO konkretnego robota
    ComboBox1.Items.Clear;
    ComboBox1.Text := 'Pobieranie stref...';

    UpdateRobotStatus;
    PobierzSkrotyZChmury;
  end;
end;

procedure TForm1.ComboBox3KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm1.EdycjaMapy1Click(Sender: TObject);
var
  I: Integer;
  OriginalZone: TZoneData;
  NewZoneCopy: TZoneData;
begin
  Application.MessageBox('Opcja niedostępna w wersji Alpha', 'Dreame Unofficial', MB_OK);
  Exit;

  Form4.ComboBox6.Items.Clear;
  for I := 0 to ComboBox1.Items.Count - 1 do
  begin
    if ComboBox1.Items.Objects[I] is TZoneData then
    begin
      OriginalZone := TZoneData(ComboBox1.Items.Objects[I]);
      NewZoneCopy := TZoneData.Create(OriginalZone.ZoneId, OriginalZone.RawConfigJSON);
      Form4.ComboBox6.Items.AddObject(ComboBox1.Items[I], NewZoneCopy);
    end;
  end;

  if Form4.ComboBox6.Items.Count > 0 then
      Form4.ComboBox6.ItemIndex := 0;
  Form4.Show;

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Application.Terminate;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  OneCopy: THandle;
begin
  Application.Title := 'Dreame Unofficial';

  OneCopy := CreateMutex(nil, True, 'Dreame Unofficial'); //tylko jedna kopia uruchomiona
  if (OneCopy = 0) or (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    if OneCopy <> 0 then CloseHandle(OneCopy);  //zamykanie uchwytu
    Application.MessageBox('Program jest już uruchomiony', 'Dreame Unofficial', MB_OK);
    Halt;
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
   Application.Terminate;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Edit1.Enabled := True;
  Edit2.Enabled := True;
  Button2.Enabled := False;
  Button6.Enabled := False;
  Button7.Enabled := False;

  Znajdrobota1.Enabled := False;
  Oprnijpojemnikteraz1.Enabled := False;
  Uruchompraniemopwteraz1.Enabled := False;
  EdycjaMapy1.Enabled := False;
end;

procedure TForm1.Oprnijpojemnikteraz1Click(Sender: TObject);
var
  LocalDid: string;
begin
  if FSelectedDid.IsEmpty then Exit;
  LocalDid := FSelectedDid;

  Form1.Panel8.Caption := 'Opróżnianie pojemnika';

  TTask.Run(procedure
  begin
    TThread.Synchronize(nil, procedure
    begin
      Memo1.Lines.Add('Polecenie: Opróżnianie pojemnika');
      Memo1.Lines.Add('');
    end);

    // Wywołanie akcji opróżniania: siid 15, aiid 1 wg dreame_miot.py
    SendRobotAction(LocalDid, 15, 1, '[]');

    // Wymuszenie natychmiastowej aktualizacji statusu po wysłaniu komendy
    TThread.Sleep(500); // Krótka pauza, żeby chmura przetworzyła akcję
    TThread.Synchronize(nil, procedure
    begin
      UpdateRobotStatus;
    end);
  end);
end;

procedure TForm1.Oprogrmie1Click(Sender: TObject);
begin
  Form3.Show;
end;

procedure TForm1.Zakoczdziaanieprogramu1Click(Sender: TObject);
 begin
  Application.Terminate;
 end;

procedure TForm1.ZakontoDreame1Click(Sender: TObject);
begin
  Application.MessageBox('Opcja niedostępna w wersji Alpha', 'Dreame Unofficial', MB_OK);
  Exit;
end;

procedure TForm1.Znajdrobota1Click(Sender: TObject);
var
  LocalDid: string;
begin
  if FSelectedDid.IsEmpty then Exit;
  LocalDid := FSelectedDid;

  Form1.Panel8.Caption := 'Tu jestem!';

  TTask.Run(procedure
  begin
    TThread.Synchronize(nil, procedure
    begin
      Memo1.Lines.Add('Polecenie: lokalizacja robota');
      Memo1.Lines.Add('');
    end);
    SendRobotAction(LocalDid, 7, 1, '[]');
  end);
end;

procedure TForm1.UpdateRobotStatus;
var
  LToken, LDid, LTenant, LCountry: string;
begin
  if FKeyToken.IsEmpty or FSelectedDid.IsEmpty then Exit;
  LToken := FKeyToken; LDid := FSelectedDid; LTenant := FTenantId; LCountry := Combobox2.Text;

  TTask.Run(procedure
  var
    HTTP: TNetHTTPClient;
    Response: IHTTPResponse;
    RespJSON, DataObj, PageObj, DeviceObj, InnerProp: TJSONObject;
    RecordsArr: TJSONArray;
    I, V_Status: Integer;
    V_Did, PropStr: string;
  begin
    HTTP := TNetHTTPClient.Create(nil);
    try
      HTTP.CustomHeaders['Content-Type'] := 'application/json';
      HTTP.CustomHeaders['User-Agent'] := USER_AGENT;
      HTTP.CustomHeaders['Authorization'] := AUTH_HEADER;
      HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + LToken;
      HTTP.CustomHeaders['Tenant-Id'] := LTenant;

      Response := HTTP.Post(GetBaseUrl(LCountry) + '/dreame-user-iot/iotuserbind/device/listV2',
        TStringStream.Create('{}', TEncoding.UTF8));

      if Response.StatusCode = 200 then
      begin
        RespJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
        if Assigned(RespJSON) and (RespJSON.GetValue<integer>('code') = 0) then
        begin
          if RespJSON.GetValue('data') = nil then
            Exit;

          DataObj := RespJSON.GetValue('data') as TJSONObject;

          if not Assigned(DataObj) then
            Exit;


          PageObj := DataObj.GetValue('page') as TJSONObject;
          RecordsArr := PageObj.GetValue('records') as TJSONArray;

          for I := 0 to RecordsArr.Count - 1 do
          begin
            DeviceObj := RecordsArr.Items[I] as TJSONObject;
            V_Did := DeviceObj.GetValue<string>('did');

            if V_Did = LDid then
            begin
              // Bateria
              S_Batt := DeviceObj.GetValue('battery').Value + '% naładowania';

              // Status AIoT z pola property
              V_Status := -1;
              if DeviceObj.Get('property') <> nil then
              begin
                PropStr := DeviceObj.GetValue<string>('property');


                InnerProp := TJSONObject.ParseJSONValue(PropStr) as TJSONObject;
                try
                  if Assigned(InnerProp) and (InnerProp.Get('2.1') <> nil) then
                    V_Status := InnerProp.GetValue<Integer>('2.1');
                finally
                  InnerProp.Free;
                end;
              end;

              // Fallback do latestStatus
              if V_Status = -1 then V_Status := DeviceObj.GetValue<Integer>('latestStatus');

              // Mapowanie rygorystycznie wg vacuum.py (STATE_CODE_TO_STATE)
               case V_Status of
                  0: S_Status := 'Status Nieznany';
                  1:  S_Status := 'Oczekiwanie';
                  2:  S_Status := 'W Gotowości';
                  3:  S_Status := 'Bezczynny';
                  4:  S_Status := 'Wstrzymano (Pauza)';
                  5:  S_Status := 'Powrót do bazy w celu naładowania';
                  6:  S_Status := 'Ładowanie';
                  7:  S_Status := 'Ładowanie2?';
                  8:  S_Status := 'Suszenie mopa';
                  9:  S_Status := 'Mycie Mopów';
                  10: S_Status := 'Mopowanie';
                  11: S_Status := 'Budowanie mapy';
                  12: S_Status := 'Odkurzanie i mopowanie';
                  13: S_Status := 'Ładowanie zakończone';
                  14: S_Status := 'Aktualizacja';
                  21: S_Status := 'Czyszczenie wstrzymane';
                  22: S_Status := 'Auto-opróżnianie pojemnika';
                  16: S_Status := 'Reset stacji';
                  97: S_Status := 'Czyszczenie strefowe: '+ ComboBox1.Text;
                else
                  S_Status := 'Status ID: ' + V_Status.ToString;
                end;
              Break;
            end;
          end;
        end;
        if Assigned(RespJSON) then RespJSON.Free;
      end;

      TThread.Synchronize(nil, procedure
      begin
        Panel4.Caption := S_Batt;
        Panel8.Caption := S_Status;
      end);
    finally
      HTTP.Free;
    end;
  end);
end;

procedure TForm1.Uruchompraniemopwteraz1Click(Sender: TObject);
var
  LocalDid: string;
begin
  if FSelectedDid.IsEmpty then Exit;

  Form1.Panel8.Caption := 'Mycie mopów';

  LocalDid := FSelectedDid;

  TTask.Run(procedure
  begin
    TThread.Synchronize(nil, procedure
    begin
      Memo1.Lines.Add('Polecenie: Mycie mopów');
      Memo1.Lines.Add('');
    end);

    // Mycie mopów w stacji
    SendRobotAction(LocalDid, 4, 4, '[]');

    // odśwież status po chwili
    TThread.Sleep(500);

    TThread.Synchronize(nil, procedure
    begin
      UpdateRobotStatus;
    end);
  end);
end;

procedure TForm1.Ustawieniakonta1Click(Sender: TObject);
begin
  Application.MessageBox('Opcja niedostępna w wersji Alpha', 'Dreame Unofficial', MB_OK);
  Exit;
  Form9.Show;
end;

procedure TForm1.Wiadomocizrobota1Click(Sender: TObject);
begin
  Application.MessageBox('Opcja niedostępna /w fazie testów/', 'Dreame Unofficial', MB_OK);
  Exit;

  Form8.Show;
end;

procedure TForm1.WybrJzyka1Click(Sender: TObject);
begin
  Application.MessageBox('Opcja niedostępna w wersji Alpha', 'Dreame Unofficial', MB_OK);
  Exit;
  Form10.Show;
end;

constructor TZoneData.Create(AId: Integer; const AConfig: string);
  begin
    inherited Create;
    ZoneId := AId;
    RawConfigJSON := AConfig;
  end;


procedure TForm1.PobierzSkrotyZChmury;
var
  LocalDid, LocalShard, TargetURL: string;
begin
  if FKeyToken.IsEmpty or FTenantId.IsEmpty or FSelectedDid.IsEmpty then Exit;

  LocalDid := FSelectedDid;
  LocalShard := FSelectedShard;
  if LocalShard.IsEmpty then LocalShard := '10000';

  TargetURL := GetBaseUrl(Combobox2.Text) + '/dreame-iot-com-' + LocalShard + '/device/sendCommand';

  ComboBox1.Items.Clear;
  Memo1.Lines.Add('=Pobieranie Stref z Dreame=');

  TTask.Run(
    procedure
    var
      HTTP: TNetHTTPClient;
      Response: IHTTPResponse;
      ReqObj, DataObjRPC, ParamObj, RespJSON, DataObj, ResultObj: TJSONObject;
      ParamsArr, ResultArr: TJSONArray;
      PayloadStr, ResBody, ShortCutValueStr, Base64Name, DecodedName: string;
      ShortCutArrData: TJSONArray;
      ItemVal: TJSONValue;
      ItemObj: TJSONObject;
      Idx: Integer;

      ResponseStream: TStringStream;
      ZoneId: Integer;
      ConfigVal: TJSONValue;
      RawConfigStr: string;
      ZoneDataObj: TZoneData;
    begin
      HTTP := TNetHTTPClient.Create(nil);

      try
        HTTP.ConnectionTimeout := 15000;
        HTTP.ResponseTimeout := 15000;

        HTTP.CustomHeaders['Content-Type'] := 'application/json';
        HTTP.CustomHeaders['User-Agent'] := USER_AGENT;
        HTTP.CustomHeaders['Authorization'] := 'Basic ZHJlYW1lX2FwcHYxOkFQXmR2QHpAU1FZVnhOODg=';
        HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + FKeyToken;
        HTTP.CustomHeaders['Tenant-Id'] := FTenantId;

        ReqObj := TJSONObject.Create;
        try
          ReqObj.AddPair('did', LocalDid);
          ReqObj.AddPair('id', TJSONNumber.Create(4567));

          DataObjRPC := TJSONObject.Create;
          DataObjRPC.AddPair('did', LocalDid);
          DataObjRPC.AddPair('id', TJSONNumber.Create(4567));
          DataObjRPC.AddPair('method', 'get_properties');

          ParamsArr := TJSONArray.Create;
          ParamObj := TJSONObject.Create;
          ParamObj.AddPair('siid', TJSONNumber.Create(4));
          ParamObj.AddPair('piid', TJSONNumber.Create(48));
          ParamsArr.AddElement(ParamObj);

          DataObjRPC.AddPair('params', ParamsArr);
          DataObjRPC.AddPair('From', 'app');

          ReqObj.AddPair('data', DataObjRPC);
          PayloadStr := ReqObj.ToJSON;
        finally
        end;

        try
          ResponseStream := TStringStream.Create('', TEncoding.UTF8);
          try
            Response := HTTP.Post(TargetURL, TStringStream.Create(PayloadStr, TEncoding.UTF8), ResponseStream);
            ResBody := ResponseStream.DataString;
          finally
            ResponseStream.Free;
          end;
        except
          on E: Exception do Exit;
        end;

        ReqObj.Free;

        if (Response <> nil) and (Response.StatusCode = 200) and (not ResBody.IsEmpty) then
        begin
          RespJSON := TJSONObject.ParseJSONValue(ResBody) as TJSONObject;
          try
            if Assigned(RespJSON) and (RespJSON.GetValue<integer>('code') = 0) then
            begin
              DataObj := RespJSON.GetValue('data') as TJSONObject;
              if Assigned(DataObj) then
              begin
                ResultArr := DataObj.GetValue('result') as TJSONArray;
                if Assigned(ResultArr) and (ResultArr.Count > 0) then
                begin
                  if ResultArr.Items[0] is TJSONObject then
                  begin
                    ResultObj := ResultArr.Items[0] as TJSONObject;

                    if Assigned(ResultObj) and (ResultObj.GetValue<integer>('code') = 0) then
                    begin
                      ShortCutValueStr := ResultObj.GetValue<string>('value');

                      ShortCutArrData := TJSONObject.ParseJSONValue(ShortCutValueStr) as TJSONArray;
                      if Assigned(ShortCutArrData) then
                      begin
                        try
                          TThread.Synchronize(nil,
                            procedure
                            begin
                              Memo1.Lines.Add('Zapisanych stref: ' + ShortCutArrData.Count.ToString);
                              Form1.Memo1.Lines.Add(' ');
                            end);

                          for Idx := 0 to ShortCutArrData.Count - 1 do
                          begin
                            ItemVal := ShortCutArrData.Items[Idx];
                            if Assigned(ItemVal) then
                            begin
                              ItemObj := TJSONObject(ItemVal);

                              if ItemObj.TryGetValue<string>('name', Base64Name) then
                              begin
                                try
                                  DecodedName := TNetEncoding.Base64.Decode(Base64Name);
                                  if DecodedName.IsEmpty then DecodedName := Base64Name;
                                except
                                  on E: Exception do DecodedName := Base64Name;
                                end;

                                // WYCIĄGANIE KLUCZOWYCH PARAMETRÓW AIoT DLA SENDROBOT
                                if not ItemObj.TryGetValue<Integer>('id', ZoneId) then ZoneId := Idx;

                                // W protokole AIoT parametry strefy siedzą w sekcji "cur" lub "cfg" obiektu skrótu
                                RawConfigStr := '';
                                ConfigVal := ItemObj.GetValue('cur');
                                if not Assigned(ConfigVal) then ConfigVal := ItemObj.GetValue('cfg');

                                if Assigned(ConfigVal) then
                                  RawConfigStr := ConfigVal.ToJSON
                                else
                                  RawConfigStr := ItemObj.ToJSON; // fallback do pełnego obiektu



                                TThread.Synchronize(nil,
                                  procedure
                                  begin
                                    // Tworzy obiekt z kompletem danych i wrzuca do ComboBox
                                    ZoneDataObj := TZoneData.Create(ZoneId, RawConfigStr);
                                    ComboBox1.Items.AddObject(DecodedName, ZoneDataObj);
                                  end);
                              end;
                            end;
                          end;
                        finally
                          ShortCutArrData.Free;
                        end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          finally
            if Assigned(RespJSON) then RespJSON.Free;
          end;
        end;

        TThread.Synchronize(nil,
          procedure
          begin

            if Form1.ComboBox1.Items.Count > 0 then
            Form1.ComboBox1.ItemIndex := 0

            else
              Form1.ComboBox1.Text := 'Robot wyłączony, Brak stref do sprzątania';
          end);

      finally
        HTTP.Free;
      end;
    end
  );
end;


procedure TForm1.Powiadomienia1Click(Sender: TObject);
begin
  Application.MessageBox('Opcja niedostępna /w fazie testów/', 'Dreame Unofficial', MB_OK);
  Exit;
  Form6.Show;
end;

end.


