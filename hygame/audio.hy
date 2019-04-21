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

;; This module provides procedures to process audio input

(import queue soundfile sounddevice numpy)

(defn AudioFile [file-name &optional [fps 25] [dtype 'int16]]
  "Return a file audio buffer slice per frame getter"
  (setv ifile (soundfile.SoundFile file-name)
        wav (.read ifile -1 :dtype dtype)
        freq ifile.samplerate)
  (when (not (= (% freq fps) 0))
    (raise (RuntimeError (.format "Samplerate {} Hz doesn't match {} fps"
                                  freq fps))))
  (setv blocksize (// freq fps)
        frames-count (* (// (len wav) freq) fps)
        frames-path (numpy.linspace 0 (len wav) frames-count
                                    :endpoint False :dtype int))
  (fn [frame]
    "If frame is a symbol, return information, else return buffer slice"
    (cond [(= frame 'freq) freq]
          [(= frame 'channels) ifile.channels]
          [True
           (setv pos (get frames-path frame))
           (cut wav pos (+ pos blocksize))])))

(defn AudioIn [&optional [fps 25] [freq 44100] [dtype 'int16]]
  "Return a microphone audio buffer slice per frame getter"
  (setv q (queue.Queue :maxsize fps))
  (defn callback [indata frames time status]
    (when status
      (print "Input status:" status))
    (.put q indata))
  (setv stream (sounddevice.InputStream
                 :device "default"
                 :channels 1
                 :dtype dtype
                 :samplerate freq
                 :blocksize (// freq fps)
                 :callback callback))
  (fn [&optional frame]
    "If frame is a symbol, return information, else return current slice"
    (cond [(= frame 'freq) freq]
          [(= frame 'channels) 1]
          [True
           (when (not stream.active)
             (.start stream))
           (while (> (.qsize q) 1)
             (print "Dropping audio input")
             (.get q))
           (.get q)])))

(defn AudioInput [&optional file-name [fps 25]]
  (if file-name
      (AudioFile file-name :fps fps)
      (AudioIn :fps fps)))

(defn AudioOut [&optional [fps 25] [freq 44100] [channels 1] [dtype 'int16]]
  "Return an audio output buffer setter"
  (setv q (queue.Queue :maxsize fps))
  (defn callback [outdata frames time status]
    (when status.output_underflow
      (print "Underflow..."))
    (try
      (setv data (.tobytes (.get_nowait q)))
      (except [queue.Empty]
        ;; Scene is likely paused, nothing to play
        (setv data b"")))
    (when (< (len data) (len outdata))
      (setv data (+ data (* b"\x00" (- (len outdata) (len data))))))
    (setv (cut outdata) data))
  (defn finished []
    (print "AudioOut over"))
  (setv stream (sounddevice.RawOutputStream
                 :device "default"
                 :channels channels
                 :dtype dtype
                 :samplerate freq
                 :blocksize (// freq fps)
                 :callback callback
                 :finished-callback finished))
  (fn [buf]
    "Play the buffer"
    (.put q buf)
    (when (not stream.active)
      (.start stream))))

(defmain [&rest argv]
  "A simple audio player demo"
  (import [hygame.clock [Clock]]
          [hygame.cli [usage]])
  (setv args (usage)
        clock (Clock :fps args.fps)
        read (AudioFile args.wav)
        play (AudioOut :freq (read 'freq) :channels (read 'channels)))
  (setv frame 0)
  (print "Playing" (get argv 1) "at 25 fps ("
         (read 'freq) " Hz - "
         (read 'channels) " channels )")
  (while True
    (-> (read frame) (play))
    (setv frame (inc frame))
    (print (.format "\r{:04d}" frame) :end "")
    (.tick clock))
  (print (af 'freq)))
