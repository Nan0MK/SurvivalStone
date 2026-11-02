import std.math : sqrt;

import raylib;

import material;

// Bourke marching-cubes corners. Corner 0 is (x, y, z). Y is up.
// 0 (x,   y,   z)    1 (x+1, y,   z)    2 (x+1, y,   z+1)  3 (x,   y,   z+1)
// 4 (x,   y+1, z)    5 (x+1, y+1, z)    6 (x+1, y+1, z+1)  7 (x,   y+1, z+1)
immutable int[3][8] cornerOffset = [
    [0, 0, 0],
    [1, 0, 0],
    [1, 0, 1],
    [0, 0, 1],
    [0, 1, 0],
    [1, 1, 0],
    [1, 1, 1],
    [0, 1, 1],
];

// Each edge joins two corners. The bit in edgeTable is 1 << edge.
immutable int[2][12] edgeCorners = [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 0],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 4],
    [0, 4],
    [1, 5],
    [2, 6],
    [3, 7],
];

// Bourke's edge and triangle tables. The cube index bit is set for an inside corner.
immutable int[256] edgeTable = [
    0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
    0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
    0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
    0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
    0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
    0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
    0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
    0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
    0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
    0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
    0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
    0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
    0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
    0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
    0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
    0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
    0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
    0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
    0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
    0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
    0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
    0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
    0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
    0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
    0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
    0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
    0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
    0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
    0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
    0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
    0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
    0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
];

immutable int[16][256] triTable = [
    [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 1, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 8, 3, 9, 8, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 3, 1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [9, 2, 10, 0, 2, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [2, 8, 3, 2, 10, 8, 10, 9, 8, -1, -1, -1, -1, -1, -1, -1],
    [3, 11, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 11, 2, 8, 11, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 9, 0, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 11, 2, 1, 9, 11, 9, 8, 11, -1, -1, -1, -1, -1, -1, -1],
    [3, 10, 1, 11, 10, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 10, 1, 0, 8, 10, 8, 11, 10, -1, -1, -1, -1, -1, -1, -1],
    [3, 9, 0, 3, 11, 9, 11, 10, 9, -1, -1, -1, -1, -1, -1, -1],
    [9, 8, 10, 10, 8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 7, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 3, 0, 7, 3, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 1, 9, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 1, 9, 4, 7, 1, 7, 3, 1, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 10, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [3, 4, 7, 3, 0, 4, 1, 2, 10, -1, -1, -1, -1, -1, -1, -1],
    [9, 2, 10, 9, 0, 2, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1],
    [2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4, -1, -1, -1, -1],
    [8, 4, 7, 3, 11, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [11, 4, 7, 11, 2, 4, 2, 0, 4, -1, -1, -1, -1, -1, -1, -1],
    [9, 0, 1, 8, 4, 7, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1],
    [4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1, -1, -1, -1, -1],
    [3, 10, 1, 3, 11, 10, 7, 8, 4, -1, -1, -1, -1, -1, -1, -1],
    [1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4, -1, -1, -1, -1],
    [4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3, -1, -1, -1, -1],
    [4, 7, 11, 4, 11, 9, 9, 11, 10, -1, -1, -1, -1, -1, -1, -1],
    [9, 5, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [9, 5, 4, 0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 5, 4, 1, 5, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [8, 5, 4, 8, 3, 5, 3, 1, 5, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 10, 9, 5, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [3, 0, 8, 1, 2, 10, 4, 9, 5, -1, -1, -1, -1, -1, -1, -1],
    [5, 2, 10, 5, 4, 2, 4, 0, 2, -1, -1, -1, -1, -1, -1, -1],
    [2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8, -1, -1, -1, -1],
    [9, 5, 4, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 11, 2, 0, 8, 11, 4, 9, 5, -1, -1, -1, -1, -1, -1, -1],
    [0, 5, 4, 0, 1, 5, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1],
    [2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5, -1, -1, -1, -1],
    [10, 3, 11, 10, 1, 3, 9, 5, 4, -1, -1, -1, -1, -1, -1, -1],
    [4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10, -1, -1, -1, -1],
    [5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3, -1, -1, -1, -1],
    [5, 4, 8, 5, 8, 10, 10, 8, 11, -1, -1, -1, -1, -1, -1, -1],
    [9, 7, 8, 5, 7, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [9, 3, 0, 9, 5, 3, 5, 7, 3, -1, -1, -1, -1, -1, -1, -1],
    [0, 7, 8, 0, 1, 7, 1, 5, 7, -1, -1, -1, -1, -1, -1, -1],
    [1, 5, 3, 3, 5, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [9, 7, 8, 9, 5, 7, 10, 1, 2, -1, -1, -1, -1, -1, -1, -1],
    [10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3, -1, -1, -1, -1],
    [8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2, -1, -1, -1, -1],
    [2, 10, 5, 2, 5, 3, 3, 5, 7, -1, -1, -1, -1, -1, -1, -1],
    [7, 9, 5, 7, 8, 9, 3, 11, 2, -1, -1, -1, -1, -1, -1, -1],
    [9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11, -1, -1, -1, -1],
    [2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7, -1, -1, -1, -1],
    [11, 2, 1, 11, 1, 7, 7, 1, 5, -1, -1, -1, -1, -1, -1, -1],
    [9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11, -1, -1, -1, -1],
    [5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0, -1],
    [11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0, -1],
    [11, 10, 5, 7, 11, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [10, 6, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 3, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [9, 0, 1, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 8, 3, 1, 9, 8, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1],
    [1, 6, 5, 2, 6, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 6, 5, 1, 2, 6, 3, 0, 8, -1, -1, -1, -1, -1, -1, -1],
    [9, 6, 5, 9, 0, 6, 0, 2, 6, -1, -1, -1, -1, -1, -1, -1],
    [5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8, -1, -1, -1, -1],
    [2, 3, 11, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [11, 0, 8, 11, 2, 0, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1],
    [0, 1, 9, 2, 3, 11, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1],
    [5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11, -1, -1, -1, -1],
    [6, 3, 11, 6, 5, 3, 5, 1, 3, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6, -1, -1, -1, -1],
    [3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9, -1, -1, -1, -1],
    [6, 5, 9, 6, 9, 11, 11, 9, 8, -1, -1, -1, -1, -1, -1, -1],
    [5, 10, 6, 4, 7, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 3, 0, 4, 7, 3, 6, 5, 10, -1, -1, -1, -1, -1, -1, -1],
    [1, 9, 0, 5, 10, 6, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1],
    [10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4, -1, -1, -1, -1],
    [6, 1, 2, 6, 5, 1, 4, 7, 8, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7, -1, -1, -1, -1],
    [8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6, -1, -1, -1, -1],
    [7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9, -1],
    [3, 11, 2, 7, 8, 4, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1],
    [5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11, -1, -1, -1, -1],
    [0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6, -1, -1, -1, -1],
    [9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6, -1],
    [8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6, -1, -1, -1, -1],
    [5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11, -1],
    [0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7, -1],
    [6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9, -1, -1, -1, -1],
    [10, 4, 9, 6, 4, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 10, 6, 4, 9, 10, 0, 8, 3, -1, -1, -1, -1, -1, -1, -1],
    [10, 0, 1, 10, 6, 0, 6, 4, 0, -1, -1, -1, -1, -1, -1, -1],
    [8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10, -1, -1, -1, -1],
    [1, 4, 9, 1, 2, 4, 2, 6, 4, -1, -1, -1, -1, -1, -1, -1],
    [3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4, -1, -1, -1, -1],
    [0, 2, 4, 4, 2, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [8, 3, 2, 8, 2, 4, 4, 2, 6, -1, -1, -1, -1, -1, -1, -1],
    [10, 4, 9, 10, 6, 4, 11, 2, 3, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6, -1, -1, -1, -1],
    [3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10, -1, -1, -1, -1],
    [6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1, -1],
    [9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3, -1, -1, -1, -1],
    [8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1, -1],
    [3, 11, 6, 3, 6, 0, 0, 6, 4, -1, -1, -1, -1, -1, -1, -1],
    [6, 4, 8, 11, 6, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [7, 10, 6, 7, 8, 10, 8, 9, 10, -1, -1, -1, -1, -1, -1, -1],
    [0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10, -1, -1, -1, -1],
    [10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0, -1, -1, -1, -1],
    [10, 6, 7, 10, 7, 1, 1, 7, 3, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7, -1, -1, -1, -1],
    [2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9, -1],
    [7, 8, 0, 7, 0, 6, 6, 0, 2, -1, -1, -1, -1, -1, -1, -1],
    [7, 3, 2, 6, 7, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7, -1, -1, -1, -1],
    [2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7, -1],
    [1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11, -1],
    [11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1, -1, -1, -1, -1],
    [8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6, -1],
    [0, 9, 1, 11, 6, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0, -1, -1, -1, -1],
    [7, 11, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [7, 6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [3, 0, 8, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 1, 9, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [8, 1, 9, 8, 3, 1, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1],
    [10, 1, 2, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 10, 3, 0, 8, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1],
    [2, 9, 0, 2, 10, 9, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1],
    [6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8, -1, -1, -1, -1],
    [7, 2, 3, 6, 2, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [7, 0, 8, 7, 6, 0, 6, 2, 0, -1, -1, -1, -1, -1, -1, -1],
    [2, 7, 6, 2, 3, 7, 0, 1, 9, -1, -1, -1, -1, -1, -1, -1],
    [1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6, -1, -1, -1, -1],
    [10, 7, 6, 10, 1, 7, 1, 3, 7, -1, -1, -1, -1, -1, -1, -1],
    [10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8, -1, -1, -1, -1],
    [0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7, -1, -1, -1, -1],
    [7, 6, 10, 7, 10, 8, 8, 10, 9, -1, -1, -1, -1, -1, -1, -1],
    [6, 8, 4, 11, 8, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [3, 6, 11, 3, 0, 6, 0, 4, 6, -1, -1, -1, -1, -1, -1, -1],
    [8, 6, 11, 8, 4, 6, 9, 0, 1, -1, -1, -1, -1, -1, -1, -1],
    [9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6, -1, -1, -1, -1],
    [6, 8, 4, 6, 11, 8, 2, 10, 1, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6, -1, -1, -1, -1],
    [4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9, -1, -1, -1, -1],
    [10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3, -1],
    [8, 2, 3, 8, 4, 2, 4, 6, 2, -1, -1, -1, -1, -1, -1, -1],
    [0, 4, 2, 4, 6, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8, -1, -1, -1, -1],
    [1, 9, 4, 1, 4, 2, 2, 4, 6, -1, -1, -1, -1, -1, -1, -1],
    [8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1, -1, -1, -1, -1],
    [10, 1, 0, 10, 0, 6, 6, 0, 4, -1, -1, -1, -1, -1, -1, -1],
    [4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3, -1],
    [10, 9, 4, 6, 10, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 9, 5, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 3, 4, 9, 5, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1],
    [5, 0, 1, 5, 4, 0, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1],
    [11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5, -1, -1, -1, -1],
    [9, 5, 4, 10, 1, 2, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1],
    [6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5, -1, -1, -1, -1],
    [7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2, -1, -1, -1, -1],
    [3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6, -1],
    [7, 2, 3, 7, 6, 2, 5, 4, 9, -1, -1, -1, -1, -1, -1, -1],
    [9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7, -1, -1, -1, -1],
    [3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0, -1, -1, -1, -1],
    [6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8, -1],
    [9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7, -1, -1, -1, -1],
    [1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4, -1],
    [4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10, -1],
    [7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10, -1, -1, -1, -1],
    [6, 9, 5, 6, 11, 9, 11, 8, 9, -1, -1, -1, -1, -1, -1, -1],
    [3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5, -1, -1, -1, -1],
    [0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11, -1, -1, -1, -1],
    [6, 11, 3, 6, 3, 5, 5, 3, 1, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6, -1, -1, -1, -1],
    [0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10, -1],
    [11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5, -1],
    [6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3, -1, -1, -1, -1],
    [5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2, -1, -1, -1, -1],
    [9, 5, 6, 9, 6, 0, 0, 6, 2, -1, -1, -1, -1, -1, -1, -1],
    [1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8, -1],
    [1, 5, 6, 2, 1, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6, -1],
    [10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0, -1, -1, -1, -1],
    [0, 3, 8, 5, 6, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [10, 5, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [11, 5, 10, 7, 5, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [11, 5, 10, 11, 7, 5, 8, 3, 0, -1, -1, -1, -1, -1, -1, -1],
    [5, 11, 7, 5, 10, 11, 1, 9, 0, -1, -1, -1, -1, -1, -1, -1],
    [10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1, -1, -1, -1, -1],
    [11, 1, 2, 11, 7, 1, 7, 5, 1, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11, -1, -1, -1, -1],
    [9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7, -1, -1, -1, -1],
    [7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2, -1],
    [2, 5, 10, 2, 3, 5, 3, 7, 5, -1, -1, -1, -1, -1, -1, -1],
    [8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5, -1, -1, -1, -1],
    [9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2, -1, -1, -1, -1],
    [9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2, -1],
    [1, 3, 5, 3, 7, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 7, 0, 7, 1, 1, 7, 5, -1, -1, -1, -1, -1, -1, -1],
    [9, 0, 3, 9, 3, 5, 5, 3, 7, -1, -1, -1, -1, -1, -1, -1],
    [9, 8, 7, 5, 9, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [5, 8, 4, 5, 10, 8, 10, 11, 8, -1, -1, -1, -1, -1, -1, -1],
    [5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0, -1, -1, -1, -1],
    [0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5, -1, -1, -1, -1],
    [10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4, -1],
    [2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8, -1, -1, -1, -1],
    [0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11, -1],
    [0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5, -1],
    [9, 4, 5, 2, 11, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4, -1, -1, -1, -1],
    [5, 10, 2, 5, 2, 4, 4, 2, 0, -1, -1, -1, -1, -1, -1, -1],
    [3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9, -1],
    [5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2, -1, -1, -1, -1],
    [8, 4, 5, 8, 5, 3, 3, 5, 1, -1, -1, -1, -1, -1, -1, -1],
    [0, 4, 5, 1, 0, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5, -1, -1, -1, -1],
    [9, 4, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 11, 7, 4, 9, 11, 9, 10, 11, -1, -1, -1, -1, -1, -1, -1],
    [0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11, -1, -1, -1, -1],
    [1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11, -1, -1, -1, -1],
    [3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4, -1],
    [4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2, -1, -1, -1, -1],
    [9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3, -1],
    [11, 7, 4, 11, 4, 2, 2, 4, 0, -1, -1, -1, -1, -1, -1, -1],
    [11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4, -1, -1, -1, -1],
    [2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9, -1, -1, -1, -1],
    [9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7, -1],
    [3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10, -1],
    [1, 10, 2, 8, 7, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 9, 1, 4, 1, 7, 7, 1, 3, -1, -1, -1, -1, -1, -1, -1],
    [4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1, -1, -1, -1, -1],
    [4, 0, 3, 7, 4, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [4, 8, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [9, 10, 8, 10, 11, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [3, 0, 9, 3, 9, 11, 11, 9, 10, -1, -1, -1, -1, -1, -1, -1],
    [0, 1, 10, 0, 10, 8, 8, 10, 11, -1, -1, -1, -1, -1, -1, -1],
    [3, 1, 10, 11, 3, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 2, 11, 1, 11, 9, 9, 11, 8, -1, -1, -1, -1, -1, -1, -1],
    [3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9, -1, -1, -1, -1],
    [0, 2, 11, 8, 0, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [3, 2, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [2, 3, 8, 2, 8, 10, 10, 8, 9, -1, -1, -1, -1, -1, -1, -1],
    [9, 10, 2, 0, 9, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8, -1, -1, -1, -1],
    [1, 10, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [1, 3, 8, 9, 1, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 9, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [0, 3, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
];

struct SmoothTriangle {
    Vector3 a;
    Vector3 b;
    Vector3 c;
    Color color;
}

/// One chunk of smooth terrain.
/// Samples sit on a grid one step wider than the cubes. Marching cubes builds
/// the surface where density crosses isolevel. A triangle takes its color from
/// the solid material next to that surface.
// Finest marching cubes, used next to the player. A chunk stays 16 units across.
// The player is not scaled with this. Farther chunks use fewer cubes.
enum int cubesPerUnit = 2;
// A skirt this tall covers the gap where two resolutions meet.
enum float skirtDrop = 8.0f;

struct ChunkSmooth {
    const int chunkSize = 16;
    int meshResolution = cubesPerUnit;
    int cubeCount = chunkSize * cubesPerUnit;
    int sampleCount = chunkSize * cubesPerUnit + 1;
    float sampleStep = 1.0f / cubesPerUnit;
    enum float isolevel = 0.0f;

    // +X, -X, +Z, -Z. A side whose neighbor uses a different cube count gets a skirt.
    int[4] neighborCells = [32, 32, 32, 32];

    int[] materials;
    float[] density;
    SmoothTriangle[] triangles;
    Vector3 origin;

    static ChunkSmooth* create(int cells = 0) {
        ChunkSmooth* chunk = new ChunkSmooth();
        if(cells < 1)
            cells = chunk.chunkSize * cubesPerUnit;
        chunk.setCells(cells);
        return chunk;
    }

    // cells is how many marching cubes run along one edge of this chunk.
    void setCells(int cells) {
        cubeCount = cells;
        sampleCount = cells + 1;
        sampleStep = cast(float)chunkSize / cast(float)cells;
        meshResolution = 0;
        if(cells >= chunkSize && cells % chunkSize == 0)
            meshResolution = cells / chunkSize;
        int volume = sampleCount * sampleCount * sampleCount;
        materials.length = volume;
        density.length = volume;
        int n = 0;
        while(n < 4) {
            neighborCells[n] = cells;
            n += 1;
        }
    }

    // X moves fastest, then Y, then Z. Same order as Chunk2.chunkIndex.
    int sampleIndex(int x, int y, int z) {
        return x + (y * sampleCount) + (z * sampleCount * sampleCount);
    }

    void setSample(int x, int y, int z, int materialId, float d) {
        int i = sampleIndex(x, y, z);
        materials[i] = materialId;
        density[i] = d;
    }

    // Altitude, then ranges, then ledges, then detail. The sum is the ground surface.
    float terrainHeight(int x, int z) {
        return groundHeight(x, z);
    }

    void populateTerrain() {
        triangles.length = 0;
        int baseX = cast(int)origin.x;
        int baseY = cast(int)origin.y;
        int baseZ = cast(int)origin.z;
        float minD = float.max;
        float maxD = -float.max;
        int z = 0;
        while(z < sampleCount) {
            int x = 0;
            while(x < sampleCount) {
                float wx = cast(float)baseX + cast(float)x * sampleStep;
                float wz = cast(float)baseZ + cast(float)z * sampleStep;
                float h = groundHeightAt(wx, wz);
                int y = 0;
                while(y < sampleCount) {
                    float wy = cast(float)baseY + cast(float)y * sampleStep;
                    float d = h - wy;
                    int id = getMaterialID(MaterialType.AIR);
                    if(d > isolevel)
                        id = terrainMaterial(wx, wy, wz);
                    setSample(x, y, z, id, d);
                    if(d < minD)
                        minD = d;
                    if(d > maxD)
                        maxD = d;
                    y += 1;
                }
                x += 1;
            }
            z += 1;
        }
        // A chunk that is all ground or all air has no surface.
        if(minD <= isolevel && maxD > isolevel) {
            buildMesh();
            addSkirts();
        }
    }

    void buildMesh() {
        triangles.length = 0;
        triangles.reserve(cubeCount * cubeCount * 8);
        int y = 0;
        while(y < cubeCount) {
            int z = 0;
            while(z < cubeCount) {
                int x = 0;
                while(x < cubeCount) {
                    marchCube(x, y, z);
                    x += 1;
                }
                z += 1;
            }
            y += 1;
        }
    }

    // A triangle outside the view, or facing away from the camera, is not drawn.
    void drawChunk(Camera3D camera, Frustum view) {
        int i = 0;
        int count = cast(int)triangles.length;
        while(i < count) {
            SmoothTriangle tri = triangles[i];
            Vector3 a = tri.a + origin;
            Vector3 b = tri.b + origin;
            Vector3 c = tri.c + origin;
            if(triangleInFrustum(view, a, b, c)) {
                Vector3 normal = faceNormal(a, b, c);
                if(facesCamera(normal, a, camera.position))
                    DrawTriangle3D(a, b, c, shadeColor(tri.color, normal));
            }
            i += 1;
        }
    }

    // A corner is inside the ground when its density is above isolevel.
    // The triangle faces away from that corner, so the ground is seen from the air.
    void marchCube(int x, int y, int z) {
        float[8] val;
        int[8] mat;
        Vector3[8] pos;
        int n = 0;
        while(n < 8) {
            int sx = x + cornerOffset[n][0];
            int sy = y + cornerOffset[n][1];
            int sz = z + cornerOffset[n][2];
            int i = sampleIndex(sx, sy, sz);
            val[n] = density[i];
            mat[n] = materials[i];
            pos[n] = Vector3(cast(float)sx * sampleStep, cast(float)sy * sampleStep, cast(float)sz * sampleStep);
            n += 1;
        }

        int cubeindex = 0;
        if(val[0] > isolevel) cubeindex |= 1;
        if(val[1] > isolevel) cubeindex |= 2;
        if(val[2] > isolevel) cubeindex |= 4;
        if(val[3] > isolevel) cubeindex |= 8;
        if(val[4] > isolevel) cubeindex |= 16;
        if(val[5] > isolevel) cubeindex |= 32;
        if(val[6] > isolevel) cubeindex |= 64;
        if(val[7] > isolevel) cubeindex |= 128;

        if(edgeTable[cubeindex] == 0)
            return;

        Color color = colorFromMaterials(val, mat);
        if(color.a == 0)
            return;

        Vector3[12] vertlist;
        int e = 0;
        while(e < 12) {
            if((edgeTable[cubeindex] & (1 << e)) != 0) {
                int c0 = edgeCorners[e][0];
                int c1 = edgeCorners[e][1];
                vertlist[e] = vertexInterp(isolevel, pos[c0], pos[c1], val[c0], val[c1]);
            }
            e += 1;
        }

        int t = 0;
        while(t < 16 && triTable[cubeindex][t] != -1) {
            SmoothTriangle tri;
            tri.a = vertlist[triTable[cubeindex][t]];
            tri.b = vertlist[triTable[cubeindex][t + 1]];
            tri.c = vertlist[triTable[cubeindex][t + 2]];
            tri.color = color;
            triangles ~= tri;
            t += 3;
        }
    }

    // The solid sample closest to the surface owns the color. Height is not read.
    Color colorFromMaterials(float[8] val, int[8] mat) {
        int bestId = getMaterialID(MaterialType.AIR);
        float bestD = float.max;
        int n = 0;
        while(n < 8) {
            if(val[n] > isolevel && val[n] < bestD && materialIsSolid(mat[n])) {
                bestD = val[n];
                bestId = mat[n];
            }
            n += 1;
        }
        return getMaterialColor(bestId);
    }

    // Drop a strip down a side that meets a different resolution, so the seam stays covered.
    void addSkirts() {
        int face = 0;
        while(face < 4) {
            if(neighborCells[face] != cubeCount)
                skirtFace(face);
            face += 1;
        }
    }

    void skirtFace(int face) {
        float plane = 0.0f;
        int axis = 0;
        Vector3 outward = Vector3(0, 0, 0);
        if(face == 0) {
            plane = cast(float)chunkSize;
            axis = 0;
            outward = Vector3(1, 0, 0);
        } else if(face == 1) {
            plane = 0.0f;
            axis = 0;
            outward = Vector3(-1, 0, 0);
        } else if(face == 2) {
            plane = cast(float)chunkSize;
            axis = 1;
            outward = Vector3(0, 0, 1);
        } else {
            plane = 0.0f;
            axis = 1;
            outward = Vector3(0, 0, -1);
        }

        int[6][] seen;
        int count = cast(int)triangles.length;
        int i = 0;
        while(i < count) {
            SmoothTriangle tri = triangles[i];
            Vector3[3] p = [tri.a, tri.b, tri.c];
            int e = 0;
            while(e < 3) {
                Vector3 a = p[e];
                Vector3 b = p[(e + 1) % 3];
                if(onPlane(a, axis, plane) && onPlane(b, axis, plane))
                    addSkirtEdge(a, b, outward, tri.color, seen);
                e += 1;
            }
            i += 1;
        }
    }

    bool onPlane(Vector3 p, int axis, float plane) {
        float v = p.x;
        if(axis == 1)
            v = p.z;
        float d = v - plane;
        return d < 0.001f && d > -0.001f;
    }

    void addSkirtEdge(Vector3 a, Vector3 b, Vector3 outward, Color color, ref int[6][] seen) {
        int ax = quantSkirt(a.x);
        int ay = quantSkirt(a.y);
        int az = quantSkirt(a.z);
        int bx = quantSkirt(b.x);
        int by = quantSkirt(b.y);
        int bz = quantSkirt(b.z);
        if(ax == bx && ay == by && az == bz)
            return;
        if(bx < ax || (bx == ax && by < ay) || (bx == ax && by == ay && bz < az)) {
            int tx = ax;
            int ty = ay;
            int tz = az;
            ax = bx;
            ay = by;
            az = bz;
            bx = tx;
            by = ty;
            bz = tz;
        }
        int n = 0;
        while(n < cast(int)seen.length) {
            int[6] key = seen[n];
            if(key[0] == ax && key[1] == ay && key[2] == az && key[3] == bx && key[4] == by && key[5] == bz)
                return;
            n += 1;
        }
        int[6] key = [ax, ay, az, bx, by, bz];
        seen ~= key;

        Vector3 a2 = Vector3(a.x, a.y - skirtDrop, a.z);
        Vector3 b2 = Vector3(b.x, b.y - skirtDrop, b.z);
        Vector3 normal = faceNormal(a, b, b2);
        float facing = normal.x * outward.x + normal.y * outward.y + normal.z * outward.z;
        SmoothTriangle top;
        SmoothTriangle bottom;
        top.color = color;
        bottom.color = color;
        if(facing >= 0.0f) {
            top.a = a;
            top.b = b;
            top.c = b2;
            bottom.a = a;
            bottom.b = b2;
            bottom.c = a2;
        } else {
            top.a = b;
            top.b = a;
            top.c = a2;
            bottom.a = b;
            bottom.b = a2;
            bottom.c = b2;
        }
        triangles ~= top;
        triangles ~= bottom;
    }
}

Vector3 vertexInterp(float iso, Vector3 p1, Vector3 p2, float v1, float v2) {
    float d1 = iso - v1;
    if(d1 < 0.00001f && d1 > -0.00001f)
        return p1;
    float d2 = iso - v2;
    if(d2 < 0.00001f && d2 > -0.00001f)
        return p2;
    float span = v1 - v2;
    if(span < 0.00001f && span > -0.00001f)
        return p1;
    float mu = (iso - v1) / (v2 - v1);
    return Vector3(
        p1.x + mu * (p2.x - p1.x),
        p1.y + mu * (p2.y - p1.y),
        p1.z + mu * (p2.z - p1.z),
    );
}

// Ken Perlin's improved noise, in 2D. perm holds the shuffle twice so a lookup
// of perm[i] + 1 never walks off the end.
int[512] buildPerm() {
    int[256] values;
    int i = 0;
    while(i < 256) {
        values[i] = i;
        i += 1;
    }
    uint state = 127;
    i = 255;
    while(i > 0) {
        state = state * 1664525u + 1013904223u;
        int j = cast(int)(state % cast(uint)(i + 1));
        int tmp = values[i];
        values[i] = values[j];
        values[j] = tmp;
        i -= 1;
    }
    int[512] doubled;
    i = 0;
    while(i < 256) {
        doubled[i] = values[i];
        doubled[i + 256] = values[i];
        i += 1;
    }
    return doubled;
}

immutable int[512] perm = buildPerm();

int floorInt(float v) {
    int i = cast(int)v;
    if(cast(float)i > v)
        i -= 1;
    return i;
}

// Chunk index of a world position. Integer division truncates toward 0,
// so negative positions use floorInt first.
int chunkCoord(float p, int size) {
    int i = floorInt(p);
    if(i >= 0)
        return i / size;
    return -((-i - 1) / size) - 1;
}

// Render distance in chunks, on x and on z. A new world starts at this.
enum int chunkRadius = 20;

// Cubes along one edge. Near the player the cells are half a unit.
// A few chunks out they are one unit, and past that they are two units.
int lodCells(int dist) {
    int size = ChunkSmooth.init.chunkSize;
    if(dist < 0)
        dist = -dist;
    if(dist <= 2)
        return size * 2;
    if(dist <= 6)
        return size;
    return size / 2;
}

int quantSkirt(float v) {
    if(v >= 0.0f)
        return cast(int)(v * 64.0f + 0.5f);
    return cast(int)(v * 64.0f - 0.5f);
}

// The layers in the terrain illustration, from the bottom up.
// Detail is last, so the bumps sit on the ledges.
float groundHeightAt(float x, float z) {
    float height = altitudeAt(x, z);
    height += rangesAt(x, z);
    height += ledgesAt(x, z);
    height += detailAt(x, z);
    return height;
}

float groundHeight(int x, int z) {
    return groundHeightAt(cast(float)x, cast(float)z);
}

// Chunk layers the ground passes through in one column. y1 is the top layer that has solid samples.
void surfaceLayers(int cx, int cz, int size, out int y0, out int y1) {
    float minH = float.max;
    float maxH = -float.max;
    float step = 1.0f / cubesPerUnit;
    float lz = 0.0f;
    while(lz <= cast(float)size) {
        float lx = 0.0f;
        while(lx <= cast(float)size) {
            float h = groundHeightAt(cast(float)(cx * size) + lx, cast(float)(cz * size) + lz);
            if(h < minH)
                minH = h;
            if(h > maxH)
                maxH = h;
            lx += step;
        }
        lz += step;
    }
    y0 = chunkCoord(minH, size);
    y1 = chunkCoord(maxH, size);
    while(y1 > y0 && maxH <= cast(float)(y1 * size))
        y1 -= 1;
}

private ulong chunkKey(int cx, int cy, int cz) {
    ulong ux = cast(uint)(cx + (1 << 20));
    ulong uy = cast(uint)(cy + (1 << 20));
    ulong uz = cast(uint)(cz + (1 << 20));
    return ux | (uy << 21) | (uz << 42);
}

private struct LayerSpan {
    int y0;
    int y1;
}

// One side of the view. The inside of the view is where x*nx + y*ny + z*nz + d is at least 0.
private struct FrustumPlane {
    float x;
    float y;
    float z;
    float d;
}

struct Frustum {
    FrustumPlane[6] planes;
}

private FrustumPlane makePlane(float a, float b, float c, float d) {
    FrustumPlane plane;
    plane.x = a;
    plane.y = b;
    plane.z = c;
    plane.d = d;
    return plane;
}

// Same projection BeginMode3D builds: fovy is degrees, near 0.01, far 1000.
Frustum frustumFromCamera(Camera3D camera, float aspect) {
    Matrix view = MatrixLookAt(camera.position, camera.target, camera.up);
    Matrix projection = MatrixPerspective(camera.fovy * DEG2RAD, aspect, RL_CULL_DISTANCE_NEAR, RL_CULL_DISTANCE_FAR);
    Matrix clip = MatrixMultiply(view, projection);
    Frustum frustum;
    frustum.planes[0] = makePlane(clip.m3 + clip.m0, clip.m7 + clip.m4, clip.m11 + clip.m8, clip.m15 + clip.m12);
    frustum.planes[1] = makePlane(clip.m3 - clip.m0, clip.m7 - clip.m4, clip.m11 - clip.m8, clip.m15 - clip.m12);
    frustum.planes[2] = makePlane(clip.m3 + clip.m1, clip.m7 + clip.m5, clip.m11 + clip.m9, clip.m15 + clip.m13);
    frustum.planes[3] = makePlane(clip.m3 - clip.m1, clip.m7 - clip.m5, clip.m11 - clip.m9, clip.m15 - clip.m13);
    frustum.planes[4] = makePlane(clip.m3 + clip.m2, clip.m7 + clip.m6, clip.m11 + clip.m10, clip.m15 + clip.m14);
    frustum.planes[5] = makePlane(clip.m3 - clip.m2, clip.m7 - clip.m6, clip.m11 - clip.m10, clip.m15 - clip.m14);
    return frustum;
}

// True when the box meets the view. A box that only crosses an edge still counts.
bool boxInFrustum(Frustum frustum, Vector3 bmin, Vector3 bmax) {
    int i = 0;
    while(i < 6) {
        FrustumPlane plane = frustum.planes[i];
        float px = plane.x >= 0.0f ? bmax.x : bmin.x;
        float py = plane.y >= 0.0f ? bmax.y : bmin.y;
        float pz = plane.z >= 0.0f ? bmax.z : bmin.z;
        if(plane.x * px + plane.y * py + plane.z * pz + plane.d < 0.0f)
            return false;
        i += 1;
    }
    return true;
}

// True when the triangle is not completely outside any side of the view.
// A triangle that only crosses an edge still counts.
bool triangleInFrustum(Frustum frustum, Vector3 a, Vector3 b, Vector3 c) {
    int i = 0;
    while(i < 6) {
        FrustumPlane plane = frustum.planes[i];
        float sa = plane.x * a.x + plane.y * a.y + plane.z * a.z + plane.d;
        float sb = plane.x * b.x + plane.y * b.y + plane.z * b.z + plane.d;
        float sc = plane.x * c.x + plane.y * c.y + plane.z * c.z + plane.d;
        if(sa < 0.0f && sb < 0.0f && sc < 0.0f)
            return false;
        i += 1;
    }
    return true;
}

// True when the camera sits on the front side of the triangle. The normal is (b - a) × (c - a).
bool facesCamera(Vector3 normal, Vector3 point, Vector3 cameraPos) {
    float dx = cameraPos.x - point.x;
    float dy = cameraPos.y - point.y;
    float dz = cameraPos.z - point.z;
    return normal.x * dx + normal.y * dy + normal.z * dz > 0.0f;
}

struct ChunkWorld {
    int radius = chunkRadius;
    private ChunkSmooth*[ulong] loaded;
    private LayerSpan[ulong] layers;
    private int playerCx;
    private int playerCz;
    private int playerCy;
    private int activeRadius;
    private bool hasPlayer;
    private bool caughtUp;

    // One missing surface chunk. The first call builds the layer nearest the player.
    void update(Vector3 playerPos) {
        int size = ChunkSmooth.init.chunkSize;
        int cx = chunkCoord(playerPos.x, size);
        int cz = chunkCoord(playerPos.z, size);
        bool moved = !hasPlayer || cx != playerCx || cz != playerCz;
        bool radiusChanged = !hasPlayer || activeRadius != radius;
        hasPlayer = true;
        playerCx = cx;
        playerCz = cz;
        playerCy = chunkCoord(playerPos.y, size);
        if(moved || radiusChanged) {
            dropOutside();
            caughtUp = false;
            activeRadius = radius;
        }
        if(caughtUp)
            return;
        // Raise or lower one chunk's detail before filling the horizon.
        if(refreshNearest())
            return;
        if(!fillNearest(size))
            caughtUp = true;
    }

    int loadedCount() {
        return cast(int)loaded.length;
    }

    void draw(Camera3D camera) {
        float height = cast(float)GetScreenHeight();
        float aspect = 1.0f;
        if(height > 0.0f)
            aspect = cast(float)GetScreenWidth() / height;
        Frustum view = frustumFromCamera(camera, aspect);
        float size = cast(float)ChunkSmooth.init.chunkSize;
        foreach(chunk; loaded) {
            if(chunk.triangles.length == 0)
                continue;
            Vector3 bmin = chunk.origin;
            Vector3 bmax = Vector3(bmin.x + size, bmin.y + size, bmin.z + size);
            if(boxInFrustum(view, bmin, bmax))
                chunk.drawChunk(camera, view);
        }
    }

    ChunkSmooth* findChunk(int cx, int cy, int cz) {
        ChunkSmooth** found = chunkKey(cx, cy, cz) in loaded;
        if(found is null)
            return null;
        return *found;
    }

    private void cachedLayers(int cx, int cz, int size, out int y0, out int y1) {
        ulong key = chunkKey(cx, 0, cz);
        LayerSpan* found = key in layers;
        if(found !is null) {
            y0 = found.y0;
            y1 = found.y1;
            return;
        }
        surfaceLayers(cx, cz, size, y0, y1);
        layers[key] = LayerSpan(y0, y1);
    }

    private void unpackKey(ulong key, out int cx, out int cy, out int cz) {
        cx = cast(int)(key & ((1 << 21) - 1)) - (1 << 20);
        cy = cast(int)((key >> 21) & ((1 << 21) - 1)) - (1 << 20);
        cz = cast(int)((key >> 42) & ((1 << 21) - 1)) - (1 << 20);
    }

    private void dropOutside() {
        ulong[] drop;
        foreach(key, chunk; loaded) {
            int cx;
            int cy;
            int cz;
            unpackKey(key, cx, cy, cz);
            int dx = cx - playerCx;
            if(dx < 0)
                dx = -dx;
            int dz = cz - playerCz;
            if(dz < 0)
                dz = -dz;
            int cheb = dx > dz ? dx : dz;
            if(cheb > radius)
                drop ~= key;
        }
        foreach(key; drop) {
            loaded[key].triangles.length = 0;
            loaded.remove(key);
        }
    }

    // Nearest missing layer. A closer column finishes before the next ring is opened.
    private bool fillNearest(int size) {
        int dist = 0;
        while(dist <= radius) {
            int bestOx;
            int bestOy;
            int bestOz;
            int bestYd = int.max;
            bool found = false;
            int oz = playerCz - dist;
            while(oz <= playerCz + dist) {
                int ox = playerCx - dist;
                while(ox <= playerCx + dist) {
                    int dx = ox - playerCx;
                    if(dx < 0)
                        dx = -dx;
                    int dz = oz - playerCz;
                    if(dz < 0)
                        dz = -dz;
                    int cheb = dx > dz ? dx : dz;
                    if(cheb == dist) {
                        int y0;
                        int y1;
                        cachedLayers(ox, oz, size, y0, y1);
                        int oy = y0;
                        while(oy <= y1) {
                            if((chunkKey(ox, oy, oz) in loaded) is null) {
                                int yd = oy - playerCy;
                                if(yd < 0)
                                    yd = -yd;
                                if(!found || yd < bestYd || (yd == bestYd && oy < bestOy)) {
                                    found = true;
                                    bestYd = yd;
                                    bestOx = ox;
                                    bestOy = oy;
                                    bestOz = oz;
                                }
                            }
                            oy += 1;
                        }
                    }
                    ox += 1;
                }
                oz += 1;
            }
            if(found) {
                fillChunk(chunkKey(bestOx, bestOy, bestOz), size);
                return true;
            }
            dist += 1;
        }
        return false;
    }

    private int columnDist(int cx, int cz) {
        int dx = cx - playerCx;
        if(dx < 0)
            dx = -dx;
        int dz = cz - playerCz;
        if(dz < 0)
            dz = -dz;
        return dx > dz ? dx : dz;
    }

    // Outside the loaded square there is no neighbor, so that side matches this chunk.
    private int cellsBeside(int cx, int cz, int own) {
        if(columnDist(cx, cz) > radius)
            return own;
        return lodCells(columnDist(cx, cz));
    }

    private void applyNeighbors(ChunkSmooth* chunk, int cx, int cz) {
        int own = chunk.cubeCount;
        chunk.neighborCells[0] = cellsBeside(cx + 1, cz, own);
        chunk.neighborCells[1] = cellsBeside(cx - 1, cz, own);
        chunk.neighborCells[2] = cellsBeside(cx, cz + 1, own);
        chunk.neighborCells[3] = cellsBeside(cx, cz - 1, own);
    }

    private bool chunkStale(ChunkSmooth* chunk, int cx, int cz) {
        int want = lodCells(columnDist(cx, cz));
        if(chunk.cubeCount != want)
            return true;
        if(chunk.neighborCells[0] != cellsBeside(cx + 1, cz, want))
            return true;
        if(chunk.neighborCells[1] != cellsBeside(cx - 1, cz, want))
            return true;
        if(chunk.neighborCells[2] != cellsBeside(cx, cz + 1, want))
            return true;
        if(chunk.neighborCells[3] != cellsBeside(cx, cz - 1, want))
            return true;
        return false;
    }

    // The closest chunk whose detail does not match its distance.
    private bool refreshNearest() {
        int bestDist = int.max;
        int bestYd = int.max;
        int bestCy = 0;
        int bestCx = 0;
        int bestCz = 0;
        ChunkSmooth* best = null;
        foreach(key, chunk; loaded) {
            int cx;
            int cy;
            int cz;
            unpackKey(key, cx, cy, cz);
            if(!chunkStale(chunk, cx, cz))
                continue;
            int dist = columnDist(cx, cz);
            int yd = cy - playerCy;
            if(yd < 0)
                yd = -yd;
            if(best is null || dist < bestDist || (dist == bestDist && (yd < bestYd || (yd == bestYd && cy < bestCy)))) {
                best = chunk;
                bestDist = dist;
                bestYd = yd;
                bestCy = cy;
                bestCx = cx;
                bestCz = cz;
            }
        }
        if(best is null)
            return false;
        best.setCells(lodCells(bestDist));
        applyNeighbors(best, bestCx, bestCz);
        best.populateTerrain();
        return true;
    }

    private void fillChunk(ulong key, int size) {
        int cx;
        int cy;
        int cz;
        unpackKey(key, cx, cy, cz);
        ChunkSmooth* chunk = ChunkSmooth.create(lodCells(columnDist(cx, cz)));
        chunk.origin = Vector3(cast(float)(cx * size), cast(float)(cy * size), cast(float)(cz * size));
        applyNeighbors(chunk, cx, cz);
        chunk.populateTerrain();
        loaded[key] = chunk;
    }
}

float fade(float t) {
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
}

float lerp(float a, float b, float t) {
    return a + t * (b - a);
}

float grad2(int hash, float x, float y) {
    switch(hash & 3) {
        case 0:
            return x + y;
        case 1:
            return -x + y;
        case 2:
            return x - y;
        default:
            return -x - y;
    }
}

float perlin2(float x, float y) {
    int x0 = floorInt(x);
    int y0 = floorInt(y);
    float xf = x - cast(float)x0;
    float yf = y - cast(float)y0;
    int xi = x0 & 255;
    int yi = y0 & 255;
    float u = fade(xf);
    float v = fade(yf);
    int aa = perm[perm[xi] + yi];
    int ba = perm[perm[xi + 1] + yi];
    int ab = perm[perm[xi] + yi + 1];
    int bb = perm[perm[xi + 1] + yi + 1];
    float x1 = lerp(grad2(aa, xf, yf), grad2(ba, xf - 1.0f, yf), u);
    float x2 = lerp(grad2(ab, xf, yf - 1.0f), grad2(bb, xf - 1.0f, yf - 1.0f), u);
    return lerp(x1, x2, v);
}

// Fixed sun: up, and a little toward east (+X) and south (+Z). It does not move.
Vector3 unit(Vector3 v) {
    float len = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    if(len < 0.00001f)
        return Vector3(0, 1, 0);
    return v / len;
}

immutable Vector3 sunDirection = unit(Vector3(0.3f, 0.9f, 0.25f));

Vector3 faceNormal(Vector3 a, Vector3 b, Vector3 c) {
    Vector3 u = b - a;
    Vector3 v = c - a;
    return Vector3(
        u.y * v.z - u.z * v.y,
        u.z * v.x - u.x * v.z,
        u.x * v.y - u.y * v.x,
    );
}

ubyte scaleChannel(ubyte channel, float shade) {
    float value = cast(float)channel * shade + 0.5f;
    if(value > 255.0f)
        value = 255.0f;
    if(value < 0.0f)
        value = 0.0f;
    return cast(ubyte)value;
}

// DrawTriangle3D has no light of its own. Brightness is ambient plus how
// squarely the face points at the sun. The stored color stays the material.
Color shadeColor(Color color, Vector3 normal) {
    Vector3 n = unit(normal);
    float ndotl = n.x * sunDirection.x + n.y * sunDirection.y + n.z * sunDirection.z;
    if(ndotl < 0.0f)
        ndotl = 0.0f;
    float shade = 0.35f + 0.65f * ndotl;
    return Color(
        scaleChannel(color.r, shade),
        scaleChannel(color.g, shade),
        scaleChannel(color.b, shade),
        color.a,
    );
}

// Base height. One noise feature is 256 chunks across, so the ground rises and
// falls over hundreds of chunks. The shift keeps the sample off the Perlin lattice.
float altitudeAt(float x, float z) {
    float scale = 1.0f / (256.0f * 16.0f);
    float n = perlin2(x * scale + 3.1f, z * scale + 8.4f);
    return 28.0f + n * 160.0f;
}

// Smooth 0..1 wave from the illustration. It scales the bumps. Lows stay quiet.
float detailIntensityAt(float x, float z) {
    float scale = 1.0f / (24.0f * 16.0f);
    float n = perlin2(x * scale + 1.7f, z * scale + 4.2f);
    float t = n * 0.5f + 0.5f;
    if(t < 0.0f)
        t = 0.0f;
    if(t > 1.0f)
        t = 1.0f;
    return t * t;
}

// Bumps on the steps. Their height follows detail intensity, and full strength is 1.5.
float detailAt(float x, float z) {
    float intensity = detailIntensityAt(x, z);
    float n = perlin2(x * 0.22f + 9.3f, z * 0.22f + 2.6f);
    n += 0.5f * perlin2(x * 0.44f + 9.3f, z * 0.44f + 2.6f);
    return n * 1.5f * intensity;
}

// One cycle is a steep rise and then a long slope down. Three cycles fit in 0..1.
// The peak of a cycle is 8. The bottom is 0.
float ledgeWave(float u) {
    if(u < 0.0f)
        u = 0.0f;
    if(u > 1.0f)
        u = 1.0f;
    float cycles = 3.0f;
    float rise = 0.18f;
    float s = u * cycles;
    float frac = s - cast(float)floorInt(s);
    float shaped;
    if(frac < rise)
        shaped = frac / rise;
    else
        shaped = (1.0f - frac) / (1.0f - rise);
    return shaped * 8.0f;
}

// The scarp itself, before intensity and chance scale it. The noise is wide.
float ledgeShapeAt(float x, float z) {
    float n = perlin2(x * 0.01f + 6.5f, z * 0.01f + 11.2f) * 1.8f;
    return ledgeWave(n * 0.5f + 0.5f);
}

// Smooth 0..1 wave, like detail intensity. The noise is mapped one-to-one, so a
// high stretch reaches a full ledge and a low stretch stays quiet. It scales height.
float ledgeIntensityAt(float x, float z) {
    float scale = 1.0f / (32.0f * 16.0f);
    float n = perlin2(x * scale + 8.6f, z * scale + 2.9f);
    float t = n + 0.5f;
    if(t < 0.0f)
        t = 0.0f;
    if(t > 1.0f)
        t = 1.0f;
    return t * t;
}

// Smooth 0..1 wave, like detail intensity, across a wider area. Where it is low,
// the ledges fade out. Where it is high, they are present.
float ledgeChanceAt(float x, float z) {
    float scale = 1.0f / (48.0f * 16.0f);
    float n = perlin2(x * scale + 12.4f, z * scale + 6.1f);
    float t = n + 0.5f;
    if(t < 0.0f)
        t = 0.0f;
    if(t > 1.0f)
        t = 1.0f;
    return t * t;
}

// Sits on the ranges, before detail. Height is the scarp times intensity times chance.
float ledgesAt(float x, float z) {
    return ledgeShapeAt(x, z) * ledgeIntensityAt(x, z) * ledgeChanceAt(x, z);
}

// One giant ledge. u moves from 0 to 1 across the whole shape.
// First a steep climb of 300. Then a drop of 75, only a little less steep.
// Then a long slope back down to the plain.
float rangeWave(float u) {
    if(u < 0.0f)
        u = 0.0f;
    if(u > 1.0f)
        u = 1.0f;
    float peak = 300.0f;
    float drop = 75.0f;
    float riseEnd = 0.02f;
    float dropRun = riseEnd * (drop / peak) * 1.25f;
    float dropEnd = riseEnd + dropRun;
    if(u < riseEnd)
        return peak * (u / riseEnd);
    if(u < dropEnd) {
        float t = (u - riseEnd) / dropRun;
        return peak - drop * t;
    }
    float t = (u - dropEnd) / (1.0f - dropEnd);
    return (peak - drop) * (1.0f - t);
}

// The noise slides along that shape. One cycle is a few hundred units, so the
// climb stays a wall and the last slope stays long.
float rangesAt(float x, float z) {
    float scale = 1.0f / 480.0f;
    float n = perlin2(x * scale + 8.3833f, z * scale - 0.4667f);
    float u = n * 0.5f + 0.5f;
    if(u < 0.0f)
        u = 0.0f;
    if(u > 1.0f)
        u = 1.0f;
    return rangeWave(u);
}

// Solid cells only. Another Perlin sample picks dirt or rock, and it changes with depth.
int terrainMaterial(float x, float y, float z) {
    float n = perlin2(x * 0.13f + 2.2f, z * 0.13f + y * 0.13f + 7.5f);
    if(n >= 0.0f)
        return getMaterialID(MaterialType.ROCK);
    return getMaterialID(MaterialType.DIRT);
}

int terrainMaterial(int x, int y, int z) {
    return terrainMaterial(cast(float)x, cast(float)y, cast(float)z);
}
