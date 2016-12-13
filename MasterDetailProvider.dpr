program MasterDetailProvider;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {MDPMain},
  MDProvider in 'MDProvider.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMDPMain, MDPMain);
  Application.Run;
end.
