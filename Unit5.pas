unit Unit5;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, System.StrUtils,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.Threading, System.JSON;
type
  TForm5 = class(TForm)
    GroupBox1: TGroupBox;
    Label19: TLabel;
    Label8: TLabel;
    Label11: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox9: TCheckBox;
    ComboBox12: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Panel1: TPanel;
    Label18: TLabel;
    TrackBar2: TTrackBar;
    GroupBox2: TGroupBox;
    Panel2: TPanel;
    TrackBar1: TTrackBar;
    Label17: TLabel;
    Label13: TLabel;
    CheckBox8: TCheckBox;
    ComboBox5: TComboBox;
    Label10: TLabel;
    ComboBox11: TComboBox;
    Label12: TLabel;
    ComboBox9: TComboBox;
    Label14: TLabel;
    ComboBox4: TComboBox;
    CheckBox3: TCheckBox;
    GroupBox3: TGroupBox;
    Panel3: TPanel;
    TrackBar3: TTrackBar;
    Label1: TLabel;
    Label6: TLabel;
    ComboBox7: TComboBox;
    Label9: TLabel;
    ComboBox8: TComboBox;
    Label20: TLabel;
    ComboBox13: TComboBox;
    CheckBox7: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox11: TCheckBox;
    GroupBox4: TGroupBox;
    Label21: TLabel;
    Label22: TLabel;
    CheckBox13: TCheckBox;
    Label16: TLabel;
    ComboBox6: TComboBox;
    Panel4: TPanel;
    Button1: TButton;
    ComboBox14: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure TrackBar3Change(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure CheckBox13Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox5Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure ComboBox7KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox8KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox13KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox11KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox9KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox4KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox5KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox2KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox3KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox12KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox6KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox1KeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox14KeyPress(Sender: TObject; var Key: Char);

  private
    { Private declarations }
  public

  end;

var
  Form5: TForm5;

implementation

{$R *.dfm}

uses Unit1, Unit4;

procedure TForm5.Button1Click(Sender: TObject);
begin
  Form5.Close;
end;

procedure TForm5.CheckBox13Click(Sender: TObject);
begin
  if checkbox13.Checked then
  begin
    Edit1.Enabled := True;
    Edit2.Enabled := True;
    end;

  if checkbox13.Checked = False then
  begin
    Edit1.Enabled := False;
    Edit2.Enabled := False;
    end;
end;

procedure TForm5.CheckBox1Click(Sender: TObject);
begin
 if Checkbox1.Checked  then
   begin
    ComboBox12.ItemIndex := 0;
    ComboBox12.Enabled := true
   end

   else begin
    ComboBox12.ItemIndex := -1;
    ComboBox12.Enabled := False;
    end;
end;

procedure TForm5.ComboBox11KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox12KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox13KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox14KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox1KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox2KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox3KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox4KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox5Change(Sender: TObject);
begin
  if ComboBox5.ItemIndex = -1 then Checkbox8.Enabled := False;
  if ComboBox5.ItemIndex = 0 then Checkbox8.Enabled := False;
  if ComboBox5.ItemIndex = 1 then Checkbox8.Enabled := True;
  if ComboBox5.ItemIndex = 2 then Checkbox8.Enabled := False;

end;

procedure TForm5.ComboBox5KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox6KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox7KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox8KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.ComboBox9KeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm5.FormCreate(Sender: TObject);
begin
  Edit1.Enabled := False;
  Edit2.Enabled := False;
end;


procedure TForm5.TrackBar1Change(Sender: TObject);
var
  Pt: TPoint;
begin
  // 1. Aktualizacja tekstu podpowiedzi o bie¿¹c¹ wartoœæ
  TrackBar1.Hint := IntToStr(TrackBar1.Position);
  // 2. Wymuszenie natychmiastowego wyœwietlenia i odœwie¿enia dymka
  Pt := Mouse.CursorPos;
  Application.ActivateHint(Pt);
end;

procedure TForm5.TrackBar2Change(Sender: TObject);
var
  Pt: TPoint;
begin
  // 1. Aktualizacja tekstu podpowiedzi o bie¿¹c¹ wartoœæ
  TrackBar2.Hint := IntToStr(TrackBar2.Position);
  // 2. Wymuszenie natychmiastowego wyœwietlenia i odœwie¿enia dymka
  Pt := Mouse.CursorPos;
  Application.ActivateHint(Pt);
end;

procedure TForm5.TrackBar3Change(Sender: TObject);
var
  Pt: TPoint;
begin
  // 1. Aktualizacja tekstu podpowiedzi o bie¿¹c¹ wartoœæ
  TrackBar3.Hint := IntToStr(TrackBar3.Position);
  // 2. Wymuszenie natychmiastowego wyœwietlenia i odœwie¿enia dymka
  Pt := Mouse.CursorPos;
  Application.ActivateHint(Pt);
end;


end.
