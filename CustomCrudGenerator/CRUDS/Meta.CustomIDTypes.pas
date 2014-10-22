unit Meta.CustomIDTypes;

interface

uses
  Data.DataRecord;

type
  TTest_ID = type TBaseIDValue;
  TTypedTest_IDField = class(TCustomIDField<TTest_ID>);

  TDataRecord_Helper = class helper for TDataRecord
  protected
    function GetTypedTest_IDField(aIndex: Integer): TTypedTest_IDField;
  end;

implementation

{ TDataRecord_Helper }

function TDataRecord_Helper.GetTypedTest_IDField(aIndex: Integer): TTypedTest_IDField;
begin
  Result := GetTypedField<TTypedTest_IDField>(aIndex);
end;

end.
