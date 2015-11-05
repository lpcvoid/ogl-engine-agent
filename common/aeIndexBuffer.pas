unit aeIndexBuffer;

interface

uses windows, classes, types, dglOpenGL, aeLoggingManager;

type
  TaeIndexBuffer = class
  private
      // opengl buffer ID for this data
    _gpuBufferID: Cardinal;
    _data: Array of Word;
    _index: Cardinal;
    _critsect: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    /// Preallocate memory!.
    /// </summary>
    procedure PreallocateIndices(nIndices: Cardinal);
    /// <summary>
    /// Add a index range to the array. index_count is the number of indices (2 byte chunks).
    /// </summary>
    procedure AddIndexRange(i0: pWord; index_count: integer);
    /// <summary>
    /// Add a single vertex to the array.
    /// </summary>
    procedure AddIndex(i0: Word);
    /// <summary>
    /// Clear the index array.
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
    /// Returns number of indices in this buffer.
    /// </summary>
    function Count: Cardinal;
    /// <summary>
    /// Gets the OpenGL Buffer ID.
    /// </summary>
    function GetOpenGLBufferID: Cardinal;
    /// <summary>
    /// Uploads data to GPU as index data.
    /// </summary>
    function UploadToGPU: boolean;
    /// <summary>
    /// Deletes data on GPU.
    /// </summary>
    function RemoveFromGPU: boolean;
    /// <summary>
    /// Returns pointer to start of index array.
    /// </summary>
    function GetIndexData: Pointer;
    /// <summary>
    /// Returns certain index of index array.
    /// </summary>
    function GetIndex(indx: Cardinal): Word;
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

{ TaeIndexBuffer }

procedure TaeIndexBuffer.AddIndex(i0: Word);
begin
  self._data[_index] := i0;
  inc(_index);
end;

procedure TaeIndexBuffer.AddIndexRange(i0: pWord; index_count: integer);
begin
  CopyMemory(@self._data[self._index], i0, index_count * 2);
  inc(self._index, index_count);
end;

procedure TaeIndexBuffer.Clear;
begin
  self._index := 0;
  SetLength(self._data, 0);
  Finalize(self._data);
  self._data := nil;
end;

function TaeIndexBuffer.Count: Cardinal;
begin
  Result := self._index;
end;

constructor TaeIndexBuffer.Create;
begin
  InitializeCriticalSection(self._critsect);
  self.Clear;
  self._gpuBufferID := 0;
end;

destructor TaeIndexBuffer.Destroy;
begin
  self.Clear;
  self.RemoveFromGPU;
  DeleteCriticalSection(self._critsect);
  inherited;
end;

function TaeIndexBuffer.Empty: boolean;
begin
  Result := self._index = 0;
end;

function TaeIndexBuffer.GetIndex(indx: Cardinal): Word;
begin
  Result := self._data[indx];
end;

function TaeIndexBuffer.GetIndexData: Pointer;
begin
  Result := @self._data[0];
end;

function TaeIndexBuffer.GetOpenGLBufferID: Cardinal;
begin
  Result := self._gpuBufferID;
end;

procedure TaeIndexBuffer.Lock;
begin
  EnterCriticalSection(self._critsect);
end;

procedure TaeIndexBuffer.Pack;
begin
  SetLength(self._data, self._index);
end;

procedure TaeIndexBuffer.PreallocateIndices(nIndices: Cardinal);
begin
  SetLength(self._data, nIndices);
end;

function TaeIndexBuffer.RemoveFromGPU: boolean;
begin
  if (self._gpuBufferID > 0) then
  begin
    glDeleteBuffers(1, @self._gpuBufferID);
    self._gpuBufferID := 0;
    Result := true;
  end
  else
  begin
    AE_LOGGING.AddEntry('TaeIndexBuffer.RemoveFromGPU() : Attempt to delete a non-existing buffer! Ignored.', AE_LOG_MESSAGE_ENTRY_TYPE_NOTICE);
    Result := false;
  end;
end;

procedure TaeIndexBuffer.Unlock;
begin
  LeaveCriticalSection(self._critsect);
end;

function TaeIndexBuffer.UploadToGPU: boolean;
begin
   // if buffer object is still 0, we need to create one first!
  if (self._gpuBufferID = 0) then
  begin
    // create a buffer object
    glGenBuffers(1, @self._gpuBufferID);
    // mark buffer as active
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self._gpuBufferID);
    // upload data
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self._index * 2, @self._data[0], GL_STATIC_DRAW);

    Result := true;
  end
  else
  begin
    AE_LOGGING.AddEntry('TaeIndexBuffer.UploadToGPU() : Attempt to overwrite existing buffer with a new one!', AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);
    Result := false;
  end;
end;

end.
