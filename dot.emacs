;;--------------------------------------------------------------------------------
;; CMAKE mode
;;--------------------------------------------------------------------------------

; Add cmake listfile names to the mode list.
(setq auto-mode-alist
	  (append
	   '(("CMakeLists\\.txt\\'" . cmake-mode))
	   '(("\\.cmake\\'" . cmake-mode))
	   auto-mode-alist))

(autoload 'cmake-mode "/usr/share/cmake-3.10/editors/emacs/cmake-mode.el" t)

;;--------------------------------------------------------------------------------
;; Custom emacs variables
;;--------------------------------------------------------------------------------

(custom-set-variables
  ;; custom-set-variables was added by Custom -- don't edit or cut/paste it!
  ;; Your init file should contain only one such instance.
 '(case-fold-search t)
 '(current-language-environment "ASCII")
 '(font-lock-maximum-decoration t)
 '(font-lock-use-colors t)
 '(font-lock-use-fonts nil)
 '(tool-bar-mode nil nil (tool-bar))
 '(scroll-mode nil)
 '(scroll-bar-mode nil)
 '(global-font-lock-mode t nil (font-lock)))

;;--------------------------------------------------------------------------------
;; FORTH
;;--------------------------------------------------------------------------------

;; forth mode
(autoload 'forth-mode "gforth.el")
(autoload 'forth-block-mode "gforth.el")
(add-to-list 'auto-mode-alist '("\\.fs$" . forth-mode))

;;--------------------------------------------------------------------------------
;; Color themes
;;--------------------------------------------------------------------------------

(when (display-graphic-p)
  (set-face-attribute 'default nil :font "Noto Mono-10" ))

(require 'color-theme)
(defun color-theme-djcb-dark ()
  "dark color theme created by djcb, Jan. 2009."
  (interactive)
  (color-theme-install
    '(color-theme-djcb-dark
       ((foreground-color . "#a9eadf")
         (background-color . "black")
         (background-mode . dark))
       (bold ((t (:bold t))))
       (bold-italic ((t (:italic t :bold t))))
       (default ((t (nil))))

       (font-lock-builtin-face ((t (:italic t :foreground "#a96da0"))))
       (font-lock-comment-face ((t (:italic t :foreground "#bbbbbb"))))
       (font-lock-comment-delimiter-face ((t (:foreground "#666666"))))
       (font-lock-constant-face ((t (:bold t :foreground "#197b6e"))))
       (font-lock-doc-string-face ((t (:foreground "#3041c4"))))
       (font-lock-doc-face ((t (:foreground "gray"))))
       (font-lock-reference-face ((t (:foreground "white"))))
       (font-lock-function-name-face ((t (:foreground "#356da0"))))
       (font-lock-keyword-face ((t (:bold t :foreground "#bcf0f1"))))
       (font-lock-preprocessor-face ((t (:foreground "#e3ea94"))))
       (font-lock-string-face ((t (:foreground "#ffffff"))))
       (font-lock-type-face ((t (:bold t :foreground "#364498"))))
       (font-lock-variable-name-face ((t (:foreground "#7685de"))))
       (font-lock-warning-face ((t (:bold t :italic nil :underline nil
                                     :foreground "yellow"))))
       (hl-line ((t (:background "#112233"))))
       (mode-line ((t (:foreground "#ffffff" :background "#333333"))))
       (region ((t (:foreground nil :background "#555555"))))
       (show-paren-match-face ((t (:bold t :foreground "#ffffff"
                                    :background "#050505")))))))

;;(color-theme-djcb-dark)
(setq color-theme-is-global t)
(color-theme-initialize)
;;(color-theme-billw)
;;(color-theme-aalto-light)
;;(color-theme-clarity)
;;(color-theme-scintilla)
;;(color-theme-goldenrod)
(color-theme-deep-blue)

;;--------------------------------------------------------------------------------
;; C++ setup
;;--------------------------------------------------------------------------------

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))

(defun my-c-indent-setup ()
  (c-set-style "k&r")
  (setq c-basic-offset 4)
  (setq indent-tabs-mode nil))
(add-hook 'c-mode-hook 'my-c-indent-setup)

(defun my-c++-indent-setup ()
  (c-set-style "linux")
  (setq c-basic-offset 4)
  (setq tab-width 4 )
  (setq indent-tabs-mode nil))
  (c-set-offset 'innamespace '0)
  (c-set-offset 'inextern-lang '0)
  (c-set-offset 'inline-open '0)
  (c-set-offset 'label '*)
  (c-set-offset 'case-label '*)
  (c-set-offset 'access-label '/)
(add-hook 'c++-mode-hook 'my-c++-indent-setup)

(add-hook 'before-save-hook 'delete-trailing-whitespace)

(setq-default tab-width 4)
(setq-default py-indent-offset 4)
(setq-default indent-tabs-mode nil)
(setq minibuffer-max-depth nil)
(setq buffers-menu-max-size 40)
(setq inhibit-splash-screen t)

;;(setq x-select-enable-primary t)
(setq x-select-enable-clipboard t) ; as above
(setq interprogram-paste-function 'x-cut-buffer-or-selection-value)
;;(global-set-key "\C-y" 'clipboard-yank)

(global-set-key "\C-P" 'recompile )
;;(global-set-key "\C-P" 'cyclebuffer-forward)
;;(global-set-key "\C-N" 'cyclebuffer-backward)
(global-set-key (kbd "<f8>") 'next-buffer)
(global-set-key (kbd "<f7>") 'previous-buffer)

(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(setq column-number-mode t)
(setq line-number-mode t)

;;--------------------------------------------------------------------------------
;; Python setup
;;--------------------------------------------------------------------------------

 ;; Set up initialization parameters for python mode:
(add-hook 'python-mode-hook
      (lambda ()
         (setq indent-tabs-mode nil)
         (setq tab-width 4 )
         (setq python-indent 4)))

;;--------------------------------------------------------------------------------
;; YAML setup
;;--------------------------------------------------------------------------------

(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\.yml$" . yaml-mode))

;;--------------------------------------------------------------------------------
;; PROLOG setup
;;--------------------------------------------------------------------------------

;; swi-prolog
(setq auto-mode-alist (append (list (cons "\\.pl$" 'prolog-mode)) auto-mode-alist))
