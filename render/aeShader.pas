unit aeShader;

interface

uses windows, types, classes, aeConst, dglOpenGL, sysutils, aeLoggingManager;

type
  TaeShader = class
  private
    _text: TStringList;
    _handle: GLHandle;

  public
    constructor Create;
    destructor destroy; override;

    function SetShader(text: TStrings): boolean;
    function LoadFromFile(filename: string): boolean;
    function Compile: boolean;

  end;

implementation

{ TaeShader }

function TaeShader.Compile: boolean;
begin

end;

constructor TaeShader.Create;
begin
  self._text := TStringList.Create;
  self._handle := glCreateProgram;
end;

destructor TaeShader.destroy;
begin
  glDeleteProgram(self._handle);
  self._text.Free;
  inherited;
end;

function TaeShader.LoadFromFile(filename: string): boolean;
begin
  if (FileExists(filename)) then
  begin
    self._text.LoadFromFile(filename);
    Result := true;
  end
  else
    AE_LOGGING.AddEntry('TaeShader.LoadFromFile() : File not found. file=' + filename, AE_LOG_MESSAGE_ENTRY_TYPE_ERROR);

end;

function TaeShader.SetShader(text: TStrings): boolean;
begin
  self._text.text := text.text;
end;

end.
