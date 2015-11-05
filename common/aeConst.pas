unit aeConst;

interface

uses types;

const
  AE_PI_DIV_180 = 0.017453;
  AE_180_DIV_PI = 57.295780;
  AE_PI = 3.1415927;
  AE_PI_MULT2 = 6.28318;
  AE_PI_DIV2 = 1.570796;

  AE_FLT_MAX = 3.40282347E+38;
  AE_FLT_MIN = 1.17549435E-38;

  AE_EPSILON = 0.00001;

  AE_LOGGING_LOG_PATH = 'ae_log.txt'; // next to executable



type
  TaeTVectorArrayPointer = ^TVectorArray;

type
  TaeMeshLevelOfDetail = (AE_MESH_LOD_HIGH, AE_MESH_LOD_MID, AE_MESH_LOD_LOW);

  // every height data source must have a method which looks like this
type
  TaeTerrainGetHeightCall = function(x, y: single): single of object;

implementation

end.
