import std.stdio;

import raylib;
import block;

enum int
    EAST = 0,
    WEST = 1,
    NORTH = 2,
    SOUTH = 3,
    UP = 4,
    DOWN = 5;

struct Chunk {
    const int chunkSize = 16;
    const int chunkSize3D = chunkSize * chunkSize * chunkSize;
    Vector3[chunkSize3D] blockData; /// should be 48
    BlockMesh[chunkSize3D] meshData;

    int xOut(int index) {
        return index % chunkSize;
    }
    int yOut(int index) {
        return (index / chunkSize) % chunkSize;
    }
    int zOut(int index) {
        return index / (chunkSize * chunkSize);
    }

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


struct Chunk2 {
    const int chunkSize = 16;
    const int chunkSize3D = chunkSize * chunkSize * chunkSize;
    int      [chunkSize3D] chunkData;
    BlockMesh[chunkSize3D] chunkMesh;

    int xOut(int index) { return index % chunkSize; }
    int yOut(int index) { return (index / chunkSize) % chunkSize; }
    int zOut(int index) { return index / (chunkSize * chunkSize); }

    int chunkIndex(int x, int y, int z) {
        return x + y*chunkSize + z*chunkSize * chunkSize;
    }

    bool inChunk(int x, int y, int z) {
        return x >= 0 && x < chunkSize &&
               y >= 0 && y < chunkSize &&
               z >= 0 && z < chunkSize;
    }

    int getNeighbor(int index, int dir) {
        int x = xOut(index);
        int y = yOut(index);
        int z = zOut(index);

        final switch(dir) {
            case EAST:   x += 1; break;
            case WEST:   x -= 1; break;
            case NORTH:  z -= 1; break; // pick one axis and stay with it
            case SOUTH:  z += 1; break;
            case UP:     y += 1; break;
            case DOWN:   y -= 1; break;
        }

        if (!inChunk(x, y, z))
                return -1;
        return chunkData[chunkIndex(x, y, z)];
    }

    // X then Z then Y = Y{ Z{ X{placement} } }
    void populateChunk() {
        // int i = chunkSize3D;
        int y = chunkSize;
        while(y > 0 ) {
            int z = chunkSize;
            while(z > 0) {
                int x = chunkSize;
                while(x > 0) {
                    int i = x + (y*chunkSize-1) + (z*(chunkSize-1 * chunkSize-1));
                    chunkData[i] = getBlockID(BlockType.TEST);
                    x -= 1;
                }
                z -= 1;
            }
            y -= 1;
        }

        int j = chunkSize3D - 1;
        while(j > -1){
            BlockMesh newMesh;
            chunkMesh[j] = newMesh;
            j -= 1;
        }
    }

    void drawChunk() {
        int i = 0;
        while(i < chunkSize3D){
            if(getNeighbor(i, WEST) != getBlockID(BlockType.TEST) ){
                Vector3 newOffset = Vector3(xOut(i), yOut(i), zOut(i));
                chunkMesh[i].drawEAST(newOffset);
            }

            // Vector3 newOffset = Vector3(xOut(i), yOut(i), zOut(i));
            // chunkMesh[i].drawMesh(newOffset);
            i += 1;
        }
    }
}
