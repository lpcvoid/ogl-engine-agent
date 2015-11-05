unit aePrimitiveShapes;

interface

uses aeConst, aeMaths, aeRenderable, System.Types, dglOpenGL, aeSceneNode, System.Generics.Collections,
  aeMesh, aeVectorBuffer, aeIndexBuffer, aeTypes;

type
  TaePrimitiveShapeType = (AE_PRIMITIVESHAPE_TYPE_DEFAULT, AE_PRIMITIVESHAPE_TYPE_RAY);

type
  TaePrimitiveShape = class(TaeMesh)
  private
    _type: TaePrimitiveShapeType;
    _vectorBuffer: TaeVectorBuffer;
    _indexBuffer: TaeIndexBuffer;
  public
    property ShapeType: TaePrimitiveShapeType read _type write _type;
    constructor Create;
  end;

type
  TaePrimitiveShapeNode = class(TaeSceneNode)
  public

    constructor Create;
    procedure AddShape(shape: TaePrimitiveShape);
    Procedure RenderShapes;

  private
    _shapes: TList<TaePrimitiveShape>;
  end;

type
  TaePrimitiveShapeRay = class(TaePrimitiveShape)
  private
    _lineVerts: Array [0 .. 5] of single;
    procedure SetIndices;

  const
    RAY_RENDER_LEN = 10000.0;
  public
    constructor Create(orgin, direction: TPoint3D); overload;
    constructor Create(ray: TaeRay3); overload;
    constructor Create; overload;
    procedure UpdateRay(r: TaeRay3);

  end;

function GenerateUnitCubeVBO: TaeVertexIndexBuffer;

implementation

function GenerateUnitCubeVBO: TaeVertexIndexBuffer;
const
  VERTICES: array [0 .. 47] of single = (1, 1, 1, 1, 1, 1, -1, 1, 1, 0, 1, 1, -1, -1, 1, 0, 0, 1, 1, -1, 1, 1, 0, 1, 1, -1, -1, 1, 0, 0, -1, -1, -1, 0, 0, 0, -1, 1, -1, 0, 1, 0, 1, 1, -1, 1, 1, 0);
  INDICES: array [0 .. 23] of word = (0, 1, 2, 3, // Front face
    7, 4, 5, 6, // Back face
    6, 5, 2, 1, // Left face
    7, 0, 3, 4, // Right face
    7, 6, 1, 0, // Top face
    3, 2, 5, 4 // Bottom face
    );

begin
  Result.vertexBuffer := TaeVectorBuffer.Create;
  Result.indexBuffer := TaeIndexBuffer.Create;

  Result.vertexBuffer.PreallocateVectors(16);
  Result.vertexBuffer.AddVectorRange(@VERTICES[0], 16);
  Result.vertexBuffer.pack;

  Result.indexBuffer.PreallocateIndices(24);
  Result.indexBuffer.AddIndexRange(@INDICES[0], 24);
  Result.indexBuffer.pack;
end;

{ TaePrimitiveShapeRay }

constructor TaePrimitiveShapeRay.Create(orgin, direction: TPoint3D);
begin
  inherited Create;
  self.UpdateRay(TaeRay3.Create(orgin, direction));
  self.ShapeType := AE_PRIMITIVESHAPE_TYPE_RAY;
  self.SetIndices;
  self.SetRenderPrimitive(GL_LINES);
end;

constructor TaePrimitiveShapeRay.Create(ray: TaeRay3);
begin
  inherited Create;
  self.UpdateRay(ray);
  self.ShapeType := AE_PRIMITIVESHAPE_TYPE_RAY;
  self.SetIndices;
  self.SetRenderPrimitive(GL_LINES);
end;

constructor TaePrimitiveShapeRay.Create;
begin
  inherited;
  self.ShapeType := AE_PRIMITIVESHAPE_TYPE_RAY;
  self.SetIndices;
  self.SetRenderPrimitive(GL_LINES);
end;

procedure TaePrimitiveShapeRay.SetIndices;
begin
  self._indexBuffer.Clear;
  self._indexBuffer.RemoveFromGPU;
  self._indexBuffer.PreallocateIndices(2);
  self._indexBuffer.AddIndex(0);
  self._indexBuffer.AddIndex(1);
end;

procedure TaePrimitiveShapeRay.UpdateRay(r: TaeRay3);
begin
  self._vectorBuffer.Clear;
  self._vectorBuffer.RemoveFromGPU;
  self._vectorBuffer.PreallocateVectors(2);
  _lineVerts[0] := r.GetOrgin.x;
  _lineVerts[1] := r.GetOrgin.y;
  _lineVerts[2] := r.GetOrgin.z;
  _lineVerts[3] := _lineVerts[0] + r.GetDirection.x * self.RAY_RENDER_LEN;
  _lineVerts[4] := _lineVerts[1] + r.GetDirection.y * self.RAY_RENDER_LEN;
  _lineVerts[5] := _lineVerts[2] + r.GetDirection.z * self.RAY_RENDER_LEN;
  self._vectorBuffer.AddVectorRange(@_lineVerts[0], 2);
end;

{ TaePrimitiveShapeNode }

procedure TaePrimitiveShapeNode.AddShape(shape: TaePrimitiveShape);
begin
  self._shapes.Add(shape);
end;

constructor TaePrimitiveShapeNode.Create;
begin
  inherited Create('TaePrimitiveShapeNode');
  self._NodeType := AE_SCENENODE_TYPE_PRIMITIVESHAPE;
  self._shapes := TList<TaePrimitiveShape>.Create;
end;

procedure TaePrimitiveShapeNode.RenderShapes;
var
  i: Integer;
begin

  for i := 0 to self._shapes.Count - 1 do
  begin
    case self._shapes[i].ShapeType of

      AE_PRIMITIVESHAPE_TYPE_DEFAULT:
        begin
        // error
        end;

      AE_PRIMITIVESHAPE_TYPE_RAY:
        TaePrimitiveShapeRay(self._shapes[i]).Render;

    end;

  end;

end;

{ TaePrimitiveShape }

{ TaePrimitiveShape }

constructor TaePrimitiveShape.Create;
begin
  inherited;
  // we actually don't want to keep primitive shapes in ram. They are only for visualization.
  self.SetPurgeAfterGPUUpload(true);
  self._vectorBuffer := TaeVectorBuffer.Create;
  self._indexBuffer := TaeIndexBuffer.Create;
  self.SetVertexBuffer(self._vectorBuffer);
  self.SetIndexBuffer(self._indexBuffer);
end;

end.
