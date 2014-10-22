unit Meta.TEST;

{ Metadata definition for table: CompendaAppDemo.TEST }

interface

{$WEAKLINKRTTI ON}  

uses
  Meta.Data;

type
  TTESTField      = class(TBaseTableField);
  TTESTFieldClass = class of TTESTField;

  [TTableMeta('Test', '')]
  TEST = class(TBaseTableAttribute)
  public
    constructor Create(const aField: TTESTFieldClass);
  end;

  [TTypedMetaField   ('ID', ftFieldID, True{required}, '')]
  ID                    = class(TTESTField);
  [TTypedMetaField   ('Datum', ftFieldDateTime, True{required}, '')]
  Datum                 = class(TTESTField);
  [TDefaultValueMeta('StandaardTekst')]
  [TTypedMetaField   ('Tekst', ftFieldString, False, '')]
  Tekst                 = class(TTESTField);


implementation

constructor TEST.Create(const aField: TTESTFieldClass);
begin
  FField := aField;
end;


end.

