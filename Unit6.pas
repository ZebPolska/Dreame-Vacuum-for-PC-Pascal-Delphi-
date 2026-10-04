unit Unit6;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.JSON;


type
  TForm6 = class(TForm)
    ListView1: TListView;
    Button1: TButton; // Zamknij
    Button2: TButton; // Usuñ zaznaczone
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

uses Unit1; // Tu mamy dostêp do Form1.FKeyToken, Form1.FTenantId, Form1.GetBaseUrl() itp.

procedure TForm6.Button1Click(Sender: TObject);
begin
  Form6.Close;
end;




end.
