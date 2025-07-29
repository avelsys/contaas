program Contas;

uses
  Vcl.Forms,
  Contas.View in 'Fontes\View\Contas.View.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
