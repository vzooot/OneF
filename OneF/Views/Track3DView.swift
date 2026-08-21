import SwiftUI
import SceneKit

/// Interactive 3D circuit map: the real track centerline extruded into a
/// ribbon, with a glowing racing line, corner markers, and a start gate.
/// Slowly auto-rotates; drag to orbit, pinch to zoom.
struct Track3DView: UIViewRepresentable {
    let map: TrackMap

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.allowsCameraControl = true
        view.antialiasingMode = .multisampling4X
        view.scene = TrackSceneBuilder.build(map: map)
        context.coordinator.circuitName = map.circuitName
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        guard context.coordinator.circuitName != map.circuitName else { return }
        context.coordinator.circuitName = map.circuitName
        view.scene = TrackSceneBuilder.build(map: map)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var circuitName: String?
    }
}

enum TrackSceneBuilder {
    static func build(map: TrackMap) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let points = normalizedPoints(map: map)
        guard points.count > 2 else { return scene }

        // Spinner carries the slow auto-rotation; the flat track node inside it
        // holds everything positioned in the 2D map plane.
        let spinner = SCNNode()
        let flat = SCNNode()
        flat.eulerAngles.x = -.pi / 2
        spinner.addChildNode(flat)
        scene.rootNode.addChildNode(spinner)

        // Asphalt ribbon with a hint of thickness (top face + slightly lower
        // shadow face reads as a slab from shallow angles).
        let asphalt = SCNMaterial()
        asphalt.diffuse.contents = UIColor(white: 0.17, alpha: 1)
        asphalt.specular.contents = UIColor(white: 0.3, alpha: 1)
        asphalt.isDoubleSided = true
        let ribbon = SCNNode(geometry: ribbonGeometry(points: points, halfWidth: 0.22, material: asphalt))
        flat.addChildNode(ribbon)

        let edge = SCNMaterial()
        edge.lightingModel = .constant
        edge.diffuse.contents = UIColor(white: 0.32, alpha: 1)
        edge.isDoubleSided = true
        let underlay = SCNNode(geometry: ribbonGeometry(points: points, halfWidth: 0.26, material: edge))
        underlay.position.z = -0.03
        flat.addChildNode(underlay)

        // Glowing racing line, floating just above the asphalt.
        let glow = SCNMaterial()
        glow.lightingModel = .constant
        glow.diffuse.contents = UIColor(red: 0.882, green: 0.024, blue: 0, alpha: 1)
        glow.emission.contents = UIColor(red: 1.0, green: 0.15, blue: 0.1, alpha: 1)
        glow.isDoubleSided = true
        let line = SCNNode(geometry: ribbonGeometry(points: points, halfWidth: 0.05, material: glow))
        line.position.z = 0.02
        flat.addChildNode(line)

        // Start/finish gate at the first centerline point.
        let gate = SCNNode(geometry: SCNBox(width: 0.55, height: 0.07, length: 0.16, chamferRadius: 0.01))
        gate.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        gate.geometry?.firstMaterial?.emission.contents = UIColor(white: 0.7, alpha: 1)
        gate.position = SCNVector3(points[0].x, points[0].y, 0.06)
        let next = points[1]
        gate.eulerAngles.z = Float(atan2(next.y - points[0].y, next.x - points[0].x)) + .pi / 2
        flat.addChildNode(gate)

        // Corner number markers.
        for corner in map.corners {
            let p = normalize(corner.trackPosition.x, corner.trackPosition.y, map: map)
            let text = SCNText(string: "\(corner.number)", extrusionDepth: 0.4)
            text.font = UIFont.systemFont(ofSize: 5, weight: .heavy)
            text.flatness = 0.2
            text.firstMaterial?.lightingModel = .constant
            text.firstMaterial?.diffuse.contents = UIColor(white: 0.85, alpha: 1)

            let node = SCNNode(geometry: text)
            node.scale = SCNVector3(0.055, 0.055, 0.055)
            // Center the glyph on the corner position, lifted off the track.
            let (minB, maxB) = text.boundingBox
            node.pivot = SCNMatrix4MakeTranslation((maxB.x + minB.x) / 2, (maxB.y + minB.y) / 2, 0)
            node.position = SCNVector3(p.x, p.y, 0.4)
            node.constraints = [SCNBillboardConstraint()]
            flat.addChildNode(node)
        }

        // Slow orbit; user gestures move the camera independently.
        spinner.runAction(.repeatForever(.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 45)))

        // Lights.
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 350
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 750
        sun.eulerAngles = SCNVector3(-Float.pi / 3, 0.4, 0)
        scene.rootNode.addChildNode(sun)

        // Camera with a touch of bloom so the racing line glows.
        let camera = SCNCamera()
        camera.wantsHDR = true
        camera.bloomIntensity = 0.8
        camera.bloomThreshold = 0.45
        camera.zFar = 200
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 7.5, 10.5)
        cameraNode.constraints = [SCNLookAtConstraint(target: spinner)]
        scene.rootNode.addChildNode(cameraNode)

        return scene
    }

    // MARK: - Geometry helpers

    /// Center-of-mass and scale used to map decimeter coordinates into a
    /// roughly 10-unit-wide scene.
    private static func bounds(map: TrackMap) -> (cx: Double, cy: Double, scale: Double) {
        let minX = map.x.min() ?? 0, maxX = map.x.max() ?? 1
        let minY = map.y.min() ?? 0, maxY = map.y.max() ?? 1
        let span = max(maxX - minX, maxY - minY, 1)
        return ((minX + maxX) / 2, (minY + maxY) / 2, 10.0 / span)
    }

    private static func normalize(_ x: Double, _ y: Double, map: TrackMap) -> (x: Float, y: Float) {
        let b = bounds(map: map)
        return (Float((x - b.cx) * b.scale), Float((y - b.cy) * b.scale))
    }

    private static func normalizedPoints(map: TrackMap) -> [(x: Float, y: Float)] {
        guard map.x.count == map.y.count else { return [] }
        return zip(map.x, map.y).map { normalize($0, $1, map: map) }
    }

    /// Builds the track ribbon as an explicit closed triangle strip between
    /// the centerline offset left and right — no triangulation involved, so
    /// it can never accidentally fill the infield.
    private static func ribbonGeometry(
        points: [(x: Float, y: Float)], halfWidth: Float, material: SCNMaterial
    ) -> SCNGeometry {
        let n = points.count
        var vertices: [SCNVector3] = []
        vertices.reserveCapacity(2 * (n + 1))

        for i in 0...n {
            let index = i % n
            let prev = points[(index - 1 + n) % n]
            let next = points[(index + 1) % n]
            var dx = next.x - prev.x
            var dy = next.y - prev.y
            let len = max(sqrt(dx * dx + dy * dy), 0.0001)
            dx /= len
            dy /= len
            let p = points[index]
            vertices.append(SCNVector3(p.x - dy * halfWidth, p.y + dx * halfWidth, 0))
            vertices.append(SCNVector3(p.x + dy * halfWidth, p.y - dx * halfWidth, 0))
        }

        let normals = [SCNVector3](repeating: SCNVector3(0, 0, 1), count: vertices.count)
        let indices = (0..<UInt32(vertices.count)).map { $0 }
        let geometry = SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: vertices),
                SCNGeometrySource(normals: normals),
            ],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangleStrip)]
        )
        geometry.materials = [material]
        return geometry
    }
}
