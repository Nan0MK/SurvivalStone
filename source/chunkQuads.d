import std.math : sqrt;

import raylib;

import chunkSmooth;

// Each wall is a square of this side length. A 45 degree side of the same
// length ends at side/sqrt(2) on x and z, so those corners miss the integer dots.
enum float wallSide = 2;

enum QuadKind {
    cardinal,
    diagonalWall,
    ramp,
    diagonalRamp,
    flat,
}

struct GridQuad {
    float[3][4] corner;
    QuadKind kind;
    Color color;
}

GridQuad cardinalWall(float x0, float z0, float x1, float z1, float y0, float y1, float outX, float outZ) {
    return verticalQuad(x0, z0, x1, z1, y0, y1, QuadKind.cardinal, outX, outZ);
}

GridQuad diagonalWall(float x0, float z0, float x1, float z1, float y0, float y1, float outX, float outZ) {
    return verticalQuad(x0, z0, x1, z1, y0, y1, QuadKind.diagonalWall, outX, outZ);
}

GridQuad axisRamp(float x0, float z0, float x1, float z1, float y, float rx, float ry, float rz) {
    return slopedQuad(x0, z0, x1, z1, y, rx, ry, rz, QuadKind.ramp);
}

GridQuad diagonalRamp(float x0, float z0, float x1, float z1, float y, float rx, float ry, float rz) {
    return slopedQuad(x0, z0, x1, z1, y, rx, ry, rz, QuadKind.diagonalRamp);
}

// Eight equal squares. Each ramp is another square of wallSide, at 45 degrees,
// sharing the whole bottom edge of one wall. Rise and run are both wallSide/sqrt(2).
GridQuad[] buildDemo() {
    float diag = sqrt(wallSide * wallSide * 0.5f);
    float x0 = 2;
    float x1 = x0 + wallSide;
    float z0 = 0;
    float z1 = diag;
    float z2 = diag + wallSide;
    float z3 = wallSide + diag * 2;
    float xEast = x1 + diag;
    float xWest = x0 - diag;

    GridQuad[] quads;
    quads ~= cardinalWall(x0, z0, x1, z0, 0, wallSide, 0, -1);
    quads ~= diagonalWall(x1, z0, xEast, z1, 0, wallSide, 1, -1);
    quads ~= cardinalWall(xEast, z1, xEast, z2, 0, wallSide, 1, 0);
    quads ~= diagonalWall(xEast, z2, x1, z3, 0, wallSide, 1, 1);
    quads ~= cardinalWall(x1, z3, x0, z3, 0, wallSide, 0, 1);
    quads ~= diagonalWall(x0, z3, xWest, z2, 0, wallSide, -1, 1);
    quads ~= cardinalWall(xWest, z2, xWest, z1, 0, wallSide, -1, 0);
    quads ~= diagonalWall(xWest, z1, x0, z0, 0, wallSide, -1, -1);
    float half = wallSide * 0.5f;
    quads ~= axisRamp(x0, z3, x1, z3, 0, 0, diag, diag);
    quads ~= diagonalRamp(x1, z0, xEast, z1, 0, half, diag, -half);
    return quads;
}

void drawQuads(GridQuad[] quads) {
    foreach (q; quads) {
        Vector3 a = cornerAt(q.corner[0]);
        Vector3 b = cornerAt(q.corner[1]);
        Vector3 c = cornerAt(q.corner[2]);
        Vector3 d = cornerAt(q.corner[3]);
        drawLit(a, b, c, q.color);
        drawLit(a, c, d, q.color);
    }
}

private void drawLit(Vector3 a, Vector3 b, Vector3 c, Color color) {
    float bx = b.x - a.x;
    float by = b.y - a.y;
    float bz = b.z - a.z;
    float cx = c.x - a.x;
    float cy = c.y - a.y;
    float cz = c.z - a.z;
    Vector3 normal = Vector3(by * cz - bz * cy, bz * cx - bx * cz, bx * cy - by * cx);
    DrawTriangle3D(a, b, c, shadeColor(color, normal));
}

private GridQuad verticalQuad(float x0, float z0, float x1, float z1, float y0, float y1, QuadKind kind, float outX, float outZ) {
    float dx = x1 - x0;
    float dz = z1 - z0;
    // This corner order has a normal of (dz, -dx) in the ground plane.
    if (dz * outX - dx * outZ < 0) {
        float swapX = x0;
        x0 = x1;
        x1 = swapX;
        float swapZ = z0;
        z0 = z1;
        z1 = swapZ;
    }
    GridQuad quad;
    quad.kind = kind;
    quad.color = quadColor(kind);
    quad.corner[0] = [x0, y0, z0];
    quad.corner[1] = [x0, y1, z0];
    quad.corner[2] = [x1, y1, z1];
    quad.corner[3] = [x1, y0, z1];
    return quad;
}

private GridQuad slopedQuad(float x0, float z0, float x1, float z1, float y, float rx, float ry, float rz, QuadKind kind) {
    float dx = x1 - x0;
    float dz = z1 - z0;
    // This corner order points up when rz * dx - rx * dz is positive.
    if (rz * dx - rx * dz < 0) {
        float swapX = x0;
        x0 = x1;
        x1 = swapX;
        float swapZ = z0;
        z0 = z1;
        z1 = swapZ;
    }
    GridQuad quad;
    quad.kind = kind;
    quad.color = quadColor(kind);
    quad.corner[0] = [x0, y, z0];
    quad.corner[1] = [x0 + rx, y + ry, z0 + rz];
    quad.corner[2] = [x1 + rx, y + ry, z1 + rz];
    quad.corner[3] = [x1, y, z1];
    return quad;
}

private Vector3 cornerAt(float[3] corner) {
    return Vector3(corner[0], corner[1], corner[2]);
}

private Color quadColor(QuadKind kind) {
    if (kind == QuadKind.cardinal)
        return Colors.BLUE;
    if (kind == QuadKind.diagonalWall)
        return Colors.ORANGE;
    if (kind == QuadKind.ramp)
        return Colors.GREEN;
    return Colors.YELLOW;
}

// Nodes are the wallSide lattice of one chunk, including the far face.
// A 16-unit chunk runs from its origin through origin + 16 on x, y, and z.
Vector3[] chunkNodes(Vector3 position) {
    int size = ChunkSmooth.init.chunkSize;
    int steps = size / cast(int) wallSide;
    float ox = cast(float)(chunkCoord(position.x, size) * size);
    float oy = cast(float)(chunkCoord(position.y, size) * size);
    float oz = cast(float)(chunkCoord(position.z, size) * size);
    int count = steps + 1;
    Vector3[] nodes = new Vector3[count * count * count];
    int cursor = 0;
    int iy = 0;
    while (iy <= steps) {
        int iz = 0;
        while (iz <= steps) {
            int ix = 0;
            while (ix <= steps) {
                nodes[cursor] = Vector3(
                    ox + cast(float) ix * wallSide,
                    oy + cast(float) iy * wallSide,
                    oz + cast(float) iz * wallSide,
                );
                cursor++;
                ix++;
            }
            iz++;
        }
        iy++;
    }
    return nodes;
}

private Texture2D nodeSprite;

// A white circle. DrawBillboard turns it toward the camera.
void loadNodeSprite() {
    if (nodeSprite.id != 0)
        return;
    Image image = GenImageColor(32, 32, Color(0, 0, 0, 0));
    ImageDrawCircle(&image, 16, 16, 12, Colors.WHITE);
    ImageDrawCircleLines(&image, 16, 16, 14, Colors.BLACK);
    nodeSprite = LoadTextureFromImage(image);
    UnloadImage(image);
    SetTextureFilter(nodeSprite, cast(int) TextureFilter.TEXTURE_FILTER_BILINEAR);
}

void unloadNodeSprite() {
    if (nodeSprite.id == 0)
        return;
    UnloadTexture(nodeSprite);
    nodeSprite.id = 0;
}

// Pull each dot a little toward the camera so a node on a quad stays visible.
void drawChunkNodes(Camera3D camera, Vector3 position) {
    loadNodeSprite();
    float size = 0.4f;
    float pull = size * 0.5f;
    foreach (node; chunkNodes(position)) {
        float dx = camera.position.x - node.x;
        float dy = camera.position.y - node.y;
        float dz = camera.position.z - node.z;
        float len = sqrt(dx * dx + dy * dy + dz * dz);
        Vector3 spot = node;
        if (len > 0.001f) {
            spot.x += dx / len * pull;
            spot.y += dy / len * pull;
            spot.z += dz / len * pull;
        }
        DrawBillboard(camera, nodeSprite, spot, size, Colors.WHITE);
    }
}
