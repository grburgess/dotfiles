---
name: notebook-matplotlib-widget
description: Convention for matplotlib in Jupyter notebooks — always use the interactive `%matplotlib widget` backend (ipympl), never `%matplotlib inline`. Also covers the matched plotting idioms (no `plt.close(fig)` after `plt.show()`; how to save+show together; how to manage figure memory across long notebook sessions without leaking). Use this skill whenever you're creating a Jupyter notebook from scratch, editing an existing notebook to add plotting cells, retrofitting an inline-backend notebook, or troubleshooting matplotlib figures that render partially / lose toolbar / lose interactivity in JupyterLab. Triggers on phrases like "make a notebook that plots X", "add a plot to this notebook", "the figure isn't interactive", "convert this to widget mode", "matplotlib not working in lab", or any mention of matplotlib + notebook in the same task. Applies even if the user doesn't explicitly say "widget".
---

# Notebook matplotlib widget convention

In this user's JupyterLab setup, the default and only correct matplotlib backend in notebooks is `%matplotlib widget` (provided by `ipympl`). It is installed in every mamba env via `create_default_packages`, the JupyterLab host has the matching extensions, and it is the user's workflow expectation. `%matplotlib inline` is incompatible with this setup — it works, but it forfeits interactivity and conflicts with idioms the user relies on (pan/zoom, mouse-coord readout, live updating of figures across cells).

## Core rule

Every notebook that touches matplotlib must begin with `%matplotlib widget` in its setup cell, before any matplotlib import or figure creation. Never emit `%matplotlib inline`, `%matplotlib notebook`, `%matplotlib nbagg`, or call `matplotlib.use(...)` to override this.

## The two paired rules — these are not optional

The widget backend changes the lifecycle of a Figure. The Figure object IS the live widget — its `Canvas` is what the browser hooks for pan/zoom, toolbar, and mouse events. Two idioms that are perfectly safe with the `inline` backend will silently destroy widget interactivity. Both must be avoided.

### Rule 1: never `plt.close(fig)` after `plt.show()` (or `display(fig)`)

```python
# WRONG — kills the widget the moment the cell ends
fig, ax = plt.subplots()
ax.plot(x, y)
fig.savefig("out.png")
plt.show(); plt.close(fig)   # ← the close destroys the widget canvas

# RIGHT — save before show, then let the widget live
fig, ax = plt.subplots()
ax.plot(x, y)
fig.savefig("out.png")
plt.show()
```

This is the single most common failure when retrofitting an inline notebook. The symptom is unambiguous: the figure draws its initial PNG snapshot but the toolbar is missing or non-responsive, mouse-over coordinates don't update, pan/zoom buttons do nothing, and some Artists (lines drawn after first paint, legends, text) never appear. If the user reports any of these, check for `plt.close(...)` after `plt.show(...)` first.

### Rule 2: save BEFORE you show

`fig.savefig(path)` writes a snapshot of the figure's current state. With the widget backend, calling it AFTER `plt.show()` works in principle, but the figure widget may be in mid-update and the saved PNG can be missing freshly-drawn elements. Always do `savefig` then `show`:

```python
fig.savefig(path)
plt.show()
```

If the user explicitly wants a save-after-interactive-tweak workflow, do that interactively in a separate cell — don't bake it into the plotting cell.

## Memory management in long sessions — the hard part

With the inline backend, `plt.close(fig)` after `plt.show()` is the standard idiom for releasing figure memory. With the widget backend you can't do that (Rule 1), so figures accumulate in `pyplot`'s state machine. In a notebook with 30 plot cells, this is real memory pressure. Use one of the following idioms, in order of preference:

### Preferred: wrap plotting in a function with a local figure

```python
def render_per_VXN(N):
    fig, ax = plt.subplots(figsize=(10, 6))
    # ... plot code ...
    fig.savefig(FIG / f"per_VXN_{N}.png")
    plt.show()
    # No close. When the function returns, `fig` is a local var.
    # The widget reference is held by Jupyter; the Python reference goes out of scope.
```

The function-scope approach lets the figure's Python references drop naturally while the widget itself persists as the cell's output. This is the cleanest pattern and matches how the user already writes plotting helpers.

### Acceptable: explicit `display(fig)` then drop the reference

```python
from IPython.display import display
fig, ax = plt.subplots()
ax.plot(x, y)
fig.savefig("out.png")
display(fig)
del fig   # Release the local Python reference; widget output stays in the cell
```

`display` and `plt.show` are nearly equivalent here, but `display` makes the "we are explicitly handing this to the frontend" intent clearer when you also want to `del` afterward.

### Last resort: a kernel restart between heavy plotting sections

If the user is writing a notebook with dozens of large figures and memory is a concern, suggest splitting into multiple notebooks or restarting the kernel partway through. Don't reach for `plt.close` to "fix" it — that's solving inline-era memory pressure with an idiom that breaks the widget backend.

## Retrofitting an existing inline notebook

When the user asks you to modify an existing notebook that uses `%matplotlib inline`:

1. **Change the magic.** In the setup cell, replace `%matplotlib inline` with `%matplotlib widget`. If there is no setup cell with a backend magic, add `%matplotlib widget` as the first line of the first cell that imports matplotlib.
2. **Hunt and remove `plt.close()` after `plt.show()`** across every cell. Use a search across the notebook (e.g., `mcp__plugin_data-agent-kit-starter-pack_notebook__search_cells` for `plt.close`). For each match, if it's paired with a `plt.show()` immediately before, drop the `plt.close()`. If it's standalone (e.g., closing a figure that was never shown), leave it.
3. **Audit the order of `savefig` and `show`.** If you find `plt.show(); fig.savefig(...)`, swap them.
4. **Flag, don't auto-fix, structural issues.** If a notebook uses a pattern like making 50 figures in a loop, that worked with `plt.close` but is incompatible with widgets. Don't silently let it leak; surface the function-scope rewrite to the user as a suggested change.
5. **Tell the user what changed** — succinctly, before they re-run. They may have downstream expectations (e.g., automated PNG export scripts that depend on inline behavior) that need a heads-up.

## When NOT to use widget

These cases want `%matplotlib inline` (or no backend magic at all):

- **Notebooks intended for static rendering** — nbconvert to HTML for sharing, exports for Confluence/Sphinx/docs, papermill batch runs producing static PDFs. Widget figures don't render in those targets without ipympl on the consumer side.
- **CI/CD or scheduled notebook runs** where there is no live frontend.
- **Standalone Python scripts** (not notebooks at all) — `plt.savefig` then nothing, no backend magic needed.

When the user's intent is clearly one of these, override the default and use `inline` (or no magic). State the reason briefly so they can correct you if you guessed wrong.

## Quick reference card

```python
# Setup cell — ALWAYS first, before matplotlib import
%matplotlib widget
import matplotlib.pyplot as plt

# Per-figure pattern
fig, ax = plt.subplots(figsize=(10, 6))
ax.plot(x, y)
fig.savefig(path)   # save first
plt.show()          # then show
# NO plt.close(fig)

# In a function, no extra cleanup needed:
def make_plot(data):
    fig, ax = plt.subplots()
    ax.plot(data)
    fig.savefig("out.png")
    plt.show()
```

## Why this matters (the why behind the rules)

`%matplotlib widget` is what makes Lab a viable replacement for static-PNG workflows. With it, you can rotate a 3D plot, zoom into a heatmap, click a point in a scatter — all without re-executing the cell. The `inline` backend gives you a dead PNG. The user has set up the entire mamba env stack (ipympl in every env, jupyterlab-widgets, nb_conda_kernels) specifically to make `widget` the default. Honoring that convention is the difference between getting interactive plots and silently producing static images that the user has to re-render to actually work with.

The `plt.close` rule looks finicky but it is THE pitfall that breaks widget plots in retrofitted notebooks. The user has hit it in a real production analysis. Internalize Rule 1.
