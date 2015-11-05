unit aeGeometry;

interface

uses aeSceneNode, types, aeMesh, System.Generics.Collections, aeMaterial, aeMaths, aeOBB,
  aeConst, aeBoundingVolume, aetypes, aeLoggingManager;

type
  TaeGeometry = class(TaeSceneNode)
  private
    _meshes: TList<TaeMesh>;
    _material: TaeMaterial;
    _MID: int64;
    _boundingvolume_obb: TaeOBB;

    /// <summary>
    /// This method intersects a given mesh with a ray, by checking every triangle for intersection.
    /// </summary>
    function IntersectTriangles(ray: TaeRay3; m: TaeMesh; var t: single): boolean;
  public

    property Material: TaeMaterial read _material write _material;
    /// <summary>
    /// Material ID. Can be asigned at will.
    /// </summary>
    property MID: int64 read _MID write _MID;
    constructor Create(name: string); overload;
    constructor Create; overload;
    destructor Destroy; override;

    procedure addMesh(m: TaeMesh; lod: TaeMeshLevelOfDetail = AE_MESH_LOD_HIGH);
    function getMeshes: TList<TaeMesh>;
    function GetMesh(lod: TaeMeshLevelOfDetail = AE_MESH_LOD_HIGH): TaeMesh;
    function Clone: TaeGeometry;

    procedure SetRenderPrimitive(prim: Cardinal);

    function GetTriangleCount: Cardinal;

    /// <remarks>
    /// Updates the bounding volume Data.
    /// </remarks>
    function updateBoundingVolume: boolean;
    function getBoundingVolume: TaeOBB;

    function Intersect(other: TaeGeometry): boolean; overload;
    function Intersect(ray: TaeRay3): boolean; overload;

  end;

implementation

{ TaeGeometry }

constructor TaeGeometry.Create(name: string);
begin
  inherited Create(name);
  self._meshes := TList<TaeMesh>.Create;
  self._material := TaeMaterial.Create;
  self._NodeType := AE_SCENENODE_TYPE_GEOMETRY;
  self._boundingvolume_obb := TaeOBB.Create;
end;

constructor TaeGeometry.Create;
begin
  inherited;
  self._meshes := TList<TaeMesh>.Create;
  self._material := TaeMaterial.Create;
  self._NodeType := AE_SCENENODE_TYPE_GEOMETRY;
  self._boundingvolume_obb := TaeOBB.Create;
end;

destructor TaeGeometry.Destroy;
begin
  self._meshes.Free;
  self._material.Free;
  self._boundingvolume_obb.Free;
  inherited;
end;

function TaeGeometry.Clone: TaeGeometry;
var
  i: Integer;
begin
  result := TaeGeometry.Create(self._name);
  for i := 0 to self.getMeshes.Count - 1 do
    result.addMesh(self._meshes[i]);
  result.Material.Color.setColor(self.Material.Color.getColor);
  result.Material.Rendermode := self.Material.Rendermode;
  result.GetLocalTransform.CopyTransformFrom(self.GetLocalTransform);
end;

function TaeGeometry.GetMesh(lod: TaeMeshLevelOfDetail): TaeMesh;
var
  i: Integer;
begin

  if (self._meshes.Count > 0) then
  begin
    for i := 0 to self._meshes.Count - 1 do
      if (self._meshes[i].GetLOD = lod) then
        result := self._meshes[i];

    // no mesh with that LOD found. We return the first we have.
    if (result = nil) then
      result := self._meshes[0];
  end
  else
  begin
    AE_LOGGING.AddEntry('TaeGeometry.GetMesh() : No mesh attached to return!', AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
  end;

end;

function TaeGeometry.updateBoundingVolume: boolean;
var
  mesh4bounding: TaeMesh;
begin
  mesh4bounding := self.GetMesh(AE_MESH_LOD_HIGH);
  if (mesh4bounding <> nil) then
  begin
    if (mesh4bounding.GetVertexBuffer <> nil) and (mesh4bounding.GetindexBuffer <> nil) then
    begin
      if (mesh4bounding.GetVertexBuffer.Count > 2) and (mesh4bounding.GetindexBuffer.Count > 2) then
      begin

        result := self._boundingvolume_obb.calculateBoundingVolume(mesh4bounding.GetVertexIndexBuffer, true);

      end;

    end
    else
    begin
      AE_LOGGING.AddEntry('TaeGeometry.updateBoundingVolume() : Either indices or vertices are not assigned! Cannot calculate bounding volume!', AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
      result := false;
    end;
  end
  else
  begin
    AE_LOGGING.AddEntry('TaeGeometry.updateBoundingVolume() : No mesh attached, cannot calculate BoundingVolume!', AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
  end;

end;

procedure TaeGeometry.addMesh(m: TaeMesh; lod: TaeMeshLevelOfDetail = AE_MESH_LOD_HIGH);
begin
  m.SetLOD(lod);
  self._meshes.Add(m);
end;

function TaeGeometry.getBoundingVolume: TaeOBB;
begin
  result := self._boundingvolume_obb;
end;

function TaeGeometry.getMeshes: TList<TaeMesh>;
begin
  result := self._meshes;
end;

function TaeGeometry.GetTriangleCount: Cardinal;
var
  i: Integer;
begin
  result := 0;
  for i := 0 to self._meshes.Count - 1 do
  begin
    if (self._meshes[i].GetVertexBuffer <> nil) then
      result := result + (self._meshes[i].GetVertexBuffer.Count div 3);

  end;
end;

function TaeGeometry.Intersect(ray: TaeRay3): boolean;
var
  i: Integer;
  t: single;
begin
  for i := 0 to self._meshes.Count - 1 do
  begin

    result := self._boundingvolume_obb.Intersect(ray, self.GetWorldTransformationMatrix);

    if (result = true) then
    begin
      result := self.IntersectTriangles(ray, self._meshes[i], t);

    end;
  end;
end;

function TaeGeometry.IntersectTriangles(ray: TaeRay3; m: TaeMesh; var t: single): boolean;
var
  i: Integer;
  _v0, _v1, _v2: TVectorArray;
  v0, v1, v2: TPoint3D;
  indexCount, indexPos, indexValue: word;
  worldTransformMatrix: TaeMatrix44;
  tri: TaeTriangle;
  vib: TaeVertexIndexBuffer;
begin
  vib := m.GetVertexIndexBuffer;
  if (vib.vertexBuffer <> nil) and (vib.indexBuffer <> nil) then
  begin
    try
      vib.vertexBuffer.Lock;
      vib.indexBuffer.Lock;
      indexCount := vib.indexBuffer.Count;
      indexPos := 0;
      t := 0.0;
      if (indexCount > 0) and (vib.vertexBuffer.Count > 0) then
      begin
        result := false;
        worldTransformMatrix := self.GetWorldTransformationMatrix;
    // loop all triangles...

        while (indexPos < indexCount) do
        begin
          indexValue := vib.indexBuffer.GetIndex(indexPos);
      // get vertices of a triangle
          _v0 := vib.vertexBuffer.GetVector(indexValue);
      // _v0 := TaeTVectorArrayPointer(dword(meshDataPointer) + (indexValue * 12))^;
          v0.Create(_v0[0], _v0[1], _v0[2]);

          indexValue := vib.indexBuffer.GetIndex(indexPos + 1);
          _v1 := vib.vertexBuffer.GetVector(indexValue);
      // _v1 := TaeTVectorArrayPointer(dword(meshDataPointer) + ((indexValue) * 12))^;
          v1.Create(_v1[0], _v1[1], _v1[2]);

          indexValue := vib.indexBuffer.GetIndex(indexPos + 2);
          _v2 := vib.vertexBuffer.GetVector(indexValue);
      // _v2 := TaeTVectorArrayPointer(dword(meshDataPointer) + ((indexValue) * 12))^;
          v2.Create(_v2[0], _v2[1], _v2[2]);

          tri.Create(v0, v1, v2);
          tri := tri * worldTransformMatrix;
          indexPos := indexPos + 3;

      // we got the transformed triangle... now we need to test it for an intersection!
      // Möller–Trumbore intersection algorithm
          result := tri.Intersect(ray, t);

          if (result) then
            exit;

        end;
      end;
    finally
      vib.indexBuffer.Unlock;
      vib.vertexBuffer.Unlock;
    end;

  end;

end;

procedure TaeGeometry.SetRenderPrimitive(prim: Cardinal);
var
  i: Integer;
begin
  for i := 0 to self._meshes.Count - 1 do
    self._meshes[i].SetRenderPrimitive(prim);
end;

function TaeGeometry.Intersect(other: TaeGeometry): boolean;
begin

end;

end.
