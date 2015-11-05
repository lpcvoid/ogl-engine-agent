(*

  Base class for all loaders. Each loader handles one file type.

*)

unit ae3DModelLoaderBase;

interface

uses windows, types, System.Generics.Collections, aeGeometry, sysutils;

Type
  TaeLoaderFiletype = (AE_LOADER_FILETYPE_3DS, AE_LOADER_FILETYPE_AIONCGF);

type
  Tae3DModelLoaderBase = class
  public
    Constructor Create;
    function loadFromFile(file_name: string; var geo: TaeGeometry): boolean; virtual; abstract;
    function getHandledFileExtension: string;
    function getLoaderType: TaeLoaderFiletype;

  private
    _fileExtension: string;

  protected
    _fileType: TaeLoaderFiletype;
    procedure setHandledFileExtension(extension: string);

  end;

implementation

{ TaeLoaderBase }

constructor Tae3DModelLoaderBase.Create;
begin
  self._fileExtension := '';
end;

function Tae3DModelLoaderBase.getHandledFileExtension: string;
begin
  result := self._fileExtension;
end;

function Tae3DModelLoaderBase.getLoaderType: TaeLoaderFiletype;
begin
  result := self._fileType;
end;

procedure Tae3DModelLoaderBase.setHandledFileExtension(extension: string);
begin
  self._fileExtension := lowercase(extension);
end;

end.
