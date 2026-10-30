## Search order

In a project with `graphify-out/graph.json`, use graphify (`graphify query` / `path` / `explain`) for codebase questions. In a project with a qmd collection (`qmd collection list`), use qmd (see the qmd skill) before reading files. Use Read/Grep last.

## Code Review Standards

After completing any implementation, review the code for:
- Functions longer than 50 lines of logic (don't count docstrings\ comments)
- Logic duplicated more than twice (extract to utility)
- Any `any` type usage in TypeScript (replace with real types)
- Components with more than 3 props that could be grouped into an object
- Missing error handling on async operations

Run /simplify before presenting code to the user
