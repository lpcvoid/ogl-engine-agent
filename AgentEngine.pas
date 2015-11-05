unit AgentEngine;

interface

uses windows, aeSceneNode, sysutils, dialogs, forms, aeConst, graphics, aeSceneGraph, aeOGLRenderer,
  System.Generics.Collections, aeCamera, aeLoaderManager, aeLoggingManager, classes, types;

type
  TAgentEngine = class
    SceneGraph: TaeSceneGraph;
    Renderer: TaeOGLRenderer;
    Loader: TaeLoaderManager;
    constructor Create();
    procedure enableRenderer(renderHandle: THandle; width, height: cardinal);
    procedure testNodes(nodeCount: cardinal);
    procedure CreatePlayerNodeAndCamera(name: string; start_position: TPoint3D);
    procedure SwapSceneGraph(newGraph: TaeSceneGraph);

  private

  end;

implementation

constructor TAgentEngine.Create();
begin
  Randomize;
  self.SceneGraph := TaeSceneGraph.Create;
  self.Loader := TaeLoaderManager.Create;
  AE_LOGGING.AddEntry('TAgentEngine.Create() : Startup!', AE_LOG_MESSAGE_ENTRY_TYPE_NORMAL);

end;

procedure TAgentEngine.CreatePlayerNodeAndCamera(name: string; start_position: TPoint3D);
var
  PlayerNode: TaeSceneNode;
  Camera: TaeCamera;
begin
  PlayerNode := TaeSceneNode.Create(name);
  PlayerNode.Move(start_position.Negative);
  Camera := TaeCamera.Create(PlayerNode);
  // Camera.SetCameraViewType(AE_CAMERA_VIEW_LOOKFROMCENTER);
  Camera.SetDistance(30.0);
  self.Renderer.setCamera(Camera);
  self.SceneGraph.AddChild(PlayerNode);

end;

procedure TAgentEngine.enableRenderer(renderHandle: THandle; width, height: cardinal);
begin
  self.Renderer := TaeOGLRenderer.Create(renderHandle, width, height);
end;

procedure TAgentEngine.SwapSceneGraph(newGraph: TaeSceneGraph);
begin
  self.SceneGraph.Free;
  self.SceneGraph := newGraph;
  self.Renderer.setSceneGraph(self.SceneGraph);
end;

procedure TAgentEngine.testNodes(nodeCount: cardinal);
var
  nodeArray: array of TaeSceneNode;
  i: integer;
begin
  // first, let's generate some random nodes.
  SetLength(nodeArray, nodeCount);
  for i := 0 to nodeCount - 1 do
  begin
    nodeArray[i] := TaeSceneNode.Create('TestNode_' + inttostr(i));
  end;

  nodeArray[0].AddChild(nodeArray[1]);
  nodeArray[0].AddChild(nodeArray[2]);

  nodeArray[1].AddChild(nodeArray[4]);
  nodeArray[1].AddChild(nodeArray[5]);
  nodeArray[1].AddChild(nodeArray[8]);

  nodeArray[4].AddChild(nodeArray[8]);
  nodeArray[4].AddChild(nodeArray[10]);
  nodeArray[4].AddChild(nodeArray[4]);

  ShowMessage('Number of children : ' + inttostr(nodeArray[0].ListChildren.Count));
end;

end.
