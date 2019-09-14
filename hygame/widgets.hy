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

;; This module provides gtk widgets

(import gi threading numpy)
(for [tk ["Gtk" "Gdk"]]
  (gi.require_version tk "3.0"))
(import [gi.repository [Gdk Gtk]])

;; Keyval symbols
(setv Keys {'escape 65307 })

(defclass Window [object]
  "Simple window"
  (defn --init-- [self]
    (setv
      self.alive True
      self.win (Gtk.Window)
      self.box (Gtk.Box :orientation Gtk.Orientation.VERTICAL :spacing 0))
    (self.win.connect "destroy" Gtk.main_quit)
    (self.win.connect "key_press_event"
                      (fn [win ev]
                        (when (= ev.keyval (get Keys 'escape))
                          (.stop self))))
    (.add self.win self.box))

  (defn add [self obj]
    (.pack_start self.box obj True True 0))

  (defn render [self]
    (.queue_draw self.box))

  (defn update-loop [self]
    "Blocking procedure to trigger the Gtk main loop"
    (print "Starting gtk loop...")
    (.show_all self.win)
    (.show_all self.box)
    (Gtk.main))

  (defn start [self]
    "Start the Gtk main loop in a thread"
    (setv self.update-thread (threading.Thread :target self.update-loop))
    (.start self.update-thread))

  (defn stop [self]
    "Stop the Gtk main loop and close the window"
    (Gtk.main_quit)
    (setv self.alive False)
    (when (getattr self "update-thread" None)
      (.join self.update-thread))))

(defclass DrawingWidget [object]
  "Silly widget to support user-data based DrawingArea"
  (defn --init-- [self callback]
    (setv self.user-data None
          self.callback callback
          self.widget (Gtk.DrawingArea))
    (.connect self.widget 'draw self.draw))

  (defn draw [self window context]
    (setv rect (get (.get_allocated_size window) 0))
    (self.callback self.user-data (, rect.width rect.height) context))

  (defn render [self user-data]
    (setv self.user-data user-data)))

(defn wav-scope [buffer size context]
  (when (none? buffer)
    (return))
  (setv [x y] size
        mid (// y 2))
  (setv mono (/ (numpy.mean buffer :axis 1) (** 2 16)))

  ;; Move to first zero crossing
  (setv mono
        (cut mono (get (get (numpy.where (numpy.diff (numpy.sign mono))) 0) 0)))

  ;; fill background
  (.set_source_rgb context 0 0 0)
  (.rectangle context 0 0 x y)
  (.fill context)

  (.set_source_rgb context 1 1 1)
  (.set_line_width context 1)
  (.move_to context 0 (+ mid (* (get mono 0) mid)))
  (for [pos (range 1 (min x (- (len mono) 1)))]
    (.line_to context pos (+ mid (* (get mono (+ pos 1)) mid))))
  (.stroke context))

(defn mod-scope []
  (setv values None)
  (fn [value size context]
    (when (none? value)
      (return))
    (nonlocal values)
    (setv [x y] size)
    (when (or (none? values) (!= values.shape (, x)))
      (setv nvalues (numpy.zeros x))
      (when (not (none? values))
        (for [pos (range (min x (len values)))]
          (setv (get nvalues (- -1 pos)) (get values (- -1 pos)))))
      (setv values nvalues))
    (setv values (numpy.roll values -1)
          (get values -1) value)
    ;; fill background
    (.set_source_rgb context 0 0 0)
    (.rectangle context 0 0 x y)
    (.fill context)

    (.set_source_rgb context 1 1 1)
    (.set_line_width context 1)
    (.move_to context (- x 1) (- y (* value y)))
    (for [pos (range 2 x)]
      (.line_to context (- x pos) (- y (* (get values (- -1 pos)) y))))
    (.stroke context)))

(defn WavScope [] (DrawingWidget wav-scope))
(defn ModScope [] (DrawingWidget (mod-scope)))

(defmain [&rest argv]
  (import [hygame.clock [Clock]]
          [hygame.cli [usage]]
          [hygame.modulations [AmpModulator]]
          [hygame.audio [AudioInput AudioOut]])
  (setv args (usage)
        clock (Clock :fps args.fps)
        win (Window)
        wav-scope (WavScope)
        mod-scope (ModScope)
        mod (AmpModulator 'int16)
        read (AudioInput args.wav :fps args.fps)
        play (if args.wav
                 (AudioOut :freq (read 'freq) :channels (read 'channels))
                 None))
  (.add win wav-scope.widget)
  (.add win mod-scope.widget)
  (.start win)
  (setv frame 0)
  (while win.alive
    (setv buf (read frame))
    (.render wav-scope buf)
    (.render mod-scope (mod buf))
    (.render win)
    (when play
      (play buf))
    (setv frame (inc frame))
    (.tick clock)))
