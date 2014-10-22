unit MWUtils;

interface

uses
   Data.Base;

  function PreparedQueryToString(const aSQL: string;  aParams: TVariantArray): string;

implementation

uses
  SysUtils, Variants, System.StrUtils,
  UltraStringUtils;

function PreparedQueryToString(const aSQL: string; aParams: TVariantArray): string;
var i, LPos, CPos: Integer;
    RString: string;
begin
   Result := '';
   i := 0;
   LPos := 1;
   CPos := Pos('?', aSQL);

   while (CPos > 0) do
   begin
      Case VarType(aParams[i]) of
         varString, varUString, varWord, varLongWord:
            RString := QuotedStr(VarToStr(aParams[i]));
         varDate:
            RString := QryDateToStr(VarToDateTime(aParams[i]), SMSSQL, dtfDateTimeFull);
         varNull:
            RString := 'null';
         varDouble:
            RString := StringReplace(VarToStr(aParams[i]), ',','.',[]);
         else
            RString := VarToStr(aParams[i]);
      end;

      Result := Result+Copy(aSQL, LPos, CPos-LPos)+RString;
      LPos := CPos+1;
      CPos := PosEx('?', aSQL, LPos);
      Inc(i);
   end;

   //Aantal parameters en aantal vervangvelden(='?') in de SQL string moeten overeenkomen.
   Assert(i <= Length(aParams));// TODO: Hier met Andre naar kijken! Dit gaat met mis Identity insert SQLCE!
   //Laatste deel query wegschrijven of hele query als er geen parameters meegegeven zijn.
   if (LPos <= Length(aSQL)) then
      Result := Result+Copy(aSQL, LPos, Length(aSQL)-LPos+1);
end;

end.
