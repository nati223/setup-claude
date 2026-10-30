## Rule: always use qmd before reading files

Before reading files or exploring directories, always use qmd to search for information in local projects — **except** when the current project already has a graphify knowledge graph (`graphify-out/graph.json` exists): use graphify first, per the `## graphify` rule below. Its structured query/path/explain return scoped relationships qmd's text search can't see.

qmd is for non-binary text files only (md, txt, code). PDF and DOCX are not searchable in qmd.

Available tools:

- `qmd search "query"` — fast keyword search (BM25)
- `qmd query "query"` — hybrid search with reranking (best quality)
- `qmd vsearch "query"` — semantic vector search
- `qmd get <file>` — retrieve a specific document

Use qmd search for quick lookups and qmd query for complex questions.

Use Read/Glob only if qmd doesn't return enough results.

## graphify

If the current project has `graphify-out/graph.json`:

- For codebase questions, run `graphify query "<question>"` first — cheaper and more precise than qmd's raw snippets or Read/Glob.
- Use `graphify path "<A>" "<B>"` for relationships, `graphify explain "<concept>"` for a focused concept.
- If `graphify-out/wiki/index.md` exists, use it for broad navigation instead of raw source browsing.
- Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review or when query/path/explain don't surface enough context.
- After modifying code, run `graphify update .` (or `/graphify --update`) to keep the graph current — AST-only, no API cost.

Priority chain: graphify (if graph exists, current-project codebase questions) → qmd (general/cross-project search, or no graph yet) → Read/Glob (last resort).

No graph yet? Build one with `/graphify` (`~/.claude/skills/graphify/SKILL.md`) — any input to knowledge graph: code, docs, papers, images, video.

## Code Review Standards

After completing any implementation, review the code for:
- Functions longer than 50 lines of logic (don't count docstrings\ comments)
- Logic duplicated more than twice (extract to utility)
- Any `any` type usage in TypeScript (replace with real types)
- Components with more than 3 props that could be grouped into an object
- Missing error handling on async operations

Run /simplify before presenting code to the user
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
