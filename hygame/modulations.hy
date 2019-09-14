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

;; This module provides procedures to normalize raw data

(import [numpy :as np])

;; Primitive procedures
(defn compose [f g]
  (fn [x] (f (g x))))
(defn combine [f g]
  (fn [x] (+ (f x) (g x))))

(defn repeat [f n]
  (if (= n 1)
      f
      (compose f (repeat f (dec n)))))

(defn decay-damp [prev new damp]
  (if (> new prev)
      new
      (damp prev new)))

(defn average [x y]
  (/ (+ x y) 2))

(defn average-decay [prev new]
  (decay-damp prev new average))

(defn ratio-decay [ratio]
  (fn [prev new]
    (decay-damp
      prev
      new
      (fn [prev new] (- prev (/ (- prev new) ratio))))))

; Input selector
(defn midi-track-selector [track-name]
  (fn [input]
    (for [event input]
      (if (= (.get event "track") track-name)
          (return (.get event "ev"))))
    []))

(defn midi-pitch-selector [selector]
  (fn [input]
    (for [event (selector input)]
      (if (= (.get event "type") "chords")
          (return (.get event "pitch"))))))

; Higher level procedures
(defn band-selector [proc lower-freq upper-freq]
  (fn [input]
    (setv band (cut input.band lower-freq upper-freq))
    (cond [(.all (= band 0)) 0]
          [True (proc band)])))

(defn amp-max [dtype]
  (cond [(= dtype 'int16) (setv n (** 2 16))]
        [True (raise (RuntimeError (.format "Unknown dtype {}" dtype)))])
  (fn [input]
    (/ (np.max input) n)))

(defn midi-pitch-max [selector]
  (fn [input]
    (setv pitch (selector input))
    (if pitch
        (/ (max (.values pitch)) 127)
        0)))

(defn midi-note [selector note]
  (fn [input]
    (setv pitch (selector input))
    (if (and pitch (in note pitch))
        (get pitch note)
        0)))

(defn threshold-limit [selector threshold]
  (fn [input]
    (setv val (selector input))
    (if (< val threshold)
        0.0
        val)))

(defn Modulator [selector modulator &optional [init 0.0]]
  (setv prev init)
  (fn [input]
    ;; A bit of impurity to keep the previous value
    (nonlocal prev)
    (setv val (modulator prev (selector input)))
    (setv prev val)
    val))

; Public procedures
(defn AmpModulator [dtype &optional [decay 10]]
  (Modulator
    (amp-max dtype)
    (ratio-decay decay)))

(defn PitchModulator [track-name &optional [decay 10]]
  (Modulator
    (midi-pitch-max (midi-pitch-selector (midi-track-selector track-name)))
    (ratio-decay decay)))

(defn AudioModulator [band &optional peak [threshold 0.0] [decay 10]]
  (Modulator
    (threshold-limit
      (band-selector (if peak np.max np.mean)
                     (first band) (last band))
      threshold)
    (ratio-decay decay)))

(defn AudioPeakModulator [band &optional [decay 10]]
  (Modulator
    (band-selector (first band) (last band) :combinator np.max)
    (ratio-decay decay)))

(defn NoteModulator [track-name note &optional [decay 10]]
  (Modulator
    (midi-note (midi-pitch-selector (midi-track-selector track-name)) note)
    (ratio-decay decay)))
