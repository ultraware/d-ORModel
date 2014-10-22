unit Meta.CustomIDTypes;

interface

uses
  Data.DataRecord;

type
  TTEST_ID = type TBaseIDValue;
  TTypedTEST_IDField = class(TCustomIDField<TTEST_ID>);

  TDataRecord_Helper = class helper for TDataRecord
  protected
    function GetTypedTEST_IDField(aIndex: Integer): TTypedTEST_IDField;
  end;

implementation

{ TDataRecord_Helper }

function TDataRecord_Helper.GetTypedTEST_IDField(aIndex: Integer): TTypedTEST_IDField;
begin
   Result := GetTypedField<TTypedTEST_IDField>(aIndex);
end;

end.


