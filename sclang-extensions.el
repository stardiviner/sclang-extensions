;;; sclang-extensions.el --- Extensions for the SuperCollider Emacs mode.

;; Copyright (C) 2013 Chris Barrett

;; Author: Chris Barrett <chris.d.barrett@me.com>
;; Version: 2.2.9
;; Package-Requires: ((auto-complete "1.4.0")(s "1.3.1")(dash "1.2.0")(emacs "24.1"))
;; Keywords: sclang supercollider languages tools

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Extensions for the SuperCollider Emacs mode. Each extension is implemented as
;; a minor-mode; you can enable them individually, or enable all of them by
;; activating `sclang-extensions-mode'.

;;; Installation:

;; Add this mode to your sclang hooks:
;;
;;   (add-hook 'sclang-mode-hook 'sclang-extensions-mode)
;;

;;; Code:

(require 'sclang-ac-mode)
(require 'sclang-doc-mode)
(require 'sclang-post-mode)
(require 'dash)

(defgroup sclang-extensions nil
  "Extensions to the SuperCollider (sclang) Emacs mode."
  :group 'languages)

(defcustom sclang-bury-post-on-start? t
  "Whether to bury the sclang Post buffer when starting the mode.
The Post buffer becomes much less useful when you use `sclang-post-mode'."
  :group 'sclang-extensions
  :type 'boolean)

;;; ----------------------------------------------------------------------------

(defun scl:visual-expression-start ()
  "Return the beginning of the current expression.
Ignore trailing semicolons and whitespace.
Return the position of the first non-whitespace char."
  (save-excursion
    (while (and (or (scl:char-before-point-looking-at? (rx (any space "\n" ";"))))
                (not (bobp)))
      (forward-char -1))
    (-when-let (pos (scl:expression-start-pos))
      (goto-char pos)
      (when (search-forward-regexp (rx (not (any space "\n"))) nil t)
        (unless (bobp)
          (forward-char -1))))
    (point)))

;;;###autoload
(defun sclang-eval-last-expression ()
  "Evaluate the sclang expression before point."
  (interactive)
  (->> (buffer-substring-no-properties (scl:visual-expression-start) (point))
    (scl:blocking-eval-string)
    (scl:print-post-message)))

;;;###autoload
(defun sclang-expression-start ()
  "Move to the start of the sclang expression before point."
  (interactive)
  (-when-let (pos (scl:visual-expression-start))
    (goto-char pos)))

;;;###autoload
(defvar sclang-extensions-mode-map
  (let ((km (make-keymap)))
    (define-key km (kbd "M-a") 'sclang-expression-start)
    (define-key km (kbd "C-x C-e") 'sclang-eval-last-expression)
    km))

(defvar sclang-extensions-mode-hook nil
  "Hook run after `sclang-extensions-mode' is initialized.")

(defun scl:bury-post-buffer ()
  "Hide the SuperCollider Post buffer."
  (when (boundp 'sclang-post-buffer)
    (--each (--filter (equal sclang-post-buffer (buffer-name (window-buffer it)))
                      (window-list))
      (delete-window it))))

;;;###autoload
(define-minor-mode sclang-extensions-mode
  "Enable all extensions to the sclang Emacs mode."
  nil " scl" sclang-extensions-mode-map
  (cond

   ;; Enable mode.
   (sclang-extensions-mode
    (when sclang-bury-post-on-start?
      (scl:bury-post-buffer)
      (add-hook 'sclang-mode-hook 'scl:bury-post-buffer t))

    (sclang-ac-mode +1)
    (sclang-doc-mode +1)
    (sclang-post-mode +1)
    (run-hooks 'sclang-extensions-mode-hook))

   ;; Disable mode.
   (t
    ;; Deactivate minor modes.
    (remove-hook 'sclang-mode-hook 'scl:bury-post-buffer t)
    (sclang-ac-mode -1)
    (sclang-post-mode -1)
    (sclang-doc-mode -1))))

(provide 'sclang-extensions)

;; Local Variables:
;; lexical-binding: t
;; End:

;;; sclang-extensions.el ends here
