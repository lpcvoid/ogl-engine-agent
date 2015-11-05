unit aeSceneObject;

interface

(*


  Base scene object.
  Can keep track of its orientation and translation in space.
  Used for a base class for other scene graph things.

*)
uses types, math, aeConst, aeTransform, System.Generics.Collections, aeMaths, sysutils;

type
  TaeSetDirtyCallback = procedure of object;

type
  TaeSceneObject = class
    constructor Create;

    // set callback to signal to node that it has to put children dirty.
    procedure SetDirtyCallback(callback: TaeSetDirtyCallback);
/// <summary>
    /// Rotate around axis. Angle in degrees.
    /// </summary>
    procedure Rotate(axis: TPoint3D; degrees: single);
    procedure SetRotation(rotationmatrix: TaeMatrix44);

    /// <summary>
    /// Set translation.
    /// </summary>
    procedure Move(p: TPoint3D);
    function getPosition: TPoint3D;
    function GetPositionString: string;
    function GetForwardVector: TPoint3D;
    procedure SetMinimumHeight(mh: single);

    /// <summary>
    /// Set scale.
    /// </summary>
    procedure Scale(Scale: single); overload;
    procedure Scale(x, y, z: single); overload;

    /// <summary>
    /// Orientate this object towards some point.
    /// </summary>
    procedure LookAt(own_pos, target_pos: TPoint3D); overload;
    procedure LookAt(own_pos, target_pos, up_vector: TPoint3D); overload;
    procedure LookAt(own_pos: TPoint3D; obj: TaeSceneObject); overload;

    function GetLocalTransformMatrix: TaeMatrix44;
    function GetLocalTransform: TaeTransform;

    procedure resetOrientation;

    function IsLocalTransformDirty: boolean;
    procedure SetLocalTransformDirty(dirty: boolean);

  private
    // this transform contains stuff done to only this object!
    _localTransform: TaeTransform;
    // this matrix contains the sum of all transformations
    _localTransformMatrix: TaeMatrix44;

    // pointer to a procedure which is called after a transform is applied.
    _dirtyCallback: TaeSetDirtyCallback;

    // minimum height that this object can go!
    _minHeight: single;

  protected
      // transform dirty flag.
    _localTransformDirty: boolean;

  end;

implementation

{ TaeSceneObject }

constructor TaeSceneObject.Create;
begin
  self._localTransform := TaeTransform.Create;
  self.resetOrientation;
  self._minHeight := 0.0;
  self.SetLocalTransformDirty(false);
  self._dirtyCallback := nil;
  self._localTransformMatrix.loadIdentity;
  // self._transformStack := TList<TaeTransform>.Create;
end;

// function TaeSceneObject.GetLocalTransformMatrix: TaeMatrix44;
// begin
// result := self._localTransform.getTransformMatrix();
// end;

procedure TaeSceneObject.LookAt(own_pos, target_pos: TPoint3D);
begin
  self._localTransform.LookAt(own_pos, target_pos, Point3D(0, 1, 0));
  self.SetLocalTransformDirty(true);
end;

procedure TaeSceneObject.LookAt(own_pos: TPoint3D; obj: TaeSceneObject);
begin
  self.LookAt(own_pos, obj.getPosition);
end;

procedure TaeSceneObject.LookAt(own_pos, target_pos, up_vector: TPoint3D);
begin

  self._localTransform.LookAt(own_pos, target_pos, up_vector);
  self.SetLocalTransformDirty(true);
end;

procedure TaeSceneObject.resetOrientation;
begin
  self._localTransform.Reset;
  self.SetLocalTransformDirty(true);
end;

procedure TaeSceneObject.Rotate(axis: TPoint3D; degrees: single);
begin
  self._localTransform.RotateDegrees(axis, degrees);
  self.SetLocalTransformDirty(true);
end;

function TaeSceneObject.getPosition: TPoint3D;
begin
  result := self._localTransform.getPosition;
end;

function TaeSceneObject.GetPositionString: string;
var
  p: TPoint3D;
begin
  p := self.getPosition;
  result := 'X=' + FloatToStr(RoundTo(p.x, -2)) + ' Y=' + FloatToStr(RoundTo(p.y, -2)) + 'Z=' + FloatToStr(RoundTo(p.z, -2));
end;

function TaeSceneObject.IsLocalTransformDirty: boolean;
begin
  result := self._localTransformDirty;
end;

function TaeSceneObject.GetForwardVector: TPoint3D;
begin
  // result := (Point3D(0, 0, 1) * self._localTransform).Normalize;
end;

function TaeSceneObject.GetLocalTransform: TaeTransform;
begin
  result := self._localTransform;
end;

function TaeSceneObject.GetLocalTransformMatrix: TaeMatrix44;
var
  Translate, Scale, Rotation: TaeMatrix44;
begin
 // 1. rotate 2. scale  3. translate
 // opengl uses left multiplication
 // we need to apply the transformations in reverse order

  if (self.IsLocalTransformDirty) then
  begin

    Translate.loadIdentity;
    Translate.SetTranslation(self._localTransform.getPosition);

    Scale.loadIdentity;
    Scale.SetScale(self._localTransform.GetScale);

    Rotation.loadIdentity;
    Rotation := self._localTransform.GetRotation;

    self._localTransformMatrix.loadIdentity;

    self._localTransformMatrix := self._localTransformMatrix * Scale;

    self._localTransformMatrix := self._localTransformMatrix * Rotation;

    self._localTransformMatrix := self._localTransformMatrix * Translate;

    self._localTransformDirty := false;
  end;

  result := _localTransformMatrix;

end;

procedure TaeSceneObject.Move(p: TPoint3D);
begin
  if (p <> self._localTransform.getPosition) then
  begin
    self._localTransform.SetPosition(p);
    self.SetLocalTransformDirty(true);
  end;
end;

procedure TaeSceneObject.Scale(Scale: single);
begin
  self._localTransform.SetScale(Scale);
  self.SetLocalTransformDirty(true);
end;

procedure TaeSceneObject.SetLocalTransformDirty(dirty: boolean);
begin
  self._localTransformDirty := dirty;
  // notify callback if it's set that all children are to be flagged as dirty!
  // this only applies if this class is inherited by a Node.
  if (Assigned(self._dirtyCallback)) then
    self._dirtyCallback;
end;

procedure TaeSceneObject.Scale(x, y, z: single);
begin
  self._localTransform.SetScale(x, y, z);
  self.SetLocalTransformDirty(true);
end;

procedure TaeSceneObject.SetDirtyCallback(callback: TaeSetDirtyCallback);
begin
  self._dirtyCallback := callback;
end;

procedure TaeSceneObject.SetMinimumHeight(mh: single);
begin
  self._minHeight := mh;
end;

procedure TaeSceneObject.SetRotation(rotationmatrix: TaeMatrix44);
begin
  self._localTransform.SetRotationMatrix(rotationmatrix);
  self.SetLocalTransformDirty(true);
end;

end.
