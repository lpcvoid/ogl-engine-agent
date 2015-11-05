unit aeSceneGraph;

interface

uses types, windows, aeSceneNode, System.Generics.Collections, aeGeometry, aeMaths;

type
  TaeSceneGraph = class(TaeSceneNode)
    constructor Create;
    function GetTriangleCount: cardinal;
    function Intersect(ray: TaeRay3): boolean;
    function GetChildByName(n: String): TaeSceneNode;
  end;

implementation

{ TaeSceneGraph }

constructor TaeSceneGraph.Create;
begin
  inherited;
end;

function TaeSceneGraph.GetChildByName(n: String): TaeSceneNode;
var
  l: TList<TaeSceneNode>;
  i: Integer;
begin
  l := self.ListChildren;
  for i := 0 to l.Count - 1 do
    if (l[i].GetNodeName = n) then
    begin
      result := l[i];
      exit;
    end;

  l.Free;

end;

function TaeSceneGraph.GetTriangleCount: cardinal;
var
  l: TList<TaeSceneNode>;
  i: Integer;
begin
  result := 0;
  l := self.ListChildren;
  for i := 0 to l.Count - 1 do
  begin
    case l[i].getType of
      AE_SCENENODE_TYPE_GEOMETRY:
        result := result + TaeGeometry(l[i]).GetTriangleCount;

    end;

  end;
  l.Free;

end;

function TaeSceneGraph.Intersect(ray: TaeRay3): boolean;
var
  l: TList<TaeSceneNode>;
  geo: TaeGeometry;
  i: Integer;
begin
  l := self.ListChildren;

  for i := 0 to l.Count - 1 do
  begin
    case l[i].getType() of
      AE_SCENENODE_TYPE_GEOMETRY:
        begin
          geo := TaeGeometry(l[i]);
          result := geo.Intersect(ray);
          if (result) then
            exit;
        end;

    end;
  end;

  l.Free;

end;

end.
