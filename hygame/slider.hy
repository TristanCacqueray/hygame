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

;; This module provides procedures to create parameter value control sliders.
;; The goal is to provide dynamic range control for any parameter type.
;;
;; Useful doc:
;; https://python-gtk-3-tutorial.readthedocs.io/en/latest/entry.html
;; https://lazka.github.io/pgi-docs/Gdk-3.0/
;; https://lazka.github.io/pgi-docs/Gtk-3.0/

(import math threading time)

(import [hygame.widgets [Gdk Gtk Window]])

(defn load-css []
  "Load custom style to make things smaller"
  (setv screen (Gdk.Screen.get_default)
        provider (Gtk.CssProvider)
        context (Gtk.StyleContext))
  (.add_provider_for_screen
    context screen provider Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
  (.load_from_data provider (.encode #[[
#value_entry {
  min-height: 0px;
}
]] "utf-8")))

(defn human-str [value]
  (if (< value 0.0)
      (setv sign "-")
      (setv sign ""))
  (cond [(= value 0.0) "0.0"]
        [(or (>= (abs value) 1000) (<= (abs value) 0.0001))
         (.format "{}{:.3E}" sign value)]
        [True (.format "{}{:03.4f}" sign value)]))


(defclass Sliders [Window]
  "Collection of sliders"

  (defn --init-- [self]
    (Window.--init-- self)
    (setv self.sliders [])
    (load-css))

  (defn add [self sliders]
    (if (not (instance? list sliders))
        (setv sliders [sliders]))
    (for [slider sliders]
      (.append self.sliders slider)
      (Window.add self slider.box)))

  (defn render [self]
    "Update sliders' position when value changed"
    (for [slider self.sliders]
      (.update slider))))


(defclass Slider [object]
  (defn --init-- [self name getter setter]
    "Getter and setter are callback procedure"
    (setv info-box (Gtk.Box :orientation Gtk.Orientation.HORIZONTAL :spacing 0)
          label (Gtk.Label)
          self.entry (Gtk.Entry)
          self.mid-label (Gtk.Label)
          self.min-label (Gtk.Label)
          self.max-label (Gtk.Label)
          ;; The sliders box
          self.box (Gtk.Fixed)
          self.range-scale
          (Gtk.Scale :adjustment (Gtk.Adjustment :value 50 :lower 0 :upper 100))
          self.value-scale
          (Gtk.Scale :adjustment (Gtk.Adjustment :value 50 :lower 0 :upper 100))
          ;; State
          self.getter getter)

    ;; Trigger initial update
    (.update self)

    ;; Configure the range slider
    (.connect self.range-scale "button-release-event"
              (fn [widget event]
                "Extend the range when the grip goes out of bound"
                (setv value (.get_value widget))
                (when (or (<= value 0) (>= value 100))
                  (setv self.range self.cur-range)
                  (.set_value widget 50))))
    (.connect self.range-scale "change-value"
              (fn [widget event value]
                "Update the range while making sure it doesn't reach 0"
                (setv value (* (/ (- (.get_value widget) 50) 100)))
                (setv self.cur-range (+ self.range (* self.range value)))
                (.update-range self)))

    ;; Configure the value slider
    (.connect self.value-scale "button-release-event"
              (fn [widget event]
                "Recenter the slider when the grip goes out of bound"
                (setv value (.get_value widget))
                (when (or (<= value 0) (>= value 100))
                  (setv self.center (getter))
                  (.update-range self)
                  (.set_value widget 50))))
    (.connect self.value-scale "change-value"
              (fn [widget event value]
                (setv value (+ (self.get-min)
                               (* (/ (.get_value widget) 100)
                                  (- (self.get-max) (self.get-min)))))
                (setter value)
                (.set_text self.entry (str value))))

    ;; Pack and customize the widgets
    (for [scale [self.range-scale self.value-scale]]
      ;; Scale to available space, though it's now fixed...
      (.set_hexpand scale True)
      ;; Do not display scale value
      (.set_draw_value scale False))
    (for [widget
          [label self.entry self.min-label self.mid-label self.max-label]]
      (.pack_start info-box widget True True 0))
    (.set_markup label (.format "<b>{:>20s}</b>: " name))
    ;; Associate css to entry widget
    (.set_name self.entry "value_entry")
    ;; Fix scales' width
    (.set_size_request self.range-scale 200 5)
    (.set_size_request self.value-scale 400 5)
    (.put self.box info-box 0 0)
    (.put self.box self.range-scale 400 20)
    (.put self.box self.value-scale 0 20))

  (defn update-range [self]
    (setv self.center (self.getter))
    (.set_value self.value-scale 50)
    (.set_label self.min-label (.format " {} <-- " (human-str (self.get-min))))
    (.set_label self.mid-label (.format " {} " (human-str self.center)))
    (.set_label self.max-label (.format " --> {} " (human-str (self.get-max)))))

  (defn get-min [self]
    (return (- self.center (/ self.cur-range 2))))

  (defn get-max [self]
    (return (+ self.center (/ self.cur-range 2))))

  (defn update [self]
    "Update sliders from the value"
    (setv value (.getter self))
    (setv self.range (** 10 (+ 1 (int (math.log10 value)))))
    (setv self.cur-range self.range)
    (.set_text self.entry (human-str value))
    (.update-range self)))


(defn make-slider [param]
  "Create a slider(s) widget based on the parameter type"
  (cond [(numeric? (get param 'value))
         (Slider (get param 'name)
                 (fn [] (get param 'value))
                 (fn [value] (assoc param 'value value)))]
        [(instance? list (get param 'value))
         (setv array [] syms '(x y z w))
         (for [idx (range (len (get param 'value)))]
           (.append array
                    (Slider (.format "{}_{}" (get param 'name) (get syms idx))
                            ((fn [idx]
                               ;;
                               (fn [] (get (get param 'value) idx))) idx)
                            ((fn [idx]
                               (fn [value]
                                 (setv (get (get param 'value) idx)
                                       value))) idx))))
         array]
        [True
         (print "Unknown param type" param)
         (list)]))

(defmain [&rest argv]
  (setv sliders (Sliders))
  (setv seed [0.1 1.5])
  (.add sliders (make-slider {'name "zoom" 'value 42.0}))
  (.add sliders (make-slider {'name "mod1" 'value 0.1}))
  (.add sliders (make-slider {'name "seed" 'value seed}))
  (if (> (len argv) 1)
      (do
        (.start sliders)
        (try
          (while True
            (print "Seed:" seed)
            (time.sleep 1))
          (except [KeyboardInterrupt]))
        (.stop sliders))
      (.update-loop sliders)))
