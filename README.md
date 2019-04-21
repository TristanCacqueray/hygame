# hygame: Hylang Game Toolchain

This repository is a collection of modules to create interactive visualisations.
The general design is that each frame undergoes:

* Input procedures to collect raw data such as audio or midi events.
* Modulations procedures to normalize the raw data.
* Scene procedures to transform the modulation into rendering parameters.
* Output procedures to generate visualization.

Procedures shall works near real time or delayed. Thus Hygame uses a dedicated
clock and the input procedures also works with pre-recorded data.

Please note that the interfaces are not meant to be stable but rather bundled
with the final visualisation program. This is the third implementation
of this toolchain:

* pycf: original implementation with tkinter and Context Free Art
* demo-code: first refactor using pygame, OpenCL and glumpy
* hygame: another refactor based on Hylang

Each module has a standalone main procedure with usage example.
