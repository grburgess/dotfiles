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
