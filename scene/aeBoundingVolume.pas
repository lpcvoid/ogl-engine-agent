unit aeBoundingVolume;

interface

uses types, windows, aeMaths, aeRenderable, aeConst, aetypes;

// AE_BOUNDINGVOLUME_TYPE_UNINITILIZED means that we have an abstract, not good!
type
  TaeBoundingVolumeType = (AE_BOUNDINGVOLUME_TYPE_UNINITILIZED, AE_BOUNDINGVOLUME_TYPE_OBB);

type
  TaeBoundingVolume = class(TaeRenderable)
  public
    constructor Create;

    function distanceFromCenter(otherBV: TaeBoundingVolume): Single;
    /// <remarks>
    /// calculates bounding Volume from triangle data.
    /// </remarks>
    /// <returns>
    /// returns true if successful.
    /// </returns>
    function calculateBoundingVolume(vio: TaeVertexIndexBuffer; avarageCenter: boolean = false): boolean; virtual; abstract;
    function collideWith(otherBV: TaeBoundingVolume; var transformMatrix: TaeMatrix44): boolean; virtual; abstract;
    function Intersect(ray: TaeRay3; transformMatrix: TaeMatrix44): boolean; virtual; abstract;
    procedure clear; virtual; abstract;
    function getCenter: TPoint3D;
    function getType: TaeBoundingVolumeType;
  protected
    _type: TaeBoundingVolumeType;
    _center: TPoint3D;

  end;

implementation

{ TaeBoundingVolume }

constructor TaeBoundingVolume.Create;
begin
  self._type := AE_BOUNDINGVOLUME_TYPE_UNINITILIZED;
end;

function TaeBoundingVolume.distanceFromCenter(otherBV: TaeBoundingVolume): Single;
begin
  Result := self._center.Distance(otherBV.getCenter);
end;

function TaeBoundingVolume.getCenter: TPoint3D;
begin
  Result := self._center;
end;

function TaeBoundingVolume.getType: TaeBoundingVolumeType;
begin
  Result := self._type;
end;

end.
