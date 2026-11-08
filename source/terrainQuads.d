import raylib;

import material;
import chunkQuads;
import chunkSmooth;

// Posts sit on a square grid of wallSide. Height is groundHeightAt rounded to
// that same step. A cell whose far edge is one step higher is one 45 degree
// ramp across the whole cell, so that face is wider than a wall square. A taller
// step is a flat at the low edge plus a stack of vertical squares. The squares
// face the low side.
GridQuad[] buildTerrain(float originX, float originZ, int cellsX, int cellsZ) {
    int postsX = cellsX + 1;
    int postsZ = cellsZ + 1;
    int[] posts = new int[postsX * postsZ];
    int k = 0;
    while (k < postsZ) {
        int i = 0;
        while (i < postsX) {
            float x = originX + cast(float) i * wallSide;
            float z = originZ + cast(float) k * wallSide;
            posts[k * postsX + i] = heightLevel(groundHeightAt(x, z));
            i++;
        }
        k++;
    }
    return meshPosts(posts, postsX, postsZ, originX, originZ);
}

GridQuad[] meshPosts(int[] posts, int postsX, int postsZ, float originX, float originZ) {
    GridQuad[] quads;
    if (postsX < 2 || postsZ < 2)
        return quads;
    int k = 0;
    while (k < postsZ - 1) {
        int i = 0;
        while (i < postsX - 1) {
            int sw = postAt(posts, postsX, i, k);
            int se = postAt(posts, postsX, i + 1, k);
            int nw = postAt(posts, postsX, i, k + 1);
            int ne = postAt(posts, postsX, i + 1, k + 1);
            float x = originX + cast(float) i * wallSide;
            float z = originZ + cast(float) k * wallSide;
            addCell(quads, x, z, sw, se, nw, ne);
            i++;
        }
        k++;
    }
    return quads;
}

int heightLevel(float y) {
    float q = y / wallSide;
    if (q >= 0.0f)
        return cast(int)(q + 0.5f);
    return cast(int)(q - 0.5f);
}

// Walkable height of the quad that covers this point. A ramp slopes across the
// cell. A cliff is the low floor. A bent cell follows the same two triangles
// the mesh draws. The vertical squares are walls, so they are not a floor.
float quadHeightAt(float x, float z) {
    float originX = cellOrigin(x);
    float originZ = cellOrigin(z);
    int sw = heightLevel(groundHeightAt(originX, originZ));
    int se = heightLevel(groundHeightAt(originX + wallSide, originZ));
    int nw = heightLevel(groundHeightAt(originX, originZ + wallSide));
    int ne = heightLevel(groundHeightAt(originX + wallSide, originZ + wallSide));
    return cellSurface(x, z, originX, originZ, sw, se, nw, ne);
}

float cellSurface(float x, float z, float originX, float originZ, int sw, int se, int nw, int ne) {
    if (sw == se && nw == ne && sw == nw)
        return cast(float) sw * wallSide;
    if (sw == se && nw == ne)
        return riseSurface(z, originZ, sw, nw);
    if (sw == nw && se == ne)
        return riseSurface(x, originX, sw, se);
    return bentSurface(x, z, originX, originZ, sw, se, nw, ne);
}

private float cellOrigin(float p) {
    int cell = floorInt(p / wallSide);
    return cast(float) cell * wallSide;
}

// along is the coordinate that climbs. near is the low end of that axis when
// diff is positive: south for z, west for x.
private float riseSurface(float along, float origin, int near, int far) {
    int diff = far - near;
    int span = diff;
    if (span < 0)
        span = -span;
    int low = near;
    if (far < low)
        low = far;
    if (span >= 2)
        return cast(float) low * wallSide;
    float t = along - origin;
    if (diff < 0)
        t = wallSide - t;
    return cast(float) low * wallSide + t;
}

private float bentSurface(float x, float z, float originX, float originZ, int sw, int se, int nw, int ne) {
    float u = (x - originX) / wallSide;
    float v = (z - originZ) / wallSide;
    float hsw = cast(float) sw * wallSide;
    float hse = cast(float) se * wallSide;
    float hnw = cast(float) nw * wallSide;
    float hne = cast(float) ne * wallSide;
    if (u <= v)
        return (1.0f - v) * hsw + (v - u) * hnw + u * hne;
    return (1.0f - u) * hsw + v * hne + (u - v) * hse;
}

private int postAt(int[] posts, int postsX, int i, int k) {
    return posts[k * postsX + i];
}

private void addCell(ref GridQuad[] quads, float x, float z, int sw, int se, int nw, int ne) {
    float midX = x + wallSide * 0.5f;
    float midZ = z + wallSide * 0.5f;
    int top = sw;
    if (se > top)
        top = se;
    if (nw > top)
        top = nw;
    if (ne > top)
        top = ne;
    Color color = getMaterialColor(terrainMaterial(midX, cast(float) top * wallSide, midZ));

    if (sw == se && nw == ne && sw == nw) {
        quads ~= flatGround(x, z, sw, color);
        return;
    }
    if (sw == se && nw == ne) {
        addRise(quads, x, z, sw, nw, true, color);
        return;
    }
    if (sw == nw && se == ne) {
        addRise(quads, x, z, sw, se, false, color);
        return;
    }
    quads ~= bentGround(x, z, sw, se, nw, ne, color);
}

private void addRise(ref GridQuad[] quads, float x, float z, int near, int far, bool alongZ, Color color) {
    int diff = far - near;
    int span = diff;
    if (span < 0)
        span = -span;
    if (span == 0) {
        quads ~= flatGround(x, z, near, color);
        return;
    }
    if (span == 1) {
        int low = near;
        if (far < low)
            low = far;
        float y = cast(float) low * wallSide;
        GridQuad ramp;
        if (alongZ && diff > 0)
            ramp = axisRamp(x, z, x + wallSide, z, y, 0, wallSide, wallSide);
        else if (alongZ)
            ramp = axisRamp(x, z + wallSide, x + wallSide, z + wallSide, y, 0, wallSide, -wallSide);
        else if (diff > 0)
            ramp = axisRamp(x, z, x, z + wallSide, y, wallSide, wallSide, 0);
        else
            ramp = axisRamp(x + wallSide, z, x + wallSide, z + wallSide, y, -wallSide, wallSide, 0);
        ramp.color = color;
        quads ~= ramp;
        return;
    }
    int floor = near;
    if (far < floor)
        floor = far;
    quads ~= flatGround(x, z, floor, color);
    float y0 = cast(float) floor * wallSide;
    int step = 0;
    while (step < span) {
        float y = y0 + cast(float) step * wallSide;
        GridQuad wall;
        if (alongZ && diff > 0)
            wall = cardinalWall(x, z + wallSide, x + wallSide, z + wallSide, y, y + wallSide, 0, 1);
        else if (alongZ)
            wall = cardinalWall(x, z, x + wallSide, z, y, y + wallSide, 0, -1);
        else if (diff > 0)
            wall = cardinalWall(x + wallSide, z, x + wallSide, z + wallSide, y, y + wallSide, -1, 0);
        else
            wall = cardinalWall(x, z, x, z + wallSide, y, y + wallSide, 1, 0);
        wall.color = color;
        quads ~= wall;
        step++;
    }
}

private GridQuad flatGround(float x, float z, int level, Color color) {
    float y = cast(float) level * wallSide;
    GridQuad quad;
    quad.kind = QuadKind.flat;
    quad.color = color;
    quad.corner[0] = [x, y, z];
    quad.corner[1] = [x, y, z + wallSide];
    quad.corner[2] = [x + wallSide, y, z + wallSide];
    quad.corner[3] = [x + wallSide, y, z];
    return quad;
}

private GridQuad bentGround(float x, float z, int sw, int se, int nw, int ne, Color color) {
    GridQuad quad;
    quad.kind = QuadKind.flat;
    quad.color = color;
    quad.corner[0] = [x, cast(float) sw * wallSide, z];
    quad.corner[1] = [x, cast(float) nw * wallSide, z + wallSide];
    quad.corner[2] = [x + wallSide, cast(float) ne * wallSide, z + wallSide];
    quad.corner[3] = [x + wallSide, cast(float) se * wallSide, z];
    return quad;
}
