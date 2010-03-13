;;; ffap-include-start.el --- recognise C #include when at start of line

;; Copyright 2007, 2009, 2010 Kevin Ryde

;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 9
;; Keywords: files
;; URL: http://user42.tuxfamily.org/ffap-include-start/index.html
;; EmacsWiki: FindFileAtPoint

;; ffap-include-start.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; ffap-include-start.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses/>.


;;; Commentary:

;; M-x ffap normally only recognises an include like
;;
;;     #include <foo.h>
;;
;; when point is on the filename part.  This spot of code lets it work when
;; point in the "#include" part, including at the start of the line, and
;; lets it work with any of the following,
;;
;;     #include <foo.h>       C language
;;     #include "foo.h"       C language
;;     include foo.make       GNU Make
;;     include "foo.rc"       Gtk RC file
;;
;; You can always move point to the filename and M-x ffap from there, but
;; it's handy to have it work from the start of the line too, especially
;; when just browsing rather than editing.
;;
;; For a GNU make multiple-file include like
;;
;;     include foo.make bar.make
;;
;; the first filename is offered when point is at or before the first name,
;; and the second when point is on it.
;;
;; This code works with ffap-makefile-vars.el too, so if you load that
;; package then the a Make include can have variables to expand,
;;
;;     include $(HOME)/mystuff/foo.make

;;; Install:

;; Put ffap-include-start.el in one of your `load-path' directories and the
;; following in your .emacs
;;
;;     (eval-after-load "ffap" '(require 'ffap-include-start))

;;; History:
;; 
;; Version 1 - the first version
;; Version 2 - GPLv3
;; Version 3 - set region for ffap-highlight
;; Version 4 - allow missing closing quote, don't extend across newline
;; Version 5 - set ffap-string-at-point variable
;; Version 6 - recognise gnu make include too
;; Version 7 - recognise gtk rc include too
;; Version 8 - undo defadvice on unload-feature
;; Version 9 - speedup for big buffers


;;; Code:

;;;###autoload (eval-after-load "ffap" '(require 'ffap-include-start))

;; for `ad-find-advice' macro when running uncompiled
;; (don't unload 'advice before our -unload-function)
(require 'advice)

(defadvice ffap-string-at-point (around ffap-include-start activate)
  "Recognise various \"include /my/file/name.x\" with point at bol."

  ;; The C and GtkRc patterns are not anchored to start of line so they work
  ;; commented out.  # is the RC comment char, so a commented out RC looks
  ;; like a C #include, eg.
  ;;
  ;;     # don't use this for now
  ;;     # include "foo.rc"
  ;;
  ;; The Make pattern is anchored to the start of a line as it would be too
  ;; ambiguous not at the start of a line.
  ;;
  ;; Narrowing to the current line is a speedup for big buffers.  It limits
  ;; the amount of searching forward and back that thing-at-point-looking-at
  ;; does when it works-around the way re-search-backward won't match across
  ;; point.
  ;;
  (require 'thingatpt)
  (if (save-restriction
        (narrow-to-region (line-beginning-position) (line-end-position))
        (or (thing-at-point-looking-at "include[ \t]+\"\\([^ \t\r\n\"]+\\)\"")
            (thing-at-point-looking-at "^include[ \t]+\\([^ \t\r\n]+\\)")
            (thing-at-point-looking-at "#[ \t]*include[ \t]+[\"<]\\([^\">\r\n]+\\)\\([\">]\\|$\\)")))
      (progn
        (setq ffap-string-at-point-region (list (match-beginning 1)
                                                (match-end 1)))
        (setq ad-return-value
              (setq ffap-string-at-point ;; and return the value
                    (buffer-substring-no-properties (match-beginning 1)
                                                    (match-end 1)))))
    ad-do-it))

(defun ffap-include-start-unload-function ()
  (when (ad-find-advice 'ffap-string-at-point 'around 'ffap-include-start)
    (ad-remove-advice   'ffap-string-at-point 'around 'ffap-include-start)
    (ad-activate        'ffap-string-at-point))
  nil) ;; and do normal unload-feature actions too

(provide 'ffap-include-start)

;;; ffap-include-start.el ends here
