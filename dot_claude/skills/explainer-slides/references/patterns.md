# Explainer patterns — recipes

Deeper conventions for the house-style explainer pages. Read alongside `template.html`.

## 1. Inline SVG over base64 raster (always)

Build figures as inline `<svg>`, not embedded PNGs. Reasons: ~10× smaller, infinitely scalable, diffable in git, and it inherits the theme through `var(--green)`, `var(--purple)`, `var(--warn)`, `var(--ink)`, `var(--muted)`. A static base64 PNG can't recolor with the theme and bloats the file. (A real swap this style made: a 150 KB base64 matplotlib panel → a 51 KB animated inline SVG carrying the same data.)

## 2. Data-driven figure = generator script → inject

When a figure must reflect REAL data (not a toy mock), don't hand-place coordinates. Write a small Python generator:

1. Load the real data (parquet, geometry, metrics …).
2. Normalize to an SVG `viewBox` (compute the bbox, scale to e.g. 0..W; flip y for screen coords).
3. Emit SVG layers as strings — fills/strokes use `var(--…)` so they track the theme.
4. Inject into the page by replacing a placeholder (a regex over an `<img …>` or a marker comment), then write the file back.
5. Print a one-line summary (counts, viewBox) so the result is auditable.

This keeps figures reproducible: re-run the generator when the data changes. Keep the generator in `/tmp` or alongside the doc; reference it in a comment near the injected SVG.

## 3. Animated figures (CSS keyframes + reduced-motion)

For "state A ⇄ state B" reveals (e.g. raw → merged, before → after), draw both layers in one `<svg>` and crossfade with CSS `@keyframes` on `opacity`, scoped to the svg's class so it can't leak:

```css
.fig .layerA { animation: figA 7s ease-in-out infinite; }
.fig .layerB { animation: figB 7s ease-in-out infinite; }
@keyframes figA { 0%,40%{opacity:1} 50%,92%{opacity:0} 100%{opacity:1} }
@keyframes figB { 0%,40%{opacity:0} 50%,92%{opacity:1} 100%{opacity:0} }
@media (prefers-reduced-motion:reduce){
  .fig .layerA{opacity:0;animation:none} .fig .layerB{opacity:1;animation:none}
}
```

Rules: scope keyframes/classes to the figure; persistent context (axes, regions, frame) sits in a non-animated layer behind both states; the reduced-motion fallback pins to the MORE INFORMATIVE state (usually B / "after").

## 4. Flow diagrams (`.flow-svg`)

A pipeline = themed boxes + arrows that draw on when the slide enters:

```html
<svg class="flow-svg reveal" viewBox="0 0 1180 150" role="img" aria-label="A to B to C">
  <defs><marker id="ah" markerWidth="9" markerHeight="9" refX="7" refY="4.5" orient="auto">
    <path d="M0,0 L9,4.5 L0,9 z" fill="var(--green)"/></marker></defs>
  <g font-family="Spline Sans Mono" font-size="13" fill="var(--ink)" text-anchor="middle">
    <rect x="40" y="50" width="220" height="64" rx="12" fill="var(--panel)" stroke="var(--green-deep)"/>
    <text x="150" y="78">stage</text><text x="150" y="96" fill="var(--muted)" font-size="11">note</text>
    <!-- violet box: fill var(--panel-violet) stroke var(--purple-deep) -->
  </g>
  <path class="draw" d="M260,82 L480,82" stroke="var(--green)" stroke-width="2.5" fill="none" marker-end="url(#ah)"/>
</svg>
```

`.draw` paths start hidden (`stroke-dasharray:1; stroke-dashoffset:1`) and animate via the `drawLine` keyframe once `.in` is added. The shared engine fires an `enter` CustomEvent on each `.slide`; the template's per-page script adds `.in` to that slide's `.draw` paths on `enter`. Solid (non-`.draw`) arrows are always visible — use them if you don't want the draw-on effect.

## 5. Figure color discipline

- Themed structure: regions/guides dashed in `var(--purple-deep)`; foreground fills `var(--green)`; seams/airgaps bright `var(--ink)` (white) or `var(--green-bright)`.
- The ONE highlighted case → `var(--warn)` (gold). Don't spend gold on anything else.
- Categorical (many instances): a soft theme-harmonized palette (greens/teals/purples/rose/lime), reduced saturation so it reads on the dark bg — never clashy primaries (no raw `#ff0000`/`#0000ff`). Gold stays reserved for the flagged category.

## 6. chrome-devtools verification checklist (mandatory before "done")

1. Open the file: `new_page` `file:///…/<doc>.html` (or `navigate_page` reload after edits).
2. `list_console_messages` → must be **zero** errors.
3. Scroll the target slide into view (`evaluate_script` `el.scrollIntoView`), `take_screenshot`, and read it back.
4. Animated figure: pin each state via `evaluate_script` (set `layerA.style.opacity=…`, `layerB.style.opacity=…`), screenshot BOTH; then clear the inline styles so the live animation resumes.
5. If a figure is too small to read, temporarily widen it (`svg.style.width='1500px'`) for the screenshot, then reset.
6. Confirm geometry counts / labels match the data the generator reported.

## 7. Slide rhythm

Open (slide 00) with a fact or a tension, not a generic field statement; build to the unsolved question (`burgess_voice`). Use `.callout--issue` then `.callout--fix` to pair a problem with its resolution. One takeaway per slide; one diagram per idea. Keep section labels (`.slide-tag .mono`) short and lowercase.
