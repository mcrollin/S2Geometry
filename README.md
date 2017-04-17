S2Geometry Library in Swift
======================================

[![Travis CI](https://travis-ci.org/mcrollin/S2Geometry.svg?branch=master)](https://travis-ci.org/mcrollin/S2Geometry) [![codecov](https://codecov.io/gh/mcrollin/S2Geometry/branch/master/graph/badge.svg)](https://codecov.io/gh/mcrollin/S2Geometry) [![MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Status of the Library

This library is a swift port of the [C++ S2 library](https://code.google.com/archive/p/s2-geometry-library). It is greatly inspired analogous [Go](https://raw.githubusercontent.com/golang/geo) and [java](https://github.com/google/s2-geometry-library-java) libraries.

### ℝ¹: One-dimensional Cartesian coordinates

Full parity with C++.

### ℝ²: Two-dimensional Cartesian coordinates

Full parity with C++.

### ℝ³: Three-dimensional Cartesian coordinates

Full parity with C++.

### S¹: Circular Geometry

Full parity with C++ with the exception of:

**Mostly complete**
 * S1Interval - Missing ClampPoint

**In Progress**
 * S1ChordAngle

### S²: Spherical Geometry

Not Started Yet.
