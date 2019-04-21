#!/bin/env python
# Copyright 2019 tristanC
# This file is part of hygame.
#
# Hygame is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Hygame is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hygame.  If not, see <https://www.gnu.org/licenses/>.

from setuptools import find_packages, setup

setup(
    name="hygame",
    version="0.0.1",
    install_requires=[
        'hy',
        'soundfile',
        'sounddevice',
        'numpy',
        'PyGObject'
    ],
    packages=find_packages(exclude=['tests']),
    package_data={
        'hygame': ['*.hy'],
    },
    author="Tristan de Cacqueray",
    author_email="tristanC@wombatt.eu",
    long_description="Hylang Game Toolkit",
    license="GPL-3",
    url="https://gitlab.com/TristanCacqueray/hygame",
    platforms=['any'],
    python_requires='>=3.4',
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: DFSG approved",
        "License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)",
        "Operating System :: OS Independent",
        "Programming Language :: Lisp",
        "Topic :: Software Development :: Libraries",
    ]
)
