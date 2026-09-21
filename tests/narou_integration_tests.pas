program NarouIntegrationTests;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$CODEPAGE UTF8}
  {$H+}
{$ENDIF}

uses
  Classes, SysUtils, BookJson, NarouParser;

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

function LoadUTF8File(const FileName: string): UTF8String;
var
  InputStream: TFileStream;
begin
  InputStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, InputStream.Size);
    if InputStream.Size > 0 then
      InputStream.ReadBuffer(Result[1], InputStream.Size);
  finally
    InputStream.Free;
  end;
end;

function CountMatchingFiles(const Pattern: string): Integer;
var
  SearchRec: TSearchRec;
begin
  Result := 0;
  if FindFirst(Pattern, faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        Inc(Result);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

procedure RunIntegrationTest;
const
  SourceURL = 'https://ncode.syosetu.com/n0000aa/';
var
  Book: TBookJson;
  TopHTML, ChapterHTML, Title, Author, ChapterTitle, ChapterBody: string;
  FirstBody, SecondBody: string;
  JsonText: UTF8String;
  OutputFile: string;
begin
  OutputFile := 'tests/integration-output.book.json';
  if FileExists(OutputFile) then
    DeleteFile(OutputFile);

  TopHTML := string(LoadUTF8File('tests/fixtures/narou-top.html'));
  GetReaderBookInfo(TopHTML, Title, Author);
  AssertEqual('ダミー長編小説', Title, 'book title');
  AssertEqual('テスト作者', Author, 'author');
  AssertEqual('n0000aa', ExtractNarouWorkId(SourceURL), 'work id');

  Book := TBookJson.Create;
  try
    Book.Id := ExtractNarouWorkId(SourceURL);
    Book.Title := Title;
    Book.Author := Author;
    Book.SourceURL := SourceURL;

    ChapterHTML := string(LoadUTF8File('tests/fixtures/narou-chapter-001.html'));
    GetReaderChapter(ChapterHTML, ChapterTitle, ChapterBody);
    FirstBody := ChapterBody;
    AssertEqual('第一話 はじまり', ChapterTitle, 'first chapter title');
    AssertTrue(Pos('これは第一話です。', ChapterBody) > 0,
      'first chapter body');
    AssertTrue(Pos('これは第一話です。' + LineEnding + '二行目です。',
      ChapterBody) > 0, 'first chapter line break');
    AssertTrue(Pos('漢字', ChapterBody) > 0, 'ruby base text');
    AssertTrue(Pos('かんじ', ChapterBody) = 0, 'ruby reading was not removed');
    AssertTrue(Pos('自作の前書きです。', ChapterBody) <
      Pos('これは第一話です。', ChapterBody), 'preface order');
    AssertTrue(Pos('自作の後書きです。', ChapterBody) >
      Pos('これは第一話です。', ChapterBody), 'afterword order');
    Book.AddChapter(ChapterTitle, ChapterBody);

    ChapterHTML := string(LoadUTF8File('tests/fixtures/narou-chapter-002.html'));
    GetReaderChapter(ChapterHTML, ChapterTitle, ChapterBody);
    SecondBody := ChapterBody;
    AssertEqual('第二話 続き', ChapterTitle, 'second chapter title');
    AssertTrue(Pos('引用符 " のテストです。', ChapterBody) > 0,
      'quote in second chapter');
    AssertTrue(Pos('バックスラッシュ \ のテストです。', ChapterBody) > 0,
      'backslash in second chapter');
    Book.AddChapter(ChapterTitle, ChapterBody);

    AssertEqual('2', IntToStr(Book.ChapterCount), 'chapter count');
    AssertTrue(Book.SaveToFile(OutputFile), 'book JSON save');
    JsonText := LoadUTF8File(OutputFile);
    AssertTrue(Pos('"schemaVersion": "0.1"', JsonText) > 0,
      'schema version');
    AssertTrue(Pos('"id": "001"', JsonText) < Pos('"id": "002"', JsonText),
      'chapter order');
    AssertTrue(Pos(UTF8Encode(UnicodeString(FirstBody)), JsonText) = 0,
      'unescaped multiline body unexpectedly present');
    AssertTrue(Pos(UTF8Encode(UnicodeString('引用符 \" のテストです。')), JsonText) > 0,
      'JSON quote escaping');
    AssertTrue(Pos(UTF8Encode(UnicodeString('バックスラッシュ \\ のテストです。')), JsonText) > 0,
      'JSON backslash escaping');
    AssertTrue(Pos(UTF8Encode(UnicodeString('ダミー長編小説')), JsonText) > 0,
      'UTF-8 title');
    AssertTrue(Pos(UTF8Encode(UnicodeString('［＃')), JsonText) = 0,
      'Aozora command leaked into JSON');
    AssertTrue(Pos('"id": "n0000aa"', JsonText) > 0, 'JSON work id');
    AssertTrue(Pos('"url": "' + SourceURL + '"', JsonText) > 0,
      'JSON source URL');
    AssertTrue(CountMatchingFiles(OutputFile + '.*.tmp') = 0,
      'temporary file remained');
    AssertTrue(CountMatchingFiles(OutputFile + '.*.bak') = 0,
      'backup file remained');
    AssertTrue(SecondBody <> '', 'second body was empty');
  finally
    Book.Free;
    if FileExists(OutputFile) then
      DeleteFile(OutputFile);
  end;
end;

begin
  try
    RunIntegrationTest;
    Writeln('narou integration tests: PASS (' + IntToStr(PassedAssertions) +
      ' assertions, 0 failures)');
  except
    on E: Exception do
    begin
      Writeln('narou integration tests: FAIL: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
