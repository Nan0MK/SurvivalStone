import std.stdio;

import raylib;
import raylib.rcamera;
// import raylib.rlgl;


/// The visual aspect of a block.
/// Contains the vertecies and capabilities to draw each face.
struct BlockMesh {
    Vector3 vertex0 = Vector3(0,0,0);
    Vector3 vertex1 = Vector3(0,1,0);
    Vector3 vertex2 = Vector3(0,1,1);
    Vector3 vertex3 = Vector3(0,0,1);

    Vector3 vertex4 = Vector3(-1,0,1);
    Vector3 vertex5 = Vector3(-1,1,1);
    Vector3 vertex6 = Vector3(-1,0,0);
    Vector3 vertex7 = Vector3(-1,1,0);

    /// EAST face
    void drawEAST(Vector3 offset = Vector3(0,0,0)) {
        DrawTriangle3D(vertex0 + offset, vertex1 + offset, vertex2 + offset, Colors.RED);
		DrawTriangle3D(vertex0 + offset, vertex2 + offset, vertex3 + offset, Colors.RED);
    }
    void drawWEST(Vector3 offset = Vector3(0,0,0)) {
        /// draw WEST face
        DrawTriangle3D(vertex5 + offset, vertex6 + offset, vertex4 + offset, Colors.MAROON);
		DrawTriangle3D(vertex7 + offset, vertex6 + offset, vertex5 + offset, Colors.MAROON);
    }
    void drawNORTH(Vector3 offset = Vector3(0,0,0)) {
        /// draw NORTH face
        DrawTriangle3D(vertex7 + offset, vertex0 + offset, vertex6 + offset, Colors.BLUE);
		DrawTriangle3D(vertex1 + offset, vertex0 + offset, vertex7 + offset, Colors.BLUE);
    }
    void drawSOUTH(Vector3 offset = Vector3(0,0,0)) {
        /// draw SOUTH face
        DrawTriangle3D(vertex3 + offset, vertex2 + offset, vertex4 + offset, Colors.DARKBLUE);
		DrawTriangle3D(vertex5 + offset, vertex4 + offset, vertex2 + offset, Colors.DARKBLUE);
    }
    void drawUP(Vector3 offset = Vector3(0,0,0)) {
        /// draw UP face
        DrawTriangle3D(vertex2 + offset, vertex7 + offset, vertex5 + offset, Colors.GREEN);
		DrawTriangle3D(vertex7 + offset, vertex2 + offset, vertex1 + offset, Colors.GREEN);
    }
    void drawDOWN(Vector3 offset = Vector3(0,0,0)) {
        /// draw DOWN face
        DrawTriangle3D(vertex3 + offset, vertex4 + offset, vertex0 + offset, Colors.DARKGREEN);
		DrawTriangle3D(vertex4 + offset, vertex6 + offset, vertex0 + offset, Colors.DARKGREEN);
    }

    void drawMesh(Vector3 offset = Vector3(0,0,0)) {
		drawEAST(offset);
		drawWEST(offset);
		drawNORTH(offset);
		drawSOUTH(offset);
		drawUP(offset);
		drawDOWN(offset);
    }
}

struct Chunk {
    const int chunkSize = 16;
    const int chunkSize3D = chunkSize * chunkSize * chunkSize;
    Vector3[chunkSize3D] blockData; /// should be 48
    BlockMesh[chunkSize3D] meshData;

    /// X then Z then Y = Y{ Z{ X{placement} } }
    void populateChunk() {
        int i = chunkSize3D;
        int y = chunkSize;
        while(y > 0 ) {
            int z = chunkSize;
            while(z > 0) {
                int x = chunkSize;
                while(x > 0) {
                    Vector3 blockPosition = Vector3(x, y, z);
                    blockData[i - 1] = blockPosition;
                    i -= 1;
                    x -= 1;
                }
                z -= 1;
            }
            y -= 1;
        }

        int j = chunkSize3D - 1;
        while(j > -1){
            BlockMesh newMesh;
            meshData[j] = newMesh;
            j -= 1;
        }
    }

    void drawChunk() {
        int i = chunkSize3D - 1;
        while(i > -1){
            Vector3 newOffset = blockData[i];
            meshData[i].drawMesh(newOffset);
            i -= 1;
        }
    }
}
