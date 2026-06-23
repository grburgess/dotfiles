# Editorial Dark Atlas — Plot Recipes

Code recipes for the common plot types. All assume `atlas_dark.py` is importable as `atlas_dark` (drop it into `<project>/<lib>/` or similar).

## Table of contents

1. [Choropleth heat-cell map](#1-choropleth-heat-cell-map)
2. [Dual-layer polygon map (primary + exclusion)](#2-dual-layer-polygon-map-primary--exclusion)
3. [Full atlas map (land + states + primary + exclusion + heat cells)](#3-full-atlas-map)
4. [Cluster overlay with labels](#4-cluster-overlay-with-labels)
5. [Line plot — multiple series](#5-line-plot)
6. [Bar chart — categorical](#6-bar-chart)
7. [Scatter — with size/color encoding](#7-scatter)
8. [Multi-panel figure](#8-multi-panel-figure)
9. [Animated film (matplotlib + FFMpegWriter)](#9-animated-film-mp4)
10. [Plotly variant (interactive HTML)](#10-plotly-variant)

---

## 1. Choropleth heat-cell map

```python
import matplotlib.pyplot as plt
import geopandas as gpd
from atlas_dark import apply_atlas, PALETTE, grid_backdrop_kwargs, state_lines_kwargs, heat_kwargs

cells = gpd.read_parquet("cells_with_values.parquet")  # has 'value' column
land  = gpd.read_parquet("conus_land.parquet")
states = gpd.read_parquet("states.parquet")

with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(14, 8))
    land.plot(ax=ax, **grid_backdrop_kwargs())
    cells.plot(ax=ax, **heat_kwargs("value", scheme="Quantiles", k=7, legend=True))
    states.boundary.plot(ax=ax, **state_lines_kwargs())
    ax.set_axis_off()
    ax.set_title("Cell values — quantile choropleth", loc="left", pad=10)
    plt.savefig("heat.png", dpi=200, bbox_inches="tight", facecolor=PALETTE["bg"])
```

## 2. Dual-layer polygon map (primary + exclusion)

The signature move of the atlas: one saturated hero layer, one soft tint with a stronger boundary.

```python
with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(14, 8))
    land.plot(ax=ax, **grid_backdrop_kwargs())
    # Primary feature: violet at α=0.85
    primary_gdf.plot(ax=ax, **primary_kwargs())
    # Exclusion: teal at α=0.10 fill + α=0.65 boundary
    exclusion_gdf.plot(ax=ax, **exclusion_fill_kwargs())
    exclusion_gdf.boundary.plot(ax=ax, **exclusion_boundary_kwargs())
    states.boundary.plot(ax=ax, **state_lines_kwargs())
    ax.set_axis_off()
    plt.savefig("dual.png", dpi=200, bbox_inches="tight", facecolor=PALETTE["bg"])
```

## 3. Full atlas map

Land + state boundaries + primary footprint + exclusion mask + wishlist heat cells, with manual legend.

```python
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(15, 9))
    land.plot(ax=ax, **grid_backdrop_kwargs())
    primary_gdf.plot(ax=ax, **primary_kwargs())
    exclusion_gdf.plot(ax=ax, **exclusion_fill_kwargs())
    exclusion_gdf.boundary.plot(ax=ax, **exclusion_boundary_kwargs())
    cells.plot(ax=ax, **heat_kwargs("req_count", scheme="Quantiles", k=7))
    states.boundary.plot(ax=ax, **state_lines_kwargs())

    legend_items = [
        Patch(facecolor=PALETTE["primary_fill"], alpha=0.85, label="Primary footprint"),
        Patch(facecolor=PALETTE["exclusion_fill"], edgecolor=PALETTE["exclusion_boundary"],
              alpha=0.6, label="Exclusion zone"),
        Line2D([0],[0], color=PALETTE["state_line"], lw=0.5, label="State boundary"),
    ]
    ax.legend(handles=legend_items, loc="lower left", frameon=True)
    ax.set_axis_off()
    ax.set_title("Wishlist within budget", loc="left", pad=10, fontsize=14)
    plt.savefig("atlas.png", dpi=220, bbox_inches="tight", facecolor=PALETTE["bg"])
```

## 4. Cluster overlay with labels (hybrid — stay on dual-layer palette)

For HDBSCAN strip / zone overlays in a deck whose other figures already use dual-layer styling (e.g. `slate_navy`). Don't switch variants — use the `_quiet` exclusion helpers to drop the VX layer's volume and pick a warm complementary cmap so the clusters become the new hero without introducing a third color system.

```python
from atlas_dark import (
    apply_atlas, PALETTE, use_variant,
    grid_backdrop_kwargs, state_lines_kwargs,
    exclusion_fill_kwargs_quiet, exclusion_boundary_kwargs_quiet,
    cluster_edge_kwargs,
)

use_variant("slate_navy")        # same palette as the rest of the deck

with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(14, 8))
    land.plot(ax=ax, **grid_backdrop_kwargs())
    # VX whispers — same teal, ~40% of usual alpha
    vx.plot(ax=ax, **exclusion_fill_kwargs_quiet())
    vx.boundary.plot(ax=ax, **exclusion_boundary_kwargs_quiet())
    states.boundary.plot(ax=ax, **state_lines_kwargs())
    # Clusters become the new hero — warm cmap complements the teal field
    clusters.plot(ax=ax, column="total_requests", cmap="atlas_molten",
                  alpha=0.9, **cluster_edge_kwargs(), legend=True)
    for _, row in clusters.iterrows():
        c = row.geometry.centroid
        ax.annotate(str(row["cluster_id"]), (c.x, c.y),
                    color=PALETTE["cluster_label_color"], fontsize=8, ha="center",
                    bbox=dict(facecolor=PALETTE["cluster_label_bg"], alpha=0.85,
                              edgecolor="none", boxstyle="round,pad=0.2"))
    ax.set_axis_off()
    plt.savefig("clusters.png", dpi=220, bbox_inches="tight", facecolor=PALETTE["bg"])
```

**Why this works:** `slate_navy`'s teal is preserved (so the deck reads as one), but `_quiet` drops the cumulative weight of the 1M km² VX field. `atlas_molten` (burnt orange → cream, low → high) is the warm complement to teal — no purple mid-tones to fight the exclusion hue, and high-value strips glow cream against the canvas while low-value strips recede into a deep ember. Pick `atlas_ylord` or `atlas_rose` for the same logic in a different warm-hue register.

## 5. Line plot

```python
from atlas_dark import apply_atlas, PALETTE, line_kwargs

with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(10, 5))
    for i, (label, y) in enumerate(series.items()):
        ax.plot(x, y, label=label, **line_kwargs(i))
    ax.set_xlabel("Date")
    ax.set_ylabel("Value")
    ax.set_title("Monthly trend", loc="left")
    ax.grid(True, alpha=0.15)
    ax.legend(loc="upper left")
    plt.savefig("line.png", dpi=200, bbox_inches="tight", facecolor=PALETTE["bg"])
```

## 6. Bar chart

```python
from atlas_dark import apply_atlas, PALETTE, bar_kwargs

with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.bar(categories, values, **bar_kwargs(0))
    ax.set_title("Top-30 zones by request volume", loc="left")
    ax.tick_params(axis="x", rotation=40)
    for spine in ("top", "right", "left", "bottom"):
        ax.spines[spine].set_visible(False)
    ax.grid(True, axis="y", alpha=0.15)
    plt.savefig("bar.png", dpi=200, bbox_inches="tight", facecolor=PALETTE["bg"])
```

## 7. Scatter

```python
from atlas_dark import apply_atlas, PALETTE

with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(8, 8))
    sc = ax.scatter(df.x, df.y, c=df.value, cmap=PALETTE["heat_cmap"],
                    s=df.size_scaled, alpha=0.75, edgecolor="none")
    cb = plt.colorbar(sc, ax=ax, shrink=0.7, pad=0.02)
    cb.set_label("Value", color=PALETTE["text"])
    ax.set_xlabel("X"); ax.set_ylabel("Y")
    plt.savefig("scatter.png", dpi=200, bbox_inches="tight", facecolor=PALETTE["bg"])
```

## 8. Multi-panel figure

```python
with plt.rc_context(apply_atlas()):
    fig, axes = plt.subplots(2, 2, figsize=(14, 10), constrained_layout=True)
    # ... fill each axes ...
    for ax in axes.flat:
        ax.set_facecolor(PALETTE["bg"])  # constrained_layout sometimes overrides
    fig.suptitle("Atlas — quarterly comparison", color=PALETTE["text"], fontsize=14)
    plt.savefig("multi.png", dpi=200, bbox_inches="tight", facecolor=PALETTE["bg"])
```

## 9. Animated film (MP4)

```python
import matplotlib.animation as anim
from atlas_dark import apply_atlas, PALETTE

with plt.rc_context(apply_atlas()):
    fig, ax = plt.subplots(figsize=(14, 8))
    def draw_frame(i):
        ax.clear()
        ax.set_facecolor(PALETTE["bg"])  # clear() resets, so re-apply
        # ... plot frame i ...
    writer = anim.FFMpegWriter(fps=2, bitrate=4000,
                                extra_args=["-pix_fmt", "yuv420p"])
    a = anim.FuncAnimation(fig, draw_frame, frames=N)
    a.save("film.mp4", writer=writer, dpi=160,
           savefig_kwargs=dict(facecolor=PALETTE["bg"]))
```

## 10. Plotly variant

```python
import plotly.graph_objects as go
from atlas_dark import PALETTE, plotly_layout, matplotlib_cmap_to_plotly

fig = go.Figure()
fig.add_trace(go.Scatter(
    x=x, y=y, mode="lines",
    line=dict(color=PALETTE["line_cycle"][0], width=2),
    name="Series A",
))
fig.update_layout(**plotly_layout(), title="Interactive trend")
fig.write_html("interactive.html")
```

For choropleths, use `colorscale=matplotlib_cmap_to_plotly("magma")`.

---

## Saving — checklist

Every `savefig` should include:

- `facecolor=PALETTE["bg"]` — otherwise matplotlib defaults to white on save
- `dpi=200` minimum (220+ for slides), `300` for print
- `bbox_inches="tight"` — but watch for clipping on figures with text annotations near the edge

For animations, pass `savefig_kwargs=dict(facecolor=PALETTE["bg"])` to `.save()`.
