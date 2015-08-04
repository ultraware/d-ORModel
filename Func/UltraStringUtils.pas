unit UltraStringUtils;

interface

const
   SMySQL = 0;
   SMSSQL = 1;
   SMSSQLScope = 2;
type
   DateTimeFormat = (dtfDateOnly, dtfDateTimeSmall, dtfDateTimeFull);

   function _(const Input: string): string;
   function _Fmt(const Input: string; const Args: array of const; Capital: Boolean = True; Lower: Boolean = False): string;
   function Fld(const FieldName: string): string;

   function  QryDateToStr(Date: TDateTime; DBSoort: Integer = SMSSQL; Format: DateTimeFormat = dtfDateTimeSmall): string;
   function  GetStringPart(const S: string; const Part: Integer; const Separator: Char = ','): string;
   procedure AddToCSVList(const Value: string; var CSV: string; Separator: Char = ','; Unique: Boolean = False);

   function RTrim(const S: string; Char: string =  ' '): string;
   function StringIn(const ZoekStr, InStr: string; CaseSensitive: Boolean = False; Separator: Char = ','): Boolean;

   function Capitalize(Str: string; LowerRest: Boolean = False): string;

   function QryBoolToStr(Value: Boolean): string;

   function RoundF(const Value: Currency): Currency; overload;
   function RoundF(const Value: Double; Decimals: Integer): Double; overload;

   procedure TODO(const What: string = ''); deprecated 'Pending TODO!';

implementation

uses
  SysUtils, Math, StrUtils
  {$IFDEF ULTRA_TRANSLATE}
  ,gnugettext
  {$ENDIF}
  ;

function _(const Input: string): string;
begin
{$IFDEF ULTRA_TRANSLATE}
   if (Input = '') then
      Result := ''
   else
      Result := gnugettext._(Input);
{$ELSE}
   Result := Input;
{$ENDIF}
end;

function UFormat(const Input: string; const Args: array of const): string;
//safe format?
begin
   try
      Result := Format(Input, Args);
   except
      Result := Input;
   end;
end;

function Capitalize(Str: string; LowerRest: Boolean = False): string;
//only first char as Capital
begin
   if LowerRest then
      Str := LowerCase(Str);
   Result := UpperCase(Copy(Str,1,1))+Copy(Str,2,Length(Str));
end;

function _Fmt(const Input: string; const Args: array of const; Capital: Boolean = True; Lower: Boolean = False): string;
begin
   Result := UFormat(_(Input), Args);

   if Lower then
      Result := LowerCase(Result);

   if Capital then
      Result := Capitalize(Result);
end;

function Fld(const FieldName: string): string;
// FieldName with surrounding [ and ]
begin
   Result := '[' + StringReplace(StringReplace(FieldName,'[', '(',[rfReplaceAll]),']',')',[rfReplaceAll])+']';
end;

function QryDateToStr(Date: TDateTime; DBSoort: Integer = SMSSQL; Format: DateTimeFormat = dtfDateTimeSmall): string;
begin
   if (Date > 0.0) then
   begin
      case Format of
         dtfDateOnly:
            begin
               case DBSoort of
                  SMSSQL:
                     Result := QuotedStr(FormatDateTime('yyyymmdd', Date));
                  SMySQL:
                     Result := QuotedStr(FormatDateTime('yyyy-mm-dd', Date));
               else
                 Assert(false);
               end
            end;
         dtfDateTimeSmall:
            begin
               case DBSoort of
                  SMSSQL:
                     Result := QuotedStr(FormatDateTime('yyyymmdd hh":"nn', Date)); // TODO: DIT MOET ALTIJD!!! ':' respecteert scheidingsteken!
                  SMySQL:
                     Result := QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn', Date));
               else
                 Assert(false);
               end
            end;
         dtfDateTimeFull:
            begin
               case DBSoort of
                  SMSSQL:
                     Result := QuotedStr(FormatDateTime('yyyymmdd hh:nn:ss:zzz', Date));
                  SMySQL:
                     Result := QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss:zzz', Date));
               else
                 Assert(false);
               end
            end;
         else
           Assert(false);
      end;
   end
   else
      Result := 'null';
end;

function GetStringPart(const S: string; const Part: Integer; const Separator: Char = ','): string;
{ Geeft het zoveelste deel van een string terug, gescheiden door "Separator", begint te tellen bij 0 }
var sepCount, i: Integer;
begin
   Result := '';
   sepCount := 0;
   for i := 1 to Length(S) do
   begin
      if (Separator = s[i]) then
      begin
         Inc(sepCount);
         Continue;
      end;
      if (sepCount = Part) then
         Result := Result+s[i];
      if (sepCount > Part) then
         Break;
   end;
end;

procedure AddToCSVList(const Value: string; var CSV: string; Separator: Char = ','; Unique: Boolean = False);
begin
   if (CSV <> '') then
   begin
      if (not Unique) or (Pos(Separator+Value+Separator,Separator+CSV+Separator) = 0) then // UNIQUE is case sensitive... voor nu gebruiken we dus pos (is vele malen sneller dan stringin)...
         CSV := CSV+Separator+Value
   end
   else
      CSV := Value;
end;

function RTrim(const S: string; Char: string =  ' '): string;
//right trim
begin
   Result := S;
   while (Length(Result) > 0) and (AnsiRightStr(Result, 1) = Char) do
      SetLength(Result, Length(Result) - 1);
end;

function GetStringPartCount(const S: string; const Separator: Char = ','): Integer;
var sDummy: string;
    i, Len: Integer;
begin
   Result := 0;
   sDummy := S;
   Len := Length(sDummy);

   if (Len > 0) then
   begin
      if (sDummy[len] <> Separator) then
      begin
         sDummy := sDummy+Separator;
         Inc(len);
      end;

      for i := 1 to len do
         if (sDummy[i] = Separator) then
            Inc(Result);
   end;
end;

function StringIn(const ZoekStr, InStr: string; CaseSensitive: Boolean = False; Separator: Char = ','): Boolean;
var i, Count: Integer;
  sZoekStr, sInStr: string;
begin
   Result := False;
   sZoekStr := ZoekStr;
   sInStr := InStr;

   if (Length(sInStr) < Length(sZoekStr)) then
      EXIT;
   if not CaseSensitive then
   begin
      sZoekStr := UpperCase(sZoekStr);
      sInStr := UpperCase(sInStr);
   end;
   if (Pos(sZoekStr,sInStr) < 1) then
      EXIT;
   i := 0;
   Count := GetStringPartCount(sInStr,Separator);
   while (not Result) and (i < Count) do
   begin
      Result := (sZoekStr = GetStringPart(sInStr,i,Separator));
      Inc(i);
   end;
end;

function QryBoolToInt(Value: Boolean): Integer;
begin
   if Value then
      Result := 1
   else
      Result := 0;
end;

function QryBoolToStr(Value: Boolean): string;
//boolean to string ('1' or '0')
begin
   Result := IntToStr(QryBoolToInt(Value));
end;

function RoundF(const Value: Currency): Currency;
//round with 2 decimals
var Cents: Currency;
begin
    Cents := Value*100;
    if (Cents < 0) then
    begin {handle negative numbers}
       if (ABS(Frac(Cents)) >= 0.50) then
          Result := (Trunc(Cents)-1)/100
       else
          Result := (Trunc(Cents))/100;
    end
    else
    begin
       if (Frac(Cents) >= 0.50) then
          Result := (Trunc(Cents)+1)/100
       else
          Result := (Trunc(Cents))/100;
    end;
end;

function RoundF(const Value: Double; Decimals: Integer): Double;
//round with X decimals
var Decs, DecDivider: Double;
begin
    DecDivider := Power(10,Decimals);
    Decs := Value*DecDivider;
    if (Decs < 0) then
    begin {handle negative numbers}
       if (ABS(Frac(Decs)) >= 0.5) then
          Result := (Trunc(Decs)-1)/DecDivider
       else
          Result := (Trunc(Decs))/DecDivider;
    end
    else
    begin
       if (Frac(Decs) >= 0.5) then
          Result := (Trunc(Decs)+1)/DecDivider
       else
          Result := (Trunc(Decs))/DecDivider;
    end;
end;

procedure TODO(const What: string = '');
begin
  //nothing
end;

end.
