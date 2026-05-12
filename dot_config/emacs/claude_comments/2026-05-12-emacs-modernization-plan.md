# Emacs Modernization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the broken startup theme load, modernize ~10 plugins to current Emacs-30 equivalents, drop dead code, restructure init.org for correct load order. No keybinding changes.

**Architecture:** Single source file (`init.org`) is org-tangled to `init.el` + new `early-init.el`. Both live under chezmoi source. Each phase = edit `init.org` → re-tangle → byte-compile check → commit. Phases ordered so the user can pause/resume cleanly. `chezmoi apply` deploys.

**Tech Stack:** Emacs 30.x, straight.el, use-package, org-mode tangling, chezmoi.

**Spec:** `claude_comments/2026-05-12-emacs-modernization-design.md`

**Paths (used throughout):**
- Chezmoi source dir: `~/.local/share/chezmoi/dot_config/emacs/`
- Deployed dir: `~/.config/emacs/`
- Edits land in chezmoi source; `chezmoi apply` deploys.

**Repeated commands (referenced as `$TANGLE` and `$BYTECOMPILE` below):**

`$TANGLE`:
```bash
emacs -Q --batch \
  --eval "(require 'org)" \
  --eval "(setq org-confirm-babel-evaluate nil)" \
  --eval "(org-babel-tangle-file \"~/.local/share/chezmoi/dot_config/emacs/init.org\")"
```

`$BYTECOMPILE`:
```bash
emacs -Q --batch -L ~/.local/share/chezmoi/dot_config/emacs \
  -f batch-byte-compile \
  ~/.local/share/chezmoi/dot_config/emacs/init.el \
  ~/.local/share/chezmoi/dot_config/emacs/early-init.el
```
Expected: warnings OK; **no errors**. Common acceptable warnings: `free-variable`, `unused-lexical-variable`. Unacceptable: `Symbol's function definition is void`, `Wrong number of arguments`, unbalanced parens.

---

## Phase 0 — Safety net

### Task 0.1: Backup branch + baseline byte-compile

**Files:** none modified.

- [ ] **Step 1: Create backup branch in chezmoi git**

```bash
cd ~/.local/share/chezmoi
git status
git checkout -b emacs-modernization-2026-05-12
git checkout -b emacs-pre-modernization-backup
git checkout emacs-modernization-2026-05-12
```

Expected: `git status` shows the untracked `claude_comments/` from the spec. Two branches now exist; on `emacs-modernization-2026-05-12`.

- [ ] **Step 2: Commit the design + plan docs**

```bash
git add dot_config/emacs/claude_comments/
git commit -m "docs(emacs): add modernization design + plan"
```

- [ ] **Step 3: Baseline byte-compile of current init.el**

Run `$BYTECOMPILE`. Save stderr for comparison:

```bash
emacs -Q --batch -L ~/.local/share/chezmoi/dot_config/emacs \
  -f batch-byte-compile \
  ~/.local/share/chezmoi/dot_config/emacs/init.el \
  2> /tmp/emacs-baseline-warnings.log
wc -l /tmp/emacs-baseline-warnings.log
```

Expected: completes; some warnings. The line count is the floor — later byte-compiles should not exceed it by much.

---

## Phase 1 — `early-init.el` foundation

### Task 1.1: Add Startup → early-init section

**Files:**
- Modify: `~/.local/share/chezmoi/dot_config/emacs/init.org` (section `* Start up`)
- Will create on tangle: `~/.local/share/chezmoi/dot_config/emacs/early-init.el`

- [ ] **Step 1: Open init.org and locate `** Performance` (line ~64) and `**  Native comp` (line ~80)**

These two blocks currently set `gc-cons-threshold` and native-comp warnings inside `init.el`. They must move to `early-init.el`.

- [ ] **Step 2: Insert a new subsection `** Early init` immediately under `* Start up`**

Insert this org content (the `:tangle` header overrides the file-level `init.el` property):

````org
** Early init
This block tangles to =early-init.el=, which runs before package init and frame creation.

#+begin_src emacs-lisp :tangle ~/.local/share/chezmoi/dot_config/emacs/early-init.el
;;; early-init.el --- Pre-init configuration -*- lexical-binding: t -*-

;; Disable package.el — straight.el is the package manager.
(setq package-enable-at-startup nil)

;; GC tuning during startup (restored to a sane value after init in init.el).
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Native compilation quiet.
(setq native-comp-async-report-warnings-errors 'silent
      native-comp-deferred-compilation t)
(setq comp-async-report-warnings-errors nil)

;; Relocate user-emacs-directory off the source dir before anything reads it.
;; no-littering will pick it up later in init.el.
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/"))

;; Frame chrome: never create the bars, faster than disabling later.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(internal-border-width . 0) default-frame-alist)
(push '(alpha . (85 . 70)) default-frame-alist)

;; Reduce visual noise on startup.
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

(provide 'early-init)
;;; early-init.el ends here
#+end_src
````

- [ ] **Step 3: Update `** Performance` block in init.org**

Replace its body with this (it now runs after the high GC threshold from early-init, restoring a normal value):

````org
** Performance
#+begin_src emacs-lisp
;; Restore GC to sane value after init.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 50 1000 1000)
                  gc-cons-percentage 0.1)
            (message "*** Emacs loaded in %.2fs with %d garbage collections."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))
#+end_src
````

- [ ] **Step 4: Delete `** Native comp` block entirely**

(It moved to early-init.) Delete the org subsection at ~line 80–88.

- [ ] **Step 5: Delete the duplicate transparency block at `** Transparent` (~line 166–175)**

(Frame alpha now set in early-init.) Replace the section body with a one-line comment:

````org
** Transparent
Frame alpha now set in early-init.el; see =Early init= section above.
````

- [ ] **Step 6: Delete duplicate `(setq inhibit-startup-message t)` and the chrome-disable block in `** Default parameters` (~line 144–165)**

Strip the `dolist` block that disables `tool-bar-mode`, `scroll-bar-mode`, `menu-bar-mode`, `tooltip-mode` (early-init's `default-frame-alist` covers them). Keep `fset 'yes-or-no-p`, `set-fringe-mode`, `visible-bell`.

After this step the block reads:

````org
** Default parameters
#+begin_src emacs-lisp
(fset 'yes-or-no-p 'y-or-n-p)
(setq visible-bell t)
(set-fringe-mode 5)
(tooltip-mode -1)
#+end_src
````

- [ ] **Step 7: Move `user-emacs-directory` override out of no-littering block**

In `*** no littering` (~line 177), delete:
```elisp
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))
```

Keep the `(use-package no-littering)` and the `custom-file` lines. (early-init already set `user-emacs-directory`; `url-history-file` is fine being relative since no-littering handles it.)

- [ ] **Step 8: Re-tangle**

Run `$TANGLE`. Verify both files exist:

```bash
ls -la ~/.local/share/chezmoi/dot_config/emacs/{init.el,early-init.el}
```

Expected: both present; `early-init.el` is small (~30 lines).

- [ ] **Step 9: Byte-compile**

Run `$BYTECOMPILE`. Expected: no errors.

- [ ] **Step 10: Deploy + restart Emacs to verify**

```bash
chezmoi apply
```

Then quit and restart Emacs. Expected: starts cleanly, modus-vivendi loads as before (theme fix is Phase 2), no menu/tool/scroll bars, transparency applied. `M-x emacs-init-time` should report a comparable or slightly faster time than before.

- [ ] **Step 11: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_config/emacs/init.org dot_config/emacs/init.el dot_config/emacs/early-init.el
git commit -m "emacs: add early-init.el, move startup config to right phase"
```

---

## Phase 2 — Theme load fix

### Task 2.1: Fix theme bug, single terminal load

**Files:**
- Modify: `init.org` section `*** doom themes` (~line 362)
- Modify: `init.org` section `*** modus` (~line 448)
- Modify: `init.org` section `* Load the primary theme` (~line 4354)

- [ ] **Step 1: Fix doom-themes — move calls from `:init` to `:config`**

Replace the `*** doom themes` block body with:

````org
*** doom themes
#+begin_src emacs-lisp
(use-package doom-themes
  :defer t
  :config
  (doom-themes-visual-bell-config)
  (doom-themes-org-config)
  (doom-themes-neotree-config))
#+end_src
````

(`doom-themes-neotree-config` is harmless once neotree is dropped in Phase 9 — we'll prune it then.)

- [ ] **Step 2: Remove `(load-theme 'modus-vivendi t)` from `*** modus` block**

In the `(use-package modus-themes ...)` block, delete the `:config` body's `(load-theme 'modus-vivendi t)` line. Keep all the `setq modus-themes-*` customization in `:init`.

Resulting block ends with `:init (setq modus-themes-... ...)` and no `:config`. (use-package handles eager load.)

- [ ] **Step 3: Replace the terminal `* Load the primary theme` section**

Delete the broken nested-hook block. Replace with:

````org
* Load the primary theme
Loaded last so all face-customizing packages have registered their faces.

#+begin_src emacs-lisp
(defun jmb/apply-theme (&optional frame)
  "Load the primary theme. Daemon-safe: called per new frame."
  (with-selected-frame (or frame (selected-frame))
    (load-theme 'modus-vivendi t)))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'jmb/apply-theme)
  (jmb/apply-theme))
#+end_src
````

- [ ] **Step 4: Re-tangle, byte-compile, deploy, restart**

```bash
# tangle
$TANGLE
# byte-compile
$BYTECOMPILE
# deploy
chezmoi apply
```

Restart Emacs. Expected: `modus-vivendi` loads on startup with NO competing flicker, no errors. Verify with `M-: custom-enabled-themes RET` — should show `(modus-vivendi)`.

- [ ] **Step 5: Test daemon path (optional but recommended)**

```bash
emacs --daemon
emacsclient -c
```

Expected: new frame appears already themed as modus-vivendi. Kill the daemon with `emacsclient -e '(kill-emacs)'` after verifying.

- [ ] **Step 6: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: fix theme load — terminal jmb/apply-theme, daemon-safe"
```

---

## Phase 3 — Drop dead code

### Task 3.1: Remove unused theme packages

**Files:** Modify `init.org` `*** other themes` block (~line 380–445).

- [ ] **Step 1: Replace entire `*** other themes` block body with empty section + note**

````org
*** other themes
Only =modus-themes= (primary), =ef-themes= (secondary), and =doom-themes= (fallback) are kept. Dropped: kaolin, green-is-the-new-black, green-phosphor, vscode-dark-plus, blueballs-dark, brilliance-dull, nano, writerish-dark, omni, the-matrix.
````

(Delete every `(use-package X-theme ...)` block under this heading except the modus/ef sections which live in `*** modus`.)

- [ ] **Step 2: Re-tangle + byte-compile**

`$TANGLE` then `$BYTECOMPILE`. Expected: no new errors.

- [ ] **Step 3: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: drop unused theme packages"
```

### Task 3.2: Delete commented-out use-package blocks + obvious dead code

**Files:** Modify `init.org` across all sections.

- [ ] **Step 1: Search-and-delete commented use-package blocks**

Open init.org in Emacs. Run `M-x occur RET ;; (use-package RET` to find all commented blocks. Walk each match. Delete the entire commented `(use-package ...)` form for:

- `;; (use-package all-the-icons-ibuffer ...)` (~line 313 area)
- `;; (use-package super-save ...)` (~line 340 area)
- `;; (use-package beacon ...)` (~line 810 area)
- `;; (use-package winner ...)` (~line 1894 area)
- `;; (use-package ace-jump-mode ...)` (~line 1919 area)
- `;; (use-package popper ...)` (~line 1927 area)
- `;; (use-package posframe ...)` (~line 1663–1685 area)
- `;; (use-package vertico-posframe ...)` (~line 1664)
- `;; (use-package prescient ...)`, `;; (use-package ivy-prescient ...)` (~lines 1588–1598)
- `;; (use-package all-the-icons-completion ...)` (~line 1826)
- `;; (use-package origami ...)` (~line 2993)
- `;; (use-package dash ...)` (~line 2987)
- `;; (use-package hideshow ...)` (~line 3021)
- `;; (use-package ghub ...)`, `;; (use-package ghub+ ...)` (~lines 3116–3122)
- `;; (use-package git-commit ...)` (~line 3143)
- `;; (use-package forge ...)` (~line 3166)
- `;; (use-package magit-todos ...)` (~line 3176)  — **wait**: this one becomes uncommented in Phase 17; leave for now.
- `;; (use-package ac-stan ...)` (~line 3352)
- `;; (use-package htmlize ...)`, `;; (use-package org-mime ...)`, `;; (use-package mu4e ...)` and all mu4e-* (~lines 3627–3866)
- `;; (use-package slack ...)`, `;; (use-package alert ...)` (~lines 3877–3900)
- `;; (use-package chatgpt-shell ...)`, `;; (use-package gptel ...)` (~lines 4272–4282) — **wait**: gptel becomes uncommented in Phase 16; leave for now.
- `;; (use-package erc-hl-nicks ...)`, `;; (use-package erc-image ...)`, `;; (use-package erc ...)` (~lines 4303–4310)

- [ ] **Step 2: Drop dead use-packages: sublimity, rubocop, org-bullets**

- `*** sublimity` block (~line 278): delete the `(use-package sublimity ...)` form; keep section as empty placeholder OR delete subsection entirely. Prefer deletion: remove the `** sublimity` heading and its body.
- `(use-package rubocop)` in `* LSP` (~line 2791): delete.
- `*** org bullets` (~line 2542–2557): delete the entire subsection (`(use-package org-bullets ...)`). org-superstar in `*** org super star` replaces it.

- [ ] **Step 3: Re-tangle + byte-compile**

`$TANGLE` then `$BYTECOMPILE`. Expected: no new errors.

- [ ] **Step 4: Restart Emacs, sanity check**

Open Emacs. Verify it still starts. `M-x list-packages` no longer shows org-bullets/sublimity/rubocop as required.

- [ ] **Step 5: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: drop commented-out + unused packages (sublimity, rubocop, org-bullets, mu4e/slack/erc stubs)"
```

### Task 3.3: Strip redundant `:ensure t`

**Files:** Modify `init.org` (global edit).

- [ ] **Step 1: Open init.org in Emacs**

- [ ] **Step 2: Strip `:ensure t` lines via query-replace-regexp**

`M-x query-replace-regexp RET ^\s-*:ensure t\s-*$ RET RET` then answer `!` to replace all.

Expected: ~70–80 replacements. This is safe because `(setq straight-use-package-by-default t)` makes every `use-package` straight-ensured.

- [ ] **Step 3: Manual scan for inline `:ensure t`**

`M-x occur RET :ensure t RET`. For any remaining occurrences (where `:ensure t` is on the same line as other keywords), delete them by hand.

- [ ] **Step 4: Re-tangle + byte-compile**

`$TANGLE` then `$BYTECOMPILE`. Expected: no new errors; warning count comparable to baseline.

- [ ] **Step 5: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: strip redundant :ensure t (straight handles it)"
```

---

## Phase 4 — Section reorganization

### Task 4.1: Move Keyboard section to end

**Files:** Modify `init.org`.

- [ ] **Step 1: Cut entire `* Keyboard` section**

In Emacs: navigate to `* Keyboard` (~line 890). `M-x org-cut-subtree` (or `C-c C-x C-w`).

- [ ] **Step 2: Paste before `* Load the primary theme`**

Navigate to `* Load the primary theme`. Move point to its heading line. `org-paste-subtree` (`C-c C-x C-y`).

Resulting order: `... * Addons → * IRC → * Keyboard → * Load the primary theme`.

- [ ] **Step 3: Move `(load custom-file t)` to immediately before terminal theme load**

Locate `(load custom-file t)` inside `*** no littering` (~line 191). Cut it and the preceding line that sets `custom-file`. Paste into a new section just above `* Load the primary theme`:

````org
* Custom-file
#+begin_src emacs-lisp
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)
#+end_src
````

- [ ] **Step 4: Re-tangle + byte-compile**

`$TANGLE` then `$BYTECOMPILE`. Expected: no errors.

- [ ] **Step 5: Restart Emacs, verify all keybindings still work**

Spot-check: `which-key` popup on `C-c`, your hydras, ace-window key. (You did not change keybindings — they should be identical.)

- [ ] **Step 6: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: reorder — Keyboard section to end, custom-file before theme load"
```

---

## Phase 5 — company → corfu + cape

### Task 5.1: Drop company, extend corfu

**Files:** Modify `init.org` `** company` (~line 1686) and `** region completion Corfu` (~line 1704).

- [ ] **Step 1: Delete entire `** company` subsection**

Cut the section including heading. Company's `:bind` (`C-n`/`C-p` in company-active-map) goes with it; that's an internal keymap, not a global binding, so this does not violate the no-keybinding-changes constraint.

- [ ] **Step 2: Replace corfu block with extended config**

Update `** region completion Corfu` to:

````org
** region completion Corfu
#+begin_src emacs-lisp
(use-package corfu
  :straight (corfu :host github :repo "minad/corfu"
                   :files ("*.el" "extensions/*.el"))
  :bind (:map corfu-map
              ("C-j" . corfu-next)
              ("C-k" . corfu-previous)
              ("C-f" . corfu-insert))
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 2)
  (corfu-preview-current nil)
  (corfu-quit-no-match 'separator)
  :init
  (global-corfu-mode))

(use-package corfu-popupinfo
  :straight nil
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :custom
  (corfu-popupinfo-delay '(0.5 . 0.2)))

(use-package corfu-history
  :straight nil
  :after corfu
  :init (corfu-history-mode 1)
  :config
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package cape
  :straight (cape :host github :repo "minad/cape")
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-elisp-symbol))
#+end_src
````

(Note: `corfu-global-mode` → `global-corfu-mode`; the older name is deprecated.)

- [ ] **Step 3: Re-tangle, byte-compile, restart Emacs**

`$TANGLE` then `$BYTECOMPILE`. Then restart. In a `.py` or `.el` buffer, type a few chars — corfu popup should appear within 0.15s. After a brief pause, popupinfo doc panel should appear.

- [ ] **Step 4: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: drop company, extend corfu w/ popupinfo+history+cape"
```

---

## Phase 6 — lsp-mode → eglot

### Task 6.1: Replace lsp-mode, lsp-ui, lsp-pyright, lsp-julia with eglot

**Files:** Modify `init.org` `* LSP` section (~line 2716–2795) and `*** Julia` (~line 3374).

- [ ] **Step 1: Replace entire `* LSP` section body**

````org
* LSP
Built-in Eglot is the LSP client. =eglot-booster= speeds up the JSON-RPC transport (requires the =emacs-lsp-booster= binary in $PATH).

#+begin_src emacs-lisp
(use-package eglot
  :straight nil
  :hook ((python-mode python-ts-mode
          rust-mode rust-ts-mode
          go-mode go-ts-mode
          yaml-mode yaml-ts-mode
          LaTeX-mode latex-mode
          fortran-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-initiated-edits nil)
  (eglot-send-changes-idle-time 0.5)
  (eglot-extend-to-xref t)
  :config
  ;; Pyright over default Python LSP.
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("pyright-langserver" "--stdio")))
  ;; Rust-analyzer with project clippy on save.
  (setq-default eglot-workspace-configuration
                '(:pyright (:useLibraryCodeForTypes t)
                  :rust-analyzer (:checkOnSave (:command "clippy")
                                  :inlayHints (:lifetimeElisionHints (:enable "skip_trivial")
                                               :closureReturnTypeHints (:enable t))))))

(use-package eglot-booster
  :straight (eglot-booster :host github :repo "jdtsmith/eglot-booster")
  :after eglot
  :config (eglot-booster-mode))

(use-package consult-eglot
  :after (consult eglot))
#+end_src
````

- [ ] **Step 2: Install `emacs-lsp-booster` binary (Mac via homebrew tap)**

```bash
brew tap blahgeek/tap
brew install emacs-lsp-booster
which emacs-lsp-booster
```

Alternative if tap fails: `cargo install emacs-lsp-booster` or download release from `https://github.com/blahgeek/emacs-lsp-booster/releases`.

Expected: `which emacs-lsp-booster` prints a path. If not installed, eglot-booster will silently no-op — eglot still works, just slower.

- [ ] **Step 3: Replace julia LSP config in `*** Julia` (~line 3380)**

Replace the `(use-package lsp-julia ...)` block with:

````org
#+begin_src emacs-lisp
(use-package julia-mode)
;; Julia LSP via eglot. Requires `using LanguageServer; using SymbolServer`
;; in your Julia v1.7 env: ~/.julia/environments/v1.7.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((julia-mode julia-ts-mode)
                 . ("julia"
                    "--startup-file=no"
                    "--history-file=no"
                    "-e" "using LanguageServer; using SymbolServer; runserver()"))))
#+end_src
````

- [ ] **Step 4: Check `.dir-locals.el` files for lsp-mode settings**

```bash
find ~/coding/projects -name .dir-locals.el 2>/dev/null -exec grep -l 'lsp-' {} \;
```

Any matches: edit them by hand later — eglot ignores `lsp-*` vars. Note paths in a TODO comment in init.org if found.

- [ ] **Step 5: Re-tangle, byte-compile, restart Emacs**

Open a Python file in a project that uses pyright. Wait for "Connected!" message in echo area. `M-x eglot-find-typeDefinition` should work. `M-x consult-eglot-symbols` should list project symbols.

- [ ] **Step 6: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: lsp-mode -> eglot + eglot-booster + consult-eglot"
```

---

## Phase 7 — flycheck → flymake (keep flycheck for stan)

### Task 7.1: Move flycheck to stan-only, enable flymake globally

**Files:** Modify `init.org` `*** Flycheck` (~line 2818), `*** Stan` (~line 3291).

- [ ] **Step 1: Replace `*** Flycheck` block**

````org
*** Flymake (general) + Flycheck (stan only)
Flymake is Emacs-native; Eglot wires diagnostics to it automatically. Flycheck is retained *only* for =stan-mode= (no flymake-stan exists).

#+begin_src emacs-lisp
(use-package flymake
  :straight nil
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-no-changes-timeout 1.0))

;; flycheck retained for stan only; loaded by stan-mode hook below.
(use-package flycheck
  :defer t)
#+end_src
````

- [ ] **Step 2: Update Stan section to keep flycheck-stan**

In `*** Stan` (~line 3291), ensure `(use-package flycheck-stan ...)` has:

````org
#+begin_src emacs-lisp
(use-package flycheck-stan
  :after (flycheck stan-mode)
  :hook (stan-mode . (lambda ()
                       (require 'flycheck)
                       (flycheck-mode 1))))
#+end_src
````

(Replace whatever current flycheck-stan setup exists with this.)

- [ ] **Step 3: Drop the legacy `(lsp-prefer-flymake nil)` reference** — already gone with lsp-mode in Phase 6.

- [ ] **Step 4: Re-tangle, byte-compile, restart Emacs**

Open a Python file with an obvious error (e.g., `undefined_name`). Expected: flymake underlines it within ~1s. `M-x flymake-show-buffer-diagnostics` lists it.

Open a `.stan` file with a syntax error. Expected: flycheck (not flymake) flags it.

- [ ] **Step 5: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: flycheck -> flymake (keep flycheck for stan only)"
```

---

## Phase 8 — projectile → project.el + consult-project-extra

### Task 8.1: Replace projectile with project.el integrations

**Files:** Modify `init.org` `** projectile` (~line 3183) and `** ibuffer` (~line 2347).

- [ ] **Step 1: Replace `** projectile` block**

````org
** Projects (project.el)
Built-in =project.el= manages project membership; =consult-project-extra= provides the discoverability projectile had.

#+begin_src emacs-lisp
(use-package project
  :straight nil
  :custom
  (project-vc-extra-root-markers '(".project" "pyproject.toml" "Cargo.toml" "go.mod" "package.json"))
  :config
  (when (file-directory-p "~/coding/projects")
    (dolist (dir (directory-files "~/coding/projects" t "\\`[^.]" t))
      (when (file-directory-p (expand-file-name ".git" dir))
        (project-remember-project (project-current nil dir))))))

(use-package consult-project-extra
  :after consult)
#+end_src
````

(The `dolist` block warm-loads any git repos under `~/coding/projects` into `project--list` so `C-x p p` shows them immediately — equivalent to projectile's search path.)

- [ ] **Step 2: Replace ibuffer-projectile with ibuffer-project**

In `** ibuffer` (~line 2347), replace the `(use-package ibuffer-projectile ...)` block with:

````org
#+begin_src emacs-lisp
(use-package ibuffer-project
  :hook (ibuffer . (lambda ()
                     (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))
                     (unless (eq ibuffer-sorting-mode 'project-file-relative)
                       (ibuffer-do-sort-by-project-file-relative)))))
#+end_src
````

- [ ] **Step 3: Re-tangle, byte-compile, restart Emacs**

`C-x p p` → project switch. `M-x consult-project-extra-find` → fuzzy file picker scoped to project. `M-x ibuffer` → grouped by project.

- [ ] **Step 4: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: projectile -> project.el + consult-project-extra + ibuffer-project"
```

---

## Phase 9 — neotree + treemacs → dirvish (preserve `[f8]`)

### Task 9.1: Drop neotree + treemacs-nerd-icons; rebind `[f8]` to dirvish-side

**Files:** Modify `init.org` `** neotree` (~line 854) and `** dirvish` location.

- [ ] **Step 1: Replace `** neotree` block**

````org
** Sidebar (dirvish-side)
Replaces neotree+treemacs. Same =[f8]= binding preserved.

#+begin_src emacs-lisp
(global-set-key [f8] #'dirvish-side)
#+end_src
````

(The `(use-package neotree ...)` and `(use-package treemacs-nerd-icons ...)` blocks are deleted in this step.)

- [ ] **Step 2: Prune `(doom-themes-neotree-config)` from `*** doom themes`**

In the doom-themes `:config` block (modified in Phase 2), delete `(doom-themes-neotree-config)`.

- [ ] **Step 3: Re-tangle, byte-compile, restart Emacs**

Press `F8`. Expected: dirvish sidebar opens.

- [ ] **Step 4: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: drop neotree+treemacs; [f8] -> dirvish-side"
```

---

## Phase 10 — all-the-icons → nerd-icons

### Task 10.1: Drop all-the-icons, ensure nerd-icons fonts installed

**Files:** Modify `init.org` `** all the icons` (~line 290).

- [ ] **Step 1: Replace `** all the icons` block**

````org
** Icons (nerd-icons only)
All-the-icons is dropped — nerd-icons is its modern, terminal-capable successor and is already wired into completion/dired/ibuffer.

#+begin_src emacs-lisp
;; Ensure the Nerd Font is available; install once on a fresh machine:
;;   M-x nerd-icons-install-fonts
;; (FiraCode Nerd Font is already your default per the Font section.)
#+end_src
````

(`** nerd icons` block stays as-is at ~line 324.)

- [ ] **Step 2: Audit other blocks for `all-the-icons` references**

```bash
grep -n 'all-the-icons' ~/.local/share/chezmoi/dot_config/emacs/init.org
```

Replace each surviving reference (e.g., in `doom-modeline` config) with the `nerd-icons` equivalent. Most likely matches:
- `doom-modeline-icon` / `doom-modeline-major-mode-icon` — already nerd-icons-compatible in current doom-modeline; verify the `:custom` block in `** Doom mode line` doesn't force `all-the-icons`.

If `(setq doom-modeline-icon ...)` is set to anything referencing all-the-icons, change to `'nerd-icons`.

- [ ] **Step 3: Re-tangle, byte-compile, restart Emacs**

Modeline, dired, ibuffer, completion margins should all show nerd-icons glyphs (or nothing — never broken-glyph squares).

- [ ] **Step 4: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: drop all-the-icons (nerd-icons only)"
```

---

## Phase 11 — highlight-indent-guides → indent-bars

### Task 11.1: Swap indent guides

**Files:** Modify `init.org` `*** highlight indent guides` (~line 2948).

- [ ] **Step 1: Replace block**

````org
*** Indent bars
Treesit-aware, native faces; lighter than highlight-indent-guides.

#+begin_src emacs-lisp
(use-package indent-bars
  :straight (indent-bars :host github :repo "jdtsmith/indent-bars")
  :hook ((python-mode python-ts-mode
          yaml-mode yaml-ts-mode
          json-mode json-ts-mode) . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-no-descend-string t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  (indent-bars-color '(highlight :face-bg t :blend 0.2))
  (indent-bars-pattern ".")
  (indent-bars-width-frac 0.15)
  (indent-bars-pad-frac 0.1))
#+end_src
````

(Section header renamed from `*** highlight indent guides` to `*** Indent bars`.)

- [ ] **Step 2: Re-tangle, byte-compile, restart Emacs**

Open a Python file with nested indents. Expected: thin vertical bars at each indent level, blended with theme bg.

- [ ] **Step 3: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: highlight-indent-guides -> indent-bars (treesit-aware)"
```

---

## Phase 12 — which-key (external → built-in)

### Task 12.1: Drop external which-key package

**Files:** Modify `init.org` `** which key` (~line 895).

- [ ] **Step 1: Replace block**

````org
** which key
Built-in since Emacs 30. No package needed.

#+begin_src emacs-lisp
(which-key-mode 1)
(setq which-key-idle-delay 0.3)
#+end_src
````

(Deletes the `(use-package which-key ...)` form, keeps your prior delay setting.)

- [ ] **Step 2: Re-tangle, byte-compile, restart Emacs**

Press `C-x` and wait 0.3s — which-key popup appears as before. No behavior change.

- [ ] **Step 3: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: which-key external -> built-in"
```

---

## Phase 13 — flyspell → jinx

### Task 13.1: Replace flyspell with jinx

**Files:** Modify `init.org` `*** Flyspell` (~line 3084).

- [ ] **Step 1: Install enchant (Mac via homebrew)**

```bash
brew install enchant pkg-config
```

Expected: enchant-2 in `/opt/homebrew/bin/`. Jinx's native module compiles against it.

- [ ] **Step 2: Replace `*** Flyspell` block (rename section)**

````org
*** Jinx (spellcheck)
Enchant-based, JIT, no startup hit. Replaces flyspell.

#+begin_src emacs-lisp
(use-package jinx
  :hook (text-mode . jinx-mode)
  :custom
  (jinx-languages "en_US"))
#+end_src
````

(`flyspell` `:commands` autoloads from old block are dropped; jinx exposes `jinx-correct` etc.)

- [ ] **Step 3: Re-tangle, byte-compile, restart Emacs**

Open a markdown buffer with a typo. Expected: misspelling highlighted; `M-$` (or `M-x jinx-correct`) opens correction prompt via vertico.

If jinx fails to compile native module: `M-x jinx-install` or check `brew --prefix enchant` is on `PKG_CONFIG_PATH`.

- [ ] **Step 4: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: flyspell -> jinx (enchant-based, JIT)"
```

---

## Phase 14 — treesit-auto + ts-mode remapping

### Task 14.1: Add treesit-auto

**Files:** Add new section to `init.org` after `* Tooling` (or wherever LSP lives now).

- [ ] **Step 1: Insert new `** Tree-sitter` section**

````org
** Tree-sitter
=treesit-auto= installs grammars on demand and remaps =foo-mode= → =foo-ts-mode= when a grammar is available.

#+begin_src emacs-lisp
(use-package treesit-auto
  :straight (treesit-auto :host github :repo "renzmann/treesit-auto")
  :custom (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))
#+end_src
````

- [ ] **Step 2: Re-tangle, byte-compile, restart Emacs**

Open a `.py`, `.rs`, `.go`, `.json`, `.yaml`, `.dockerfile` file in turn. First time per language: Emacs prompts to install a grammar — accept. Major mode shown should be `python-ts-mode`, `rust-ts-mode`, etc.

- [ ] **Step 3: Verify eglot still attaches in `*-ts-mode`**

Open a `.py` file → mode = `python-ts-mode` → eglot connects to pyright (`*-ts-mode` was added to the eglot `:hook` in Phase 6). Expected: "Connected!" echo.

- [ ] **Step 4: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: add treesit-auto, remap *-mode -> *-ts-mode"
```

---

## Phase 15 — vertico extensions

### Task 15.1: Add vertico-multiform, vertico-directory, vertico-quick

**Files:** Modify `init.org` `** Vertico` (~line 1624).

- [ ] **Step 1: Extend vertico block**

Replace the `(use-package vertico ...)` block with:

````org
#+begin_src emacs-lisp
(use-package vertico
  :straight (vertico :files (:defaults "extensions/*")
                     :host github :repo "minad/vertico")
  :init (vertico-mode)
  :custom
  (vertico-cycle t)
  (vertico-resize t))

(use-package vertico-directory
  :straight nil
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package vertico-multiform
  :straight nil
  :after vertico
  :init (vertico-multiform-mode)
  :custom
  (vertico-multiform-commands
   '((consult-line buffer)
     (consult-imenu buffer)
     (consult-outline buffer)))
  (vertico-multiform-categories
   '((file grid)
     (consult-grep buffer))))

(use-package vertico-quick
  :straight nil
  :after vertico
  :bind (:map vertico-map
              ("M-q" . vertico-quick-insert)
              ("C-q" . vertico-quick-exit)))
#+end_src
````

(RET/DEL inside vertico-map are vertico's own keys, not global muscle-memory bindings; this is the standard vertico-directory pattern and matches the no-keybinding-changes spirit.)

- [ ] **Step 2: Re-tangle, byte-compile, restart Emacs**

`C-x C-f` → start typing → `DEL` should delete by component (jump up directory). `M-x consult-line` → vertico opens as side-buffer.

- [ ] **Step 3: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: add vertico-multiform/-directory/-quick extensions"
```

---

## Phase 16 — gptel (Claude backend, auth deferred)

### Task 16.1: Add gptel with Claude backend

**Files:** Modify `init.org` `** chatGPT` (~line 4268, currently commented) → rename to `** AI`. Also add `claude_comments/gptel-setup.md`.

- [ ] **Step 1: Replace `** chatGPT` block**

````org
** AI (gptel)
Claude backend declared. Auth deferred — see =claude_comments/gptel-setup.md= for the =~/.authinfo.gpg= setup once a Claude API key is provisioned.

#+begin_src emacs-lisp
(use-package gptel
  :defer t
  :config
  (setq gptel-default-mode 'org-mode)
  (setq gptel-model 'claude-sonnet-4-5
        gptel-backend (gptel-make-anthropic "Claude"
                        :stream t
                        :key (lambda ()
                               (auth-source-pick-first-password
                                :host "api.anthropic.com")))))
#+end_src
````

- [ ] **Step 2: Create gptel setup note**

Create `~/.local/share/chezmoi/dot_config/emacs/claude_comments/gptel-setup.md`:

````markdown
# gptel — Claude auth setup

## Prerequisite

Anthropic enterprise API key (`sk-ant-api03-...`). If your org has key creation disabled in the console, request it from your workspace admin.

## Steps

1. Visit https://console.anthropic.com → API Keys → Create. Save key (`sk-ant-api03-...`).
2. Append to `~/.authinfo.gpg` (encrypted) or `~/.authinfo` (plaintext, less safe):

   ```
   machine api.anthropic.com login apikey password sk-ant-api03-XXXXXXXXXXXXXXXXXXXX
   ```

3. In Emacs: `M-x gptel-send` — first call should now succeed.

## Org-mode usage

Open any `.org` file, write a prompt, `C-c RET` (or `M-x gptel-send`). Response streams into buffer.

## Switching models

`M-x gptel-menu` → change model (claude-opus-4-X / sonnet-4-X / haiku-4-X).
````

- [ ] **Step 3: Re-tangle, byte-compile, restart Emacs**

`M-x gptel` should open a chat buffer (no error). Without an API key, `M-x gptel-send` will error with an auth-source miss — expected.

- [ ] **Step 4: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el \
        dot_config/emacs/claude_comments/gptel-setup.md
git commit -m "emacs: add gptel w/ Claude backend (auth deferred)"
```

---

## Phase 17 — magit-todos

### Task 17.1: Uncomment + configure magit-todos

**Files:** Modify `init.org` `*** magit todos` (~line 3174).

- [ ] **Step 1: Replace block**

````org
*** magit todos
#+begin_src emacs-lisp
(use-package magit-todos
  :after magit
  :config (magit-todos-mode 1))
#+end_src
````

- [ ] **Step 2: Re-tangle, byte-compile, restart Emacs**

`M-x magit-status` in a repo with TODO/FIXME comments. Expected: new `Todos` section in the magit buffer.

- [ ] **Step 3: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: enable magit-todos"
```

---

## Phase 18 — breadcrumb

### Task 18.1: Add breadcrumb

**Files:** Add to `init.org` Tooling section (near eglot block).

- [ ] **Step 1: Insert new subsection**

````org
*** Breadcrumb
Header-line breadcrumb of imenu/treesit/eglot path; replaces lsp-ui-headerline-breadcrumb.

#+begin_src emacs-lisp
(use-package breadcrumb
  :hook ((prog-mode . breadcrumb-local-mode)))
#+end_src
````

- [ ] **Step 2: Re-tangle, byte-compile, restart Emacs**

Open a function-heavy Python file. Header line should show `file > class > method` path that updates as you navigate.

- [ ] **Step 3: Commit**

```bash
git add dot_config/emacs/init.org dot_config/emacs/init.el
git commit -m "emacs: add breadcrumb (header-line code path)"
```

---

## Phase 19 — Final verification

### Task 19.1: Clean byte-compile, restart, smoke test

- [ ] **Step 1: Clean byte-compile from scratch**

```bash
rm -f ~/.local/share/chezmoi/dot_config/emacs/init.elc
rm -f ~/.local/share/chezmoi/dot_config/emacs/early-init.elc
$BYTECOMPILE 2> /tmp/emacs-final-warnings.log
wc -l /tmp/emacs-baseline-warnings.log /tmp/emacs-final-warnings.log
```

Expected: final warning count ≤ baseline. No errors.

- [ ] **Step 2: `chezmoi apply`**

```bash
chezmoi diff
chezmoi apply
```

Inspect diff first; apply.

- [ ] **Step 3: Cold-start Emacs with `--debug-init`**

```bash
emacs --debug-init &
```

Expected: starts to a modus-vivendi frame, no `*Backtrace*` window. `M-x emacs-init-time` prints a time comparable to or faster than baseline.

- [ ] **Step 4: Smoke test checklist**

Verify each of:
- [ ] Theme is `modus-vivendi` (`M-: custom-enabled-themes`)
- [ ] `F8` opens dirvish sidebar
- [ ] `C-x p p` lists projects
- [ ] In a `.py` file: major mode = `python-ts-mode`, eglot connects, flymake flags errors
- [ ] In a `.stan` file: flycheck (not flymake) is active
- [ ] `M-x gptel` opens chat buffer
- [ ] `M-x magit-status` shows magit-todos section
- [ ] `C-x` after 0.3s shows which-key popup
- [ ] Vertico, corfu, marginalia, consult, embark all behave as before
- [ ] All custom keybindings (general-define-key, hydras, ace-window key) work

- [ ] **Step 5: Final commit if any tweaks needed; otherwise stop**

```bash
git status   # should be clean
git log --oneline emacs-pre-modernization-backup..HEAD
```

Expected: ~18 commits since branch start. Push or merge to main per your usual workflow.

---

## Self-Review Notes

**Spec coverage:**
- §1 Theme fix → Phase 2 ✓
- §2 Replace (9 swaps) → Phases 5–13 ✓
- §2 Drop (themes, sublimity, commented, org-bullets, rubocop, :ensure t) → Phase 3 ✓
- §2 Add (treesit-auto, cape, corfu-popupinfo+history, vertico-*, consult-project-extra, consult-eglot, eglot-booster, gptel, magit-todos, jinx, breadcrumb, indent-bars) → Phases 5, 6, 11, 13, 14, 15, 16, 17, 18 ✓
- §3 Section reorg + Keyboard-to-end → Phase 4 ✓
- §3 early-init.el → Phase 1 ✓
- §3 Strip :ensure t → Phase 3.3 ✓
- §3 Move custom-file → Phase 4.1 step 3 ✓
- §3 user-emacs-directory → early-init → Phase 1.1 step 7 ✓
- §4 Validation → byte-compile in every phase + final cold-start ✓
- §5 Edit/deploy flow → chezmoi source edits + `chezmoi apply` ✓

**No placeholders.** All code blocks contain literal elisp/shell to paste.

**Keybindings preserved:** Only `[f8]` (neotree → dirvish-side) and internal `corfu-map`/`vertico-map` keys touched. No global muscle-memory bindings changed.

**Risk hotspots:**
- Phase 6 (eglot) — most invasive. Pyright/julia LSP semantics differ subtly from lsp-mode. If anything breaks, `git revert` Phase 6's commit.
- Phase 1 (early-init) — wrong path here breaks startup completely. Backup branch from Phase 0 protects this.
- Phase 14 (treesit-auto) — first-time grammar prompts may surprise; choose "yes" each.
