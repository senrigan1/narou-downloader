program BookJsonTests;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$CODEPAGE UTF8}
  {$H+}
{$ENDIF}

uses
  Classes, SysUtils, BookJson;

var
  PassedAssertions: Integer = 0;

procedure AssertTrue(const Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    raise Exception.Create(MessageText);
  Inc(PassedAssertions);
end;

procedure AssertEqual(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    raise Exception.Create(MessageText + ': expected "' + Expected +
      '", actual "' + Actual + '"');
  Inc(PassedAssertions);
end;

procedure TestWorkId;
begin
  AssertEqual('n1234ab', ExtractNarouWorkId('https://ncode.syosetu.com/n1234ab/'),
    'normal work id');
  AssertEqual('n5678cd', ExtractNarouWorkId('https://novel18.syosetu.com/N5678CD'),
    'R18 work id');
  AssertEqual('', ExtractNarouWorkId('https://example.com/n1234ab/'),
    'unsupported site');
  AssertEqual('', ExtractNarouWorkId('https://ncode.syosetu.com/n1234ab/1/'),
    'chapter URL must be rejected');
  AssertEqual('', ExtractNarouWorkId('https://ncode.syosetu.com/../book.json'),
    'path traversal must be rejected');
end;

procedure TestJsonEscape;
var
  Input, Expected: string;
begin
  Input := '引用"・パス\・タブ' + #9 + '改行' + #13#10 + '終端';
  Expected := '引用\"・パス\\・タブ\t改行\r\n終端';
  AssertEqual(Expected, JsonEscape(Input), 'JSON string escaping');
end;

procedure TestBookOutput;
var
  Book, IncompleteBook: TBookJson;
  Lines: TStringList;
  JsonText, OutputFile: string;
begin
  OutputFile := ExtractFilePath(ParamStr(0)) + 'test-output.book.json';
  if FileExists(OutputFile) then
    DeleteFile(OutputFile);

  IncompleteBook := TBookJson.Create;
  try
    AssertTrue(not IncompleteBook.SaveToFile(OutputFile),
      'incomplete book must not be saved');
    AssertTrue(not FileExists(OutputFile),
      'incomplete book left an output file');
  finally
    IncompleteBook.Free;
  end;

  Book := TBookJson.Create;
  try
    Book.Id := 'n0000aa';
    Book.Title := 'ダミー"作品';
    Book.Author := 'テスト作者';
    Book.SourceURL := 'https://ncode.syosetu.com/n0000aa/';
    Book.AddChapter('第一話', '一行目' + #13#10 + '二行目');
    Book.AddChapter('第二話', '引用"と\と' + #9 + 'タブ');
    AssertTrue(Book.SaveToFile(OutputFile), 'complete book was not saved');

    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(OutputFile, TEncoding.UTF8);
      JsonText := Lines.Text;
    finally
      Lines.Free;
    end;
    AssertTrue(Pos('"schemaVersion": "0.1"', JsonText) > 0,
      'schema version missing');
    AssertTrue(Pos('"id": "001"', JsonText) < Pos('"id": "002"', JsonText),
      'chapter order is incorrect');
    AssertTrue(Pos('一行目\r\n二行目', JsonText) > 0,
      'multiline body was not escaped; generated JSON: ' + JsonText);
    AssertTrue(Pos('引用\"と\\と\tタブ', JsonText) > 0,
      'quote, backslash, or tab was not escaped');
    AssertTrue(Pos('［＃', JsonText) = 0,
      'Aozora command leaked into JSON');
  finally
    Book.Free;
    if FileExists(OutputFile) then
      DeleteFile(OutputFile);
  end;
end;

begin
  try
    TestWorkId;
    TestJsonEscape;
    TestBookOutput;
    Writeln('bookjson tests: PASS (' + IntToStr(PassedAssertions) +
      ' assertions, 0 failures)');
  except
    on E: Exception do
    begin
      Writeln('bookjson tests: FAIL: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
