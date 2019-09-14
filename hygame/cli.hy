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

(import argparse os)

(defn usage []
  (setv parser (argparse.ArgumentParser))
  (.add-argument parser "--sound-device")
  (.add-argument parser "--wav" :metavar "FILE")
  (.add-argument parser "--fps" :type int :default 25)
  (setv args (parser.parse_args))
  (when (or args.sound_device (get os.environ "SD_DEVICE"))
    (import sounddevice)
    (cond [(= "help" args.sound_device)
           (print (sounddevice.query_devices))
           (exit 1)]
          [args.sound_device
           (setv default-device args.sound_device)]
          [True
           (setv default-device (get os.environ "SD_DEVICE"))])
    (setv args.sound_device (int default-device))
    (setv sounddevice.default.device args.sound_device))
  args)

(defmain [&rest argv]
  (print (usage)))
