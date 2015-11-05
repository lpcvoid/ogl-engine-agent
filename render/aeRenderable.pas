(*
  Every class which wishes to be renderable by the renderer must inherit from this class in order to get a vbo identifier.
*)

unit aeRenderable;

interface

uses windows, aeConst, dglOpenGl;

type
  TaeRenderable = class
  public

    Procedure Render(); virtual; abstract;

  end;

implementation

{ TaeRenderable }

end.
