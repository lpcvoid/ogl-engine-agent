unit aeVectorBuffer;

interface

uses windows, classes, types, dglOpenGL, aeLoggingManager;

type
  TaeVectorBuffer = class
  private
      // opengl buffer ID for this data
    _gpuBufferID: Cardinal;
    _data: Array of TVectorArray;
    _index: Cardinal;
    _critsect: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    /// Preallocate memory!.
    /// </summary>
    procedure PreallocateVectors(nVectors: Cardinal);
    /// <summary>
    /// Add a vector range to the array. vector_count is the number of vectors (12 byte chunks).
    /// </summary>
    procedure AddVectorRange(v0: PSingle; vector_count: integer);
    /// <summary>
    /// Add a single vertex to the array.
    /// </summary>
    procedure AddVector(v0: TVectorArray);
    /// <summary>
    /// Adds three vertices to the array.
    /// </summary>
    procedure Add3Vectors(v0, v1, v2: TVectorArray);
    /// <summary>
    /// Clear the vector array.
    /// </summary>
    procedure Clear;
    /// <summary>
    /// Returns true if buffer is empty.
    /// </summary>
    function Empty: boolean;
    /// <summary>
    /// Reduces the capacity to the actual length. Cuts of excess space that is not used.
    /// </summary>
    procedure Pack;
    /// <summary>
    /// Returns number of vectors in this buffer.
    /// </summary>
    function count: Cardinal;
    /// <summary>
    /// Gets the OpenGL Buffer ID.
    /// </summary>
    function GetOpenGLBufferID: Cardinal;
    /// <summary>
    /// Uploads data to GPU as vertex data.
    /// </summary>
    function UploadToGPU: boolean;
    /// <summary>
    /// Deletes data on GPU.
    /// </summary>
    function RemoveFromGPU: boolean;
    /// <summary>
    /// Returns pointer to start of vector array.
    /// </summary>
    function GetVectorData: Pointer;
    /// <summary>
    /// Returns certain vector of vector array.
    /// </summary>
    function GetVector(indx: Cardinal): TVectorArray;
    /// <summary>
    /// Locks this buffer for other threads.
    /// </summary>
    procedure Lock;
    /// <summary>
    /// Unlocks this buffer for other threads.
    /// </summary>
    procedure Unlock;

  end;

implementation

{ TaeVectorBuffer }

procedure TaeVectorBuffer.Add3Vectors(v0, v1, v2: TVectorArray);
begin
  self.AddVector(v0);
  self.AddVector(v1);
  self.AddVector(v2);
end;

procedure TaeVectorBuffer.AddVector(v0: TVectorArray);
begin
  self._data[_index] := v0;
  inc(_index);
end;

procedure TaeVectorBuffer.AddVectorRange(v0: PSingle; vector_count: integer);
begin
  CopyMemory(@self._data[self._index], v0, vector_count * 12);
  inc(self._index, vector_count);
end;

procedure TaeVectorBuffer.Clear;
begin
  self._index := 0;
  SetLength(self._data, 0);
  Finalize(self._data);
  self._data := nil;
end;

function TaeVectorBuffer.count: Cardinal;
begin
  Result := self._index;
end;

constructor TaeVectorBuffer.Create;
begin
  self.Clear;
  InitializeCriticalSection(self._critsect);
  self._gpuBufferID := 0;
end;

destructor TaeVectorBuffer.Destroy;
begin
  self.Clear;
  self.RemoveFromGPU;
  DeleteCriticalSection(self._critsect);
  inherited;
end;

function TaeVectorBuffer.Empty: boolean;
begin
  Result := self._index = 0;
end;

function TaeVectorBuffer.GetOpenGLBufferID: Cardinal;
begin
  Result := self._gpuBufferID;
end;

function TaeVectorBuffer.GetVector(indx: Cardinal): TVectorArray;
begin
  Result := self._data[indx];
end;

function TaeVectorBuffer.GetVectorData: Pointer;
begin
  Result := @self._data[0];
end;

procedure TaeVectorBuffer.Lock;
begin
  EnterCriticalSection(self._critsect);
end;

procedure TaeVectorBuffer.Pack;
begin
  SetLength(self._data, self._index);
end;

procedure TaeVectorBuffer.PreallocateVectors(nVectors: Cardinal);
begin
  SetLength(self._data, nVectors);
end;

function TaeVectorBuffer.RemoveFromGPU: boolean;
begin
  if (self._gpuBufferID > 0) then
  begin
    glDeleteBuffers(1, @self._gpuBufferID);
    self._gpuBufferID := 0;
    Result := true;
  end;

end;

procedure TaeVectorBuffer.Unlock;
begin
  LeaveCriticalSection(self._critsect);
end;

function TaeVectorBuffer.UploadToGPU: boolean;
begin
  // if buffer object is still 0, we need to create one first!
  if (self._gpuBufferID = 0) then
  begin
    // create a buffer object
    glGenBuffers(1, @self._gpuBufferID);
    // mark buffer as active
    glBindBuffer(GL_ARRAY_BUFFER, self._gpuBufferID);
    // upload data
    glBufferData(GL_ARRAY_BUFFER, self._index * 3 * 4, @self._data[0], GL_STATIC_DRAW);

    Result := true;
  end
  else
  begin
    AE_LOGGING.AddEntry('TaeVectorBuffer.UploadToGPU() : Attempt to overwrite existing buffer with a new one!', AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
    Result := false;
  end;

end;

end.
