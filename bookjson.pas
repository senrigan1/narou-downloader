unit BookJson;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$CODEPAGE UTF8}
  {$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, Contnrs;

type
  TBookChapter = class
  public
    Id: string;
    Title: string;
    Body: string;
  end;

  TBookJson = class
  private
    FId: string;
    FTitle: string;
    FAuthor: string;
    FSourceURL: string;
    FChapters: TObjectList;
    function BuildJson: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddChapter(const ATitle, ABody: string);
    function ChapterCount: Integer;
    function IsComplete: Boolean;
    function SaveToFile(const AFileName: string): Boolean;
    property Id: string read FId write FId;
    property Title: string read FTitle write FTitle;
    property Author: string read FAuthor write FAuthor;
    property SourceURL: string read FSourceURL write FSourceURL;
  end;

function ExtractNarouWorkId(const AURL: string): string;
function JsonEscape(const Value: string): string;

implementation

const
  JSON_EOL = #13#10;

function IsAsciiLetterOrDigit(const Ch: Char): Boolean;
begin
  Result := ((Ch >= 'a') and (Ch <= 'z')) or
            ((Ch >= 'A') and (Ch <= 'Z')) or
            ((Ch >= '0') and (Ch <= '9'));
end;

function ExtractNarouWorkId(const AURL: string): string;
const
  NORMAL_PREFIX = 'https://ncode.syosetu.com/';
  R18_PREFIX = 'https://novel18.syosetu.com/';
var
  I, SlashPos: Integer;
  LowerURL, Rest: string;
begin
  Result := '';
  LowerURL := LowerCase(Trim(AURL));
  if Pos(NORMAL_PREFIX, LowerURL) = 1 then
    Rest := Copy(LowerURL, Length(NORMAL_PREFIX) + 1, MaxInt)
  else if Pos(R18_PREFIX, LowerURL) = 1 then
    Rest := Copy(LowerURL, Length(R18_PREFIX) + 1, MaxInt)
  else
    Exit;

  SlashPos := Pos('/', Rest);
  if SlashPos > 0 then
  begin
    if SlashPos <> Length(Rest) then
      Exit;
    Delete(Rest, SlashPos, 1);
  end;

  if (Length(Rest) < 2) or (Rest[1] <> 'n') then
    Exit;
  for I := 1 to Length(Rest) do
    if not IsAsciiLetterOrDigit(Rest[I]) then
      Exit;
  Result := Rest;
end;

function JsonEscape(const Value: string): string;
var
  I: Integer;
  Ch: Char;
begin
  Result := '';
  for I := 1 to Length(Value) do
  begin
    Ch := Value[I];
    case Ch of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      if Ord(Ch) < 32 then
        Result := Result + '\u' + IntToHex(Ord(Ch), 4)
      else
        Result := Result + Ch;
    end;
  end;
end;

constructor TBookJson.Create;
begin
  inherited Create;
  FChapters := TObjectList.Create(True);
end;

destructor TBookJson.Destroy;
begin
  FChapters.Free;
  inherited Destroy;
end;

procedure TBookJson.AddChapter(const ATitle, ABody: string);
var
  Chapter: TBookChapter;
begin
  Chapter := TBookChapter.Create;
  Chapter.Id := FormatFloat('000', FChapters.Count + 1);
  Chapter.Title := ATitle;
  Chapter.Body := ABody;
  FChapters.Add(Chapter);
end;

function TBookJson.ChapterCount: Integer;
begin
  Result := FChapters.Count;
end;

function TBookJson.IsComplete: Boolean;
begin
  Result := (FId <> '') and (FTitle <> '') and (FSourceURL <> '') and
            (FChapters.Count > 0);
end;

function TBookJson.BuildJson: string;
var
  I: Integer;
  Chapter: TBookChapter;
  Comma: string;
begin
  Result := '{' + JSON_EOL +
    '  "schemaVersion": "0.1",' + JSON_EOL +
    '  "id": "' + JsonEscape(FId) + '",' + JSON_EOL +
    '  "title": "' + JsonEscape(FTitle) + '",' + JSON_EOL +
    '  "author": "' + JsonEscape(FAuthor) + '",' + JSON_EOL +
    '  "source": {' + JSON_EOL +
    '    "site": "syosetu.com",' + JSON_EOL +
    '    "url": "' + JsonEscape(FSourceURL) + '"' + JSON_EOL +
    '  },' + JSON_EOL +
    '  "chapters": [' + JSON_EOL;

  for I := 0 to FChapters.Count - 1 do
  begin
    Chapter := TBookChapter(FChapters[I]);
    if I < FChapters.Count - 1 then
      Comma := ','
    else
      Comma := '';
    Result := Result +
      '    {' + JSON_EOL +
      '      "id": "' + JsonEscape(Chapter.Id) + '",' + JSON_EOL +
      '      "title": "' + JsonEscape(Chapter.Title) + '",' + JSON_EOL +
      '      "body": "' + JsonEscape(Chapter.Body) + '"' + JSON_EOL +
      '    }' + Comma + JSON_EOL;
  end;
  Result := Result + '  ]' + JSON_EOL + '}' + JSON_EOL;
end;

function TBookJson.SaveToFile(const AFileName: string): Boolean;
var
  Bytes: TBytes;
  OutputStream: TFileStream;
  TempFileName: string;
begin
  Result := False;
  if not IsComplete then
    Exit;

  TempFileName := AFileName + '.tmp';
  if FileExists(TempFileName) and not DeleteFile(TempFileName) then
    Exit;

  try
    Bytes := TEncoding.UTF8.GetBytes(BuildJson);
    OutputStream := TFileStream.Create(TempFileName, fmCreate);
    try
      if Length(Bytes) > 0 then
        OutputStream.WriteBuffer(Bytes[0], Length(Bytes));
    finally
      OutputStream.Free;
    end;

    if FileExists(AFileName) and not DeleteFile(AFileName) then
      Exit;
    Result := RenameFile(TempFileName, AFileName);
  finally
    if FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
end;

end.
