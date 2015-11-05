unit aeMaterial;

interface

uses types, aeColor, dglOpenGL;

type
  TaeMaterialRenderMode = (AE_MATERIAL_RENDERMODE_TRIANGLES, AE_MATERIAL_RENDERMODE_WIREMESH);

type
  TaeMaterial = class
  private
    _color: TaeColor;
    // opengl mode : GL_POINTS, GL_LINE_STRIP, GL_LINE_LOOP, GL_LINES,
    // GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, GL_TRIANGLES,
    // GL_QUAD_STRIP, GL_QUADS, und GL_POLYGON
    _renderMode: TaeMaterialRenderMode;

  public
    property Color: TaeColor read _color write _color;
    property Rendermode: TaeMaterialRenderMode read _renderMode write _renderMode;
    constructor Create;
  end;

implementation

{ TaeMaterial }

constructor TaeMaterial.Create;
begin
  self._color := TaeColor.Create(); // start with white default!
  self._renderMode := AE_MATERIAL_RENDERMODE_TRIANGLES; // default : wiremesh
end;

end.
