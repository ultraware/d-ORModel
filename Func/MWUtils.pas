unit MWUtils;

interface

uses // Delphi
     // Shared
   Data.Base;

  function PreparedQueryToString(const aSQL: string;  aParams: TVariantArray): string;

implementation

uses // Delphi
     SysUtils, System.Variants
     ,System.Classes
     , DB.Connector
     , UltraUtilsBasic;

function PreparedQueryToString(const aSQL: string; aParams: TVariantArray): string;
type TStringMode = (smDefault, smQuoted, smSquareBrackets);
var ParamIndex: Integer;
    aChar: Char;
    RString: string;
    Modus: TStringMode;
    AddChar: Boolean;
begin
   Result := '';
   ParamIndex := 0;
   Modus := smDefault;

   for aChar in aSQL do
   begin
      AddChar := True;
      case aChar of
         '''':
         begin
            case Modus of
               smDefault:        Modus := smQuoted;
               smQuoted:         Modus := smDefault;
            end;
         end;
         '[':
         begin
            case Modus of
               smDefault:        Modus := smSquareBrackets;
            end;
         end;
         ']':
         begin
            case Modus of
               smSquareBrackets: Modus := smDefault;
            end;
         end;
         '?':
         begin
            case Modus of
               smDefault:
               begin
                  case VarType(aParams[ParamIndex]) of
                    varString, varUString, varWord, varLongWord:
                        RString := QuotedStr(VarToStr(aParams[ParamIndex]));
                    varDate:
                        RString := QryDateToStr(VarToDateTime(aParams[ParamIndex]), SMSSQL, dtfDateTimeFull);
                    varNull:
                        RString := 'null';
                    varDouble:
                        RString := StringReplace(VarToStr(aParams[ParamIndex]), ',','.',[]);
                    varBoolean:
                        RString := IntToStr(Ord(Boolean(aParams[ParamIndex])));
                    else
                        RString := VarToStr(aParams[ParamIndex]);
                  end;

                  Result := Result+RString;
                  Inc(ParamIndex);
                  AddChar := False;
               end;
            end;
         end;
      end;
      if AddChar then
         Result := Result + aChar;
   end;

   //Aantal parameters en aantal vervangvelden(='?') in de SQL string moeten overeenkomen.
   //Assert(i <= Length(aParams));// TODO: Hier met Andre naar kijken! Dit gaat met mis Identity insert SQLCE!
   //Laatste deel query wegschrijven of hele query als er geen parameters meegegeven zijn.
   //if (LPos <= Length(aSQL)) then
   //   Result := Result+Copy(aSQL, LPos, Length(aSQL)-LPos+1);
end;

end.
