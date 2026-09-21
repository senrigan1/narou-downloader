unit NarouParser;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$CODEPAGE UTF8}
  {$H+}
{$ENDIF}

interface

procedure GetReaderBookInfo(const HTMLSrc: string; out BookTitle, Author: string);
procedure GetReaderChapter(const HTMLSrc: string; out ChapterTitle, ChapterBody: string);
function Restore2RealChar(Base: string): string;
function AfterDecord(Base: string): string;

implementation

uses
  SysUtils, RegExpr, SHParser,
{$IFDEF FPC}
  LazUTF8;
{$ELSE}
  LazUTF8wrap;
{$ENDIF}

const
{$IFDEF LINUX}
  READER_EOL = #10;
{$ELSE}
  READER_EOL = #13#10;
{$ENDIF}

function Restore2RealChar(Base: string): string;
var
  Tmp, Code, RawCode: string;
  Value: Integer;
  Ch: Char;
  WideCh: WideChar;
  Regex: TRegExpr;
begin
  Tmp := UTF8StringReplace(Base, '&quot;', '"', [rfReplaceAll]);
  Tmp := UTF8StringReplace(Tmp, '&nbsp;', ' ', [rfReplaceAll]);
  Tmp := UTF8StringReplace(Tmp, '&yen;', '\', [rfReplaceAll]);
  Tmp := UTF8StringReplace(Tmp, '&brvbar;', '|', [rfReplaceAll]);
  Tmp := UTF8StringReplace(Tmp, '&copy;', '©', [rfReplaceAll]);
  Tmp := UTF8StringReplace(Tmp, '&amp;', '&', [rfReplaceAll]);
  Tmp := UTF8StringReplace(Tmp, '》 ', '》', [rfReplaceAll]);
  Regex := TRegExpr.Create;
  try
    Regex.Expression := '&#\w{2,6};';
    Regex.InputString := Tmp;
    if Regex.Exec then
    begin
      repeat
        UTF8Delete(Tmp, Regex.MatchPos[0], Regex.MatchLen[0]);
        Code := Regex.Match[0];
        UTF8Delete(Code, 1, 2);
        UTF8Delete(Code, UTF8Length(Code), 1);
        if Code[1] = 'x' then
          Code[1] := '$';
        try
          Value := StrToInt(Code);
          Ch := Char(Value);
        except
          Ch := '？';
        end;
        UTF8Insert(Ch, Tmp, Regex.MatchPos[0]);
      until not Regex.ExecNext;
    end;

    Regex.Expression := '\\u[0-9A-Fa-f]{4}';
    Regex.InputString := Tmp;
    if Regex.Exec then
    begin
      repeat
        Code := Regex.Match[0];
        RawCode := '\' + Code;
        UTF8Delete(Code, 1, 2);
        UTF8Insert('$', Code, 1);
        try
          Value := StrToInt(Code);
          WideCh := Char(Value);
        except
          WideCh := '？';
        end;
        Tmp := ReplaceRegExpr(RawCode, Tmp, WideCh);
      until not Regex.ExecNext;
    end;
  finally
    Regex.Free;
  end;
  Result := Tmp;
end;

function AfterDecord(Base: string): string;
begin
  Result := UTF8StringReplace(Base, '&lt;', '<', [rfReplaceAll]);
  Result := UTF8StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
end;

function PlainTextDecord(Src: string): string;
begin
  Result := UTF8StringReplace(Src, '<br />', READER_EOL, [rfReplaceAll]);
  Result := UTF8StringReplace(Result, '<br/>', READER_EOL, [rfReplaceAll]);
  Result := UTF8StringReplace(Result, '<br>', READER_EOL, [rfReplaceAll]);
  Result := UTF8StringReplace(Result, '</p>', READER_EOL, [rfReplaceAll]);
  Result := ReplaceRegExpr('<rp>.*?</rp>', Result, '');
  Result := ReplaceRegExpr('<rt>.*?</rt>', Result, '');
  Result := Restore2RealChar(Result);
end;

function TrimTrailingLineBreaks(const Value: string): string;
begin
  Result := Value;
  while (Length(Result) > 0) and
        ((Result[Length(Result)] = #13) or (Result[Length(Result)] = #10)) do
    Delete(Result, Length(Result), 1);
end;

procedure AppendReaderPart(var Dest: string; const Value: string);
var
  Part: string;
begin
  Part := TrimTrailingLineBreaks(Value);
  if Part = '' then
    Exit;
  if Dest <> '' then
    Dest := Dest + READER_EOL + READER_EOL;
  Dest := Dest + Part;
end;

procedure GetReaderBookInfo(const HTMLSrc: string; out BookTitle, Author: string);
var
  Parser: TSHParser;
begin
  BookTitle := '';
  Author := '';
  Parser := TSHParser.Create(HTMLSrc);
  try
    BookTitle := Parser.Find('h1', 'class', 'p-novel__title', False);
    BookTitle := ReplaceRegExpr('<.*?>', BookTitle, '');
    BookTitle := AfterDecord(Restore2RealChar(BookTitle));
    Author := Parser.Find('div', 'class', 'p-novel__author', False);
    Author := ReplaceRegExpr('<.*?>', ReplaceRegExpr('作者：', Author, ''), '');
    Author := AfterDecord(Restore2RealChar(Author));
  finally
    Parser.Free;
  end;
end;

procedure GetReaderChapter(const HTMLSrc: string; out ChapterTitle, ChapterBody: string);
var
  Parser: TSHParser;
  Part: string;
begin
  ChapterTitle := '';
  ChapterBody := '';
  Parser := TSHParser.Create(HTMLSrc);
  try
    Parser.OnBeforeGetText := @PlainTextDecord;
    Parser.OnAfterGetText := @AfterDecord;
    ChapterTitle := Parser.Find('h1', 'class',
      'p-novel__title p-novel__title--rensai');
    Part := Parser.Find('div', 'class',
      'js-novel-text p-novel__text p-novel__text--preface');
    AppendReaderPart(ChapterBody, Part);
    Part := Parser.Find('div', 'class', 'js-novel-text p-novel__text');
    AppendReaderPart(ChapterBody, Part);
    Part := Parser.Find('div', 'class',
      'js-novel-text p-novel__text p-novel__text--afterword');
    AppendReaderPart(ChapterBody, Part);
  finally
    Parser.Free;
  end;
end;

end.
