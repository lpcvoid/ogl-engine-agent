unit aeTransform;

interface

uses types, aeConst, aeMaths;

type
  TaeTransform = class
  protected
    _rotation: TaeMatrix44;
    // _rotation: TaeQuaternion;
    _position: TPoint3D;
    _scale: TPoint3D;

  public
    constructor Create;

    procedure CopyTransformFrom(t: TaeTransform);
    procedure Reset;

    procedure RotateRadians(axis: TPoint3D; radians: single);
    procedure RotateDegrees(axis: TPoint3D; degrees: single);
    procedure SetRotationMatrix(m: TaeMatrix44);
    // procedure SetQuaternion(q: TaeQuaternion);
    function GetRotation: TaeMatrix44;

    procedure SetScale(s: single); overload;
    procedure SetScale(X, y, z: single); overload;
    procedure SetScale(p: TPoint3D); overload;
    function GetScale: TPoint3D;

    procedure LookAt(own_pos, target_pos, up_vector: TPoint3D);
    procedure Orientate(target_pos, up_vector: TPoint3D);

    function GetPosition: TPoint3D;
    procedure SetPosition(p: TPoint3D);

    function Clone: TaeTransform;

  end;

implementation

{ TaeTransform }

function TaeTransform.Clone: TaeTransform;
begin
  result := TaeTransform.Create;
  result._rotation := self._rotation;
  result._scale := self._scale;
  result._position := self._position;
end;

procedure TaeTransform.CopyTransformFrom(t: TaeTransform);
begin
  if (t <> nil) then
  begin
    self.SetRotationMatrix(t.GetRotation);
    self.SetPosition(t.GetPosition);
    self.SetScale(t.GetScale);
  end;
end;

constructor TaeTransform.Create;
begin
  self.Reset;
end;

function TaeTransform.GetPosition: TPoint3D;
begin
  result := self._position;
end;

function TaeTransform.GetRotation: TaeMatrix44;
begin
  result := self._rotation;
end;

function TaeTransform.GetScale: TPoint3D;
begin
  result := self._scale;
end;

procedure TaeTransform.LookAt(own_pos, target_pos, up_vector: TPoint3D);
var
  _up, _right, _forward: TPoint3D;
begin
  self.SetPosition(own_pos);
  self.Orientate(target_pos, up_vector);
end;

// RIGHT HANDED!
// http://gamedev.stackexchange.com/a/8845
procedure TaeTransform.Orientate(target_pos, up_vector: TPoint3D);
var
  _up, _right, _forward: TPoint3D;
begin
  _forward := (self._position - target_pos).Normalize;
  _right := _forward.CrossProduct(up_vector).Normalize;
  _up := _right.CrossProduct(_forward).Normalize;

  self._rotation.loadIdentity;
  self._rotation.SetRotationVectorX(_right);
  self._rotation.SetRotationVectorY(_up);
  self._rotation.SetRotationVectorZ(_forward);

end;

procedure TaeTransform.Reset;
begin
  self._rotation.loadIdentity;
  self._scale.Create(1.0, 1.0, 1.0);
  self._position.Create(0, 0, 0);
end;

procedure TaeTransform.RotateDegrees(axis: TPoint3D; degrees: single);
begin
  self.RotateRadians(axis, degrees * AE_PI_DIV_180);
end;

procedure TaeTransform.RotateRadians(axis: TPoint3D; radians: single);
begin
  // _rotation.loadIdentity;
  _rotation.SetRotation(axis, radians);
end;

procedure TaeTransform.SetScale(s: single);
begin
  self._scale.Create(s, s, s);

end;

procedure TaeTransform.SetRotationMatrix(m: TaeMatrix44);
begin
  self._rotation := m;
end;

procedure TaeTransform.SetScale(p: TPoint3D);
begin
  self._scale := p;
end;

procedure TaeTransform.SetScale(X, y, z: single);
begin
  self._scale.X := X;
  self._scale.y := y;
  self._scale.z := z;
end;

procedure TaeTransform.SetPosition(p: TPoint3D);
begin
  self._position := p;
end;

// procedure TaeTransform.SetQuaternion(q: TaeQuaternion);
// begin
// self._rotation := q;
// end;

end.
