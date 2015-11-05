unit aeMesh;

interface

uses types, windows, aeMaths, aeRenderable, aeConst, aeLoggingManager,
  sysutils, aeVectorBuffer, aeIndexBuffer, aetypes, dglOpenGL;

type
  TaeMesh = class(TaeRenderable)
  private
  var
    _vbo: TaeVertexIndexBuffer;
    _LOD: TaeMeshLevelOfDetail;

    // flag if mesh data is to be deleted from ram after upload to GPU
    _purge_after_upload: boolean;
    // did we already upload some data?
    _data_uploaded_to_gpu: boolean;
    // opengl flag which tells it how to render. Default we want tiangles.
    _render_primitive: cardinal;

  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// If purge is set to true, this mesh will delete RAM contents after data is uploaded to GPU.
    /// </summary>
    procedure SetPurgeAfterGPUUpload(purge: boolean);

    procedure SetVertexBuffer(vb: TaeVectorBuffer);
    procedure SetIndexBuffer(ib: TaeIndexBuffer);

    function GetVertexBuffer: TaeVectorBuffer;
    function GetIndexBuffer: TaeIndexBuffer;

    procedure SetRenderPrimitive(prim: cardinal);

    function GetVertexIndexBuffer: TaeVertexIndexBuffer;

    procedure SetLOD(lod: TaeMeshLevelOfDetail);
    function GetLOD: TaeMeshLevelOfDetail;

    function GetVertexCount: cardinal;
    function GetIndexCount: cardinal;
    function GetVertexData: Pointer;
    function GetIndexData: Pointer;

    procedure Render(); override;

  end;

implementation

{ TaeMesh }

constructor TaeMesh.Create;
begin
  inherited;

  self.SetLOD(AE_MESH_LOD_HIGH);
  self.SetPurgeAfterGPUUpload(false);
  self.SetRenderPrimitive(GL_TRIANGLES);
end;

destructor TaeMesh.Destroy;
begin
  self._vbo.vertexBuffer.Free;
  self._vbo.indexBuffer.Free;
  inherited;
end;

procedure TaeMesh.SetLOD(lod: TaeMeshLevelOfDetail);
begin
  self._LOD := lod;
end;

procedure TaeMesh.SetPurgeAfterGPUUpload(purge: boolean);
begin
  self._purge_after_upload := purge;
end;

procedure TaeMesh.SetRenderPrimitive(prim: cardinal);
begin
  self._render_primitive := prim;
end;

function TaeMesh.GetLOD: TaeMeshLevelOfDetail;
begin
  result := self._LOD;
end;

function TaeMesh.GetIndexBuffer: TaeIndexBuffer;
begin
  result := self._vbo.indexBuffer;
end;

function TaeMesh.GetIndexCount: cardinal;
begin
  if (self._vbo.indexBuffer <> nil) then
    result := self._vbo.indexBuffer.Count;
end;

function TaeMesh.GetIndexData: Pointer;
begin
  if (self._vbo.indexBuffer <> nil) then
    result := self._vbo.indexBuffer.GetIndexData;
end;

function TaeMesh.GetVertexBuffer: TaeVectorBuffer;
begin
  result := self._vbo.vertexBuffer;
end;

function TaeMesh.GetVertexCount: cardinal;
begin
  if (self._vbo.vertexBuffer <> nil) then
    result := self._vbo.vertexBuffer.Count;
end;

function TaeMesh.GetVertexData: Pointer;
begin
  if (self._vbo.vertexBuffer <> nil) then
    result := self._vbo.vertexBuffer.GetVectorData;
end;

function TaeMesh.GetVertexIndexBuffer: TaeVertexIndexBuffer;
begin
  result := self._vbo;
end;

procedure TaeMesh.Render();
begin
  if (self._vbo.vertexBuffer <> nil) and (self._vbo.indexBuffer <> nil) then
  begin
    if (self._vbo.vertexBuffer.GetOpenGLBufferID = 0) then
      self._vbo.vertexBuffer.UploadToGPU;

    if (self._vbo.indexBuffer.GetOpenGLBufferID = 0) then
      self._vbo.indexBuffer.UploadToGPU;

    if (self._purge_after_upload) then
    begin
      self._vbo.vertexBuffer.Clear;
      // self._vbo.indexBuffer.Clear;
    end;

    glEnableClientState(GL_VERTEX_ARRAY);
    // Make the vertex VBO active
    glBindBuffer(GL_ARRAY_BUFFER, self._vbo.vertexBuffer.GetOpenGLBufferID);
    // Establish its 3 coordinates per vertex...
    glVertexPointer(3, GL_FLOAT, 0, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self._vbo.indexBuffer.GetOpenGLBufferID);

    // CANT DELETE INDEX ARRAY BECAUSE COUNT WOULD BE 0 THEN!
    // TODO : Fix this somehow...
    glDrawElements(self._render_primitive, self._vbo.indexBuffer.Count, GL_UNSIGNED_SHORT, nil);
    glDisableClientState(GL_VERTEX_ARRAY);
  end;
end;

procedure TaeMesh.SetIndexBuffer(ib: TaeIndexBuffer);
begin
  self._vbo.indexBuffer := ib;
end;

procedure TaeMesh.SetVertexBuffer(vb: TaeVectorBuffer);
begin
  self._vbo.vertexBuffer := vb;
end;

end.
