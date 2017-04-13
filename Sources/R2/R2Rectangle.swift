//
//  R2Rectangle.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

// R2Rectangle represents a closed axis-aligned rectangle in the (x,y) plane.
struct R2Rectangle {
    let x: R1Interval
    let y: R1Interval
}

extension R2Rectangle: CustomStringConvertible {

    var description: String {
        return "[low\(low), high\(high)]"
    }
}

extension R2Rectangle: Equatable {

    // Returns true iff both points have similar x- and y-intervals.
    static func == (lhs: R2Rectangle, rhs: R2Rectangle) -> Bool {
        return lhs.x == rhs.x && lhs.y == lhs.y
    }
}

extension R2Rectangle: AlmostEquatable {

    // Returns true if the x- and y-intervals of the two rectangles are
    // the same up to the given tolerance.
    static func ==~ (lhs: R2Rectangle, rhs: R2Rectangle) -> Bool {
        return lhs.x ==~ rhs.x && lhs.y ==~ lhs.y
    }
}

extension R2Rectangle {

    // Expands the rectangle to include the given rectangle.
    // This is the same as replacing the rectangle by the union
    // of the two rectangles, but is more efficient.
    static func + (lhs: R2Rectangle, rhs: R2Rectangle) -> R2Rectangle {
        return lhs.union(with: rhs)
    }

    // Constructs the canonical empty rectangle. Use IsEmpty() to test
    // for empty rectangles, since they have more than one representation.
    // A Rect() is not the same as the empty.
    static var empty: R2Rectangle {
        return R2Rectangle(x: .empty, y: .empty)
    }

    // Constructs a rectangle that contains the given points.
    init(points: R2Point...) {
        guard points.count > 0 else {
            self.x = R1Interval(point: 0.0)
            self.y = R1Interval(point: 0.0)

            return
        }

        var x: R1Interval = .empty
        var y: R1Interval = .empty

        for point in points {
            x = x.add(point: point.x)
            y = y.add(point: point.y)
        }

        self.x = x
        self.y = y
    }

    // Constructs a rectangle with the given center and size.
    // Both dimensions of size must be non-negative.
    init(center: R2Point, size: R2Point) {
        x = R1Interval(low: center.x - size.x / 2, high: center.x + size.x / 2)
        y = R1Interval(low: center.y - size.y / 2, high: center.y + size.y / 2)
    }

    // Low corner of the rect.
    var low: R2Point {
        return R2Point(x: x.low, y: y.low)
    }

    // High corner of the rect.
    var high: R2Point {
        return R2Point(x: x.high, y: y.high)
    }

    // Center of the rectangle in (x,y)-space
    var center: R2Point {
        return R2Point(x: x.center, y: y.center)
    }

    // Width and height of this rectangle in (x,y)-space.
    // Empty rectangles have a negative width and height.
    var size: R2Point {
        return R2Point(x: x.length, y: y.length)
    }

    // Four vertices of the rectangle.
    // Vertices are returned in CCW direction starting with the lower left corner.
    var vertices: [R2Point] {
        return [R2Point(x: x.low, y: y.low),
                R2Point(x: x.high, y: y.low),
                R2Point(x: x.high, y: y.high),
                R2Point(x: x.low, y: y.high)]
    }

    // Reports whether the rectangle is empty.
    func isEmpty() -> Bool {
        return x.isEmpty()
    }

    // Reports whether the rectangle is valid.
    // This requires the width to be empty iff the height is empty.
    func isValid() -> Bool {
        return x.isEmpty() == y.isEmpty()
    }

    // Returns the vertex in direction i along the X-axis (0=left, 1=right)
    // and direction j along the Y-axis (0=down, 1=up).
    func vertex(i: Int, j: Int) -> R2Point {
        let xx = i == 1 ? x.high : x.low
        let yy = j == 1 ? y.high : y.low

        return R2Point(x: xx, y: yy)
    }

    // Reports whether the rectangle contains the given point.
    // Rectangles are closed regions, i.e. they contain their boundary.
    func contains(point: R2Point) -> Bool {
        return x.contains(point: point.x)
            && y.contains(point: point.y)
    }

    // Returns true iff the given point is contained in the interior
    // of the region (i.e. the region excluding its boundary).
    func interiorContains(point: R2Point) -> Bool {
        return x.interiorContains(point: point.x)
            && y.interiorContains(point: point.y)
    }

    // Reports whether the rectangle contains the given rectangle.
    func contains(rectangle other: R2Rectangle) -> Bool {
        return x.contains(interval: other.x)
            && y.contains(interval: other.y)
    }

    // Reports whether the interior of this rectangle contains all of the
    // points of the given other rectangle (including its boundary).
    func interiorContains(rectangle other: R2Rectangle) -> Bool {
        return x.interiorContains(interval: other.x)
            && y.interiorContains(interval: other.y)
    }

    // Reports whether this rectangle and the other rectangle have any points in common.
    func intersects(with other: R2Rectangle) -> Bool {
        return x.intersects(with: other.x)
            && y.intersects(with: other.y)
    }

    // Reports whether its the interior of this rectangle intersects
    // any point (including the boundary) of the given other rectangle.
    func interiorIntersects(with other: R2Rectangle) -> Bool {
        return x.interiorIntersects(with: other.x)
            && y.interiorIntersects(with: other.y)
    }

    // Expands the rectangle to include the given point.
    // The rectangle is expanded by the minimum amount possible.
    func add(point: R2Point) -> R2Rectangle {
        return R2Rectangle(x: x.add(point: point.x),
                           y: y.add(point: point.y))
    }

    // Returns the closest point in the rectangle to the given point.
    // The rectangle must be non-empty.
    func clamp(to point: R2Point) -> R2Point {
        return R2Point(x: x.clamp(to: point.x),
                       y: y.clamp(to: point.y))
    }

    // Returns a rectangle that has been expanded in the x-direction by margin.x,
    // and in y-direction by margin.y. If either margin is empty, then shrink
    // the interval on the corresponding sides instead. The resulting rectangle
    // may be empty. Any expansion of an empty rectangle remains empty.
    func expanded(margin: R2Point) -> R2Rectangle {
        let xx = x.expanded(by: margin.x)
        let yy = y.expanded(by: margin.y)

        if xx.isEmpty() || yy.isEmpty() {
            return .empty
        }

        return R2Rectangle(x: xx, y: yy)
    }

    // Returns a Rectangle that has been expanded by the amount on all sides.
    func expanded(margin: Double) -> R2Rectangle {
        return expanded(margin: R2Point(x: margin, y: margin))
    }

    // Returns the smallest rectangle containing the union of this rectangle
    // and the given rectangle.
    func union(with other: R2Rectangle) -> R2Rectangle {
        return R2Rectangle(x: x.union(with: other.x),
                           y: y.union(with: other.y))
    }

    // Returns the smallest rectangle containing the intersection of this
    // rectangle and the given rectangle.
    func intersection(with other: R2Rectangle) -> R2Rectangle {
        let xx = x.intersection(with: other.x)
        let yy = y.intersection(with: other.y)

        if xx.isEmpty() || yy.isEmpty() {
            return .empty
        }

        return R2Rectangle(x: xx, y: yy)
    }
}
