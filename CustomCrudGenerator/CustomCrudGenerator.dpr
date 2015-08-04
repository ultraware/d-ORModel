program CustomCrudGenerator;

{$R *.res}

uses
  Forms,
  SysUtils,
  fMain in '..\UltraGenerator\fMain.pas' {frmMain},
  fModelGenerator in '..\UltraGenerator\fModelGenerator.pas' {frmModelGenerator},
  uGenerator in '..\UltraGenerator\uGenerator.pas',
  uMetaLoader in '..\UltraGenerator\uMetaLoader.pas',
  Data.Base in '..\Data\Data.Base.pas',
  Data.CRUD in '..\Data\Data.CRUD.pas',
  Data.CRUDDataset in '..\Data\Data.CRUDDataset.pas',
  Data.CustomTypes in '..\Data\Data.CustomTypes.pas',
  Data.DataRecord in '..\Data\Data.DataRecord.pas',
  Data.DataRecordList in '..\Data\Data.DataRecordList.pas',
  Data.EnumField in '..\Data\Data.EnumField.pas',
  Data.Query in '..\Data\Data.Query.pas',
  Data.CRUDSettings in '..\UltraGenerator\Data.CRUDSettings.pas',
  DB.ADODataConverter in '..\DB\DB.ADODataConverter.pas',
  DB.Base in '..\DB\DB.Base.pas',
  DB.Connection in '..\DB\DB.Connection.pas',
  DB.ConnectionPool in '..\DB\DB.ConnectionPool.pas',
  DB.Connector in '..\DB\DB.Connector.pas',
  DB.SQLBuilder in '..\DB\DB.SQLBuilder.pas',
  DB.Connection.SQLServer in '..\DB\DB.Connection.SQLServer.pas',
  DB.Settings,
  DB.Settings.SQLServer in '..\DB\DB.Settings.SQLServer.pas',
  DB.Provider.ADO in '..\DB\DB.Provider.ADO.pas',
  GlobalRTTI in '..\Func\GlobalRTTI.pas',
  Meta.Data in '..\Func\Meta.Data.pas',
  MultiEvent in '..\Func\MultiEvent.pas',
  ThreadFinalization in '..\Func\ThreadFinalization.pas',
  Utils.Validation in '..\Func\Utils.Validation.pas',
  CRUD.TEST in 'CRUDS\CRUD.TEST.pas',
  Meta.TEST in 'CRUDS\Meta.TEST.pas',
  Meta.CustomIDTypes in 'CRUDS\Meta.CustomIDTypes.pas',
  fDBSettings in '..\UltraGenerator\fDBSettings.pas' {DBSettingsFrm};

begin
  Application.Initialize;

//  TfrmMain.OutputCRUDPath := ExtractFilePath(Application.ExeName) + '..\CRUDs\';
  TGeneratorSettings.TemplatePath := ExtractFilePath(Application.ExeName) + '..\templates\';

  AddSQLDatabaseSettings('', 'TestDB.sdf',
              '', '', '', True, '',
              dbtSQLServerCE);
  //create CE db with TEST table
  DeleteFile('TestDB.sdf');
  CreateSQLCeDatabase('TestDB.sdf');
  CRUD.TEST.TESTCRUD.QueryCreateTable();

  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TDBSettingsFrm, DBSettingsFrm);
  //  Application.CreateForm(TfrmModelGenerator, frmModelGenerator);
  Application.Run;
end.
