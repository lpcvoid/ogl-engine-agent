/// <summary>
/// This class contains a basic scene node, to which objects can be attached, and which serves as a node for the scene graph.
/// All
/// </summary>

unit aeSceneNode;

interface

uses windows, types, System.Generics.Collections, aeSceneObject, aeTransform, aeMaths;

type
  TaeSceneNodeType = (AE_SCENENODE_TYPE_NODE, AE_SCENENODE_TYPE_GEOMETRY, AE_SCENENODE_TYPE_LIGHT, AE_SCENENODE_TYPE_PRIMITIVESHAPE, AE_SCENENODE_TYPE_TERRAIN);

type
  TaeSceneNode = class(TaeSceneObject)
    constructor Create(name: string); overload;
    constructor Create; overload;

    destructor Destroy; override;

    procedure AddChild(theChild: TaeSceneNode);
    function RemoveChild(theChild: TaeSceneNode): boolean;

    /// <remarks>
    /// Gets all child nodes.
    /// </remarks>
    function ListChildren: TList<TaeSceneNode>; overload;
    /// <remarks>
    /// Gets all child nodes of a certain type.
    /// </remarks>
    function ListChildren(childType: TaeSceneNodeType): TList<TaeSceneNode>; overload;

    procedure setParent(parent: TaeSceneNode);
    function getParent: TaeSceneNode;

    procedure RemoveFromParentNode;

    /// <remarks>
    /// Get the type of scene node.
    /// </remarks>
    function getType: TaeSceneNodeType;

    /// <remarks>
    /// Get world transformation (the sum of all transformations of all nodes before this and including this in tree)
    /// </remarks>
    function GetWorldTransformationMatrix: TaeMatrix44;
    procedure RecalculateWorldTransform;
    function IsWorldTransformDirty: boolean;
    procedure SetWorldTransformDirty(d: boolean);

    procedure SetNodeName(n: string);
    function GetNodeName: String;

  private
    // this transform matrix contains all changes done to this point in scene graph!
    _worldTransformMatrix: TaeMatrix44;
    _worldMatrixDirty: boolean;

    _parent: TaeSceneNode;
    _childNodes: TList<TaeSceneNode>;

    procedure SetSelfAndChildrenDirty;
  protected
    _NodeType: TaeSceneNodeType;
    _name: String;
  end;

implementation

{ TaeNode }

constructor TaeSceneNode.Create(name: string);
begin
  inherited Create;
  self._NodeType := AE_SCENENODE_TYPE_NODE;
  self._name := name;
  self._childNodes := TList<TaeSceneNode>.Create;
  self._worldTransformMatrix.loadIdentity;
  self.SetLocalTransformDirty(false);
  self.SetDirtyCallback(self.SetSelfAndChildrenDirty);

end;

constructor TaeSceneNode.Create;
begin
  inherited Create;
  self._NodeType := AE_SCENENODE_TYPE_NODE;
  self._worldTransformMatrix.loadIdentity;
  self._childNodes := TList<TaeSceneNode>.Create;
  self._worldTransformMatrix.loadIdentity;
  self.SetLocalTransformDirty(false);
  self.SetDirtyCallback(self.SetSelfAndChildrenDirty);
end;

// multiply current local transform with parent's world transform.
procedure TaeSceneNode.RecalculateWorldTransform;
var
  parentWorldMatrix, newMatrix: TaeMatrix44;

begin

  // recalc our world matrix, using parent's world matrix and our local one.
  if (self.getParent <> nil) then
  begin

    // Recursively recalculate transforms until root node
    if (self.getParent.IsWorldTransformDirty()) or (self.getParent.IsLocalTransformDirty()) then
      self.getParent.RecalculateWorldTransform;

    parentWorldMatrix := self.getParent.GetWorldTransformationMatrix;
    self._worldTransformMatrix.loadIdentity;
    self._worldTransformMatrix := (parentWorldMatrix * self.GetLocalTransformMatrix());
    self.SetWorldTransformDirty(false);
  end
  else
    // world matrix of root node is same as the local transform of world!
    self._worldTransformMatrix := self.GetLocalTransformMatrix();
end;

function TaeSceneNode.RemoveChild(theChild: TaeSceneNode): boolean;
var
  i: Integer;
begin
  result := false;
  if (self._childNodes.Remove(theChild) > -1) then
  begin
    self._childNodes.Pack;
    result := true;
  end;
end;

procedure TaeSceneNode.RemoveFromParentNode;
begin
  if (self._parent <> nil) then
  begin
    self._parent.RemoveChild(self);
    self._parent := nil;
  end;
end;

function TaeSceneNode.GetWorldTransformationMatrix: TaeMatrix44;
var
  localTransform: TaeMatrix44;
begin
  if (self.IsWorldTransformDirty()) or (self.IsLocalTransformDirty()) then
  begin
    self.RecalculateWorldTransform;
  end;
  result := self._worldTransformMatrix;
end;

function TaeSceneNode.IsWorldTransformDirty: boolean;
begin
  result := self._worldMatrixDirty;
end;

procedure TaeSceneNode.SetNodeName(n: string);
begin
  self._name := n;
end;

destructor TaeSceneNode.Destroy;
begin
  // TODO : Free all children? Or do we need to have them do that on their own?
  self._childNodes.Free;
  self._parent := nil;
  inherited;
end;

function TaeSceneNode.GetNodeName: String;
begin
  result := self._name;
end;

function TaeSceneNode.getParent: TaeSceneNode;
begin
  result := self._parent;
end;

function TaeSceneNode.getType: TaeSceneNodeType;
begin
  result := self._NodeType;
end;

function TaeSceneNode.ListChildren(childType: TaeSceneNodeType): TList<TaeSceneNode>;
var
  i: Integer;
begin
  result := self.ListChildren;
  for i := 0 to result.Count - 1 do
    if (result[i].getType <> childType) then
      result.Delete(i);
end;

procedure TaeSceneNode.AddChild(theChild: TaeSceneNode);
begin
  if (theChild <> self) then
  begin
    theChild.setParent(self);
    self._childNodes.Add(theChild);
  end;

end;

function TaeSceneNode.ListChildren: TList<TaeSceneNode>;
var
  i: Integer;
  tempRecursiveList: TList<TaeSceneNode>;
  e: Integer;
begin
  // recursively list all children!
  result := TList<TaeSceneNode>.Create;

  if (self._childNodes.Count > 0) then
  begin
    // we have child nodes!
    for i := 0 to self._childNodes.Count - 1 do
    begin
      // for every child node, we first add it...
      result.Add(self._childNodes[i]);
      // ... and then, we add that node's children recursively!
      tempRecursiveList := self._childNodes[i].ListChildren;
      for e := 0 to tempRecursiveList.Count - 1 do
        result.Add(tempRecursiveList[e]);
      // now, we free the list.
      tempRecursiveList.Free;

    end;
  end;

end;

procedure TaeSceneNode.setParent(parent: TaeSceneNode);
begin
  self._parent := parent;
end;

procedure TaeSceneNode.SetWorldTransformDirty(d: boolean);
begin
  self._worldMatrixDirty := d;
end;

procedure TaeSceneNode.SetSelfAndChildrenDirty;
var
  l: TList<TaeSceneNode>;
  i: Integer;
begin
  self.SetWorldTransformDirty(true);
  self._localTransformDirty := true;
  l := self.ListChildren;
  for i := 0 to l.Count - 1 do
  begin
    l[i].SetWorldTransformDirty(true);
    l[i].SetLocalTransformDirty(true);
  end;

  l.Free;

end;

end.
