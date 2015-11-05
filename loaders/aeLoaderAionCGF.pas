unit aeLoaderAionCGF;

interface

uses windows, ae3DModelLoaderBase, aeGeometry, System.Generics.Collections, types, aeMesh, classes, sysutils, aeMaths,
  aeRenderable, aeIndexBuffer, aeVectorBuffer;

const
  CGF_CHUNKTYPE_MESH = $CCCC0000;
  CGF_CHUNKTYPE_NODE = $CCCC000B;
  CGF_CHUNKTYPE_MATERIAL = $CCCC000C;
  CGF_FILETYPE_GEOMETRY = $FFFF0000;
  CGF_FILETYPE_ANIMATION = $FFFF0001;

type
  TaeLoaderAionCGF = class(Tae3DModelLoaderBase)
  private

    type
    PaeAionCGFChunkHeader = ^TaeAionCGFChunkHeader;

    TaeAionCGFChunkHeader = record
      chunkType: integer;
      chunkVersion: integer;
      chunkOffset: integer;
      chunkId: integer;
    end;

  type
    PaeAionCGFNode823 = ^TaeAionCGFNode823;

    TaeAionCGFNode823 = packed record
      header: TaeAionCGFChunkHeader;
      name: array [0 .. 63] of ansichar;
      ObjectID: integer;
      ParentID: integer;
      nChildren: integer;
      MaterialID: integer;
      isGroupHead, isGroupMember: boolean;
      transformMatrix: TaeMatrix44;
    end;

  type
    PaeAionCGFMesh744 = ^TaeAionCGFMesh744;

    TaeAionCGFMesh744 = packed record
      header: TaeAionCGFChunkHeader;
      verticesCount: integer;
      verticesArray: array of single;
      indicesCount: integer;
      indexArray: array of word;
    end;

  var
    _cgfNodes: array of TaeAionCGFNode823;
    _cgfMeshes: array of TaeAionCGFMesh744;
    _cgfChunks: array of TaeAionCGFChunkHeader;

    function GetChunkByChunkID(chunkId: integer): Pointer;
    function GetMeshFromChunk(fs: TFileStream; chunk_offset: integer): TaeAionCGFMesh744;
    function GetNodeFromChunk(fs: TFileStream; chunk_offset: integer): TaeAionCGFNode823;
    function ReadChunkHeader(fs: TFileStream; chunk_offset: integer): TaeAionCGFChunkHeader;
    function RemoveLODMeshes(geo: TaeGeometry): integer;
    procedure ResetLoader;
  public
    constructor Create;
    function loadFromFile(file_name: string; var geo: TaeGeometry): boolean; override;
  end;

implementation

{ TaeLoaderCGF }

constructor TaeLoaderAionCGF.Create;
begin
  self.setHandledFileExtension('cgf');
  // we want to handle 3ds with this loader!
  self._fileType := AE_LOADER_FILETYPE_AIONCGF;
end;

function TaeLoaderAionCGF.GetChunkByChunkID(chunkId: integer): Pointer;
var
  i: integer;
begin
  result := nil;
  for i := 0 to length(self._cgfNodes) - 1 do
    if (self._cgfNodes[i].header.chunkId = chunkId) then
    begin
      result := @self._cgfNodes[i];
      exit;
    end;

  for i := 0 to length(self._cgfMeshes) - 1 do
    if (self._cgfMeshes[i].header.chunkId = chunkId) then
    begin
      result := @self._cgfMeshes[i];
      exit;
    end;

end;

function TaeLoaderAionCGF.GetMeshFromChunk(fs: TFileStream; chunk_offset: integer): TaeAionCGFMesh744;
var
  m: TaeMesh;
  v, ind: integer;
  indx: integer;
  vert: single;
begin

  result.header := self.ReadChunkHeader(fs, chunk_offset);
  fs.Position := fs.Position + 4; // Skip byte[hasVertexWeights, hasVertexColors, reserved1, reserved2]
  fs.ReadData(result.verticesCount, 4);
  fs.Position := fs.Position + 4; // skip uvs count
  fs.ReadData(result.indicesCount, 4);
  fs.Position := fs.Position + 4; // skip vertAnim reference

  if (result.verticesCount > 0) and (result.indicesCount > 0) then
  begin
    // copy data...
    SetLength(result.verticesArray, result.verticesCount * 3);
    SetLength(result.indexArray, result.indicesCount * 3);

    for v := 0 to result.verticesCount - 1 do
    begin
	//CryVertex
      fs.ReadData(vert, 4);
      vert := vert / 100.0;
      result.verticesArray[v * 3] := vert;

      fs.ReadData(vert, 4);
      vert := vert / 100.0;
      result.verticesArray[v * 3 + 1] := vert;

      fs.ReadData(vert, 4);
      vert := vert / 100.0;
      result.verticesArray[v * 3 + 2] := vert;
      fs.Position := fs.Position + 12; // Skip normal
    end;

    for ind := 0 to result.indicesCount - 1 do
    begin
	//CryFace
      fs.ReadData(indx, 4);
      result.indexArray[ind * 3] := indx;
      fs.ReadData(indx, 4);
      result.indexArray[ind * 3 + 1] := indx;
      fs.ReadData(indx, 4);
      result.indexArray[ind * 3 + 2] := indx;

      fs.Position := fs.Position + 8; // Skip normal
    end;
  end;

end;

(*

  char		name[64];

  int			ObjectID;		// ID of this node's object chunk (if present)
  int			ParentID;		// chunk ID of the parent Node's chunk
  int			nChildren;		// # of children Nodes
  int			MatID;			// Material chunk No

  bool		IsGroupHead;
  bool		IsGroupMember;

  float	tm[4][4];				// transformation matrix
  Vec3	pos;			// pos component of matrix
  CryQuat		rot;			// rotation component of matrix
  Vec3	scl;			// scale component of matrix

  int			pos_cont_id;	// position controller chunk id
  int			rot_cont_id;	// rotation controller chunk id
  int			scl_cont_id;	// scale controller chunk id

  int			PropStrLen;		// lenght of the property string

*)
function TaeLoaderAionCGF.GetNodeFromChunk(fs: TFileStream; chunk_offset: integer): TaeAionCGFNode823;
var
  sm: TaeSerializedMatrix44;
begin
  result.header := self.ReadChunkHeader(fs, chunk_offset);
  ZeroMemory(@result.name[0], 64);
  fs.ReadData(@result.name[0], 64);
  fs.ReadData(result.ObjectID, 4);
  fs.ReadData(result.ParentID, 4);
  fs.ReadData(result.nChildren, 4);
  fs.ReadData(result.MaterialID, 4);
  fs.ReadData(result.isGroupHead, 1);
  fs.ReadData(result.isGroupMember, 1);
  fs.Position := fs.Position + 2; // Skip strange 2 bytes before transforma matrix...
  fs.ReadData(@sm[0], 4 * 16);
  result.transformMatrix.DeserializeMatrix44(sm);
  fs.Position := fs.Position + 26 * 4; // Skip other shit...

end;

function TaeLoaderAionCGF.loadFromFile(file_name: string; var geo: TaeGeometry): boolean;
var
  fs: TFileStream;
  cgf_mesh: TaeMesh;
  ib: TaeIndexBuffer;
  vb: TaeVectorBuffer;
  signature: array [0 .. 5] of ansichar;
  cgf_file_type: integer;
  cgf_tableoffset: integer;
  cgf_chunk_count: integer;
  cgf_chunk_header: TaeAionCGFChunkHeader;
  cgf_chunk_mesh: TaeAionCGFMesh744;
  cgf_chunk_node: TaeAionCGFNode823;
  cgf_chunk_ptr: Pointer;
  i: integer;
  e: integer;
  v_i, i_i: integer;
  v: TVectorArray;

begin
  self.ResetLoader;
  // Now, let's read.
  fs := TFileStream.Create(file_name, fmOpenRead);
  fs.ReadData(@signature[0], 6);
  if (signature = 'NCAion') then
  begin
    fs.Position := fs.Position + 2; // 2 00 bytes...
    fs.ReadData(cgf_file_type, 4);
    case cgf_file_type of
      CGF_FILETYPE_ANIMATION:
        begin
          result := False;
          exit;
        end;
      CGF_FILETYPE_GEOMETRY:
        begin
          // read headers
          fs.Position := fs.Position + 4; // unknown data
          fs.ReadData(cgf_tableoffset, 4);
          // now move to the chunk table
          fs.Position := cgf_tableoffset;
          fs.ReadData(cgf_chunk_count, 4);
          for i := 0 to cgf_chunk_count - 1 do
          begin
            cgf_chunk_header := self.ReadChunkHeader(fs, fs.Position);
            SetLength(self._cgfChunks, length(self._cgfChunks) + 1);
            self._cgfChunks[length(self._cgfChunks) - 1] := cgf_chunk_header;
          end;
          // process headers
          for i := 0 to cgf_chunk_count - 1 do
          begin
            case self._cgfChunks[i].chunkType of
              CGF_CHUNKTYPE_MESH:
                begin
                  if (self._cgfChunks[i].chunkVersion = $744) then
                  begin
                    cgf_chunk_mesh := self.GetMeshFromChunk(fs, self._cgfChunks[i].chunkOffset);
                    SetLength(self._cgfMeshes, length(self._cgfMeshes) + 1);
                    self._cgfMeshes[length(self._cgfMeshes) - 1] := cgf_chunk_mesh;
                  end;

                end;
              CGF_CHUNKTYPE_NODE:
                begin
                  cgf_chunk_node := self.GetNodeFromChunk(fs, self._cgfChunks[i].chunkOffset);
                  SetLength(self._cgfNodes, length(self._cgfNodes) + 1);
                  self._cgfNodes[length(self._cgfNodes) - 1] := cgf_chunk_node;

                end;
            else
              // nothing
            end;
          end;

          geo := TaeGeometry.Create(fs.FileName);

          // cycle nodes, and see if we can find a geometry attached to the nodes... then we have correct transform values at least!
          for i := 0 to length(self._cgfNodes) - 1 do
          begin
            cgf_chunk_node := self._cgfNodes[i];

            // get object that's bound to node......
            if (cgf_chunk_node.ObjectID > 0) then
            begin

              for e := 0 to length(self._cgfMeshes) - 1 do
                if (self._cgfMeshes[e].header.chunkId = cgf_chunk_node.ObjectID) then
                begin
                  // geo.GetLocalTransform.SetMatrix(cgf_chunk_node.transformMatrix);
                  cgf_mesh := TaeMesh.Create;

                  vb := TaeVectorBuffer.Create;
                  vb.PreallocateVectors(self._cgfMeshes[i].verticesCount);
                  ib := TaeIndexBuffer.Create;
                  ib.PreallocateIndices(self._cgfMeshes[i].indicesCount);

                  vb.AddVectorRange(@self._cgfMeshes[i].verticesArray[0], self._cgfMeshes[i].verticesCount);
                  ib.AddIndexRange(@self._cgfMeshes[i].indexArray[0], self._cgfMeshes[i].indicesCount);

                  vb.Pack;
                  ib.Pack;

                  cgf_mesh.SetVertexBuffer(vb);
                  cgf_mesh.SetIndexBuffer(ib);
                  geo.addMesh(cgf_mesh);
                end;

            end;

          end;

          // only keep largest mesh - the others are probably LOD!
          self.RemoveLODMeshes(geo);

          geo.updateBoundingVolume;

        end;
    end;

  end;
  fs.free;
end;

function TaeLoaderAionCGF.ReadChunkHeader(fs: TFileStream; chunk_offset: integer): TaeAionCGFChunkHeader;
begin
  fs.Position := chunk_offset;
  fs.ReadData(result.chunkType, 4);
  fs.ReadData(result.chunkVersion, 4);
  fs.ReadData(result.chunkOffset, 4);
  fs.ReadData(result.chunkId, 4);
end;

function TaeLoaderAionCGF.RemoveLODMeshes(geo: TaeGeometry): integer;
var
  maxVertexCount: integer;
  maxVertexCountIndex: integer;
  currentVertices: integer;
  i: integer;
begin
  // remove lod meshes
  maxVertexCount := 0;
  maxVertexCountIndex := 0;
  result := 0;
  if (geo.getMeshes.Count > 0) then
  begin
    for i := 0 to geo.getMeshes.Count - 1 do
    begin
      currentVertices := geo.getMeshes[i].getVertexCount;
      if (currentVertices > maxVertexCount) then
      begin
        maxVertexCountIndex := i;
        maxVertexCount := currentVertices;
      end;

    end;

    // delete all meshes except maxVertexCountIndex!
    for i := 0 to geo.getMeshes.Count - 1 do
      if (i <> maxVertexCountIndex) then
      begin
        geo.getMeshes[i].free;
        geo.getMeshes[i] := nil;
      end;

    geo.getMeshes.Pack;
    geo.getMeshes.Capacity := 1;

  end;
end;

procedure TaeLoaderAionCGF.ResetLoader;
begin
  SetLength(_cgfNodes, 0);
  SetLength(_cgfMeshes, 0);
  SetLength(_cgfChunks, 0);
end;

end.
