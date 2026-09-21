# Novel Reader Importer Status

- Stage 1: **COMPLETE**
- Schema: `0.1` (`book.json`)
- Branch: `feature/novel-reader-importer`
- Final commit: the commit referenced by the annotated
  `checkpoint-novel-reader-importer-stage1` tag (resolve with
  `git rev-parse checkpoint-novel-reader-importer-stage1^{commit}`).
- Tests: BookJson 26/26 assertions; offline Narou integration 27/27
  assertions; 0 failures in both.
- Build targets: Linux x86_64 and Windows x86_64 / win64 full `na6dl` builds.
  Windows `na6dl.exe` startup and `--json` / `-j` usage were verified.
- Known warnings: FPC reports existing string-conversion and dependency
  warnings (149 on Linux full build, 150 on Windows full build, and 1 in the
  BookJson unit build at the Stage 1 checkpoint); no build errors.
- Current limitations: no live-site automated E2E under the current
  [Syosetu terms](https://syosetu.com/site/rule/); no Novel Reader UI; ruby
  readings are omitted; preface and afterword are included in chapter `body`
  rather than stored as separate fields. The existing upstream downloader is
  retained, but importer development does not expand automated site access.
- Next stage: Novel Readerが`book.json`を読み込んで表示する。
