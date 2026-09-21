# Novel Reader Importer

## Stage 1 goal

Convert one supported Narou novel URL into a reader-neutral `book.json` file.

```text
Narou URL
   ↓
narou-downloader / importer
   ↓
book.json
   ↓
Novel Reader
```

## Design rules

- Keep the downloader/importer separate from the Novel Reader UI.
- Do not commit downloaded novel text or other copyrighted work content to this repository.
- Keep `main` stable; development happens on feature branches.
- Stage 1 is limited to title, author, source URL, chapter title, and chapter body.
- AI commentary, translation, cover images, bookmarks, and reading progress are out of scope for Stage 1.

## Files

- `schemas/book.schema.json`: initial data contract for imported books.
- `examples/book.example.json`: dummy example containing no real novel content.
- `bookjson.pas`: schema v0.1 model, N-code validation, JSON escaping, and safe file output.

## CLI

```powershell
na6dl --json https://ncode.syosetu.com/nxxxxxx/ book.json
```

`-j` can be used instead of `--json`. When the output name is omitted,
`book.json` is written next to the current process working directory. The
normal command without `--json` continues to create the existing Aozora-style
TXT and log files.

JSON output contains plain reading text. Aozora commands such as
`［＃改ページ］`, headings, and boxed-text markers are only added to the legacy
TXT path. Ruby readings are omitted from Stage 1 JSON while their base text is
retained.

The JSON file is written only after all requested chapters have been collected.
An invalid or chapter-level URL is rejected before downloading and does not
leave a partial JSON file. The legacy `-s` partial-download option is rejected
in JSON mode because a `book.json` must represent the complete work.

## Offline test

`tests/bookjson_tests.pas` covers N-code extraction, escaping, multiline text,
chapter order, and refusal to save incomplete data. It has no network or real
novel fixture dependency.

```powershell
fpc -Fu. .\tests\bookjson_tests.pas
.\tests\bookjson_tests.exe
```

## Stage 1 boundary

This stage only adds one-work JSON export. Novel Reader UI, additional sites,
cover images, AI features, bookmarks, and reading progress remain out of scope.
