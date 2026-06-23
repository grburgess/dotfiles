---
name: doumont-plotting
description: Apply Jean-luc Doumont's "Trees, Maps, and Theorems" framework to graphical displays — when creating, critiquing, or improving any plot, chart, graph, figure, or data visualization. Use this whenever the user asks to make a plot, build a figure, design a chart, write a figure caption, choose a graph type, or critique a visualization, even if they don't mention Doumont. The framework treats graphs as purpose-driven communication, not decoration — every drop of ink should carry a message.
---

# Effective graphical displays (Doumont)

A graph is not a picture of data. It is a tool to get one message across to one audience. The same three laws that govern writing govern graphs: **adapt to your audience, maximize signal-to-noise, use effective redundancy.** Everything below follows from that.

A picture is *not* always worth a thousand words. Visual codings are intuitive, global, fast — perfect for spatial, comparative, or relational meaning. Verbal codings are precise, sequential, abstract — better when accuracy and ambiguity-free meaning matter. Choose the coding to fit what must be communicated, then use the other as backup (effective redundancy).

## The fundamentals applied to graphs

### Signal-to-noise

Most "noise" in scientific graphs is unintentional, decorative, or convention-driven:

- **3D effects on 2D data** — adds no information, distorts perception.
- **Gradient fills, drop shadows, textures** — decorative ink, no signal.
- **Heavy gridlines, dense tick marks, dark borders** — compete with the data for ink dominance.
- **Default-software ornament** — chart-junk legends, oversized titles, redundant labels.
- **Bright backgrounds** behind data — visual cost, no benefit.

Rule of thumb from the book: *the data lines should be the heaviest ink on the graph*. Axes, ticks, gridlines should be thinner and lighter than the data they support. If you cannot see the trend at a glance, the noise has won.

### Adapting to the audience

Specialists tolerate (and want) more density: log axes, broken scales, multiple series. Nonspecialists need labels in plain language, units expanded, and one main visual idea per figure. A figure for a journal differs from the same figure for a board slide.

### Effective redundancy

A categorical variable encoded by color *and* shape *and* position is more robust than any one alone (Doumont's stop sign: red + octagon + the word STOP). Use redundancy when the reader might be color-blind, when the figure might be printed in greyscale, or when the legend is far from the data.

But concurrent codings that *compete* are worse than no redundancy: a dual y-axis with mismatched scales, a pie chart with both slices and exploded labels and percentages and a legend — these are noise pretending to be redundancy.

## The five-step workflow

### 1. Plan — purpose and message

Before opening any plotting library, answer:

- **What is the one message?** State it as a complete sentence (the "so what"), not as a noun phrase (the "what"). Not *Sales over time*; rather *Sales dropped 40% after the policy change*. The message determines everything else.
- **Who is the audience?** What do they already see in this data, and what is new?
- **What constraints?** Print or screen, color or grayscale, figure size, journal style, accompanying text or standalone.

If you cannot state the message, the graph has no purpose yet. Ask the user for it.

### 2. Design — choose the right graph type

The graph type follows from the *kind of relationship* being shown, not from data format. Common families:

| To show… | Use… |
|---|---|
| A single number's magnitude in context | Annotated value, sometimes a single bar |
| Comparison across a few categories | Bar chart (horizontal if labels are long) |
| Composition of a whole, few parts | Stacked bar (rarely a pie — only when ≤4 parts and ratios are obvious) |
| Distribution of a continuous variable | Histogram, density, or ECDF |
| Distribution comparison across groups | Small multiples, ridge plots, or overlaid densities |
| Trend over time | Line plot |
| Relationship between two continuous variables | Scatter plot |
| Many series over time / multi-condition | Small multiples (faceted), not a spaghetti chart |
| Hierarchy / nested categories | Grouped bars, treemap (use cautiously), or bar chart with grouping |

Doumont notes specifically: **pie charts struggle past five slices** because angular comparison is harder than length comparison. A bar chart almost always communicates composition better, and it preserves a sortable axis. Reserve pies for ≤4 parts where the message is genuinely about a few proportions of a whole.

**Avoid by default**: 3D bars, 3D pies, dual y-axes, stacked area with many series, radial layouts where rectangular would do.

### 3. Design — axes, scales, encodings

- **Axes are scaffolding, not decoration.** Light grey lines, modest tick marks, restrained labels. The data should dominate.
- **Start the y-axis at zero for bar charts** (length encoding is read as ratio — truncating the axis lies). For line plots and scatters, start where the data lives — but make a broken axis explicit if relevant.
- **Log scale** when the data span orders of magnitude or when ratios matter. Label so a nonspecialist can tell it's log.
- **Color** carries meaning only after position and length. Use it for categories (qualitative palette) or ordered magnitude (sequential / diverging palette) — never both interchangeably. Default to colorblind-safe palettes. Use grey as the workhorse non-color and reserve hue for what matters.
- **Direct labels beat legends.** A line annotated at its right end with the series name removes a saccade to a legend box.
- **Units in axis titles**, not in every tick label.

### 4. Construct — minimum ink, maximum clarity

A useful test: print the graph in grayscale and squint. Can you still see the message? If not, the data is not the heaviest ink, or the encoding leans too hard on color.

Specifically:
- Remove the chart border unless it serves a purpose.
- Remove redundant gridlines (keep one direction if the eye needs to track values; remove both if not).
- Soften minor ticks; emphasize major ticks that carry round, memorable values.
- Use sentence-case axis titles and labels — not Title Case Shout.
- Increase font size for anything a reader will read at viewing distance. Default plot fonts are usually too small for presentations.

### 5. Draft the caption — state the message

This is the rule Doumont emphasizes most for figures and one that authors most often miss:

> **A figure caption should state the message, not describe what's shown.**

Bad (a *what* caption): *Sales by quarter, 2019–2023.*

Better (a *so what* caption): *Sales dropped 40% in Q3 2021 after the policy change and have not recovered.*

The figure itself shows the *what*. The caption tells the reader the *so what* they should take away — the message. A reader scanning figures and captions alone should learn the conclusions of the document.

A figure that needs no caption to convey its message is rare and excellent. A figure whose caption only describes what is plotted is doing half the job.

## Common shortcomings to flag in critique

When reviewing someone's plot, look specifically for:

- **3D pies, 3D bars, gradient-filled bars** — almost always chart-junk.
- **Truncated y-axes on bar charts** without explicit indication — misleading.
- **Spaghetti line plots** with >5 series and no direct labels — convert to small multiples or highlight one + grey out the rest.
- **Pie chart with >5 slices** — convert to a sorted bar chart.
- **Default Excel/matplotlib styling** untouched — usually too heavy on borders, gridlines, and font weight, too light on data.
- **Legends far from the data** when direct labels would work.
- **Color carrying meaning that grayscale would lose** — add shape, position, or label redundancy.
- **Captions that describe rather than conclude** — rewrite as the message sentence.
- **Dual y-axes** with arbitrary scaling — usually two graphs would be honest, one is deceptive.
- **Axes without units** or with the unit hidden in the caption rather than the title.
- **Title and caption duplicating each other** — pick one home for the message.
- **Too many decimal places** in tick labels — round to what the audience can use.
- **Same color used to mean different things** across panels — break the pattern or unify.

## Working with the user

When asked to make a plot: first ask *what is the one message?* and *who is the audience?* Then propose a graph type tied to the message, sketch the encodings, and write the caption as a full message sentence. Do not jump to code until the message is clear — that is Doumont's first move.

When asked to critique a plot: identify (a) what the message appears to be, (b) what encodings serve or fight it, (c) what noise can be removed, and (d) what the caption should say. Explain each suggestion by citing the principle (signal-to-noise, audience, redundancy) so the user can apply it next time.

When generating actual plots in code (matplotlib, seaborn, plotly, ggplot, etc.): apply these defaults — light grey axes thinner than data, no top/right spines unless needed, direct labels where possible, colorblind-safe palette, the caption written as a message sentence in the surrounding markdown or `plt.figtext`. Do not rely on library defaults; they optimize for "looks like a chart," not "carries a message."

## Style cues

- *A picture is worth a thousand words — but only when the message is intuitive, global, or relational. Otherwise, a word is worth a thousand pictures.*
- *Nothing is neutral.* Every line, color, tick, and label is either signal or noise.
- *Theorem, then proof* — for captions: state the message, then let the figure prove it.
