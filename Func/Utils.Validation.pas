unit Utils.Validation;

interface

  function IsValidEmail(const aEmail: string): boolean;

implementation

uses
  SysUtils;

//http://www.howtodothings.com/computers/a1169-validating-email-addresses-in-delphi.html
//or by using regular expresion:
//- from: http://www.regular-expressions.info/email.html)
//- [a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?
//- Tip: test/debug/visualize reqular expresion: http://www.debuggex.com/
function IsValidEmail(const aEmail: string): boolean;
// Returns True if the email address is valid
// Author: Ernesto D'Spirito
const
  // Valid characters in an "atom"
  C_atom_chars = [#33..#255] - ['(', ')', '<', '>', '@', ',', ';', ':',
                              '\', '/', '"', '.', '[', ']', #127];
  // Valid characters in a "quoted-string"
  C_quoted_string_chars = [#0..#255] - ['"', #13, '\'];
  // Valid characters in a subdomain
  C_letters = ['A'..'Z', 'a'..'z'];
  C_letters_digits = ['0'..'9', 'A'..'Z', 'a'..'z'];
  C_subdomain_chars = ['-', '0'..'9', 'A'..'Z', 'a'..'z'];
type
  TState = (STATE_BEGIN, STATE_ATOM, STATE_QTEXT, STATE_QCHAR,
    STATE_QUOTE, STATE_LOCAL_PERIOD, STATE_EXPECTING_SUBDOMAIN,
    STATE_SUBDOMAIN, STATE_HYPHEN);
var
  state: TState;
  i, n, subdomains: integer;
  c: char;
begin
  state := STATE_BEGIN;
  n := Length(aEmail);
  i := 1;
  subdomains := 1;
  while (i <= n) do
  begin
    c := aEmail[i];
    case state of
    STATE_BEGIN:
      if CharInSet(c, C_atom_chars) then
        state := STATE_ATOM
      else if c = '"' then
        state := STATE_QTEXT
      else
        break;
    STATE_ATOM:
      if c = '@' then
        state := STATE_EXPECTING_SUBDOMAIN
      else if c = '.' then
        state := STATE_LOCAL_PERIOD
      else if not CharInSet(c, C_atom_chars) then
        break;
    STATE_QTEXT:
      if c = '\' then
        state := STATE_QCHAR
      else if c = '"' then
        state := STATE_QUOTE
      else if not CharInSet(c, C_quoted_string_chars) then
        break;
    STATE_QCHAR:
      state := STATE_QTEXT;
    STATE_QUOTE:
      if c = '@' then
        state := STATE_EXPECTING_SUBDOMAIN
      else if c = '.' then
        state := STATE_LOCAL_PERIOD
      else
        break;
    STATE_LOCAL_PERIOD:
      if CharInSet(c, C_atom_chars)  then
        state := STATE_ATOM
      else if c = '"' then
        state := STATE_QTEXT
      else
        break;
    STATE_EXPECTING_SUBDOMAIN:
      if CharInSet(c, C_letters) then
        state := STATE_SUBDOMAIN
      else
        break;
    STATE_SUBDOMAIN:
      if c = '.' then begin
        inc(subdomains);
        state := STATE_EXPECTING_SUBDOMAIN
      end else if c = '-' then
        state := STATE_HYPHEN
      else if not CharInSet(c, C_letters_digits) then
        break;
    STATE_HYPHEN:
      if CharInSet(c, C_letters_digits) then
        state := STATE_SUBDOMAIN
      else if c <> '-' then
        break;
    end;
    inc(i);
  end;
  if i <= n then
    Result := False
  else
    Result := (state = STATE_SUBDOMAIN) and (subdomains >= 2);
end;

end.
