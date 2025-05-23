;; (defun dw/org-babel-tangle-dont-ask ()
;;   ;; Dynamic scoping to the rescue
;;   (let ((org-confirm-babel-evaluate nil))
;;     (org-babel-tangle)))

;; (add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'dw/org-babel-tangle-dont-ask
;;                                               'run-at-end 'only-in-org-mode)))

(setq jmb/is-guix-system (and (eq system-type 'gnu/linux)
                              (require 'f)
                              (string-equal (f-read "/etc/issue")
                                            "\nThis is the GNU system.  Welcome.\n")))

(setq jmb/is-macos-system (eq system-type 'darwin))

;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))

;; Profile emacs startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

;; Silence compiler warnings as they can be pretty disruptive
(setq comp-async-report-warnings-errors nil)
(setq native-comp-async-report-warnings-errors nil)

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

;; Load the helper package for commands like `straight-x-clean-unused-repos'
(require 'straight-x)

(use-package chezmoi
  :ensure t
  :after magit
  :config
  (add-hook 'org-babel-post-tangle-hook #'chezmoi-write)
  )

(use-package bug-hunter
  :ensure t
  )

(fset 'yes-or-no-p 'y-or-n-p)

;;(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)


(setq visible-bell t)

(set-fringe-mode 5)

(dolist (mode
         '(tool-bar-mode                ; No toolbars, more room fo
           scroll-bar-mode              ; No scroll bars either
           menu-bar-mode
           tooltip-mode
           ))
  (funcall mode -1))

(set-frame-parameter (selected-frame) 'alpha '(85 . 70))
(add-to-list 'default-frame-alist '(alpha . (85 . 70)))

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(use-package no-littering)

;; Keep customization settings in a temporary file (thanks Ambrevar!)
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

(defvar user-temporary-file-directory
  "~/.emacs-autosaves/")

(make-directory user-temporary-file-directory t)
(setq backup-by-copying t)
(setq backup-directory-alist
      `(("." . ,user-temporary-file-directory)
        (tramp-file-name-regexp nil)))
(setq auto-save-list-file-prefix
      (concat user-temporary-file-directory ".auto-saves-"))
(setq auto-save-file-name-transforms
      `((".*" ,user-temporary-file-directory t)))

(defun tidy ()
  "Ident, untabify and unwhitespacify current buffer, or region if active."
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (point-min)))
        (end (if (region-active-p) (region-end) (point-max))))
    (indent-region beg end)
    (whitespace-cleanup)
    (untabify beg (if (< end (point-max)) end (point-max)))))


(defun kill-this-buffer-unless-scratch ()
  "Works like `kill-this-buffer' unless the current buffer is the
*scratch* buffer. In witch case the buffer content is deleted and
the buffer is buried."
  (interactive)
  (if (not (string= (buffer-name) "*scratch*"))
      (kill-this-buffer)
    (delete-region (point-min) (point-max))
    (switch-to-buffer (other-buffer))
    (bury-buffer "*scratch*")))

(if (eq system-type 'darwin)
    (defun copy-from-osx ()
      (shell-command-to-string "pbpaste"))

  (defun paste-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))

  (setq interprogram-cut-function 'paste-to-osx)
  (setq interprogram-paste-function 'copy-from-osx)
  )


;; set keys for Apple keyboard, for emacs in OS X
(setq mac-command-modifier 'super) ; make cmd key do Meta
(setq ns-function-modifier 'hyper)  ; make Fn key do Hyper

(set-default-coding-systems 'utf-8)

(setq large-file-warning-threshold nil)
(setq vc-follow-symlinks t)
(setq ad-redefinition-action 'accept)

;; Minimap
(use-package sublimity
  :ensure t
  :config (require 'sublimity)
  (require 'sublimity-scroll)
  (setq sublimity-scroll-weight 10
        sublimity-scroll-drift-length 20)
                                        ;  (require 'sublimity-map)
  (sublimity-mode 1))
                                        ;  (sublimity-map-set-delay 3))

(use-package s)
(use-package all-the-icons
  :if (display-graphic-p)
  :ensure t
  :demand t
  :after s
  :config
  (when (not (member "all-the-icons" (font-family-list)))
    (all-the-icons-install-fonts t)))

;; (setq
;;  all-the-icons-mode-icon-alist
;;  `(,@all-the-icons-mode-icon-alist
;;    (telega-chat-mode all-the-icons-fileicon "telegram" :v-adjust 0.0
;;                      :face all-the-icons-blue-alt)
;;    (telega-root-mode all-the-icons-material "contacts" :v-adjust 0.0)))

;; (use-package all-the-icons-ibuffer
;;   :ensure t
;;   :init (all-the-icons-ibuffer-mode 1))

(use-package nerd-icons
  :ensure t
  ;; :custom
  ;; The Nerd Font you want to use in GUI
  ;; "Symbols Nerd Font Mono" is the default and is recommended
  ;; but you can use any other Nerd Font if you want
  ;; (nerd-icons-font-family "Symbols Nerd Font Mono")
  )

;; (use-package super-save
;;   :defer 1
;;   :diminish super-save-mode
;;   :config
;;   (super-save-mode +1)
;;   (setq super-save-auto-save-when-idle t))


;; Revert Dired and other buffers
(setq global-auto-revert-non-file-buffers t)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

(use-package doom-themes
  :ensure t
  :defer t
  :init

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config)
  (doom-themes-neotree-config)

  )

;; Or if you have use-package installed
(use-package kaolin-themes
  :ensure t

  :config
  )

(use-package green-is-the-new-black-theme
  :ensure t

  :config
  )

(use-package green-phosphor-theme
  :ensure t

  :config
  )


(use-package vscode-dark-plus-theme
  :ensure t


  )

(use-package blueballs-dark-theme
  :straight
  (:host github :repo "blueballs-theme/blueballs-emacs" :branch "master" :files ("*.el"))
  )

(use-package brilliance-dull-theme
  :straight
  (:host github :repo "bizzyman/brilliance-dull-theme-emacs" :branch "master" :files ("*.el"))
  )


(use-package nano-theme
  :straight
  (:host github :repo "rougier/nano-theme" :branch "master" :files ("*.el"))
  )

(use-package writerish-dark-theme
  :straight
  (:host github :repo "apc/writerish" :branch "master" :files ("*.el"))
  )


(use-package omni-theme
  :straight
  (:host github :repo "getomni/emacs" :branch "main" :files ("*.el"))
  )


(use-package the-matrix-theme
  :straight
  (:host github :repo "monkeyjunglejuice/matrix-emacs-theme" :branch "main" :files ("*.el"))
  )

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
          (t . (semilight 1.1))))


  :config
  (load-theme 'modus-vivendi t)


  )


(use-package ef-themes
  :ensure t
  :init
  ;; Add all your customizations prior to loading the themes

  (setq ef-themes-mode-line '(accented borderless)
        ef-themes-bold-constructs t
        ef-themes-italic-constructs t
        ef-themes-fringes 'subtle
        ef-themes-tabs-accented t
        ef-themes-syntax '(faint)
        ef-themes-paren-match '(bold intense)
        ef-themes-prompts '(bold intense)
        ef-themes-completions (quote ((matches . (extrabold intense background))
                                      (selection . (semibold accented intense))
                                      (popup . (accented))))

                                        ;ef-themes-org-blocks nil;'tinted-background
        ef-themes-scale-headings t
        ef-themes-region '(bg-only)
        ef-themes-headings
        '((1 . (rainbow  1.4))
          (2 . (rainbow  1.3))
          (3 . (rainbow bold 1.2))
          (t . (semilight 1.1))))



  )

(require 'display-line-numbers)
(defcustom display-line-numbers-exempt-modes '(vterm-mode eshell-mode shell-mode term-mode org-mode ansi-term-mode)
  "Major modes on which to disable the linum mode, exempts them from global requirement"
  :group 'display-line-numbers
  :type 'list
  :version "green")

(defun display-line-numbers--turn-on ()
  "turn on line numbers but excempting certain major modes defined in `display-line-numbers-exempt-modes'"
  (if (and
       (not (member major-mode display-line-numbers-exempt-modes))
       (not (minibufferp)))
      (display-line-numbers-mode)))

(global-display-line-numbers-mode)

(column-number-mode)

;; Set the font face based on platform



(defun jmb/set-font ()
  (add-to-list 'default-frame-alist
               '(font . "FiraCode Nerd Font Mono 13"))



  (set-frame-font "FiraCode Nerd Font Mono 13" nil t)

  (set-face-attribute 'default nil :font "FiraCode Nerd Font Mono 13"
                      ;;:height 170
                      )

  ;; Set the fixed pitch face
  (set-face-attribute 'fixed-pitch nil
                      :font "FiraCode Nerd Font Mono 13"
                      :weight 'light)


  ;; Set the variable pitch face
  (set-face-attribute 'variable-pitch nil
                      ;; :font "Cantarell"
                      :font "BlexMono Nerd Font 13"
                      :weight 'light)

  )


(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (setq doom-modeline-icon t)
                (with-selected-frame frame
                  (jmb/set-font))))
  (jmb/set-font))

(defun preserve-font ( &rest args)


  (jmb/set-font)



  (set-face-attribute 'org-document-title nil :font "BlexMono Nerd Font" :weight 'bold :height 1.3)
  (dolist (face '((org-level-1 . 1.5)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "BlexMono Nerd Font" :weight 'regular :height (cdr face)))

  ;; Make sure org-indent face is available
  ;;    (require 'org-indent)

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil  :inherit 'fixed-pitch)
  (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)


  )

(advice-add 'consult-theme :after 'preserve-font)

(provide 'advice)

(use-package emojify
  :init
  (global-emojify-mode))

(setq display-time-format "%l:%M %p %b %y"
      display-time-default-load-average nil)

(use-package diminish
  :ensure t
  :config
  (diminish 'rainbow-mode)
  (diminish 'auto-fill-mode)
  (diminish 'abbrev-mode)
  (diminish 'auto-revert-mode)
  (diminish 'yas-mode)
  (diminish 'yas-global-mode)

  ;; (diminish 'sphinx-doc-mode)
  (diminish 'which-key-mode)
  (diminish 'global-eldoc-mode)
  (diminish 'global-font-lock-mode)
  (diminish 'highlight-indent-guides-mode)
  (diminish 'elpy-mode)
  (diminish 'abbrev-mode)
  (diminish 'flyspell-mode)
  (diminish 'flycheck-mode)
  (diminish 'font-lock-mode)


  )

;; You must run (all-the-icons-install-fonts) one time after
;; installing this package!

(use-package minions
  :ensure t
  :hook (doom-modeline-mode . minions-mode))

(use-package doom-modeline
  :ensure t
  ;;:after eshell     ;; Make sure it gets hooked after eshell
  ;;:hook (after-init . doom-modeline-mode)
  :init (doom-modeline-mode 1)
  :custom-face
  (mode-line ((t (:height 0.85))))
  (mode-line-inactive ((t (:height 0.85))))
  :custom
  (doom-modeline-height 15)
  (doom-modeline-bar-width 6)
  (doom-modeline-lsp t)
  (doom-modeline-mu4e nil)
  (doom-modeline-irc nil)
  (doom-modeline-persp-name nil)
  (doom-modeline-buffer-file-name-style 'truncate-except-project)
  ;;  (doom-modeline-buffer-file-name-style 'auto)
  (doom-modeline-major-mode-icon nil)
  (doom-modeline-hud t)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-window-width-limit fill-column)
  (doom-modeline-project-detection 'projectile)
  (doom-modeline-buffer-encoding nil)
  (auto-revert-check-vc-info t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-minor-modes nil)
  (doom-modeline-enable-word-count nil)
  (doom-modeline-checker-simple-format nil)
  (doom-modeline-vcs-max-length 20)
  (doom-modeline-github t)
  (doom-modeline-github-interval (* 30 60))
  (doom-modeline-env-version nil)
  (doom-modeline-env-enable-python t)
  (doom-modeline-env-enable-ruby nil)
  (doom-modeline-env-python-executable "python3")
  )

(use-package pulsar
  :ensure t
  :straight
  (:host github :repo "protesilaos/pulsar" :branch "main" :files ("*.el"))
  :config

  (customize-set-variable
   'pulsar-pulse-functions ; Read the doc string for why not `setq'
   '(recenter-top-bottom
     move-to-window-line-top-bottom
     reposition-window
     bookmark-jump
     other-window
     delete-window
     delete-other-windows
     forward-page
     backward-page
     scroll-up-command
     scroll-down-command
     windmove-right
     windmove-left
     windmove-up
     windmove-down
     windmove-swap-states-right
     windmove-swap-states-left
     windmove-swap-states-up
     windmove-swap-states-down
     tab-new
     tab-close
     tab-next
     org-next-visible-heading
     org-previous-visible-heading
     org-forward-heading-same-level
     org-backward-heading-same-level
     outline-backward-same-level
     outline-forward-same-level
     outline-next-visible-heading
     outline-previous-visible-heading
     outline-up-heading))

  (setq pulsar-face 'pulsar-magenta)
  (setq pulsar-delay 0.055)

  ;; integration with the `consult' package:
  (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
  (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry)




  )

;; (use-package beacon
;;   :ensure t
;;   :config

;;   (progn

;;     (setq beacon-color "#00FCB7")
;;     (setq beacon-push-mark 60)

;;     (setq beacon-blink-when-point-moves-vertically nil) ; default nil
;;     (setq beacon-blink-when-point-moves-horizontally nil) ; default nil
;;     (setq beacon-blink-when-buffer-changes t) ; default t
;;     (setq beacon-blink-when-window-scrolls t) ; default t
;;     (setq beacon-blink-when-window-changes t) ; default t
;;     (setq beacon-blink-when-focused t) ; default nil

;;     (setq beacon-blink-duration 0.7) ; default 0.3
;;     (setq beacon-blink-delay 0.1) ; default 0.3
;;     (setq beacon-size 40) ; default 40

;;     (add-to-list 'beacon-dont-blink-major-modes 'term-mode)

;;     (beacon-mode 1)))

(use-package rainbow-mode
  :ensure t
  :hook (prog-mode . rainbow-mode )
  )

(use-package svg-lib
  :ensure t
  )

(use-package neotree
  :ensure t
  :config
  (global-set-key [f8] 'neotree-toggle)
  (setq neo-theme (if (display-graphic-p) 'icons 'arrow))

  )

(use-package treemacs-nerd-icons
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package solaire-mode
  :ensure t
  :config

  (solaire-global-mode +1)


  )

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(use-package which-key
  :ensure t
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.7))

(use-package hydra
  :ensure t
  )

(use-package major-mode-hydra
  :ensure t
  :after all-the-icons
  :demand t
  :config
  (require 'all-the-icons)

  (defun with-faicon (icon str &optional height v-adjust)
    (s-concat (all-the-icons-faicon icon :v-adjust (or v-adjust 0) :height (or height 1)) " " str))

  (defun vl/window-half-height (&optional window)
    (max 1 (/ (1- (window-height window)) 2)))

  (defun vl/scroll-down-half-other-window ()
    (interactive)
    (scroll-other-window
     (vl/window-half-height (other-window-for-scrolling))))
  (defun vl/scroll-up-half-other-window ()
    (interactive)
    (scroll-other-window-down
     (vl/window-half-height (other-window-for-scrolling))))

  (defvar org--title (with-faicon "mars" "Orgy" 1 -0.05))
  (defvar tab-move--title (with-faicon "bomb" "Tabs" 1 -0.05))
  (defvar mc--title (with-faicon "i-cursor" "Multiple Cursors" 1 -0.05))
  (defvar parens--title (with-faicon "rebel" "Smart Parens" 1 -0.05))
  (defvar python--title (with-faicon "code" "Python Clean Up" 1 -0.05))
  (defvar mail--title (with-faicon "male" "Mail" 1 -0.05))
  (defvar music--title (with-faicon "music" "Music" 1 -0.05))
  (defvar slack--title (with-faicon "slack" "Slack" 1 -0.05))


  (pretty-hydra-define jmb/org-mode-hydra
    (:color red :timeout 2 :quit-key "q" :title org--title)
    ("Actions"
     (
      ("t" org-toggle-inline-images "toggle inline images" )
      ("a" org-agenda "org agenda")
      ))
    )

  (pretty-hydra-define jmb/vim-move
    (:color red :timeout 5 :quit-key "q")
    ("Actions"
     (      ("h" backward-char "←")
            ("M-h" backward-word "←")
            ("j" next-line "↓")
            ("k" previous-line "↑")
            ("l" forward-char "→")
            ("M-l" forward-word "→")
            ("a" crux-move-beginning-of-line "")
            ("e" end-of-line  "")
            ))
    )





  (pretty-hydra-define jmb/tab-move
    (:color red :timeout 2 :quit-key "q" :title tab-move--title)
    ("Actions"
     (      ("<left>" centaur-tabs-backward "prev tab")
            ("<right>" centaur-tabs-forward "next tab")
            ("<up>" centaur-tabs-backward-group "prev. group")
            ("<down>" centaur-tabs-forward-group "next group")
            ("k" centaur-tabs-kill-other-buffers-in-current-group "kill all other thabs in this group")
            ))
    )


  (defhydra hydra-window (:color blue :hint nil)
    "
                                                                       ╭─────────┐
     Move to      Size    Scroll        Split                    Do    │ Windows │
  ╭────────────────────────────────────────────────────────────────────┴─────────╯
        ^^            ^_K_^       ^_p_^    ╭─┬─┐^ ^        ╭─┬─┐^ ^         ↺ [_u_] undo layout
        ^^↑^^           ^^↑^^       ^^↑^^    │ │ │_v_ertical ├─┼─┤_b_alance   ↻ [_r_] restore layout
      ←   →     _H_ ←   → _L_   ^^ ^^    ╰─┴─╯^ ^        ╰─┴─╯^ ^         ✗ [_d_] close window
        ^^↓^^           ^^↓^^       ^^↓^^    ╭───┐^ ^        ╭───┐^ ^         ⇋ [_w_] cycle window
        ^^            ^_J_^       ^_n_^    ├───┤_s_tack    │   │_z_oom
        ^^ ^^           ^^ ^^       ^^ ^^    ╰───╯^ ^        ╰───╯^ ^
  --------------------------------------------------------------------------------
            "
    ("<tab>" hydra-master/body "back")
    ("<ESC>" nil "quit")
    ("n" vl/scroll-up-half-other-window :color red)
    ("p" vl/scroll-down-half-other-window :color red)
    ("b" balance-windows)
    ("d" delete-window)
    ("H" shrink-window-horizontally :color red)
    ("<left>" windmove-left :color red)
    ("J" shrink-window :color red)
    ("<down>" windmove-down :color red)
    ("K" enlarge-window :color red)
    ("<up>" windmove-up :color red)
    ("L" enlarge-window-horizontally :color red)
    ("<right>" windmove-right :color red)
    ("r" winner-redo :color red)
    ("s" split-window-vertically :color red)
    ("u" winner-undo :color red)
    ("v" split-window-horizontally :color red)
    ("w" other-window)
    ("z" delete-other-windows))





  (pretty-hydra-define hydra-mc (:color red :title mc--title)

    ("Mark"
     (
      ("a" mc/mark-all-like-this "mark all")
      ("n" mc/mark-next-like-this "mark next")
      ("N" mc/unmark-next-like-this "unmark next")
      ("p" mc/mark-previous-like-this "mark previous")
      ("P" mc/unmark-previous-like-this "unmark previous")
      )
     "Skip"
     (
      ("sn" mc/skip-to-next-like-this "skip to next")
      ("sp" mc/skip-to-previous-like-this "skip to prev")
      )
     "Edit"
     (
      ("e" mc/edit-lines "edit lines" :color blue)
      )
     )
    )

  (defhydra hydra-folding (:color red)
    "
  _o_pen node    _n_ext fold       toggle _f_orward  _s_how current only
  _c_lose node   _p_revious fold   toggle _a_ll
  "
    ("o" origami-open-node)
    ("c" origami-close-node)
    ("n" origami-next-fold)
    ("p" origami-previous-fold)
    ("f" origami-forward-toggle-node)
    ("a" origami-toggle-all-nodes)
    ("s" origami-show-only-node))




  (defhydra hydra-rectangle (:color blue)
    "rectangles"
    ("s" string-rectange "string")
    ("i" string-insert-rectangle "string insert"))





  (pretty-hydra-define hydra-smartparens (:color red :title parens--title)
    ("Move"
     (
      ("f" sp-forward-sexp "forward")
      ("d" sp-backward-sexp "back")
      )
     "Wrap"
     (
      ("(" sp-wrap-round "wrap round")
      ("{" sp-wrap-curly "wrap brace")
      ("[" sp-wrap-square "wrap square")
      ("u" sp-unwrap-sexp "unwrap")
      )
     "Kill"
     (("k" sp-kill-sexp "kill")
      ("K" sp-backward-kill-sexp "backward kill")
      )
     "Slurp Barff"
     (
      ("s" sp-forward-slurp-sexp "forward slurp")
      ("S" sp-backward-slurp-sexp "backward slurp")
      ("b" sp-forward-barf-sexp "forward barf")
      ("B" sp-backward-barf-sexp "backward barf"))
     )
    )




  (defhydra hydra-lsp (:color blue)
    "lsp"
    ("d" lsp-find-definition "find definition")
    ("i" lsp-find-implementation "find implementation")
    ("r" lsp-find-references "find references"))




  (pretty-hydra-define hydra-python-format (:color teal :title python--title)
    ("Format"
     (
      ("f" blacken-buffer "blacken")
      ("i" py-isort-buffer "isort"))
     "Shift"
     (
      ("<right>" tom/shift-right "right")
      ("<left>"  tom/shift-left"left")
      )
     )

    )





  (defhydra hydra-smerge (:color pink
                                 :hint nil
                                 :pre (smerge-mode 1)
                                 ;; Disable `smerge-mode' when quitting hydra if
                                 ;; no merge conflicts remain.
                                 :post (smerge-auto-leave))
    "
^Move^       ^Keep^               ^Diff^                 ^Other^
^^-----------^^-------------------^^---------------------^^-------
_n_ext       _b_ase               _<_: upper/base        _C_ombine
_p_rev       _u_pper (mine)       _=_: upper/lower       _r_esolve
^^           _l_ower              _>_: base/lower        _k_ill current
^^           _a_ll                _R_efine
^^           _RET_: current       _E_diff
"
    ("n" smerge-next)
    ("p" smerge-prev)
    ("b" smerge-keep-base)
    ("u" smerge-keep-upper)
    ("l" smerge-keep-lower)
    ("a" smerge-keep-all)
    ("RET" smerge-keep-current)
    ("\C-m" smerge-keep-current)
    ("<" smerge-diff-base-upper)
    ("=" smerge-diff-upper-lower)
    (">" smerge-diff-base-lower)
    ("R" smerge-refine)
    ("E" smerge-ediff)
    ("C" smerge-combine-with-next)
    ("r" smerge-resolve)
    ("k" smerge-kill-current)
    ("q" nil "cancel" :color blue))



  (pretty-hydra-define my-mu4e-quick (:color blue :title mail--title)
    ("Unread"
     (
      ("w" (mu4e-headers-search "flag:unread AND maildir:/mpe/INBOX") "unread work")
      ("p" (mu4e-headers-search "flag:unread AND maildir:/gmail/INBOX")   "unread personal")

      )
     "Bookmark" (
                 ("t" (mu4e-headers-search "date:today..now AND maildir:/mpe/INBOX")   "today work")
                 ("d" (mu4e-headers-search "Damien AND maildir:/mpe/INBOX") "Damien" )
                 ("j" (mu4e-headers-search "Jochen AND maildir:/mpe/INBOX") "Jochen" )

                 )

     "Org"
     (
      ("o" (org-mime-edit-mail-in-org-mode)  "edit message in org mode")
      ("e" (org-mime-htmlize) "export to html")

      )

     "Utils"
     (
      ("c" (mu4e-compose-new)    "compase a message")
      ("u" (mu4e-update-index) "update")
      )
     )

    )

  (pretty-hydra-define jmb/hydra-music (:color red :timeout 4 :title music--title)
    ("Skip"
     (
      ("n" #'musica-play-next "next")
      ("p" #'musica-play-previous "previous")
      ("r" #'musica-play-next-random "next random"))
     "Search"

     (("s" #'musica-search "search")
      ("i" #'musica-info "info"))
     "Play"(
            ("SPC" #'musica-play-pause "play-pause"))

     ))



  (pretty-hydra-define jmb/hydra-slack (:color red :timeout 4 :title slack--title)
    ("Select"
     (
      ("i" slack-im-select  "im")
      ("c" slack-channel-select "channel")
      ("r" #'musica-play-next-random "next random"))
     "Insert"

     (("e" slack-insert-emoji "emojii")
      )
     "Start"(
             ("s" slack-start "start"))

     ))

  )

(use-package auto-highlight-symbol
  :ensure t
  )

(use-package symbol-navigation-hydra
  :ensure t
  :config


  ;; You'll want a keystroke for bringing up the hydra.
  ;;(global-set-key (kbd "something") 'symbol-navigation-hydra-engage-hydra)

  ;; The hydra is intended for navigation only in the current window.
  (setq-default ahs-highlight-all-windows nil)

  ;; Highlight only while the hydra is active; not upon other circumstances.
  (setq-default ahs-highlight-upon-window-switch nil)
  (setq-default ahs-idle-interval 999999999.0)

  ;; Be case-sensitive, since you are probably using this for code.
  (setq-default ahs-case-fold-search nil)

  ;; Personal preference -- set the default "range" of operation to be the entire buffer.
  (setq-default ahs-default-range 'ahs-range-whole-buffer)

  ;; Same defaults for multiple cursor behavior
  ;;(setq-default mc/always-repeat-command t)
  ;;(setq-default mc/always-run-for-all t)

  ;; You might want this so SN Hydra mutliple cursors can update
  ;; print-statements / doc-strings
  (setq-default ahs-inhibit-face-list (delete 'font-lock-string-face ahs-inhibit-face-list))
  (setq-default ahs-inhibit-face-list (delete 'font-lock-doc-face ahs-inhibit-face-list))




  )

(use-package crux
  :ensure ;TODO: v
  )




(use-package general
  :ensure t
  :config
  (general-define-key
   "C-M-y" 'consult-yank-from-kill-ring
   "M-y" 'consult-yank-pop
   "M-g M-g" 'consult-goto-line
   "M-s" 'isearch-forward
   ;;"C-," 'hydra-mc/body
   "C-<backspace>" 'crux-kill-line-backwards
   [remap move-beginning-of-line] 'crux-move-beginning-of-line
   [remap kill-whole-line] 'crux-kill-whole-line
   [(shift return)] 'crux-smart-open-line
   "C-,"  'hydra-mc/body
   "C-<tab>" 'jmb/tab-move/body
                                        ;"C-M-v" 'hydra-window/body
   "M-j" (lambda () (interactive)
           (join-line -1))
   "C-z" 'avy-goto-char-timer

   "C-h" 'jmb/vim-move/body
   )




  ;; Cc
  (general-define-key
   :prefix "C-c"
   ;;"c" 'org-capture
   ;;"c" telega-prefix-map
   "]" 'hydra-smartparens/body
   "l" 'org-store-link
   "m" 'jmb/hydra-music/body
   "s" 'ispell-word
   "z" 'jmb/org-mode-hydra/body
   "g" 'consult-git-grep

   "i"  (lambda () (interactive)  (chezmoi-find "~/.config/emacs/init.org"))
   "<SPC>" (lambda () (interactive)  (chezmoi-find "~/.config/zsh/.zshrc"))
   "t" 'consult-theme
   "<up>" 'windmove-up
   "<down>" 'windmove-down
   "<left>" 'windmove-left
   "<right>" 'windmove-right

   )

  ;; (general-define-key
  ;;  :prefix "C-q"
  ;;  "h" 'backward-char    ; Move left
  ;;  "l" 'forward-char     ; Move right
  ;;  "j" 'next-line        ; Move down
  ;;  "k" 'previous-line    ; Move up
  ;;  )


  ;; Cx
  (general-define-key
   :prefix "C-x"
   "b" 'consult-buffer
   "m" 'magit-status
   "a" 'ace-jump-mode
   "C-b" 'ibuffer
   "k" 'kill-this-buffer-unless-scratch
   "w" 'elfeed
   "'" 'hydra-window/body
   "/" 'my-mu4e-quick/body
   )

  ( general-def python-mode-map
    "C-c f" 'hydra-python-format/body
    )

  ;; (general-def lsp-mode-map
  ;;   "C-c f" 'lsp-format-buffer
  ;;      )

  (general-def projectile-mode-map
    "s-p" 'projectile-command-map

    )


  )

(use-package easy-kill
  :ensure t
  :bind (([remap kill-ring-save] . #'easy-kill)
         ([remap mark-sexp]      . #'easy-mark)
         :map easy-kill-base-map
         ("," . easy-kill-expand)))

;; (defun read-file (file-path)
;;   (with-temp-buffer
;;     (insert-file-contents file-path)
;;     (buffer-string)))

;; (defun dw/get-current-package-version ()
;;   (interactive)
;;   (let ((package-json-file (concat (eshell/pwd) "/package.json")))
;;     (when (file-exists-p package-json-file)
;;       (let* ((package-json-contents (read-file package-json-file))
;;              (package-json (ignore-errors (json-parse-string package-json-contents))))
;;         (when package-json
;;           (ignore-errors (gethash "version" package-json)))))))

;; (defun dw/map-line-to-status-char (line)
;;   (cond ((string-match "^?\\? " line) "?")))

;; (defun dw/get-
;;     git-status-prompt ()
;;   (let ((status-lines (cdr (process-lines "git" "status" "--porcelain" "-b"))))
;;     (seq-uniq (seq-filter 'identity (mapcar 'dw/map-line-to-status-char status-lines)))))

;; (defun dw/get-prompt-path ()
;;   (let* ((current-path (eshell/pwd))
;;          (git-output (shell-command-to-string "git rev-parse --show-toplevel"))
;;          (has-path (not (string-match "^fatal" git-output))))
;;     (if (not has-path)
;;         (abbreviate-file-name current-path)
;;       (string-remove-prefix (file-name-directory git-output) current-path))))

;; ;; This prompt function mostly replicates my custom zsh prompt setup
;; ;; that is powered by github.com/denysdovhan/spaceship-prompt.
;; (defun dw/eshell-prompt ()
;;   (let (
;;         (package-version (dw/get-current-package-version)))
;;     (concat
;;      "\n"
;;      (propertize (system-name) 'face `(:foreground "#62aeed"))
;;      (propertize " ॐ " 'face `(:foreground "white"))
;;      (propertize (dw/get-prompt-path) 'face `(:foreground "#82cfd3"))
;;      ;; (when current-branch
;;      ;;   (concat
;;      ;;    (propertize " • " 'face `(:foreground "white"))
;;      ;;    (propertize (concat " " current-branch) 'face `(:foreground "#c475f0"))))
;;      ;; (when package-version
;;      ;;   (concat
;;      ;;    (propertize " @ " 'face `(:foreground "white"))
;;      ;;    (propertize package-version 'face `(:foreground "#e8a206"))))
;;      (propertize " • " 'face `(:foreground "white"))
;;      (propertize (format-time-string "%I:%M:%S %p") 'face `(:foreground "#5a5b7f"))
;;      (if (= (user-uid) 0)
;;          (propertize "\n#" 'face `(:foreground "red2"))
;;        (propertize "\nλ" 'face `(:foreground "#aece4a")))
;;      (propertize " " 'face `(:foreground "white")))))



;; (defun dw/eshell-configure ()
;;   (use-package xterm-color)

;;   (push 'eshell-tramp eshell-modules-list)
;;   (push 'xterm-color-filter eshell-preoutput-filter-functions)
;;   (delq 'eshell-handle-ansi-color eshell-output-filter-functions)

;;   ;; Save command history when commands are entered
;;   (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

;;   (add-hook 'eshell-before-prompt-hook
;;             (lambda ()
;;               (setq xterm-color-preserve-properties t)))

;;   ;; Truncate buffer for performance
;;   (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

;;   ;; We want to use xterm-256color when running interactive commands
;;   ;; in eshell but not during other times when we might be launching
;;   ;; a shell command to gather its output.
;;   (add-hook 'eshell-pre-command-hook
;;             (lambda () (setenv "TERM" "xterm-256color")))
;;   (add-hook 'eshell-post-command-hook
;;             (lambda () (setenv "TERM" "dumb")))

;;   ;; Use completion-at-point to provide completions in eshell
;;   (define-key eshell-mode-map (kbd "<tab>") 'completion-at-point)

;;   ;; Initialize the shell history
;;   (eshell-hist-initialize)


;;   (setenv "PAGER" "cat")

;;   (setq eshell-prompt-function      'dw/eshell-prompt
;;         eshell-prompt-regexp        "^λ "
;;         eshell-history-size         10000
;;         eshell-buffer-maximum-lines 10000
;;         eshell-hist-ignoredups t
;;         eshell-highlight-prompt t
;;         eshell-scroll-to-bottom-on-input t
;;         eshell-prefer-lisp-functions nil))

(use-package eshell
  ;;:hook (eshell-first-time-mode . dw/eshell-configure)
  :init
  ;; (setq eshell-directory-name "~/.dotfiles/.emacs.d/eshell/")
  ;; eshell-aliases-file (expand-file-name "~/.dotfiles/.emacs.d/eshell/alias")


  )

(use-package eshell-z
  :hook ((eshell-mode . (lambda () (require 'eshell-z)))
         (eshell-z-change-dir .  (lambda () (eshell/pushd (eshell/pwd))))))

(use-package exec-path-from-shell
  :init
  (setq exec-path-from-shell-check-startup-files nil)
  :config


  ;; (when (memq window-system '(mac ns x))
  ;;   (exec-path-from-shell-initialize))

  (when (memq system-type '(gnu/linux windows-nt darwin))
    (exec-path-from-shell-initialize))


  )





(global-set-key [f5] 'eshell)

(with-eval-after-load 'esh-opt
  (setq eshell-destroy-buffer-when-process-dies t)
  (setq eshell-visual-commands '("htop" "zsh" "vim")))

(use-package eshell-syntax-highlighting
  :after esh-mode
  :config
  (eshell-syntax-highlighting-global-mode +1))

(use-package esh-autosuggest
  :hook (eshell-mode . esh-autosuggest-mode)
  :config
  (setq esh-autosuggest-delay 0.5)
  (set-face-foreground 'company-preview-common "#4b5668")
  (set-face-background 'company-preview nil))

(use-package vterm
  :commands vterm
  :config
  (setq vterm-max-scrollback 10000))

(use-package savehist
  :config
  (setq history-length 50)
  (savehist-mode 1))


(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)


;; (use-package prescient
;;   :ensure t
;;   :config
;;   (setq prescient-history-length 200)
;;   (setq prescient-save-file "~/.config/emacs/prescient-items")
;;   (setq prescient-filter-method '(literal regexp))
;;   (prescient-persist-mode 1)

;;   )

;; (use-package ivy-prescient

;;   :ensure t
;;   :after (prescient ivy)
;;   :config
;;   (setq ivy-prescient-sort-commands
;;         '(:not counsel-grep
;;                counsel-rg
;;                counsel-switch-buffer
;;                ivy-switch-buffer
;;                swiper
;;                swiper-multi))
;;   (setq ivy-prescient-retain-classic-highlighting t)
;;   (setq ivy-prescient-enable-filtering nil)
;;   (setq ivy-prescient-enable-sorting t)
;;   (ivy-prescient-mode 1))

;; Individual history elements can be configured separately
;;(put 'minibuffer-history 'history-length 25)
;;(put 'evil-ex-history 'history-length 50)
;;(put 'kill-ring 'history-length 25))

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
  :straight '(vertico :host github
                      :repo "minad/vertico"
                      :branch "main")
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)
              ("C-f" . vertico-exit)
              :map minibuffer-local-map
              ("M-h" . dw/minibuffer-backward-kill))
  :custom
  (vertico-cycle t)
  :custom-face
  (vertico-current ((t (:background "#880833"))))
  :init
  (vertico-mode)



  )

;; (use-package posframe :demand)
;; (use-package vertico-posframe
;;   :straight (vertico-posframe :host github :repo "tumashu/vertico-posframe")
;;                                         ;:disabled
;;   :config
;;   (setq vertico-posframe-parameters
;;         '((left-fringe . 8)
;;           (right-fringe . 8)
;;           (alpha . 95)
;;           ))
;;   (defun my/posframe-poshandler-p0.5p0-to-f0.5p1 (info)
;;     (let ((x (car (posframe-poshandler-p0.5p0-to-f0.5f0 info)))

;;           (y (cdr (posframe-poshandler-point-1 info nil t))))
;;       (cons x y)))
;;   (setq vertico-posframe-poshandler 'my/posframe-poshandler-p0.5p0-to-f0.5p1)
;;   (vertico-posframe-mode 1))

(use-package company
  :ensure t
  :bind (:map company-active-map
              ("C-n" . company-select-next)
              ("C-p" . company-select-previous))
  :config
  (setq company-idle-delay 0.1)
  (global-company-mode t)
  )

(use-package corfu
  :straight '(corfu :host github
                    :repo "minad/corfu")
  :bind (:map corfu-map
              ("C-j" . corfu-next)
              ("C-k" . corfu-previous)
              ("C-f" . corfu-insert))
  :custom
  (corfu-cycle t)
  :config
  (corfu-global-mode))

(use-package kind-icon
  :ensure t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default) ; to compute blended backgrounds correctly
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package orderless
  :straight t
  :init
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion)))


        )

  )

(defun dw/get-project-root ()
  (when (fboundp 'projectile-project-root)
    (projectile-project-root)))

(use-package consult
  :straight t
  :demand t
  :bind (("C-s" . consult-line)
         ("C-M-l" . consult-imenu)
         ;;("C-M-j" . persp-switch-to-buffer*)
         :map minibuffer-local-map
         ("C-r" . consult-history))
  :custom
  (consult-project-root-function #'dw/get-project-root)
  (completion-in-region-function #'consult-completion-in-region)
  :config
  ;;(consult-preview-mode)
  )

(use-package consult-dir
  :ensure t
  :bind (("C-x C-d" . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file))

  :config

  (setq consult-dir-project-list-function #'consult-dir-projectile-dirs)


  )

(use-package kind-icon
  :ensure t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default) ; to compute blended backgrounds correctly
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package marginalia
  :after vertico
  :straight t
  :custom

  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light t))


  :config
  :init
  (marginalia-mode))


;; (use-package all-the-icons-completion
;;   :ensure t
;;   :init
;;   (all-the-icons-completion-mode)
;;   :hook
;;   (marginalia-mode-hook . all-the-icons-completion-marginalia-setup)

(use-package nerd-icons-completion
  :straight (nerd-icons-completion :type git :host github :repo "rainstormstudio/nerd-icons-completion")
  :after marginalia
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
  :config
  (nerd-icons-completion-mode))

(use-package embark
  :straight t
  :bind (("C-." . embark-act)
         :map minibuffer-local-map
         ("C-." . embark-act))
  :config

  ;; ;; Show Embark actions via which-key
  ;; (setq embark-action-indicator
  ;;       (lambda (map)
  ;;         (which-key--show-keymap "Embark" map nil nil 'no-paging)
  ;;         #'which-key--hide-popup-ignore-command)
  ;;       embark-become-indicator embark-action-indicator)


  )


;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package ace-window
  :bind (("M-o" . ace-window))
  :custom
  (aw-scope 'frame)
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (aw-minibuffer-flag t)
  :config
  (ace-window-display-mode 1))

;; (use-package winner

;;   :config
;;   (winner-mode)
;;   (setq  winner-dont-bind-my-keys t)

;;   )

(defun dw/org-mode-visual-fill ()
  (setq visual-fill-column-width 110
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))


(use-package visual-fill-column
  :defer t
  :hook (org-mode . dw/org-mode-visual-fill))

;; (use-package ace-jump-mode
;;   :ensure t)

;; (use-package popper
;;   :ensure t ; or :straight t
;;   :bind (("C-`"   . popper-toggle-latest)
;;          ("M-`"   . popper-cycle)
;;          ("C-M-`" . popper-toggle-type))
;;   :init
;;   (setq popper-reference-buffers

;;         '("\\*Messages\\*"
;;           "Output\\*$"
;;           "\\*Async Shell Command\\*"
;;           help-mode
;;           compilation-mode
;;           ("^\\*Warnings\\*$" . hide)
;;           ("^\\*Compile-Log\\*$" . hide)
;;           "^\\*Backtrace\\*"
;;           "^\\*Apropos"
;;           "^Calc:"
;;           "^\\*eldoc\\*"
;;           "^\\*TeX errors\\*"
;;           "^\\*ielm\\*"
;;           "^\\*TeX Help\\*"
;;           "\\*Shell Command Output\\*"
;;           ("\\*Async Shell Command\\*" . hide)
;;           "\\*Completions\\*"
;;           ;; "\\*scratch\\*"
;;           "[Oo]utput\\*"


;;           )

;;         )

;;   (popper-mode +1)
;;   (popper-echo-mode +1))

(use-package avy
  :ensure t
  :commands (avy-goto-word-1 avy-goto-char-2 avy-goto-char-timer)
  :config
  (setq avy-timeout-seconds 0.35)
  (setq avy-keys '(?a ?s ?d ?f ?g ?j ?l ?\; ;?x
                      ?v ?b ?n ?, ?/ ?u ?p ?e ?.
                      ?c ?q ?2 ?3 ?'))
  (setq avy-dispatch-alist '((?m . avy-action-mark)
                             (?  . avy-action-mark-to-char)
                             (?i . avy-action-ispell)
                             (?z . avy-action-zap-to-char)
                             (?o . avy-action-embark)
                             (?= . avy-action-define)
                             ;; (?W . avy-action-tuxi)
                             (?h . avy-action-helpful)
                             (?x . avy-action-exchange)

                             (11 . avy-action-kill-line)
                             (25 . avy-action-yank-line)

                             (?w . avy-action-easy-copy)

                             (?k . avy-action-kill-stay)
                             (?y . avy-action-yank)
                             (?t . avy-action-teleport)

                             (?W . avy-action-copy-whole-line)
                             (?K . avy-action-kill-whole-line)
                             (?Y . avy-action-yank-whole-line)
                             (?T . avy-action-teleport-whole-line)))

  (defun avy-action-easy-copy (pt)
    (require 'easy-kill)
    (goto-char pt)
    (cl-letf (((symbol-function 'easy-kill-activate-keymap)
               (lambda ()
                 (let ((map (easy-kill-map)))
                   (set-transient-map
                    map
                    (lambda ()
                      ;; Prevent any error from activating the keymap forever.
                      (condition-case err
                          (or (and (not (easy-kill-exit-p this-command))
                                   (or (eq this-command
                                           (lookup-key map (this-single-command-keys)))
                                       (let ((cmd (key-binding
                                                   (this-single-command-keys) nil t)))
                                         (command-remapping cmd nil (list map)))))
                              (ignore
                               (easy-kill-destroy-candidate)
                               (unless (or (easy-kill-get mark) (easy-kill-exit-p this-command))
                                 (easy-kill-save-candidate))))
                        (error (message "%s:%s" this-command (error-message-string err))
                               nil)))
                    (lambda ()
                      (let ((dat (ring-ref avy-ring 0)))
                        (select-frame-set-input-focus
                         (window-frame (cdr dat)))
                        (select-window (cdr dat))
                        (goto-char (car dat)))))))))
      (easy-kill)))

  (defun avy-action-exchange (pt)
    "Exchange sexp at PT with the one at point."
    (set-mark pt)
    (transpose-sexps 0))

  (defun avy-action-helpful (pt)
    (save-excursion
      (goto-char pt)
      (helpful-at-point))
    (select-window
     (cdr (ring-ref avy-ring 0)))
    t)

  (defun avy-action-define (pt)
    (cl-letf (((symbol-function 'keyboard-quit)
               #'abort-recursive-edit))
      (save-excursion
        (goto-char pt)
        (dictionary-search-dwim))
      (select-window
       (cdr (ring-ref avy-ring 0))))
    t)


  (defun avy-action-embark (pt)
    (unwind-protect
        (save-excursion
          (goto-char pt)
          (embark-act)))
    (select-window
     (cdr (ring-ref avy-ring 0)))
    t)

  (defun avy-action-kill-line (pt)
    (save-excursion
      (goto-char pt)
      (kill-line))
    (select-window
     (cdr (ring-ref avy-ring 0)))
    t)

  (defun avy-action-copy-whole-line (pt)
    (save-excursion
      (goto-char pt)
      (cl-destructuring-bind (start . end)
          (bounds-of-thing-at-point 'line)
        (copy-region-as-kill start end)))
    (select-window
     (cdr
      (ring-ref avy-ring 0)))
    t)

  (defun avy-action-kill-whole-line (pt)
    (save-excursion
      (goto-char pt)
      (kill-whole-line))
    (select-window
     (cdr
      (ring-ref avy-ring 0)))
    t)

  (defun avy-action-yank-whole-line (pt)
    (avy-action-copy-whole-line pt)
    (save-excursion (yank))
    t)

  (defun avy-action-teleport-whole-line (pt)
    (avy-action-kill-whole-line pt)
    (save-excursion (yank)) t)

  (defun avy-action-mark-to-char (pt)
    (activate-mark)
    (goto-char pt))

  (defun my/avy-goto-char-this-window (&optional arg)
    "Goto char in this window with hints."
    (interactive "P")
    (let ((avy-all-windows)
          (current-prefix-arg (if arg 4)))
      (call-interactively 'avy-goto-char)))

  (defun my/avy-isearch (&optional arg)
    "Goto isearch candidate in this window with hints."
    (interactive "P")
    (let ((avy-all-windows)
          (current-prefix-arg (if arg 4)))
      (call-interactively 'avy-isearch)))



  (defun my/avy-copy-line-no-prompt (arg)
    (interactive "p")
    (avy-copy-line arg)
    (beginning-of-line)
    (zap-to-char 1 32)
    (delete-forward-char 1)
    (move-end-of-line 1))


  )

(use-package centaur-tabs
  :demand
  :config
  (centaur-tabs-mode t)
  (centaur-tabs-headline-match)

  (setq centaur-tabs-style "bar")

  (setq centaur-tabs-height 16)
  (setq centaur-tabs-set-modified-marker t)
  (setq centaur-tabs-set-icons t)
  (setq centaur-tabs-set-bar 'under)
  (setq centaur-tabs-cycle-scope 'tabs)

  (centaur-tabs-enable-buffer-reordering)

  ;; When the currently selected tab(A) is at the right of the last visited
  ;; tab(B), move A to the right of B. When the currently selected tab(A) is
  ;; at the left of the last visited tab(B), move A to the left of B
  (setq centaur-tabs-adjust-buffer-order t)

  ;; Move the currently selected tab to the left of the the last visited tab.
  (setq centaur-tabs-adjust-buffer-order 'left)

  ;; Move the currently selected tab to the right of the the last visited tab.
                                        ;(setq centaur-tabs-adjust-buffer-order 'right)


  (centaur-tabs-group-by-projectile-project)


  (defun centaur-tabs-hide-tab (x)
    "Do no to show buffer X in tabs."
    (let ((name (format "%s" x)))
      (or
       ;; Current window is not dedicated window.
       (window-dedicated-p (selected-window))

       ;; Buffer name not match below blacklist.
       (string-prefix-p "*epc" name)
       (string-prefix-p "*helm" name)
       (string-prefix-p "*Helm" name)
       (string-prefix-p "*Compile-Log*" name)
       (string-prefix-p "*lsp" name)
       (string-prefix-p "*company" name)
       (string-prefix-p "*Flycheck" name)
       (string-prefix-p "*tramp" name)
       (string-prefix-p " *Mini" name)
       (string-prefix-p "*help" name)
       (string-prefix-p "*straight" name)
       (string-prefix-p " *temp" name)
       (string-prefix-p "*Help" name)
       (string-prefix-p "*mybuf" name)

       ;; Is not magit buffer.
       (and (string-prefix-p "magit" name)
            (not (file-name-extension name)))
       )))



  ;; :bind
  ;; ("C-<prior>" . centaur-tabs-backward)
  ;; ("C-<next>" . centaur-tabs-forward))

  :hook
  (term-mode . centaur-tabs-local-mode)
  (calendar-mode . centaur-tabs-local-mode)
  (org-agenda-mode . centaur-tabs-local-mode)
  (helpful-mode . centaur-tabs-local-mode)

  )

;(use-package all-the-icons-dired)

(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

(use-package dired
  :ensure nil
  :straight nil
  :defer 1
  :commands (dired dired-jump)
  :config
  (setq dired-listing-switches "-l --almost-all --human-readable --time-style=long-iso --group-directories-first --no-group"
        dired-omit-files "^\\.[^.].*"
        dired-omit-verbose nil
        dired-hide-details-hide-symlink-targets nil
        delete-by-moving-to-trash t)



  (setq dired-use-ls-dired nil)
  ( require 'ls-lisp)
  (setq ls-lisp-use-insert-directory-program nil)
  (autoload 'dired-omit-mode "dired-x")

  (add-hook 'dired-load-hook
            (lambda ()
              (interactive)
              (dired-collapse)))

  (add-hook 'dired-mode-hook
            (lambda ()
              (interactive)
              (dired-omit-mode 1)
              (dired-hide-details-mode 1)

              (hl-line-mode 1))))

(use-package dired-rainbow
  :defer 2
  :config
  (dired-rainbow-define-chmod directory "#6cb2eb" "d.*")
  (dired-rainbow-define html "#eb5286" ("css" "less" "sass" "scss" "htm" "html" "jhtm" "mht" "eml" "mustache" "xhtml"))
  (dired-rainbow-define xml "#f2d024" ("xml" "xsd" "xsl" "xslt" "wsdl" "bib" "json" "msg" "pgn" "rss" "yaml" "yml" "rdata"))
  (dired-rainbow-define document "#9561e2" ("docm" "doc" "docx" "odb" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub" "odp" "ppt" "pptx"))
  (dired-rainbow-define markdown "#ffed4a" ("org" "etx" "info" "markdown" "md" "mkd" "nfo" "pod" "rst" "tex" "textfile" "txt"))
  (dired-rainbow-define database "#6574cd" ("xlsx" "xls" "csv" "accdb" "db" "mdb" "sqlite" "nc"))
  (dired-rainbow-define media "#de751f" ("mp3" "mp4" "mkv" "MP3" "MP4" "avi" "mpeg" "mpg" "flv" "ogg" "mov" "mid" "midi" "wav" "aiff" "flac"))
  (dired-rainbow-define image "#f66d9b" ("tiff" "tif" "cdr" "gif" "ico" "jpeg" "jpg" "png" "psd" "eps" "svg"))
  (dired-rainbow-define log "#c17d11" ("log"))
  (dired-rainbow-define shell "#f6993f" ("awk" "bash" "bat" "sed" "sh" "zsh" "vim"))
  (dired-rainbow-define interpreted "#38c172" ("py" "ipynb" "rb" "pl" "t" "msql" "mysql" "pgsql" "sql" "r" "clj" "cljs" "scala" "js"))
  (dired-rainbow-define compiled "#4dc0b5" ("asm" "cl" "lisp" "el" "c" "h" "c++" "h++" "hpp" "hxx" "m" "cc" "cs" "cp" "cpp" "go" "f" "for" "ftn" "f90" "f95" "f03" "f08" "s" "rs" "hi" "hs" "pyc" ".java"))
  (dired-rainbow-define executable "#8cc4ff" ("exe" "msi"))
  (dired-rainbow-define compressed "#51d88a" ("7z" "zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar" "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
  (dired-rainbow-define packaged "#faad63" ("deb" "rpm" "apk" "jad" "jar" "cab" "pak" "pk3" "vdf" "vpk" "bsp"))
  (dired-rainbow-define encrypted "#ffed4a" ("gpg" "pgp" "asc" "bfe" "enc" "signature" "sig" "p12" "pem"))
  (dired-rainbow-define fonts "#6cb2eb" ("afm" "fon" "fnt" "pfb" "pfm" "ttf" "otf"))
  (dired-rainbow-define partition "#e3342f" ("dmg" "iso" "bin" "nrg" "qcow" "toast" "vcd" "vmdk" "bak"))
  (dired-rainbow-define vc "#0074d9" ("git" "gitignore" "gitattributes" "gitmodules"))
  (dired-rainbow-define-chmod executable-unix "#38c172" "-.*x.*"))

;; (use-package dired-single
;;   :defer t)

;; (use-package dired-ranger
;;   :defer t)

;; (use-package dired-collapse
;;   :defer t)

(use-package dirvish
  :init
  (dirvish-override-dired-mode)
  :custom
  (dirvish-quick-access-entries
   '(("h" "~/" "home")
     ("e" "~/.config/emacs/" "emacs")
     ("p" "~/coding/projects" "projects")
     ("c" "~/.config/" "config")
     ("d" "~/Downloads/" "downloads")
     ))
  (dirvish-mode-line-format
   '(:left (sort file-time " " file-size symlink) :right (omit yank index)))
  ;; Don't worry, Dirvish is still performant even you enable all these attributes
  (dirvish-attributes '(all-the-icons collapse subtree-state vc-state))
  :config
  (setq dired-dwim-target t)
  (setq delete-by-moving-to-trash t)
  (setq dired-use-ls-dired nil)
  ( require 'ls-lisp)
  (setq ls-lisp-use-insert-directory-program nil)
  ;; Enable mouse drag-and-drop files to other applications
  ;; (setq dired-mouse-drag-files t)                   ; added in Emacs 29
  (setq mouse-drag-and-drop-region-cross-program t) ; added in Emacs 29
  ;;(setq dired-listing-switches
  ;;      "-l  --human-readable ")
  :bind
  ;; Bind `dirvish|dirvish-side|dirvish-dwim' as you see fit
  (("C-c f" . dirvish-fd)
   ;; Dirvish has all the keybindings in `dired-mode-map' already
   :map dirvish-mode-map
   ("a"   . dirvish-quick-access)
   ("f"   . dirvish-file-info-menu)
   ("y"   . dirvish-yank-menu)
   ("N"   . dirvish-narrow)
   ("^"   . dirvish-history-last)
   ("h"   . dirvish-history-jump) ; remapped `describe-mode'
   ("s"   . dirvish-quicksort)    ; remapped `dired-sort-toggle-or-edit'
   ("v"   . dirvish-vc-menu)      ; remapped `dired-view-file'
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
  :config

  (add-hook 'ibuffer-hook
            (lambda ()
              (ibuffer-projectile-set-filter-groups)
              (unless (eq ibuffer-sorting-mode 'alphabetic)
                (ibuffer-do-sort-by-alphabetic))))

  (setq ibuffer-formats
        '((mark modified read-only " "
                (name 18 18 :left :elide)
                " "
                (size 9 -1 :right)
                " "
                (mode 16 16 :left :elide)
                " "
                project-relative-file)))



  )



(setq ibuffer-expert t)
(setq ibuffer-show-empty-filter-groups nil)

(add-hook 'ibuffer-mode-hook
          '(lambda ()
             (ibuffer-auto-mode 1)
             (ibuffer-switch-to-saved-filter-groups "home")))


(setq ibuffer-saved-filter-groups
      '(("home"

         ("Org" (or (mode . org-mode)
                    (filename . "OrgMode")))
         ("code" (filename . "code"))
         ("Web Dev" (or (mode . html-mode)
                        (mode . css-mode)))
         ("Subversion" (name . "\*svn"))
         ("Magit" (name . "\*magit"))

         ("ERC" (mode . erc-mode))
         ("Help" (or (name . "\*Help\*")
                     (name . "\*Apropos\*")
                     (name . "\*info\*"))))))


(use-package nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(setq-default fill-column 80)
;; Turn on indentation and auto-fill mode for Org files
(defun dw/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (auto-fill-mode 1)
  (visual-line-mode 1)
                                        ;(diminish org-indent-mode)

  )

(use-package org
                                        ;  :defer t
  :hook (org-mode . dw/org-mode-setup)
  :config
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-hide-block-startup nil
        org-src-preserve-indentation nil
        org-startup-folded 'content
        org-cycle-separator-lines 2)

  (setq org-refile-targets '((nil :maxlevel . 2)
                             (org-agenda-files :maxlevel . 2)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  (setq org-directory "~/Documents/roam")
  (setq org-agenda-files (list "~/Documents/roam/" "~/Documents/roam/journal"))
  ;;  (setq org-default-notes-file "~/org/notes.org")
  (setq org-agenda-file-regexp "\\`[^.].*\\.org\\|.todo\\'")

  (setq org-todo-keywords
        '((sequence "TODO" "READ" "RESEARCH" "|" "DONE" "DELEGATED" )))



  (setq org-default-notes-file (concat org-directory "notes.org"))      ;; some sexier setup

  (setq org-hide-emphasis-markers t)

  ;; (font-lock-add-keywords 'org-mode
  ;;                         '(("^ *\\([-]\\) "
  ;;                            (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  (add-hook 'org-mode-hook 'turn-on-flyspell)
  (setq org-fontify-done-headline t)


  (setq org-todo-keyword-faces
        '(("TODO" . org-warning) ("READ" . "yellow") ("RESEARCH" . (:foreground "blue" :weight bold))
          ("CANCELED" . (:foreground "pink" :weight bold))
          ("WRITING" . (:foreground "red" :weight bold))
          ("RECIEVED" . (:foreground "red" :background "green" :weight bold))
          ("SUBMITTED" . (:foreground "blue"))
          ("ACCEPTED" . (:foreground "green"))


          ))




  )

(use-package org-superstar
  :ensure t
  :after org
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-remove-leading-stars t)
  (org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●"))


  )

;; We can't tangle without org!
(require 'org)

;; Make sure org-indent face is available
(require 'org-indent)

(preserve-font)


;; Get rid of the background on column views
;; (set-face-attribute 'org-column nil :background 'unspecified')
;; (set-face-attribute 'org-column-title nil :background unspecified)

(require 'org-tempo)

(add-to-list 'org-structure-template-alist '("sh" . "src sh"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
(add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
(add-to-list 'org-structure-template-alist '("json" . "src json"))

(use-package org-bullets
  :ensure t
  :after org
  :commands org-bullets-mode
  :init
  (add-hook 'org-mode-hook 'org-bullets-mode)
  )



                                        ;(define-key global-map "\C-cc" 'org-capture)

(setq org-src-fontify-natively t
      org-src-tab-acts-natively t
      org-confirm-babel-evaluate nil
      org-edit-src-content-indentation 0)

;;(require 'org)
(eval-after-load "org"
  '(progn
     (setcar (nthcdr 2 org-emphasis-regexp-components) " \t\n,")
     (custom-set-variables `(org-emphasis-alist ',org-emphasis-alist))))

(use-package org-download
  :ensure t
  :after org

  :defer nil
  :custom
  (org-download-method 'directory)
  (org-download-image-dir "~/Documents/roam/pictures")
  (org-download-heading-lvl nil)
  (org-download-timestamp "%Y%m%d-%H%M%S_")
  (org-image-actual-width 300)
  (org-download-screenshot-method "/opt/homebrew/bin/pngpaste %s")
  :bind
  ("C-M-y" . org-download-screenshot)
  :config
  (require 'org-download))

(use-package org-roam
  :ensure t
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
      :unnarrowed t)

     )
   )

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
                                        ;  (org-roam-db-autosync-mode)


  (org-roam-setup))

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

(add-to-list 'org-after-todo-state-change-hook
             (lambda ()
               (when (equal org-state "DONE")
                 (my/org-roam-copy-todo-to-today))))

(use-package org-roam-ui
  :straight
  (:host github :repo "org-roam/org-roam-ui" :branch "main" :files ("*.el" "out"))
  :after org-roam
  ;;    :hook
  ;;         normally we'd recommend hooking orui after org-roam, but since org-roam does not have
  ;;         a hookable mode anymore, you're advised to pick something yourself
  ;;         if you don't care about startup time, use
  ;;:hook (after-init . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme nil
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package lsp-pyright
  :straight (lsp-pyright :type git :host github :repo "emacs-lsp/lsp-pyright")
  :hook (python-mode . (lambda ()
                         (require 'lsp-pyright)
                         (lsp-deferred)))

  :custom
  (lsp-pyright-use-library-code-for-types t)
  (lsp-pyright-multi-root nil)

  )


(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)


  :custom
  (lsp-auto-guess-root nil)
  (lsp-prefer-flymake nil) ; Use flycheck instead of flymake
  (lsp-disabled-clients '((python-mode . pyls)))

  (lsp-rust-analyzer-cargo-watch-command "clippy")

  ;; enable / disable the hints as you prefer:
  (lsp-rust-analyzer-server-display-inlay-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-parameter-hints nil)
  (lsp-rust-analyzer-display-reborrow-hints nil)

  :config
  (setq lsp-print-performance nil)
  (setq lsp-idle-delay 0.55)
  (setq lsp-enable-symbol-highlighting t)
  (setq lsp-enable-snippet t)
  (setq lsp-restart 'auto-restart)
  (setq lsp-enable-completion-at-point t)
  (setq lsp-log-io t)
  (setq lsp-enable-links nil)




  :hook ((python-mode) . lsp-deferred)
  (yaml-mode . lsp)
  (LaTeX-mode . lsp)
  (latex-mode . lsp)
  (fortran-mode . lsp)
  )



(use-package lsp-ui
  :ensure t
  :config (setq lsp-ui-sideline-show-hover t
                lsp-ui-doc-frame-mode t
                lsp-ui-sideline-delay 3
                lsp-ui-doc-delay 3
                lsp-ui-sideline-ignore-duplicates t
                lsp-headerline-breadcrumb-icons-enable t
                lsp-ui-doc-position 'bottom
                lsp-ui-doc-alignment 'frame
                lsp-ui-doc-header nil
                lsp-ui-doc-include-signature t
                lsp-ui-doc-use-childframe t)

  :commands lsp-ui-mode
  )

(use-package rubocop)

(use-package apheleia
  :ensure t
  :config
  (apheleia-global-mode +1)
  (add-to-list 'apheleia-mode-alist '(python-mode . (ruff isort)))
  (add-to-list 'apheleia-mode-alist '(python-ts-mode . ( ruff isort)))


  )

(use-package flycheck
  :ensure t
  :defer t
  :hook (lsp-mode . flycheck-mode))

(use-package yasnippet                  ; Snippets
  :ensure t
  :hook (prog-mode . yas-minor-mode)
  :config

  (setq yas-snippet-dirs '("~/.config/emacs/snippets"))

  (yas-reload-all)
  )
(use-package yasnippet-snippets         ; Collection of snippets
  :after yasnippet
  :ensure t
  :config (yasnippet-snippets-initialize)

  )

(use-package move-lines
  :straight (move-lines
             :type git
             :host github
             :repo "kinnala/move-lines")
  :after hydra
  :init
  (progn
    (defun tom/shift-left (start end &optional count)
      "Shift region left and activate hydra."
      (interactive
       (if mark-active
           (list (region-beginning) (region-end) current-prefix-arg)
         (list (line-beginning-position) (line-end-position) current-prefix-arg)))
      (python-indent-shift-left start end count)
      (tom/hydra-move-lines/body))

    (defun tom/shift-right (start end &optional count)
      "Shift region right and activate hydra."
      (interactive
       (if mark-active
           (list (region-beginning) (region-end) current-prefix-arg)
         (list (line-beginning-position) (line-end-position) current-prefix-arg)))
      (python-indent-shift-right start end count)
      (tom/hydra-move-lines/body))

    (defun tom/move-lines-p ()
      "Move lines up once and activate hydra."
      (interactive)
      (move-lines-up 1)
      (tom/hydra-move-lines/body))

    (defun tom/move-lines-n ()
      "Move lines down once and activate hydra."
      (interactive)
      (move-lines-down 1)
      (tom/hydra-move-lines/body))


    (defhydra tom/hydra-move-lines (:color blue :timeout 1)
      "Move one or multiple lines"
      ("<down>" move-lines-down "down")
      ("<up>" move-lines-up "up")
      ("<left>" tom/shift-left "left")
      ("<right>" tom/shift-right "right")))

  :bind (("C-c n" . tom/move-lines-n)
         ("C-c p" . tom/move-lines-p))
  )

(use-package smartparens
  :ensure t
  :config
                                        ;  (use-package smartparens-config)
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
        sp-autoinsert-quote-if-followed-by-closing-pair nil)
  :hook (prog-mode . smartparens-mode))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode)
  )

(defun my-highlighter (level responsive display)
  (if (> 1 level)
      nil
    (highlight-indent-guides--highlighter-default level responsive display)))



(use-package highlight-indent-guides
  :ensure t
  :init
  (setq highlight-indent-guides-auto-enabled nil)
  (setq highlight-indent-guides-method 'character)

  (setq highlight-indent-guides-responsive 'stack)
  :config


  (set-face-foreground 'highlight-indent-guides-character-face "#D103CE" )
  (set-face-foreground 'highlight-indent-guides-top-character-face "#5BFFB2")
  (set-face-foreground 'highlight-indent-guides-stack-character-face "#785390")
  (setq highlight-indent-guides-highlighter-function 'my-highlighter)

  :hook (prog-mode . highlight-indent-guides-mode)

  )

;; (use-package dash
;;   :ensure t

;;   )

;; ;; Origami code folding
;; (use-package origami
;;   :ensure t
;;   :commands origami-mode
;;   :config

;;   (global-origami-mode 1)

;;   (progn
;;     (add-hook 'prog-mode-hook 'origami-mode)
;;     (with-eval-after-load 'hydra
;;       (define-key origami-mode-map (kbd "C-x f")
;;         (defhydra hydra-folding (:color red :hint nil)
;;           "
;; _o_pen node    _n_ext fold       toggle _f_orward    _F_ill column: %`fill-column
;; _c_lose node   _p_revious fold   toggle _a_ll        e_x_it
;; "
;;           ("o" origami-open-node)
;;           ("c" origami-close-node)
;;           ("n" origami-next-fold)
;;           ("p" origami-previous-fold)
;;           ("f" origami-forward-toggle-node)
;;           ("a" origami-toggle-all-nodes)
;;           ("F" fill-column)
;;           ("x" nil :color blue))))))

;; (use-package hideshow
;;   :ensure t
;;   :config
;;   (defun hs-cycle (&optional level)
;;     (interactive "p")
;;     (let (message-log-max
;;           (inhibit-message t))
;;       (if (= level 1)
;;           (pcase last-command
;;             ('hs-cycle
;;              (hs-hide-level 1)
;;              (setq this-command 'hs-cycle-children))
;;             ('hs-cycle-children
;;              ;; TODO: Fix this case. `hs-show-block' needs to be
;;              ;; called twice to open all folds of the parent
;;              ;; block.
;;              (save-excursion (hs-show-block))
;;              (hs-show-block)
;;              (setq this-command 'hs-cycle-subtree))
;;             ('hs-cycle-subtree
;;              (hs-hide-block))
;;             (_
;;              (if (not (hs-already-hidden-p))
;;                  (hs-hide-block)
;;                (hs-hide-level 1)
;;                (setq this-command 'hs-cycle-children))))
;;         (hs-hide-level level)
;;         (setq this-command 'hs-hide-level))))

;;   (defun hs-global-cycle ()
;;     (interactive)
;;     (pcase last-command
;;       ('hs-global-cycle
;;        (save-excursion (hs-show-all))
;;        (setq this-command 'hs-global-show))
;;       (_ (hs-hide-all))))

;;   )

(use-package multiple-cursors
  ;;  :disabled
  :ensure t
  :defer nil
  :config

  (setq mc/list-file "~/.config/emacs/mc-lists")

  )

(use-package flyspell
                                        ; nil
  :commands (ispell-change-dictionary
             ispell-word
             flyspell-buffer
             flyspell-mode
             flyspell-region)
  :config
  (setq flyspell-issue-message-flag nil)
  (setq flyspell-issue-welcome-flag nil)
  (setq ispell-program-name "/opt/homebrew/bin/ispell")
  (setq ispell-dictionary "american")
  (add-hook 'text-mode-hook 'flyspell-mode)
  )

;; (use-package ghub
;;   :ensure t


;;   )

;; (use-package ghub+
;;   :ensure t


;;   )

(use-package magit
  :ensure t
  :demand t
  :bind ( ("s-g" . magit-status))
  ;; :commands (magit-status magit-get-current-branch)
  ;;  :custom
  ;; (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)


  )

;; (use-package git-commit
;;   :ensure t
;;   :after magit
;;   :config
;;   (setq git-commit-summary-max-length 50)
;;   (setq git-commit-known-pseudo-headers
;;         '("Signed-off-by"
;;           "Acked-by"
;;           "Modified-by"
;;           "Cc"
;;           "Suggested-by"
;;           "Reported-by"
;;           "Tested-by"
;;           "Reviewed-by"))
;;   (setq git-commit-style-convention-checks
;;         '(non-empty-second-line
;;           overlong-summary-line)))


(use-package git-timemachine
  :ensure t
  :commands git-timemachine)

;; (use-package forge
;;   :ensure t
;;   :after magit)

;; (use-package magit-todos
;;   :ensure t

;;   :defer t)

;; (defun dw/switch-project-action ()
;;   "Switch to a workspace with the project name and start `magit-status'."
;;   ;; TODO: Switch to EXWM workspace 1?
;;   (persp-switch (projectile-project-name))
;;   (magit-status))


(use-package projectile
                                        ;:diminish projectile-mode
  :config (projectile-mode)
  :demand t
  ;; :bind-keymap
  ;; ("C-c p" . projectile-command-map)
  :init
  (when (file-directory-p "~/coding/projects")
    (setq projectile-project-search-path '("~/coding/projects" "~/coding/projects") ))
  )

(use-package py-isort
  :ensure t
  :after python
  )

(use-package blacken
  :after python
  :init
  (setq-default blacken-fast-unsafe t)
  (setq-default blacken-line-length 80)
  )

                                        ; direnv mode allows automatic loading of direnv variables
(use-package direnv
  :ensure t
  :config
  (direnv-mode))



(use-package pyvenv
  :ensure t
  :config

  (pyvenv-tracking-mode 1)

  (setq pyvenv-mode-line-indicator
        '(pyvenv-virtual-env-name ("<" pyvenv-virtual-env-name "> "  )))

  (pyvenv-mode 1)


  )


(use-package python-mode
  :ensure nil
  :straight nil
  :hook
  (python-mode . pyvenv-mode)
  (python-mode . company-mode)
  (python-mode . yas-minor-mode)
  :custom
  ;; NOTE: Set these if Python 3 is called "python3" on your system!
  (python-shell-interpreter "python3")
  (python-shell-interpreter-args "-i")
  :config

  ;; (progn
  ;;   (defhydra python-indent (python-mode-map "C-c TAB")
  ;;     "Adjust python indentation."
  ;;     ("k" py-shift-right "right")
  ;;     ("j" py-shift-left "left")
  ;;     ("<right>" py-shift-right "right")
  ;;     ("<left>" py-shift-left "left")

  ;;     )
  ;;   )

  (yas-reload-all)
  )

(use-package sphinx-doc
  :ensure t
  :hook (python-mode . sphinx-doc-mode)
  :config
  (setq sphinx-doc-include-types t)

  )

;; (setq python-shell-interpreter "python3"
;;       python-shell-interpreter-args "-i")


(defun wcx-restart-python ()
  (pyvenv-restart-python))

;; Uncomment the line below if not required elsewhere.
;; (require 'use-package)

                                        ;stan-mode.el
(use-package stan-mode
  :straight
  (:host github :repo "stan-dev/stan-mode" :branch "master" :files ("stan-mode/stan-mode.el" "stan-mode/stan-keywords.el"))
  ;;  :ensure t
  :mode (("\\.stan\\'" . stan-mode)
         ("\\.stanfunctions\\'" . stan-mode))
  :hook (stan-mode . stan-mode-setup)

  :config
  ;; The officially recommended offset is 2.
  (setq stan-indentation-offset 2))


(use-package company-stan
  :ensure t
  :hook (stan-mode . company-stan-setup)
  ;;
  :config
  ;; Whether to use fuzzy matching in `company-stan'
  (setq company-stan-fuzzy t))


(use-package eldoc-stan
  :ensure t
  :hook (stan-mode . eldoc-stan-setup)
  ;;
  :config
  ;; No configuration options as of now.
  )


(use-package flycheck-stan
  ;; Add a hook to setup `flycheck-stan' upon `stan-mode' entry
  :ensure t
  :hook ((stan-mode . flycheck-stan-stanc2-setup)
         (stan-mode . flycheck-stan-stanc3-setup))
  :config
  ;; A string containing the name or the path of the stanc2 executable
  ;; If nil, defaults to `stanc2'
  (setq flycheck-stanc-executable nil)
  ;; A string containing the name or the path of the stanc2 executable
  ;; If nil, defaults to `stanc3'
  (setq flycheck-stanc3-executable nil))


(use-package stan-snippets
  :ensure t
  :hook (stan-mode . stan-snippets-initialize)
  ;;
  :config
  ;; No configuration options as of now.
  )

    ;;; ac-stan.el (Not on MELPA; Need manual installation)
;; (use-package ac-stan
;;   :load-path "path-to-your-directory/ac-stan/"
;;   ;; Delete the line below if using.
;;   :disabled t
;;   :hook (stan-mode . stan-ac-mode-setup)
;;   ;;
;;   :config
;;   ;; No configuration options as of now.
;;   )


;;   ;; No configuration options as of now.
;;   )

(use-package julia-mode
  :ensure t
  )

(use-package lsp-julia
  :config
  (setq lsp-julia-default-environment "~/.julia/environments/v1.7"))

(use-package yaml-mode
  :ensure t
  :mode ("\\.yml$" . yaml-mode)
  )

(use-package auctex
  :defer t
  :ensure t)


(use-package reftex
  :defer t
  :ensure t)



(use-package latex
  :straight (:type built-in)                           ; nil
  :mode
  ("\\.tex\\'" . latex-mode)
  :bind
  (:map LaTeX-mode-map
        ("M-<delete>" . TeX-remove-macro)
        ("C-c C-r" . reftex-query-replace-document)
        ("C-c C-g" . reftex-grep-document))
  :init


  :config

  (setq-default TeX-master nil ; by each new fie AUCTEX will ask for a master fie.
                TeX-PDF-mode t
                TeX-engine 'xetex)     ; optional
  (auto-fill-mode 1)
  (setq TeX-auto-save t
        TeX-save-query nil       ; don't prompt for saving the .tex file
        TeX-parse-self t
        TeX-show-compilation nil         ; if `t`, automatically shows compilation log
        LaTeX-babel-hyphen nil ; Disable language-specific hyphen insertion.
        ;; `"` expands into csquotes macros (for this to work, babel pkg must be loaded after csquotes pkg).
        LaTeX-csquotes-close-quote "}"
        LaTeX-csquotes-open-quote "\\enquote{"
        TeX-file-extensions '("Rnw" "rnw" "Snw" "snw" "tex" "sty" "cls" "ltx" "texi" "texinfo" "dtx"))


  (setq reftex-plug-into-AUCTeX t)
  (setq reftex-default-bibliography '("/Users/jburgess/Documents/complete_bib.bib"))

  (add-to-list 'safe-local-variable-values
               '(TeX-command-extra-options . "-shell-escape"))

  ;; Font-lock for AuCTeX
  ;; Note: '«' and '»' is by pressing 'C-x 8 <' and 'C-x 8 >', respectively
  (font-lock-add-keywords 'latex-mode (list (list "\\(«\\(.+?\\|\n\\)\\)\\(+?\\)\\(»\\)" '(1 'font-latex-string-face t) '(2 'font-latex-string-face t) '(3 'font-latex-string-face t))))
  ;; Add standard Sweave file extensions to the list of files recognized  by AuCTeX.
  (add-hook 'TeX-mode-hook (lambda () (reftex-isearch-minor-mode)))
  (add-hook 'LaTeX-mode-hook #'TeX-fold-mode) ;; Automatically activate TeX-fold-mode.
  (add-hook 'LaTeX-mode-hook 'TeX-fold-buffer t)

  :hook (

         (LaTeX-mode . reftex-mode)
         (LaTeX-mode . visual-line-mode)
         (LaTeX-mode . flyspell-mode)
         (LaTeX-mode . LaTeX-math-mode)
         (LaTeX-mode . turn-on-reftex)

         )
  )

(use-package bibtex
  :mode (("\\.bib\\'" . bibtex-mode)))

(use-package markdown-mode
  :straight t
  :mode "\\.md\\'"
  :config
  (setq markdown-command "marked")
  (defun dw/set-markdown-header-font-sizes ()
    (dolist (face '((markdown-header-face-1 . 1.2)
                    (markdown-header-face-2 . 1.1)
                    (markdown-header-face-3 . 1.0)
                    (markdown-header-face-4 . 1.0)
                    (markdown-header-face-5 . 1.0)))
      (set-face-attribute (car face) nil :weight 'normal :height (cdr face))))

  (defun dw/markdown-mode-hook ()
    (dw/set-markdown-header-font-sizes))

  (add-hook 'markdown-mode-hook 'dw/markdown-mode-hook))

(use-package dockerfile-mode
  :defer t
  :straight
  (:host github :repo "spotify/dockerfile-mode" :branch "master" :files ("*.el" "out"))

  :config

  (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode))


  )



(use-package docker-compose-mode
  :ensure t

  )

(use-package json-mode
  :ensure t

  )

(use-package clojure-mode
  :ensure t
  :mode (("\\.clj\\'" . clojure-mode)
         ("\\.edn\\'" . clojure-mode))
  :init
  (add-hook 'clojure-mode-hook #'yas-minor-mode)
  (add-hook 'clojure-mode-hook #'subword-mode)
  (add-hook 'clojure-mode-hook #'smartparens-mode)
  (add-hook 'clojure-mode-hook #'rainbow-delimiters-mode)
  (add-hook 'clojure-mode-hook #'eldoc-mode)
  (add-hook 'clojure-mode-hook #'idle-highlight-mode))

(use-package clj-refactor
  :defer t
  :ensure t
  :diminish clj-refactor-mode
  :config (cljr-add-keybindings-with-prefix "C-c C-m"))

(use-package cider
  :ensure t
  :defer t
  :init (add-hook 'cider-mode-hook #'clj-refactor-mode)
  :diminish subword-mode
  :config
  (setq nrepl-log-messages t
        cider-repl-display-in-current-window t
        cider-repl-use-clojure-font-lock t
        cider-prompt-save-file-on-load 'always-save
        cider-font-lock-dynamically '(macro core function var)
        nrepl-hide-special-buffers t
        cider-overlays-use-font-lock t)
  (cider-repl-toggle-pretty-printing))

(use-package go-mode
  :init
  (defun lsp-go-install-save-hooks ()
    (add-hook 'before-save-hook #'lsp-format-buffer t t)
    (add-hook 'before-save-hook #'lsp-organize-imports t t))
  (add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

  ;; Start LSP Mode and YASnippet mode
  (add-hook 'go-mode-hook #'lsp-deferred)
  (add-hook 'go-mode-hook #'yas-minor-mode)

  )

(use-package rustic
  :ensure
  :bind (:map rustic-mode-map
              ("M-j" . lsp-ui-imenu)
              ("M-?" . lsp-find-references)
              ("C-c C-c l" . flycheck-list-errors)
              ("C-c C-c a" . lsp-execute-code-action)
              ("C-c C-c r" . lsp-rename)
              ("C-c C-c q" . lsp-workspace-restart)
              ("C-c C-c Q" . lsp-workspace-Ctshutdown)
              ("C-c C-c s" . lsp-rust-analyzer-status))
  :config
  ;; uncomment for less flashiness
  ;; (setq lsp-eldoc-hook nil)
  ;; (setq lsp-enable-symbol-highlighting nil)
  ;; (setq lsp-signature-auto-activate nil)

  ;; comment to disable rustfmt on save
  (setq rustic-format-on-save t)
  )

;;use-package

;; load mu4e from the installation path.
;; yours might differ check with the Emacs installation

;; (use-package htmlize
;;   :ensure t
;;   )

;; (use-package org-mime
;;   :ensure t
;;   )

;; (use-package mu4e
;;   :load-path  " /opt/homebrew/share/emacs/site-lisp/mu/mu4e/"
;;   :straight nil

;;   :config

;;   (require 'org-mime)

;;   ;; for sending mails
;;   (require 'smtpmail)


;;   ;; we installed this with homebrew
;;   (setq mu4e-mu-binary (executable-find "mu"))

;;   ;; this is the directory we created before:
;;   (setq mu4e-maildir "~/.maildir")

;;   ;; this command is called to sync imap servers:
;;   (setq mu4e-get-mail-command (concat (executable-find "mbsync") " -a"))
;;   ;; how often to call it in seconds:
;;   (setq mu4e-update-interval (* 2 60))

;;   (setq mu4e-index-update-error-warning nil)
;;   ;; save attachment to desktop by default
;;   ;; or another choice of yours:
;;   (setq mu4e-attachment-dir "~/Downloads")

;;   ;; rename files when moving - needed for mbsync:
;;   (setq mu4e-change-filenames-when-moving t)

;;   ;; list of your email adresses:
;;   (setq mu4e-user-mail-address-list '("jmichaelburgess@gmail.com"
;;                                       "jburgess@mpe.mpg.de"
;;                                       ))


;;   ;; check your ~/.maildir to see how the subdirectories are called
;;   ;; for the generic imap account:
;;   ;; e.g `ls ~/.maildir/example'
;;   (setq   mu4e-maildir-shortcuts
;;           '(

;;             ("/gmail/INBOX" . ?g)
;;             ("/gmail/[Gmail]/Sent Mail" . ?G)
;;             ("/mpe/INBOX" . ?m)
;;             ("/mpe/Sent" . ?M)))






;;   (setq mu4e-contexts
;;         `(
;;           ,(make-mu4e-context
;;             :name "gmail"
;;             :enter-func
;;             (lambda () (mu4e-message "Enter jmichaelburgess@gmail.com context"))
;;             :leave-func
;;             (lambda () (mu4e-message "Leave jmichaelburgess@gmail.com context"))
;;             :match-func
;;             (lambda (msg)
;;               (when msg
;;                 (mu4e-message-contact-field-matches msg
;;                                                     :to "jmichaelburgess@gmail.com")))
;;             :vars '((user-mail-address . "jmichaelburgess@gmail.com")
;;                     (user-full-name . "J. Michael Burgess")
;;                     (mu4e-drafts-folder . "/gmail/Drafts")
;;                     (mu4e-refile-folder . "/gmail/Archive")
;;                     (mu4e-sent-folder . "/gmail/Sent")
;;                     (mu4e-trash-folder . "/gmail/Trash")
;;                     (mu4e-compose-signature  .
;;                                              (concat
;;                                               "-----\n"
;;                                               "/J. Michael\n"
;;                                               "sent from emacs without a mouse\n"))
;;                     )
;;             )

;;           ,(make-mu4e-context
;;             :name "mpe"
;;             :enter-func
;;             (lambda () (mu4e-message "Enter jburgess@mpe.mpg.de context"))
;;             :leave-func
;;             (lambda () (mu4e-message "Leave jburgess@mpe.mpg.de context"))
;;             :match-func
;;             (lambda (msg)
;;               (when msg
;;                 (mu4e-message-contact-field-matches msg
;;                                                     :to "jburgess@mpe.mpg.de")))
;;             :vars '((user-mail-address . "jburgess@mpe.mpg.de")
;;                     (user-full-name . "J. Michael Burgess")

;;                     (mu4e-compose-signature  .
;;                                              (concat
;;                                               "-----\n"
;;                                               "/J. Michael\n"
;;                                               "sent from emacs without a mouse\n"))
;;                     (mu4e-drafts-folder . "/mpe/Drafts")
;;                     (mu4e-refile-folder . "/mpe/Archive")
;;                     (mu4e-sent-folder . "/mpe/Sent")
;;                     (mu4e-trash-folder . "/mpe/Trash")))))

;;   (setq mu4e-context-policy 'pick-first) ;; start with the first (default) context;
;;   (setq mu4e-compose-context-policy 'ask) ;; ask for context if no context matches;



;;   ;; gpg encryptiom & decryption:
;;   ;; this can be left alone
;;   (require 'epa-file)
;;   (epa-file-enable)
;;   (setq epa-pinentry-mode 'loopback)
;;   (auth-source-forget-all-cached)

;;   ;; don't keep message compose buffers around after sending:
;;   (setq message-kill-buffer-on-exit t)

;;   ;; send function:
;;   (setq send-mail-function 'sendmail-send-it
;;         message-send-mail-function 'sendmail-send-it)

;;   ;; send program:
;;   ;; this is exeranal. remember we installed it before.
;;   (setq sendmail-program (executable-find "msmtp"))

;;   ;; select the right sender email from the context.
;;   (setq message-sendmail-envelope-from 'header)

;;   ;; chose from account before sending
;;   ;; this is a custom function that works for me.
;;   ;; well I stole it somewhere long ago.
;;   ;; I suggest using it to make matters easy
;;   ;; of course adjust the email adresses and account descriptions
;;   (defun timu/set-msmtp-account ()
;;     (if (message-mail-p)
;;         (save-excursion
;;           (let*
;;               ((from (save-restriction
;;                        (message-narrow-to-headers)
;;                        (message-fetch-field "from")))
;;                (account
;;                 (cond

;;                  ((string-match "jmichaelburgess@gmail.com" from) "gmail")
;;                  ((string-match "jburgess@mpe.mpg.de" from) "example"))))
;;             (setq message-sendmail-extra-arguments (list '"-a" account))))))

;;   (add-hook 'message-send-mail-hook 'timu/set-msmtp-account)

;;   ;; mu4e cc & bcc
;;   ;; this is custom as well
;;   (add-hook 'mu4e-compose-mode-hook
;;             (defun timu/add-cc-and-bcc ()
;;               "My Function to automatically add Cc & Bcc: headers.
;;     This is in the mu4e compose mode."
;;               (save-excursion (message-add-header "Cc:\n"))
;;               (save-excursion (message-add-header "Bcc:\n"))))

;;   ;; mu4e address completion
;;   (add-hook 'mu4e-compose-mode-hook 'company-mode)


;;   ;; store link to message if in header view, not to header query:
;;   (setq org-mu4e-link-query-in-headers-mode nil)
;;   ;; don't have to confirm when quitting:
;;   (setq mu4e-confirm-quit nil)
;;   ;; number of visible headers in horizontal split view:
;;   (setq mu4e-headers-visible-lines 20)
;;   ;; don't show threading by default:
;;   (setq mu4e-headers-show-threads t)
;;   ;; hide annoying "mu4e Retrieving mail..." msg in mini buffer:
;;   (setq mu4e-hide-index-messages t)
;;   ;; customize the reply-quote-string:
;;   (setq message-citation-line-format "%N @ %Y-%m-%d %H:%M :\n")
;;   ;; M-x find-function RET message-citation-line-format for docs:
;;   (setq message-citation-line-function 'message-insert-formatted-citation-line)
;;   ;; by default do not show related emails:
;;   (setq mu4e-headers-include-related nil)
;;   ;; by default do not show threads:
;;   (setq mu4e-headers-show-threads nil)
;;   :init



;;   (setq org-mu4e-convert-to-html t)

;;   (setq org-mime-export-options '(:section-numbers nil
;;                                                    :with-author nil
;;                                                    :with-toc nil))

;;   (add-hook 'org-mime-html-hook
;;             (lambda ()
;;               (org-mime-change-element-style
;;                "pre" (format "color: %s; background-color: %s; padding: 0.5em;"
;;                              "#5EFFA5" "#211F20"))))

;;   (global-set-key [f6] 'mu4e)
;;   )

;; (use-package mu4e-column-faces
;;   :ensure t
;;   :after mu4e
;;   :config (mu4e-column-faces-mode 1))


;; (use-package mu4e-thread-folding
;;   :straight (mu4e-thread-folding :type git :host github :repo "rougier/mu4e-thread-folding")
;;   :init
;;   (add-to-list 'mu4e-header-info-custom
;;                '(:empty . (:name "Empty"
;;                                  :shortname ""
;;                                  :function (lambda (msg) "  "))))
;;   (setq mu4e-headers-fields '((:empty         .    1)
;;                               (:human-date    .   12)
;;                               (:from          .   22)
;;                               (:flags         .    6)
;;                               (:mailing-list  .   10)

;;                               (:subject       .   nil)))
;;   :config

;;   (define-key mu4e-headers-mode-map (kbd "<tab>")     'mu4e-headers-toggle-at-point)
;;   (define-key mu4e-headers-mode-map (kbd "<left>")    'mu4e-headers-fold-at-point)
;;   (define-key mu4e-headers-mode-map (kbd "<S-left>")  'mu4e-headers-fold-all)
;;   (define-key mu4e-headers-mode-map (kbd "<right>")   'mu4e-headers-unfold-at-point)
;;   (define-key mu4e-headers-mode-map (kbd "<S-right>") 'mu4e-headers-unfold-all)

;;   )

;; (use-package mu4e-marker-icons
;;   :ensure t
;;   :init (mu4e-marker-icons-mode 1))

;; (use-package slack
;;   :commands (slack-start)
;;   :init
;;   (setq slack-buffer-emojify t) ;; if you want to enable emoji, default nil
;;   (setq slack-prefer-current-team t)
;;   :config

;;   (slack-register-team
;;    :name "hemato"
;;    :default t
;;    :token (auth-source-pick-first-password
;;            :host "hema-to.slack.com"
;;            :user "jmichael@hema.to")
;;    :cookie (auth-source-pick-first-password
;;             :host "hema-to.slack.com"
;;             :user "jmichael@hema.to^cookie")

;;    :subscribed-channels '(general ml_club office tech research off-topic)
;;    :full-and-display-names t)


;;   )

;; (use-package alert
;;   :commands (alert)
;;   :init
;;   (setq alert-default-style 'osx-notifier))

(use-package redacted
  :ensure t
  :straight
  (:host github :repo "bkaestner/redacted.el" :branch "main" :files ("*.el"))
  :init
  (global-set-key [f2] 'redacted-mode)
  )

(use-package darkroom
  :ensure t
  :commands darkroom-mode
  :defer t
  :config
  (setq darkroom-text-scale-increase 0))

(use-package focus
  :ensure t
  :defer t
  )

(setq telega-server-libs-prefix "/opt/homebrew/")



(use-package tracking
  :defer nil
  :config
  (setq tracking-faces-priorities '(all-the-icons-pink
                                    all-the-icons-lgreen
                                    all-the-icons-lblue))
                                        ;(setq tracking-frame-behavior nil)
  )

(use-package visual-fill-column
  :ensure t
  )

(use-package rainbow-identifiers
  :ensure t
  )


(use-package telega
  ;; :stright
  ;; ((:host github :repo "zevlg/telega.el" :branch "master" :files ("*.el")))
  :commands telega
  :config


  (setq telega-user-use-avatars t
        telega-use-tracking-for '(unread)
        telega-chat-use-markdown-formatting t
        telega-emoji-use-images t
        telega-msg-rainbow-title t
        telega-use-images t
        telega-chat-fill-column 100
        telega-use-docker t
        telega-translate-to-language-by-default t
        )

  (add-hook 'telega-load-hook 'telega-mode-line-mode)
  :init
  (global-set-key [f1] 'telega)
  (define-key global-map (kbd "C-c c") telega-prefix-map)

  (telega-mode-line-mode 1)

  )
                                        ;  (define-key global-map (kbd "f12") telega-prefix-map)

(use-package csv-mode
  :ensure t
  )

(use-package elfeed-org
  :ensure t
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files (list "~/org/rss.org"))
  )




(defun concatenate-authors (authors-list)
  "Given AUTHORS-LIST, list of plists; return string of all authors
concatenated."
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

    ;; (when feed-title
    ;;   (insert (propertize entry-authors
    ;; 'face 'elfeed-search-feed-face) " "))

    (when entry-authors
      (insert (propertize feed-title
                          'face 'elfeed-search-feed-face) " "))

    ;; (when tags
    ;;   (insert "(" tags-str ")"))

    )
  )



(use-package elfeed
  :ensure t
  :config
  ;;  (global-set-key (kbd "C-x w") 'elfeed)


  (setq elfeed-search-print-entry-function #'my-search-print-fn)

  )


(use-package elfeed-score
  :ensure t
  :config


  (setq   elfeed-score-serde-score-file "~/.config/emacs/elfeed.score")
  (elfeed-score-enable)
  (define-key elfeed-search-mode-map "=" elfeed-score-map)


  )

(defun musica-index ()
  "Indexes Music's tracks in two stages:
1. Generates \"Tracks.sqlite\" using pytunes (needs https://github.com/hile/pytunes installed).
2. Caches an index at ~/.emacs.d/.musica.el."
  (interactive)
  (message "Indexing music... started")
  (let* ((now (current-time))
         (name "Music indexing")
         (buffer (get-buffer-create (format "*%s*" name))))
    (with-current-buffer buffer
      (delete-region (point-min)
                     (point-max)))
    (set-process-sentinel
     (start-process name
                    buffer
                    (file-truename (expand-file-name invocation-name
                                                     invocation-directory))
                    "--quick" "--batch" "--eval"
                    (prin1-to-string
                     `(progn
                        (interactive)
                        (require 'cl-lib)
                        (require 'seq)
                        (require 'map)

                        (message "Generating Tracks.sqlite...")
                        (process-lines "pytunes" "update-index") ;; Generates Tracks.sqlite
                        (message "Generating Tracks.sqlite... done")

                        (defun parse-tags (path)
                          (with-temp-buffer
                            (if (eq 0 (call-process "ffprobe" nil t nil "-v" "quiet"
                                                    "-print_format" "json" "-show_format" path))
                                (map-elt (json-parse-string (buffer-string)
                                                            :object-type 'alist)
                                         'format)
                              (message "Warning: Couldn't read track metadata for %s" path)
                              (message "%s" (buffer-string))
                              (list (cons 'filename path)))))

                        (let* ((paths (process-lines "sqlite3"
                                                     (concat (expand-file-name "~/")
                                                             "Music/Music/Music Library.musiclibrary/Tracks.sqlite")
                                                     "select path from tracks"))
                               (total (length paths))
                               (n 0)
                               (records (seq-map (lambda (path)
                                                   (let ((tags (parse-tags path)))
                                                     (message "%d/%d %s" (setq n (1+ n))
                                                              total (or (map-elt (map-elt tags 'tags) 'title) "No title"))
                                                     tags))
                                                 paths)))
                          (with-temp-buffer
                            (prin1 records (current-buffer))
                            (write-file "~/.config/emacs/.musica.el" nil))))))
     (lambda (process state)
       (if (= (process-exit-status process) 0)
           (message "Indexing music... finished"
                                        ;    (float-time (time-subtract (current-time) now))

                    )
         (message "Indexing music... failed, see" )))


     )))


(defun musica-search ()
  (interactive)
  (cl-assert (executable-find "pytunes") nil "pytunes not installed")
  (let* ((c1-width (round (* (- (window-width) 9) 0.4)))
         (c2-width (round (* (- (window-width) 9) 0.3)))
         (c3-width (- (window-width) 9 c1-width c2-width)))
    (completing-read "Play: " (mapcar
                               (lambda (track)
                                 (let-alist track
                                   (cons (format "%s   %s   %s"
                                                 (truncate-string-to-width
                                                  (or .tags.title
                                                      (file-name-base .filename)
                                                      "No title") c1-width nil ?\s "…")
                                                 (truncate-string-to-width (propertize (or .tags.artist "")
                                                                                       'face '(:foreground "yellow")) c2-width nil ?\s "…")
                                                 (truncate-string-to-width
                                                  (propertize (or .tags.album "")
                                                              'face '(:foreground "cyan1")) c3-width nil ?\s "…"))
                                         track)))
                               (musica--index))
                     :action (lambda (selection)
                               (let-alist (cdr selection)
                                 (process-lines "pytunes" "play" .filename)
                                 (message "Playing: %s [%s] %s"
                                          (or .tags.title
                                              (file-name-base .filename)
                                              "No title")
                                          (or .tags.artist
                                              "No artist")
                                          (or .tags.album
                                              "No album")))))))

(defun musica--index ()
  (with-temp-buffer
    (insert-file-contents "~/.config/emacs/.musica.el")
    (read (current-buffer))))


(defun musica-info ()
  (interactive)
  (let ((raw (process-lines "pytunes" "info")))
    (message "%s [%s] %s"
             (string-trim (string-remove-prefix "Title" (nth 3 raw)))
             (string-trim (string-remove-prefix "Artist" (nth 1 raw)))
             (string-trim (string-remove-prefix "Album" (nth 2 raw))))))

(defun musica-play-pause ()
  (interactive)
  (cl-assert (executable-find "pytunes") nil "pytunes not installed")
  (process-lines "pytunes" "play")
  (musica-info))

(defun musica-play-next ()
  (interactive)
  (cl-assert (executable-find "pytunes") nil "pytunes not installed")
  (process-lines "pytunes" "next"))

(defun musica-play-next-random ()
  (interactive)
  (cl-assert (executable-find "pytunes") nil "pytunes not installed")
  (process-lines "pytunes" "shuffle" "enable")
  (let-alist (seq-random-elt (musica--index))
    (process-lines "pytunes" "play" .filename))
  (musica-info))

(defun musica-play-previous ()
  (interactive)
  (cl-assert (executable-find "pytunes") nil "pytunes not installed")
  (process-lines "pytunes" "previous"))

;; (use-package chatgpt-shell
;;   :ensure t
;;   :config
;;   (setq chatgpt-shell-openai-key
;;         (auth-source-pick-first-password :host "api.openai.com"))
;;   )




;; (use-package gptel
;;   :defer t
;;   :config
;;   (setq gptel-api-key "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")

;;   )

(use-package regex-tool
  :ensure t
  :config
  (setq regex-tool-backend "Perl")
  )

;; (use-package erc-hl-nicks
;;   :after erc)

;; (use-package erc-image
;;   :after erc)


;; (use-package erc
;;   :commands erc
;;   :config
;;   (setq erc-server "localhost"
;;         erc-nick "jburgess"    ; Change this!
;;         erc-user-full-name "J Michael Burgess"  ; And this!
;;         erc-track-shorten-start 8
;;         erc-track-position-in-mode-line t
;;                                         ;        erc-autojoin-channels-alist '((""))
;;         erc-kill-buffer-on-part t
;;         erc-auto-query 'bury
;;         erc-track-exclude-types '("JOIN" "NICK" "PART" "QUIT" "MODE"
;;                                   "324" "329" "332" "333" "353" "477")
;;                                         ;erc-join-buffer 'bury
;;         erc-modules
;;         '(autoaway autojoin button completion fill irccontrols keep-place
;;                    list match menu move-to-prompt netsplit networks noncommands
;;                    readonly ring stamp track hl-nicks))






;;   (defvar bitlbee-password "slapitup")

;;   (add-hook 'erc-join-hook 'bitlbee-identify)
;;   (defun bitlbee-identify ()
;;     "If we're on the bitlbee server, send the identify command to the
;;  &bitlbee channel."
;;     (when (and (string= "localhost" erc-session-server)
;;                (string= "&bitlbee" (buffer-name)))
;;       (erc-message "PRIVMSG" (format "%s identify %s"
;;                                      (erc-default-target)
;;                                      bitlbee-password))))


;;   )

(add-hook 'after-init-hook (lambda () (add-hook 'after-init-hook (lambda () (load-theme 'solarized-light)))
                             ))
