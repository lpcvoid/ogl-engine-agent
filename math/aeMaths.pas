(*

aeMaths - 2014 Swoosh
swoosh2009@live.de

*)

unit aeMaths;

interface 

uses windows, classes, types, aeLoggingManager, sysutils, aeConst, math;

type
  TaeSerializedMatrix44 = array [0 .. 15] of single;

type
  TaeSerializedMatrix33 = array [0 .. 8] of single;

type
  TaeAxisOrder = (AE_AXIS_ORDER_XYZ, AE_AXIS_ORDER_XZY);

type
  TaeVector3 = record
  private
    _x, _y, _z: single;
  public
    property X: single read _x write _x;
    property Y: single read _y write _y;
    property Z: single read _z write _z;

  end;

type
  TaeRay3 = record
  private
    _orgin, _dir: TPoint3D;
  public
    constructor Create(orgin, direction: TPoint3D);
    function GetOrgin: TPoint3D;
    function GetDirection: TPoint3D;
    // gets minimum distance between two rays. If rays are paralell, returns -1.
    function GetMinimumDistance(otherRay: TaeRay3): single;
  end;

type
  TaeTriangle = record
  private
    _v0, _v1, _v2: TPoint3D;
  public

    property V0: TPoint3D read _v0 write _v0;
    property V1: TPoint3D read _v1 write _v1;
    property V2: TPoint3D read _v2 write _v2;

    constructor Create(V0, V1, V2: TPoint3D); overload;
    constructor Create(v0x, v0y, v0z, v1x, v1y, v1z, v2x, v2y, v2z: single); overload;
    /// <summary>
    /// Returns boolean if the ray intersects this triangle.
    /// dist contains distance of ray orgin to triangle.
    /// This call assumes that the triangle is in same coordinate space as ray!
    /// </summary>
    function Intersect(ray: TaeRay3; var dist: single): boolean;

  end;

  (*
    x.x x.y x.z 0
    y.x y.y y.z 0
    z.x z.y z.z 0
    p.x p.y p.z 1

    or

    { x.x x.y x.z 0 y.x y.y y.z 0 z.x z.y z.z 0 p.x p.y p.z 1 }

  [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]  [8]  [9] [10] [11] [12] [13] [14] [15]
  [m11  m21  m31  m41  m12  m22  m32  m42  m13  m23  m33  m43  m14 m24 m34  m44]
    1    0    0    0    0    1    0    0    0    0   1    0    tx   ty   tz    1



 *)

type
  TaeMatrix44 = record
  private
    _elements: array [0 .. 15] of single;
    function Subdeterminant(excludeIndex: integer): single;
    function GetElement(indx: integer): single;
    procedure SetElement(indx: integer; const Value: single);
  public

    constructor Create(m: TaeSerializedMatrix44);
    procedure loadIdentity;

    procedure SetRotation(const AAxis: TPoint3D; const AAngle: single);
    // procedure SetRotationYawPitchRoll(const AYaw, APitch, ARoll: single);
    procedure SetTranslation(p: TPoint3D);
    procedure SetScale(s: single); overload;
    procedure SetScale(X, Y, Z: single); overload;
    procedure SetScale(p: TPoint3D); overload;

    function GetScaleX: single;
    function GetScaleY: single;
    function GetScaleZ: single;

    procedure SetRotationVectorX(v: TPoint3D);
    procedure SetRotationVectorY(v: TPoint3D);
    procedure SetRotationVectorZ(v: TPoint3D);
    procedure SetDirectionVectors(right, up, front: TPoint3D);

    function GetRotationVectorX: TPoint3D;
    function GetRotationVectorY: TPoint3D;
    function GetRotationVectorZ: TPoint3D;
    function GetRotationMatrix: TaeMatrix44;

    procedure SetPerspective(fovY, aspect, zNear, zFar: single);

    function GetValue(row, column: byte): single;

    // exchanges y and z axis in this matrix.
    procedure SwapD3DOpenGLAxis;

    /// <summary>
    /// Get an axis.
    /// x=0; y=1; z=2
    /// </summary>
    function GetRotationVectorAxis(xyz: integer): TPoint3D;

    function GetTranslation: TPoint3D;

    procedure DeserializeMatrix44(var m: TaeSerializedMatrix44; columnMajor: boolean = false);
    procedure DeserializeMatrix33(var m: TaeSerializedMatrix33; columnMajor: boolean = false);
    function SerializeMatrix44(columnMajor: boolean = true): TaeSerializedMatrix44;

    function Transpose: TaeMatrix44;
    function Invert: TaeMatrix44;
    function Determinant: single;
    // sum of all scale parameters
    // http://mathworld.wolfram.com/MatrixTrace.html
    function Trace: single;

    // fill with random junk.
    procedure PopulateRandomly;

    class operator Multiply(m1, m2: TaeMatrix44): TaeMatrix44; inline;
    class operator Multiply(const APoint: TPoint3D; const m1: TaeMatrix44): TPoint3D; inline;
    class operator Multiply(const APoint: TVectorArray; const m1: TaeMatrix44): TVectorArray; inline;
    class operator Multiply(const ATri: TaeTriangle; const m1: TaeMatrix44): TaeTriangle; inline;

    property Elements[indx: integer]: single read GetElement write SetElement; default;

  end;

type
  TaeQuaternion = record
  private
    _x, _y, _z, _w: single;
  public
    constructor Create(X, Y, Z, w: single); overload;
    constructor Create(q: TaeQuaternion); overload;
    procedure loadIdentity;
    property X: single read _x write _x;
    property Y: single read _y write _y;
    property Z: single read _z write _z;
    property w: single read _w write _w;
    /// <summary>
    /// builds a Quaternion from the Euler rotation
    /// * angles (y,r,p). Note that we are applying in order: roll, pitch, yaw but
    /// * we've ordered them in x, y, and z for convenience.
    /// * See: http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm
    /// <param name="yaw">the Euler yaw of rotation (in radians). (aka Bank, often rot around x)
    /// </param>
    /// <param name="roll">the Euler roll of rotation (in radians). (aka Bank, often Heading around y)
    /// </param>
    /// <param name="pitch">the Euler pitch of rotation (in radians). (aka Bank, often Attitude around z)
    /// </param>
    /// </summary >

    Procedure SetFromAngles(yaw, roll, pitch: single);
    procedure SetFromAngleAxis(radians: single; axis: TPoint3D);
    procedure SetFromAxis(X, Y, Z: TPoint3D);
    Procedure SetFromRotationMatrix(m: TaeMatrix44);
    procedure LookAt(direction, vec_up: TPoint3D);
    procedure Orientate(direction_vector: TPoint3D);
    function ToRotationMatrix: TaeMatrix44;
    // sets this quaternion to handle rotation between start, to dest.
    procedure SetToRotationBetweenVectors(start, dest: TPoint3D);
    function Norm: single;
    Procedure Normalize;

    class operator Multiply(a, b: TaeQuaternion): TaeQuaternion;
    class operator Multiply(a: TaeQuaternion; v: TPoint3D): TPoint3D;

  end;

type
  TaeSphere = record
  private
    _radius, _theta, _phi: double;
    _pos: TPoint3D;
    procedure SetTheta(theta: double);
    procedure SetPhi(phi: double);
  public
    constructor Create(Radius: single);

    property Radius: double read _radius write _radius;

    /// <summary>
    /// "vertical", polar angle, orthogonal to phi plane
    /// </summary>
    property theta: double read _theta write SetTheta;

    property Position: TPoint3D read _pos write _pos;

    /// <summary>
    /// "horizontal", orthogonal to the zenith, azimuth angle
    /// </summary>
    property phi: double read _phi write SetPhi;

    function Get3DPoint(axisOrder: TaeAxisOrder): TPoint3D;
    function IsPointInSphere(p: TPoint3D): boolean;

  end;

type
  TaePlane3 = record
  private
    _p, _normal: TPoint3D;
  public
    constructor Create(p, normal: TPoint3D);
    function GetPoint: TPoint3D;
    function GetNormal: TPoint3D;
     /// <summary>
    /// Returns boolean if the ray intersects this plane.
    /// dist contains distance of ray orgin to plane.
    /// intersectionPoint contains Point of intersection.
    /// This call assumes that the plane is in same coordinate space as ray!
    /// </summary>
    function Intersect(ray: TaeRay3; var dist: single; var intersectionPoint: TPoint3D): boolean;
  end;

type
  TaeLine3 = record
  private
    _l0, _l1: TPoint3D;
  public
    constructor Create(l1, l2: TPoint3D);
    function Length: single;
    function GetClosestPointOnLine(otherP: TPoint3D): TPoint3D;
    function Lerp(t: single): TPoint3D;
    function MakeRay: TaeRay3;
  end;

function PrintPoint3D(p: TPoint3D): string;

implementation

{ TaeMaths }

function PrintPoint3D(p: TPoint3D): string;
begin
  Result := '';
  Result := Result + 'X:' + FloatToStr(RoundTo(p.X, -2));
  Result := Result + ' Y:' + FloatToStr(RoundTo(p.Y, -2));
  Result := Result + ' Z:' + FloatToStr(RoundTo(p.Z, -2));
end;

{ TaeMatrix44 }

function invSqrt_fast(number: single): single; inline;
var
  i: integer;
  x2, Y: single;
const
  threehalfs = 1.5;
begin

  x2 := number * 0.5;
  Y := number;
  i := pInteger(@Y)^; // evil floating point bit level hacking
  i := $5F3759DF - (i shr 1); // what the fuck?
  Y := psingle(@i)^;
  Y := Y * (threehalfs - (x2 * Y * Y)); // 1st iteration
  Result := Y;

end;

function RadiansToDegrees(rad: single): single;
begin
  Result := rad * AE_180_DIV_PI;
end;

function DegreesToRadians(deg: single): single;
begin
  Result := deg * AE_PI_DIV_180;
end;

constructor TaeMatrix44.Create(m: TaeSerializedMatrix44);
begin
  self.DeserializeMatrix44(m);
end;

(*

Cryengine :

	ILINE void SetTranslationMat(  const Vec3_tpl<F>& v  ) {
		m00=1.0f;	m01=0.0f;	m02=0.0f;	m03=v.x;
		m10=0.0f;	m11=1.0f;	m12=0.0f;	m13=v.y;
		m20=0.0f;	m21=0.0f;	m22=1.0f;	m23=v.z;
	}
	ILINE static Matrix34_tpl<F, A> CreateTranslationMat(  const Vec3_tpl<F>& v  ) {	Matrix34_tpl<F, A> m34; m34.SetTranslationMat(v); return m34; 	}


	//NOTE: all vectors are stored in columns
	ILINE void SetFromVectors(const Vec3& vx, const Vec3& vy, const Vec3& vz, const Vec3& pos)	{
		m00=vx.x;		m01=vy.x;		m02=vz.x;		m03 = pos.x;
		m10=vx.y;		m11=vy.y;		m12=vz.y;		m13 = pos.y;
		m20=vx.z;		m21=vy.z;		m22=vz.z;		m23 = pos.z;
	}

*)

procedure TaeMatrix44.DeserializeMatrix33(var m: TaeSerializedMatrix33; columnMajor: boolean);
begin

  self.loadIdentity;
  if not(columnMajor) then
  begin
    self.SetRotationVectorX(Point3D(m[0], m[1], m[2]));
    self.SetRotationVectorY(Point3D(m[3], m[4], m[5]));
    self.SetRotationVectorZ(Point3D(m[6], m[7], m[8]));
    // self := self.Transpose;
  end
  else
  begin
    // column
    self.SetRotationVectorX(Point3D(m[0], m[3], m[6]));
    self.SetRotationVectorY(Point3D(m[1], m[4], m[7]));
    self.SetRotationVectorZ(Point3D(m[2], m[5], m[8]));
    // self := self.Transpose;
  end;

end;

procedure TaeMatrix44.DeserializeMatrix44(var m: TaeSerializedMatrix44; columnMajor: boolean = false);
begin
  CopyMemory(@self._elements[0], @m[0], 64);
  // if columnMajor then
  // self := self.Transpose;
end;

function TaeMatrix44.Determinant: single;
var
  subdeterminant0, subdeterminant1, subdeterminant2, subdeterminant3: single;
begin

  subdeterminant0 := Subdeterminant(0);
  subdeterminant1 := Subdeterminant(4);
  subdeterminant2 := Subdeterminant(8);
  subdeterminant3 := Subdeterminant(12);

  Result := _elements[0] * subdeterminant0 + _elements[4] * -subdeterminant1 + _elements[8] * subdeterminant2 + _elements[12] * -subdeterminant3;
end;

function TaeMatrix44.SerializeMatrix44(columnMajor: boolean = true): TaeSerializedMatrix44;
var
  tm: TaeMatrix44;
begin
  // if columnMajor then
  // tm := self.Transpose;
  CopyMemory(@Result[0], @self._elements[0], 64);
end;

function TaeMatrix44.Trace: single;
begin
  Result := self._elements[0] + self._elements[4] + self._elements[7];
end;

// correct
function TaeMatrix44.Transpose: TaeMatrix44;
begin
  Result._elements[0] := self._elements[0];
  Result._elements[1] := self._elements[4];
  Result._elements[2] := self._elements[8];
  Result._elements[3] := self._elements[12];
  Result._elements[4] := self._elements[1];
  Result._elements[5] := self._elements[5];
  Result._elements[6] := self._elements[9];
  Result._elements[7] := self._elements[13];
  Result._elements[8] := self._elements[2];
  Result._elements[9] := self._elements[6];
  Result._elements[10] := self._elements[10];
  Result._elements[11] := self._elements[14];
  Result._elements[12] := self._elements[3];
  Result._elements[13] := self._elements[7];
  Result._elements[14] := self._elements[11];
  Result._elements[15] := self._elements[15];
end;

function TaeMatrix44.GetElement(indx: integer): single;
begin
  if (indx < 16) and (indx >= 0) then
    Result := self._elements[indx]
  else
  begin
    Result := 0;
    AE_LOGGING.AddEntry('TaeMatrix44.GetElement() : Wrong index range! index=' + inttostr(indx), AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
  end;

end;

function TaeMatrix44.GetRotationMatrix: TaeMatrix44;
begin
  Result.loadIdentity;
  Result.SetRotationVectorX(self.GetRotationVectorX);
  Result.SetRotationVectorY(self.GetRotationVectorY);
  Result.SetRotationVectorZ(self.GetRotationVectorZ);
end;

function TaeMatrix44.GetRotationVectorAxis(xyz: integer): TPoint3D;
begin
  case xyz of
    0:
      Result := self.GetRotationVectorX;
    1:
      Result := self.GetRotationVectorY;
    2:
      Result := self.GetRotationVectorZ;
  else
    AE_LOGGING.AddEntry('TaeMatrix44.GetRotationVectorAxis() axis parameter out of Bound! param=' + inttostr(xyz), AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
  end;
end;

function TaeMatrix44.GetRotationVectorX: TPoint3D;
begin
  Result.X := _elements[0];
  Result.Y := _elements[1];
  Result.Z := _elements[2];
end;

function TaeMatrix44.GetRotationVectorY: TPoint3D;
begin
  Result.X := _elements[4];
  Result.Y := _elements[5];
  Result.Z := _elements[6];
end;

function TaeMatrix44.GetRotationVectorZ: TPoint3D;
begin
  Result.X := _elements[8];
  Result.Y := _elements[9];
  Result.Z := _elements[10];
end;

function TaeMatrix44.GetScaleX: single;
begin
  Result := self._elements[0];
end;

function TaeMatrix44.GetScaleY: single;
begin
  Result := self._elements[5];
end;

function TaeMatrix44.GetScaleZ: single;
begin
  Result := self._elements[10];
end;

procedure TaeMatrix44.SetRotationVectorX(v: TPoint3D);
begin
  _elements[0] := v.X;
  _elements[1] := v.Y;
  _elements[2] := v.Z;
end;

procedure TaeMatrix44.SetRotationVectorY(v: TPoint3D);
begin
  _elements[4] := v.X;
  _elements[5] := v.Y;
  _elements[6] := v.Z;
end;

procedure TaeMatrix44.SetRotationVectorZ(v: TPoint3D);
begin
  _elements[8] := v.X;
  _elements[9] := v.Y;
  _elements[10] := v.Z;
end;

procedure TaeMatrix44.SetScale(p: TPoint3D);
begin
  self.SetScale(p.X, p.Y, p.Z);
end;

procedure TaeMatrix44.SetScale(X, Y, Z: single);
begin
  _elements[0] := X;
  _elements[5] := Y;
  _elements[10] := Z;
end;

// function TaeMatrix44.GetRotationVectorX: TPoint3D;
// begin
// result.x := _elements[0];
// result.y := _elements[4];
// result.z := _elements[8];
// end;
//
// function TaeMatrix44.GetRotationVectorY: TPoint3D;
// begin
// result.x := _elements[1];
// result.y := _elements[5];
// result.z := _elements[9];
// end;
//
// function TaeMatrix44.GetRotationVectorZ: TPoint3D;
// begin
// result.x := _elements[2];
// result.y := _elements[6];
// result.z := _elements[10];
// end;
//
// procedure TaeMatrix44.SetRotationVectorX(v: TPoint3D);
// begin
// _elements[0] := v.x;
// _elements[4] := v.y;
// _elements[8] := v.z;
// end;
//
// procedure TaeMatrix44.SetRotationVectorY(v: TPoint3D);
// begin
// _elements[1] := v.x;
// _elements[5] := v.y;
// _elements[9] := v.z;
// end;
//
// procedure TaeMatrix44.SetRotationVectorZ(v: TPoint3D);
// begin
// _elements[2] := v.x;
// _elements[6] := v.y;
// _elements[10] := v.z;
// end;

procedure TaeMatrix44.SetDirectionVectors(right, up, front: TPoint3D);
begin
  self.SetRotationVectorX(right);
  self.SetRotationVectorY(up);
  self.SetRotationVectorZ(front);
end;

procedure TaeMatrix44.SetElement(indx: integer; const Value: single);
begin
  if (indx < 16) and (indx >= 0) then
    self._elements[indx] := Value
  else
  begin
    AE_LOGGING.AddEntry('TaeMatrix44.SetElement() : Wrong index range! index=' + inttostr(indx), AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
  end;
end;

procedure TaeMatrix44.SetPerspective(fovY, aspect, zNear, zFar: single);
var
  sine, cotangent, deltaZ: single;
begin

  self.loadIdentity;

  fovY := DegreesToRadians(fovY) / 2.0;
  deltaZ := zFar - zNear;
  sine := sin(fovY);

  if (deltaZ = 0.0) or (sine = 0.0) or (aspect = 0.0) then
    exit;

  cotangent := (cos(fovY) / sine);

  self._elements[0] := (cotangent / aspect);
  self._elements[5] := cotangent;
  self._elements[10] := (-(zFar + zNear) / deltaZ);
  self._elements[11] := -1.0;
  self._elements[14] := ((-2.0 * zNear * zFar) / deltaZ);
  self._elements[15] := 0.0;
end;

// correct
procedure TaeMatrix44.loadIdentity;
begin
  _elements[0] := 1.0;
  _elements[1] := 0.0;
  _elements[2] := 0.0;
  _elements[3] := 0.0;
  _elements[4] := 0.0;
  _elements[5] := 1.0;
  _elements[6] := 0.0;
  _elements[7] := 0.0;
  _elements[8] := 0.0;
  _elements[9] := 0.0;
  _elements[10] := 1.0;
  _elements[11] := 0.0;
  _elements[12] := 0.0;
  _elements[13] := 0.0;
  _elements[14] := 0.0;
  _elements[15] := 1.0;
end;

class operator TaeMatrix44.Multiply(const APoint: TPoint3D; const m1: TaeMatrix44): TPoint3D;
begin
  Result.X := (APoint.X * m1._elements[0]) + (APoint.Y * m1._elements[4]) + (APoint.Z * m1._elements[8]) + m1._elements[12];
  Result.Y := (APoint.X * m1._elements[1]) + (APoint.Y * m1._elements[5]) + (APoint.Z * m1._elements[9]) + m1._elements[13];
  Result.Z := (APoint.X * m1._elements[2]) + (APoint.Y * m1._elements[6]) + (APoint.Z * m1._elements[10]) + m1._elements[14];
end;

class operator TaeMatrix44.Multiply(m1, m2: TaeMatrix44): TaeMatrix44;
begin
  Result._elements[0] := m1[0] * m2[0] + m1[1] * m2[4] + m1[2] * m2[8] + m1[3] * m2[12];
  Result._elements[1] := m1[0] * m2[1] + m1[1] * m2[5] + m1[2] * m2[9] + m1[3] * m2[13];
  Result._elements[2] := m1[0] * m2[2] + m1[1] * m2[6] + m1[2] * m2[10] + m1[3] * m2[14];
  Result._elements[3] := m1[0] * m2[3] + m1[1] * m2[7] + m1[2] * m2[11] + m1[3] * m2[15];
  Result._elements[4] := m1[4] * m2[0] + m1[5] * m2[4] + m1[6] * m2[8] + m1[7] * m2[12];
  Result._elements[5] := m1[4] * m2[1] + m1[5] * m2[5] + m1[6] * m2[9] + m1[7] * m2[13];
  Result._elements[6] := m1[4] * m2[2] + m1[5] * m2[6] + m1[6] * m2[10] + m1[7] * m2[14];
  Result._elements[7] := m1[4] * m2[3] + m1[5] * m2[7] + m1[6] * m2[11] + m1[7] * m2[15];
  Result._elements[8] := m1[8] * m2[0] + m1[9] * m2[4] + m1[10] * m2[8] + m1[11] * m2[12];
  Result._elements[9] := m1[8] * m2[1] + m1[9] * m2[5] + m1[10] * m2[9] + m1[11] * m2[13];
  Result._elements[10] := m1[8] * m2[2] + m1[9] * m2[6] + m1[10] * m2[10] + m1[11] * m2[14];
  Result._elements[11] := m1[8] * m2[3] + m1[9] * m2[7] + m1[10] * m2[11] + m1[11] * m2[15];
  Result._elements[12] := m1[12] * m2[0] + m1[13] * m2[4] + m1[14] * m2[8] + m1[15] * m2[12];
  Result._elements[13] := m1[12] * m2[1] + m1[13] * m2[5] + m1[14] * m2[9] + m1[15] * m2[13];
  Result._elements[14] := m1[12] * m2[2] + m1[13] * m2[6] + m1[14] * m2[10] + m1[15] * m2[14];
  Result._elements[15] := m1[12] * m2[3] + m1[13] * m2[7] + m1[14] * m2[11] + m1[15] * m2[15];
end;

procedure TaeMatrix44.SetRotation(const AAxis: TPoint3D; const AAngle: single);
var
  NormAxis: TPoint3D;
  Cosine, sine, OneMinusCos: Extended;
begin
  System.SineCosine(AAngle, sine, Cosine);
  OneMinusCos := 1 - Cosine;
  NormAxis := AAxis.Normalize;
  _elements[0] := (OneMinusCos * NormAxis.X * NormAxis.X) + Cosine;
  _elements[1] := (OneMinusCos * NormAxis.X * NormAxis.Y) - (NormAxis.Z * sine);
  _elements[2] := (OneMinusCos * NormAxis.Z * NormAxis.X) + (NormAxis.Y * sine);
  _elements[4] := (OneMinusCos * NormAxis.X * NormAxis.Y) + (NormAxis.Z * sine);
  _elements[5] := (OneMinusCos * NormAxis.Y * NormAxis.Y) + Cosine;
  _elements[6] := (OneMinusCos * NormAxis.Y * NormAxis.Z) - (NormAxis.X * sine);
  _elements[8] := (OneMinusCos * NormAxis.Z * NormAxis.X) - (NormAxis.Y * sine);
  _elements[9] := (OneMinusCos * NormAxis.Y * NormAxis.Z) + (NormAxis.X * sine);
  _elements[10] := (OneMinusCos * NormAxis.Z * NormAxis.Z) + Cosine;
end;

//
// procedure TaeMatrix44.SetRotationYawPitchRoll(const AYaw, APitch, ARoll: single);
// var
// SineYaw, SinePitch, SineRoll: Extended;
// CosineYaw, CosinePitch, CosineRoll: Extended;
// begin
// System.SineCosine(AYaw, SineYaw, CosineYaw);
// System.SineCosine(APitch, SinePitch, CosinePitch);
// System.SineCosine(ARoll, SineRoll, CosineRoll);
//
// _elements[0] := CosineRoll * CosineYaw + SinePitch * SineRoll * SineYaw;
// _elements[1] := CosineYaw * SinePitch * SineRoll - CosineRoll * SineYaw;
// _elements[2] := -CosinePitch * SineRoll;
// _elements[4] := CosinePitch * SineYaw;
// _elements[5] := CosinePitch * CosineYaw;
// _elements[6] := SinePitch;
// _elements[8] := CosineYaw * SineRoll - CosineRoll * SinePitch * SineYaw;
// _elements[9] := -CosineRoll * CosineYaw * SinePitch - SineRoll * SineYaw;
// _elements[10] := CosinePitch * CosineRoll;
//
// end;

// correct
procedure TaeMatrix44.SetScale(s: single);
begin
  _elements[0] := s;
  _elements[5] := s;
  _elements[10] := s;
end;

// correct
procedure TaeMatrix44.SetTranslation(p: TPoint3D);
begin
  _elements[12] := p.X;
  _elements[13] := p.Y;
  _elements[14] := p.Z;
end;

function TaeMatrix44.Subdeterminant(excludeIndex: integer): single;
var
  index4x4, index3x3: integer;
  matrix3x3: array [0 .. 8] of single;
begin

  index3x3 := 0;
  for index4x4 := 0 to 15 do
  begin
    if (index4x4 div 4 = excludeIndex div 4) or (index4x4 mod 4 = excludeIndex mod 4) then
      Continue;

    matrix3x3[index3x3] := _elements[index4x4];
    inc(index3x3);

  end;

  Result := matrix3x3[0] * (matrix3x3[4] * matrix3x3[8] - matrix3x3[5] * matrix3x3[7]) - matrix3x3[3] * (matrix3x3[1] * matrix3x3[8] - matrix3x3[2] * matrix3x3[7]) + matrix3x3[6] * (matrix3x3[1] * matrix3x3[5] - matrix3x3[2] * matrix3x3[4]);
end;

procedure TaeMatrix44.SwapD3DOpenGLAxis;
var
  temp: single;
  V1, V2: TPoint3D;

begin
  V1 := self.GetRotationVectorX;
  temp := V1.Y;
  V1.Y := V1.Z;
  V1.Z := temp;
  self.SetRotationVectorX(V1);

  V1 := self.GetRotationVectorY;
  temp := V1.Y;
  V1.Y := V1.Z;
  V1.Z := temp;
  self.SetRotationVectorY(V1);

  V1 := self.GetRotationVectorZ;
  temp := V1.Y;
  V1.Y := V1.Z;
  V1.Z := temp;
  self.SetRotationVectorZ(V1);

 // now change vectors
  V1 := self.GetRotationVectorY;
  self.SetRotationVectorY(self.GetRotationVectorZ);
  self.SetRotationVectorZ(V1);
end;

// correct
function TaeMatrix44.GetTranslation: TPoint3D;
begin
  Result.X := _elements[12];
  Result.Y := _elements[13];
  Result.Z := _elements[14];
end;

function TaeMatrix44.GetValue(row, column: byte): single;
begin
  Result := row * 4 + column;
end;

function TaeMatrix44.Invert: TaeMatrix44;
var
  Determinant: single;
  index, indexTransposed, sign: integer;
begin
  Determinant := self.Determinant;

  for index := 0 to 15 do
  begin
    sign := 1 - (((index mod 4) + (index div 4)) mod 2) * 2;
    indexTransposed := (index mod 4) * 4 + index div 4;
    Result._elements[indexTransposed] := Subdeterminant(index) * sign / Determinant;
  end;

end;

class operator TaeMatrix44.Multiply(const APoint: TVectorArray; const m1: TaeMatrix44): TVectorArray;
begin
  Result[0] := (APoint[0] * m1._elements[0]) + (APoint[1] * m1._elements[4]) + (APoint[2] * m1._elements[8]) + m1._elements[12];
  Result[1] := (APoint[0] * m1._elements[1]) + (APoint[1] * m1._elements[5]) + (APoint[2] * m1._elements[9]) + m1._elements[13];
  Result[2] := (APoint[0] * m1._elements[2]) + (APoint[1] * m1._elements[6]) + (APoint[2] * m1._elements[10]) + m1._elements[14];
end;

class operator TaeMatrix44.Multiply(const ATri: TaeTriangle; const m1: TaeMatrix44): TaeTriangle;
begin
  Result.V0 := ATri.V0 * m1;
  Result.V1 := ATri.V1 * m1;
  Result.V2 := ATri.V2 * m1;
end;

procedure TaeMatrix44.PopulateRandomly;
var
  i: integer;
begin
  for i := 0 to 15 do
    _elements[i] := RandG(1.0, 5.0);
end;

{ TaeSphere }

constructor TaeSphere.Create(Radius: single);
begin
  self._radius := Radius; // unit sphere
  self._theta := 1.0;
  self._phi := 1.0;
  self._pos.Create(0, 0, 0);
end;

function TaeSphere.Get3DPoint(axisOrder: TaeAxisOrder): TPoint3D;
begin

  case axisOrder of
    AE_AXIS_ORDER_XYZ:
      begin
        Result.X := self._radius * sin(self._theta) * cos(self._phi);
        Result.Y := self._radius * sin(self._theta) * sin(self._phi);
        Result.Z := self._radius * cos(self._theta);
      end;
    AE_AXIS_ORDER_XZY:
      begin
        // opengl order, height (z in maths) is y in ogl
        Result.X := self._radius * sin(self._theta) * cos(self._phi);
        Result.Y := self._radius * cos(self._theta);
        Result.Z := self._radius * sin(self._theta) * sin(self._phi);

      end;
  end;

end;

function TaeSphere.IsPointInSphere(p: TPoint3D): boolean;
var
  X, Y, Z: single;
begin
  X := self._pos.X - p.X;
  Y := self._pos.Y - p.Y;
  Z := self._pos.Z - p.Z;
  Result := (X * X + Y * Y + Z * Z) < (_radius * _radius);
end;

procedure TaeSphere.SetPhi(phi: double);
begin
  // http://en.wikipedia.org/wiki/Spherical_coordinate_system#Unique_coordinates
  // 0° ≤ φ < 360° (2π rad)
  self._phi := phi;

  // if (phi < 0.0) then
  // self._phi := 0.0;
  //
  // if (phi > AE_PI_MULT2) then
  // self._phi := 0.0;
end;

procedure TaeSphere.SetTheta(theta: double);
begin
  // 0° ≤ θ ≤ 180° (π rad)
  // http://en.wikipedia.org/wiki/Spherical_coordinate_system#Unique_coordinates
  self._theta := theta;

  // if (theta < 0.0) then
  // self._theta := 0.0;
  //
  // if (theta > AE_PI) then
  // self._theta := 0.0;

end;

{ TaeLine3 }

constructor TaeLine3.Create(l1, l2: TPoint3D);
begin
  self._l0 := l1;
  self._l1 := l2;
end;

// http://www.gamedev.net/topic/444154-closest-point-on-a-line/
function TaeLine3.GetClosestPointOnLine(otherP: TPoint3D): TPoint3D;
var
  c, v: TPoint3D;
  d, t: single;
begin
  // // Determine the length of the vector from a to b
  // c := otherP - _l0;
  // v := _l1 - _l0;
  // v := Norm(v, @d);
  // t := Dot(v, c);
  // // Check to see if ‘t’ is beyond the extents of the line segment
  // if t < 0 then
  // begin
  // result := l1;
  // exit;
  // end
  // else if t > d then
  // begin
  // result := l2;
  // exit;
  // end;
  // // Return the point between ‘a’ and ‘b’
  // result.X := v.X * t + l1.X;
  // result.Y := v.Y * t + l1.Y;
  // result.Z := v.Z * t + l1.Z;

end;

function TaeLine3.Length: single;
begin
  Result := _l0.Distance(_l1);
end;

function TaeLine3.Lerp(t: single): TPoint3D;
begin
  Result := (self._l0 + (self._l1 - self._l0)).Scale(t);
end;

function TaeLine3.MakeRay: TaeRay3;
begin
  Result.Create(self._l0, (self._l1 - self._l0).Normalize);
end;

{ TaeRay3 }

constructor TaeRay3.Create(orgin, direction: TPoint3D);
begin
  self._orgin := orgin;
  self._dir := direction;
end;

function TaeRay3.GetDirection: TPoint3D;
begin
  Result := self._dir;
end;

// easycalculation.com/analytical/shortest-distance-between-lines.php
function TaeRay3.GetMinimumDistance(otherRay: TaeRay3): single;
var
  closestPoint1, closestPoint2, r: TPoint3D;
  a, b, e, d, c, f, s, t: single;
begin
  closestPoint1.Create(0, 0, 0);
  closestPoint2.Create(0, 0, 0);
  a := self.GetDirection.DotProduct(self.GetDirection);
  b := self.GetDirection.DotProduct(otherRay.GetDirection);
  e := otherRay.GetDirection.DotProduct(otherRay.GetDirection);
  d := a * e - b * b;
  // rays aren't parallel
  if (d <> 0.0) then
  begin
    r := self.GetOrgin - otherRay.GetOrgin;
    c := self.GetDirection.DotProduct(r);
    f := otherRay.GetDirection.DotProduct(r);
    s := (b * f - c * e) / d;
    t := (a * f - c * b) / d;

    closestPoint1 := self.GetOrgin + self.GetDirection.Scale(s);
    closestPoint2 := otherRay.GetOrgin + otherRay.GetDirection.Scale(t);

    Result := closestPoint1.Distance(closestPoint2);
  end
  else
    Result := -1;

end;

function TaeRay3.GetOrgin: TPoint3D;
begin
  Result := self._orgin;
end;

{ TaeTriangle }

constructor TaeTriangle.Create(V0, V1, V2: TPoint3D);
begin
  self._v0 := V0;
  self._v1 := V1;
  self._v2 := V2;
end;

constructor TaeTriangle.Create(v0x, v0y, v0z, v1x, v1y, v1z, v2x, v2y, v2z: single);
begin
  self._v0.Create(v0x, v0y, v0z);
  self._v1.Create(v1x, v1y, v1z);
  self._v2.Create(v2x, v2y, v2z);
end;

function TaeTriangle.Intersect(ray: TaeRay3; var dist: single): boolean;
var
  // Möller–Trumbore intersection algorithm variables
  p, q, e1, e2, Tp: TPoint3D; // Edge1, Edge2
  det, inv_det, u, v: single;
begin

      /// /Find vectors for two edges sharing V1
  e1 := _v1 - _v0;
  e2 := _v2 - _v0;
      // Begin calculating determinant - also used to calculate u parameter
  p := ray.GetDirection.CrossProduct(e2);
      // if determinant is near zero, ray lies in plane of triangle
  det := e1.DotProduct(p);
      // NOT CULLING
  if ((det > -AE_EPSILON) and (det < AE_EPSILON)) then
  begin
    Result := false;
    exit;
  end;

  inv_det := 1.0 / det;

      // calculate distance from V1 to ray origin
  Tp := ray.GetOrgin - V0;

      // Calculate u parameter and test bound
  u := Tp.DotProduct(p) * inv_det;

      // The intersection lies outside of the triangle?
  if ((u < 0.0) or (u > 1.0)) then
  begin
    Result := false;
    exit;
  end;

      // Prepare to test v parameter
  q := Tp.CrossProduct(e1);

      // Calculate V parameter and test bound
  v := q.DotProduct(ray.GetDirection) * inv_det;

      // The intersection lies outside of the triangle?
  if ((v < 0.0) or ((v + u) > 1.0)) then
  begin
    Result := false;
    exit;
  end;
  dist := e2.DotProduct(q) * inv_det;

  if (dist > AE_EPSILON) then
  begin
    Result := true;
    exit;
  end;

  dist := 0.0;
  Result := false;
end;

{ TaePlane3 }

constructor TaePlane3.Create(p, normal: TPoint3D);
begin
  self._p := p;
  self._normal := normal;
end;

function TaePlane3.GetNormal: TPoint3D;
begin
  Result := self._normal;
end;

function TaePlane3.GetPoint: TPoint3D;
begin
  Result := self._p;
end;

function TaePlane3.Intersect(ray: TaeRay3; var dist: single; var intersectionPoint: TPoint3D): boolean;
var
  nDotD: single;
begin
  Result := false;
  nDotD := self._normal.DotProduct(ray.GetDirection);

  if (nDotD = 0) then
    exit;

  dist := (-self._normal.DotProduct(ray.GetOrgin - self.GetPoint) / nDotD);

  intersectionPoint := ray.GetOrgin + (ray.GetDirection.Scale(dist));

  Result := true;
end;

{ TaeQuaternion }

constructor TaeQuaternion.Create(X, Y, Z, w: single);
begin
  self._x := X;
  self._y := Y;
  self._z := Z;
  self._w := w;
end;

constructor TaeQuaternion.Create(q: TaeQuaternion);
begin
  self.Create(q.X, q.Y, q.Z, q.w);
end;

procedure TaeQuaternion.loadIdentity;
begin
  self.X := 0.0;
  self.Y := 0.0;
  self.Z := 0.0;
  self.w := 1.0;
end;

procedure TaeQuaternion.LookAt(direction, vec_up: TPoint3D);
var
  right, newup: TPoint3D;
  V1, V2, v3: TPoint3D;
  rot1, rot2, combined: TaeQuaternion;
begin
  v3 := direction.Normalize;
  V1 := vec_up.CrossProduct(direction).Normalize;
  V2 := direction.CrossProduct(V1).Normalize;
  self.SetFromAxis(V1, V2, v3);
// if direction.Length < AE_EPSILON then
// begin
// self.loadIdentity;
// exit;
// end;
//
// right := direction.CrossProduct(vec_up);
// vec_up := right.CrossProduct(direction);
//
// rot1.SetToRotationBetweenVectors(Point3D(0, 0, 1), direction);
// newup := rot1 * Point3D(0, 1, 0);
// rot2.SetToRotationBetweenVectors(newup, vec_up);
// combined := rot2 * rot1;
// self.x := combined.x;
// self.y := combined.y;
// self.z := combined.z;
// self.w := combined.w;
end;

class operator TaeQuaternion.Multiply(a: TaeQuaternion; v: TPoint3D): TPoint3D;
var
  vx, vy, vz: single;
begin

  if (v.Length = 0) then
  begin
    Result.Create(0, 0, 0);
    exit;
  end;

  vx := v.X;
  vy := v.Y;
  vz := v.Z;
  Result.X := a.w * a.w * vx + 2 * a.Y * a.w * vz - 2 * a.Z * a.w * vy + a.X * a.X * vx + 2 * a.Y * a.X * vy + 2 * a.Z * a.X * vz - a.Z * a.Z * vx - a.Y * a.Y * vx;
  Result.Y := 2 * a.X * a.Y * vx + a.Y * a.Y * vy + 2 * a.Z * a.Y * vz + 2 * a.w * a.Z * vx - a.Z * a.Z * vy + a.w * a.w * vy - 2 * a.X * a.w * vz - a.X * a.X * vy;
  Result.Z := 2 * a.X * a.Z * vx + 2 * a.Y * a.Z * vy + a.Z * a.Z * vz - 2 * a.w * a.Y * vx - a.Y * a.Y * vz + 2 * a.w * a.X * vy - a.X * a.X * vz + a.w * a.w * vz;
end;

class operator TaeQuaternion.Multiply(a, b: TaeQuaternion): TaeQuaternion;
begin
  Result.X := (b.w * a.X) + (b.X * a.w) + (b.Y * a.Z) - (b.Z * a.Y);
  Result.Y := (b.w * a.Y) - (b.X * a.Z) + (b.Y * a.w) + (b.Z * a.X);
  Result.Z := (b.w * a.Z) + (b.X * a.Y) - (b.Y * a.X) + (b.Z * a.w);
  Result.w := (b.w * a.w) - (b.X * a.X) - (b.Y * a.Y) - (b.Z * a.Z);
end;

function TaeQuaternion.Norm: single;
begin
  Result := w * w + X * X + Y * Y + Z * Z;
end;

procedure TaeQuaternion.Normalize;
var
  n: single;
begin
  n := invSqrt_fast(self.Norm());
  X := X * n;
  Y := Y * n;
  Z := Z * n;
  w := w * n;

end;

procedure TaeQuaternion.Orientate(direction_vector: TPoint3D);
var
  dot, angle: single;
  cross: TPoint3D;
begin
  dot := direction_vector.DotProduct(Point3D(0, 0, 1));
  angle := ArcCos(dot);
  cross := direction_vector.CrossProduct(Point3D(0, 0, 1)).Normalize;
  self.SetFromAngleAxis(angle, cross);
end;

procedure TaeQuaternion.SetFromAngleAxis(radians: single; axis: TPoint3D);
var
  NormAxis: TPoint3D;
  halfAngle, sin_s: single;
begin
  NormAxis := axis.Normalize;

  if (NormAxis.X = 0) and (NormAxis.Y = 0) and (NormAxis.Z = 0) then
    self.loadIdentity
  else
  begin
    halfAngle := 0.5 * radians;
    sin_s := sin(halfAngle);
    w := cos(halfAngle);
    X := sin_s * axis.X;
    Y := sin_s * axis.Y;
    Z := sin_s * axis.Z;
  end;
end;

procedure TaeQuaternion.SetFromAngles(yaw, roll, pitch: single);
var
  sinRoll, sinPitch, sinYaw, cosRoll, cosPitch, cosYaw: single;
  angle, cosRollXcosPitch, sinRollXsinPitch, cosRollXsinPitch, sinRollXcosPitch: single;
begin
  angle := pitch * 0.5;
  sinPitch := sin(angle);
  cosPitch := cos(angle);
  angle := roll * 0.5;
  sinRoll := sin(angle);
  cosRoll := cos(angle);
  angle := yaw * 0.5;
  sinYaw := sin(angle);
  cosYaw := cos(angle);

  // variables used to reduce multiplication calls.
  cosRollXcosPitch := cosRoll * cosPitch;
  sinRollXsinPitch := sinRoll * sinPitch;
  cosRollXsinPitch := cosRoll * sinPitch;
  sinRollXcosPitch := sinRoll * cosPitch;

  self.w := (cosRollXcosPitch * cosYaw - sinRollXsinPitch * sinYaw);
  self.X := (cosRollXcosPitch * sinYaw + sinRollXsinPitch * cosYaw);
  self.Y := (sinRollXcosPitch * cosYaw + cosRollXsinPitch * sinYaw);
  self.Z := (cosRollXsinPitch * cosYaw - sinRollXcosPitch * sinYaw);

  self.Normalize();
end;

procedure TaeQuaternion.SetFromAxis(X, Y, Z: TPoint3D);
var
  t, Scale: single;
begin
  t := X.X + Y.Y + Z.Z;

  if (t > 0.0) then
  begin
    Scale := sqrt(t) * 2.0;
    self.X := (Y.Z - Z.Y) / Scale;
    self.Y := (Z.X - X.Z) / Scale;
    self.Z := (X.Y - Y.X) / Scale;
    self.w := 0.25 * Scale;
  end
  else if (X.X > Y.Y) and (X.X > Z.Z) then
  begin
    Scale := sqrt(1.0 + X.X - Y.Y - Z.Z) * 2.0;
    self.X := 0.25 * Scale;
    self.Y := (Y.X + X.Y) / Scale;
    self.Z := (X.Z + Z.X) / Scale;
    self.w := (Y.Z - Z.Y) / Scale;
  end
  else if (Y.Y > Z.Z) then
  begin
    Scale := sqrt(1.0 + Y.Y - X.X - Z.Z) * 2.0;
    self.X := (X.Y + Y.X) / Scale;
    self.Y := 0.25 * Scale;
    self.Z := (Z.Y + Y.Z) / Scale;
    self.w := (Z.X - X.Z) / Scale;
  end
  else
  begin
    Scale := sqrt(1.0 + 1.0 - X.X - Y.Y) * 2.0;
    self.X := (Z.X + X.Z) / Scale;
    self.Y := (Z.Y + Y.Z) / Scale;
    self.Z := 0.25 * Scale;
    self.w := (X.Y - Y.X) / Scale;
  end;
  self.Normalize;
end;

procedure TaeQuaternion.SetFromRotationMatrix(m: TaeMatrix44);
var
  X, Y, Z: TPoint3D;

begin
  X := m.GetRotationVectorX;
  Y := m.GetRotationVectorY;
  Z := m.GetRotationVectorZ;
  self.SetFromAxis(X, Y, Z);
end;

procedure TaeQuaternion.SetToRotationBetweenVectors(start, dest: TPoint3D);
var
  s, invS, cosTheta: single;
  rotationAxis: TPoint3D;

begin
  start := start.Normalize;
  dest := dest.Normalize;
  start.DotProduct(dest);
  if (cosTheta < -1 + AE_EPSILON) then
  begin
        // special case when vectors in opposite directions:
        // there is no "ideal" rotation axis
        // So guess one; any will do as long as it's perpendicular to start
    rotationAxis := Point3D(0, 0, 1).CrossProduct(start);

    if (rotationAxis.Length < 0.01) then // bad luck, they were parallel, try again!
      rotationAxis := Point3D(0, 0, 1).CrossProduct(start);

    rotationAxis := rotationAxis.Normalize;
    self.SetFromAngleAxis(180.0 * AE_PI_DIV_180, rotationAxis);
    exit;
  end;

  rotationAxis := start.CrossProduct(dest);
  s := sqrt((1 + cosTheta) * 2);
  invS := 1 / s;
  self._x := rotationAxis.X * invS;
  self._y := rotationAxis.Y * invS;
  self._z := rotationAxis.Z * invS;
  self._w := s * 0.5;

end;

(*
  [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]  [8]  [9] [10] [11] [12] [13] [14] [15]
  [m11  m21  m31  m41  m12  m22  m32  m42  m13  m23  m33  m43  m14 m24 m34  m44]
    1    0    0    0    0    1    0    0    0    0   1    0    tx   ty   tz    1
*)
function TaeQuaternion.ToRotationMatrix: TaeMatrix44;
var
  xx, xy, xz, xw, yy, yz, yw, zz, zw: single;
  vx, vy, vz: TPoint3D;
begin
  xx := X * X;
  xy := X * Y;
  xz := X * Z;
  xw := X * w;

  yy := Y * Y;
  yz := Y * Z;
  yw := Y * w;

  zz := Z * Z;
  zw := Z * w;

  Result.loadIdentity;
  vx.X := 1 - 2 * (yy + zz);
  vx.Y := 2 * (xy - zw);
  vx.Z := 2 * (xz + yw);
  Result.SetRotationVectorX(vx);

  vy.X := 2 * (xy + zw);
  vy.Y := 1 - 2 * (xx + zz);
  vy.Z := 2 * (yz - xw);
  Result.SetRotationVectorY(vy);

  vz.X := 2 * (xz - yw);
  vz.Y := 2 * (yz + xw);
  vz.Z := 1 - 2 * (xx + yy);
  Result.SetRotationVectorZ(vz);
end;

end.
