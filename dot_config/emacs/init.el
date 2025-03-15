(setq jmb/is-guix-system (and (eq system-type 'gnu/linux)
                              (require 'f)
                              (string-equal (f-read "/etc/issue")
                                            "\nThis is the GNU system.  Welcome.\n")))

(setq jmb/is-macos-system (eq system-type 'darwin))

;; Disable package.el in favor of straight.el
(setq package-enable-at-startup nil)

  ;; Temporarily set a very high GC threshold for startup
    (setq gc-cons-threshold most-positive-fixnum
          gc-cons-percentage 0.6)

    ;; Reset GC threshold to reasonable values after startup
    (add-hook 'emacs-startup-hook
              (lambda ()
                (setq gc-cons-threshold (* 16 1000 1000) ; 16MB
                      gc-cons-percentage 0.1)))

    ;; Profile emacs startup
    (add-hook 'emacs-startup-hook
              (lambda ()
                (message "*** Emacs loaded in %s with %d garbage collections."
                         (format "%.2f seconds"
                                 (float-time
                                  (time-subtract after-init-time before-init-time)))
                         gcs-done)))

    ;; Increase amount of data which Emacs reads from processes in a single chunk
    (setq read-process-output-max (* 1024 1024)) ;; 1mb

    ;; Speed up font rendering (particularly important for daemon mode)
    (setq inhibit-compacting-font-caches t)

;; Silence compiler warnings as they can be pretty disruptive
(setq comp-async-report-warnings-errors nil)
(setq native-comp-async-report-warnings-errors nil)

;; Set native-comp cache directory
(when (fboundp 'native-comp-available-p)
  (when (native-comp-available-p)
    (setq native-comp-deferred-compilation t)
    (setq native-comp-async-jobs-number 4) ;; Set to number of cores - 1
    (setq native-comp-async-report-warnings-errors 'silent)))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

(setq straight-use-package-by-default t)
(setq straight-check-for-modifications '(check-on-save find-when-checking))

;; Load the helper package for commands like `straight-x-clean-unused-repos'
(require 'straight-x)

(use-package chezmoi
  :ensure t
  :after magit
  :defer t
  :config
  (add-hook 'org-babel-post-tangle-hook #'chezmoi-write))

(use-package bug-hunter
  :ensure t
  :defer t)

;; Better confirmation UX
(fset 'yes-or-no-p 'y-or-n-p)

;; Disable startup screen and message
(setq inhibit-splash-screen t
      inhibit-startup-message t)

;; Enable visual bell
(setq visible-bell t)

;; Set fringe mode
(set-fringe-mode 5)

;; Disable various UI elements
(dolist (mode
         '(tool-bar-mode                ; No toolbars
           scroll-bar-mode              ; No scroll bars
           menu-bar-mode                ; No menu bar
           tooltip-mode))               ; No tooltips
  (when (fboundp mode) (funcall mode -1)))

(defun jmb/set-transparency (value)
  "Set frame transparency to VALUE (0-100)."
  (interactive "nTransparency Value (0-100): ")
  (set-frame-parameter (selected-frame) 'alpha (cons value value))
  (add-to-list 'default-frame-alist (cons 'alpha (cons value value))))

;; Set initial transparency to 85%
(jmb/set-transparency 85)

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(use-package no-littering
  :ensure t
  :demand t)

;; Keep customization settings in a temporary file
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

;; Centralize backup files
(use-package files
  :ensure nil
  :straight nil
  :config
  (setq backup-directory-alist
        `(("." . ,(expand-file-name "backups" user-emacs-directory)))
        make-backup-files t
        vc-make-backup-files t
        backup-by-copying t
        version-control t
        delete-old-versions t
        kept-new-versions 6
        kept-old-versions 2
        auto-save-default t
        auto-save-timeout 20
        auto-save-interval 200)

  ;; Put auto-save files in separate directory
  (setq auto-save-file-name-transforms
        `((".*" ,(expand-file-name "auto-save/" user-emacs-directory) t))))

(defun tidy ()
  "Indent, untabify and unwhitespacify current buffer, or region if active."
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (point-min)))
        (end (if (region-active-p) (region-end) (point-max))))
    (indent-region beg end)
    (whitespace-cleanup)
    (untabify beg (if (< end (point-max)) end (point-max)))))

(use-package ws-butler
  :ensure t
  :diminish ws-butler-mode
  :hook ((text-mode prog-mode) . ws-butler-mode)
  :config
  (setq ws-butler-keep-whitespace-before-point nil))

(defun kill-this-buffer-unless-scratch ()
  "Works like `kill-this-buffer' unless the current buffer is the
*scratch* buffer. In which case the buffer content is deleted and
the buffer is buried."
  (interactive)
  (if (not (string= (buffer-name) "*scratch*"))
      (kill-this-buffer)
    (delete-region (point-min) (point-max))
    (switch-to-buffer (other-buffer))
    (bury-buffer "*scratch*")))

(when (eq system-type 'darwin)
  (defun copy-from-osx ()
    (shell-command-to-string "pbpaste"))

  (defun paste-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))

  (setq interprogram-cut-function 'paste-to-osx)
  (setq interprogram-paste-function 'copy-from-osx)

  ;; Set keys for Apple keyboard
  (setq mac-command-modifier 'super) ; make cmd key do Meta
  (setq ns-function-modifier 'hyper)  ; make Fn key do Hyper

  ;; Enable emoji input on macOS
  (set-fontset-font t 'symbol (font-spec :family "Apple Color Emoji") nil 'prepend))

(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)

(setq large-file-warning-threshold (* 25 1024 1024)) ; 25MB
(setq vc-follow-symlinks t)
(setq ad-redefinition-action 'accept)
(setq ring-bell-function 'ignore)

;; Better scrolling behavior
(setq scroll-conservatively 101
      scroll-margin 2
      scroll-preserve-screen-position t
      auto-window-vscroll nil)

;; Minimap using sublimity for those Sublime Text vibes
(use-package sublimity
  :ensure t
  :defer 2
  :commands (sublimity-mode)
  :config
  (require 'sublimity-scroll)
  (setq sublimity-scroll-weight 10
        sublimity-scroll-drift-length 20)
  :hook (after-init . sublimity-mode))

(use-package s
  :ensure t
  :defer t)

(use-package all-the-icons
  :if (display-graphic-p)
  :ensure t
  :defer t
  :commands (all-the-icons-install-fonts)
  :init
  (unless (find-font (font-spec :name "all-the-icons"))
    (when (window-system)
      (let ((inhibit-message t))
        (message "all-the-icons fonts not found, installing...")
        (all-the-icons-install-fonts t)))))

(use-package nerd-icons
  :ensure t
  :defer t)

;; Revert Dired and other buffers
(setq global-auto-revert-non-file-buffers t)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

;; Add autosave-on-focus-change
(defun save-all-buffers-silently ()
  "Save all modified buffers without prompting."
  (save-some-buffers t))

(add-hook 'focus-out-hook #'save-all-buffers-silently)

;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

;; Speed up tramp connections
(setq remote-file-name-inhibit-cache nil
      tramp-verbose 1
      tramp-completion-reread-directory-timeout nil)

;; Create a central theme management system
(defvar jmb/current-theme nil
  "The current theme being used.")

(defvar jmb/preferred-themes
  '(doom-nord modus-vivendi ef-winter doom-dracula doom-palenight)
  "List of preferred themes to cycle through.")

(defun jmb/load-theme (theme)
  "Load the THEME safely, disabling other themes first."
  (interactive
   (list (completing-read "Load theme: "
                         (mapcar #'symbol-name
                                 (custom-available-themes)))))

  (unless (symbolp theme)
    (setq theme (intern theme)))

  ;; Disable all enabled themes
  (mapc #'disable-theme custom-enabled-themes)

  ;; Load the new theme
  (when theme
    (load-theme theme t)
    (setq jmb/current-theme theme)
    (preserve-font))

  (message "Loaded theme: %s" theme))

(defun jmb/cycle-theme ()
  "Cycle through the list of preferred themes."
  (interactive)
  (let* ((current-pos (cl-position jmb/current-theme jmb/preferred-themes))
         (next-pos (if current-pos
                      (mod (1+ current-pos) (length jmb/preferred-themes))
                    0))
         (next-theme (nth next-pos jmb/preferred-themes)))
    (jmb/load-theme next-theme)))

;; Bind theme cycling to F9
(global-set-key [f9] 'jmb/cycle-theme)

(use-package doom-themes
  :ensure t
  :defer t
  :init
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config)
  (doom-themes-neotree-config))

;; Install a selection of excellent themes
      (use-package kaolin-themes :ensure t :defer t)
      (use-package ef-themes :ensure t :defer t)
      (use-package modus-themes :ensure t :defer t)
      (use-package catppuccin-theme :ensure t :defer t)
      (use-package nord-theme :ensure t :defer t)


      ;; Install GitHub themes
;; Install GitHub themes
(use-package catppuccin-theme
  :ensure t
  :defer t)

(use-package modus-themes
  :ensure t
  :init
  ;; Add all your customizations prior to loading the themes
  (setq modus-themes-mode-line '(accented borderless)
        modus-themes-bold-constructs t
        modus-themes-italic-constructs t
        modus-themes-fringes 'subtle
        modus-themes-tabs-accented t
        modus-themes-syntax '(faint)
        modus-themes-paren-match '(bold intense)
        modus-themes-prompts '(bold intense)
        modus-themes-completions (quote ((matches . (extrabold intense background))
                                         (selection . (semibold accented intense))
                                         (popup . (accented))))

        modus-themes-org-blocks nil;'tinted-background
        modus-themes-scale-headings t
        modus-themes-region '(bg-only)
        modus-themes-headings
        '((1 . (rainbow  1.4))
          (2 . (rainbow  1.3))
          (3 . (rainbow bold 1.2))
          (t . (semilight 1.1)))))

(use-package display-line-numbers
  :ensure nil
  :straight nil
  :hook ((prog-mode text-mode) . display-line-numbers-mode)
  :custom
  (display-line-numbers-width 3)
  (display-line-numbers-widen t)
  :config
  (defcustom display-line-numbers-exempt-modes
    '(vterm-mode eshell-mode shell-mode term-mode org-mode ansi-term-mode pdf-view-mode)
    "Major modes on which to disable line numbers."
    :group 'display-line-numbers
    :type 'list
    :version "green")

  (defun display-line-numbers--turn-on ()
    "Turn on line numbers except for exempt modes."
    (unless (or (minibufferp)
                (member major-mode display-line-numbers-exempt-modes))
      (display-line-numbers-mode))))

;; Enable column numbers globally
(column-number-mode)

;; Improved font setup function
(defun jmb/set-font-faces ()
  "Setup fonts for the current frame."
  (interactive)
  (when (display-graphic-p)
    ;; Main font
    (set-face-attribute 'default nil
                        :family "FiraCode Nerd Font Mono"
                        :height 130
                        :weight 'normal)

    ;; Set the fixed pitch face
    (set-face-attribute 'fixed-pitch nil
                        :family "FiraCode Nerd Font Mono"
                        :height 130
                        :weight 'normal)

    ;; Set the variable pitch face
    (set-face-attribute 'variable-pitch nil
                        :family "BlexMono Nerd Font"
                        :height 130
                        :weight 'normal)

    ;; Configure org-mode specific fonts
    (with-eval-after-load 'org
      (set-face-attribute 'org-document-title nil
                          :family "BlexMono Nerd Font"
                          :weight 'bold
                          :height 1.3)
      (dolist (face '((org-level-1 . 1.5)
                      (org-level-2 . 1.1)
                      (org-level-3 . 1.05)
                      (org-level-4 . 1.0)
                      (org-level-5 . 1.1)
                      (org-level-6 . 1.1)
                      (org-level-7 . 1.1)
                      (org-level-8 . 1.1)))
        (set-face-attribute (car face) nil
                            :family "BlexMono Nerd Font"
                            :weight 'medium
                            :height (cdr face))))))

;; Run function now for non-daemon Emacs
(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame
                  (jmb/set-font-faces))))
  (jmb/set-font-faces))

(defun preserve-font (&rest args)
  "Preserve font settings after theme changes."
  (jmb/set-font-faces)

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (with-eval-after-load 'org
    (dolist (face '(org-block
                   org-table
                   org-formula
                   org-code
                   org-indent
                   org-verbatim
                   org-special-keyword
                   org-meta-line
                   org-checkbox))
      (set-face-attribute face nil :inherit '(fixed-pitch)))))

;; Apply font preservation after theme changes
(advice-add 'load-theme :after 'preserve-font)

(provide 'advice)

(use-package emojify
  :ensure t
  :defer 2
  :config
  (when (member "Noto Color Emoji" (font-family-list))
    (set-fontset-font t 'symbol (font-spec :family "Noto Color Emoji") nil 'prepend))
  (setq emojify-display-style 'unicode
        emojify-emoji-styles '(unicode)
        emojify-prog-contexts 'comments)
  :hook
  (after-init . global-emojify-mode))

(setq display-time-format "%l:%M %p %b %y"
      display-time-default-load-average nil)

(use-package diminish
  :ensure t
  :demand t
  :config
  (diminish 'rainbow-mode)
  (diminish 'auto-fill-mode)
  (diminish 'abbrev-mode)
  (diminish 'auto-revert-mode)
  (diminish 'yas-minor-mode)
  (diminish 'yas-global-mode)
  (diminish 'which-key-mode)
  (diminish 'eldoc-mode)
  (diminish 'subword-mode)
  (diminish 'global-eldoc-mode)
  (diminish 'global-font-lock-mode)
  (diminish 'highlight-indent-guides-mode)
  (diminish 'flyspell-mode)
  (diminish 'flycheck-mode)
  (diminish 'font-lock-mode))

;; Modeline improvements: minions for cleaner mode line
(use-package minions
  :ensure t
  :defer 1
  :config
  (setq minions-mode-line-lighter "✦")
  (setq minions-prominent-modes '(flymake-mode flycheck-mode))
  :hook (doom-modeline-mode . minions-mode))

;; Improved doom-modeline configuration
(use-package doom-modeline
  :ensure t
  :defer 0.5
  :init (doom-modeline-mode 1)
  :custom-face
  (mode-line ((t (:height 0.85))))
  (mode-line-inactive ((t (:height 0.85))))
  :custom
  (doom-modeline-height 15)
  (doom-modeline-bar-width 6)
  (doom-modeline-lsp t)
  (doom-modeline-buffer-file-name-style 'truncate-except-project)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-persp-name nil)
  (doom-modeline-minor-modes nil)
  (doom-modeline-enable-word-count nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-checker-simple-format nil)
  (doom-modeline-github nil) ; Disable GitHub integration for performance
  (doom-modeline-env-version nil) ; Disable environment version for performance
  (doom-modeline-env-enable-python t))

(use-package pulsar
  :ensure t
  :defer t
  :init (pulsar-global-mode)
  :config
  (setq pulsar-face 'pulsar-magenta
        pulsar-delay 0.055)
  :hook
  (consult-after-jump . pulsar-recenter-top)
  (consult-after-jump . pulsar-reveal-entry))

(use-package rainbow-mode
  :ensure t
  :diminish rainbow-mode
  :hook (prog-mode . rainbow-mode))

(use-package svg-lib
  :ensure t
  :defer t)

;; File tree explorer
(use-package neotree
  :ensure t
  :defer t
  :commands (neotree-toggle)
  :bind ([f8] . neotree-toggle)
  :config
  (setq neo-theme (if (display-graphic-p) 'icons 'arrow)))

;; Nerd icons for treemacs
(use-package treemacs-nerd-icons
  :ensure t
  :after treemacs
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package solaire-mode
  :ensure t
  :defer 1
  :hook
  (after-init . solaire-global-mode))

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(use-package which-key
  :ensure t
  :diminish which-key-mode
  :defer 1
  :config
  (setq which-key-idle-delay 0.5
        which-key-idle-secondary-delay 0.05
        which-key-sort-order 'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6)
  :init
  (which-key-mode))

(use-package hydra
  :ensure t
  :defer t)

(use-package major-mode-hydra
  :ensure t
  :after (all-the-icons hydra)
  :defer t
  :config
  (require 'all-the-icons))

;; Define a more modern approach to Hydra with transient
(use-package transient
  :ensure t
  :defer t)

(use-package crux
  :ensure t
  :defer t
  :bind (("C-a" . crux-move-beginning-of-line)
         ("C-k" . crux-smart-kill-line)
         ("C-c d" . crux-duplicate-current-line-or-region)
         ("C-c M-d" . crux-duplicate-and-comment-current-line-or-region)))

;; Modern keybinding framework
(use-package general
  :ensure t
  :config
  (general-define-key
   "C-M-y" 'consult-yank-from-kill-ring
   "M-y" 'consult-yank-pop
   "M-g M-g" 'consult-goto-line
   "M-s" 'isearch-forward
   "C-<backspace>" 'crux-kill-line-backwards
   [remap move-beginning-of-line] 'crux-move-beginning-of-line
   [remap kill-whole-line] 'crux-kill-whole-line
   [(shift return)] 'crux-smart-open-line
   "C-," 'hydra-mc/body
   "C-<tab>" 'jmb/tab-move/body
   "M-j" (lambda () (interactive) (join-line -1))
   "C-z" 'avy-goto-char-timer)

  ;; Cc
  (general-define-key
   :prefix "C-c"
   "]" 'hydra-smartparens/body
   "l" 'org-store-link
   "s" 'ispell-word
   "g" 'consult-git-grep
   "i" (lambda () (interactive) (chezmoi-find "~/.config/emacs/init.org"))
   "<SPC>" (lambda () (interactive) (chezmoi-find "~/.config/zsh/.zshrc"))
   "t" 'consult-theme
   "<up>" 'windmove-up
   "<down>" 'windmove-down
   "<left>" 'windmove-left
   "<right>" 'windmove-right)

  ;; Cx
  (general-define-key
   :prefix "C-x"
   "b" 'consult-buffer
   "m" 'magit-status
   "a" 'ace-jump-mode
   "C-b" 'ibuffer
   "k" 'kill-this-buffer-unless-scratch
   "w" 'elfeed
   "'" 'hydra-window/body))

(use-package easy-kill
  :ensure t
  :bind (([remap kill-ring-save] . easy-kill)
         ([remap mark-sexp] . easy-mark))
  :config
  (with-eval-after-load 'easy-kill
    ;; Add custom menu items
    (add-to-list 'easy-kill-alist '(?w word " ") t)
    (add-to-list 'easy-kill-alist '(?s symbol "\\_<" "\\_>") t)))

;; Modern eshell configuration
(use-package eshell
  :ensure nil
  :straight nil
  :defer t
  :init
  ;; Create eshell directory if it doesn't exist
  (make-directory (expand-file-name "eshell" user-emacs-directory) t)
  :hook
  (eshell-mode . (lambda ()
                   (setq-local completion-in-region-function 'consult-completion-in-region))))

;; Better directory navigation in eshell
(use-package eshell-z
  :ensure t
  :after eshell
  :hook
  ((eshell-mode . (lambda () (require 'eshell-z)))
   (eshell-z-change-dir . (lambda () (eshell/pushd (eshell/pwd))))))

;; Fix PATH across various platforms
(use-package exec-path-from-shell
  :ensure t
  :if (or (memq window-system '(mac ns x))
          (daemonp))
  :init
  (setq exec-path-from-shell-check-startup-files nil)
  :config
  (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "GPG_AGENT_INFO"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

;; Convenience key for eshell
(global-set-key [f5] 'eshell)

(with-eval-after-load 'esh-opt
  (setq eshell-destroy-buffer-when-process-dies t)
  (setq eshell-visual-commands '("htop" "zsh" "vim" "nvim" "less" "more" "bat" "git log" "tail")))

(use-package eshell-syntax-highlighting
  :ensure t
  :after esh-mode
  :config
  (eshell-syntax-highlighting-global-mode +1))

(use-package esh-autosuggest
  :ensure t
  :after eshell
  :hook (eshell-mode . esh-autosuggest-mode)
  :config
  (setq esh-autosuggest-delay 0.25)
  (set-face-foreground 'company-preview-common "#4b5668")
  (set-face-background 'company-preview nil))

(use-package vterm
  :ensure t
  :commands vterm
  :bind (("C-c t" . vterm))
  :custom
  (vterm-max-scrollback 10000)
  (vterm-always-compile-module t) ; Improve load performance
  (vterm-kill-buffer-on-exit t))

(use-package savehist
  :ensure nil
  :straight nil
  :init
  (setq savehist-file (expand-file-name "savehist" user-emacs-directory)
        history-length 1000
        history-delete-duplicates t
        savehist-save-minibuffer-history t)
  :config
  (savehist-mode 1))

;; Recent files
(use-package recentf
  :ensure nil
  :straight nil
  :init
  (setq recentf-max-saved-items 200
        recentf-max-menu-items 25
        recentf-auto-cleanup 'never)
  :config
  (recentf-mode 1))

(defun dw/minibuffer-backward-kill (arg)
  "When minibuffer is completing a file name delete up to parent
folder, otherwise delete a word"
  (interactive "p")
  (if minibuffer-completing-file-name
      ;; Borrowed from https://github.com/raxod502/selectrum/issues/498#issuecomment-803283608
      (if (string-match-p "/." (minibuffer-contents))
          (zap-up-to-char (- arg) ?/)
        (delete-minibuffer-contents))
    (backward-kill-word arg)))

(use-package vertico
  :ensure t
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)
              ("C-f" . vertico-exit)
              :map minibuffer-local-map
              ("M-h" . dw/minibuffer-backward-kill))
  :custom
  (vertico-cycle t)
  (vertico-count 15)
  (vertico-resize t)
  :custom-face
  (vertico-current ((t (:background "#3a3f5a" :foreground "white"))))
  :init
  (vertico-mode))

;; Modern completion with corfu
(use-package corfu
  :ensure t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.2)
  (corfu-separator ?\s)
  (corfu-quit-at-boundary 'separator)
  (corfu-preview-current 'insert)
  :bind (:map corfu-map
              ("C-j" . corfu-next)
              ("C-k" . corfu-previous)
              ("C-f" . corfu-insert))
  :init
  (global-corfu-mode))

;; Add icons to completions
(use-package kind-icon
  :ensure t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default)
  (kind-icon-blend-background nil)
  (kind-icon-blend-frac 0.08)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;; Enable Corfu completion in terminal
(use-package corfu-terminal
  :ensure t
  :after corfu
  :unless (display-graphic-p)
  :config
  (corfu-terminal-mode +1))

;; Fallback to company-mode in some special modes
(use-package company
  :ensure t
  :after corfu
  :hook (org-mode . company-mode)  ; Org-mode still works better with company-mode
  :bind (:map company-active-map
              ("C-n" . company-select-next)
              ("C-p" . company-select-previous))
  :config
  (setq company-idle-delay 0.2)
  (setq company-tooltip-limit 10))

(use-package orderless
  :ensure t
  :demand t
  :custom
  (completion-styles '(orderless basic partial-completion))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(defun dw/get-project-root ()
  "Get project root directory using projectile."
  (when (fboundp 'projectile-project-root)
    (projectile-project-root)))

(use-package consult
  :ensure t
  :demand t
  :bind (("C-s" . consult-line)
         ("C-M-l" . consult-imenu)
         ("C-c b" . consult-bookmark)
         ("C-c f" . consult-find)
         ("C-c r" . consult-ripgrep)
         :map minibuffer-local-map
         ("C-r" . consult-history))
  :custom
  (consult-project-root-function #'dw/get-project-root)
  (consult-narrowing-key "<")
  (consult-line-numbers-widen t)
  (consult-line-start-from-top nil)
  (completion-in-region-function #'consult-completion-in-region)
  :config
  ;; Improve performance by using asynchronous candidates search
  (setq consult-async-min-input 3
        consult-async-refresh-delay 0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1))

(use-package consult-dir
  :ensure t
  :bind (("C-x C-d" . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file))
  :config
  (setq consult-dir-project-list-function #'consult-dir-projectile-dirs))

(use-package marginalia
  :ensure t
  :after vertico
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light t))
  :init
  (marginalia-mode))

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
  :config
  (nerd-icons-completion-mode))

(use-package embark
  :ensure t
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         :map minibuffer-local-map
         ("C-." . embark-act))
  :config
  (setq embark-indicators
        '(embark-which-key-indicator
          embark-highlight-indicator
          embark-isearch-highlight-indicator))
  (setq embark-action-indicator
        (lambda (map _target)
          (which-key--show-keymap "Embark" map nil nil 'no-paging)
          #'which-key--hide-popup-ignore-command)
        embark-become-indicator embark-action-indicator))

;; Make consult commands integrate with embark
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window))
  :custom
  (aw-scope 'frame)
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (aw-minibuffer-flag t)
  :config
  (ace-window-display-mode 1))

(use-package winner
  :ensure nil
  :straight nil
  :defer 1
  :init
  (winner-mode 1))

(defun dw/org-mode-visual-fill ()
  "Set up visual fill for org-mode."
  (setq visual-fill-column-width 110
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :ensure t
  :defer t
  :hook (org-mode . dw/org-mode-visual-fill))

(use-package avy
  :ensure t
  :commands (avy-goto-word-1 avy-goto-char-2 avy-goto-char-timer)
  :bind ("C-z" . avy-goto-char-timer)
  :config
  (setq avy-timeout-seconds 0.3)
  (setq avy-background t))

(use-package centaur-tabs
  :ensure t
  :demand t
  :config
  (centaur-tabs-mode t)
  (centaur-tabs-headline-match)
  (setq centaur-tabs-style "wave")
  (setq centaur-tabs-height 32)
  (setq centaur-tabs-set-modified-marker t)
  (setq centaur-tabs-set-icons t)
  (setq centaur-tabs-set-bar 'under)
  (setq centaur-tabs-cycle-scope 'tabs)
  (centaur-tabs-enable-buffer-reordering)
  (setq centaur-tabs-adjust-buffer-order 'left)
  (centaur-tabs-group-by-projectile-project)
  :hook
  (dashboard-mode . centaur-tabs-local-mode)
  (term-mode . centaur-tabs-local-mode)
  (calendar-mode . centaur-tabs-local-mode)
  (org-agenda-mode . centaur-tabs-local-mode)
  (helpful-mode . centaur-tabs-local-mode))

(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

;; Modern terminal-based file explorer
(use-package dirvish
  :ensure t
  :after dired
  :init
  (dirvish-override-dired-mode)
  :custom
  (dirvish-quick-access-entries
   '(("h" "~/" "home")
     ("e" "~/.config/emacs/" "emacs")
     ("p" "~/coding/projects" "projects")
     ("c" "~/.config/" "config")
     ("d" "~/Downloads/" "downloads")))
  (dirvish-mode-line-format
   '(:left (sort file-time " " file-size symlink) :right (omit yank index)))
  (dirvish-attributes '(all-the-icons collapse subtree-state vc-state git-msg))
  :config
  ;; General dired settings
  (setq dired-dwim-target t
        delete-by-moving-to-trash t
        dired-kill-when-opening-new-dired-buffer t
        dired-recursive-copies 'always
        dired-recursive-deletes 'always)

  ;; Enable mouse drag-and-drop files to other applications
  (setq mouse-drag-and-drop-region-cross-program t) ; added in Emacs 29

  :bind
  (("C-c f" . dirvish-fd)
   :map dirvish-mode-map
   ("a"   . dirvish-quick-access)
   ("f"   . dirvish-file-info-menu)
   ("y"   . dirvish-yank-menu)
   ("N"   . dirvish-narrow)
   ("^"   . dirvish-history-last)
   ("h"   . dirvish-history-jump)
   ("s"   . dirvish-quicksort)
   ("v"   . dirvish-vc-menu)
   ("TAB" . dirvish-subtree-toggle)
   ("M-f" . dirvish-history-go-forward)
   ("M-b" . dirvish-history-go-backward)
   ("M-l" . dirvish-ls-switches-menu)
   ("M-m" . dirvish-mark-menu)
   ("M-t" . dirvish-layout-toggle)
   ("M-s" . dirvish-setup-menu)
   ("M-e" . dirvish-emerge-menu)
   ("M-j" . dirvish-fd-jump)))

(use-package ibuffer-projectile
  :ensure t
  :after ibuffer
  :hook (ibuffer . (lambda ()
                    (ibuffer-projectile-set-filter-groups)
                    (unless (eq ibuffer-sorting-mode 'alphabetic)
                      (ibuffer-do-sort-by-alphabetic))))
  :config
  (setq ibuffer-formats
        '((mark modified read-only " "
                (name 18 18 :left :elide)
                " "
                (size 9 -1 :right)
                " "
                (mode 16 16 :left :elide)
                " "
                project-relative-file))))

(use-package ibuffer
  :ensure nil
  :straight nil
  :bind ("C-x C-b" . ibuffer)
  :config
  (setq ibuffer-expert t)
  (setq ibuffer-show-empty-filter-groups nil)
  (setq ibuffer-saved-filter-groups
      '(("home"
         ("Org" (or (mode . org-mode)
                    (filename . "OrgMode")))
         ("code" (filename . "code"))
         ("Web Dev" (or (mode . html-mode)
                        (mode . css-mode)))
         ("Magit" (name . "\*magit"))
         ("Help" (or (name . "\*Help\*")
                     (name . "\*Apropos\*")
                     (name . "\*info\*")))))))

(use-package nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

;; Define preferred line width
(setq-default fill-column 80)

;; Org mode setup function
(defun dw/org-mode-setup ()
  "Initial setup for org-mode."
  (org-indent-mode 1)
  (variable-pitch-mode 1)
  (auto-fill-mode 1)
  (visual-line-mode 1)
  (setq evil-auto-indent nil))

;; Improved org configuration
(use-package org
  :defer t
  :hook (org-mode . dw/org-mode-setup)
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture))
  :custom
  (org-ellipsis " ▾")
  (org-hide-emphasis-markers t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 2)
  (org-hide-block-startup nil)
  (org-src-preserve-indentation nil)
  (org-startup-folded 'content)
  (org-cycle-separator-lines 2)
  (org-agenda-start-with-log-mode t)
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-agenda-window-setup 'current-window)

  :config
  (setq org-refile-targets '((nil :maxlevel . 2)
                             (org-agenda-files :maxlevel . 2)))
  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)
  (setq org-directory "~/Documents/roam")
  (setq org-agenda-files (list "~/Documents/roam/" "~/Documents/roam/journal"))
  (setq org-agenda-file-regexp "\\`[^.].*\\.org\\|.todo\\'")
  (setq org-todo-keywords
        '((sequence "TODO" "READ" "RESEARCH" "|" "DONE" "DELEGATED" )))
  (setq org-default-notes-file (concat org-directory "notes.org"))
  (setq org-hide-emphasis-markers t)

  (add-hook 'org-mode-hook 'turn-on-flyspell)
  (setq org-fontify-done-headline t)

  (setq org-todo-keyword-faces
        '(("TODO" . org-warning)
          ("READ" . "yellow")
          ("RESEARCH" . (:foreground "blue" :weight bold))
          ("CANCELED" . (:foreground "pink" :weight bold))
          ("WRITING" . (:foreground "red" :weight bold))
          ("RECIEVED" . (:foreground "red" :background "green" :weight bold))
          ("SUBMITTED" . (:foreground "blue"))
          ("ACCEPTED" . (:foreground "green")))))

(use-package org-superstar
  :ensure t
  :after org
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-remove-leading-stars t)
  (org-superstar-leading-bullet " ")
  (org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●")))

(use-package org-tempo
  :ensure nil
  :straight nil
  :after org
  :config
  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
  (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
  (add-to-list 'org-structure-template-alist '("json" . "src json")))

(use-package org-download
  :ensure t
  :after org
  :defer t
  :custom
  (org-download-method 'directory)
  (org-download-image-dir "~/Documents/roam/pictures")
  (org-download-heading-lvl nil)
  (org-download-timestamp "%Y%m%d-%H%M%S_")
  (org-image-actual-width 300)
  (org-download-screenshot-method
   (cond ((executable-find "pngpaste") "pngpaste %s")
         ((executable-find "scrot") "scrot -s %s")
         (t "screenshot %s")))
  :bind
  ("C-M-y" . org-download-screenshot)
  :config
  (require 'org-download))

(use-package org-roam
    :ensure t
    :defer 2
    :init
    (setq org-roam-v2-ack t)
    (setq org-roam-dailies-directory "~/Documents/roam/journal/")
    :custom
    (org-roam-directory "~/Documents/roam")
    (org-roam-completion-everywhere t)
    (org-roam-capture-templates
     '(("d" "default" plain "%?"
        :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n")
        :unnarrowed t)
       ("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
        :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n#+filetags: project")
        :unnarrowed t)
       ("b" "brainstorm" plain "%?"
        :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n#+filetags: brainstorm")
        :unnarrowed t)
       ("m" "meeting" plain "* Topic\n\n%?\n\n* Attending\n\n* Notes\n\n ** Conclusion\n\n"
        :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n#+filetags: project")
        :unnarrowed t)
       ("a" "article" plain "*[[${link}][${description}]]\n\n* Notes\n\n"
        :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n#+filetags: article")
        :unnarrowed t)))

    (org-roam-dailies-capture-templates
     '(("d" "default" entry "* %<%I:%M %p>: %?"
        :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))

    :bind (("C-c o l" . org-roam-buffer-toggle)
           ("C-c o f" . org-roam-node-find)
           ("C-c o i" . org-roam-node-insert)
           :map org-mode-map
           ("C-M-i"    . completion-at-point)
           :map org-roam-dailies-map
           ("Y" . org-roam-dailies-capture-yesterday)
           ("T" . org-roam-dailies-capture-tomorrow))
    :bind-keymap
    ("C-c o d" . org-roam-dailies-map)
    :config
    (require 'org-roam-dailies) ;; Ensure the keymap is available
    (org-roam-db-autosync-mode))

  (defun my/org-roam-copy-todo-to-today ()
    (interactive)
    (let ((org-refile-keep t) ;; Set this to nil to delete the original!
          (org-roam-dailies-capture-templates
           '(("t" "tasks" entry "%?"
              :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n" ("Tasks")))))
          (org-after-refile-insert-hook #'save-buffer)
          today-file
          pos)
      (save-window-excursion
        (org-roam-dailies--capture (current-time) t)
        (setq today-file (buffer-file-name))
        (setq pos (point)))

      ;; Only refile if the target file is different than the current file
      (unless (equal (file-truename today-file)
                     (file-truename (buffer-file-name)))
        (org-refile nil nil (list "Tasks" today-file nil pos)))))


(with-eval-after-load 'org
  (add-hook 'org-after-todo-state-change-hook
            (lambda ()
              (when (equal org-state "DONE")
                (my/org-roam-copy-todo-to-today)))))

(use-package org-roam-ui
  :ensure t
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme nil
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package flycheck
:ensure t
:defer t
:diminish flycheck-mode
:hook ((prog-mode . flycheck-mode)
       (lsp-mode . flycheck-mode))
:custom
(flycheck-display-errors-delay 0.3)
(flycheck-check-syntax-automatically '(save mode-enabled idle-change))
(flycheck-idle-change-delay 0.5)
:config
;; Define missing variable for ruff
(defvar flycheck-python-ruff-args nil
  "Arguments to pass to ruff when checking Python files.")

;; Fix for ruff output format if using newer ruff versions
(flycheck-define-checker python-ruff
  "A Python syntax and style checker using the ruff utility."
  :command ("ruff"
            "--format=json"  ;; Updated format option for newer ruff versions
            (eval flycheck-python-ruff-args)
            source-inplace)
  :error-parser flycheck-parse-ruff
  :modes python-mode
  :predicate flycheck-buffer-saved-p)

;; Make sure python-ruff is included in the checkers
(add-to-list 'flycheck-checkers 'python-ruff)

;; Set up Python checkers priority
(flycheck-add-next-checker 'python-flake8 'python-pylint)
(flycheck-add-next-checker 'python-pylint 'python-ruff)

;; Set up Python checkers to ignore certain errors
(setq flycheck-flake8-maximum-line-length 100)
(setq flycheck-python-pylint-executable "pylint")
(setq flycheck-python-flake8-executable "flake8")

;; Customize error display
(setq flycheck-indication-mode 'right-fringe)
(when (fboundp 'define-fringe-bitmap)
  (define-fringe-bitmap 'flycheck-fringe-bitmap-double-arrow
    [0 0 0 0 0 4 12 28 60 124 252 124 60 28 12 4 0 0 0 0]))

;; Add a slight delay before checking
(setq flycheck-highlighting-mode 'symbols)
(setq flycheck-check-syntax-automatically '(save idle-change mode-enabled))
(setq flycheck-idle-change-delay 0.8)
(setq flycheck-idle-buffer-switch-delay 0.5))

(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :hook (prog-mode . yas-minor-mode)
  :config
  (setq yas-snippet-dirs '("~/.config/emacs/snippets"))
  (yas-reload-all))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet
  :config
  (yasnippet-snippets-initialize))

(use-package move-lines
  :straight (move-lines :type git :host github :repo "targzeta/move-lines")
  :ensure t
  :bind (("C-c n" . move-lines-down)
         ("C-c p" . move-lines-up))
  :config
  (defun tom/shift-left (start end &optional count)
    "Shift region left and activate hydra."
    (interactive
     (if mark-active
         (list (region-beginning) (region-end) current-prefix-arg)
       (list (line-beginning-position) (line-end-position) current-prefix-arg)))
    (python-indent-shift-left start end count))

  (defun tom/shift-right (start end &optional count)
    "Shift region right and activate hydra."
    (interactive
     (if mark-active
         (list (region-beginning) (region-end) current-prefix-arg)
       (list (line-beginning-position) (line-end-position) current-prefix-arg)))
    (python-indent-shift-right start end count)))

(use-package smartparens
  :ensure t
  :defer t
  :diminish smartparens-mode
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config)
  (setq-default sp-escape-quotes-after-insert nil)
  (setq sp-autoinsert-pair nil
        sp-autodelete-pair nil
        sp-autodelete-closing-pair nil
        sp-autodelete-opening-pair nil
        sp-autoskip-closing-pair nil
        sp-autoskip-opening-pair nil
        sp-cancel-autoskip-on-backward-movement nil
        sp-autodelete-wrap nil
        sp-autowrap-region nil
        sp-autoinsert-quote-if-followed-by-closing-pair nil))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

(defun my-highlighter (level responsive display)
  "Custom highlighter function for indent guides."
  (if (> 1 level)
      nil
    (highlight-indent-guides--highlighter-default level responsive display)))

(use-package highlight-indent-guides
  :ensure t
  :defer t
  :diminish highlight-indent-guides-mode
  :hook (prog-mode . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-auto-enabled nil)
  (highlight-indent-guides-method 'character)
  (highlight-indent-guides-responsive 'stack)
  (highlight-indent-guides-highlighter-function 'my-highlighter)
  :config
  (set-face-foreground 'highlight-indent-guides-character-face "#D103CE")
  (set-face-foreground 'highlight-indent-guides-top-character-face "#5BFFB2")
  (set-face-foreground 'highlight-indent-guides-stack-character-face "#785390"))

;; Modern multiple cursors functionality
(use-package multiple-cursors
  :ensure t
  :defer t
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this))
  :config
  (setq mc/list-file "~/.config/emacs/mc-lists"))

(use-package flyspell
  :ensure nil
  :straight nil
  :diminish flyspell-mode
  :commands (ispell-change-dictionary
             ispell-word
             flyspell-buffer
             flyspell-mode
             flyspell-region)
  :config
  (setq flyspell-issue-message-flag nil)
  (setq flyspell-issue-welcome-flag nil)
  (setq ispell-program-name
        (cond ((executable-find "aspell") "aspell")
              ((executable-find "hunspell") "hunspell")
              (t "ispell")))
  (setq ispell-dictionary "american")
  :hook
  (text-mode . flyspell-mode)
  (org-mode . flyspell-mode))

;; Modern Git interface
(use-package magit
  :ensure t
  :defer t
  :bind (("s-g" . magit-status)
         ("C-x g" . magit-status))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; Modern time machine for Git
(use-package git-timemachine
  :ensure t
  :defer t
  :bind ("C-c g t" . git-timemachine))

;; Modern approach to track todos in Git projects
(use-package magit-todos
  :ensure t
  :after magit
  :hook (magit-mode . magit-todos-mode)
  :custom
  (magit-todos-exclude-globs '("node_modules" "*.json" "*.lock"))
  :config
  (magit-todos-mode))

;; Modern project management
(use-package projectile
  :ensure t
  :defer 0.5
  :diminish projectile-mode
  :custom
  (projectile-completion-system 'default)
  (projectile-indexing-method 'hybrid)
  (projectile-sort-order 'recentf)
  (projectile-enable-caching t)
  (projectile-globally-ignored-directories
   '(".idea" ".vscode" ".ensime_cache" ".eunit" ".git" ".hg" ".fslckout" ".bzr" "_darcs" ".tox" ".svn" ".stack-work" "node_modules" "build" "dist"))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :config
  (when (file-directory-p "~/coding/projects")
    (setq projectile-project-search-path '("~/coding/projects")))
  (projectile-mode))

;; Integration between projectile and consult
(use-package consult-projectile
  :ensure t
  :after (consult projectile)
  :bind (("C-c p f" . consult-projectile-find-file)
         ("C-c p g" . consult-projectile-ripgrep)))

;; Python formatting tools
(use-package py-isort
  :ensure t
  :after python
  :defer t)

(use-package blacken
  :ensure t
  :after python
  :defer t
  :custom
  (blacken-fast-unsafe t)
  (blacken-line-length 88))

;; Environment management
(use-package direnv
  :ensure t
  :defer 0.5
  :config
  (direnv-mode))

(use-package pyvenv
  :ensure t
  :defer t
  :custom
  (pyvenv-mode-line-indicator '(pyvenv-virtual-env-name ("<" pyvenv-virtual-env-name "> ")))
  :hook
  (python-mode . pyvenv-mode)
  :config
  (pyvenv-tracking-mode 1))

;; Python mode configuration
(use-package python
  :ensure nil
  :straight nil
  :mode "\\.py\\'"
  :hook
  (python-mode . (lambda ()
                  (setq tab-width 4)
                  (setq python-indent-offset 4)))
  :custom
  (python-shell-interpreter "python3")
  (python-shell-interpreter-args "-i"))

;; Auto documentation for Python
(use-package sphinx-doc
  :ensure t
  :defer t
  :hook (python-mode . sphinx-doc-mode)
  :custom
  (sphinx-doc-include-types t))

;; Restart python when changing virtual environment
(defun wcx-restart-python ()
  "Restart Python interpreter."
  (interactive)
  (pyvenv-restart-python))

;; Stan mode for statistical modeling
(use-package stan-mode
  :ensure t
  :mode (("\\.stan\\'" . stan-mode)
         ("\\.stanfunctions\\'" . stan-mode))
  :hook (stan-mode . stan-mode-setup)
  :custom
  (stan-indentation-offset 2))

(use-package company-stan
  :ensure t
  :hook (stan-mode . company-stan-setup)
  :custom
  (company-stan-fuzzy t))

(use-package eldoc-stan
  :ensure t
  :hook (stan-mode . eldoc-stan-setup))

(use-package flycheck-stan
  :ensure t
  :hook ((stan-mode . flycheck-stan-stanc2-setup)
         (stan-mode . flycheck-stan-stanc3-setup))
  :custom
  (flycheck-stanc-executable nil)
  (flycheck-stanc3-executable nil))

(use-package stan-snippets
  :ensure t
  :hook (stan-mode . stan-snippets-initialize))

;; Julia support
(use-package julia-mode
  :ensure t
  :defer t
  :mode "\\.jl\\'")

;; Julia LSP support
(use-package lsp-julia
  :ensure t
  :defer t
  :after lsp-mode
  :custom
  (lsp-julia-default-environment "~/.julia/environments/v1.7"))

;; YAML support
(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml$" . yaml-mode)
  :hook (yaml-mode . (lambda ()
                      (define-key yaml-mode-map "\C-m" 'newline-and-indent))))

;; LaTeX editing
(use-package auctex
  :ensure t
  :defer t
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-PDF-mode t)
  (TeX-master nil)
  (TeX-engine 'xetex))

;; Reference management
(use-package reftex
  :ensure t
  :defer t
  :after latex
  :custom
  (reftex-plug-into-AUCTeX t)
  (reftex-default-bibliography '("/Users/jburgess/Documents/complete_bib.bib")))

;; LaTeX mode configuration
(use-package latex
  :ensure auctex
  :mode ("\\.tex\\'" . latex-mode)
  :bind
  (:map LaTeX-mode-map
        ("M-<delete>" . TeX-remove-macro)
        ("C-c C-r" . reftex-query-replace-document)
        ("C-c C-g" . reftex-grep-document))
  :custom
  (LaTeX-babel-hyphen nil)
  (LaTeX-csquotes-close-quote "}")
  (LaTeX-csquotes-open-quote "\\enquote{")
  (TeX-file-extensions '("Rnw" "rnw" "Snw" "snw" "tex" "sty" "cls" "ltx" "texi" "texinfo" "dtx"))
  :hook
  (LaTeX-mode . reftex-mode)
  (LaTeX-mode . visual-line-mode)
  (LaTeX-mode . flyspell-mode)
  (LaTeX-mode . LaTeX-math-mode)
  (LaTeX-mode . turn-on-reftex)
  (LaTeX-mode . TeX-fold-mode)
  :config
  (add-to-list 'safe-local-variable-values '(TeX-command-extra-options . "-shell-escape"))
  (font-lock-add-keywords 'latex-mode (list (list "\\(«\\(.+?\\|\n\\)\\)\\(+?\\)\\(»\\)" '(1 'font-latex-string-face t) '(2 'font-latex-string-face t) '(3 'font-latex-string-face t))))
  (add-hook 'TeX-mode-hook (lambda () (reftex-isearch-minor-mode)))
  (add-hook 'LaTeX-mode-hook 'TeX-fold-buffer t))

;; BibTeX mode for bibliography files
(use-package bibtex
  :ensure nil
  :straight nil
  :mode ("\\.bib\\'" . bibtex-mode))

;; Improved markdown editing with live preview
(use-package markdown-mode
  :ensure t
  :defer t
  :mode ("\\.md\\'" . markdown-mode)
  :custom
  (markdown-command
   (cond ((executable-find "marked") "marked")
         ((executable-find "pandoc") "pandoc")
         (t "markdown")))
  (markdown-fontify-code-blocks-natively t)
  :config
  (defun dw/set-markdown-header-font-sizes ()
    "Set markdown header font sizes."
    (dolist (face '((markdown-header-face-1 . 1.2)
                    (markdown-header-face-2 . 1.1)
                    (markdown-header-face-3 . 1.0)
                    (markdown-header-face-4 . 1.0)
                    (markdown-header-face-5 . 1.0)))
      (set-face-attribute (car face) nil :weight 'normal :height (cdr face))))

  (defun dw/markdown-mode-hook ()
    "Hook for markdown-mode."
    (dw/set-markdown-header-font-sizes))

  (add-hook 'markdown-mode-hook 'dw/markdown-mode-hook))

;; Live markdown preview
(use-package markdown-preview-mode
  :ensure t
  :after markdown-mode
  :defer t)

;; Docker file editing
(use-package dockerfile-mode
  :ensure t
  :defer t
  :mode ("Dockerfile\\'" . dockerfile-mode))

;; Docker compose file editing
(use-package docker-compose-mode
  :ensure t
  :defer t
  :mode ("docker-compose\\.ya?ml\\'" . docker-compose-mode))

;; Docker management interface
(use-package docker
  :ensure t
  :defer t
  :bind ("C-c d" . docker))

;; Enhanced JSON editing
(use-package json-mode
  :ensure t
  :defer t
  :mode "\\.json\\'"
  :hook (json-mode . (lambda ()
                     (setq-local js-indent-level 2))))

;; Pretty print JSON
(use-package json-reformat
  :ensure t
  :after json-mode
  :bind (:map json-mode-map
              ("C-c C-f" . json-reformat-region)))

;; Clojure editing
(use-package clojure-mode
  :ensure t
  :defer t
  :mode (("\\.clj\\'" . clojure-mode)
         ("\\.edn\\'" . clojure-mode))
  :hook ((clojure-mode . yas-minor-mode)
         (clojure-mode . subword-mode)
         (clojure-mode . smartparens-mode)
         (clojure-mode . rainbow-delimiters-mode)
         (clojure-mode . eldoc-mode)))

;; Clojure refactoring
(use-package clj-refactor
  :ensure t
  :defer t
  :diminish clj-refactor-mode
  :hook (clojure-mode . clj-refactor-mode)
  :config
  (cljr-add-keybindings-with-prefix "C-c C-m"))

;; Clojure REPL integration
(use-package cider
  :ensure t
  :defer t
  :diminish subword-mode
  :hook (cider-mode . clj-refactor-mode)
  :custom
  (nrepl-log-messages t)
  (cider-repl-display-in-current-window t)
  (cider-repl-use-clojure-font-lock t)
  (cider-prompt-save-file-on-load 'always-save)
  (cider-font-lock-dynamically '(macro core function var))
  (nrepl-hide-special-buffers t)
  (cider-overlays-use-font-lock t)
  :config
  (cider-repl-toggle-pretty-printing))

;; Go language support
(use-package go-mode
  :ensure t
  :defer t
  :mode "\\.go\\'"
  :hook ((go-mode . lsp-deferred)
         (go-mode . yas-minor-mode)
         (before-save . (lambda ()
                        (when (eq major-mode 'go-mode)
                          (lsp-format-buffer)
                          (lsp-organize-imports))))))

;; Redact text temporarily for screenshots/privacy
(use-package redacted
  :ensure t
  :commands redacted-mode
  :bind ([f2] . redacted-mode))

;; Distraction-free writing environment
(use-package darkroom
  :ensure t
  :commands darkroom-mode
  :bind ("C-c w d" . darkroom-tentative-mode)
  :custom
  (darkroom-text-scale-increase 0))

;; Focus on current region/paragraph
(use-package focus
  :ensure t
  :defer t
  :bind ("C-c w f" . focus-mode))

;; Modern centered writing mode
(use-package writeroom-mode
  :ensure t
  :defer t
  :bind ("C-c w w" . writeroom-mode)
  :custom
  (writeroom-width 90)
  (writeroom-mode-line t))

;; Enhanced CSV editing
(use-package csv-mode
  :ensure t
  :defer t
  :mode "\\.csv\\'"
  :custom
  (csv-separators '("," ";" "|" "\t")))

;; Visual CSV table view
(use-package csv-mode
  :after csv-mode
  :defer t
  :config
  (defun csv-highlight-current-column ()
    "Highlight current column in CSV mode."
    (interactive)
    (when (derived-mode-p 'csv-mode)
      (csv-highlight-column (current-column))))
  :hook (csv-mode . csv-align-mode))

;; Modern RSS feed reader
(use-package elfeed-org
  :ensure t
  :defer t
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files (list "~/org/rss.org")))

;; Custom display function for elfeed
(defun concatenate-authors (authors-list)
  "Given AUTHORS-LIST, list of plists; return string of all authors concatenated."
  (mapconcat
   (lambda (author) (plist-get author :name))
   authors-list ", "))

(defun my-search-print-fn (entry)
  "Print ENTRY to the buffer."
  (let* ((date (elfeed-search-format-date (elfeed-entry-date entry)))
         (title (or (elfeed-meta entry :title)
                    (elfeed-entry-title entry) ""))
         (title-faces (elfeed-search--faces (elfeed-entry-tags entry)))
         (feed (elfeed-entry-feed entry))
         (feed-title
          (when feed
            (or (elfeed-meta feed :title) (elfeed-feed-title feed))))
         (entry-authors (concatenate-authors
                         (elfeed-meta entry :authors)))
         (tags (mapcar #'symbol-name (elfeed-entry-tags entry)))
         (tags-str (mapconcat
                    (lambda (s) (propertize s 'face
                                            'elfeed-search-tag-face))
                    tags ","))
         (title-width (- (window-width) 5
                         elfeed-search-trailing-width))
         (title-column (elfeed-format-column
                        title (elfeed-clamp
                               elfeed-search-title-min-width
                               title-width
                               elfeed-search-title-max-width)
                        :left))
         (authors-width 80)
         (authors-column (elfeed-format-column
                          entry-authors (elfeed-clamp
                                         elfeed-search-title-min-width
                                         authors-width
                                         130)
                          :left)))

    (insert (propertize date 'face 'elfeed-search-date-face) " ")
    (insert (propertize title-column
                        'face title-faces 'kbd-help title) " ")
    (insert (propertize authors-column
                        'face 'elfeed-search-date-face
                        'kbd-help entry-authors) " ")
    (when entry-authors
      (insert (propertize feed-title
                          'face 'elfeed-search-feed-face) " "))))

;; Main elfeed configuration
(use-package elfeed
  :ensure t
  :defer t
  :bind ("C-x w" . elfeed)
  :custom
  (elfeed-search-print-entry-function #'my-search-print-fn))

;; Scoring system for elfeed
(use-package elfeed-score
  :ensure t
  :after elfeed
  :config
  (setq elfeed-score-serde-score-file "~/.config/emacs/elfeed.score")
  (elfeed-score-enable)
  :bind (:map elfeed-search-mode-map
         ("=" . elfeed-score-map)))

;; Interactive regex testing
(use-package regex-tool
  :ensure t
  :defer t
  :custom
  (regex-tool-backend "Perl"))

;; Load the primary theme
(defun load-theme-after-init ()
  "Load theme after initialization."
  (when (display-graphic-p)
    (jmb/load-theme 'doom-nord)))

(add-hook 'after-init-hook #'load-theme-after-init)

;; Report memory usage after loading
(add-hook 'after-init-hook
          (lambda ()
            (message "*** Memory usage: %s" (memory-usage-string))))

;; Custom function to report memory usage
(defun memory-usage-string ()
  "Return formatted string with memory usage information."
  (format "%.2fMB (Emacs) %.2fMB (malloc)"
          (/ (float (memory-info-property 'total-allocated)) (* 1024 1024))
          (/ (float (memory-info-property 'total-memory)) (* 1024 1024))))

;; Enable profiler if needed
(when (and (boundp 'use-profiler) use-profiler)
  (require 'profiler)
  (profiler-start 'cpu+mem)
  (add-hook 'after-init-hook
            (lambda ()
              (profiler-report)
              (profiler-stop))))
