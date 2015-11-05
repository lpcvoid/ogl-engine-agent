unit aeCamera;

interface

uses types, aeSceneNode, aeSceneObject, aeMaths, aeTransform, aeDebugHelpers;

type
  TaeCameraViewType = (AE_CAMERA_VIEW_LOOKATCENTER, AE_CAMERA_VIEW_LOOKFROMCENTER);

// type
// IaeBaseCamera = Interface(IInterface)
// procedure LookAt(pos: TPoint3D);
// End;
//
// type
// TaeArcBallCamera = class(TInterfacedObject, IaeBaseCamera)
//
// end;

type
  TaeCamera = class
  public
    Constructor Create(targetObject: TaeSceneObject);
    procedure SetCenterObject(o: TaeSceneObject);
    procedure SetMousePosition(p: TPoint);
    procedure SetDistance(d: single);
    procedure SetCameraViewType(vt: TaeCameraViewType);
    function GetCameraViewtype: TaeCameraViewType;
    function GetCameraTarget: TaeSceneObject;
    procedure MoveForward(dist: single);
    function GetSphere: TaeSphere;
    function GetTransformMatrix: TaeMatrix44;
    procedure SetMinHeight(m: single);
    function getPosition: TPoint3D;
    function GetProjectionMatrix: TaeMatrix44;
    procedure SetViewPortSize(w, h: integer);
    procedure SetFieldOfView(fov: single);
    function GetFieldOfView: single;
    procedure SetZNearClippingPlane(zn: single);
    procedure SetZFarClippingPlane(zf: single);
  private
    // used for arcball orientation
    _arcBallCenter: TaeSceneObject;

    _transform: TaeTransform;

    _projectionMatrix: TaeMatrix44;
    _viewPortWidth, _viewPortHeight: integer;
    _projectionChanged: boolean;
    _fovY: single;
    _zNear, _zFar: single;

    _sensitivity: single;

    _sphere: TaeSphere;

    _viewType: TaeCameraViewType;

    _speed: single;

    // if current height is lower than this, we need to adjust.
    _minHeight: single;

    function GetLookAtPoint: TPoint3D;

  end;

implementation

{ TaeCamera }

constructor TaeCamera.Create(targetObject: TaeSceneObject);
begin
  if (targetObject <> nil) then
  begin
    self.SetCenterObject(targetObject);
  end;
  self._transform := TaeTransform.Create;
  self._sphere.Create(5.0);
  self._sensitivity := 0.01;

  self._speed := 1.0;

  self._viewType := AE_CAMERA_VIEW_LOOKATCENTER; // by default, we want an arcball cam.

  // default
  self._fovY := 60.0;
  self._zNear := 0.1;
  self._zFar := 10000.0;
  // aspect 1920/1080
  self._projectionMatrix.SetPerspective(self._fovY, 1.7777, self._zNear, self._zFar);
  self._projectionChanged := false;

end;

function TaeCamera.GetCameraTarget: TaeSceneObject;
begin
  Result := self._arcBallCenter;
end;

function TaeCamera.GetCameraViewtype: TaeCameraViewType;
begin
  Result := self._viewType;
end;

function TaeCamera.GetFieldOfView: single;
begin
  Result := self._fovY;
end;

function TaeCamera.GetLookAtPoint: TPoint3D;
begin
  case self._viewType of
    AE_CAMERA_VIEW_LOOKATCENTER:
      Result := self._arcBallCenter.getPosition;

    AE_CAMERA_VIEW_LOOKFROMCENTER:
      Result := self._sphere.Get3DPoint(AE_AXIS_ORDER_XZY) + self.getPosition();
  end;
end;

function TaeCamera.getPosition: TPoint3D;
begin
  case self._viewType of
    AE_CAMERA_VIEW_LOOKATCENTER:
      Result := self._sphere.Get3DPoint(AE_AXIS_ORDER_XZY) + self._arcBallCenter.getPosition;
    AE_CAMERA_VIEW_LOOKFROMCENTER:
      Result := self._arcBallCenter.getPosition;
  end;

end;

function TaeCamera.GetProjectionMatrix: TaeMatrix44;
begin
  if (self._projectionChanged) then
  begin
    self._projectionMatrix.SetPerspective(self._fovY, self._viewPortWidth / self._viewPortHeight, self._zNear, self._zFar);
    self._projectionChanged := false;
  end;

  Result := self._projectionMatrix;
end;

function TaeCamera.GetSphere: TaeSphere;
begin
  Result := self._sphere;
end;

function TaeCamera.GetTransformMatrix: TaeMatrix44;
var
  trans: TaeMatrix44;
  pos: TPoint3D;
begin
  case self._viewType of
    AE_CAMERA_VIEW_LOOKATCENTER:
      self._transform.LookAt(self.getPosition(), self._arcBallCenter.getPosition, Point3D(0.0, 1.0, 0.0));

    AE_CAMERA_VIEW_LOOKFROMCENTER:
      self._transform.LookAt(self.getPosition(), self._sphere.Get3DPoint(AE_AXIS_ORDER_XZY) + self.getPosition(), Point3D(0.0, 1.0, 0.0));
  end;

  trans.loadIdentity;
  pos := self.getPosition();
  if (pos.Y < self._minHeight) then
    pos.Y := self._minHeight;
  trans.SetTranslation(pos);

  Result.loadIdentity;
  Result := Result * self._transform.GetRotation;
  Result := Result * trans;
  // we need to invert camera's transform matrix to make it a view matrix.
  // view_mat = trans_mat^-1

  Result := Result.Invert;



  //

end;

procedure TaeCamera.MoveForward(dist: single);
var
  forwardVector, newPos, oldPos: TPoint3D;

begin
  forwardVector := (self.GetLookAtPoint - self.getPosition).Normalize;
  // forwardVector := forwardVector.Negative;
  case self._viewType of
    AE_CAMERA_VIEW_LOOKATCENTER:
      begin
        oldPos := self.getPosition;
        newPos := oldPos + forwardVector.Scale(self._speed * dist);

        PrintDebugMessage('OldPos : ' + PrintPoint3D(oldPos) + ' | NewPos : ' + PrintPoint3D(newPos));

        self._arcBallCenter.Move(newPos);
      end;

    AE_CAMERA_VIEW_LOOKFROMCENTER:
      begin
        newPos := self.getPosition;
        newPos := newPos + forwardVector.Scale(self._speed * dist);
        self._arcBallCenter.Move(newPos);
      end;
  end;

end;

procedure TaeCamera.SetCameraViewType(vt: TaeCameraViewType);
begin
  self._viewType := vt;
end;

procedure TaeCamera.SetDistance(d: single);
begin
  // Distance is irrelevant when we look from center into world.
  if (self._viewType = AE_CAMERA_VIEW_LOOKATCENTER) then
  begin
    self._sphere.Radius := self._sphere.Radius + d;

    if (self._sphere.Radius < 1.0) then
      self._sphere.Radius := 1.0;
  end;
end;

procedure TaeCamera.SetFieldOfView(fov: single);
begin
  self._fovY := fov;
  self._projectionChanged := true;
end;

procedure TaeCamera.SetMinHeight(m: single);
begin
  self._minHeight := m;
end;

procedure TaeCamera.SetMousePosition(p: TPoint);
begin

  self._sphere.theta := self._sphere.theta + p.Y * _sensitivity;

  self._sphere.phi := self._sphere.phi - p.x * _sensitivity;
end;

procedure TaeCamera.SetViewPortSize(w, h: integer);
begin
  self._viewPortWidth := w;
  self._viewPortHeight := h;
  self._projectionChanged := true;
end;

procedure TaeCamera.SetZFarClippingPlane(zf: single);
begin
  self._zFar := zf;
  self._projectionChanged := true;
end;

procedure TaeCamera.SetZNearClippingPlane(zn: single);
begin
  self._zNear := zn;
  self._projectionChanged := true;
end;

procedure TaeCamera.SetCenterObject(o: TaeSceneObject);
begin
  self._arcBallCenter := o;
end;

end.
