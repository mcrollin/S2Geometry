S2Geometry Library in Swift
======================================

[![Travis CI](https://travis-ci.org/mcrollin/S2Geometry.svg?branch=master)](https://travis-ci.org/mcrollin/S2Geometry) [![codecov](https://codecov.io/gh/mcrollin/S2Geometry/branch/master/graph/badge.svg)](https://codecov.io/gh/mcrollin/S2Geometry) [![MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Status of the Library

This library is a swift port of the [C++ S2 library](https://code.google.com/archive/p/s2-geometry-library). It is greatly inspired by analogous [Go](https://github.com/golang/geo) and [java](https://github.com/google/s2-geometry-library-java) libraries.

### ℝ¹: One-dimensional Cartesian coordinates

Full parity with C++.

### ℝ²: Two-dimensional Cartesian coordinates

Full parity with C++.

### ℝ³: Three-dimensional Cartesian coordinates

Full parity with C++.

### S¹: Circular Geometry

Full parity with C++ with the exception of:

 * S1Interval - Missing clampPoint.
 * S1Angle - Missing conversion to/from S2Point and S2LatLng.

### S²: Spherical Geometry

**Complete**

 * S2Matrix3x3

**In Progress**

 * S2Point - Missing orderedCounterClockwise, capBound, rectBound, containsCell, intersectsCell, rotate, angle, turnAngle and signedArea.
 * S2Projections - Missing faceUvToXyz, validFaceXyzToUv, xyzToFace, faceXyzToUv, getUNorm, getVNorm, getNorm, getUAxis, getVAxis.

## Cell Precision Levels

 ```
+-------+------------------------+------------------------+
| level |          min           |          max           |
+-------+------------------------+------------------------+
|   0   |   85010745.31829801    |   85010745.31829801    |
|   1   |   21252686.32957451    |   21252686.32957451    |
|   2   |   4919692.788908431    |   6026502.240789332    |
|   3   |   1055374.1635741317   |   1646450.330584525    |
|   4   |   240148.38663939087   |   410330.86799351306   |
|   5   |   57110.49115473437    |   103860.29228335699   |
|   6   |   13917.29238387263    |   25874.754791016523   |
|   7   |   3434.7062967870756   |   6484.378885287462    |
|   8   |   853.1282262375961    |   1619.407234818789    |
|   9   |   212.59037482507944   |   405.0799071557518    |
|   10  |   53.06125180306277    |   101.24253574537217   |
|   11  |   13.254527667429063   |   25.314131067518176   |
|   12  |   3.312284224208482    |   6.328099811612918    |
|   13  |   0.8279026237644239   |   1.5820793339891468   |
|   14  |  0.20695460373777771   |   0.3955130522146923   |
|   15  |   0.0517360195235312   |  0.09887911173600902   |
|   16  |  0.012933675961740044  |  0.024719671912586796  |
|   17  |  0.003233377876011487  |  0.006179931234839686  |
|   18  | 0.0008083393297172699  |  0.001544981151889418  |
|   19  | 0.0002020841900197007  | 0.0003862454950907128  |
|   20  | 5.052096720422156e-05  | 9.656134787987641e-05  |
|   21  | 1.2630231762861059e-05 | 2.4140340203705243e-05 |
|   22  | 3.157556686596609e-06  | 6.035084647155003e-06  |
|   23  |  7.89389015056682e-07  | 1.5087712126775294e-06 |
|   24  | 1.9734723436242184e-07 | 3.771927970575091e-07  |
|   25  | 4.933680604046464e-08  | 9.429820001918215e-08  |
|   26  | 1.2334201294732652e-08 | 2.3574549857392034e-08 |
|   27  | 3.0835502978371434e-09 |  5.89363744167674e-09  |
|   28  | 7.708875679977811e-10  | 1.4734093403197704e-09 |
|   29  | 1.9272189199944529e-10 | 3.683523228432608e-10  |
|   30  | 4.818047299986132e-11  | 9.208807978514953e-11  |
+-------+------------------------+------------------------+
```