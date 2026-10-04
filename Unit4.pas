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

    procedure DecryptDreameAes(ASrcStream, ADestStream: TStream; const AToken: string);
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

procedure TForm4.ParseDreameMap(SrcStream: TStream; DestBmp: TBitmap);
var
  X, Y, I: Integer;
  CurrentByte: Byte;
  GridBuffer: TBytes;
  GridSizeInPixels: Integer;

  BitSegmentId: Byte;
  BitIsWall, BitIsFloor: Boolean;

  RowPointer: PRGBQuad;
  RawCompressedBytes: TBytes;
  CompressedDataSize: Integer;

  CompressedIdx, UncompressedIdx: Integer;
  RunLength: Integer;
  PixelValue: Byte;

  L_MinX, L_MinY, L_MaxX, L_MaxY: Integer;
  L_BotX, L_BotY, L_BotAngle: Integer;
  W_Buffer: Word;
  S_Buffer: SmallInt;
  B_Buffer: Byte;

  CalculatedWidth: Integer;
  CalculatedHeight: Integer;
  GridIndex: Integer;

  FizycznyPixelX, FizycznyPixelY: Integer;
  ResztaSzerokosci: Integer;
begin
  CompressedDataSize := SrcStream.Size;
  SrcStream.Position := 0;

  if CompressedDataSize < 27 then Exit;

  // ==========================================
  // 1. ODCZYT NAGŁÓWKA GEOMETRII ŚWIATA
  // ==========================================
  SrcStream.ReadBuffer(W_Buffer, 2);
  SrcStream.ReadBuffer(B_Buffer, 1);
  SrcStream.ReadBuffer(B_Buffer, 1);
  SrcStream.ReadBuffer(W_Buffer, 2);

  SrcStream.ReadBuffer(S_Buffer, 2); L_MinX := S_Buffer;
  SrcStream.ReadBuffer(S_Buffer, 2); L_MinY := S_Buffer;
  SrcStream.ReadBuffer(S_Buffer, 2); L_MaxX := S_Buffer;
  SrcStream.ReadBuffer(S_Buffer, 2); L_MaxY := S_Buffer;

  SrcStream.Seek(2, TSeekOrigin.soCurrent);
  SrcStream.ReadBuffer(S_Buffer, 2); L_BotX := S_Buffer;
  SrcStream.ReadBuffer(S_Buffer, 2); L_BotY := S_Buffer;
  SrcStream.ReadBuffer(S_Buffer, 2); L_BotAngle := S_Buffer;

  SrcStream.Seek(27, TSeekOrigin.soBeginning);

  // Wyliczamy surowe wymiary z nagłówka
  CalculatedWidth  := (Abs(L_MaxY - L_MinY) div 50) + 1;
  CalculatedHeight := (Abs(L_MaxX - L_MinX) div 50) + 1;

  // =========================================================================
  // POPRAWKA STRIDE ALIGNMENT:
  // Zaokrąglamy szerokość klatki w górę do najbliższej wielokrotności liczby 16.
  // Zapobiega to przesunięciu pikseli o 1-2 bajty przy przejściu do nowej linii Y,
  // co ostatecznie scali te poziome kreski w gładkie kształty ścian pokoi!
  // =========================================================================
  ResztaSzerokosci := CalculatedWidth mod 16;
  if ResztaSzerokosci > 0 then
    CalculatedWidth := CalculatedWidth + (16 - ResztaSzerokosci);

  GridSizeInPixels := CalculatedWidth * CalculatedHeight;

  Self.GridSize := 50;
  Self.Left := L_MinX;
  Self.Top := L_MinY;
  Self.Robot_X := L_BotX;
  Self.Robot_Y := L_BotY;
  Self.Robot_A := L_BotAngle;
  Self.Charger_X := L_BotX;
  Self.Charger_Y := L_BotY;
  Self.Width := CalculatedWidth;
  Self.Height := CalculatedHeight;

  SetLength(RawCompressedBytes, CompressedDataSize - 27);
  SrcStream.ReadBuffer(RawCompressedBytes, CompressedDataSize - 27);

  // ==========================================
  // 2. ROZPAKOWANIE RLE DO WYRÓWNANEGO BUFORA
  // ==========================================
  SetLength(GridBuffer, GridSizeInPixels);
  CompressedIdx := 0;
  UncompressedIdx := 0;

  while (CompressedIdx < Length(RawCompressedBytes) - 1) and (UncompressedIdx < GridSizeInPixels) do
  begin
    RunLength := RawCompressedBytes[CompressedIdx];
    if RunLength = 0 then
    begin
      if CompressedIdx + 2 >= Length(RawCompressedBytes) then Break;
      RunLength := RawCompressedBytes[CompressedIdx + 1];
      PixelValue := RawCompressedBytes[CompressedIdx + 2];
      Inc(CompressedIdx, 3);
    end
    else
    begin
      PixelValue := RawCompressedBytes[CompressedIdx + 1];
      Inc(CompressedIdx, 2);
    end;

    for I := 0 to RunLength - 1 do
    begin
      if UncompressedIdx >= GridSizeInPixels then Break;
      GridBuffer[UncompressedIdx] := PixelValue;
      Inc(UncompressedIdx);
    end;
  end;

  // Inicjalizacja dwuwymiarowej matrycy logicznej
  SetLength(FGlobalPixelMap, CalculatedHeight);
  for Y := 0 to CalculatedHeight - 1 do
    SetLength(FGlobalPixelMap[Y], CalculatedWidth);

  DestBmp.PixelFormat := pf32bit;
  DestBmp.SetSize(CalculatedWidth, CalculatedHeight);

  // Czyszczenie tła
  DestBmp.Canvas.Brush.Color := RGB(32, 32, 32);
  DestBmp.Canvas.FillRect(Rect(0, 0, CalculatedWidth, CalculatedHeight));

  // ==========================================
  // 3. RENDER SCANLINE Z WYRÓWNANĄ SZEROKOŚCIĄ LINII
  // ==========================================
  for Y := 0 to CalculatedHeight - 1 do
  begin
    RowPointer := DestBmp.ScanLine[Y];
    for X := 0 to CalculatedWidth - 1 do
    begin
      GridIndex := (Y * CalculatedWidth) + X;

      if (GridIndex >= 0) and (GridIndex < UncompressedIdx) then
        CurrentByte := GridBuffer[GridIndex]
      else
        CurrentByte := 0;

      FGlobalPixelMap[Y][X] := CurrentByte;

      if CurrentByte = 0 then
      begin
        RowPointer^.rgbRed := 32;
        RowPointer^.rgbGreen := 32;
        RowPointer^.rgbBlue := 32;
      end
      else
      begin
        BitSegmentId := CurrentByte and $3F;
        BitIsWall    := (CurrentByte and $40) <> 0;
        BitIsFloor   := (CurrentByte and $80) <> 0;

        if BitIsWall then
        begin
          RowPointer^.rgbRed := 140;
          RowPointer^.rgbGreen := 140;
          RowPointer^.rgbBlue := 140;
        end
        else if BitIsFloor then
        begin
          if BitSegmentId = $3F then
          begin
            RowPointer^.rgbRed := 174;
            RowPointer^.rgbGreen := 202;
            RowPointer^.rgbBlue := 247;
          end
          else
          begin
            RowPointer^.rgbRed := 150 + ((BitSegmentId * 15) mod 30);
            RowPointer^.rgbGreen := 180 + ((BitSegmentId * 10) mod 25);
            RowPointer^.rgbBlue := 245;
          end;
        end;
      end;
      RowPointer^.rgbReserved := 255;
      Inc(RowPointer);
    end;
  end;

  // Pozycja bota na mapie
  FizycznyPixelX := (L_BotY - L_MinY) div 50;
  FizycznyPixelY := (L_BotX - L_MinX) div 50;

  if (FizycznyPixelX >= 0) and (FizycznyPixelX < CalculatedWidth) and
     (FizycznyPixelY >= 0) and (FizycznyPixelY < CalculatedHeight) then
  begin
    DestBmp.Canvas.Brush.Color := clRed;
    DestBmp.Canvas.Pen.Color := clWhite;
    DestBmp.Canvas.Pen.Width := 1;
    DestBmp.Canvas.Ellipse(FizycznyPixelX - 5, FizycznyPixelY - 5, FizycznyPixelX + 5, FizycznyPixelY + 5);
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
  LocalDid, LocalToken, LocalTenant, LocalUserAgent, LocalShard, TargetURL: string;
  WybranyIndeks: Integer;
begin
  if Form1.FKeyToken.IsEmpty or Form1.FSelectedDid.IsEmpty or Form1.FTenantId.IsEmpty then
  begin
    Form1.Memo1.Lines.Add(' ');
    Form1.Memo1.Lines.Add('============');
    Form1.Memo1.Lines.Add('Brak wymaganych danych!');
    Exit;
  end;

  LocalToken := Form1.FKeyToken;
  LocalDid := Form1.FSelectedDid;
  LocalTenant := Form1.FTenantId;
  LocalUserAgent := Form1.USER_AGENT;
  WybranyIndeks := ComboBox6.ItemIndex;

  LocalShard := Form1.FSelectedShard;
  if LocalShard.IsEmpty then LocalShard := '10000';

  // Adres bramki chmurowej AIoT Shard 10000
  TargetURL := Form1.GetBaseUrl(Form1.Combobox2.Text) + '/dreame-iot-com-' + LocalShard + '/device/sendCommand';

  Form1.Memo1.Lines.Add('============');
  Form1.Memo1.Lines.Add('POBIERANIE MAPY, Shard:' + LocalShard);

  System.Threading.TTask.Run(
    procedure
    var
      HTTP: TNetHTTPClient;
      Response: IHTTPResponse;
      RequestBody: TStringStream;
      ReqObj, DataObj, FinalParamsObj, ParamObj: TJSONObject;
      ParamsArr, ResultRespArr: TJSONArray;
      RespJSON, DataRespObj, ExtractedJsonObj: TJSONObject;
      RawCloudData: TMemoryStream;
      Bmp: TBitmap;
      PayloadStr, ResBody, InterimMapUrl: string;
      StrefaString: string;
      ParsowaneX1, ParsowaneY1, ParsowaneX2, ParsowaneY2: Integer;
      FormatOk: Boolean;
      WynikSplitRowne, Czesci: TArray<string>;
      CiasnyValueString: string;
      ItemVal: TJSONValue;
      Idx: Integer;

      ResolveReq: TStringStream;
      ResolveResponseStream: TStringStream;
      OstatecznyMapURL: string;
      MapBramkaReq: TJSONObject;
      MapBramkaStream: TStringStream;
      MapBramkaRespStream: TStringStream;
      MapBramkaJSON: TJSONObject;

      // Strumienie i zmienne dla 3-etapowego dekodowania bufora chmury
      Base64TextStream: TStringStream;
      BinaryBytes: TBytes;
      Base64DecodedStream: TMemoryStream;
      DecryptedStream: TMemoryStream;
      DecompressedStream: TMemoryStream;
      ZStream: TZDecompressionStream;
      MagicBytes: array[0..1] of Byte;
    begin
      HTTP := TNetHTTPClient.Create(nil);
      RawCloudData := TMemoryStream.Create;
      Bmp := TBitmap.Create;
      InterimMapUrl := '';
      ReqObj := nil;

      try
        HTTP.ConnectionTimeout := 15000;
        HTTP.ResponseTimeout := 15000;
        HTTP.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
        HTTP.OnValidateServerCertificate := OminWalidacjeSSL;

        HTTP.CustomHeaders['Content-Type'] := 'application/json';
        HTTP.CustomHeaders['User-Agent'] := LocalUserAgent;
        HTTP.CustomHeaders['Authorization'] := 'bearer ' + LocalToken;
        HTTP.CustomHeaders['Dreame-Auth'] := 'bearer ' + LocalToken;
        HTTP.CustomHeaders['Tenant-Id'] := LocalTenant;

        // Dynamiczne ID mapy z Twojego logu to 2
        Self.FCurrentMapIdFromCloud := 2;

        CiasnyValueString := Format('{"req_type":1,"frame_type":"I","force_type":1,"map_id":%d}', [Self.FCurrentMapIdFromCloud]);
        CiasnyValueString := CiasnyValueString.Replace(' ', '');

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

        DataObj := TJSONObject.Create;
        DataObj.AddPair('did', LocalDid);
        DataObj.AddPair('id', TJSONNumber.Create(4567));
        DataObj.AddPair('method', 'action');
        DataObj.AddPair('params', ParamObj);

        ReqObj := TJSONObject.Create;
        ReqObj.AddPair('did', LocalDid);
        ReqObj.AddPair('id', TJSONNumber.Create(4567));
        ReqObj.AddPair('data', DataObj);

        PayloadStr := ReqObj.ToJSON;

        RequestBody := TStringStream.Create(PayloadStr, TEncoding.UTF8);
        Response := HTTP.Post(TargetURL, RequestBody);
        RequestBody.Free;

        if Response <> nil then
        begin
          ResBody := Response.ContentAsString(TEncoding.UTF8);

          if Response.StatusCode = 200 then
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
                            ResBody := TJSONObject(ItemVal).GetValue<string>('value');

                            ResolveReq := TStringStream.Create(
                              Format(
                                '{"did":"%s","id":4567,"data":{"did":"%s","id":4567,"method":"action","params":{"did":"%s","siid":6,"aiid":2,"in":[{"piid":1,"value":"{\"object_name\":\"%s\"}"}]},"From":"app"}}',
                                [LocalDid, LocalDid, LocalDid, ResBody]
                              ),
                              TEncoding.UTF8
                            );

                            ResolveResponseStream := TStringStream.Create('', TEncoding.UTF8);
                            try
                              Response := HTTP.Post(TargetURL, ResolveReq, ResolveResponseStream);
                            finally
                              ResolveReq.Free;
                              ResolveResponseStream.Free;
                            end;

                            OstatecznyMapURL := Form1.GetBaseUrl(Form1.Combobox2.Text) + '/dreame-user-iot/iotfile/getDownloadUrl';

                            try
                              MapBramkaReq := TJSONObject.Create;
                              MapBramkaReq.AddPair('did', LocalDid);
                              MapBramkaReq.AddPair('filename', ResBody);
                              MapBramkaReq.AddPair('model', Form1.FSelectedModel);

                              MapBramkaStream := TStringStream.Create(MapBramkaReq.ToJSON, TEncoding.UTF8);
                              MapBramkaRespStream := TStringStream.Create('', TEncoding.UTF8);

                              try
                                Sleep(500);
                                Response := HTTP.Post(OstatecznyMapURL, MapBramkaStream, MapBramkaRespStream);

                                if Assigned(Response) and (Response.StatusCode = 200) then
                                begin
                                  MapBramkaJSON := TJSONObject.ParseJSONValue(MapBramkaRespStream.DataString) as TJSONObject;
                                  try
                                    if not MapBramkaJSON.TryGetValue<string>('data', InterimMapUrl) then
                                      InterimMapUrl := '';
                                  finally
                                    MapBramkaJSON.Free;
                                  end;
                                end;
                              finally
                                MapBramkaStream.Free;
                                MapBramkaRespStream.Free;
                              end;
                            finally
                              MapBramkaReq.Free;
                            end;

                            if not InterimMapUrl.IsEmpty then Break;
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
        end;

        // POTOK DEKODOWANIA I DESZYFRACJI PRZED RENDEREM SIATKI

        if not InterimMapUrl.IsEmpty then
        begin
          HTTP.CustHeaders.Clear;
          HTTP.CustomHeaders['User-Agent'] := LocalUserAgent;

          Response := HTTP.Get(InterimMapUrl, RawCloudData);

          if (Response <> nil) and (Response.StatusCode = 200) then
          begin
            RawCloudData.Position := 0;

            Base64TextStream := TStringStream.Create('', TEncoding.ASCII);
            Base64DecodedStream := TMemoryStream.Create;
            DecryptedStream := TMemoryStream.Create;
            DecompressedStream := TMemoryStream.Create;
            try
              // 1. Odkodowanie tekstu Base64 z chmury do czystych bajtów
              Base64TextStream.CopyFrom(RawCloudData, 0);
              try
                BinaryBytes := TNetEncoding.Base64URL.Decode(TEncoding.ASCII.GetBytes(Trim(Base64TextStream.DataString)));
              except
                BinaryBytes := TNetEncoding.Base64.Decode(TEncoding.ASCII.GetBytes(Trim(Base64TextStream.DataString)));
              end;

              if Length(BinaryBytes) > 27 then
              begin
                Base64DecodedStream.WriteBuffer(BinaryBytes[0], Length(BinaryBytes));
                Base64DecodedStream.Position := 0;

                // 2. Deszyfracja kluczem sesyjnym AES-256 z WinAPI
                Self.DecryptDreameAes(Base64DecodedStream, DecryptedStream, LocalToken);
                DecryptedStream.Position := 0;

                // 3. Rozpakowanie dekompresorem ZLIB ($78 $9C)
                if DecryptedStream.Size > 2 then
                begin
                  DecryptedStream.ReadBuffer(MagicBytes, 2);
                  DecryptedStream.Position := 0;

                   if (MagicBytes[0] = $78) then
                  begin
                    ZStream := TZDecompressionStream.Create(DecryptedStream);
                    try
                      DecompressedStream.CopyFrom(ZStream, 0);
                    finally
                      ZStream.Free;
                    end;
                  end
                  else
                  begin
                    DecompressedStream.CopyFrom(DecryptedStream, 0);
                  end;
                end
                else
                begin
                  DecompressedStream.CopyFrom(DecryptedStream, 0);
                end;

                DecompressedStream.Position := 0;
                DecompressedStream.SaveToFile(ExtractFilePath(ParamStr(0)) + 'mapa');


                // 4. Wywołanie zaktualizowanego parsera siatki z offsetem Origin
                 ParseDreameMap(DecompressedStream, Bmp);

                DiagnozaStrumieniaAIoT(DecompressedStream);

              end;

            finally
              DecompressedStream.Free;
              DecryptedStream.Free;
              Base64DecodedStream.Free;
              Base64TextStream.Free;
            end;

            // NAKŁADANIE DANYCH SELEKCJI Z COMBOBOX6
            if WybranyIndeks > -1 then
            begin
              FormatOk := False;
              ParsowaneX1 := 0; ParsowaneY1 := 0; ParsowaneX2 := 0; ParsowaneY2 := 0;

              TThread.Synchronize(nil, procedure
              begin
                StrefaString := ComboBox6.Items[WybranyIndeks];
              end);

              if StrefaString.Contains('=') then
              begin
                WynikSplitRowne := StrefaString.Split(['=']);
                if Length(WynikSplitRowne) >= 2 then
                begin
                  Czesci := WynikSplitRowne[1].Split([',']);
                  if Length(Czesci) >= 4 then
                  begin
                    FormatOk := TryStrToInt(Czesci[0], ParsowaneX1) and
                                TryStrToInt(Czesci[1], ParsowaneY1) and
                                TryStrToInt(Czesci[2], ParsowaneX2) and
                                TryStrToInt(Czesci[3], ParsowaneY2);
                  end;
                end;
              end;

              if FormatOk then
              begin
                Bmp.Canvas.Lock;
                try
                  Bmp.Canvas.Brush.Style := bsClear;
                  Bmp.Canvas.Pen.Color := clRed; Bmp.Canvas.Pen.Width := 3;
                  Bmp.Canvas.Rectangle(ParsowaneX1, ParsowaneY1, ParsowaneX2, ParsowaneY2);

                  finally
                  Bmp.Canvas.Unlock;
                end;
              end;
            end;

            TThread.Synchronize(nil, procedure
            begin
              if Assigned(FBufferBitmap) then FBufferBitmap.Free;
              FBufferBitmap := TBitmap.Create;
              FBufferBitmap.Assign(Bmp);

              InvalidatePaintBox;
              Self.Repaint;

              Form1.Memo1.Lines.Add('=Mapa jest na ekranie=');

            end);
          end;
        end;

      except
        on E: Exception do
          TThread.Synchronize(nil, procedure
          begin
            Form1.Memo1.Lines.Add('Wyjątek w potoku: ' + E.Message);
          end);
      end;

      if Assigned(ReqObj) then ReqObj.Free;
        HTTP.Free;
        RawCloudData.Free;
        Bmp.Free;
    end);
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

procedure TForm4.DecryptDreameAes(ASrcStream, ADestStream: TStream; const AToken: string);
var
  KeyHash: TBytes;
  IV: array[0..15] of Byte;
  EncryptedData: TBytes;
  DecryptedData: TBytes;
  PaddingLen: Byte;
  ActualDecLen: Integer;

  Provider: THandle;
  KeyHandle: THandle;
  BlockLen, DataLen: DWORD;
  KeyParam: record
    Header: record
      bType: Byte;
      bVersion: Byte;
      reserved: Word;
      aiKeyAlg: Cardinal;
    end;
    KeyLen: Cardinal;
    KeyBytes: array[0..31] of Byte;
  end;
begin
  if (ASrcStream.Size < 32) or (AToken.IsEmpty) then
  begin
    ASrcStream.Position := 0;
    ADestStream.CopyFrom(ASrcStream, 0);
    Exit;
  end;

  ASrcStream.Position := 0;

  // POPRAWIONE: Prawidłowe sprawdzenie indeksów tablicy bajt po bajcie
  ASrcStream.ReadBuffer(IV[0], 6);
  if ((IV[0] = $78) and ((IV[1] = $9C) or (IV[1] = $DA) or (IV[1] = $01) or (IV[1] = $5E))) or
     ((IV[0] = Ord('D')) and (IV[1] = Ord('R')) and (IV[2] = Ord('E')) and (IV[3] = Ord('A')) and (IV[4] = Ord('M')) and (IV[5] = Ord('E'))) then
  begin
    ASrcStream.Position := 0;
    ADestStream.CopyFrom(ASrcStream, 0);
    Exit;
  end;

  // Przywracamy pozycję i pobieramy pełne IV oraz dane dla starych szyfrowanych klatek
  ASrcStream.Position := 0;
  ASrcStream.ReadBuffer(IV[0], 16);

  SetLength(EncryptedData, ASrcStream.Size - 16);
  ASrcStream.ReadBuffer(EncryptedData[0], Length(EncryptedData));

  if not CryptAcquireContext(Provider, nil, nil, 24, $F0000000) then
  begin
    ADestStream.WriteBuffer(EncryptedData[0], Length(EncryptedData));
    Exit;
  end;

  try
    KeyHash := THashSHA2.GetHashBytes(AToken, SHA256);

    KeyParam.Header.bType := $08;
    KeyParam.Header.bVersion := $02;
    KeyParam.Header.reserved := 0;
    KeyParam.Header.aiKeyAlg := $00006610;
    KeyParam.KeyLen := 32;
    Move(KeyHash[0], KeyParam.KeyBytes[0], 32);

    if not CryptImportKey(Provider, @KeyParam, SizeOf(KeyParam), 0, 0, KeyHandle) then
      Exit;

    try
      BlockLen := 1;
      CryptSetKeyParam(KeyHandle, 4, @BlockLen, 0);
      CryptSetKeyParam(KeyHandle, 1, @IV[0], 0);

      DecryptedData := Copy(EncryptedData);
      DataLen := Length(DecryptedData);

      if CryptDecrypt(KeyHandle, 0, True, 0, @DecryptedData[0], DataLen) then
      begin
        if DataLen > 0 then
        begin
          PaddingLen := DecryptedData[DataLen - 1];
          if PaddingLen <= 16 then
          begin
            ActualDecLen := DataLen - PaddingLen;
            if ActualDecLen > 0 then
              ADestStream.WriteBuffer(DecryptedData[0], ActualDecLen)
            else
              ADestStream.WriteBuffer(DecryptedData[0], DataLen);
          end
          else
            ADestStream.WriteBuffer(DecryptedData[0], DataLen);
        end;
      end
      else
      begin
        ADestStream.WriteBuffer(EncryptedData[0], Length(EncryptedData));
      end;

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
                                 Form1.Memo1.Lines.Add('ID Aktywnej Mapy: ' + V_Value);
                                 ComboBox4.Text := 'Mapa ID: ' + V_Value; // Przypisanie bezpośrednie
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

        CiasnyValueString := '{"req_type":1,"frame_type":"I","force_type":1,"map_id":14}'; // Odpytujemy z automatu aktywną mapę 14

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
