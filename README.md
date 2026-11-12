# SCOTUSfiles

A better way to read and discuss Supreme Court decisions. SCOTUSfiles pulls opinions straight from
[supremecourt.gov](https://www.supremecourt.gov/opinions/slipopinions.aspx), converts the official PDFs
into clean, readable HTML, and lets readers click any sentence to comment on it in the margin.

Built on Rails 8.1 with Hotwire (Turbo Frames, Turbo Streams, morphing page refreshes, Stimulus),
Tailwind CSS 4, PostgreSQL, Solid Queue / Cache / Cable, Propshaft, import maps, and the built-in
Rails authentication generator. Deploys to Heroku.

## Getting started

Requirements:

- Ruby 4.0.9 (see `.ruby-version`; `mise install` or `rbenv install` will pick it up)
- [Poppler](https://poppler.freedesktop.org/) for `pdftohtml`: `brew install poppler` on macOS,
  `sudo apt install poppler-utils` on Debian/Ubuntu
- PostgreSQL running locally (`brew install postgresql@17 && brew services start postgresql@17`)

```bash
bin/setup
```

That installs gems, creates the database, and seeds it: an admin account (`admin@example.com` /
`password123`) plus every opinion from the current and previous October Terms, downloaded and
converted live. Then it starts the app at http://localhost:3000.

Seeding options:

```bash
SEED_TERMS=2023,2024 bin/rails db:seed   # specific terms
SEED_LIMIT=5 bin/rails db:seed           # only the newest five per term
ADMIN_EMAIL=me@example.com ADMIN_PASSWORD=... bin/rails db:seed
```

Other tasks:

```bash
bin/rails scotus:sync TERM=2025   # fetch a term's listing and import anything new
bin/rails scotus:reimport         # re-convert every decision (after improving the converter)
bin/rails test                    # run the test suite
```

Admins also get a "Sync from supremecourt.gov" button on the decisions list and a "Re-import"
button on each decision. In production, `SyncTermJob` runs hourly (see `config/recurring.yml`) so new
opinions appear on their own.

## How it works

### Importing

`Scotus::SlipOpinionIndex` reads the Court's per-term listing (date, docket, case name, holding,
author, citation, PDF link) and `Decision.sync_term` upserts those rows and queues an
`ImportDecisionJob` for each new or revised decision.

### Converting PDFs to HTML

The converter lives in `app/models/scotus/` and is driven by layout rather than plain text:

1. **`PdfLayout`** runs `pdftohtml -xml`, which keeps every text run's position, size, and italics,
   and regroups runs into lines. Small raised digits become footnote markers.
2. **`DocumentParser`** uses the Court's consistent typesetting to recover structure:
   - the running header on each page ("Opinion of the Court", "KAGAN, J., dissenting") splits the
     document into sections; opening lines such as "JUSTICE KAGAN, dissenting." split sections that
     start mid-page in bound-volume preliminary prints;
   - footnotes are the lines below the em-dash rule (or the small type at the foot of the page);
   - paragraphs start at an indent (or an outdent in the syllabus), block quotes are inset, headings
     ("I", "A") are centered, and the caption runs through the "Decided …" or "[date]" line.
3. **`LineJoiner`** rejoins lines, undoes end-of-line hyphenation (keeping real compounds that
   appear elsewhere in the document), and repairs `fi`/`fl` ligatures that some PDFs drop
   ("frst" back to "first") using `lib/scotus/ligature_repairs.txt`.
4. **`SentenceSplitter`** splits paragraphs into sentences. Slip opinions put two spaces after a
   sentence and one after an abbreviation ("U. S.", "Inc."), which makes boundaries reliable; for
   prints that justify lines with extra spaces it falls back to an abbreviation-aware heuristic.
5. **`Formatter`** wraps every sentence in `<span class="sentence" data-key="2-41">` and records it as
   a `Passage`. Keys are stable across re-imports, so comments stay attached to their sentences.

### Commenting

Clicking a sentence (the `reader` Stimulus controller) highlights it and loads its thread into a
Turbo Frame in the margin (a bottom sheet on phones). Posting a comment broadcasts Turbo Streams to
everyone reading the decision: the comment is appended to the thread, added to the discussion list,
and the sentence's comment-count badge updates.

## Data model

- `Decision`: one case on a decision date (docket, title, holding, citation, PDF URL, import status)
- `Opinion`: a section of a decision (syllabus, majority, per curiam, plurality, concurrence, dissent)
  with its formatted HTML
- `Passage`: one sentence, identified by a stable `key`
- `Comment`: a reader's note on a passage
- `User` / `Session`: Rails 8 authentication with a self-serve sign-up and an `admin` flag

## Deploying

Production runs on Heroku (heroku-24 stack) with Heroku Postgres. The `Procfile` runs migrations in
the release phase, and the `Aptfile` installs Poppler through the apt buildpack, which must come
before the Ruby buildpack:

```bash
heroku buildpacks:clear
heroku buildpacks:add heroku-community/apt
heroku buildpacks:add heroku/ruby
heroku config:set SOLID_QUEUE_IN_PUMA=true SECRET_KEY_BASE=$(bin/rails secret)
git push heroku main
heroku run ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=... bin/rails db:seed
```

Solid Queue, Solid Cache, and Solid Cable keep their tables in the main database, and
`SOLID_QUEUE_IN_PUMA` runs the job workers (including the hourly sync) inside the web dyno. Set
`APP_HOST` if the site moves off www.scotusfiles.com, and `SMTP_ADDRESS`, `SMTP_PORT`,
`SMTP_USERNAME`, `SMTP_PASSWORD`, and `MAILER_FROM` to send password-reset emails.

## Known limitations

- Some preliminary prints map the `fi` ligature to a bare `f` in their text layer. The repair table
  fixes unambiguous cases; a handful of words may still read oddly.
- Tables and images inside opinions (rare, mostly appendices) are flattened to text.
