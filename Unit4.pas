unit Unit4;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.DateUtils, System.Net.URLClient,
  System.Net.HttpClient, System.Hash, System.Net.HttpClientComponent, System.Threading,
  System.JSON, System.ZLib, System.Math, System.Generics.Collections, System.NetEncoding,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, IdGlobal, System.SyncObjs, System.Types, Vcl.Buttons;

type
  PDreamePoint = ^TDreamePoint;
  TDreamePoint = record
    X, Y: Integer;
  end;

  PDreameZone = ^TDreameZone;
  TDreameZone = record
    ZoneType: Integer; // 0 = No-Go, 1 = No-Mop, 2 = No-Sweep
    Points: array[0..3] of TDreamePoint;
  end;

  PDreameWall = ^TDreameWall;
  TDreameWall = record
    X1, Y1, X2, Y2: Integer;
  end;

type
  // Struktura pojedynczego segmentu pokoju wyciągnięta z protocol.py
  TDreameSegment = record
    SegmentId: Integer;
    TypeID: Integer;
    MinX, MinY, MaxX, MaxY: Integer;
    RoomName: string;
  end;

type
  TDreameAiotHeaderV4 = packed record
    HeaderId: Word;       // 2B
    FrameType: Byte;      // 1B
    SubVersion: Byte;     // 1B
    FrameId: Word;        // 2B
    MinX: SmallInt;       // 2B -> lewy kafel
    MinY: SmallInt;       // 2B -> górny kafel
    MaxX: SmallInt;       // 2B -> prawy kafel
    MaxY: SmallInt;       // 2B -> dolny kafel
    GridSizeMm: SmallInt; // 2B -> np. 50 (50mm = 5cm/px)
    BotX: SmallInt;       // 2B
    BotY: SmallInt;       // 2B
    BotAngle: SmallInt;   // 2B
    Unknown: Byte;        // 1B
  end;


type
  // Klastry punktów i obiektów wektorowych ścieżki i ścian z sekcji wektorowych map.py
  TAIotVectorLayer = record
    Points: array of TPoint;
  end;


type
  TForm4 = class(TForm)
    Panel6: TPanel;
    PaintBox1: TPaintBox;
    Panel5: TPanel;
    Label5: TLabel;
    ComboBox6: TComboBox;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Edit4: TEdit;
    Panel1: TPanel;
    Button1: TButton;
    ComboBox4: TComboBox;
    Label4: TLabel;
    Panel2: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    Button2: TButton;
    NetHTTPClient1: TNetHTTPClient;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ComboBox6KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox3KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox2KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox1KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox4KeyPress(Sender: TObject; var Key: Char);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox6Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button8Click(Sender: TObject);
  public
    FMapId: Int64;
    FMapWidth: Integer;
    FMapHeight: Integer;
    FMapResolution: Integer;
    FOffsetX: Integer;
    FOffsetY: Integer;

    FBufferBitmap: TBitmap;
    FZonesList: TThreadList;
    FWallsList: TThreadList;

    // Map header info
    Header_MapId: Word;
    Header_FrameId: Word;
    Header_FrameType: Byte;
    Robot_X, Robot_Y, Robot_A: SmallInt;
    Charger_X, Charger_Y, Charger_A: SmallInt;
    GridSize: Word;
    Width, Height: Word;
    Left, Top: SmallInt;

    // Wektorowe warstwy na żywo (Ścieżka robota, ściany, poligony pokoi)
    FPathLayer: TAIotVectorLayer;
    FWallsLayer: TAIotVectorLayer;
    // Ramy geograficzne świata odczytane z nagłówka
    G_MinX, G_MinY, G_MaxX, G_MaxY: Integer;

    // Flags
    IsWall, IsCarpet: Boolean;
    RoomId: Byte;

    FIsDrawing: Boolean;
    FStartMousePt, FCurrentMousePt: TPoint;
    FCurrentMapIdFromCloud: Integer;
    FGlobalPixelMap: array of array of Byte;

    function RobotMmToPixel(AX, AY: Integer): TPoint;
    function PixelToRobotMm(APx, APy: Integer): TDreamePoint;
    procedure InvalidatePaintBox;
    procedure AutomatycznePobieranieMapy;
    procedure OminWalidacjeSSL(const Sender: TObject;
              const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: Boolean);

    procedure DecryptDreameMapAes(ASrcStream, ADestStream: TStream; const AMapKey: string);
    procedure ParseDreameMap(SrcStream: TStream; DestBmp: TBitmap);

    procedure DaneRobota;
    procedure DiagnozaStrumieniaAIoT(SrcStream: TStream);
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

uses unit1, Unit5;


procedure TForm4.Button1Click(Sender: TObject);
begin
  DaneRobota;
  AutomatycznePobieranieMapy;
end;

procedure TForm4.Button2Click(Sender: TObject);
begin
  Form4.Close;
end;

procedure TForm4.Button3Click(Sender: TObject);
begin
  // 1. Kopiuj całą listę
  Form5.ComboBox14.Items.Assign(ComboBox6.Items);

  // 2. przypisz indeks (zostanie zachowany czysty indeks!)
  Form5.ComboBox14.ItemIndex := ComboBox6.ItemIndex;
  Form5.ComboBox14.Enabled := False;

  if Form4.Edit4.Text <> IntToStr(Form4.ComboBox6.ItemIndex) then
  Form5.ComboBox14.Text :=  Form4.Edit4.Text;

  Form5.Show;

end;

procedure TForm4.Button8Click(Sender: TObject);
begin
  Edit4.Text := 'Nowa Strefa';
end;

procedure TForm4.ComboBox1KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;   //blokada ręcznego wpisu do combobox
end;

procedure TForm4.ComboBox2KeyPress(Sender: TObject; var Key: Char);
begin
   Key := #0;
end;

procedure TForm4.ComboBox3KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm4.ComboBox4KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm4.ComboBox6Change(Sender: TObject);
begin
  Edit4.Text := ComboBox6.Text;

end;

procedure TForm4.ComboBox6KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm4.FormCreate(Sender: TObject);
begin
  FMapId := 0;
  FMapResolution := 50;
  FIsDrawing := False;
  FBufferBitmap := TBitmap.Create;
  FZonesList := TThreadList.Create;
  FWallsList := TThreadList.Create;
end;

procedure TForm4.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to ComboBox6.Items.Count - 1 do
    if Assigned(ComboBox6.Items.Objects[I]) then
      ComboBox6.Items.Objects[I].Free;
      FBufferBitmap.Free;
      FZonesList.Free;
      FWallsList.Free;
end;

procedure TForm4.FormShow(Sender: TObject);
begin
  Edit4.Text := ComboBox6.Text;
end;

// --------- Invalidate ---------
procedure TForm4.InvalidatePaintBox;
begin
  TThread.Synchronize(nil, procedure
  begin
    if Assigned(PaintBox1) then
      PaintBox1.Invalidate;
  end);
end;

// --------- Pobieranie mapy ---------

function ReadPGMToken(Stream: TStream): string;
var
  Ch: AnsiChar;
begin
  Result := '';
  while Stream.Position < Stream.Size do
  begin
    Stream.ReadBuffer(Ch, 1);
    if not (Ch in [#9, #10, #13, #32]) then
    begin
      Result := Result + string(Ch);
      Break;
    end;
  end;
  while Stream.Position < Stream.Size do
  begin
    Stream.ReadBuffer(Ch, 1);
    if Ch in [#9, #10, #13, #32] then
      Break
    else
      Result := Result + string(Ch);
  end;
end;

function ReadUInt16LE(
  Stream: TStream;
  out Value: Word
): Boolean;
var
  B: array[0..1] of Byte;
begin
  Result := False;

  if Stream.Position + 2 > Stream.Size then
    Exit;

  Stream.ReadBuffer(B[0], 2);

  Value :=
    Word(B[0]) or
    (Word(B[1]) shl 8);

  Result := True;
end;

function ReadInt16LE(
  Stream: TStream;
  out Value: SmallInt
): Boolean;
var
  W: Word;
begin
  Result := ReadUInt16LE(Stream, W);

  if Result then
    Move(W, Value, SizeOf(Value));
end;

procedure TForm4.ParseDreameMap(SrcStream: TStream; DestBmp: TBitmap);
var
  MapId: Word;
  FrameId: Word;
  FrameType: Byte;

  RobotX: SmallInt;
  RobotY: SmallInt;
  RobotA: SmallInt;

  ChargerX: SmallInt;
  ChargerY: SmallInt;
  ChargerA: SmallInt;

  GridSizeMm: Word;
  MapWidth: Word;
  MapHeight: Word;
  MapLeft: SmallInt;
  MapTop: SmallInt;

  PixelData: TBytes;

  X, Y: Integer;
  PixelIndex: Integer;
  Pixel: Byte;

  SegmentId: Integer;
  IsWall: Boolean;
  IsFloor: Boolean;

  RowPointer: PRGBQuad;

  PixelX: Integer;
  PixelY: Integer;

  ImageSize: Int64;
begin
  if SrcStream = nil then
    raise Exception.Create('ParseDreameMap: brak strumienia.');

  SrcStream.Position := 0;

  if SrcStream.Size < 27 then
    raise Exception.Create(Format('Mapa ma tylko %d bajtów po ZLIB.', [SrcStream.Size]));

  { ---------------------------------------------------------
    Dreame map header:

       0..1   map_id
       2..3   frame_id
       4      frame_type
       5..6   robot X
       7..8   robot Y
       9..10  robot angle
       11..12 charger X
       13..14 charger Y
       15..16 charger angle
       17..18 grid size
       19..20 width
       21..22 height
       23..24 left
       25..26 top
    --------------------------------------------------------- }

  if not ReadUInt16LE(SrcStream, MapId) then
    raise Exception.Create('Błąd nagłówka mapy: map_id.');

  if not ReadUInt16LE(SrcStream, FrameId) then
    raise Exception.Create('Błąd nagłówka mapy: frame_id.');

  if SrcStream.Position >= SrcStream.Size then
    raise Exception.Create('Błąd nagłówka mapy: frame_type.');

  SrcStream.ReadBuffer(FrameType, 1);

  if not ReadInt16LE(SrcStream, RobotX) then
    raise Exception.Create('Błąd nagłówka mapy: robot X.');

  if not ReadInt16LE(SrcStream, RobotY) then
    raise Exception.Create('Błąd nagłówka mapy: robot Y.');

  if not ReadInt16LE(SrcStream, RobotA) then
    raise Exception.Create('Błąd nagłówka mapy: robot angle.');

  if not ReadInt16LE(SrcStream, ChargerX) then
    raise Exception.Create('Błąd nagłówka mapy: charger X.');

  if not ReadInt16LE(SrcStream, ChargerY) then
    raise Exception.Create('Błąd nagłówka mapy: charger Y.');

  if not ReadInt16LE(SrcStream, ChargerA) then
    raise Exception.Create('Błąd nagłówka mapy: charger angle.');

  if not ReadUInt16LE(SrcStream, GridSizeMm) then
    raise Exception.Create('Błąd nagłówka mapy: grid size.');

  if not ReadUInt16LE(SrcStream, MapWidth) then
    raise Exception.Create('Błąd nagłówka mapy: width.');

  if not ReadUInt16LE(SrcStream, MapHeight) then
    raise Exception.Create('Błąd nagłówka mapy: height.');

  if not ReadInt16LE(SrcStream, MapLeft) then
    raise Exception.Create('Błąd nagłówka mapy: left.');

  if not ReadInt16LE(SrcStream, MapTop) then
    raise Exception.Create('Błąd nagłówka mapy: top.');

  if MapWidth = 0 then
    raise Exception.Create('Mapa ma szerokość 0.');

  if MapHeight = 0 then
    raise Exception.Create('Mapa ma wysokość 0.');

  ImageSize := 27 + Int64(MapWidth) * Int64(MapHeight);

  if ImageSize > SrcStream.Size then
    raise Exception.Create(Format('Niepełna mapa. Header wymaga %d bajtów, otrzymano %d.', [ImageSize, SrcStream.Size]));

  { ---------------------------------------------------------
    Zapis danych nagłówka do pól formularza
    --------------------------------------------------------- }

  Header_MapId := MapId;
  Header_FrameId := FrameId;
  Header_FrameType := FrameType;

  Robot_X := RobotX;
  Robot_Y := RobotY;
  Robot_A := RobotA;

  Charger_X := ChargerX;
  Charger_Y := ChargerY;
  Charger_A := ChargerA;

  GridSize := GridSizeMm;

  if GridSize = 0 then GridSize := 50;

  Width := MapWidth;
  Height := MapHeight;

  Left := MapLeft;
  Top := MapTop;

  FMapWidth := MapWidth;
  FMapHeight := MapHeight;
  FMapResolution := GridSize;

  FOffsetX := MapLeft;
  FOffsetY := MapTop;

  FMapId := MapId;

  G_MinX := MapLeft;
  G_MinY := MapTop;
  G_MaxX := MapLeft + (MapWidth * GridSize);

  G_MaxY := MapTop + (MapHeight * GridSize);

  SetLength(PixelData, Integer(MapWidth) * Integer(MapHeight));

  SrcStream.Position := 27;

  SrcStream.ReadBuffer(PixelData[0], Length(PixelData));

  SetLength(FGlobalPixelMap, MapHeight);

  for Y := 0 to MapHeight - 1 do
    SetLength(FGlobalPixelMap[Y], MapWidth);

  DestBmp.PixelFormat := pf32bit;

  DestBmp.SetSize(MapWidth, MapHeight);

  DestBmp.Canvas.Brush.Color := RGB(32, 32, 32);

  DestBmp.Canvas.FillRect(Rect(0, 0, MapWidth, MapHeight));

  for Y := 0 to MapHeight - 1 do
  begin
    RowPointer := DestBmp.ScanLine[MapHeight - Y - 1];

    for X := 0 to MapWidth - 1 do
    begin
      PixelIndex := (Y * MapWidth) + X;
      Pixel := PixelData[PixelIndex];
      FGlobalPixelMap[Y][X] := Pixel;
      SegmentId := Pixel and $3F;
      IsWall := (Pixel and $80) <> 0;
      IsFloor := SegmentId > 0;

      { OUTSIDE }
      if Pixel = 0 then
      begin
        RowPointer^.rgbRed := 32;
        RowPointer^.rgbGreen := 32;
        RowPointer^.rgbBlue := 32;
      end

      { WALL / BORDER }
      else if IsWall then
      begin
        RowPointer^.rgbRed := 125;
        RowPointer^.rgbGreen := 125;
        RowPointer^.rgbBlue := 125;
      end

      { FLOOR / ROOM }
      else if IsFloor then
      begin
        if SegmentId = 63 then
        begin
          RowPointer^.rgbRed := 225;
          RowPointer^.rgbGreen := 225;
          RowPointer^.rgbBlue := 225;
        end
        else
        begin
          RowPointer^.rgbRed := 135 + ((SegmentId * 17) mod 45);
          RowPointer^.rgbGreen := 175 + ((SegmentId * 11) mod 35);
          RowPointer^.rgbBlue := 225 + ((SegmentId * 3) mod 25);
        end;
      end

      else
      begin
        RowPointer^.rgbRed := 32;
        RowPointer^.rgbGreen := 32;
        RowPointer^.rgbBlue := 32;
      end;

      RowPointer^.rgbReserved := 255;
      Inc(RowPointer);
    end;
  end;

  PixelX := Round((RobotY - MapTop) / GridSize);
  PixelY := MapHeight - Round((RobotX - MapLeft) / GridSize) - 1;

  if
    (PixelX >= 0) and
    (PixelX < MapWidth) and
    (PixelY >= 0) and
    (PixelY < MapHeight)
  then
  begin
    DestBmp.Canvas.Brush.Color := clRed;
    DestBmp.Canvas.Pen.Color := clWhite;
    DestBmp.Canvas.Pen.Width := 1;

    DestBmp.Canvas.Ellipse(
      PixelX - 5,
      PixelY - 5,
      PixelX + 5,
      PixelY + 5
    );
  end;
end;


  function ExtractObjectName(const JsonStr: string): string;
    var
      J, Data, Res: TJSONObject;
      Arr: TJSONArray;
      I: Integer;
    begin
      Result := '';

      J := TJSONObject.ParseJSONValue(JsonStr) as TJSONObject;
      try
        if not Assigned(J) then Exit;

        Data := J.GetValue('data') as TJSONObject;
        if not Assigned(Data) then Exit;

        Res := Data.GetValue('result') as TJSONObject;
        if not Assigned(Res) then Exit;

        Arr := Res.GetValue('out') as TJSONArray;
        if not Assigned(Arr) then Exit;

        for I := 0 to Arr.Count - 1 do
        begin
          if Arr.Items[I] is TJSONObject then
          begin
            if TJSONObject(Arr.Items[I]).GetValue<Integer>('piid') = 3 then
            begin
              Result := TJSONObject(Arr.Items[I]).GetValue<string>('value');
              Exit;
            end;
          end;
        end;

      finally
        J.Free;
      end;
    end;

procedure TForm4.AutomatycznePobieranieMapy;
var
  LocalDid: string;
  LocalToken: string;
  LocalTenant: string;
  LocalUserAgent: string;
  LocalShard: string;
  TargetURL: string;
begin
  if Form1.FKeyToken.IsEmpty then
  begin
    Form1.Memo1.Lines.Add('BŁĄD MAPY: brak FKeyToken.');
    Exit;
  end;

  if Form1.FSelectedDid.IsEmpty then
  begin
    Form1.Memo1.Lines.Add('BŁĄD MAPY: brak DID.');
    Exit;
  end;

  if Form1.FTenantId.IsEmpty then
  begin
    Form1.Memo1.Lines.Add('BŁĄD MAPY: brak TenantId.');
    Exit;
  end;

  LocalDid := Form1.FSelectedDid;
  LocalToken := Form1.FKeyToken;
  LocalTenant := Form1.FTenantId;
  LocalUserAgent := Form1.USER_AGENT;

  LocalShard := Form1.FSelectedShard;
  if LocalShard.IsEmpty then LocalShard := '10000';

  TargetURL := Form1.GetBaseUrl(Form1.ComboBox2.Text) +
    '/dreame-iot-com-' + LocalShard + '/device/sendCommand';

  Form1.Memo1.Lines.Add('===');
  Form1.Memo1.Lines.Add('POBIERANIE AKTUALNEJ MAPY');
  Form1.Memo1.Lines.Add('DID: ' + LocalDid);
  Form1.Memo1.Lines.Add('Shard: ' + LocalShard);

  TTask.Run(procedure var
      HTTP: TNetHTTPClient;
      DownloadHTTP: TNetHTTPClient;
      Response: IHTTPResponse;

      RequestBody: TStringStream;
      ResponseBody: string;

      ReqObj: TJSONObject;
      DataObj: TJSONObject;
      ParamsObj: TJSONObject;

      ParamsArray: TJSONArray;
      PropertiesArray: TJSONArray;

      RespJSON: TJSONObject;
      RespData: TJSONObject;
      ResultArray: TJSONArray;

      Item: TJSONObject;

      ActiveMapId: Integer;

      MapRequest: TJSONObject;
      MapDataObj: TJSONObject;
      MapParamsObj: TJSONObject;
      MapParamsArray: TJSONArray;

      MapResponse: string;
      ObjectName: string;
      MapKey: string;

      DownloadReq: TJSONObject;
      DownloadResponse: TStringStream;

      DownloadURL: string;

      RawDownload: TStringStream;

      Base64Text: string;
      Base64Bytes: TBytes;

      EncryptedStream: TMemoryStream;
      DecryptedStream: TMemoryStream;
      DecompressedStream: TMemoryStream;

      ZStream: TZDecompressionStream;

      Bitmap: TBitmap;

      I: Integer;

  function PostJSON( const URL: string; const JSON: string): string;
  var
    Req: TStringStream;
    RespStream: TStringStream;
    Resp: IHTTPResponse;
      begin
        Result := '';

        Req := TStringStream.Create(JSON, TEncoding.UTF8);
        RespStream := TStringStream.Create('', TEncoding.UTF8);

        try
          Resp := HTTP.Post(URL, Req, RespStream);

          if Assigned(Resp) then
          begin
            if Resp.StatusCode = 200 then
              Result := RespStream.DataString;
          end;

        finally
          Req.Free;
          RespStream.Free;
        end;
      end;

    begin
      HTTP := nil;
      DownloadHTTP := nil;
      RequestBody := nil;
      RawDownload := nil;
      EncryptedStream := nil;
      DecryptedStream := nil;
      DecompressedStream := nil;
      Bitmap := nil;

      try
        HTTP := TNetHTTPClient.Create(nil);
        HTTP.ConnectionTimeout := 20000;
        HTTP.ResponseTimeout := 30000;
        HTTP.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
        HTTP.OnValidateServerCertificate := OminWalidacjeSSL;

        HTTP.CustomHeaders['Content-Type'] := 'application/json';
        HTTP.CustomHeaders['User-Agent'] := LocalUserAgent;
        HTTP.CustomHeaders['Authorization'] := 'bearer ' + LocalToken;
        HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + LocalToken;
        HTTP.CustomHeaders['Tenant-Id'] := LocalTenant;

        ActiveMapId := -1;

        ReqObj := TJSONObject.Create;

        try
          ReqObj.AddPair('did', LocalDid);
          ReqObj.AddPair('id', TJSONNumber.Create(7001));

          DataObj := TJSONObject.Create;
          DataObj.AddPair('did', LocalDid);
          DataObj.AddPair('id', TJSONNumber.Create(7001));
          DataObj.AddPair('method', 'get_properties');

          PropertiesArray := TJSONArray.Create;
          ParamsObj := TJSONObject.Create;
          ParamsObj.AddPair('siid', TJSONNumber.Create(4));
          ParamsObj.AddPair('piid', TJSONNumber.Create(1));

          PropertiesArray.AddElement(ParamsObj);
          DataObj.AddPair('params', PropertiesArray);
          DataObj.AddPair('From', 'app');

          ReqObj.AddPair('data', DataObj);
          ResponseBody := PostJSON(TargetURL, ReqObj.ToJSON);

        finally
          ReqObj.Free;
        end;

        if ResponseBody.IsEmpty then
          raise Exception.Create('Nie otrzymano odpowiedzi get_properties.');

        RespJSON := TJSONObject.ParseJSONValue(ResponseBody) as TJSONObject;

        if not Assigned(RespJSON) then
          raise Exception.Create('Nieprawidłowy JSON get_properties.');

        try
          RespData := RespJSON.GetValue('data') as TJSONObject;

          if not Assigned(RespData) then
            raise Exception.Create('Brak data w odpowiedzi get_properties.');

          ResultArray := RespData.GetValue('result') as TJSONArray;

          if not Assigned(ResultArray) then
            raise Exception.Create('Brak result w get_properties.');

          for I := 0 to ResultArray.Count - 1 do
          begin
            Item := ResultArray.Items[I] as TJSONObject;

            if not Assigned(Item) then Continue;

            if
              Item.GetValue<Integer>('piid') = 1 then
            begin
              if
                Item.GetValue<Integer>('siid') = 4
              then
              begin
                ActiveMapId := StrToIntDef(Item.GetValue<string>('value'), -1);
                Break;
              end;
            end;
          end;

        finally
          RespJSON.Free;
        end;

        if ActiveMapId < 0 then
          raise Exception.Create('Nie udało się pobrać aktywnego map_id.');

        FCurrentMapIdFromCloud := ActiveMapId;
        Form1.Memo1.Lines.Add('Aktualne map_id: ' + IntToStr(ActiveMapId));

        MapRequest := TJSONObject.Create;

        try
          MapRequest.AddPair('req_type', TJSONNumber.Create(1));
          MapRequest.AddPair('frame_type', 'I');
          MapRequest.AddPair('force_type', TJSONNumber.Create(1));
          MapRequest.AddPair('map_id', TJSONNumber.Create(ActiveMapId));
          MapDataObj := TJSONObject.Create;
          MapDataObj.AddPair('did', LocalDid);
          MapDataObj.AddPair('id', TJSONNumber.Create(7101));
          MapDataObj.AddPair('method', 'action');
          MapParamsObj := TJSONObject.Create;
          MapParamsObj.AddPair('did', LocalDid);
          MapParamsObj.AddPair('siid', TJSONNumber.Create(6));
          MapParamsObj.AddPair('aiid', TJSONNumber.Create(1));
          MapParamsArray := TJSONArray.Create;

          ParamsObj := TJSONObject.Create;
          ParamsObj.AddPair('piid', TJSONNumber.Create(2));
          ParamsObj.AddPair('value', MapRequest.ToJSON);

          MapParamsArray.AddElement(ParamsObj);
          MapParamsObj.AddPair('in', MapParamsArray);
          MapDataObj.AddPair('params', MapParamsObj);

          ReqObj := TJSONObject.Create;
          ReqObj.AddPair('did', LocalDid);
          ReqObj.AddPair('id', TJSONNumber.Create(7101));
          ReqObj.AddPair('data', MapDataObj);

          ResponseBody := PostJSON(TargetURL, ReqObj.ToJSON);

          ReqObj.Free;
          ReqObj := nil;

        finally
          MapRequest.Free;
        end;

        if ResponseBody.IsEmpty then
          raise Exception.Create('Brak odpowiedzi map_request.');

        RespJSON := TJSONObject.ParseJSONValue(ResponseBody) as TJSONObject;

        if not Assigned(RespJSON) then
          raise Exception.Create('Nieprawidłowy JSON map_request.');

        try
          RespData := RespJSON.GetValue('data') as TJSONObject;

          if not Assigned(RespData) then
            raise Exception.Create('Brak data w map_request.');

          ResultArray := RespData.GetValue('result') as TJSONArray;

          if not Assigned(ResultArray) then
            raise Exception.Create('Brak result w map_request.');

          ObjectName := '';

          for I := 0 to ResultArray.Count - 1 do
          begin
            Item := ResultArray.Items[I] as TJSONObject;
            if not Assigned(Item) then Continue;

            if Item.GetValue<Integer>('piid') = 3 then
            begin
              ObjectName := Item.GetValue<string>('value');
              Break;
            end;
          end;

        finally
          RespJSON.Free;
        end;

        if ObjectName.IsEmpty then
          raise Exception.Create('Chmura nie zwróciła object_name mapy.');

        Form1.Memo1.Lines.Add('object_name: ' + ObjectName);
        MapKey := '';

        I := ObjectName.IndexOf(',');

        if I >= 0 then
        begin
          MapKey := Copy(ObjectName, I + 2, MaxInt);
          ObjectName := Copy(ObjectName, 1, I);
        end;

        MapKey := Trim(MapKey);

        if MapKey.IsEmpty then
          raise Exception.Create('object_name nie zawiera klucza AES.');

        Form1.Memo1.Lines.Add('Klucz mapy został wykryty.');

        DownloadReq := TJSONObject.Create;

        try
          DownloadReq.AddPair('did', LocalDid);
          DownloadReq.AddPair('filename', ObjectName);
          DownloadReq.AddPair('model', Form1.FSelectedModel);
          DownloadResponse :=TStringStream.Create('', TEncoding.UTF8);

          try
            Response := HTTP.Post(Form1.GetBaseUrl(Form1.ComboBox2.Text) +
                '/dreame-user-iot/iotfile/getDownloadUrl',
                TStringStream.Create(DownloadReq.ToJSON, TEncoding.UTF8), DownloadResponse);

            if
              (not Assigned(Response)) or (Response.StatusCode <> 200)
            then
              raise Exception.Create('getDownloadUrl HTTP ' + IntToStr(Response.StatusCode));

            RespJSON := TJSONObject.ParseJSONValue(DownloadResponse.DataString) as TJSONObject;

            try
              if not Assigned(RespJSON) then
                raise Exception.Create('Nieprawidłowa odpowiedź getDownloadUrl.');

              if not RespJSON.TryGetValue<string>('data', DownloadURL) then DownloadURL := '';

            finally
              RespJSON.Free;
            end;

          finally
            DownloadResponse.Free;
          end;

        finally
          DownloadReq.Free;
        end;

        if DownloadURL.IsEmpty then
          raise Exception.Create('getDownloadUrl nie zwrócił URL.');

        Form1.Memo1.Lines.Add('URL mapy otrzymany.');

        RawDownload := TStringStream.Create('', TEncoding.ASCII);
        DownloadHTTP := TNetHTTPClient.Create(nil);

        try
          DownloadHTTP.ConnectionTimeout := 30000;
          DownloadHTTP.ResponseTimeout := 60000;
          DownloadHTTP.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
          DownloadHTTP.OnValidateServerCertificate := OminWalidacjeSSL;
          DownloadHTTP.UserAgent := LocalUserAgent;

          Response := DownloadHTTP.Get(DownloadURL, RawDownload);

          if not Assigned(Response) then
            raise Exception.Create('Pobranie mapy: brak odpowiedzi HTTP.');

          if Response.StatusCode <> 200 then
            raise Exception.Create('Pobranie mapy HTTP ' + IntToStr(Response.StatusCode));

          Base64Text := Trim(RawDownload.DataString);

        finally
          RawDownload.Free;
          DownloadHTTP.Free;
          DownloadHTTP := nil;
        end;

        Base64Text := Base64Text
            .Replace('-', '+')
            .Replace('_', '/')
            .Replace(#13, '')
            .Replace(#10, '')
            .Replace(' ', '')
            .Trim;

        while
          (Length(Base64Text) mod 4) <> 0
        do
          Base64Text := Base64Text + '=';

        Base64Bytes := TNetEncoding.Base64.Decode(TEncoding.ASCII.GetBytes(Base64Text));

        if Length(Base64Bytes) = 0 then
          raise Exception.Create('Base64 mapy jest pusty.');

        EncryptedStream := TMemoryStream.Create;
        EncryptedStream.WriteBuffer(Base64Bytes[0], Length(Base64Bytes));
        EncryptedStream.Position := 0;

        DecryptedStream := TMemoryStream.Create;

        DecryptDreameMapAes(EncryptedStream, DecryptedStream, MapKey);

        if DecryptedStream.Size = 0 then
          raise Exception.Create('AES zwrócił pustą mapę.');

        DecompressedStream := TMemoryStream.Create;
        DecryptedStream.Position := 0;

        ZStream := TZDecompressionStream.Create(DecryptedStream);

        try
          DecompressedStream.CopyFrom(ZStream, 0);
        finally
          ZStream.Free;
        end;

        if DecompressedStream.Size < 27 then
          raise Exception.Create(Format('Po ZLIB otrzymano tylko %d bajtów.', [DecompressedStream.Size]));

        DecompressedStream.Position := 0;
        Form1.Memo1.Lines.Add('Mapa odszyfrowana i rozpakowana: ' + IntToStr(DecompressedStream.Size) + ' B');

        Bitmap := TBitmap.Create;
        ParseDreameMap(DecompressedStream, Bitmap);

        if
          (Bitmap.Width = 0) or (Bitmap.Height = 0)
        then
          raise Exception.Create('Renderer utworzył pustą bitmapę.');

        TThread.Synchronize(nil,
          procedure
          begin
            if Assigned(FBufferBitmap) then
              FBufferBitmap.Free;
              FBufferBitmap := TBitmap.Create;
              FBufferBitmap.Assign(Bitmap);

            PaintBox1.Invalidate;
            PaintBox1.Repaint;

            Form1.Memo1.Lines.Add('===');
            Form1.Memo1.Lines.Add('MAPA WYSWIETLONA PRAWIDLOWO');
            Form1.Memo1.Lines.Add(Format('Rozmiar: %d x %d', [Bitmap.Width, Bitmap.Height]));
            Form1.Memo1.Lines.Add('===');
          end
        );

      except
        on E: Exception do
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              Form1.Memo1.Lines.Add('BŁĄD MAPY: ' + E.Message);
            end
          );
        end;
      end;

      Bitmap.Free;
      EncryptedStream.Free;
      DecryptedStream.Free;
      DecompressedStream.Free;
      HTTP.Free;
    end
  );
end;

// --------- Rysowanie mapy ---------
procedure TForm4.PaintBox1Paint(Sender: TObject);
var
  I: Integer;
  P1, P2: TPoint;
  RobotPixelPt, ChargerPixelPt: TPoint;
  Zone: TDreameZone;
  Wall: TDreameWall;
  List: TList;
  MapRect: TRect;
  WspolczynnikAspect: Double;
  NowyW, NowyH: Integer;
begin
  // ZABEZPIECZENIE: Jeśli brak bitmapy w pamięci, malujemy tło i wychodzimy
  if (PaintBox1.Width <= 0) or (PaintBox1.Height <= 0) or (FBufferBitmap = nil) then
  begin
    PaintBox1.Canvas.Brush.Color := RGB(32, 32, 32);
    PaintBox1.Canvas.FillRect(Rect(0, 0, PaintBox1.Width, PaintBox1.Height));
    Exit;
  end;

  // Główny podkład czyszczący PaintBoxa pod spód wszystkich warstw
  PaintBox1.Canvas.Brush.Color := RGB(32, 32, 32);
  PaintBox1.Canvas.FillRect(Rect(0, 0, PaintBox1.Width, PaintBox1.Height));

  // ==========================================================
  // 1. RYSUJEMY MAPĘ Z ZACHOWANIEM PROPORCJI (ASPECT RATIO) MIESZKANIA
  // ==========================================================
  if (FBufferBitmap.Width > 0) and (FBufferBitmap.Height > 0) then
  begin
    WspolczynnikAspect := FBufferBitmap.Width / FBufferBitmap.Height;

    if (PaintBox1.Width / PaintBox1.Height) > WspolczynnikAspect then
    begin
      NowyH := PaintBox1.Height;
      NowyW := Round(NowyH * WspolczynnikAspect);
      MapRect := Rect((PaintBox1.Width - NowyW) div 2, 0, ((PaintBox1.Width - NowyW) div 2) + NowyW, NowyH);
    end
    else
    begin
      NowyW := PaintBox1.Width;
      NowyH := Round(NowyW / WspolczynnikAspect);
      MapRect := Rect(0, (PaintBox1.Height - NowyH) div 2, NowyW, ((PaintBox1.Height - NowyH) div 2) + NowyH);
    end;

    // Rysowanie zdekodowanej wektorowo mapy z FBufferBitmap na płótno PaintBoxa
    PaintBox1.Canvas.StretchDraw(MapRect, FBufferBitmap);
  end;

  // Blokowanie rysowania stylów pędzla dla nałożenia linii wektorowych
  PaintBox1.Canvas.Brush.Style := bsClear;

  // ==========================================================
  // 2. Rysowanie wirtualnych ścian (FWallsList) - Nakładka UI
  // ==========================================================
  List := FWallsList.LockList;
  try
    PaintBox1.Canvas.Pen.Color := clRed;
    PaintBox1.Canvas.Pen.Width := 3;
    PaintBox1.Canvas.Pen.Style := psSolid;
    for I := 0 to List.Count - 1 do
    begin
      Wall := PDreameWall(List[I])^;
      P1 := RobotMmToPixel(Wall.X1, Wall.Y1);
      P2 := RobotMmToPixel(Wall.X2, Wall.Y2);
      PaintBox1.Canvas.MoveTo(P1.X, P1.Y);
      PaintBox1.Canvas.LineTo(P2.X, P2.Y);
    end;
  finally
    FWallsList.UnlockList;
  end;

  // ==========================================================
  // 3. Rysowanie stref zabronionych (FZonesList) - Nakładka UI
  // ==========================================================
  List := FZonesList.LockList;
  try
    for I := 0 to List.Count - 1 do
    begin
      Zone := PDreameZone(List[I])^;
      case Zone.ZoneType of
        0: begin // Strefa zakazana (Czerwona)
          PaintBox1.Canvas.Pen.Color := clRed;
          PaintBox1.Canvas.Brush.Color := RGB(255, 100, 100);
        end;
        1: begin // Strefa bez mopa (Niebieska)
          PaintBox1.Canvas.Pen.Color := clBlue;
          PaintBox1.Canvas.Brush.Color := RGB(100, 150, 255);
        end;
        2: begin // Wirtualna ściana / specjalna (Pomarańczowa)
          PaintBox1.Canvas.Pen.Color := RGB(255, 165, 0);
          PaintBox1.Canvas.Brush.Color := RGB(255, 200, 100);
        end;
      end;
      PaintBox1.Canvas.Brush.Style := bsSolid;

      PaintBox1.Canvas.Polygon([
        RobotMmToPixel(Zone.Points[0].X, Zone.Points[0].Y),
        RobotMmToPixel(Zone.Points[1].X, Zone.Points[1].Y),
        RobotMmToPixel(Zone.Points[2].X, Zone.Points[2].Y),
        RobotMmToPixel(Zone.Points[3].X, Zone.Points[3].Y)
      ]);
    end;
  finally
    FZonesList.UnlockList;
  end;

  // ==========================================================
  // 4. Rysowanie przeciąganego prostokąta selekcji użytkownika
  // ==========================================================
  if FIsDrawing then
  begin
    PaintBox1.Canvas.Pen.Color := clGreen;
    PaintBox1.Canvas.Pen.Width := 2;
    PaintBox1.Canvas.Brush.Style := bsClear;
    PaintBox1.Canvas.Rectangle(FStartMousePt.X, FStartMousePt.Y, FCurrentMousePt.X, FCurrentMousePt.Y);
  end;

  // ==========================================================
  // 5. NAKŁADANIE DYNAMICZNYCH PUNKTÓW URZĄDZENIA - Dokładna pozycja świata
  // ==========================================================
  RobotPixelPt := RobotMmToPixel(Robot_X, Robot_Y);
  ChargerPixelPt := RobotMmToPixel(Charger_X, Charger_Y);

  // Rysowanie stacji bazowej (Niebieski kwadracik)
  PaintBox1.Canvas.Brush.Color := clBlue;
  PaintBox1.Canvas.Brush.Style := bsSolid;
  PaintBox1.Canvas.Pen.Color := clBlack;
  PaintBox1.Canvas.Pen.Style := psSolid;
  PaintBox1.Canvas.FillRect(Rect(ChargerPixelPt.X - 5, ChargerPixelPt.Y - 5, ChargerPixelPt.X + 5, ChargerPixelPt.Y + 5));

  // Rysowanie pozycji Robota (Czerwone koło)
  PaintBox1.Canvas.Brush.Color := clRed;
  PaintBox1.Canvas.Ellipse(RobotPixelPt.X - 7, RobotPixelPt.Y - 7, RobotPixelPt.X + 7, RobotPixelPt.Y + 7);
end;


// konwersja mm na px
function TForm4.RobotMmToPixel(AX, AY: Integer): TPoint;
begin
  if Self.GridSize = 0 then Self.GridSize := 50;

  // Przesunięcie o pozycję startową (Origin) i dzielenie przez wielkość siatki
  Result.X := Round((AX - Self.Left) / Self.GridSize);

  // Odwrócenie osi Y chmury Dreame AIoT dla Canvasa VCL Windows
  Result.Y := Round(Self.Height - ((AY - Self.Top) / Self.GridSize) - 1);
end;

// px na mm
function TForm4.PixelToRobotMm(APx, APy: Integer): TDreamePoint;
var
  GridX, GridY: Integer;
begin
  if Self.FMapResolution = 0 then Self.FMapResolution := 50;
  if (PaintBox1.Width = 0) or (PaintBox1.Height = 0) then Exit;

  // Krok 1: Przeliczenie pikseli kliknięcia kontrolki UI na piksel siatki binarnej mapy
  GridX := Round(APx * (Width / PaintBox1.Width));
  GridY := Round(APy * (Height / PaintBox1.Height));

  // Krok 2: Odwrócenie osi Y dla układu milimetrowego bota
  GridY := Height - GridY - 1;

  // Krok 3: Przeliczenie siatki binarnej na milimetry bota z uwzględnieniem przesunięcia Origin
  Result.X := (GridX * Self.FMapResolution) + Self.FOffsetX;
  Result.Y := (GridY * Self.FMapResolution) + Self.FOffsetY;
end;


procedure TForm4.OminWalidacjeSSL
          (const Sender: TObject; const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: Boolean);
begin
  Accepted := True;
end;


// -----------------------------------------------------------------------
// Deszyfrownie

const
  PROV_RSA_AES = 24;
  CRYPT_VERIFYCONTEXT = $F0000000;
  PLAINTEXTKEYBLOB = $08;
  CALG_AES_256 = $00006610;
  KP_MODE = 4;
  CRYPT_MODE_CBC = 1;
  KP_IV = 1;
  ADVAPI32_DLL = 'advapi32.dll';

function CryptAcquireContext(var phProv: THandle; pszContainer: PWideChar; pszProvider: PWideChar; dwProvType: DWORD; dwFlags: DWORD): LongBool; stdcall; external ADVAPI32_DLL Name 'CryptAcquireContextW';
function CryptImportKey(hProv: THandle; pbData: Pointer; dwDataLen: DWORD; hPubKey: THandle; dwFlags: DWORD; var phKey: THandle): LongBool; stdcall; external ADVAPI32_DLL;
function CryptSetKeyParam(hKey: THandle; dwParam: DWORD; pbData: Pointer; dwFlags: DWORD): LongBool; stdcall; external ADVAPI32_DLL;
function CryptDecrypt(hKey: THandle; hHash: THandle; Final: LongBool; dwFlags: DWORD; pbData: Pointer; var pdwDataLen: DWORD): LongBool; stdcall; external ADVAPI32_DLL;
function CryptDestroyKey(hKey: THandle): LongBool; stdcall; external ADVAPI32_DLL;
function CryptReleaseContext(hProv: THandle; dwFlags: DWORD): LongBool; stdcall; external ADVAPI32_DLL;
//
// -----------------------------------------------------------------------

const
  DREAME_MAP_AES_IV = 'aebf8c52e26a4767';

procedure TForm4.DecryptDreameMapAes(
  ASrcStream, ADestStream: TStream;
  const AMapKey: string
);
const
  PROV_RSA_AES = 24;
  CRYPT_VERIFYCONTEXT = $F0000000;
  PLAINTEXTKEYBLOB = $08;
  CALG_AES_256 = $00006610;
  KP_MODE = 4;
  CRYPT_MODE_CBC = 1;
  KP_IV = 1;
  ADVAPI32_DLL = 'advapi32.dll';

type
  TKeyBlobHeader = packed record
    bType: Byte;
    bVersion: Byte;
    reserved: Word;
    aiKeyAlg: Cardinal;
  end;

  TKeyBlob = packed record
    Header: TKeyBlobHeader;
    KeyLen: Cardinal;
    KeyBytes: array[0..31] of Byte;
  end;

var
  Provider: THandle;
  KeyHandle: THandle;
  HashString: string;
  KeyBytes: TBytes;
  EncryptedData: TBytes;
  DecryptedData: TBytes;
  IV: array[0..15] of Byte;
  KeyBlob: TKeyBlob;
  Mode: DWORD;
  DataLen: DWORD;
  I: Integer;
begin
  ADestStream.Size := 0;
  ADestStream.Position := 0;

  if (ASrcStream = nil) or
     (ASrcStream.Size = 0) or
     AMapKey.IsEmpty then
    raise Exception.Create('Brak danych lub klucza AES mapy.');

  ASrcStream.Position := 0;

  SetLength(EncryptedData, ASrcStream.Size);
  ASrcStream.ReadBuffer(
    EncryptedData[0],
    Length(EncryptedData)
  );

  if (Length(EncryptedData) = 0) then
    raise Exception.Create('Pusty bufor szyfrowanej mapy.');

  if (Length(EncryptedData) mod 16 <> 0) then
    raise Exception.Create(
      Format(
        'Nieprawidłowa długość AES: %d bajtów.',
        [Length(EncryptedData)]
      )
    );

  HashString :=
    THashSHA2.GetHashString(AMapKey, SHA256).ToLower;

  if Length(HashString) < 32 then
    raise Exception.Create('Nie udało się utworzyć klucza SHA256.');

  HashString := Copy(HashString, 1, 32);
  KeyBytes := TEncoding.ASCII.GetBytes(HashString);

  if Length(KeyBytes) <> 32 then
    raise Exception.Create('Klucz AES nie ma 32 bajtów.');

  FillChar(IV, SizeOf(IV), 0);

  for I := 0 to Length(DREAME_MAP_AES_IV) - 1 do
    IV[I] := Ord(DREAME_MAP_AES_IV[I + 1]);

  FillChar(KeyBlob, SizeOf(KeyBlob), 0);

  KeyBlob.Header.bType := PLAINTEXTKEYBLOB;
  KeyBlob.Header.bVersion := 2;
  KeyBlob.Header.reserved := 0;
  KeyBlob.Header.aiKeyAlg := CALG_AES_256;
  KeyBlob.KeyLen := 32;

  Move(
    KeyBytes[0],
    KeyBlob.KeyBytes[0],
    32
  );

  if not CryptAcquireContext(
    Provider,
    nil,
    nil,
    PROV_RSA_AES,
    CRYPT_VERIFYCONTEXT
  ) then
    RaiseLastOSError;

  try
    if not CryptImportKey(
      Provider,
      @KeyBlob,
      SizeOf(KeyBlob),
      0,
      0,
      KeyHandle
    ) then
      RaiseLastOSError;

    try
      Mode := CRYPT_MODE_CBC;

      if not CryptSetKeyParam(
        KeyHandle,
        KP_MODE,
        @Mode,
        0
      ) then
        RaiseLastOSError;

      if not CryptSetKeyParam(
        KeyHandle,
        KP_IV,
        @IV[0],
        0
      ) then
        RaiseLastOSError;

      DecryptedData := Copy(EncryptedData);

      DataLen := Length(DecryptedData);

      if not CryptDecrypt(
        KeyHandle,
        0,
        True,
        0,
        @DecryptedData[0],
        DataLen
      ) then
        RaiseLastOSError;

      if DataLen = 0 then
        raise Exception.Create(
          'AES zwrócił pusty bufor.'
        );

      ADestStream.WriteBuffer(
        DecryptedData[0],
        DataLen
      );

      ADestStream.Position := 0;

    finally
      CryptDestroyKey(KeyHandle);
    end;

  finally
    CryptReleaseContext(Provider, 0);
  end;
end;

procedure TForm4.DaneRobota;
var
  LocalDid, LocalShard, TargetURL, LocalToken, LocalTenant, LocalUserAgent: string;
begin
  if Form1.FKeyToken.IsEmpty or Form1.FTenantId.IsEmpty or Form1.FSelectedDid.IsEmpty then Exit;

  LocalDid := Form1.FSelectedDid;
  LocalToken := Form1.FKeyToken;
  LocalTenant := Form1.FTenantId;
  LocalUserAgent := Form1.USER_AGENT;

  LocalShard := Form1.FSelectedShard;
  if LocalShard.IsEmpty then LocalShard := '10000';

  TargetURL := Form1.GetBaseUrl(Form1.Combobox2.Text) + '/dreame-iot-com-' + LocalShard + '/device/sendCommand';

  Form1.Memo1.Lines.Add('=ZASOBY URZĄDZENIA=');

  TTask.Run(
    procedure
    var
      HTTP: TNetHTTPClient;
      Response: IHTTPResponse;
      ReqObj, DataObjRPC, ParamObj, FinalParamsObj: TJSONObject;
      ParamsArr: TJSONArray;
      PayloadStr, ResBody, CiasnyValueString, ObjectMapName: string;
      ResponseStream: TStringStream;
      RespJSON, DataObj, ItemObj, DataRespObj, ExtractedJsonObj: TJSONObject;
      ResultArr, ResultRespArr: TJSONArray;
      Idx, V_Piid: Integer;
      V_Value: string;
      ItemVal: TJSONValue;
      ActiveMapId: Integer;
    begin
      HTTP := TNetHTTPClient.Create(nil);
      try
        HTTP.ConnectionTimeout := 15000;
        HTTP.ResponseTimeout := 15000;

        HTTP.CustomHeaders['Content-Type'] := 'application/json';
        HTTP.CustomHeaders['User-Agent'] := LocalUserAgent;
        HTTP.CustomHeaders['Authorization'] := 'bearer ' + LocalToken;
        HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + LocalToken;
        HTTP.CustomHeaders['Tenant-Id'] := LocalTenant;

        // CZĘŚĆ 1: Odczyt pamięci zużycia i parametrów sprzętowych robota

        ReqObj := TJSONObject.Create;
        try
          ReqObj.AddPair('did', LocalDid);
          ReqObj.AddPair('id', TJSONNumber.Create(8888));

          DataObjRPC := TJSONObject.Create;
          DataObjRPC.AddPair('did', LocalDid);
          DataObjRPC.AddPair('id', TJSONNumber.Create(8888));
          DataObjRPC.AddPair('method', 'get_properties');

          ParamsArr := TJSONArray.Create;
          ParamObj := TJSONObject.Create; ParamObj.AddPair('siid', TJSONNumber.Create(4)); ParamObj.AddPair('piid', TJSONNumber.Create(1)); ParamsArr.AddElement(ParamObj);
          ParamObj := TJSONObject.Create; ParamObj.AddPair('siid', TJSONNumber.Create(4)); ParamObj.AddPair('piid', TJSONNumber.Create(5)); ParamsArr.AddElement(ParamObj);
          ParamObj := TJSONObject.Create; ParamObj.AddPair('siid', TJSONNumber.Create(4)); ParamObj.AddPair('piid', TJSONNumber.Create(7)); ParamsArr.AddElement(ParamObj);
          ParamObj := TJSONObject.Create; ParamObj.AddPair('siid', TJSONNumber.Create(4)); ParamObj.AddPair('piid', TJSONNumber.Create(27)); ParamsArr.AddElement(ParamObj);
          ParamObj := TJSONObject.Create; ParamObj.AddPair('siid', TJSONNumber.Create(4)); ParamObj.AddPair('piid', TJSONNumber.Create(28)); ParamsArr.AddElement(ParamObj);
          ParamObj := TJSONObject.Create; ParamObj.AddPair('siid', TJSONNumber.Create(4)); ParamObj.AddPair('piid', TJSONNumber.Create(29)); ParamsArr.AddElement(ParamObj);

          DataObjRPC.AddPair('params', ParamsArr);
          DataObjRPC.AddPair('From', 'app');
          ReqObj.AddPair('data', DataObjRPC.ToJSON.Replace(' ', ''));
          PayloadStr := ReqObj.ToJSON;
        finally
        end;

        ResponseStream := TStringStream.Create('', TEncoding.UTF8);
        try
          Response := HTTP.Post(TargetURL, TStringStream.Create(PayloadStr, TEncoding.UTF8), ResponseStream);
          ResBody := ResponseStream.DataString;
        finally
          ResponseStream.Free;
        end;
        ReqObj.Free;

        if (Response <> nil) and (Response.StatusCode = 200) and (not ResBody.IsEmpty) then
        begin
          RespJSON := TJSONObject.ParseJSONValue(ResBody) as TJSONObject;
          try
            if Assigned(RespJSON) and (RespJSON.GetValue<Integer>('code') = 0) then
            begin
              DataObj := RespJSON.GetValue('data') as TJSONObject;
              if Assigned(DataObj) then
              begin
                ResultArr := DataObj.GetValue('result') as TJSONArray;
                if Assigned(ResultArr) then
                begin
                  for Idx := 0 to ResultArr.Count - 1 do
                  begin
                    ItemObj := ResultArr.Items[Idx] as TJSONObject;
                    if Assigned(ItemObj) and (ItemObj.GetValue<Integer>('code') = 0) then
                    begin
                      //V_Siid := ItemObj.GetValue<Integer>('siid');
                      V_Piid := ItemObj.GetValue<Integer>('piid');
                      V_Value := ItemObj.GetValue('value').Value;

                      TThread.Synchronize(nil, procedure
                      begin
                        case V_Piid of
                           1: begin
                              ActiveMapId := StrToIntDef(V_Value, -1);
                              Form1.Memo1.Lines.Add('ID Aktywnej Mapy: ' + IntToStr(ActiveMapId));
                              ComboBox4.Text :='Mapa ID: ' + IntToStr(ActiveMapId);
                            end;
                          5: Form1.Memo1.Lines.Add('Ilość map w urządzeniu: ' + V_Value);
                          7: Form1.Memo1.Lines.Add('Pozycja robota: ' + V_Value);
                          27: Form1.Memo1.Lines.Add('Zużycie filtra powietrza: ' + V_Value + '%');
                          28: Form1.Memo1.Lines.Add('Zużycie szczotki głównej: ' + V_Value + '%');
                          29: Form1.Memo1.Lines.Add('Zużycie szczotki bocznej: ' + V_Value + '%');
                        end;

                      end);
                    end;
                  end;
                end;
              end;
            end;
          finally
            RespJSON.Free;
          end;
        end;

        // CZĘŚĆ 2: Wymuszenie na obiekcie wykonawczym nazwy pliku mapy (SIID: 6)

        //CiasnyValueString := '{"req_type":1,"frame_type":"I","force_type":1,"map_id":14}'; // Odpytujemy z automatu aktywną mapę 14
        CiasnyValueString := Format('{"req_type":1,"frame_type":"I","force_type":1,"map_id":%d}', [ActiveMapId]);

        FinalParamsObj := TJSONObject.Create;
        FinalParamsObj.AddPair('piid', TJSONNumber.Create(2));
        FinalParamsObj.AddPair('value', CiasnyValueString);

        ParamsArr := TJSONArray.Create;
        ParamsArr.AddElement(FinalParamsObj);

        ParamObj := TJSONObject.Create;
        ParamObj.AddPair('did', LocalDid);
        ParamObj.AddPair('siid', TJSONNumber.Create(6));
        ParamObj.AddPair('aiid', TJSONNumber.Create(1));
        ParamObj.AddPair('in', ParamsArr);

        DataObjRPC := TJSONObject.Create;
        DataObjRPC.AddPair('did', LocalDid);
        DataObjRPC.AddPair('id', TJSONNumber.Create(4567));
        DataObjRPC.AddPair('method', 'action');
        DataObjRPC.AddPair('params', ParamObj);

        ReqObj := TJSONObject.Create;
        ReqObj.AddPair('did', LocalDid);
        ReqObj.AddPair('id', TJSONNumber.Create(4567));
        ReqObj.AddPair('data', DataObjRPC); // Bez spłaszczania w kontenerze pomocniczym, czysty obiekt pod chmurę

        PayloadStr := ReqObj.ToJSON;

        ResponseStream := TStringStream.Create('', TEncoding.UTF8);
        try
          Response := HTTP.Post(TargetURL, TStringStream.Create(PayloadStr, TEncoding.UTF8), ResponseStream);
          ResBody := ResponseStream.DataString;
        finally
          ResponseStream.Free;
        end;
        ReqObj.Free;

        // Parsowanie nazwy pliku z pamięci operacyjnej żądania mapy

        if (Response <> nil) and (Response.StatusCode = 200) then
        begin
          RespJSON := TJSONObject.ParseJSONValue(ResBody) as TJSONObject;
          if Assigned(RespJSON) then
          try
            if RespJSON.TryGetValue('data', DataRespObj) and Assigned(DataRespObj) then
            begin
              if DataRespObj.TryGetValue('result', ExtractedJsonObj) and Assigned(ExtractedJsonObj) then
              begin
                if ExtractedJsonObj.Get('out') <> nil then
                begin
                  ResultRespArr := ExtractedJsonObj.Get('out').JsonValue as TJSONArray;
                  if Assigned(ResultRespArr) then
                  begin
                    for Idx := 0 to ResultRespArr.Count - 1 do
                    begin
                      ItemVal := ResultRespArr.Items[Idx];
                      if Assigned(ItemVal) and (ItemVal is TJSONObject) then
                      begin
                        if TJSONObject(ItemVal).GetValue<Integer>('piid') = 3 then
                        begin
                          ObjectMapName := TJSONObject(ItemVal).GetValue<string>('value');

                          TThread.Synchronize(nil, procedure
                          begin
                            Form1.Memo1.Lines.Add('--- DETEKCJA STRUKTURY PLIKU MAPY ---');
                            Form1.Memo1.Lines.Add('NAZWA PLIKU W PAMIĘCI CHMURY: ' + ObjectMapName);
                            Form1.Memo1.Lines.Add('Ścieżka do pobrania z bramki: ');
                            Form1.Memo1.Lines.Add('Plik konfig (Baza danych geometrii): ' + ObjectMapName + '_patch');
                          end);
                          Break;
                        end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          finally
            RespJSON.Free;
          end;
        end;

      finally
        HTTP.Free;
      end;
    end
  );
end;



procedure TForm4.DiagnozaStrumieniaAIoT(SrcStream: TStream);
var
  I: Integer;
  B: Byte;
  W: Word;
  L: Cardinal;
  //S: SmallInt;
  LogStr: string;
begin
  Form1.Memo1.Lines.Add('=== ROZPOCZĘCIE DIAGNOZY BINARNEJ PLIKU ===');
  if SrcStream = nil then
  begin
    Form1.Memo1.Lines.Add('BŁĄD: Strumień jest pusty!');
    Exit;
  end;

  SrcStream.Position := 0;
  Form1.Memo1.Lines.Add(Format('Całkowity rozmiar pliku po dekompresji ZLIB: %d bajtów', [SrcStream.Size]));

  // Odczyt pierwszych 32 bajtów jako surowe liczby, aby zobaczyć nagłówek
  LogStr := 'Pierwsze 32 bajty (HEX): ';
  for I := 0 to 31 do
  begin
    if SrcStream.Position < SrcStream.Size then
    begin
      SrcStream.ReadBuffer(B, 1);
      LogStr := LogStr + IntToHex(B, 2) + ' ';
    end;
  end;
  Form1.Memo1.Lines.Add(LogStr);

  // Sprawdźmy co leży na offsetach jako potencjalne typy sekcji
  SrcStream.Position := 22;
  if SrcStream.Position + 6 <= SrcStream.Size then
  begin
    SrcStream.ReadBuffer(W, 2); SrcStream.ReadBuffer(L, 4);
    Form1.Memo1.Lines.Add(Format('Offset 22 -> Potencjalny Typ Warstwy: %d (HEX: %.4X), Rozmiar: %d', [W, W, L]));
  end;

  SrcStream.Position := 25;
  if SrcStream.Position + 6 <= SrcStream.Size then
  begin
    SrcStream.ReadBuffer(W, 2); SrcStream.ReadBuffer(L, 4);
    Form1.Memo1.Lines.Add(Format('Offset 25 -> Potencjalny Typ Warstwy: %d (HEX: %.4X), Rozmiar: %d', [W, W, L]));
  end;

  SrcStream.Position := 27;
  if SrcStream.Position + 6 <= SrcStream.Size then
  begin
    SrcStream.ReadBuffer(W, 2); SrcStream.ReadBuffer(L, 4);
    Form1.Memo1.Lines.Add(Format('Offset 27 -> Potencjalny Typ Warstwy: %d (HEX: %.4X), Rozmiar: %d', [W, W, L]));
  end;

  SrcStream.Position := 29;
  if SrcStream.Position + 6 <= SrcStream.Size then
  begin
    SrcStream.ReadBuffer(W, 2); SrcStream.ReadBuffer(L, 4);
    Form1.Memo1.Lines.Add(Format('Offset 29 -> Potencjalny Typ Warstwy: %d (HEX: %.4X), Rozmiar: %d', [W, W, L]));
  end;

  Form1.Memo1.Lines.Add('=== KONIEC DIAGNOZY ===');
end;

end.
