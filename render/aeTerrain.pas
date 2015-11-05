unit aeTerrain;

interface

uses windows, types, classes, aeCamera, System.Generics.Collections, aeRenderable, aeMesh, aeSceneNode,
  aeConst, sysutils, aeLoggingManager, math, aeVectorBuffer, aeIndexBuffer, dglOpenGL;

const
  // target tile size. When quadtree arrived at this size, we stop splitting tree.
  AE_TERRAIN_TILE_SIZE = 128;
  // 1 many vertices every x meter
  AE_TERRAIN_TILE_LOD_RES_HIGH = 2;
  AE_TERRAIN_TILE_LOD_RES_MID = 8;
  AE_TERRAIN_TILE_LOD_RES_LOW = 32;

type
  TaeTerrainNeighborType = (AE_TERRAIN_NEIGHBOR_TYPE_TOP, AE_TERRAIN_NEIGHBOR_TYPE_RIGHT, AE_TERRAIN_NEIGHBOR_TYPE_BOTTOM, AE_TERRAIN_NEIGHBOR_TYPE_LEFT);

type
  TaeTerrainTile = class(TaeMesh)
  public
    constructor Create(row, column: integer; heightDataCall: TaeTerrainGetHeightCall);
    // calculate a triangle mesh from the height data...
    Procedure CalculateTerrainMesh();
    procedure SetNeighbor(tile: TaeTerrainTile; ntype: TaeTerrainNeighborType);
    function GetManhattanDistance(p: TPoint3D): single;
    function GetDistance(p: TPoint3D): single;
    procedure SetLOD(lod: TaeMeshLevelOfDetail);
  private
    _n_top, _n_right, _n_bottom, _n_left: TaeTerrainTile;
    _vb_lod: TaeVectorBuffer;
    _ib_lod_high: TaeIndexBuffer;
    _ib_lod_mid: TaeIndexBuffer;
    _ib_lod_low: TaeIndexBuffer;
    function GenerateLODIndexBuffer(ib: TaeIndexBuffer; tile_size, tile_res: integer): integer;
    // stich a triangle border around a tile.
    // function StichTile(tile: TaeTerrainTile): integer;
    // create a triangle border.
    // function CreateBorderStrip(gbo: TaeGraphicsBufferObject; neighbor_type: TaeTerrainNeighborType; border_len: integer; border_res_1, border_res_2: word): integer;
  protected
    _row, _column: integer;
    _GetHeightCall: TaeTerrainGetHeightCall;
  end;

type
  TaeVisableTerrainTiles = record
    count: integer;
    tiles: array of TaeTerrainTile;
  end;

type
  TaeTerrain = class(TaeSceneNode)
  public
    Constructor Create(terrain_size: Cardinal; hmap_resolution: integer; hmap_src: TaeTerrainGetHeightCall);
    procedure SetCamera(cam: TaeCamera);
    function GetVisableTiles: TaeVisableTerrainTiles;
  protected
    // setup basic grid
    Procedure SetupGrid;
    // approximate each edge to neighbor so we avoid cracks!

  private
    _GetHeightCall: TaeTerrainGetHeightCall;
    _tiles: TList<TaeTerrainTile>;
    _terrain_size: Cardinal; // squared
    _cam: TaeCamera;

  end;

implementation

{ TaeTerrain }

// constructor TaeTerrain.Create(hmap: TaeHeightmap);
// begin
// self._hmap := hmap;
// end;
//
// procedure TaeTerrain.SetCamera(cam: TaeCamera);
// begin
// self._cam := cam;
//
// end;

{ TaeTerrain }

constructor TaeTerrain.Create(terrain_size: Cardinal; hmap_resolution: integer; hmap_src: TaeTerrainGetHeightCall);
begin
  inherited Create('NODE_Terrain_' + IntToStr(terrain_size));
  Self._NodeType := AE_SCENENODE_TYPE_TERRAIN;
  Self._tiles := TList<TaeTerrainTile>.Create;
  Self._terrain_size := terrain_size * hmap_resolution; // normally 2
  Self._GetHeightCall := hmap_src;
  Self.SetupGrid;
  AE_LOGGING.AddEntry('TaeTerrain.Create() : Terrain engine started..', AE_LOG_MESSAGE_ENTRY_TYPE_NORMAL);
end;

function TaeTerrain.GetVisableTiles: TaeVisableTerrainTiles;
var
  i: integer;
  indx: integer;
  mhd: single;
begin
  indx := 0;
  Result.count := Self._tiles.count;
  SetLength(Result.tiles, Result.count);
  for i := 0 to Result.count - 1 do
  begin
    mhd := Self._tiles[i].GetDistance(Self._cam.getPosition);
    if (mhd < 5000) then
    begin
      if (Self._tiles[i].GetVertexBuffer = nil) then
        Self._tiles[i].CalculateTerrainMesh;

      if mhd < 300 then
      begin
        Self._tiles[i].SetLOD(AE_MESH_LOD_HIGH);
      end

      else if (mhd < 800) then
        Self._tiles[i].SetLOD(AE_MESH_LOD_MID)
      else
        Self._tiles[i].SetLOD(AE_MESH_LOD_LOW);

      Result.tiles[indx] := Self._tiles[i];
      inc(indx);
    end;
  end;

  Result.count := indx;
  SetLength(Result.tiles, Result.count);
end;

procedure TaeTerrain.SetCamera(cam: TaeCamera);
begin
  Self._cam := cam;
end;

procedure TaeTerrain.SetupGrid;
var
  nTiles: integer;
  y: integer;
  x: integer;
  tt: TaeTerrainTile;
  i: integer;
  i2: integer;
begin
  nTiles := Self._terrain_size div AE_TERRAIN_TILE_SIZE;

  for y := 0 to nTiles - 1 do
    for x := 0 to nTiles - 1 do
    begin
      // setup first
      tt := TaeTerrainTile.Create(x, y, Self._GetHeightCall);
      Self._tiles.Add(tt);
    end;

 // now fix neighbor links !
  for y := 0 to nTiles - 1 do
    for x := 0 to nTiles - 1 do
    begin
      i := x + y * nTiles;
 // set top
      if (y > 0) then
        Self._tiles[i].SetNeighbor(Self._tiles[i - nTiles], AE_TERRAIN_NEIGHBOR_TYPE_TOP);

 // set right
      if (x < (nTiles - 1)) then
        Self._tiles[i].SetNeighbor(Self._tiles[i + 1], AE_TERRAIN_NEIGHBOR_TYPE_RIGHT);

 // set bottom
      if (y < (nTiles - 1)) then
        Self._tiles[i].SetNeighbor(Self._tiles[i + nTiles], AE_TERRAIN_NEIGHBOR_TYPE_BOTTOM);

 // set left
      if (x > 0) then
        Self._tiles[i].SetNeighbor(Self._tiles[i - 1], AE_TERRAIN_NEIGHBOR_TYPE_LEFT);

    end;

end;

{ TaeTerrainTile }

procedure TaeTerrainTile.CalculateTerrainMesh;
var
  x: integer;
  y: integer;
  tx, ty: single;
  indx: word;
  v: TVectorArray;
  i: integer;
  numTriangles: integer;
  i_row, i_col: integer;
  i_top_left, i_bottom_right: word;
begin
    // create a buffer
  Self._vb_lod.Clear;
  numTriangles := (AE_TERRAIN_TILE_SIZE) * (AE_TERRAIN_TILE_SIZE) * 2;
  Self._vb_lod.PreallocateVectors(numTriangles * 3);
  // calculate world coordinate offsets
  // tx/ty is top left coordinate of tile

  tx := Self._column * AE_TERRAIN_TILE_SIZE;
  ty := Self._row * AE_TERRAIN_TILE_SIZE;

    // first we load all vertices into vertex array.
  for y := 0 to AE_TERRAIN_TILE_SIZE - 1 do
  begin
    v[2] := ty + y;
    for x := 0 to AE_TERRAIN_TILE_SIZE - 1 do
    begin
      v[0] := tx + x;
      v[1] := Self._GetHeightCall(v[0], v[2]);
      Self._vb_lod.AddVector(v);
    end;
  end;

  Self._vb_lod.Pack;
  Self.SetVertexBuffer(Self._vb_lod);

end;

function TaeTerrainTile.GenerateLODIndexBuffer(ib: TaeIndexBuffer; tile_size, tile_res: integer): integer;
var
  neededIndices: word;
  i_row, i_col: integer;
  i_top_left, i_bottom_right: word;
begin
  ib.Clear;
  // calculate needed indices
  neededIndices := (tile_size div tile_res) * (tile_size div tile_res) * 2 * 3;
  ib.PreallocateIndices(neededIndices);

  i_col := 0;
  i_row := 0;
  while i_col < (tile_size div tile_res) - 1 do
  begin
    while i_row < (tile_size div tile_res) - 1 do
    begin

      // top left vertex
      i_top_left := (i_col * tile_size * tile_res) + (i_row * tile_res);
      ib.addIndex(i_top_left);

      // bottom right vertex
      i_bottom_right := i_top_left + tile_size * tile_res + tile_res;
      ib.addIndex(i_bottom_right);

      // top right vertex
      ib.addIndex(i_top_left + tile_res);


      // bottom triangle

      // top left vertex
      ib.addIndex(i_top_left);
      // bottom left vertex
      ib.addIndex(i_top_left + tile_size * tile_res);
      // bottom right vertex
      ib.addIndex(i_bottom_right);

      inc(i_row);
    end;

    i_row := 0;
    inc(i_col);

  end;
  ib.Pack;

// okay, now for the borders.
// Self.StichTile(Self._n_top);
// Self.StichTile(Self._n_right);
// Self.StichTile(Self._n_bottom);
// Self.StichTile(Self._n_left);

  Result := ib.count;
end;

{ function TaeTerrainTile.StichTile(tile: TaeTerrainTile): integer;
begin
  // the higher quality always reaches down to lower quality.

  if (tile <> nil) then
    case Self.GetLOD() of

      AE_MESH_LOD_HIGH:
        begin

          case tile.GetLOD() of

            AE_MESH_LOD_HIGH:
              begin

              end;

            AE_MESH_LOD_MID:
              begin

              end;

          end;

        end;

      AE_MESH_LOD_MID:
        begin

          case tile.GetLOD() of

            AE_MESH_LOD_MID:
              begin

              end;

            AE_MESH_LOD_LOW:
              begin

              end;

          end;

        end;

      AE_MESH_LOD_LOW:
        begin
        // only have to deal with low quality
        end;

    end;

end; }

constructor TaeTerrainTile.Create(row, column: integer; heightDataCall: TaeTerrainGetHeightCall);
begin
  inherited Create();
  Self._row := row;
  Self._column := column;
  Self._GetHeightCall := heightDataCall;

  Self._vb_lod := TaeVectorBuffer.Create;
  Self._ib_lod_high := TaeIndexBuffer.Create;
  Self._ib_lod_mid := TaeIndexBuffer.Create;
  Self._ib_lod_low := TaeIndexBuffer.Create;

  // we want to delete ram contents, after it has been uploaded to GPU!
  Self.SetPurgeAfterGPUUpload(True);
  Self.SetRenderPrimitive(GL_TRIANGLES);
end;

{ function TaeTerrainTile.CreateBorderStrip(gbo: TaeGraphicsBufferObject; neighbor_type: TaeTerrainNeighborType; border_len: integer; border_res_1, border_res_2: word): integer;
var
  largerSide, smallerSide: word;
  triangleResolution: word;
  i: integer;
  indx: integer;
begin
  // find out which of the border sides has more detail (which of the tiles actually)
  // afterwards, we ´have the lower res side connect to higher res one.
  largerSide := Max(border_res_1, border_res_2);
  smallerSide := Min(border_res_1, border_res_2);
  triangleResolution := largerSide div smallerSide;

  // now add indices for every triangle that is smallerside.
  case neighbor_type of
    AE_TERRAIN_NEIGHBOR_TYPE_TOP:
      begin
        // top-bottom...
        for i := 0 to smallerSide - 1 do
        begin
          indx := border_len * i;
          gbo.addIndex(indx);
          gbo.addIndex(indx);
        end;

      end;
    AE_TERRAIN_NEIGHBOR_TYPE_RIGHT:
      ;
    AE_TERRAIN_NEIGHBOR_TYPE_BOTTOM:
      ;
    AE_TERRAIN_NEIGHBOR_TYPE_LEFT:
      ;
  end;

end; }

function TaeTerrainTile.GetDistance(p: TPoint3D): single;
var
  centerPoint: TPoint3D;
begin
  centerPoint.x := (Self._column * AE_TERRAIN_TILE_SIZE) + (AE_TERRAIN_TILE_SIZE div 2);
  centerPoint.z := (Self._row * AE_TERRAIN_TILE_SIZE) + (AE_TERRAIN_TILE_SIZE div 2);
  centerPoint.y := Self._GetHeightCall(centerPoint.x, centerPoint.z);
  Result := p.Distance(centerPoint);

end;

function TaeTerrainTile.GetManhattanDistance(p: TPoint3D): single;
begin
// return an approximate distance to the given point.
  Result := (abs(p.x - Self._row * AE_TERRAIN_TILE_SIZE) + abs(p.z - Self._column * AE_TERRAIN_TILE_SIZE));
end;

procedure TaeTerrainTile.SetLOD(lod: TaeMeshLevelOfDetail);
begin
  inherited;
  case lod of
    AE_MESH_LOD_HIGH:
      begin
        if (Self._ib_lod_high.Empty) then
          Self.GenerateLODIndexBuffer(Self._ib_lod_high, AE_TERRAIN_TILE_SIZE, AE_TERRAIN_TILE_LOD_RES_HIGH);
        Self.SetIndexBuffer(Self._ib_lod_high);
      end;

    AE_MESH_LOD_MID:
      begin
        // now add a middle quality!
        if (Self._ib_lod_mid.Empty) then
          Self.GenerateLODIndexBuffer(Self._ib_lod_mid, AE_TERRAIN_TILE_SIZE, AE_TERRAIN_TILE_LOD_RES_MID);
        Self.SetIndexBuffer(Self._ib_lod_mid);
      end;

    AE_MESH_LOD_LOW:
      begin
      // now add a low quality!
        if (Self._ib_lod_low.Empty) then
          Self.GenerateLODIndexBuffer(Self._ib_lod_low, AE_TERRAIN_TILE_SIZE, AE_TERRAIN_TILE_LOD_RES_LOW);
        Self.SetIndexBuffer(Self._ib_lod_low);
      end;

  end;

end;

procedure TaeTerrainTile.SetNeighbor(tile: TaeTerrainTile; ntype: TaeTerrainNeighborType);
begin
  case ntype of
    AE_TERRAIN_NEIGHBOR_TYPE_TOP:
      Self._n_top := tile;
    AE_TERRAIN_NEIGHBOR_TYPE_RIGHT:
      Self._n_right := tile;
    AE_TERRAIN_NEIGHBOR_TYPE_BOTTOM:
      Self._n_bottom := tile;
    AE_TERRAIN_NEIGHBOR_TYPE_LEFT:
      Self._n_left := tile;
  end;
end;

end.
