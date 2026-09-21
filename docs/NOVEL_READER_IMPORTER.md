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

## Next implementation step

Add an output mode that converts a supported Narou work into JSON conforming to `schemas/book.schema.json`.
