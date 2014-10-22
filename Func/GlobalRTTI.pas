{***************************************************************************}
{                                                                           }
{           d'ORModel - Model based ORM for Delphi                          }
{			https://github.com/ultraware/d-ORModel							}
{           Copyright (C) 2013-2014 www.ultraware.nl                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}
unit GlobalRTTI;

interface

uses
  RTTI;

type
  PRttiContext = ^TRttiContext; //pointer is needed because TRttiContext is a record (so get copied + destroyed on each get!)

  function RTTICache: PRttiContext;

implementation

var
  _GlobalRTTI: TRttiContext;    //keep rtti structures in memory, no re-read/re-create everytime...

function RTTICache: PRttiContext;
begin
  Result := @_GlobalRTTI;
end;

initialization
  _GlobalRTTI := TRttiContext.Create;  //not a real create (TRttiContext) but "initialization" of the record
finalization
  _GlobalRTTI.Free;

end.
