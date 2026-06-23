# Editorial Dark Atlas — Palette Variants

Eight variants in two families. Pick a variant with `use_variant(name)`:

```python
from atlas_dark import apply_atlas, use_variant
use_variant("ink_molten")        # switches the active palette
with plt.rc_context(apply_atlas()):
    # ... plot ...
```

All kwargs helpers (`primary_kwargs()`, `exclusion_fill_kwargs()`, `heat_kwargs()`, etc.) read from the active palette — no other code changes when you swap.

---

## The two families — pick the right one

### Dual-layer family

For figures with **two competing polygon layers** (primary footprint + exclusion mask). The exclusion is a soft tint (α 0.10) with a stronger boundary (α 0.65) — present but quiet.

| Variant | Hero | Exclusion | Heat cmap | Mood |
|---|---|---|---|---|
| `slate_navy` *(default)* | violet | teal | magma | general-purpose, professional |
| `deep_forest` | amber | sage green | inferno | environmental, organic |
| `deep_plum` | cyan | magenta | plasma | synthwave, consumer-facing |
| `graphite` | amber | neutral gray | inferno | newspaper, maximum restraint |

### Single-hero family

For figures where **one layer dominates** (cluster choropleth, heat-cell map). The "exclusion" layer is silenced — either boundary-only or fill-only in a near-canvas neutral — so the heat colormap can breathe.

| Variant | Hero | Exclusion treatment | Heat cmap | Mood |
|---|---|---|---|---|
| `obsidian` | red | boundary-only, muted slate-blue | `atlas_ylord` | editorial, FT/NYT |
| `neon_noir` | magenta | boundary-only, dim cyan | `atlas_neon` (cyan→magenta) | bold, presentation-stopper |
| `ink_molten` | burnt-orange | fill-only, silent dark slate | `atlas_molten` (oranges) | best signal-to-noise |
| `twilight_coral` | crimson | fill-only, silent indigo | `atlas_rose` (rose) | softer than obsidian |

### How to choose

- Are you plotting **two competing polygon layers** that both need to read? → dual-layer.
- Is one of your layers a **colormap** (heat cells, cluster strips, choropleth)? → single-hero. The dual-layer setup will make the colormap fight the exclusion layer.
- Mixing both kinds of figure in one deliverable? → Use `slate_navy` for the dual-layer figures and one single-hero variant (most often `ink_molten`) for the heatmap figures. Use `use_variant(...)` per-figure inside a `with` block.

---

## Role reference

| Key | Role |
|---|---|
| `bg` | Canvas. Near-black with a hint of color. Never pure `#000000` unless the variant explicitly calls for it (only `obsidian` does). |
| `land` | One step above bg. Land polygons, grid backdrop, legend bg. The "stage". |
| `state_line` | Mid-tone, visible against bg. Boundaries, spines. |
| `text` / `text_dim` | Title / tick label tier. |
| `primary_fill` (+ alpha) | Hero feature. Saturated, mid-bright, high alpha (~0.85). |
| `exclusion_fill` (+ alpha) | Soft tint in dual-layer (~0.10); silent neutral or 0 in single-hero. |
| `exclusion_boundary` (+ alpha + width) | Strong stroke in dual-layer (~0.65); 0 in fill-only single-hero variants. |
| `heat_cmap` / `cluster_cmap` | Sequential cmap matched to the variant's hue family. |
| `line_cycle` | 7 distinct saturated tones for line/bar/scatter. |

---

## Full variant definitions

The `atlas_dark.py` module ships with all eight registered in the `VARIANTS` dict. Below are the hex values for reference / fork.

### slate_navy (default — dual-layer)

```python
{
    "bg": "#020617", "land": "#0a1628", "state_line": "#64748b",
    "primary_fill": "#a78bfa", "primary_fill_alpha": 0.85,
    "exclusion_fill": "#5eead4", "exclusion_fill_alpha": 0.10,
    "exclusion_boundary": "#2dd4bf", "exclusion_boundary_alpha": 0.65,
    "heat_cmap": "magma",
}
```

### deep_forest (dual-layer)

```python
{
    "bg": "#0a0f0a", "land": "#0e1610", "state_line": "#5a6b5d",
    "primary_fill": "#fbbf24", "primary_fill_alpha": 0.85,
    "exclusion_fill": "#86efac", "exclusion_fill_alpha": 0.10,
    "exclusion_boundary": "#4ade80", "exclusion_boundary_alpha": 0.65,
    "heat_cmap": "inferno",
}
```

### deep_plum (dual-layer)

```python
{
    "bg": "#1a0a1f", "land": "#22122a", "state_line": "#7c5e85",
    "primary_fill": "#67e8f9", "primary_fill_alpha": 0.85,
    "exclusion_fill": "#f0abfc", "exclusion_fill_alpha": 0.10,
    "exclusion_boundary": "#e879f9", "exclusion_boundary_alpha": 0.65,
    "heat_cmap": "plasma",
}
```

### graphite (dual-layer, monochrome editorial)

```python
{
    "bg": "#0d0d0d", "land": "#171717", "state_line": "#737373",
    "primary_fill": "#fbbf24", "primary_fill_alpha": 0.85,
    "exclusion_fill": "#d4d4d4", "exclusion_fill_alpha": 0.10,
    "exclusion_boundary": "#a3a3a3", "exclusion_boundary_alpha": 0.65,
    "heat_cmap": "inferno",
}
```

### obsidian (single-hero, editorial)

```python
{
    "bg": "#000000", "land": "#1a1a1a", "state_line": "#3f4a4f",
    "primary_fill": "#dc2626", "primary_fill_alpha": 0.85,
    # exclusion goes boundary-only — no fill
    "exclusion_fill": "#3f4a4f", "exclusion_fill_alpha": 0.0,
    "exclusion_boundary": "#3f4a4f", "exclusion_boundary_alpha": 0.55,
    "heat_cmap": "atlas_ylord",   # deep red → cream (low → high)
}
```

### neon_noir (single-hero, cyberpunk)

```python
{
    "bg": "#030308", "land": "#0a0b12", "state_line": "#1e3a5f",
    "primary_fill": "#ec4899", "primary_fill_alpha": 0.9,
    # exclusion boundary-only, dim slate-cyan
    "exclusion_fill_alpha": 0.0,
    "exclusion_boundary": "#1e3a5f", "exclusion_boundary_alpha": 0.70,
    "heat_cmap": "atlas_neon",    # cyan→violet→magenta
}
```

### ink_molten (single-hero, recommended for cluster maps)

```python
{
    "bg": "#020203", "land": "#0c0c0e", "state_line": "#3a3a3f",
    "primary_fill": "#ea580c", "primary_fill_alpha": 0.85,
    # exclusion fill-only, silent dark slate (no boundary)
    "exclusion_fill": "#1a1d22", "exclusion_fill_alpha": 1.0,
    "exclusion_boundary_alpha": 0.0,
    "heat_cmap": "atlas_molten",  # burnt orange → cream (low → high)
}
```

### twilight_coral (single-hero, dusky)

```python
{
    "bg": "#070514", "land": "#0d0a1e", "state_line": "#4a4475",
    "primary_fill": "#e11d48", "primary_fill_alpha": 0.85,
    # exclusion fill-only, silent indigo
    "exclusion_fill": "#1a1638", "exclusion_fill_alpha": 0.8,
    "exclusion_boundary_alpha": 0.0,
    "heat_cmap": "atlas_rose",    # crimson → cream (low → high)
}
```

---

## Custom atlas cmaps

The module auto-registers four custom cmaps at import. Address them by name (`cmap="atlas_molten"`) anywhere matplotlib accepts a cmap name.

Warm cmaps are ordered **dark → light (low → high)** so high values glow against the dark canvas and low values recede into it. Do not reverse the stop order — that inverts the perceptual mapping on a dark backdrop (bright low-value cells fight the heat reading).

| Name | Stops (low → high) | Use case |
|---|---|---|
| `atlas_molten` | burnt → orange → cream | warm hero on dark, no hue conflict |
| `atlas_neon` | cyan → violet → magenta | cyberpunk; pairs with `neon_noir` (hue gradient, not brightness) |
| `atlas_rose` | crimson → coral → cream | warm rose hero, pairs with `twilight_coral` |
| `atlas_ylord` | deep red → orange → cream | editorial; pairs with `obsidian` |

---

## Mixing variants in one notebook

Two patterns. The first is cleaner for sub-figures of one report; the second is right when each figure stands alone.

### Per-figure switch (recommended for mixed notebooks)

```python
from atlas_dark import use_variant, apply_atlas, PALETTE, primary_kwargs, exclusion_fill_kwargs, exclusion_boundary_kwargs

# Figures 01–05: dual-layer EV vs VX
use_variant("slate_navy")
with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(...)
    ev.plot(ax=ax, **primary_kwargs())
    vx.plot(ax=ax, **exclusion_fill_kwargs())
    vx.boundary.plot(ax=ax, **exclusion_boundary_kwargs())
    plt.savefig("fig01.png", facecolor=PALETTE["bg"])

# Figure 06: single-hero cluster map
use_variant("ink_molten")
with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(...)
    vx.plot(ax=ax, **exclusion_fill_kwargs())          # silent gray
    clusters.plot(ax=ax, column="reqs", cmap=PALETTE["cluster_cmap"], ...)
    plt.savefig("fig06.png", facecolor=PALETTE["bg"])
```

### One-variant-rules-all

If you want the deck visually consistent, pick a **single-hero** variant for everything and accept that the dual-layer figures will lose their two-color hero/whisper structure (the VX will go silent instead of teal). The EV layer becomes the only colored feature.

---

## Authoring a new variant

To add a ninth variant:

1. Copy an existing entry from `VARIANTS` in `atlas_dark.py`.
2. Pick a name (snake_case).
3. Tune in this order: `bg` → `land` (one step lighter) → `state_line` (visible at 0.5px) → `primary_fill` (saturated mid-tone) → exclusion treatment (dual-layer or single-hero?) → `heat_cmap`.
4. Test by rendering a real plot, not just swatches. Some palettes look great as hex chips and muddy in actual figures.

The role structure is what makes the kwargs helpers reusable — preserve all keys even if you set some alphas to 0.

---

## Light-mode (not recommended)

This skill is optimized for dark mode. If you need a light variant for printed output, build it as a new entry in `VARIANTS` with inverted lightness tiers, but expect to re-tune the cmaps — most of the atlas_* cmaps are designed to glow on dark and will look washed out on light.
