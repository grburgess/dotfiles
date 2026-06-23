---
name: doumont-writing
description: Apply Jean-luc Doumont's "Trees, Maps, and Theorems" framework when writing or revising any professional written document — reports, papers, abstracts, memos, emails, technical documentation, proposals, or any prose intended for a real audience. Use this whenever the user asks to draft, write, revise, improve, restructure, or critique a written document, even if they don't mention Doumont by name. The framework treats writing as architecture, not decoration — purpose-driven structure for rational minds.
---

# Effective written documents (Doumont)

Writing is engineering: optimization under constraints. The goal is not to express yourself — it is to get an audience to *pay attention to, understand, and (be able to) act upon* a maximum of messages, given constraints. Everything below follows from that.

This skill applies Doumont's framework. The framework is principled, not mechanical — explain the *why* when you apply a rule, and adapt to the situation. If the user is writing a haiku, do not give them an abstract.

## The three laws (apply at every level)

1. **Adapt to your audience.** You are the one with a purpose. They are not obligated to read. Identify what they know, what they want, and what they can give you in attention — then shape the document for *them*, not for yourself. Blaming the reader for not understanding fails the first law.

2. **Maximize the signal-to-noise ratio.** Nothing is neutral: anything that does not help the message detracts from it. Default to *suppress, not add*. Typos, filler words, decorative formatting, throat-clearing introductions, unexplained jargon — all noise. Remove every drop of unneeded ink.

3. **Use effective redundancy.** Tell things in complementary ways across complementary codings (text + headings + layout + visuals) so noise in one channel does not erase the message. But concurrent channels that compete (text-heavy slides during a talk) are *more* harmful than no redundancy at all.

## The five-step workflow

When asked to draft a document from scratch, work through these in order. When revising, identify which step the document is failing at and fix that one.

### 1. Plan — the five W's

Before writing a word, answer:

- **Why** (purpose) — What change should this document produce in the reader? Phrase as something they should *be able to do* (sign the contract, replicate the experiment, approve the budget), not as something *you* want (impress, demonstrate). If you cannot state the purpose, you have no metric for success.
- **Who** (audience) — Specialists or nonspecialists? Primary (here-and-now decision-makers) or secondary (distant in time/space, need context)? Most real audiences are mixed.
- **What** (content) — Selected from the purpose, not from what you happen to have.
- **When / Where** (constraints) — Length, deadline, channel.

The purpose is the only metric for whether the document is effective. Without it, you cannot decide what to cut.

### 2. Design — break the chronology

Authors instinctively report work chronologically (motivation → method → result). Readers want the reverse: result first, motivation framed up front, method only if they need it. Effective documents are **audience-ordered, not author-ordered**.

Place a **global component** (abstract / executive summary / foreword + summary) on the first page. It should make sense standing alone — most readers will read nothing else. The seven-part structure that works almost everywhere:

| Part | Question | Tense |
|---|---|---|
| Context | Why now? | present |
| Need | Why this matters to you | present |
| Task | What I/we did | past |
| Object | What this document covers | present |
| Findings | What resulted | past |
| Conclusion | So what? | present |
| Perspectives | What next | future |

The first four are the *before* (motivation, ≈ foreword). The last three are the *after* (outcome, ≈ summary). Missing the motivation makes the document feel *out of the blue*; missing the outcome makes it *promissory*; missing context/conclusion makes it *self-centered*.

### 3. Design — fractal structure

The same global-then-details pattern applies at every level: document, chapter, section, paragraph. A section starts with a paragraph stating its message and previewing its subsections. A paragraph starts with its message sentence. A sentence puts the main clause first.

Hierarchy depth: aim for ≤3 levels (chapters, sections, subsections). Items per level: ≤5. More than that means you should regroup, not add depth. Numbering: decimal (2.4.1), three levels max.

### 4. Draft — state messages upfront

**Every paragraph has one message and states it in the first sentence.** If the message is buried at the end, move it. If there is no message, ask whether the paragraph should exist.

Sentence craft:
- One idea per sentence. Length follows complexity, not the other way around.
- The grammatical subject should be the *topic* (what the sentence is about), and the verb should carry the action. Active voice by default; passive only when the topic is genuinely the patient ("The sample was heated to 200 °C" is fine if the sample is the topic).
- Keep what goes together close together. Long subjects far from their verbs strain short-term memory.
- For complex sentences: main idea in the main clause; supporting detail in subordinate clauses. *Not* the reverse.

Lists (parallel structure):
- ≤5 items.
- Introduce with a clause that all items grammatically complete.
- All items in the same grammatical form.
- Use lists for genuinely comparable items, not to dress up a paragraph.

Word choice priorities (in order): **clarity, accuracy, conciseness**. Use technical terms (precise) but not jargon (cryptic). Spell out acronyms on first use. Replace nominalizations with verbs (*perform an analysis of* → *analyze*). Conciseness is a second-draft optimization — first get it clear and accurate.

### 5. Format — reveal structure visually

Formatting is about *structure*, not aesthetics. Aesthetic appeal follows from clean structure; ugliness distracts.

- Use proximity: closer = related. More space *above* a heading than below it.
- Use similarity: same-level items look the same; different-level items look different.
- Use prominence sparingly. Bold for things readers must notice without reading (headings, figure labels). Italic for emphasis within text. Color only when redundant with another cue, and rarely.
- Leave white space. Visual inflation (everything bold, everything large) defeats itself.

### 6. Revise

Iterate. The first draft is for yourself; revision is for the audience. Read each paragraph and ask: *what is this paragraph's message, and is it the first sentence?* Read each sentence and ask: *what is its subject and verb, and do they carry the meaning?*

## Common shortcomings to flag in critique

When reviewing someone else's draft, watch for these specifically:

- **Chronological structure** masquerading as logical structure (intro → method → results → discussion, with the message buried in discussion).
- **Promissory abstracts** that describe the work without stating findings.
- **Out-of-the-blue abstracts** that state findings without motivation.
- **Buried messages** in paragraphs that start with setup sentences.
- **Passive voice hiding the agent** when the agent matters ("It was decided that…").
- **Subordinate-clause main information** ("Figure 3 shows that the rate dropped" — the rate dropping is the message; *Figure 3 shows that* is meta).
- **Impersonal hedges** (*It is clear that*, *It can be concluded that*) that weaken the very point they introduce.
- **Lists of one** or **one-sentence paragraphs in sequence** — structure without content.
- **Too many heading levels** (2.3.2.1.1) — flatten or regroup.
- **Jargon** vs technical terms: jargon excludes; technical terms include (when defined). Test by asking whether a secondary reader could look up the term.

## Style cues

- *Prose is architecture, not interior decoration* (Hemingway, quoted by Doumont).
- *Effectiveness of assertion is the alpha and omega of style* (Shaw, quoted by Doumont).
- Theorem first, then proof — the mathematician's habit, applied everywhere.

## When this skill applies vs. doesn't

Apply this for any prose written for a real audience with a real purpose: reports, papers, abstracts, emails, memos, proposals, documentation, design docs. Adapt the depth: a one-line Slack message doesn't need a fractal structure, but it still has an audience and a purpose.

Do not apply rigid Doumont rules to creative writing, marketing copy where surprise is the goal, or poetry — those genres optimize for different things.

## Working with the user

When asked to draft: produce a structured outline first (header, foreword in the seven parts, then body) before writing prose. Confirm purpose and audience if unclear — Doumont's first move is always to ask *why* and *who*.

When asked to revise: identify which of the five steps the document is failing at and explain *why* the change improves it, citing the underlying principle (signal-to-noise, audience-first, message-upfront). Don't just rewrite silently — Doumont's framework only sticks if the user sees the reasoning.
