;; Copyright 2019 tristanC
;; This file is part of hygame.
;;
;; Hygame is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Hygame is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Hygame.  If not, see <https://www.gnu.org/licenses/>.

;; This module provides usage for cli

(import argparse)

(defn usage []
  (setv parser (argparse.ArgumentParser))
  (.add-argument parser "--wav" :metavar "FILE")
  (.add-argument parser "--fps" :type int :default 25)
  (parser.parse_args))

(defmain [&rest argv]
  (print (usage)))
