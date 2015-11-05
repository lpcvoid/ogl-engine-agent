unit aeMatrixStack;

interface

uses aeMaths, System.Generics.Collections;

type
  TaeMatrixStack = class
    constructor Create;
    procedure Push(m: TaeMatrix44);
    function Pop: TaeMatrix44;
    function Peek: TaeMatrix44;
    function Count: integer;
  private
    _stack: Array of TaeMatrix44;
    _index: integer;
    bla: TStack<TaeMatrix44>;
    procedure AddMatrixAndIncrementIndex;
  end;

implementation

{ TaeMatrixStack }

procedure TaeMatrixStack.AddMatrixAndIncrementIndex;
begin
  SetLength(self._stack, length(self._stack) + 1);

end;

function TaeMatrixStack.Count: integer;
begin

end;

constructor TaeMatrixStack.Create;
begin
  self._index := 0;

end;

function TaeMatrixStack.Peek: TaeMatrix44;
begin

end;

function TaeMatrixStack.Pop: TaeMatrix44;
begin

end;

procedure TaeMatrixStack.Push(m: TaeMatrix44);
begin

end;

end.
