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

## Stage 1 checkpoint

Stage 1 is complete with Schema v0.1. The CLI accepts `--json` and `-j` and
produces UTF-8 `book.json` containing the work ID, title, author, source URL,
and ordered `chapters` with sequential chapter IDs, titles, and plain-text
bodies. Ruby readings are omitted and only the base text is retained. The
preface, main text, and afterword are currently combined into each chapter's
`body` in that order; Schema v0.1 has no separate fields for them.

`TBookJson.SaveToFile()` completes a unique temporary file in the output
directory before switching files. On replacement it protects the previous
file with a unique backup and attempts to restore it if switching fails. This
is a recoverable replacement, not a claim of OS-level atomic replacement.

Verified on the Stage 1 code checkpoint:

- BookJson unit tests: 26 assertions, 0 failures.
- Fully self-authored HTML fixture integration test: 27 assertions, 0 failures.
- Linux full `na6dl` build and offline CLI usage check.
- Windows x86_64 / win64 full build, `na6dl.exe` startup, and usage display
  showing `--json` and `-j`.

The CI source dependencies are fetched by exact commit SHA:

- SimpleHTMLParser: `7f606592557f429a4d9e176be5c0f04fd5be0460`
- TRegExpr: `19389caeb6823cddfb110ed284f57d1088dd8ac2`

### Site access boundary

The current [Syosetu terms, Article 14(23)](https://syosetu.com/site/rule/)
prohibit automated access to or data collection from the service by methods
other than the Narou Developer API. Accordingly, this project does not run
automated end-to-end tests against `ncode.syosetu.com` or
`novel18.syosetu.com`, and it does not use real novel text as a fixture. The
CLI example above documents the implemented syntax, **not authorization to
run it against the live site**.

The existing upstream downloader is retained. The parser and self-authored
fixtures remain for offline parsing, tests, and future input sources with
explicit permission. Novel Reader importer development must not proactively
add or expand automated live-site retrieval.
