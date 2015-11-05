unit aeLoggingManager;

interface

uses windows, types, sysutils, classes, aeConst;

type
  TaeLogMessageEntryType = (AE_LOG_MESSAGE_ENTRY_TYPE_NORMAL, AE_LOG_MESSAGE_ENTRY_TYPE_NOTICE,
    AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);

type
  TaeLoggingManager = class
  private
    _log: TStringList;
    _log_path: string;
    _critsect: TRTLCriticalSection;
    _lastMessageHashCode: integer;

  public
    Constructor Create;

    Procedure AddEntry(entryMsg: String; entryType: TaeLogMessageEntryType);
    destructor Destroy; override;
  end;

var
  AE_LOGGING: TaeLoggingManager; // singleton, blarghhh

implementation

{ TaeLoggingManager }

procedure TaeLoggingManager.AddEntry(entryMsg: String; entryType: TaeLogMessageEntryType);
var
  currentHashCode: integer;
begin
  try
    EnterCriticalSection(self._critsect);
    if (entryMsg = '') then
      exit;

    currentHashCode := entryMsg.GetHashCode();

    if (currentHashCode = self._lastMessageHashCode) then
      exit;

    case entryType of
      AE_LOG_MESSAGE_ENTRY_TYPE_NORMAL:
        self._log.Add('AE_NORMAL : ' + entryMsg);
      AE_LOG_MESSAGE_ENTRY_TYPE_NOTICE:
        self._log.Add('AE_NOTICE : ' + entryMsg);
      AE_LOG_MESSAGE_ENTRY_TYPE_ERROR:
        self._log.Add('***AE_ERROR*** : ' + entryMsg);
    end;

    self._lastMessageHashCode := currentHashCode;

    self._log.SaveToFile(self._log_path);
  finally
    LeaveCriticalSection(self._critsect);
  end;

end;

constructor TaeLoggingManager.Create;
begin
  self._lastMessageHashCode := 0;
  self._log := TStringList.Create;
  self._log_path := GetCurrentDir + '\' + AE_LOGGING_LOG_PATH;
  InitializeCriticalSection(self._critsect);
end;

destructor TaeLoggingManager.Destroy;
begin
  DeleteCriticalSection(self._critsect);
  self._log.Free;
  inherited;
end;

initialization

AE_LOGGING := TaeLoggingManager.Create;

finalization

AE_LOGGING.Free;

end.
