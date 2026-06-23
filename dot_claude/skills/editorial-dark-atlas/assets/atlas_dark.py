"""Editorial dark-atlas matplotlib style — near-black canvas + layered palette.

A reusable styling module for matplotlib figures (maps and general plots) that
need a polished dark-mode aesthetic. Three tiers of dark for depth, one
saturated primary color, one cool secondary used as soft fill + stronger
boundary (or silent gray, depending on variant), warm sequential cmaps for
heat data.

Drop this file into your project (e.g. `<project>/<lib>/atlas_dark.py`) and
import what you need.

Variants — pick one with `use_variant(name)`:

  Dual-layer family (two polygon layers, hero + whisper):
    - "slate_navy"   (default; violet hero + teal exclusion)
    - "deep_forest"  (amber hero + sage exclusion)
    - "deep_plum"    (cyan hero + magenta exclusion)
    - "graphite"     (amber hero + neutral gray exclusion)

  Single-hero family (heat/cmap is the hero; exclusion goes silent):
    - "obsidian"        (true black, VX boundary-only, YlOrRd heat)
    - "neon_noir"       (deepest dark, VX boundary-only, cyan→magenta)
    - "ink_molten"      (true ink, VX silent fill, molten oranges) ← recommended for cluster maps
    - "twilight_coral"  (deep indigo, VX silent fill, rose/coral)

Usage:
    import matplotlib.pyplot as plt
    from atlas_dark import (
        apply_atlas, PALETTE, use_variant,
        primary_kwargs, exclusion_fill_kwargs, exclusion_boundary_kwargs,
        heat_kwargs, line_kwargs,
    )

    use_variant("ink_molten")            # switch palette
    with plt.rc_context(apply_atlas()):
        fig, ax = plt.subplots(figsize=(14, 8))
        ev.plot(ax=ax, **primary_kwargs())
        vx.plot(ax=ax, **exclusion_fill_kwargs())
        vx.boundary.plot(ax=ax, **exclusion_boundary_kwargs())
        plt.savefig("fig.png", dpi=200, facecolor=PALETTE["bg"])
"""
from __future__ import annotations

import matplotlib as mpl
from matplotlib.colors import LinearSegmentedColormap


# ---------------------------------------------------------------------------
# Custom cmaps — registered at import time so they're addressable by string
# name (e.g. cmap="atlas_molten") just like stock cmaps.
#
# Warm cmaps are ordered dark→light (low→high) so high values glow against
# the dark canvas and low values recede into it. Reversing the stop order
# inverts the perceptual mapping — the eye gets pulled to low-value cells
# instead of high-value ones, which defeats the point of a heat layer on a
# dark backdrop. atlas_neon is a hue gradient, not brightness, so it stays.
# ---------------------------------------------------------------------------
_CUSTOM_CMAPS = {
    "atlas_molten":    ["#7c2d12", "#c2410c", "#ea580c", "#f97316", "#fb923c", "#fdba74", "#ffedd5"],
    "atlas_neon":      ["#22d3ee", "#67e8f9", "#a78bfa", "#c084fc", "#d946ef", "#ec4899"],
    "atlas_rose":      ["#7f1d1d", "#be123c", "#e11d48", "#f43f5e", "#fb7185", "#fda4af", "#ffe4e6", "#fff1f2"],
    "atlas_ylord":     ["#7f1d1d", "#991b1b", "#dc2626", "#f97316", "#fb923c", "#fdba74", "#fed7aa", "#fff4e6"],
}

def _register_cmaps():
    for name, stops in _CUSTOM_CMAPS.items():
        mpl.colormaps.register(LinearSegmentedColormap.from_list(name, stops), force=True)

_register_cmaps()


# ---------------------------------------------------------------------------
# Variant definitions
# ---------------------------------------------------------------------------
# Every variant carries the full role set so the kwargs helpers work
# unchanged. Single-hero variants set one of the exclusion alphas to 0
# (effectively turning that helper into a no-op).
# ---------------------------------------------------------------------------
VARIANTS: dict[str, dict] = {

    # ============================== DUAL-LAYER ==============================
    "slate_navy": {
        "bg": "#020617", "land": "#0a1628",
        "state_line": "#64748b", "state_line_w": 0.5,
        "text": "#f1f5f9", "text_dim": "#94a3b8",
        "primary_fill": "#a78bfa", "primary_fill_alpha": 0.85,
        "exclusion_fill": "#5eead4", "exclusion_fill_alpha": 0.10,
        "exclusion_boundary": "#2dd4bf", "exclusion_boundary_alpha": 0.65,
        "exclusion_boundary_width": 0.7,
        "heat_cmap": "magma", "cluster_cmap": "magma",
        "cluster_edge": "#fcd34d", "cluster_edge_w": 0.4,
        "cluster_label_bg": "#020617", "cluster_label_color": "#fcd34d",
        "accent_warm": "#fb923c",
        "line_cycle": ["#a78bfa","#5eead4","#fb923c","#fcd34d","#f472b6","#60a5fa","#a3e635"],
    },

    "deep_forest": {
        "bg": "#0a0f0a", "land": "#0e1610",
        "state_line": "#5a6b5d", "state_line_w": 0.5,
        "text": "#ecfccb", "text_dim": "#84a98c",
        "primary_fill": "#fbbf24", "primary_fill_alpha": 0.85,
        "exclusion_fill": "#86efac", "exclusion_fill_alpha": 0.10,
        "exclusion_boundary": "#4ade80", "exclusion_boundary_alpha": 0.65,
        "exclusion_boundary_width": 0.7,
        "heat_cmap": "inferno", "cluster_cmap": "inferno",
        "cluster_edge": "#fde047", "cluster_edge_w": 0.4,
        "cluster_label_bg": "#0a0f0a", "cluster_label_color": "#fde047",
        "accent_warm": "#fb7185",
        "line_cycle": ["#fbbf24","#86efac","#fb7185","#a3e635","#c084fc","#67e8f9","#fda4af"],
    },

    "deep_plum": {
        "bg": "#1a0a1f", "land": "#22122a",
        "state_line": "#7c5e85", "state_line_w": 0.5,
        "text": "#fce7f3", "text_dim": "#c4b5d8",
        "primary_fill": "#67e8f9", "primary_fill_alpha": 0.85,
        "exclusion_fill": "#f0abfc", "exclusion_fill_alpha": 0.10,
        "exclusion_boundary": "#e879f9", "exclusion_boundary_alpha": 0.65,
        "exclusion_boundary_width": 0.7,
        "heat_cmap": "plasma", "cluster_cmap": "plasma",
        "cluster_edge": "#fde047", "cluster_edge_w": 0.4,
        "cluster_label_bg": "#1a0a1f", "cluster_label_color": "#fde047",
        "accent_warm": "#fb923c",
        "line_cycle": ["#67e8f9","#f0abfc","#fde047","#86efac","#fb923c","#a78bfa","#fb7185"],
    },

    "graphite": {
        "bg": "#0d0d0d", "land": "#171717",
        "state_line": "#737373", "state_line_w": 0.5,
        "text": "#fafafa", "text_dim": "#a3a3a3",
        "primary_fill": "#fbbf24", "primary_fill_alpha": 0.85,
        "exclusion_fill": "#d4d4d4", "exclusion_fill_alpha": 0.10,
        "exclusion_boundary": "#a3a3a3", "exclusion_boundary_alpha": 0.65,
        "exclusion_boundary_width": 0.7,
        "heat_cmap": "inferno", "cluster_cmap": "inferno",
        "cluster_edge": "#fbbf24", "cluster_edge_w": 0.4,
        "cluster_label_bg": "#0d0d0d", "cluster_label_color": "#fbbf24",
        "accent_warm": "#fbbf24",
        "line_cycle": ["#fbbf24","#d4d4d4","#a3a3a3","#fbbf24","#737373","#fbbf24","#525252"],
    },

    # ============================ SINGLE-HERO ============================
    # Exclusion goes silent — either boundary-only (fill_alpha=0) or
    # fill-only (boundary_alpha=0). Picks a heat cmap that doesn't
    # introduce a third hue.

    "obsidian": {
        "bg": "#000000", "land": "#1a1a1a",
        "state_line": "#3f4a4f", "state_line_w": 0.5,
        "text": "#f5f5f4", "text_dim": "#a8a29e",
        "primary_fill": "#dc2626", "primary_fill_alpha": 0.85,
        # exclusion: boundary-only, muted slate-blue
        "exclusion_fill": "#3f4a4f", "exclusion_fill_alpha": 0.0,
        "exclusion_boundary": "#3f4a4f", "exclusion_boundary_alpha": 0.55,
        "exclusion_boundary_width": 0.5,
        "heat_cmap": "atlas_ylord", "cluster_cmap": "atlas_ylord",
        "cluster_edge": "#fcd34d", "cluster_edge_w": 0.35,
        "cluster_label_bg": "#000000", "cluster_label_color": "#fcd34d",
        "accent_warm": "#dc2626",
        "line_cycle": ["#dc2626","#fdba74","#fde047","#a8a29e","#f97316","#fb923c","#fca5a5"],
    },

    "neon_noir": {
        "bg": "#030308", "land": "#0a0b12",
        "state_line": "#1e3a5f", "state_line_w": 0.4,
        "text": "#f5f5f4", "text_dim": "#a8a29e",
        "primary_fill": "#ec4899", "primary_fill_alpha": 0.9,
        # exclusion: boundary-only, dim slate-cyan
        "exclusion_fill": "#1e3a5f", "exclusion_fill_alpha": 0.0,
        "exclusion_boundary": "#1e3a5f", "exclusion_boundary_alpha": 0.70,
        "exclusion_boundary_width": 0.6,
        "heat_cmap": "atlas_neon", "cluster_cmap": "atlas_neon",
        "cluster_edge": "#22d3ee", "cluster_edge_w": 0.4,
        "cluster_label_bg": "#030308", "cluster_label_color": "#22d3ee",
        "accent_warm": "#ec4899",
        "line_cycle": ["#22d3ee","#a78bfa","#ec4899","#67e8f9","#c084fc","#f472b6","#fde047"],
    },

    "ink_molten": {
        "bg": "#020203", "land": "#0c0c0e",
        "state_line": "#3a3a3f", "state_line_w": 0.4,
        "text": "#f5f5f4", "text_dim": "#a8a29e",
        "primary_fill": "#ea580c", "primary_fill_alpha": 0.85,
        # exclusion: fill-only, silent dark slate (no boundary)
        "exclusion_fill": "#1a1d22", "exclusion_fill_alpha": 1.0,
        "exclusion_boundary": "#1a1d22", "exclusion_boundary_alpha": 0.0,
        "exclusion_boundary_width": 0.0,
        "heat_cmap": "atlas_molten", "cluster_cmap": "atlas_molten",
        "cluster_edge": "#fcd34d", "cluster_edge_w": 0.4,
        "cluster_label_bg": "#020203", "cluster_label_color": "#fcd34d",
        "accent_warm": "#ea580c",
        "line_cycle": ["#ea580c","#fdba74","#fcd34d","#fb923c","#f97316","#fed7aa","#a8a29e"],
    },

    "twilight_coral": {
        "bg": "#070514", "land": "#0d0a1e",
        "state_line": "#4a4475", "state_line_w": 0.4,
        "text": "#f5f5f4", "text_dim": "#c4b5d8",
        "primary_fill": "#e11d48", "primary_fill_alpha": 0.85,
        # exclusion: fill-only, silent indigo
        "exclusion_fill": "#1a1638", "exclusion_fill_alpha": 0.8,
        "exclusion_boundary": "#1a1638", "exclusion_boundary_alpha": 0.0,
        "exclusion_boundary_width": 0.0,
        "heat_cmap": "atlas_rose", "cluster_cmap": "atlas_rose",
        "cluster_edge": "#fda4af", "cluster_edge_w": 0.35,
        "cluster_label_bg": "#070514", "cluster_label_color": "#fda4af",
        "accent_warm": "#e11d48",
        "line_cycle": ["#e11d48","#fda4af","#c084fc","#67e8f9","#fb7185","#a78bfa","#fde047"],
    },
}


# ---------------------------------------------------------------------------
# Active palette — swap with use_variant()
# ---------------------------------------------------------------------------
def _build_palette(variant: dict) -> dict:
    """Add derived fields (grid colors) that helpers expect."""
    p = dict(variant)
    p.setdefault("grid_color", p["land"])
    p.setdefault("grid_edge", "none")
    return p


PALETTE: dict = _build_palette(VARIANTS["slate_navy"])


def use_variant(name: str) -> dict:
    """Switch the active palette to a named variant — FULL swap.

    Mutates the module-level PALETTE so all downstream helpers pick up the
    new values. This is the right call when you want a clean re-skin and
    your primary/exclusion don't have to be semantic anchors.

    For the case where primary is a semantic anchor (e.g. a brand color or
    a domain-specific identity that must stay constant across re-skins),
    use `use_backdrop(name)` instead — it preserves primary_fill while
    swapping canvas + exclusion treatment + heat cmap.

    Raises KeyError if `name` is not a registered variant.
    """
    if name not in VARIANTS:
        raise KeyError(
            f"unknown variant {name!r}. "
            f"available: {sorted(VARIANTS)}"
        )
    PALETTE.clear()
    PALETTE.update(_build_palette(VARIANTS[name]))
    return PALETTE


# Keys that get swapped by `use_backdrop`. Anything NOT in here is preserved
# from the prior palette — most importantly `primary_fill` and
# `primary_fill_alpha`, which are treated as semantic anchors.
_BACKDROP_KEYS = {
    "bg", "land", "state_line", "state_line_w",
    "text", "text_dim",
    "exclusion_fill", "exclusion_fill_alpha",
    "exclusion_boundary", "exclusion_boundary_alpha", "exclusion_boundary_width",
    "heat_cmap", "cluster_cmap",
    "cluster_edge", "cluster_edge_w",
    "cluster_label_bg", "cluster_label_color",
    "grid_color", "grid_edge",
}


def use_backdrop(name: str) -> dict:
    """Switch canvas + exclusion treatment + heat cmap, but KEEP primary fixed.

    Use this when primary_fill is a semantic anchor (e.g. a brand color, a
    domain identity like "BrandX = violet") that must read the same
    across figures regardless of which backdrop scheme is active.

    Mechanically: takes the named variant, pulls only the backdrop-related
    keys, and merges them into the active PALETTE. `primary_fill` and
    `primary_fill_alpha` are explicitly preserved. This is the right tool
    for decks where some figures show the primary as a labeled peer (uses
    primary_kwargs) and others use it as a backdrop reference (uses
    exclusion_*_kwargs reading the scheme-specific treatment).
    """
    if name not in VARIANTS:
        raise KeyError(
            f"unknown variant {name!r}. "
            f"available: {sorted(VARIANTS)}"
        )
    src = _build_palette(VARIANTS[name])
    for k in _BACKDROP_KEYS:
        if k in src:
            PALETTE[k] = src[k]
    PALETTE["backdrop"] = name
    return PALETTE


def list_variants() -> list[str]:
    return sorted(VARIANTS)


# ---------------------------------------------------------------------------
# rcParams — apply via `with plt.rc_context(apply_atlas()):`
# ---------------------------------------------------------------------------
def apply_atlas() -> dict:
    """rcParams dict for `with plt.rc_context(...)` — editorial dark atlas.

    Reads the currently-active PALETTE. Call `use_variant(...)` first if you
    want a non-default palette.
    """
    return {
        "figure.facecolor":      PALETTE["bg"],
        "axes.facecolor":        PALETTE["bg"],
        "savefig.facecolor":     PALETTE["bg"],
        "axes.edgecolor":        PALETTE["state_line"],
        "axes.labelcolor":       PALETTE["text"],
        "axes.titlecolor":       PALETTE["text"],
        "axes.titleweight":      "bold",
        "axes.titlesize":        13,
        "axes.labelsize":        11,
        "xtick.color":           PALETTE["text_dim"],
        "ytick.color":           PALETTE["text_dim"],
        "xtick.labelsize":       9,
        "ytick.labelsize":       9,
        "text.color":            PALETTE["text"],
        "legend.facecolor":      PALETTE["land"],
        "legend.edgecolor":      PALETTE["state_line"],
        "legend.labelcolor":     PALETTE["text"],
        "legend.framealpha":     0.9,
        "axes.spines.top":       False,
        "axes.spines.right":     False,
        "axes.spines.left":      False,
        "axes.spines.bottom":    False,
        "axes.grid":             False,
        "grid.color":            PALETTE["state_line"],
        "grid.alpha":            0.15,
        "grid.linewidth":        0.5,
        "axes.prop_cycle":       _cycler_from(PALETTE["line_cycle"]),
    }


def _cycler_from(colors):
    from cycler import cycler
    return cycler(color=colors)


# ---------------------------------------------------------------------------
# Geo plot kwargs (geopandas .plot)
# ---------------------------------------------------------------------------
def grid_backdrop_kwargs():
    """For the land/grid backdrop polygon (CONUS land, country outline, etc.)."""
    return dict(color=PALETTE["grid_color"], edgecolor=PALETTE["grid_edge"])


def state_lines_kwargs():
    """For the state/admin boundary overlay."""
    return dict(color=PALETTE["state_line"], linewidth=PALETTE["state_line_w"])


def primary_kwargs():
    """The hero feature layer — saturated, high-alpha fill, no edge."""
    return dict(
        color=PALETTE["primary_fill"],
        edgecolor="none",
        alpha=PALETTE["primary_fill_alpha"],
    )


def exclusion_fill_kwargs():
    """Secondary/exclusion layer fill. May be invisible (alpha=0) in single-hero variants."""
    return dict(
        color=PALETTE["exclusion_fill"],
        edgecolor="none",
        alpha=PALETTE["exclusion_fill_alpha"],
    )


def exclusion_boundary_kwargs():
    """Secondary/exclusion boundary. May be invisible (alpha=0) in fill-only variants."""
    return dict(
        color=PALETTE["exclusion_boundary"],
        linewidth=PALETTE["exclusion_boundary_width"],
        alpha=PALETTE["exclusion_boundary_alpha"],
        linestyle="-",
    )


# Quiet exclusion variants — for cmap-heavy figures (cluster maps, heat-cell
# choropleths) where the standard exclusion layer would compete with the
# colormap. Same hue, reduced alphas, so the deck stays cohesive but the
# exclusion layer whispers harder.
def exclusion_fill_kwargs_quiet(fill_scale: float = 0.4):
    return dict(
        color=PALETTE["exclusion_fill"],
        edgecolor="none",
        alpha=PALETTE["exclusion_fill_alpha"] * fill_scale,
    )


def exclusion_boundary_kwargs_quiet(alpha_scale: float = 0.6, width_scale: float = 0.7):
    return dict(
        color=PALETTE["exclusion_boundary"],
        linewidth=PALETTE["exclusion_boundary_width"] * width_scale,
        alpha=PALETTE["exclusion_boundary_alpha"] * alpha_scale,
        linestyle="-",
    )


def exclusion_legend_patch_kwargs(alpha: float = 0.7):
    """Visible-by-default legend swatch for the exclusion layer.

    Picks whichever side (fill or boundary) has non-zero alpha in the
    active variant. Without this, boundary-only schemes (obsidian,
    neon_noir) would produce an invisible legend swatch because their
    exclusion_fill_alpha is 0.
    """
    if PALETTE["exclusion_fill_alpha"] > 0.05:
        face = PALETTE["exclusion_fill"]
    else:
        face = PALETTE["exclusion_boundary"]
    return dict(
        facecolor=face,
        edgecolor=PALETTE["exclusion_boundary"],
        linewidth=0.8,
        alpha=alpha,
    )


def heat_kwargs(column: str, cmap: str | None = None, scheme: str | None = None,
                k: int = 7, legend: bool = True):
    """For choropleth heat-cell layers."""
    kw = dict(
        column=column,
        cmap=cmap or PALETTE["heat_cmap"],
        edgecolor="none",
        legend=legend,
    )
    if scheme is not None:
        kw["scheme"] = scheme
        kw["k"] = k
    return kw


def cluster_edge_kwargs():
    """Thin stroke for cluster polygon overlays."""
    return dict(
        edgecolor=PALETTE["cluster_edge"],
        linewidth=PALETTE["cluster_edge_w"],
    )


# ---------------------------------------------------------------------------
# General plot kwargs (line / scatter / bar)
# ---------------------------------------------------------------------------
def line_kwargs(idx: int = 0, lw: float = 1.6, alpha: float = 0.9):
    return dict(
        color=PALETTE["line_cycle"][idx % len(PALETTE["line_cycle"])],
        linewidth=lw,
        alpha=alpha,
    )


def scatter_kwargs(idx: int = 0, s: float = 24, alpha: float = 0.75):
    return dict(
        color=PALETTE["line_cycle"][idx % len(PALETTE["line_cycle"])],
        s=s,
        alpha=alpha,
        edgecolor="none",
    )


def bar_kwargs(idx: int = 0, alpha: float = 0.85):
    return dict(
        color=PALETTE["line_cycle"][idx % len(PALETTE["line_cycle"])],
        edgecolor=PALETTE["state_line"],
        linewidth=0.4,
        alpha=alpha,
    )


def annotate_kwargs(color: str | None = None):
    return dict(
        color=color or PALETTE["text"],
        fontsize=9,
        bbox=dict(
            facecolor=PALETTE["land"],
            edgecolor=PALETTE["state_line"],
            alpha=0.85,
            boxstyle="round,pad=0.3",
        ),
    )


# ---------------------------------------------------------------------------
# Plotly conversion
# ---------------------------------------------------------------------------
def matplotlib_cmap_to_plotly(cmap_name: str, n: int = 32):
    """Convert a matplotlib cmap name (incl. atlas_*) to a Plotly colorscale."""
    import matplotlib.cm as cm
    import matplotlib.colors as mcolors
    cmap = cm.get_cmap(cmap_name, n)
    return [[i / (n - 1), mcolors.to_hex(cmap(i))] for i in range(n)]


def plotly_layout():
    return dict(
        paper_bgcolor=PALETTE["bg"],
        plot_bgcolor=PALETTE["bg"],
        font=dict(color=PALETTE["text"], size=11),
        title=dict(font=dict(color=PALETTE["text"], size=14)),
        xaxis=dict(
            gridcolor=PALETTE["state_line"], gridwidth=0.5,
            zerolinecolor=PALETTE["state_line"],
            tickfont=dict(color=PALETTE["text_dim"]),
        ),
        yaxis=dict(
            gridcolor=PALETTE["state_line"], gridwidth=0.5,
            zerolinecolor=PALETTE["state_line"],
            tickfont=dict(color=PALETTE["text_dim"]),
        ),
        legend=dict(
            bgcolor=PALETTE["land"],
            bordercolor=PALETTE["state_line"],
            font=dict(color=PALETTE["text"]),
        ),
    )
