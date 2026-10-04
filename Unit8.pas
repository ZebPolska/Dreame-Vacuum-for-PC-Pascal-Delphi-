unit Unit8;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.JSON;


type
  TForm8 = class(TForm)
    ListView1: TListView;
    Button1: TButton; // Zamknij
    Button2: TButton; // Usuñ zaznaczone
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form8: TForm8;

implementation

{$R *.dfm}

uses Unit1; // Tu mamy dostêp do Form1.FKeyToken, Form1.FTenantId, Form1.GetBaseUrl() itp.

procedure TForm8.Button1Click(Sender: TObject);
begin
  Form8.Close;
end;




end.
