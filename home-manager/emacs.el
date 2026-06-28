;;; init.el --- Description -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "29.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:
;;(org-babel-load-file
;; (expand-file-name
;;  "config.org"
;;  user-emacs-directory))

(eval-when-compile
        (require 'use-package))

(set-face-attribute 'default nil
                    :font "0xProto"
                    :height 110)

(set-face-attribute 'variable-pitch nil
                    :font "EB Garamond"
                    :height 156)

(set-face-attribute 'fixed-pitch nil
                    :font "0xProto"
                    :height 110)

(set-face-attribute 'font-lock-comment-face nil
                    :font "0xProto Italic"
                    :slant 'italic)

(set-face-attribute 'font-lock-string-face nil)

(menu-bar-mode   -1)
(tool-bar-mode   -1)
(scroll-bar-mode -1)

(indent-tabs-mode nil)
(setq tab-stop-list '(4 8))

(global-display-line-numbers-mode 1)
(global-visual-line-mode t)
(delete-selection-mode t)

;; TODO Figure out why this feature breaks
(setq shift-select-mode t)

(with-eval-after-load 'eldoc
  (eldoc-add-command 'doom/escape))

(use-package undo-fu
  :demand t
  :config
  (setq undo-limit 67108864)          ; 64mb.
  (setq undo-strong-limit 100663296)  ; 96mb.
  (setq undo-outer-limit 1006632960)) ; 960mb.

(use-package undo-fu-session
  :demand t
  :config
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
  (undo-fu-session-global-mode))

(use-package evil
  :demand t
  :init
  (setq
        evil-search-module       'evil-search
        evil-split-window-below  t
        evil-undo-system         'undo-fu
        evil-vsplit-window-right t
        evil-want-fine-undo      t
        evil-want-integration    t
        evil-want-keybinding     nil
	evil-want-minibuffer     t
	)
  (evil-mode ))

(use-package evil-collection
  :demand t
  :after evil
  :config
  (setq evil-collection-mode-list '(company
	  consult
	  dashboard
	  dired
	  flycheck
	  ibuffer
	  magit
	  minibuffer
	  org
	  org-roam
	  rg
	  vertico
	  which-key
	  xref))
  (evil-collection-init))

(use-package evil-tutor)

(defun open-config ()
  "Open Configuration (init.el) file."
  (interactive)
  (find-file (file-truename "~/.config/emacs/init.el")))

(defun reload-config ()
  "Reload Configuration (init.el) file."
  (interactive)
  (load-file "~/.config/emacs/init.el"))

(defun org-capture-inbox ()
  "Org capture to inbox."
  (interactive)
  (call-interactively 'org-store-link)
  (org-capture nil "i"))

(use-package general
  :demand t
  :after (evil evil-collection)
  :init
  (general-setq general-override-states
		'(insert
                  emacs
                  hybrid
                  normal
                  visual
                  motion
                  operator
                  replace))
  :config
  (general-override-mode)
  (general-evil-setup)
  

  (general-create-definer tyrant-def
    :states '(normal visual motion emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "C-SPC")

  (tyrant-def
    "SPC" '(project-find-file        :wk "Find file")
    ","   '(switch-to-buffer         :wk "Switch buffer")
    "/"   '(consult-ripgrep          :wk "Search project")
    ":"   '(execute-extended-command :wk "M-x")

    "h"   '(:ignore t         :wk "Help")
    "h f" '(describe-function :wk "Describe function")
    "h v" '(describe-variable :wk "Describe variable")

    "h c"   '(:ignore t     :wk "Config stuff")
    "h c c" '(open-config   :wk "Open config")
    "h c r" '(reload-config :wk "Reload config")
   

    "b"   '(:ignore t           :wk "Buffer operations")
    "b b" '(switch-to-buffer    :wk "Switch buffer")
    "b i" '(ibuffer             :wk "Use ibuffer")
    "b d" '(kill-current-buffer :wk "Kill buffer")
    "b [" '(next-buffer         :wk "Next buffer")
    "b ]" '(previous-buffer     :wk "Previous buffer")
    "b r" '(revert-buffer       :wk "Reload buffer")
    "b e" '(eval-buffer         :wk "Evaluate buffer")

    "c"   '(:ignore t              :wk "Code menu")
    "c c" '(compile                :wk "Compile code")
    "c d" '(xref-find-definitions  :wk "Jump to definition")
    "c l" 'lsp-command-map
    "c r" '(xref-find-references   :wk "Find references")
    "c f" '(lsp-format-buffer      :wk "Format buffer")
    "c a" '(lsp-execute-code-action :wk "Code action")
    "c r" '(lsp-rename             :wk "Rename symbol")

    "f"   '(:ignore t :wk "File operations")
    "f f" '(find-file :wk "Find file")
    "f u" '(:ignore t :wk "TODO: Open file with root")

    "g"   '(:ignore t :wk "Git")
    "g g" '(magit-status          :wk "Magit status")
    "g b" '(magit-blame           :wk "Magit blame")
    "g l" '(magit-log-buffer-file :wk "Magit log (current file)")
    "g d" '(magit-diff-unstaged   :wk "Magit diff")
    "g r" (cons "Git" 'magit-mode-map)

    "p"   (cons "Projects" project-prefix-map)

    ;; The Search menu
    "s"   '(:ignore t :wk "Search")
    "s b" '(swiper :wk "Search buffer") 
    "s d" '(consult-ripgrep :wk "Search directory")
    "s p" '(rg-project :wk "Search project (rg package)")
    "s i" '(consult-imenu :wk "Search symbols (imenu)")

    "v" '(:ignore t                   :wk "Change viewing details")
    "v l" '(display-line-numbers-mode :wk "Toggle line numbers")
    "v t" '(visual-line-mode          :wk "Toggle trucated lines")
    "v z" '(global-text-scale-adjust  :wk "Zoom")

    "w"         '(:ignore t          :wk "Window Operations")
    "w o"       '(evil-window-down   :wk "Navi down")
    "w <down>"  '(evil-window-down   :wk "Navi down")
    "w ,"       '(evil-window-up     :wk "Navi up")
    "w <up>"    '(evil-window-up     :wk "Navi up")
    "w a"       '(evil-window-left   :wk "Navi left")
    "w <left>"  '(evil-window-left   :wk "Navi left")
    "w e"       '(evil-window-right  :wk "Navi right")
    "w <right>" '(evil-window-right  :wk "Navi right")
    "w v"       '(evil-window-vsplit :wk "split window vertical")
    "w s"       '(evil-window-split  :wk "split window horizonatal")
    "w d"       '(evil-window-delete :wk "exit window")

    "q"         '(:ignore t  :wk "Emacs Menu")
    "q q"       '(kill-emacs :wk "Quit")

    "o"    '(:ignore t           :wk "Org Mode")
    "o o"  '(org-open-at-point   :wk "Open here")
    "o a"  '(org-agenda          :wk "Org Agenda")
    "o l"  '(org-store-link      :wk "Org store link")
    "o c"  '(org-capture         :wk "Org capture")
    "o i"  '(org-capture-inbox   :wk "Org capture inbox")
    "o r"  '(org-roam-node-find  :wk "Org Roam Find")
    ))

(use-package which-key
  :demand t
  :config (setq
           which-key-side-window-location       'bottom
           which-key-sort-order                 'which-key-key-order-alpha
           which-key-sort-uppercase-first       nil
           which-key-add-column-padding         1
           which-key-max-display-columns        3
           which-key-min-display-lines          6
           which-key-side-window-slot           -10
           which-key-idle-delay                 0.2
           which-key-max-description-length     65
           which-key-allow-imprecise-window-fit t
           which-key-show-docstrings            t
           which-key-separator                  " → ")
  (which-key-mode))

(use-package project
 :demand t
 :config
  (setq project-switch-commands
        '((magit-project-status "Git status" "g")
          (project-find-file "Choose File" "f")))) 

(use-package magit
  :demand t
  :config
  (setq magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1)) 

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t))

(use-package doom-modeline
  :demand t
  :config
  (doom-modeline-mode))

(use-package rg
  :demand t)

(use-package company
  :demand t
  :general
  (general-unbind
   '(company-active-map)
  "<return>"
  "RET"
  "TAB"
  "C-g")
  (general-define-key
   :keymaps     'company-active-map
   "S-<return>" '(company-complete-selection :wk "company complete")
   "S-TAB"      '(company-complete-common-or-cycle)
  )
  :config
  (global-company-mode))

(use-package emacs
  :custom
  (context-menu-mode t)
  (enable-recursive-minibuffer t)
  (read-extended-command-predicate
    #'command-completion-default-include-p)
  (minibuffer-prompt-properties
    '(read-only t cursor-intangible t face minibuffer-prompt)))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

(use-package vertico
  :demand t
  :custom
    (vertico-cycle t)
  :init
    (vertico-mode))

(use-package vertico-directory
  :demand t
  :after vertico
  :bind (:map vertico-map
	      ("RET" . vertico-directory-enter))
  :hook (rfn-eshadow-update-overlay . vertico-diretory-tidy))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) 
  (completion-pcm-leading-wildcard t)) 

(use-package consult
  :demand t
  :config 
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  )

(use-package marginalia
  :demand t
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))

(use-package flycheck
  :demand t
  :init
  (global-flycheck-mode))

(use-package smartparens
  :demand t
  :hook (prog-mode haskell-mode) ;; add `smartparens-mode` to these hooks
  :config
  ;; load default config
  (require 'smartparens-config))

(use-package envrc
  :demand t
  :hook (after-init . envrc-global-mode))

(use-package treemacs)

(use-package treemacs-evil
  :after (treemacs evil))

(use-package flycheck-aspell
  :demand t
  :after flycheck)

(use-package flycheck-haskell
  :demand t
  :after (haskell-mode flycheck))
;; Language support
;; TODO, nix, python, lua, json, org roam, latex, c/c++, rust, sh, yaml, md
(use-package haskell-mode
  :demand t
  :config
  :hook (haskell-mode . haskell-indentation-mode))

(use-package cc-mode
  :demand t
  )
(use-package nix-mode
  :demand t
  )

(use-package lsp-nix
  :demand t
  :defer t)
(use-package lsp-haskell
  :demand t
  :defer t)

(use-package lsp-mode
  :demand t
  :after (which-key)
  :hook ((haskell-mode . lsp-deferred)
	 (cc-mode      . lsp-deferred)
	 (nix-mode     . lsp-deferred)
         (lsp-mode     . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred))

(use-package lsp-ui :commands lsp-ui-mode)

;; if you are ivy user
;;(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
;;(use-package lsp-treemacs :commands lsp-treemacs-errors-list)

(use-package rainbow-delimiters
  :demand t
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package bookmark
  :demand t
  :config
  (setq bookmark-save-flag 1
        bookmark-fringe-mark nil))

(use-package editorconfig
  :demand t
  :config
  (setq editorconfig-lisp-use-default-indent t)
  :hook (prog-mode . editorconfig-mode))

(use-package tramp
  :demand t)

(use-package org
  :init
  (setq org-directory "~/Sync/Org/"
        org-agenda-files '("inbox.org" "agenda.org")
	org-capture-templates `(("i" "Inbox" entry (file "inbox.org")
				 ,(concat "* TODO %?\n"
					  "/Entered on/ %U"))
				("m" "Meeting" entry (file+headline "agenda.org" "Future")
				 ,(concat "* %? :meeting:\n"
					  "<%<%Y-%m-%d %a %H:00>>"))))
  :demand t)

(use-package org-roam
  :demand t
  :init
  (setq org-roam-directory (file-truename "~/Sync/Org/roam"))
  (org-roam-db-autosync-mode)
  )

(use-package evil-surround
  :demand t
  :config
  (global-evil-surround-mode 1))

(use-package ligature
  :demand t
  :load-path "path-to-ligature-repo"
  :config
  ;; Enable the "www" ligature in every possible major mode
  (ligature-set-ligatures 't '("www"))
  ;; Enable traditional ligature support in eww-mode, if the
  ;; `variable-pitch' face supports it
  (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
  ;; Enable all Cascadia and Fira Code ligatures in programming modes
  ;; :<|>
  (ligature-set-ligatures 'prog-mode
                        '(;; == === ==== => =| =>>=>=|=>==>> ==< =/=//=// =~
                          ;; =:= =!=
                          ("=" (rx (+ (or ">" "<" "|" "/" "~" ":" "!" "="))))
                          ;; ;; ;;;
                          (";" (rx (+ ";")))
                          ;; && &&&
                          ("&" (rx (+ "&")))
                          ;; !! !!! !. !: !!. != !== !~
                          ("!" (rx (+ (or "=" "!" "\." ":" "~"))))
                          ;; ?? ??? ?:  ?=  ?.
                          ("?" (rx (or ":" "=" "\." (+ "?"))))
                          ;; %% %%%
                          ("%" (rx (+ "%")))
                          ;; |> ||> |||> ||||> |] |} || ||| |-> ||-||
                          ;; |->>-||-<<-| |- |== ||=||
                          ;; |==>>==<<==<=>==//==/=!==:===>
                          ("|" (rx (+ (or ">" "<" "|" "/" ":" "!" "}" "\]"
                                          "-" "=" ))))
                          ;; \\ \\\ \/
                          ("\\" (rx (or "/" (+ "\\"))))
                          ;; ++ +++ ++++ +>
                          ("+" (rx (or ">" (+ "+"))))
                          ;; // /// //// /\ /* /> /===:===!=//===>>==>==/
                          ("/" (rx (+ (or ">"  "<" "|" "/" "\\" "\*" ":" "!"
                                          "="))))
                          ;; .. ... .... .= .- .? ..= ..<
                          ("\." (rx (or "=" "-" "\?" "\.=" "\.<" (+ "\."))))
                          ;; -- --- ---- -~ -> ->> -| -|->-->>->--<<-|
                          ("-" (rx (+ (or ">" "<" "|" "~" "-"))))
                          ;; *> */ *)  ** *** ****
                          ("*" (rx (or ">" "/" ")" (+ "*"))))
                          ;; www wwww
                          ("w" (rx (+ "w")))
                          ;; <> <!-- <|> <: <~ <~> <~~ <+ <* <$ </  <+> <*>
                          ;; <$> </> <|  <||  <||| <|||| <- <-| <-<<-|-> <->>
                          ;; <<-> <= <=> <<==<<==>=|=>==/==//=!==:=>
                          ;; << <<< <<<<
                          ("<" (rx (+ (or "\+" "\*" "\$" "<" ">" ":" "~"  "!"
                                          "-"  "/" "|" "="))))
                          ;; :: ::: :::: :> :< := :// ::= :<|>
                          (":" (rx (or "<|>" ">" "<" "=" "//" ":=" (+ ":"))))
                          ;; >: >- >>- >--|-> >>-|-> >= >== >>== >=|=:=>>
                          ;; >> >>> >>>>
                          (">" (rx (+ (or ">" "<" "|" "/" ":" "=" "-"))))
                          ;; #: #= #! #( #? #[ #{ #_ #_( ## ### #####
                          ("#" (rx (or ":" "=" "!" "(" "\?" "\[" "{" "_(" "_"
                                       (+ "#"))))
                          ;; ~~ ~~~ ~=  ~-  ~@ ~> ~~>
                          ("~" (rx (or ">" "=" "-" "@" "~>" (+ "~"))))
                          ;; __ ___ ____ _|_ __|____|_
                          ("_" (rx (+ (or "_" "|"))))
                          ;; Fira code: 0xFF 0x12
                          ("0" (rx (and "x" (+ (in "A-F" "a-f" "0-9")))))
                          ;; Monaspace's Textual healing
                          "im" "imi" "mi" "iw" "iwi" "wi"
                          "jm" "jmj"  "mj" "jw" "jwj" "wj"
                          "jmi" "imj" "jwi" "iwj"
                          ;; Fira code:
                          "Fl"  "Tl"  "fi"  "fj"  "fl"  "ft"
                          ;; The few not covered by the regexps.
                          "{|"  "[|"  "]#"  "(*"  "}#"  "$>"  "^="))
  ;; Enables ligature checks globally in all buffers. You can also do it
  ;; per mode with `ligature-mode'.
  (global-ligature-mode t))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(safe-local-variable-directories '("/home/daniel/dev/ghc/rts/")))

(provide 'init)
;;; init.el ends here
