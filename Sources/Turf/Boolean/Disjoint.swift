//
//  Disjoint.swift
//  Turf
//
//  Created by Sean Coker on 3/7/21.
//

/**
 * Boolean-disjoint returns (TRUE) if the intersection of the two geometries is an empty set.
 *
 * @name booleanDisjoint
 * @param {Geometry|Feature<any>} feature1 GeoJSON Feature or Geometry
 * @param {Geometry|Feature<any>} feature2 GeoJSON Feature or Geometry
 * @returns {boolean} true/false
 * @example
 * var point = turf.point([2, 2]);
 * var line = turf.lineString([[1, 1], [1, 2], [1, 3], [1, 4]]);
 *
 * turf.booleanDisjoint(line, point);
 * //=true
 */
func booleanDisjoint(feature1: Any, feature2: Any) -> Bool {
    let bool = true
    flattenEach(feature1, { (flatten1) in
        flattenEach(feature2, { (flatten2) in
            if (bool == false) {
                return false
            }
            bool = disjoint(flatten1.geometry, flatten2.geometry)
        })
    })
    return bool
}

/**
 * Disjoint operation for simple Geometries (Point/LineString/Polygon)
 *
 * @private
 * @param {Geometry<any>} geom1 GeoJSON Geometry
 * @param {Geometry<any>} geom2 GeoJSON Geometry
 * @returns {boolean} true/false
 */
private func disjoint(geom1: Any, geom2: Any) -> Bool {
    switch (geom1) {
    case is Point:
        switch (geom2) {
        case is Point:
            return !compareCoords(pair1: (geom1 as! Point).coordinates, pair2: (geom2 as! Point).coordinates)
        case is LineString:
            return !isPointOnLine(lineString: geom2 as! LineString, pt: geom1 as! Point)
        case is Polygon:
            return !(geom2 as! Polygon).contains((geom1 as! Point).coordinates)
        default:
            return false
        }

    case is LineString:
        switch (geom2) {
        case is Point:
            return !isPointOnLine(lineString: geom1 as! LineString, pt: geom2 as! Point)
        case is LineString:
            return !isLineOnLine(lineString1: geom1 as! LineString, lineString2: geom2 as! LineString)
        case is Polygon:
            return !isLineInPoly(polygon: geom2 as! Polygon, lineString: geom1 as! LineString)
        default:
            return false
        }

    case is Polygon:
        switch (geom2) {
        case is Point:
            return !(geom1 as! Polygon).contains((geom2 as! Point).coordinates)
        case is LineString:
            return !isLineInPoly(polygon: geom1 as! Polygon, lineString: geom2 as! LineString)
        case is Polygon:
            return !isPolyInPoly(feature1: geom2 as! Polygon, feature2: geom1 as! Polygon)
        default:
            return false
        }

    default:
        return false
    }
}

// http://stackoverflow.com/a/11908158/1979085
private func isPointOnLine(lineString: LineString, pt: Point) -> Bool {
    (0..<lineString.coordinates.count).forEach({ i in
        if (
            isPointOnLineSegment(
                lineSegmentStart: lineString.coordinates[i],
                lineSegmentEnd: lineString.coordinates[i + 1],
                pt: pt.coordinates
            )
        ) {
            return true
        }
    })

    return false
}

private func isLineOnLine(lineString1: LineString, lineString2: LineString) -> Bool {
    let doLinesIntersect = intersection(lineString1, lineString2)

    if (doLinesIntersect.features.length > 0) {
        return true
    }

    return false
}

private func isLineInPoly(polygon: Polygon, lineString: LineString) -> Bool {
    for coord in lineString.coordinates {
        if (polygon.contains(coord)) {
            return true
        }
    }

    let doLinesIntersect = intersection(lineString, LineString(polygon.coordinates))

    if (doLinesIntersect.features.length > 0) {
        return true
    }

    return false
}

/**
 * Is Polygon (geom1) in Polygon (geom2)
 * Only takes into account outer rings
 * See http://stackoverflow.com/a/4833823/1979085
 *
 * @private
 * @param {Geometry|Feature<Polygon>} feature1 Polygon1
 * @param {Geometry|Feature<Polygon>} feature2 Polygon2
 * @returns {boolean} true/false
 */
private func isPolyInPoly(feature1: Polygon, feature2: Polygon) -> Bool {
    for coord1 in feature1.coordinates[0] {
        if (feature2.contains(coord1)) {
            return true
        }
    }

    for coord2 in feature2.coordinates[0] {
        if (feature1.contains(coord2)) {
            return true;
        }
    }

    let doLinesIntersect = intersection(
        LineString(feature1.coordinates),
        LineString(feature2.coordinates)
    );

    if (doLinesIntersect.features.length > 0) {
        return true
    }

    return false
}

private func isPointOnLineSegment(lineSegmentStart: LocationCoordinate2D, lineSegmentEnd: LocationCoordinate2D, pt: LocationCoordinate2D) -> Bool {
    let dxc = pt.latitude - lineSegmentStart.latitude
    let dyc = pt.longitude - lineSegmentStart.longitude
    let dxl = lineSegmentEnd.latitude - lineSegmentStart.latitude
    let dyl = lineSegmentEnd.longitude - lineSegmentStart.longitude
    let cross = dxc * dyl - dyc * dxl

    if (cross != 0) {
        return false
    }

    if (abs(dxl) >= abs(dyl)) {
        if (dxl > 0) {
            return lineSegmentStart.latitude <= pt.latitude && pt.latitude <= lineSegmentEnd.latitude
        }

        return lineSegmentEnd.latitude <= pt.latitude && pt.latitude <= lineSegmentStart.latitude
    }

    if (dyl > 0) {
        return lineSegmentStart.longitude <= pt.longitude && pt.longitude <= lineSegmentEnd.longitude
    }

    return lineSegmentEnd.longitude <= pt.longitude && pt.longitude <= lineSegmentStart.longitude
}

/**
 * compareCoords
 *
 * @private
 * @param {Position} pair1 point [x,y]
 * @param {Position} pair2 point [x,y]
 * @returns {boolean} true/false if coord pairs match
 */
func compareCoords(pair1: LocationCoordinate2D, pair2: LocationCoordinate2D) -> Bool {
    return pair1.latitude == pair2.latitude && pair1.longitude == pair2.longitude;
}
