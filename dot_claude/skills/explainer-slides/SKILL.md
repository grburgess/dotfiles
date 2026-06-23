---
name: explainer-slides
description: Build slide decks and HTML explanatory pages in the user's established house style — a dark cartographic / technical-editorial theme (Bricolage Grotesque + Hanken Grotesk + Spline Sans Mono; sea-green + purple on green-black; scroll-snap full-height slides, reveal-on-scroll, inline animated SVG figures). Use WHENEVER the user asks for slides, a slide deck, an HTML explainer, an explanatory or visual page, a visual walkthrough, "make a deck", or to turn a doc / spec / notebook / README into slides or an HTML page. Bundles a verbatim theme template plus the build-and-verify workflow.
---

# Explainer Slides / HTML Pages — house style

Build slide decks and HTML explanatory pages in the user's established house style. Use the bundled theme **verbatim** — do not invent a new palette or fonts.

## When to use

Auto-activate when the user asks for: "slides", "a slide deck", "an HTML explainer", "an explanatory / visual page", "a visual walkthrough", "make a deck", or "turn this doc / spec / notebook into slides / an HTML page".

Do **not** use for: plain Markdown docs (unless they ask for HTML or a visual treatment), or when the user explicitly wants a *different* or novel look — follow them instead.

## House style (deliberate — overrides "always vary the aesthetic")

This is a single, consistent house style, on purpose. It **overrides** any guidance to vary fonts/colors per project or "avoid repeating aesthetics" (e.g. the `frontend-design` skill): for these explainers, reuse the SAME theme every time so the user's decks are instantly recognizable. Only deviate when the user asks.

The look — dark cartographic / technical-editorial:
- **Fonts:** Bricolage Grotesque (display/headings), Hanken Grotesk (body), Spline Sans Mono (labels/code/figure text).
- **Palette:** sea-green `--green #7fc9ad` + purple `--purple #b9a0e0`, amber `--warn #e8b06a` for the one thing that matters, on a deep green-black `--bg #0e1513` with an atmospheric green→purple radial mesh and a faint map grid.
- **Motion:** scroll-snap full-height slides, reveal-on-scroll (fade+rise, staggered), inline SVG figures with draw-on / crossfade animation. Always degrades under `prefers-reduced-motion`.

## How to build

1. **Start from the template.** Copy `references/template.html` to the target (e.g. `docs/<topic>-explainer.html`). Its `<style>` + `<script>` blocks ARE the shared theme — keep them verbatim. Swap the `<title>`; replace the example slides with your content.

2. **Slide structure** — one screen each:
   ```html
   <section class="slide"><div class="slide-inner stack">
     <div class="slide-tag"><span class="num">NN</span> <span class="mono">section label</span></div>
     <h2 class="h2 reveal">Slide title</h2>
     ...content...
   </div></section>
   ```
   Number slides `00`, `01`, … Add class `reveal` (optionally `style="--d:160ms"` to stagger) to anything that should animate in on scroll. `<span class="num violet">` tints the tag purple.

3. **Component vocabulary** (all pre-themed — compose, don't restyle):
   - text: `.lead`, `.muted`, `.mono`, `.eyebrow`, `.grad-text`, `.accent-green` / `.accent-purple`
   - layout: `.stack`, `.grid-2`, `.grid-3`
   - blocks: `.panel` (/ `.panel--violet`); `.callout--issue` (amber, "the problem") and `.callout--fix` (green, "the fix") with a `.callout-label`
   - inline: `.pill` / `.chip` (`--violet` / `--warn`), `<code>`, `.kbd`, `.legend` + `.swatch`
   - glossary: `ref("term", {title, desc, links:[{label,url}]})` — mount it into a placeholder span (see the template's `ref-demo`)
   - diagrams: `.flow-svg` (see step 4 and `references/patterns.md`)

4. **Figures = inline SVG, never raster.** Prefer inline `<svg>` over a base64 PNG: it's scalable, tiny, diffable, and it tracks the theme via `var(--green)`/`var(--purple)`/`var(--warn)`. For data-driven figures, write a small generator script that builds the SVG from **real data** and injects it (recipe in `references/patterns.md`). Animate with CSS `@keyframes`; always add a `prefers-reduced-motion` fallback that pins to the final/legible state. Reserve `var(--warn)` (gold) for the single highlighted case; for categorical fills use a soft theme-harmonized palette, not clashy primaries.

5. **Verify in the browser before declaring done — mandatory.** Open the file in chrome-devtools, run `list_console_messages` (must be zero errors), and `take_screenshot` to confirm it renders. For animated figures, pin each state (set the layers' opacity via `evaluate_script`) and screenshot BOTH states. Every page in this style was validated this way; do not skip it.

## Prose inside the page

For headline/lead/body copy, write in the user's voice (the `burgess_voice` skill applies to the prose): open with a fact or tension, not a generic statement; concede limits; lead callouts with the problem, then the fix.

## Reference

- `references/template.html` — copy this; it is the source of truth for theme + structure (self-contained, deterministic).
- `references/patterns.md` — animated-SVG generator recipe, the chrome-devtools verify checklist, inline-SVG rationale, flow-diagram pattern, and figure-color guidance.
- Living exemplars (project-specific; read if present): `<project>/docs/<topic>-explainer.html`.
