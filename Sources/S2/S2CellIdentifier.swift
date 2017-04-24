//
//  S2CellIdentifier.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/24/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

// swiftlint:disable file_length

import Foundation

typealias S2CellIdentifier = S2Cell.Identifier
typealias S2FaceIJ = (face: Int, i: Int, j: Int)
typealias S2FaceIJOrientation = (face: Int, i: Int, j: Int, orientation: Int)
typealias S2FaceSiTi = (face: Int, si: UInt64, ti: UInt64)

extension S2Cell {

    struct Identifier {
        static let maxLevel = 30
        static let facesCount = 6
        fileprivate static let projection = S2Projection.optimal

        static let faceBits: UInt64 = 3
        fileprivate static let lookupBits = 4
        fileprivate static let swapMask = 0x01
        fileprivate static let invertMask = 0x02

        // The extra position bit (61 rather than 60) lets us encode each cell
        // as its Hilbert curve position at the cell center (which is halfway
        // along the portion of the Hilbert curve that fills that cell).
        static let positionBits = UInt64(2 * maxLevel + 1)
        fileprivate static let wrapOffset = UInt64(facesCount) << positionBits
        fileprivate static let childrenPosition = ["0", "1", "2", "3"]
        fileprivate static let lookup = S2CellLookupTable.shared

        static let maxSize = 1 << maxLevel

        let value: UInt64
    }
}

// MARK: CustomStringConvertible compliance
extension S2CellIdentifier: CustomStringConvertible {

    var description: String {
        guard isValid else {
            return "Invalid: \(value)"
        }

        var positions = [String]()
        let cellLevel = level

        if cellLevel > 0 {
            for ll in 1 ... cellLevel {
                positions.append(S2CellIdentifier.childrenPosition[childPosition(at: ll)])
            }
        }

        return "\(face)/\(positions.joined())"
    }
}

// MARK: ExpressibleByIntegerLiteral compliance
extension S2CellIdentifier: ExpressibleByIntegerLiteral {

    init(integerLiteral value: UInt64) {
        self.value = value
    }
}

// MARK: Equatable compliance
extension S2CellIdentifier: Equatable {

    /// - returns: True iff both identifier have similar value.
    static func == (lhs: S2CellIdentifier, rhs: S2CellIdentifier) -> Bool {
        return lhs.value == rhs.value
    }
}

// MARK: Comparable compliance
// Two entities are compared element by element with the given operator.
// The first mismatch defines which is less (or greater) than the other.
// If both have equivalent values they are lexicographically equal.
extension S2CellIdentifier: Comparable {

    static func < (lhs: S2CellIdentifier, rhs: S2CellIdentifier) -> Bool {
        return lhs.value < rhs.value
    }
}

extension S2CellIdentifier {

    /// - returns: the lowest-numbered bit that is on for cells at the given level.
    fileprivate static func leastSignificantBit(at level: Int) -> UInt64 {
        assert(0 ... maxLevel ~= level)

        return 1 << (2 * UInt64(maxLevel - level))
    }

    /// Passing zero to this function has undefined behavior.
    ///
    /// - returns: the index (between 0 and 63) of the most significant set bit.
    static func mostSignificantBitSetNonZero(_ value: UInt64) -> Int {
        let values: [UInt64] = [0x2, 0xC, 0xF0, 0xFF00, 0xFFFF_0000, 0xFFFF_FFFF_0000_0000]
        let shift: [UInt64] = [1, 2, 4, 8, 16, 32]
        var msbPosition: UInt64 = 0
        var bits = value

        for i in stride(from: 5, to: -1, by: -1) where bits & values[i] != 0 {
            bits >>= shift[i]
            msbPosition |= shift[i]
        }

        return Int(msbPosition)
    }

    /// Finds the index (between 0 and 63) of the least significant set bit.
    ///
    /// - returns: the number of consecutive least significant zero bits.
    static func leastSignificantBitSetNonZero(_ value: UInt64) -> Int {
        guard value != 0 else {
            return 0
        }

        var shift: UInt32 = 1 << 4
        var bits = UInt32(truncatingBitPattern: value)
        var lsb: UInt32 = 31

        if bits == 0 {
            lsb += 32
            bits = UInt32(truncatingBitPattern: value >> 32)
        }

        for _ in 0 ... 4 {
            let x = bits << shift

            if x != 0 {
                bits = x
                lsb -= shift
            }

            shift >>= 1
        }

        return Int(lsb)
    }

    /// - returns: the value limited with a given lowest-numbered bit.
    fileprivate static func limit(value: UInt64, with leastSignificantBit: UInt64) -> UInt64 {
        return (value & (0 &- leastSignificantBit)) | leastSignificantBit
    }

    static func sizeIJ(at level: Int) -> Int {
        guard level <= maxLevel else {
            return 0
        }

        return Int(1 << UInt(maxLevel - level))
    }

    /// - returns: the edge length of a cell id in (s,t)-space at the given level.
    fileprivate static func sizeST(at level: Int) -> Double {
        assert(0 ... maxLevel ~= level)

        return S2Projection.optimal.stMinimum(ij: sizeIJ(at: level))
    }

    /// Finds the cell at the given level containing the leaf cell with the given (i,j)-coordinates.
    ///
    /// - returns: the bounds in (u,v)-space.
    static func boundUV(i: Int, j: Int, level: Int) -> R2Rectangle {
        let projection = S2Projection.optimal
        let cellSize = sizeIJ(at: level)
        let xLow = i & -cellSize
        let yLow = j & -cellSize

        return R2Rectangle(x: R1Interval(low: projection.uv(st: projection.stMinimum(ij: xLow)),
                                         high: projection.uv(st: projection.stMinimum(ij: xLow + cellSize))),
                           y: R1Interval(low: projection.uv(st: projection.stMinimum(ij: yLow)),
                                         high: projection.uv(st: projection.stMinimum(ij: yLow + cellSize))))
    }

    /// Given (i, j) coordinates that may be out of bounds,
    /// normalize them by returning the corresponding neighbor cell on an adjacent face.
    static func wrappedFrom(face: Int, i: Int, j: Int) -> S2CellIdentifier {
        // Convert i and j to the coordinates of a leaf cell just beyond the
        // boundary of this face.  This prevents 32-bit overflow in the case
        // of finding the neighbors of a face cell.
        let i = projection.wrapIJ(ij: i)
        let j = projection.wrapIJ(ij: j)

        // We want to wrap these coordinates onto the appropriate adjacent face.
        // The easiest way to do this is to convert the (i,j) coordinates to (x,y,z)
        // (which yields a point outside the normal face boundary), and then call
        // xyzToFaceUV to project back onto the correct face.
        //
        // The code below converts (i,j) to (si,ti), and then (si,ti) to (u,v) using
        // the linear projection (u=2*s-1 and v=2*t-1).  (The code further below
        // converts back using the inverse projection, s=0.5*(u+1) and t=0.5*(v+1).
        // Any projection would work here, so we use the simplest.)  We also clamp
        // the (u,v) coordinates so that the point is barely outside the
        // [-1,1]x[-1,1] face rectangle, since otherwise the reprojection step
        // (which divides by the new z coordinate) might change the other
        // coordinates enough so that we end up in the wrong leaf cell.
        let maxSize = S2CellIdentifier.maxSize
        let scale = 1.0 / Double(maxSize)
        let limit = Double(bitPattern: (Double(1).bitPattern + 1))
        let u = max(-limit, min(limit, scale * Double((i << 1) + 1 - maxSize)))
        let v = max(-limit, min(limit, scale * Double((j << 1) + 1 - maxSize)))

        // Find the leaf cell coordinates on the adjacent face,
        // and convert them to a cell id at the appropriate level.
        let (newface, newU, newV) = projection.faceUV(xyz: projection.xyz(face: face, u: u, v: v))

        let linearProjection = S2Projection.linear
        let s = linearProjection.st(uv: newU)
        let t = linearProjection.st(uv: newV)

        return S2CellIdentifier(face: newface, i: projection.ij(st: s), j: projection.ij(st: t))
    }

    static func from(face: Int, i: Int, j: Int, sameFace: Bool) -> S2CellIdentifier {
        if sameFace {
            return S2CellIdentifier(face: face, i: i, j: j)
        }

        return S2CellIdentifier.wrappedFrom(face: face, i: i, j: j)
    }
}

extension S2CellIdentifier {

    /// With leading zeros included but trailing zeros stripped.
    ///
    /// - returns: a hex-encoded string of the uint64 cell id.
    var token: String {
        guard value != 0 else {
            return "X"
        }

        return String(value, radix: 16)
            .paddingLeft(toLength: 16, withPad: "0")
            .replacingOccurrences(of: "\(0)+$", with: "", options: .regularExpression)
    }

    /// Cube face for this cell ID, in the range [0,5].
    var face: Int {
        return Int(value >> S2CellIdentifier.positionBits)
    }

    /// Position along the Hilbert curve of this cell ID, in the range [0, 2^posBits - 1].
    var position: UInt64 {
        return value & (.max >> S2CellIdentifier.faceBits)
    }

    /// The subdivision level of this cell ID, in the range [0, maxLevel].
    var level: Int {
        let maxLevel = S2CellIdentifier.maxLevel

        guard !isLeaf else {
            return maxLevel
        }

        return maxLevel - S2CellIdentifier.leastSignificantBitSetNonZero(value) >> 1
    }

    /// The least significant bit that is set.
    /* fileprivate */ var leastSignificantBit: UInt64 {
        return value & (0 &- value)
    }

    /// Whether it represents a valid cell.
    var isValid: Bool {
        return face < S2CellIdentifier.facesCount
            && (leastSignificantBit & 0x1555_5555_5555_5555 != 0)
    }

    /// Whether this cell ID is at the deepest level, the level at which the cells are smallest.
    var isLeaf: Bool {
        return value & 1 != 0
    }

    /// Whether this is a top-level (face) cell.
    var isFace: Bool {
        return value & (S2CellIdentifier.leastSignificantBit(at: 0) - 1) == 0
    }

    /// The next cell along the Hilbert curve.
    var next: S2CellIdentifier {
        return S2CellIdentifier(value: UInt64.addWithOverflow(value, leastSignificantBit << 1).0)
    }

    /// The next cell along the Hilbert curve, wrapping around from last to first as necessary.
    /// This should not be used with childBegin and childEnd.
    var nextWrap: S2CellIdentifier {
        let n = next
        let wrapOffset = S2CellIdentifier.wrapOffset

        if n.value < wrapOffset {
            return n
        }

        return S2CellIdentifier(value: UInt64.subtractWithOverflow(n.value, wrapOffset).0)
    }

    /// The previous cell along the Hilbert curve.
    var previous: S2CellIdentifier {
        return S2CellIdentifier(value: UInt64.subtractWithOverflow(value, leastSignificantBit << 1).0)
    }

    /// The previous cell along the Hilbert curve, wrapping around from last to first as necessary.
    /// This should not be used with childBegin and childEnd.
    var previousWrap: S2CellIdentifier {
        let p = previous
        let wrapOffset = S2CellIdentifier.wrapOffset

        if p.value < wrapOffset {
            return p
        }

        return S2CellIdentifier(value: UInt64.addWithOverflow(p.value, wrapOffset).0)
    }

    /// The first child in a traversal of the children of this cell, in Hilbert curve order.
    ///
    ///     var child = childBegin
    ///     let end = childEnd
    ///
    ///     while child != end {
    ///         ...
    ///         child = child.next
    ///     }
    var childBegin: S2CellIdentifier {
        assert(!isLeaf)

        let lsb = leastSignificantBit

        return S2CellIdentifier(value: value - lsb + lsb >> 2)
    }

    /// The first cell after a traversal of the children of this cell in Hilbert curve order.
    /// The returned cell may be invalid.
    var childEnd: S2CellIdentifier {
        assert(!isLeaf)

        let lsb = leastSignificantBit

        return S2CellIdentifier(value: value + lsb + lsb >> 2)
    }

    /// The four immediate children of this cell.
    /// If it a leaf cell, it returns four identical cells that are not the children.
    var children: [S2CellIdentifier] {
        assert(!isLeaf)

        var lsb = leastSignificantBit
        let child1 = S2CellIdentifier(value: value - lsb + lsb >> 2)

        lsb >>= 1

        let child2 = S2CellIdentifier(value: child1.value + lsb)
        let child3 = S2CellIdentifier(value: child2.value + lsb)
        let child4 = S2CellIdentifier(value: child3.value + lsb)

        return [child1, child2, child3, child4]
    }

    // Cheaper than parent(level:), but assumes !isFace.
    var parent: S2CellIdentifier {
        assert(!isFace)

        let nlsb = leastSignificantBit << 2

        return S2CellIdentifier(value: S2CellIdentifier.limit(value: value, with: nlsb))
    }

    /// The minimum S2CellIdentifier that is contained within this cell.
    var rangeMinimum: S2CellIdentifier {
        return S2CellIdentifier(value: value - (leastSignificantBit - 1))
    }

    /// The maximum S2CellIdentifier that is contained within this cell.
    var rangeMaximum: S2CellIdentifier {
        return S2CellIdentifier(value: value + (leastSignificantBit - 1))
    }

    /// Uses the ijLookup table to unfiddle the bits.
    var faceIJOrientation: S2FaceIJOrientation {
        let lookup = S2CellIdentifier.lookup
        let lookupBits = S2CellIdentifier.lookupBits
        let invertMask = S2CellIdentifier.invertMask
        let swapMask = S2CellIdentifier.swapMask
        var nbits = S2CellIdentifier.maxLevel - 7 * lookupBits // first iteration
        let currentFace = face
        var orientation = currentFace & swapMask
        var (i, j) = (0, 0)

        for k in stride(from: 7, to: -1, by: -1) {
            orientation += (Int(value >> UInt64(k * 2 * lookupBits + 1)) & Int((1 << UInt(2 * nbits)) - 1)) << 2
            orientation = lookup.ijLookup[orientation]
            i += (orientation >> (lookupBits + 2)) << (k * lookupBits)
            j += ((orientation >> 2) & ((1 << lookupBits) - 1)) << (k * lookupBits)
            orientation &= (swapMask | invertMask)
            nbits = lookupBits // following iterations
        }

        if leastSignificantBit & 0x1111_1111_1111_1110 != 0 {
            orientation ^= swapMask
        }

        return S2FaceIJOrientation(face: currentFace, i: i, j: j, orientation: orientation)
    }

    /// The Face/Si/Ti coordinates of the center of the cell.
    var faceSiTi: S2FaceSiTi {
        let (face, i, j, _) = faceIJOrientation

        var delta = 0

        if isLeaf {
            delta = 1
        } else if (UInt64(i) ^ (value >> 2)) & 1 != 0 {
            delta = 2
        }

        return S2FaceSiTi(face: face,
                          si: UInt64(2 * i + delta),
                          ti: UInt64(2 * j + delta))
    }

    /// Note that although (si,ti) coordinates span the range [0,2**31] in general,
    /// the cell center coordinates are always in the range [1,2**31-1] and
    /// therefore can be represented using a signed 32-bit integer.
    ///
    /// - returns: the (face, si, ti) coordinates of the center of the cell.
    var centerFaceSiTi: S2FaceSiTi {
        // First we compute the discrete (i,j) coordinates of a leaf cell contained
        // within the given cell. Given that cells are represented by the Hilbert
        // curve position corresponding at their center, it turns out that the cell
        // returned by faceIJOrientation is always one of two leaf cells closest
        // to the center of the cell (unless the given cell is a leaf cell itself,
        // in which case there is only one possibility).
        //
        // Given a cell of size s >= 2 (i.e. not a leaf cell), and letting (imin,
        // jmin) be the coordinates of its lower left-hand corner, the leaf cell
        // returned by faceIJOrientation is either (imin + s/2, jmin + s/2)
        // (imin + s/2 - 1, jmin + s/2 - 1). The first case is the one we want.
        // We can distinguish these two cases by looking at the low bit of i or
        // j. In the second case the low bit is one, unless s == 2 (i.e. the
        // level just above leaf cells) in which case the low bit is zero.
        //
        // In the code below, the expression ((i ^ (int(id) >> 2)) & 1) is true
        // if we are in the second case described above.

        let (face, i, j, _) = faceIJOrientation
        var delta = 0

        if isLeaf {
            delta = 1
        } else if ((Int64(i) ^ (Int64(value) >> 2)) & 1) == 1 {
            delta = 2
        }

        // Note that (2 * {i,j} + delta) will never overflow a 32-bit integer.
        return S2FaceSiTi(face: face, si: UInt64(2 * i + delta), ti: UInt64(2 * j + delta))
    }

    /// - returns: the center of the cell id in (s,t)-space.
    var centerST: R2Point {
        let (_, si, ti) = faceSiTi
        let projection = S2Projection.optimal

        return R2Point(x: projection.st(siTi: si), y: projection.st(siTi: ti))
    }

    /// - returns: the center of this CellID in (u,v)-space.
    /// Note that the center of the cell is defined as the point at which it is recursively subdivided
    /// into four children; in general, it is not at the midpoint of the (u,v) rectangle covered by the cell.
    var centerUV: R2Point {
        let point = centerST
        let projection = S2Projection.optimal

        return R2Point(x: projection.uv(st: point.x), y: projection.uv(st: point.y))
    }

    /// - returns: the bound of this CellID in (s,t)-space.
    var boundST: R2Rectangle {
        let size = S2CellIdentifier.sizeST(at: level)

        return R2Rectangle(center: centerST, size: R2Point(x: size, y: size))
    }

    /// - returns: the bound of this CellID in (u,v)-space.
    var boundUV: R2Rectangle {
        let (_, i, j, _) = faceIJOrientation

        return S2CellIdentifier.boundUV(i: i, j: j, level: level)
    }

    /// Edges 0, 1, 2, 3 are in the down, right, up, left directions in the face space.
    /// All neighbors are guaranteed to be distinct.
    ///
    /// - returns: the four cells that are adjacent across the cell's four edges.
    var edgeNeighbors: [S2CellIdentifier] {
        let currentLevel = level
        let size = S2CellIdentifier.sizeIJ(at: currentLevel)
        let (face, i, j, _) = faceIJOrientation

        return [
            S2CellIdentifier.wrappedFrom(face: face, i: i, j: j - size).parent(at: level),
            S2CellIdentifier.wrappedFrom(face: face, i: i + size, j: j).parent(at: level),
            S2CellIdentifier.wrappedFrom(face: face, i: i, j: j + size).parent(at: level),
            S2CellIdentifier.wrappedFrom(face: face, i: i - size, j: j).parent(at: level)
        ]
    }

    /// An unnormalized point with a vector from the origin through the center of the cell on the sphere.
    var rawPoint: S2Point {
        let projection = S2CellIdentifier.projection
        let maxSize = Double(S2CellIdentifier.maxSize)
        let (face, si, ti) = faceSiTi

        return projection.xyz(face: face,
                              u: projection.uv(st: (0.5 / maxSize) * Double(si)),
                              v: projection.uv(st: (0.5 / maxSize) * Double(ti)))
    }

    /// The center of the s2 cell on the sphere as a Point.
    /// The maximum directional error in Point (compared to the exact mathematical result)
    /// is 1.5 * epsilon radians, and the maximum length error is 2 * epsilon (the same as normalized).
    var point: S2Point {
        return rawPoint.normalized
    }

    /// LatLng returns the center of the s2 cell on the sphere as a LatLng.
    var latitudeLongitude: S2LatitudeLongitude {
        return rawPoint.latitudeLongitude
    }

    /// The return value is always non-negative.
    /// (i.e., S2CellIdentifier.face(0).childBegin(at: level))
    ///
    /// - returns: the number of steps that this cell is from the first node in the S2 heirarchy at our level.
    var distanceFromBegin: Int64 {
        return Int64(value >> UInt64(2 * (S2CellIdentifier.maxLevel - level) + 1))
    }

    /// The position in the cell ID will be truncated to correspond
    /// to the Hilbert curve position at the center of the returned cell.
    ///
    /// - parameter face: its face in the range [0, 5].
    /// - parameter position: the 61-bit Hilbert curve position pos within that face.
    /// - parameter level: the level in the range [0, maxLevel].
    init(face: Int, position: UInt64, level: Int) {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)
        assert(0 ... S2CellIdentifier.maxLevel ~= level)

        let lsb = S2CellIdentifier.leastSignificantBit(at: level)
        let value = UInt64(face) << S2CellIdentifier.positionBits + position | 1

        self.value = S2CellIdentifier.limit(value: value, with: lsb)
    }

    /// Constructs a cell identifier corresponding to a given S2 cube face.
    init(face: Int) {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        value = (UInt64(face) << S2CellIdentifier.positionBits)
            + S2CellIdentifier.leastSignificantBit(at: 0)
    }

    /// Constructs a leaf cell given its cube face (in the range [0, 5]) and IJ coordinates.
    init(face: Int, i: Int, j: Int) {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        let lookup = S2CellIdentifier.lookup
        let lookupBits = S2CellIdentifier.lookupBits
        let swapMask = S2CellIdentifier.swapMask
        let invertMask = S2CellIdentifier.invertMask
        // Note that this value gets shifted one bit to the left at the end of the function.
        var n = UInt64(face) << (S2CellIdentifier.positionBits - 1)

        // Alternating faces have opposite Hilbert curve orientations;
        // this is necessary in order for all faces to have a right-handed coordinate system.
        var bits = face & S2CellIdentifier.swapMask

        // Each iteration maps 4 bits of "i" and "j" into 8 bits of the Hilbert
        // curve position.  The lookup table transforms a 10-bit key of the form
        // "iiiijjjjoo" to a 10-bit value of the form "ppppppppoo", where the
        // letters [ijpo] denote bits of "i", "j", Hilbert curve position, and
        // Hilbert curve orientation respectively.
        for k in stride(from: 7, to: -1, by: -1) {
            let mask = (1 << lookupBits) - 1

            bits += ((i >> (k * lookupBits)) & mask) << (lookupBits + 2)
            bits += ((j >> (k * lookupBits)) & mask) << 2
            bits = lookup.positionLookup[bits]
            n |= UInt64(bits >> 2) << UInt64(k * 2 * lookupBits)
            bits &= (swapMask | invertMask)
        }

        value = n * 2 + 1
    }

    /// Constructs a leaf cell containing a given point.
    /// Usually there is exactly one such cell, but for points along the edge of a cell,
    /// any adjacent cell may be (deterministically) chosen.
    /// This is because S2CellIdentifiers are considered to be closed sets.
    /// The returned cell will always contain the given point, i.e.
    ///
    ///   S2CellIdentifier(point: p).contains(point: p)
    ///
    /// is always true.
    init(point: S2Point) {
        let projection = S2CellIdentifier.projection
        let (face, u, v) = projection.faceUV(xyz: point)
        let i = projection.ij(st: projection.st(uv: u))
        let j = projection.ij(st: projection.st(uv: v))

        self.init(face: face, i: i, j: j)
    }

    /// Constructs the leaf cell containing a given coordinate.
    init(latitudeLongitude ll: S2LatitudeLongitude) {
        self.init(point: S2Point(latitudeLongitude: ll))
    }

    /// Constructs a cell given a hex-encoded string of its uint64 ID.
    init(token: String) {
        let count = token.characters.count

        guard var value = UInt64(token, radix: 16), count <= 16 else {
            self.value = 0

            return
        }

        if count < 16 {
            value = value << (4 * (16 - UInt64(count)))
        }

        self.value = value
    }

    /// The given level must be no smaller than the cell's level.
    ///
    /// - returns: similar to childBegin at a given level deeper than this cell.
    func childBegin(at level: Int) -> S2CellIdentifier {
        assert(!isLeaf)
        assert(self.level ... S2CellIdentifier.maxLevel ~= level)

        return S2CellIdentifier(value: value - leastSignificantBit
            + S2CellIdentifier.leastSignificantBit(at: level))
    }

    /// The given level must be no smaller than the cell's level.
    /// The returned cell may be invalid.
    ///
    /// - returns: similar to childEnd at a given level deeper than this cell.
    func childEnd(at level: Int) -> S2CellIdentifier {
        assert(!isLeaf)
        assert(self.level ... S2CellIdentifier.maxLevel ~= level)

        return S2CellIdentifier(value: value + leastSignificantBit
            + S2CellIdentifier.leastSignificantBit(at: level))
    }

    /// The argumentshould be in the range 1...maxLevel.
    /// For example, childPosition(1) returns the position of
    /// this cell's level - 1 ancestor within its top-level face cell.
    ///
    /// - returns: the child position (0..3) of this cell's ancestor at the given level, relative to its parent.
    func childPosition(at level: Int) -> Int {
        assert(0 ... self.level ~= level)

        return Int(value >> UInt64(2 * (S2CellIdentifier.maxLevel - level) + 1)) & 3
    }

    /// - returns: the cell at the given level, which must be no greater than the current level.
    func parent(at level: Int) -> S2CellIdentifier {
        assert(0 ... self.level ~= level)

        let lsb = S2CellIdentifier.leastSignificantBit(at: level)

        return S2CellIdentifier(value: S2CellIdentifier.limit(value: value, with: lsb))
    }

    // Advances or retreats the indicated number of steps along the Hilbert curve at the current level,
    // and returns the new position. The position is never advanced past end or before begin.
    func advance(_ steps: Int64) -> S2CellIdentifier {
        guard steps != 0 else {
            return self
        }

        // We clamp the number of steps if necessary to ensure that we do not advance past the end
        // or before the begin of this level. Note that minSteps and maxSteps always fit in a signed 64-bit integer.
        let shift = UInt64(2 * (S2CellIdentifier.maxLevel - level) + 1)
        let wrapOffset = S2CellIdentifier.wrapOffset
        var steps = steps
        var unsignedSteps: UInt64

        if steps < 0 {
            let min = -Int64(value >> shift)

            if steps < min {
                steps = min
            }

            unsignedSteps = UInt64.subtractWithOverflow(0, UInt64(-steps)).0
        } else {
            let max = Int64((wrapOffset + leastSignificantBit - value) >> shift)

            if steps > max {
                steps = max
            }

            unsignedSteps = UInt64(steps)
        }

        return S2CellIdentifier(value: UInt64.addWithOverflow(value, unsignedSteps << shift).0)
    }

    /// Advances or retreats the indicated number of steps along the Hilbert curve at the current level
    /// and returns the new position. The position wraps between the first and last faces as necessary.
    func advanceWrap(_ steps: Int64) -> S2CellIdentifier {
        guard steps != 0 else {
            return self
        }

        // We clamp the number of steps if necessary to ensure that we do not advance past the end
        // or before the begin of this level.
        let shift = UInt64(2 * (S2CellIdentifier.maxLevel - level) + 1)
        let wrapOffset = S2CellIdentifier.wrapOffset
        var steps = steps

        if steps < 0 {
            let min = -Int64(value >> shift)

            if steps < min {
                let wrap = Int64(wrapOffset >> shift)

                steps %= wrap

                if steps < min {
                    steps += wrap
                }
            }
        } else {
            // Unlike advance, we don't want to return end(at: level).
            let max = Int64((wrapOffset - value) >> shift)

            if steps > max {
                let wrap = Int64(wrapOffset >> shift)

                steps %= wrap

                if steps > max {
                    steps -= wrap
                }
            }
        }

        let unsignedSteps = steps > 0 ? UInt64(steps)
            : UInt64.subtractWithOverflow(0, UInt64(-steps)).0

        // If steps is negative, then shifting it left has undefined behavior.
        // Cast to UInt64 for a 2's complement answer.
        return S2CellIdentifier(value: UInt64.addWithOverflow(value, unsignedSteps << shift).0)
    }

    /// - returns: the level of the common ancestor of the two S2CellIdentifiers.
    func commonAncestorLevel(identifier other: S2CellIdentifier) -> Int? {
        assert(isValid)
        assert(other.isValid)

        var bits = value ^ other.value
        let lsb = leastSignificantBit
        let otherLsb = other.leastSignificantBit

        if bits < lsb {
            bits = lsb
        }

        if bits < otherLsb {
            bits = otherLsb
        }

        let msbPosition = S2CellIdentifier.mostSignificantBitSetNonZero(bits)

        if msbPosition > 60 {
            return nil
        }

        return (60 - msbPosition) >> 1
    }

    /// Normally there are four neighbors,
    /// but the closest vertex may only have three neighbors if it is one of the 8 cube vertices.
    ///
    /// - returns: the neighboring cellIDs with vertex closest to this cell at the given level.
    func vertexNeighbors(at level: Int) -> [S2CellIdentifier] {
        let maxSize = S2CellIdentifier.maxSize
        let halfSize = S2CellIdentifier.sizeIJ(at: level + 1)
        let size = halfSize << 1
        let (face, i, j, _) = faceIJOrientation
        var (iSame, jSame) = (false, false)
        var (iOffset, jOffset) = (0, 0)

        if i & halfSize != 0 {
            iOffset = size
            iSame = (i + size) < maxSize
        } else {
            iOffset = -size
            iSame = (i - size) >= 0
        }

        if j & halfSize != 0 {
            jOffset = size
            jSame = (j + size) < maxSize
        } else {
            jOffset = -size
            jSame = (j - size) >= 0
        }

        var results = [
            parent(at: level),
            S2CellIdentifier.from(face: face, i: i + iOffset, j: j, sameFace: iSame).parent(at: level),
            S2CellIdentifier.from(face: face, i: i, j: j + jOffset, sameFace: jSame).parent(at: level)
        ]

        if iSame || jSame {
            results.append(S2CellIdentifier
                .from(face: face, i: i + iOffset, j: j + jOffset, sameFace: iSame && jSame)
                .parent(at: level))
        }

        return results
    }

    /// Two cells X and Y are neighbors if their boundaries intersect but their interiors do not.
    /// In particular, two cells that intersect at a single point are neighbors.
    /// Note that for cells adjacent to a face vertex, the same neighbor may be returned more than once.
    /// There could be up to eight neighbors including the diagonal ones that share the vertex.
    /// This requires level >= ci.Level().
    ///
    /// - returns: all neighbors of this cell at the given level.
    func allNeighbors(at level: Int) -> [S2CellIdentifier] {
        let maxSize = S2CellIdentifier.maxSize
        var neighbors = [S2CellIdentifier]()

        var (face, i, j, _) = faceIJOrientation

        // Find the coordinates of the lower left-hand leaf cell. We need to
        // normalize (i,j) to a known position within the cell because level
        // may be larger than this cell's level.
        let size = S2CellIdentifier.sizeIJ(at: self.level)

        i &= -size
        j &= -size

        let numberSize = S2CellIdentifier.sizeIJ(at: level)

        // We compute the top-bottom, left-right, and diagonal neighbors in one
        // pass. The loop test is at the end of the loop to avoid 32-bit overflow.
        var k = -numberSize

        while true {
            var sameFace = false

            if k < 0 {
                sameFace = (j + k >= 0)
            } else if k >= size {
                sameFace = (j + k < maxSize)
            } else {
                sameFace = true

                // Top and bottom neighbors.
                neighbors.append(S2CellIdentifier
                    .from(face: face, i: i + k, j: j - numberSize, sameFace: j - size >= 0)
                    .parent(at: level))
                neighbors.append(S2CellIdentifier
                    .from(face: face, i: i + k, j: j + size, sameFace: j + size < maxSize)
                    .parent(at: level))
            }

            // Left, right, and diagonal neighbors.
            neighbors.append(S2CellIdentifier
                .from(face: face, i: i - numberSize, j: j + k, sameFace: sameFace && i - size >= 0)
                .parent(at: level))
            neighbors.append(S2CellIdentifier
                .from(face: face, i: i + size, j: j + k, sameFace: sameFace && i + size < maxSize)
                .parent(at: level))

            if k >= size {
                break
            }

            k += numberSize
        }

        return neighbors
    }

    /// - returns: true iff the CellID contains the other identifier.
    func contains(identifier other: S2CellIdentifier) -> Bool {
        assert(isValid)
        assert(other.isValid)

        return rangeMinimum <= other && other <= rangeMaximum
    }

    /// - returns: true iff the CellID intersects the other identifier.
    func intersects(identifier other: S2CellIdentifier) -> Bool {
        assert(isValid)
        assert(other.isValid)

        return other.rangeMinimum <= rangeMaximum && other.rangeMaximum >= rangeMinimum
    }

    /// u' is such that the distance from the line u=u' to the given edge (u,v0)-(u,v1) is exactly the given distance
    /// (which is specified as the sine of the angle corresponding to the distance).
    ///
    /// - returns: a new u-coordinate u'
    func expandEndpoint(u: Double, maxV: Double, sinDistance: Double) -> Double {
        // This is based on solving a spherical right triangle, similar to the calculation in Cap.RectBound.
        // Given an edge of the form (u,v0)-(u,v1), let maxV = max(abs(v0), abs(v1)).
        let sinUShift = sinDistance * sqrt((1 + u * u + maxV * maxV) / (1 + u * u))
        let cosUShift = sqrt(1 - sinUShift * sinUShift)

        // The following is an expansion of tan(atan(u) + asin(sinUShift)).
        return (cosUShift * u + sinUShift) / (cosUShift - sinUShift * u)
    }

    /// Returns a rectangle expanded in (u,v)-space so that it contains all points
    /// within the given distance of the boundary, and return the smallest such rectangle.
    /// If the distance is negative, then instead shrink this rectangle so that it excludes all points
    /// within the given absolute distance of the boundary.
    ///
    /// Distances are measured *on the sphere*, not in (u,v)-space.
    /// For example, you can use this method to expand the (u,v)-bound of an CellID so that it contains
    /// all points within 5km of the original cell.
    /// You can then test whether a point lies within the expanded bounds like this:
    ///
    ///   if let uv = uv(face: face, xyz: point), bound.containsPoint(R2Point(x: u, y: v)) { ... }
    ///
    /// Limitations:
    ///
    ///  - Because the rectangle is drawn on one of the six cube-face planes (i.e., {x,y,z} = +/-1),
    ///    it can cover at most one hemisphere. This limits the maximum amount that a rectangle can be expanded.
    ///    For example, bounds can be expanded safely by at most 45 degrees (about 5000km on the Earth's surface).
    ///
    ///  - The implementation is not exact for negative distances. The resulting rectangle will exclude all points
    ///    within the given distance of the boundary but may be slightly smaller than necessary.
    func expandedByDistanceUV(uv: R2Rectangle, distance: S1Angle) -> R2Rectangle {
        // Expand each of the four sides of the rectangle just enough to include all points
        // within the given distance of that side.
        // (The rectangle may be expanded by a different amount in (u,v)-space on each side.)
        let maxU = max(abs(uv.x.low), abs(uv.x.high))
        let maxV = max(abs(uv.y.low), abs(uv.y.high))
        let sinDistance = sin(distance)

        return R2Rectangle(
            x: R1Interval(low: expandEndpoint(u: uv.x.low, maxV: maxV, sinDistance: -sinDistance),
                          high: expandEndpoint(u: uv.x.high, maxV: maxV, sinDistance: sinDistance)),
            y: R1Interval(low: expandEndpoint(u: uv.y.low, maxV: maxU, sinDistance: -sinDistance),
                          high: expandEndpoint(u: uv.y.high, maxV: maxU, sinDistance: sinDistance))
        )
    }

    /// MaxTile returns the largest cell with the same RangeMin such that
    /// RangeMax < limit.RangeMin. It returns limit if no such cell exists.
    /// This method can be used to generate a small set of CellIDs that covers
    /// a given range (a tiling). This example shows how to generate a tiling
    /// for a semi-open range of leaf cells [start, limit):
    ///
    ///   for id := start.MaxTile(limit); id != limit; id = id.next.MaxTile(limit)) { ... }
    ///
    /// Note that in general the cells in the tiling will be of different sizes;
    /// they gradually get larger (near the middle of the range) and then
    /// gradually get smaller as limit is approached.
    func maxTile(limit: S2CellIdentifier) -> S2CellIdentifier {
        let start = rangeMinimum

        if start >= limit.rangeMinimum {
            return limit
        }

        if rangeMaximum >= limit {
            // The cell is too large, shrink it. Note that when generating coverings of CellID ranges,
            // this loop usually executes only once. Also because rangeMinimum < limit.rangeMinimum,
            // we will always exit the loop by the time we reach a leaf cell.
            var ci = self

            while true {
                ci = ci.children[0]

                if ci.rangeMaximum < limit {
                    break
                }
            }

            return ci
        }

        // The cell may be too small. Grow it if necessary.
        // Note that generally this loop only iterates once.
        var ci = self

        while !ci.isFace {
            let parent = ci.parent

            if parent.rangeMinimum != start || parent.rangeMaximum >= limit {
                break
            }

            ci = parent
        }

        return ci
    }
}
