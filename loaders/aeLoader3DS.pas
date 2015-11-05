unit aeLoader3DS;

interface

uses ae3DModelLoaderBase, aeGeometry, System.Generics.Collections, types, aeMesh, classes, sysutils;

type
  TaeLoader3DS = class(Tae3DModelLoaderBase)
    constructor Create;
    function loadFromFile(file_name: string; var geo: TaeGeometry): boolean; override;
  end;

implementation

{ TaeLoader3DS }

constructor TaeLoader3DS.Create;
begin
  self.setHandledFileExtension('3ds'); // we want to handle 3ds with this loader!
  self._fileType := AE_LOADER_FILETYPE_3DS;
end;

function TaeLoader3DS.loadFromFile(file_name: string;  var geo: TaeGeometry): boolean;
var
  fs: TFileStream;
  chunktype: word;
  chunklength: integer;
begin
  // load 3ds
  if (FileExists(file_name) = false) then
  begin
    result := false;
    exit;
  end;

  fs := TFileStream.Create(file_name, fmOpenRead);
  fs.Position := 0;

  while (fs.Position < fs.Size) do
  begin
    // read the file..
    fs.ReadData(chunktype, 2);
    fs.ReadData(chunklength, 4);

    case chunktype of
      $4D4D:
        begin
          // main chunk...
          // useless really
        end;
      $0002:
        begin
          // version chunk, useless also...
          fs.Position := fs.Position + (chunklength - 6);
        end;

      $3D3D:
        begin
          // 3D Editor Chunk

        end;

    end;

  end;

  fs.free;

end;

end.
