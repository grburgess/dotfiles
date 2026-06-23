---
name: editorial-dark-atlas
description: Apply a polished near-black editorial dark-mode aesthetic to matplotlib figures — particularly choropleth maps but also general line/bar/scatter plots. Use whenever the user asks for "dark mode" / "darker" / "atlas style" / "editorial" plots, mentions making maps "sexy" / "polished" / "nicer-looking", asks about styling matplotlib for presentations or reports, wants distinct palettes for "primary" vs "exclusion" / "secondary" layers, or asks to make existing plots more visually striking. Also use when building geospatial figures with semi-transparent overlay polygons (coverage zones, masks, exclusion regions) where the user wants the overlay to read as a soft tint with a stronger boundary.
---

# Editorial Dark Atlas

A dark-mode matplotlib aesthetic tuned for cartographic + data figures that need to look like they belong in a magazine spread, not a notebook scratch cell. Near-black canvas, layered depth, one saturated primary color, one cool exclusion color used as a low-alpha tint with a stronger boundary, and warm sequential cmaps that glow against the dark.

## When to use

Trigger on any of:

- "dark mode", "darker", "make it darker", "atlas style", "editorial", "magazine-style"
- "make this map / plot sexy / polished / nicer / publication-quality"
- Geospatial work where two polygon layers need to coexist (a primary footprint + a soft exclusion mask)
- Multi-panel figures going into a deck, doc, Confluence page, or report
- The user shows you a default-matplotlib figure and asks to improve it

Don't use for:

- Light-mode-required outputs (printed reports, light-theme documentation sites)
- Pure data manipulation
- One-off `plt.plot(x, y); plt.show()` debugging plots

## The aesthetic in one paragraph

Three tiers of dark for depth (bg → land → spine/text-dim → text), never pure black. **One** saturated primary color at high alpha. **One** cool exclusion/secondary color used as a faint fill (α ≈ 0.10) paired with a stronger boundary (α ≈ 0.65) — the boundary does the legibility work, the fill just whispers presence. Heat data in `magma` so values glow warm against cool dark. Spines off. Text in slate-100 over slate-400. The whole thing rendered inside a `with plt.rc_context(...)` block, never globally.

## Three-step setup

### 1. Copy the style module into the project

```bash
cp ~/.claude/skills/editorial-dark-atlas/assets/atlas_dark.py <project>/<some_lib_or_notebooks>/
```

The module is self-contained — just `from atlas_dark import apply_atlas, PALETTE, primary_kwargs, exclusion_fill_kwargs, exclusion_boundary_kwargs, heat_kwargs`.

### 2. Pick a variant, then wrap the plot in `rc_context`

```python
import matplotlib.pyplot as plt
from atlas_dark import apply_atlas, PALETTE, use_variant

use_variant("ink_molten")        # pick from list_variants() — default is slate_navy
with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(14, 8))
    # ... plot code ...
    plt.savefig("figure.png", dpi=200, facecolor=PALETTE["bg"])
```

The `rc_context` keeps the styling scoped — you don't mutate global rcParams and break the next plot. Always pass `facecolor=PALETTE["bg"]` to `savefig` so the saved file matches what you see. To mix variants across figures in one notebook, call `use_variant(...)` again before each `with` block.

### 3. Use the pre-built kwargs for layers

The whole point of the kwargs helpers is that plotting calls stay one line. See `references/recipes.md` for full recipes (choropleth, dual-layer overlay, heat cells, line/bar/scatter).

## The palette logic — why these choices

When tuning palettes for new projects, preserve the **roles**, not necessarily the exact hex codes. The roles matter more than the colors.

| Role | Default | What it does |
|---|---|---|
| `bg` | `#020617` slate-950 | Canvas. Pushed near-black with a hint of navy — pure black flattens depth. |
| `land` | `#0a1628` | One step above bg. Used for land polygons, grid backdrop, legend bg. Creates the "stage" effect. |
| `state_line` | `#64748b` slate-500 | Mid-tone, visible against bg without screaming. Used for spines too. |
| `primary_fill` | `#a78bfa` violet-400 | The hero feature. High alpha (~0.85). Picked to be distinct from the exclusion color. |
| `exclusion_fill` | `#5eead4` teal-300 | Soft tint (α 0.10). Cool, complementary to violet primary. |
| `exclusion_boundary` | `#2dd4bf` teal-400 | Stronger (α 0.65). The boundary carries the signal, the fill is atmospheric. |
| `heat_cmap` | `magma` | Warm sequential — high values glow yellow on dark. Avoid `viridis` (greens muddy on this bg). |
| `text` / `text_dim` | `#f1f5f9` / `#94a3b8` | slate-100 over slate-400. Title bright, ticks dim. |

**The trick that makes the dual-polygon look work:** *low fill alpha + higher boundary alpha for the secondary layer.* If both layers get the same opacity treatment, they fight. The exclusion layer should feel like a "presence" — you read its extent from the boundary line, not the fill. See `references/recipes.md` for the dual-polygon recipe.

## Palette variants — two families

Eight variants ship with `atlas_dark.py`. They split into two families based on whether the second layer is a peer to the primary or silenced.

**Dual-layer** — for figures with two competing polygon layers (e.g., EV footprint + VX exclusion mask). Exclusion is a soft tint with a stronger boundary.
- `slate_navy` *(default)* — violet hero + teal exclusion
- `deep_forest` — amber hero + sage exclusion
- `deep_plum` — cyan hero + magenta exclusion
- `graphite` — amber hero + neutral gray exclusion

**Single-hero** — for figures where one layer is a colormap (cluster map, heat-cell choropleth). Exclusion goes silent — boundary-only neutral OR fill-only near-canvas — so the heat cmap can breathe.
- `obsidian` — pure black, VX boundary-only, YlOrRd heat
- `neon_noir` — deepest dark, VX boundary-only, cyan→magenta heat
- `ink_molten` — true ink, VX silent fill, molten oranges (best signal-to-noise for cluster maps)
- `twilight_coral` — deep indigo, VX silent fill, rose/coral heat

**Which family?** If you're stacking two polygon layers that both need to read, dual-layer. If one of your layers is a colormap, single-hero — otherwise the colormap's mid-tones fight the exclusion layer's hue.

**Third option — hybrid (dual-layer + quiet exclusion).** When you want one cmap-heavy figure (e.g. cluster choropleth) in a deck that's otherwise dual-layer, don't switch variants — stay on the dual-layer palette but use `exclusion_fill_kwargs_quiet()` / `exclusion_boundary_kwargs_quiet()` for the cmap figure. The exclusion stays the same hue (so the deck reads cohesively) but whispers harder so the cmap can be the new hero. Pair with a cmap from the warm side of the spectrum (`atlas_molten`, `atlas_ylord`, `atlas_rose`) that complements the exclusion hue rather than fighting it.

**Fourth option — semantic-anchor + scheme-driven backdrop (use `use_backdrop`).** This is the right tool when primary_fill is a fixed identity (a brand color, a domain identity like "BrandX = violet") that must read the same across all figures regardless of which scheme is active. Some figures show the primary/exclusion as labeled peers (use `primary_kwargs()` + a teal-anchored `exclusion_*_kwargs()` you keep at full strength); other figures use the primary as a semantic reference while the colormap is the new hero (use `exclusion_*_kwargs()` reading the scheme's silent backdrop treatment). The pattern:

```python
use_backdrop("ink_molten")     # canvas + cmap + EXCLUSION treatment swap; primary stays violet
# Labeled-peer figure (dual): primary_kwargs() + full-strength exclusion
# Silent-backdrop figure (cmap-hero): exclusion_fill_kwargs() reads scheme's silent treatment
```

Choose based on which key you want as the anchor:
- `use_variant(name)` — full re-skin; everything changes
- `use_backdrop(name)` — primary_fill stays fixed, canvas + exclusion + cmap change. Best when the primary is a semantic anchor.

See `references/palettes.md` for full hex specs, custom atlas cmaps (`atlas_molten`, `atlas_neon`, `atlas_rose`, `atlas_ylord`), and the recipe for mixing variants across figures in one notebook.

## Common pitfalls

- **Don't apply `apply_atlas()` globally** with `plt.rcParams.update(...)`. Use `rc_context` so it's scoped to one figure.
- **Don't forget `savefig(facecolor=PALETTE["bg"])`** — matplotlib's default white facecolor will override your dark figure on save.
- **Don't use `viridis` for heat data on this background.** The greens muddy out. Use `magma`, `inferno`, or `plasma`.
- **Don't bump exclusion fill alpha above ~0.20.** The whole point is that it whispers. If you need it louder, increase the *boundary* alpha or width instead.
- **Don't use pure black `#000000`.** It looks dead next to the slight navy of `#020617`. The hint of color matters.
- **Don't pair primary and exclusion in the same hue family.** Violet primary + teal exclusion works because they're complementary cool tones. Violet primary + purple exclusion would muddy.
- **Test on white backdrop too** — if the figure also needs to render embedded in a light-themed doc viewer, ensure the saved PNG has the dark `facecolor` baked in.

## References

- `references/recipes.md` — code recipes for the common plot types (choropleth, dual-layer map, heat cells with colorbar, line, bar, scatter, multi-panel)
- `references/palettes.md` — palette variants and how to author new ones following the role structure
- `assets/atlas_dark.py` — the bundled style module (copy into the user's project)
