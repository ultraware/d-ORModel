program UltraGenerator;

{$IFNDEF ULTRA_GENERATOR} {$MESSAGE ERROR 'Must define "ULTRA_GENERATOR" for direct db connection'} {$ENDIF}
{$IFNDEF COMPILER_12_UP} {$MESSAGE ERROR 'Must define "COMPILER_12_UP" for xml reading/writing'} {$ENDIF}

uses
  Forms,
  SysUtils,
  fMain in 'fMain.pas' {frmMain},
  fModelGenerator in 'fModelGenerator.pas' {frmModelGenerator},
  Data.CRUDSettings in 'Data.CRUDSettings.pas',
  uGenerator in 'uGenerator.pas',
  uMetaLoader in 'uMetaLoader.pas',
  DB.Connection.SQLServer in '..\DB\DB.Connection.SQLServer.pas',
  DB.Settings.SQLServer in '..\DB\DB.Settings.SQLServer.pas',
  DB.Provider.ADO in '..\DB\DB.Provider.ADO.pas',
  UltraStringUtils in '..\Func\UltraStringUtils.pas';

{$R *.res}

begin
  Application.Initialize;

  AddSQLDatabaseSettings('Server', 'Database', 'DatabaseUser', 'DatabasePasword');

  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  //Application.CreateForm(TfrmModelGenerator, frmModelGenerator);
  Application.Run;
end.
