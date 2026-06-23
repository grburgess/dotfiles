# arxiv-explainer — LESSONS (read at the start of EVERY run)

Auto-appended at SESSION END. User feedback outranks verifier findings. Newest at top.
Each entry: `## YYYY-MM-DD — <paper-folder>` then bullets (win / gap / fix). The auto-tuner
also edits `references/rubric.md` and `references/patterns.md`; those edits are logged here.

<!-- entries appended below this line -->

## 2026-06-16 — 2606.10775-sst-cd (SST-CD, building change detection)

**USER FEEDBACK (outranks verifier):** "this looks good, though I would like more dynamic
animations and hovers." → Durable default, applied this run and promoted:
- Ship **hover affordances** on figures and diagram parts, not just glossary words: hover-
  highlight diagram stages, hover tooltips on data marks (bars) showing exact value + Δ,
  hover-lift on panels/pills/pins. Use the theme's `ref()` popover liberally on technical
  terms (≥4–6 per deck).
- Give figure-heavy slides **continuous or interactive motion**, not only on-enter reveal:
  a flowing signal pulse through a pipeline, a sweeping scan-line over a grid, staggered
  builds. Always `prefers-reduced-motion`-gated.
- → rubric updated (motion-meaningful + toolkit-breadth sub-checks); patterns grew 5 recipes.

**Wins (verifier PASS, iter 1):**
- The strongest figure was the **interactive sensitivity slider** over a paper's own
  ablation/sensitivity table (here τ_spatial × real Table V F1/IoU). Cheap to build, high
  signal, and it let the reader *find* the paper's point (selection-off is worst) themselves.
- **Annotated paper figure with numbered pins + a matching legend list** read clearly and was
  forgiving of exact pin placement — better than trying to caption regions in prose.
- Redrawing the core mechanism as an **animated SVG crossfade** (noisy → selected) carried the
  insight better than the paper's own static figure.

**Gaps / fixes (orchestrator-caught, pre-verifier):**
- `favicon.ico` 404 counts as a console error under check 1 when served over http → ALWAYS add
  `<link rel="icon" href="data:,">` to the head. (Fold into the P4 template step.)
- I invented an arXiv id for a cited dataset (LEVIR-CD/STANet) that didn't match the mindmap's
  recorded URL → **only use URLs resolved from ground truth** (the mindmap node's `urls`, the
  Confluence search result, or the paper's own reference). Never reconstruct an arXiv id from
  memory.

**Tooling lesson (verify):** chrome-devtools MCP can hold a **stale profile lock** ("browser
already running"); Playwright **blocks `file://`**. Reliable path: `python3 -m http.server`
in the paper folder, then Playwright over `http://localhost:<port>/`. (Proposed as a gated
pipeline.md P5 note.)

**Auto-changes this run:** rubric.md (+2 dated sub-checks), patterns.md (+5 recipes, growth
log), this LESSONS entry. SKILL.md procedure unchanged (gated).
