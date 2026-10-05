unit Unit6;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.DateUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls;

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
    procedure LoadFromRobotState;
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
  ListView1.Columns[2].Width := 250;
  ListView1.Columns.Add.Caption := 'Czas';
  ListView1.Columns[3].Width := 120;
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  LoadFromRobotState;
  RefreshList;
end;

procedure TForm6.AddNotification(const ATitle, AMessage, ATypeName: string);
var
  Item: TNotificationEntry;
begin
  Item := TNotificationEntry.Create(ATitle, AMessage, ATypeName);
  FItems.Insert(0, Item);
end;

procedure TForm6.LoadFromRobotState;
var
  StatusText, BatteryText: string;
begin
  if not Assigned(Form1) then Exit;

  StatusText := Trim(Form1.Panel8.Caption);
  BatteryText := Trim(Form1.Panel4.Caption);

  if StatusText <> '' then
    AddNotification('Status robota', 'Stan: ' + StatusText, 'Status');

  if BatteryText <> '' then
    AddNotification('Bateria', 'Poziom: ' + BatteryText, 'Bateria');
end;

procedure TForm6.RefreshList;
var
  I: Integer;
  Item: TNotificationEntry;
  LVItem: TListItem;
begin
  ListView1.Items.BeginUpdate;
  try
    ListView1.Items.Clear;

    for I := 0 to FItems.Count - 1 do
    begin
      Item := FItems[I];
      LVItem := ListView1.Items.Add;
      LVItem.Caption := Item.TypeName;
      LVItem.SubItems.Add(Item.Title);
      LVItem.SubItems.Add(Item.Message);
      LVItem.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Item.Timestamp));
      LVItem.Data := Item;
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
