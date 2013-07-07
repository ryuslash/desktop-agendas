;;; desktop-agendas.el --- Change agendas based on desktop  -*- lexical-binding: t -*-

;; Copyright (C) 2013  Tom Willemse

;; Author: Tom Willemse <tom@ryuslash.org>
;; Keywords: convenience
;; Package-Requires: ((dash "1.2.0"))
;; Version: 0.1.0

;; This program is free software; you can redistribute it and/or modify
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

;;

;;; Code:

(require 'dash)
(require 'desktop)

(eval-when-compile
  (require 'org))

(defgroup desktop-agendas nil
  "Desktop agendas."
  :group 'desktop)

(defcustom desktop-agendas nil
  "Specification for agendas."
  :group 'desktop-agendas
  :type '(repeat (cons symbol (repeat file))))

(defvar desktop-agendas--changing-dir nil
  "Are we changing desktop directories?")

(defun desktop-agendas--get-matched-files (desktop)
  "Get the appropriate agenda files according to DESKTOP.

If DESKTOP is t all registered agenda files will be returned.  If
DESKTOP is a symbol it indicates the list of agenda files to use,
with the list with t as its car appended."
  (-distinct
   (-flatten
    (delq nil (mapcar
               (lambda (lst)
                 (let ((sym (car lst)))
                   (when (or (eql desktop t)
                             (eql desktop sym)
                             (eql t sym))
                     (cdr lst))))
               desktop-agendas)))))

(defun desktop-agendas-set ()
  "Set some org settings according to the loaded desktop.

If ALL is non-nil set `org-agenda-files' and `org-refile-targets'
to all registered agenda files, otherwise set them to the values
specified for the current desktop."
  (let ((agenda-files
         (desktop-agendas--get-matched-files
          (or (not desktop-dirname)
              (intern (file-name-base
                       (directory-file-name
                        (expand-file-name desktop-dirname))))))))
    (if agenda-files
        (setq org-agenda-files agenda-files
              org-refile-targets `((,agenda-files))))))

(defadvice desktop-change-dir
  (around desktop-agendas-change-dir activate)
  "Ensure desktop agendas knows a directory change is happening."
  (let ((desktop-agendas--changing-dir t))
    ad-do-it))

(defadvice desktop-clear (after desktop-agendas-clear activate)
  "Reset `org-agenda-files' to all files."
  (when (and desktop-agendas-mode (not desktop-agendas--changing-dir))
    (desktop-agendas-set)))

;;;###autoload
(define-minor-mode desktop-agendas-mode
  "A minor mode that changes the org agenda files according to
the loaded desktop."
  :global t
  (if desktop-agendas-mode
      (progn
        (add-hook 'desktop-after-read-hook 'desktop-agendas-set)
        (add-hook 'desktop-no-desktop-file-hook 'destkop-agendas-reset)
        (ad-enable-advice 'desktop-change-dir 'around
                          'desktop-agendas-change-dir)
        (ad-enable-advice 'desktop-clear 'after 'desktop-agendas-clear))
    (remove-hook 'desktop-after-read-hook 'desktop-agendas-set)
    (remove-hook 'desktop-no-desktop-file-hook 'desktop-agendas-reset)
    (ad-disable-advice 'desktop-change-dir 'around
                       'desktop-agendas-change-dir)
    (ad-disable-advice 'desktop-clear 'after 'desktop-agendas-clear))
  (desktop-agendas-set))


(provide 'desktop-agendas)
;;; desktop-agendas.el ends here
