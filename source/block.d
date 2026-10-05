import std.stdio;

import raylib;
import raylib.rcamera;
import raylib.rlgl;

struct BlockMesh {
    const Vector3 vertex0 = Vector3(0,0,0);
    const Vector3 vertex1 = Vector3(0,1,0);
    const Vector3 vertex2 = Vector3(0,1,1);
    const Vector3 vertex3 = Vector3(0,0,1);

    const Vector3 vertex4 = Vector3(-1,0,1);
    const Vector3 vertex5 = Vector3(-1,1,1);
    const Vector3 vertex6 = Vector3(-1,0,0);
    const Vector3 vertex7 = Vector3(-1,1,0);

    BlockMesh newMesh() {
        BlockMesh mesh;
        return mesh;
    }
    void drawMesh() {
        DrawTriangle3D(vertex0, vertex1, vertex2, Colors.GREEN);
		DrawTriangle3D(vertex0, vertex2, vertex3, Colors.DARKGREEN);
		DrawTriangle3D(vertex3, vertex2, vertex4, Colors.GREEN);
		DrawTriangle3D(vertex5, vertex4, vertex2, Colors.DARKGREEN);
		DrawTriangle3D(vertex5, vertex6, vertex4, Colors.GREEN);
		DrawTriangle3D(vertex7, vertex6, vertex5, Colors.DARKGREEN);
		DrawTriangle3D(vertex7, vertex0, vertex6, Colors.GREEN);
		DrawTriangle3D(vertex1, vertex0, vertex7, Colors.DARKGREEN);
		DrawTriangle3D(vertex2, vertex7, vertex5, Colors.GREEN);
		DrawTriangle3D(vertex7, vertex2, vertex1, Colors.DARKGREEN);
		DrawTriangle3D(vertex3, vertex4, vertex0, Colors.GREEN);
		DrawTriangle3D(vertex4, vertex6, vertex0, Colors.DARKGREEN);
    }
}
