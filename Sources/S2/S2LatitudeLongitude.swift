//
//  S2LatitudeLongitude.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/27/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

typealias S2LatLng = S2LatitudeLongitude

/// S2LatitudeLongitude represents a point on the unit sphere as a pair of angles.
struct S2LatitudeLongitude {
    let latitude: S1Angle
    let longitude: S1Angle

    static let northPoleLatitude: S1Angle = (.pi / 2).radians
    static let southPoleLatitude: S1Angle = -northPoleLatitude
}

// MARK: CustomStringConvertible compliance
extension S2LatitudeLongitude: CustomStringConvertible {

    var description: String {
        return "[\(latitude.degrees), \(longitude.degrees)]"
    }
}

extension S2LatitudeLongitude {

    /// - returns: a S2LatitudeLongitude for the coordinates given in degrees.
    static func fromDegrees(latitude: S1Angle, longitude: S1Angle) -> S2LatitudeLongitude {
        return S2LatitudeLongitude(latitude: S1Angle.degrees(latitude),
                                   longitude: S1Angle.degrees(longitude))
    }
}

extension S2LatitudeLongitude {

    /// Is valid iff the coordinates is normalized, with latitude ∈ [-π/2,π/2] and longitude ∈ [-π,π].
    var isValid: Bool {
        return abs(latitude.radians) <= .pi / 2
            && abs(longitude.radians) <= .pi
    }

    /// The normalized version with latitude clamped to [-π/2,π/2] and longitude wrapped in [-π,π].
    var normalized: S2LatitudeLongitude {
        var lat = latitude

        if lat > S2LatitudeLongitude.northPoleLatitude {
            lat = S2LatitudeLongitude.northPoleLatitude
        } else if lat < S2LatitudeLongitude.southPoleLatitude {
            lat = S2LatitudeLongitude.southPoleLatitude
        }

        let lng = remainder(longitude, 2 * .pi).radians

        return S2LatitudeLongitude(latitude: lat, longitude: lng)
    }

    /// The point corresponding to the latitude and longitude.
    var point: S2Point {
        return S2Point(latitudeLongitude: self)
    }

    /// - returns: the angle between two latitudeLongitude.
    func distance(with other: S2LatitudeLongitude) -> S1Angle {
        // Haversine formula, as used in C++ S2LatLng::GetDistance.
        let (lat1, lat2) = (latitude.radians, other.latitude.radians)
        let (lng1, lng2) = (longitude.radians, other.longitude.radians)
        let (dlat, dlng) = (sin(0.5 * (lat2 - lat1)), sin(0.5 * (lng2 - lng1)))
        let x = dlat * dlat + dlng * dlng * cos(lat1) * cos(lat2)

        return (2 * atan2(sqrt(x), sqrt(max(0, 1 - x)))).radians
    }
}
