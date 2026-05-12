# Emacs Configuration Modernization — Design

**Date:** 2026-05-12
**Author:** brainstormed w/ Claude
**Target:** `~/.local/share/chezmoi/dot_config/emacs/init.org` (tangles to `init.el`, deployed via chezmoi)
**Constraints:** Emacs 30.x. Aggressive modernization. **Keybindings untouched.**

---

## 1. Theme load fix (headline bug)

**Symptom:** Intended default theme does not load on startup.

**Root causes (init.org:4354–4357):**

1. Final block double-wraps `after-init-hook`:
   ```elisp
   (add-hook 'after-init-hook
             (lambda () (add-hook 'after-init-hook
                                  (lambda () (load-theme 'solarized-light)))))
   ```
   Outer fires during `after-init`, *adds* inner — but iteration over the hook is already done. Inner never executes.
2. `solarized-theme` not installed via straight.
3. `modus-themes :config` eagerly calls `(load-theme 'modus-vivendi t)` — accidental success.
4. `doom-themes :init` calls `doom-themes-visual-bell-config` etc. before package load → silent errors.

**Fix:**
- Delete broken nested-hook block.
- Remove `(load-theme 'modus-vivendi t)` from `modus-themes :config`.
- Add single explicit terminal section that loads `modus-vivendi` once, daemon-aware:
  ```elisp
  (defun jmb/apply-theme (&optional frame)
    (with-selected-frame (or frame (selected-frame))
      (load-theme 'modus-vivendi t)))
  (if (daemonp)
      (add-hook 'after-make-frame-functions #'jmb/apply-theme)
    (jmb/apply-theme))
  ```
- Move `doom-themes` config calls from `:init` → `:config`.

---

## 2. Plugin modernization

### Replace

| Current | Modern | Notes |
|---|---|---|
| lsp-mode + lsp-ui + lsp-pyright + lsp-julia | **eglot** (built-in) + **eglot-booster** + **consult-eglot** | Pyright/julia LS configured via `eglot-server-programs`. |
| flycheck (most uses) | **flymake** (built-in) | flycheck + flycheck-stan **kept only for stan-mode** (no flymake-stan exists). Everywhere else: flymake. |
| company | **corfu** (already on) + **cape** | corfu already installed; drop company. |
| projectile + ibuffer-projectile | **project.el** (built-in) + **consult-project-extra** + **ibuffer-project** | |
| neotree + treemacs + treemacs-nerd-icons | **dirvish only** | Dirvish already configured. |
| all-the-icons + all-the-icons-* | **nerd-icons** suite | Terminal-compatible. nerd-icons-completion/dired/ibuffer already on. |
| org-bullets | **org-superstar** | Already installed; pick one. |
| highlight-indent-guides | **indent-bars** | Treesit-aware, native faces. |
| which-key (external) | **which-key (built-in)** | Drop use-package, just `(which-key-mode 1)`. |

### Drop outright

- Dead theme `use-package` blocks: kaolin-themes, green-is-the-new-black-theme, green-phosphor-theme, vscode-dark-plus-theme, blueballs-dark-theme, brilliance-dull-theme, nano-theme, writerish-dark-theme, omni-theme, the-matrix-theme.
- sublimity (replaced by `pixel-scroll-precision-mode` built-in).
- org-bullets.
- All commented-out use-package blocks (origami, hideshow, mu4e, slack, popper, prescient, ace-jump, beacon, gptel placeholder, chatgpt-shell, etc.).
- rubocop (no Ruby).
- Redundant `:ensure t` on every block (~80 occurrences).

### Add

- **treesit-auto** — auto-install grammars + remap legacy modes for python, rust, go, json, yaml, dockerfile, js, ts, c, cpp, bash, toml, html, css.
- **cape** — corfu backends (file, dabbrev, keyword, elisp).
- **corfu-popupinfo** + **corfu-history** — docs-on-hover + frecency.
- **vertico-multiform** + **vertico-directory** + **vertico-quick** — first-party vertico extensions.
- **consult-project-extra** + **consult-eglot**.
- **eglot-booster** — uses emacs-lsp-booster binary, 2–5× faster transport.
- **gptel** — Claude + OpenAI + Ollama. Install + declare Claude backend; **auth deferred**: user is on enterprise plan with org ID but no confirmed API key. README note added in `claude_comments/gptel-setup.md` explaining how to add `~/.authinfo.gpg` entry for `api.anthropic.com` once a `sk-ant-...` key is provisioned. Package loads cleanly; first call errors with auth-source miss until then.
- **magit-todos** — uncomment + configure.
- **jinx** — replaces flyspell. Enchant-based, JIT, no startup hit.
- **breadcrumb** — header-line breadcrumbs (replaces lsp-ui breadcrumbs).
- **indent-bars** (see Replace).

### Keep

vertico, orderless, marginalia, consult, embark, corfu, kind-icon, magit, dirvish, doom-modeline, pulsar, avy, ace-window, yasnippet, apheleia, smartparens, multiple-cursors, hydra, general, exec-path-from-shell, no-littering, chezmoi.el, telega, elfeed+elfeed-org+elfeed-score, vterm, eshell extras, centaur-tabs.

---

## 3. Structural cleanup

### Section reorganization (top-level headings, in load order)

1. Startup
2. Package management
3. System
4. UI Foundation (font, icons, modeline, line numbers, transparency)
5. Theme (modus/ef/doom only; **no** load-theme calls inside)
6. Editing
7. Completion
8. Window/Buffer Management
9. Project & VCS
10. Languages
11. Tooling (eglot, flymake, apheleia, treesit-auto, breadcrumb, indent-bars, jinx, yasnippet)
12. Org
13. Eshell / vterm
14. Writing & Focus
15. Apps (telega, elfeed, gptel, csv-mode, regex-tool, erc)
16. **Keyboard** (untouched contents, moved here last)
17. **Load primary theme** (terminal)

Moving Keyboard to last fixes a latent bug: `general-define-key` currently fires before some target functions are autoloaded.

### Mechanical cleanups

- Strip `:ensure t` everywhere (redundant under `straight-use-package-by-default t`).
- Strip `:diminish` calls where `minions` already hides the modeline lighter.
- Quote consistency: `'foo` not `(quote foo)`.
- Delete all commented-out use-package blocks.
- Consolidate frame-alpha/frame-alist setup into one block.
- Move `(load custom-file t)` to immediately before terminal theme load.
- **New: `early-init.el`** — created via per-block `:tangle ~/.local/share/chezmoi/dot_config/emacs/early-init.el`. Contents: GC threshold, frame params (no menu/tool/scroll bar), native-comp warnings, `(setq package-enable-at-startup nil)`.

### Risks

- Removing dead themes breaks `M-x load-theme RET <removed> RET`. Accepted.
- lsp→eglot: `lsp-*` entries in `.dir-locals.el` silently stop applying. Pre-check via grep before tangle.
- flycheck→flymake: flycheck kept only for stan-mode buffers (flycheck-stan retained, no flymake-stan exists). Everywhere else flymake.
- early-init.el creation changes tangle output to two files. Per-block `:tangle` keeps blast radius small.

### Out of scope (per user instruction)

**No keybinding changes.** No edits to: `** ESC Cancels`, `** which key` (bindings), `** HYDRA`, `** General Key maps`, `** easy-kill`, any `bind-key` / `general-define-key` / `define-key` / `:bind` / `global-set-key`. Modernized plugins inherit the keys their predecessor used (e.g., consult-project-extra bound to whatever key projectile-* used, if any).

---

## 4. Validation

After tangle:

```bash
emacs -Q --batch \
  --eval "(require 'package)" \
  -f batch-byte-compile \
  ~/.local/share/chezmoi/dot_config/emacs/init.el
emacs -Q --batch \
  -f batch-byte-compile \
  ~/.local/share/chezmoi/dot_config/emacs/early-init.el
```

Then `chezmoi apply` to deploy. User restarts Emacs to verify modus-vivendi loads.

---

## 5. Edit/deploy flow

1. Edit `~/.local/share/chezmoi/dot_config/emacs/init.org` (chezmoi source).
2. Org-tangle → produces `init.el` + new `early-init.el` in same dir.
3. Byte-compile check (above).
4. `chezmoi apply` → deploys to `~/.config/emacs/`.
5. Restart Emacs.

---

## Resolved

- Flycheck: kept for stan-mode only; flymake everywhere else.
- gptel: install + Claude backend declared; auth deferred to user, setup note in `claude_comments/gptel-setup.md`.
- centaur-tabs, smartparens: kept as-is, not in scope.
- Forge: **skipped.** Magit kept as-is.
- `user-emacs-directory` override: **move to early-init.el**. Current placement (inside no-littering, mid-init) is a latent bug — straight.el and native-comp paths are already bound before the override fires. early-init.el is the correct boot phase for this. `no-littering` keeps the var consumption in main init.
