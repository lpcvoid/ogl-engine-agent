unit aeOBB;

interface

uses aeBoundingVolume, types, windows, aeMaths, aeConst, math, aetypes, aeVectorBuffer, aeIndexBuffer, aeMesh;

type
  TaeOBB = class(TaeBoundingVolume)
  public

    constructor Create;
    destructor Destroy; override;
    function calculateBoundingVolume(vio: TaeVertexIndexBuffer; avarageCenter: boolean = false): boolean; override;
    function collideWith(otherBV: TaeBoundingVolume; var transformMatrix: TaeMatrix44): boolean; override;
    function Intersect(ray: TaeRay3; transformMatrix: TaeMatrix44): boolean; override;
    procedure clear; override;
    /// <remarks>
    /// Returns the x,y,z direction distances to box insides
    /// </remarks>
    function getHalfwidths: TVectorArray;
    function getBox: TaeMesh;

  private
    _calculatedBox: TaeMesh;

    _halfwidths: TVectorArray; // x,y,z direction distances to box insides
  end;

implementation

{ TaeAABB }

function TaeOBB.calculateBoundingVolume(vio: TaeVertexIndexBuffer; avarageCenter: boolean = false): boolean;
var
  i, c: Integer;
  tempTri: TVectorArray;
  tempCenter: TPoint3D;
  tempCompareDistance: TVectorArray;
begin
  tempCenter.Create(0, 0, 0);
  tempCompareDistance[0] := 0;
  tempCompareDistance[1] := 0;
  tempCompareDistance[2] := 0;
  c := 0;
  for i := 0 to vio.indexBuffer.Count - 1 do
  begin
    tempTri := vio.vertexBuffer.GetVector(vio.indexBuffer.GetIndex(i));
    // tempTri := TaeTVectorArrayPointer(dword(v0) + (i * 12))^;

    if (avarageCenter) then
    begin
      // start calculating the sum of all triangle coordinates, we will use this later for the avarage middle
      tempCenter.X := tempCenter.X + tempTri[0];
      tempCenter.y := tempCenter.y + tempTri[1];
      tempCenter.z := tempCenter.z + tempTri[2];
      inc(c);
    end;

    // start comparing distances. We want the max.
    if (abs(tempTri[0]) > tempCompareDistance[0]) then
      tempCompareDistance[0] := abs(tempTri[0]);

    if (abs(tempTri[1]) > tempCompareDistance[1]) then
      tempCompareDistance[1] := abs(tempTri[1]);

    if (abs(tempTri[2]) > tempCompareDistance[2]) then
      tempCompareDistance[2] := abs(tempTri[2]);

  end;

  // take 000 as center, or calculate avarage?
  if (avarageCenter) then
  begin
    // okay, now calculate the middle by avarage vertex position...
    self._center.X := tempCenter.X / c;
    self._center.y := tempCenter.y / c;
    self._center.z := tempCenter.z / c;
  end
  else
    self._center.Create(0, 0, 0);

  // set the maximums...
  self._halfwidths[0] := tempCompareDistance[0];
  self._halfwidths[1] := tempCompareDistance[1];
  self._halfwidths[2] := tempCompareDistance[2];
end;

procedure TaeOBB.clear;
begin
  inherited;
  self._halfwidths[0] := 0;
  self._halfwidths[1] := 0;
  self._halfwidths[2] := 0;
  self._center.Create(0, 0, 0);
  if (self._calculatedBox.GetVertexBuffer <> nil) then
    self._calculatedBox.GetVertexBuffer.clear;

  if (self._calculatedBox.GetIndexBuffer <> nil) then
    self._calculatedBox.GetIndexBuffer.clear;
end;

function TaeOBB.collideWith(otherBV: TaeBoundingVolume; var transformMatrix: TaeMatrix44): boolean;
begin
  case otherBV.getType() of
    AE_BOUNDINGVOLUME_TYPE_OBB:
      begin
        // separating axis test

      end;
  end;
end;

constructor TaeOBB.Create;
begin
  inherited Create;
  self._calculatedBox := TaeMesh.Create;
  self._type := AE_BOUNDINGVOLUME_TYPE_OBB;
  self.clear;
end;

destructor TaeOBB.Destroy;
begin
  self._calculatedBox.Free;
  inherited;
end;

function TaeOBB.getBox: TaeMesh;
var
  v: TVectorArray;
  vb: TaeVectorBuffer;
  ib: TaeIndexBuffer;
begin
  // birds view, first level = top
  // first level   second level
  // 0  1          7  6
  // 0--0          0--0
  // |  |          |  |
  // 0--0          0--0
  // 3  2          4  5

  // GL_LINE_STRIP!

  if (self._calculatedBox.GetVertexBuffer = nil) then
  begin
    vb := TaeVectorBuffer.Create;
    self._calculatedBox.SetVertexBuffer(vb);
  end
  else
    vb := self._calculatedBox.GetVertexBuffer;

  if (self._calculatedBox.GetIndexBuffer = nil) then
  begin
    ib := TaeIndexBuffer.Create;
    self._calculatedBox.SetIndexBuffer(ib);
  end
  else
    ib := self._calculatedBox.GetIndexBuffer;

  if vb.Empty then
  begin
    vb.clear;
    ib.clear;
    ib.PreallocateIndices(20);
    vb.PreallocateVectors(20);
    // upper quad
    v[0] := self._center.X - self._halfwidths[0];
    v[1] := self._center.y + self._halfwidths[1];
    v[2] := self._center.z + self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(0);

    v[0] := self._center.X + self._halfwidths[0];
    v[1] := self._center.y + self._halfwidths[1];
    v[2] := self._center.z + self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(1);

    v[0] := self._center.X + self._halfwidths[0];
    v[1] := self._center.y + self._halfwidths[1];
    v[2] := self._center.z - self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(2);

    v[0] := self._center.X - self._halfwidths[0];
    v[1] := self._center.y + self._halfwidths[1];
    v[2] := self._center.z - self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(3);

    ib.AddIndex(0);

    // lower quad

    v[0] := self._center.X - self._halfwidths[0];
    v[1] := self._center.y - self._halfwidths[1];
    v[2] := self._center.z + self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(4);

    v[0] := self._center.X + self._halfwidths[0];
    v[1] := self._center.y - self._halfwidths[1];
    v[2] := self._center.z + self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(5);

    v[0] := self._center.X + self._halfwidths[0];
    v[1] := self._center.y - self._halfwidths[1];
    v[2] := self._center.z - self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(6);

    v[0] := self._center.X - self._halfwidths[0];
    v[1] := self._center.y - self._halfwidths[1];
    v[2] := self._center.z - self._halfwidths[2];
    vb.AddVector(v);
    ib.AddIndex(7);

    ib.AddIndex(4);
    ib.AddIndex(5);
    ib.AddIndex(1);
    ib.AddIndex(2);
    ib.AddIndex(6);
    ib.AddIndex(7);
    ib.AddIndex(3);

    ib.Pack;
    vb.Pack;
  end;

  result := self._calculatedBox;

end;

function TaeOBB.getHalfwidths: TVectorArray;
begin
  result := self._halfwidths;
end;

function TaeOBB.Intersect(ray: TaeRay3; transformMatrix: TaeMatrix44): boolean;
var
  maxS, minT: single;
  diff: TPoint3D;
  i: Integer;
  axis: TPoint3D;
  e, f, t1, t2, temp: single;
  OBBposition_worldspace: TPoint3D;
begin
  maxS := 100000.0;
  minT := 0.0;;

  OBBposition_worldspace := self._center * transformMatrix;

  // compute difference vector
  diff := OBBposition_worldspace - ray.GetOrgin;

  // for each axis do
  for i := 0 to 2 do
  begin
    axis := transformMatrix.GetRotationVectorAxis(i);
    // project relative vector onto axis
    e := axis.DotProduct(diff);
    f := ray.GetDirection().DotProduct(axis);

    // Standard case

    if (abs(f) > 0.001) then
    begin

      t1 := (e - self._halfwidths[i]) / f; // float t1 = (e+aabb_min.x)/f;
      t2 := (e + self._halfwidths[i]) / f; // float t2 = (e+aabb_max.x)/f;

      // fix order
      // We want t1 to represent the nearest intersection,
      // so if it's not the case, invert t1 and t2

      if (t1 > t2) then
      begin
        temp := t1;
        t1 := t2;
        t2 := temp;
      end;

      // tMax is the nearest "far" intersection (amongst the X,Y and Z planes pairs)
      // adjust min and max values
      if (t1 > minT) then
        minT := t1;
      if (t2 < maxS) then
        maxS := t2;

      // ray passes by box?
      if (maxS < minT) then
      begin
        result := false;
        exit;
      end;

    end
    else
    begin
      // Rare case : the ray is almost parallel to the planes, so they don't have any "intersection"
      if ((-e - self._halfwidths[i] > 0.0) or (-e + self._halfwidths[i] < 0.0)) then
      begin
        result := false;
        exit;
      end;
    end;

  end;

  // we have an intersection
  result := true;
end;

end.
