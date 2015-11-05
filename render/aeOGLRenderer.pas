unit aeOGLRenderer;

interface

uses windows, aeSceneNode, dglOpenGL, aeSceneGraph, System.Generics.Collections, strutils,
  aeGeometry, aeMesh, aeCamera, aeMaterial, aeMaths, aeBoundingVolume, aeOBB, types, aeRenderable, aeTerrain, aeConst, aePrimitiveShapes;

type
  TaeOGLRenderer = class
    Constructor Create(renderHandle: THandle; width, height: cardinal);
    procedure setRenderSize(width, height: cardinal);
    procedure clearRenderDisplay();
    procedure render; // lol
    procedure setSceneGraph(sg: TaeSceneGraph);
    procedure setCamera(cam: TaeCamera);
    function getCamera(): TaeCamera;

    procedure SetGeometryRenderDistance(dist: single);
    function GetGeometryRenderDistance: single;

  protected
    DC: HDC; // Handle auf Zeichenfläche
    RC: HGLRC; // Rendering Context
    _scene: TaeSceneGraph;
    _activeCamera: TaeCamera;

    _geometry_render_distance: single;

    procedure drawGrid(size, step: cardinal);
  end;

implementation

{ TaeOGLRenderer }

constructor TaeOGLRenderer.Create(renderHandle: THandle; width, height: cardinal);
begin
  if (InitOpenGL()) then
  begin
    self.DC := GetDC(renderHandle);
    self.RC := CreateRenderingContext(self.DC, // Device Context
      [opDoubleBuffered], // Options
      32, // ColorBits
      24, // ZBits
      0, // StencilBits
      0, // AccumBits
      0, // AuxBuffers
      0); // Layer
    ActivateRenderingContext(self.DC, self.RC);
    self.setRenderSize(width, height);
    glEnable(GL_DEPTH_TEST); // we want depth testing!
    // Set8087CW($133F); // disable all floating-point exceptions for performance reasons

    self.SetGeometryRenderDistance(500.0);
  end;
end;

function TaeOGLRenderer.getCamera: TaeCamera;
begin
  Result := self._activeCamera;
end;

function TaeOGLRenderer.GetGeometryRenderDistance: single;
begin
  Result := self._geometry_render_distance;
end;

procedure TaeOGLRenderer.render;
var
  sceneGeo: TList<TaeSceneNode>;
  meshes: TList<TaeMesh>;
  primitiveshapeNode: TaePrimitiveShapeNode;
  i, e: integer;
  geo: TaeGeometry;
  // bounding volume stuff
  meshBoundingVolume: TaeBoundingVolume;
  meshAABB: TaeOBB;
  // ********
  // debug camera stuff
  // cam_p: TPoint3D;
  // cam: TaeCameraArcball;
  // playerNode: TaeSceneNode;
  // ********

  // ********
  // terrain stuff
  terrain_tiles: TaeVisableTerrainTiles;
  terrain: TaeTerrain;
  terrain_tile: TaeTerrainTile;
  // ********

  geo_matrix: TaeMatrix44;
  debug_modelview_matrix: Array [0 .. 15] of single;
  serializedCameraMatrix, serializedGeoMatrix: TaeSerializedMatrix44;
  terrain_counter: integer;
begin
  glEnableClientState(GL_VERTEX_ARRAY); // why do I have to re-toggle this every frame?
  // glClearColor(0.137255, 0.419608, 0.556863, 1);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  // switch to modelview matrix.
  glMatrixMode(GL_MODELVIEW);
  // rest the modelview matrix!
  glLoadIdentity;

  // We need to do our camera stuff at start!
  // This is because every following transform will be multiplied with the camera matrix!
  if (self._activeCamera <> nil) then
  begin

    // gluLookAt(150, 150, 150, 0, 0, 0, 0, 1, 0);
    // glGetFloatv(GL_MODELVIEW_MATRIX, @debug_modelview_matrix[0]);
    // glLoadIdentity;

    serializedCameraMatrix := self._activeCamera.GetTransformMatrix.SerializeMatrix44(true);
    glMultMatrixf(@serializedCameraMatrix[0]);
  end;

  // self.drawGrid(250, 1);

  // First, we need a list of what to actually render
  sceneGeo := self._scene.ListChildren;
  // okay, let's loop all this stuff.

  // DEBUG

  // cam := TaeCameraArcball(self._activeCamera);
  // playerNode := self._scene.GetChildByName('player_node');
  // glColor3ub(255, 0, 100);
  // glBegin(GL_LINES);
  // glVertex3f(cam.getPosition.X, cam.getPosition.Y-2, cam.getPosition.Z);
  // glVertex3f(playerNode.getPosition.X, playerNode.getPosition.Y, playerNode.getPosition.Z);
  // glEnd;
  // DEBUG END

  for i := 0 to sceneGeo.Count - 1 do
  begin
    // alright, we need to load this into vram, right?

    case sceneGeo[i].getType of

      AE_SCENENODE_TYPE_GEOMETRY:
        begin
          glPushMatrix;

          geo := TaeGeometry(sceneGeo[i]);

          // check if geo is too far away to render!

          // if (geo.getPosition.Distance(self._activeCamera.getPosition) < self._geometry_render_distance) then
          begin

            serializedGeoMatrix := geo.GetWorldTransformationMatrix.SerializeMatrix44;
            glMultMatrixf(@serializedGeoMatrix[0]);

            meshes := geo.getMeshes;

            case geo.Material.Rendermode of
              AE_MATERIAL_RENDERMODE_TRIANGLES:
                begin
                  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
                // glEnable(GL_CULL_FACE);
                  //glDisable(GL_CULL_FACE);
                end;

              AE_MATERIAL_RENDERMODE_WIREMESH:
                begin
                // glEnable(GL_CULL_FACE);
                  glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
                // glEnable(GL_CULL_FACE);
                  glDisable(GL_CULL_FACE);
                end;
            end;

            for e := 0 to meshes.Count - 1 do
            begin
              glColor3ub(geo.Material.Color.getRed, geo.Material.Color.getGreen, geo.Material.Color.getBlue);

            // vbo manager checks if needed already!
              meshes[e].render;

            end;

            glColor3ub(0, 128, 128);
            // geo.getBoundingVolume.getBox.render(GL_LINE_STRIP);

          end;

          glPopMatrix;

        end;

      AE_SCENENODE_TYPE_LIGHT:
        begin
          // lightning...
        end;

      AE_SCENENODE_TYPE_TERRAIN:
        begin
          glPushMatrix;
          glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
          terrain := TaeTerrain(sceneGeo[i]);
          serializedGeoMatrix := terrain.GetWorldTransformationMatrix.SerializeMatrix44;
          glMultMatrixf(@serializedGeoMatrix[0]);
           // glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
          // glEnable(GL_CULL_FACE);
          terrain_tiles := terrain.GetVisableTiles;
          if (terrain_tiles.Count > 0) then
            for terrain_counter := 0 to terrain_tiles.Count - 1 do
            begin
              terrain_tile := terrain_tiles.tiles[terrain_counter];

              case terrain_tile.GetLOD of
                AE_MESH_LOD_HIGH:
                  glColor3ub(0, 255, 0);
                AE_MESH_LOD_MID:
                  glColor3ub(255, 0, 0);
                AE_MESH_LOD_LOW:
                  glColor3ub(128, 0, 128);

              end;

              // vbo manager checks if needed already!
              terrain_tile.render;
              // self.RenderBoundingVolume(terrain_tile.getBoundingVolume);
            end;

          glPopMatrix;
        end;

      AE_SCENENODE_TYPE_PRIMITIVESHAPE:
        begin
          glPushMatrix;

          glColor3ub(0, 255, 128);
          primitiveshapeNode := TaePrimitiveShapeNode(sceneGeo[i]);
          serializedGeoMatrix := primitiveshapeNode.GetWorldTransformationMatrix.SerializeMatrix44;
          glMultMatrixf(@serializedGeoMatrix[0]);
          primitiveshapeNode.RenderShapes;
// glBegin(GL_LINES);
// glVertex3f(0, 0, 0);
// glVertex3f(0, 1111, 0);
// glEnd;
          glPopMatrix;

        end;

    end;

  end;

  swapBuffers(self.DC);
  sceneGeo.Free;

end;

procedure TaeOGLRenderer.clearRenderDisplay;
begin
  glClear(GL_COLOR_BUFFER_BIT);
  glClearColor(0.3, 0.4, 0.7, 0.0);
end;

procedure TaeOGLRenderer.setCamera(cam: TaeCamera);
begin
  self._activeCamera := cam;
end;

procedure TaeOGLRenderer.SetGeometryRenderDistance(dist: single);
begin
  self._geometry_render_distance := dist;
end;

procedure TaeOGLRenderer.setRenderSize(width, height: cardinal);
var
  sm: TaeSerializedMatrix44;
begin
  glViewport(0, 0, width, height);
  glMatrixMode(GL_PROJECTION);

  if (self.getCamera <> nil) then
  begin
    self.getCamera.SetViewPortSize(width, height);
    sm := self.getCamera.GetProjectionMatrix.SerializeMatrix44();
    glLoadMatrixf(@sm[0]);
  end
  else
  begin
    glLoadIdentity;
    gluPerspective(60.0, width / height, 0.1, 10000.0);
  end;

  glMatrixMode(GL_MODELVIEW);
end;

procedure TaeOGLRenderer.setSceneGraph(sg: TaeSceneGraph);
begin
  self._scene := sg;
end;

procedure TaeOGLRenderer.drawGrid(size, step: cardinal);
var
  i: integer;
begin

  glBegin(GL_LINES);

  glColor3f(0.3, 0.3, 0.3);
  for i := 1 to (size - step) - 1 do
  begin
    glVertex3f(-size, 0, i);
              // lines parallel to X-axis
    glVertex3f(size, 0, i);
    glVertex3f(-size, 0, -i); // lines parallel to X-axis
    glVertex3f(size, 0, -i);

    glVertex3f(i, 0, -size); // lines parallel to Z-axis
    glVertex3f(i, 0, size);
    glVertex3f(-i, 0, -size); // lines parallel to Z-axis
    glVertex3f(-i, 0, size);
  end;

  // x-axis
  glColor3f(1.0, 0, 0);
  glVertex3f(size, 0, 0);
  glColor3f(0.5, 0, 0);
  glVertex3f(-size, 0, 0);

  // y-axis
  glColor3f(0, 1.0, 0);
  glVertex3f(0, size, 0);
  glColor3f(0, 0.5, 0);
  glVertex3f(0, -size, 0);

  // z-axis
  glColor3f(0, 0, 1.0);
  glVertex3f(0, 0, size);
  glColor3f(0, 0, 0.5);
  glVertex3f(0, 0, -size);

  glEnd();

end;

end.
