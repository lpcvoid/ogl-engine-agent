unit aeDebugHelpers;

interface

uses windows;

procedure PrintDebugMessage(str: string);

implementation

procedure PrintDebugMessage(str: string);
begin
  OutputDebugString(PChar(str))
end;

end.
