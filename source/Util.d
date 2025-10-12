module Util;
import raylib;

void camControls(Camera3D camra) {
	if( IsKeyDown(KeyboardKey.KEY_W) ){
		camra.position.x += 1;
	} else if (IsKeyDown(KeyboardKey.KEY_S) ){
		camra.position.x -= 1;
	}
}

// enum BlockSide{
//     NORTH,
//     SOUTH,
//     EAST,
//     WEST,
//     UP,
//     DOWN,
// }

struct Block {
	Vector3 size = {1, 1, 1};
	Vector3 pos;
	Color color = Colors.DARKGREEN;

	static Block newBlock(float x, float y, float z) {
		Block setBlock;
		setBlock.pos.x = x;
		setBlock.pos.y = y;
		setBlock.pos.z = z;
		return setBlock;
	}
}

// class BlockV2{

//     bool isDebugMode;
//     float X, Y, Z;
//     Vector3 pos;
//     Color clr;
//     // byte UP, DOWN, EAST, WEST,NORTH, SOUTH;

//     void Side_NORTH(){
//         Vector3 vert_br = {1 *X, 0 *Y, 0 *Z}; // Bottom right
//         Vector3 vert_tl = {0 *X, 1 *Y, 0 *Z}; // Top left
//         Vector3 vert_bl = {0 *X, 0 *Y, 0 *Z}; // Bottom left
//         Vector3 vert_tr = {1 *X, 1 *Y, 0 *Z}; // Top right
        
//         Color drawclr0, drawclr1;
//         if (this.isDebugMode == false){
//             drawclr0 = this.clr;
//             drawclr1 = this.clr;
//         }
//         if (this.isDebugMode == true){
//             drawclr0 = Colors.BLUE;
//             drawclr1 = Colors.DARKBLUE;
//         }

//         DrawTriangle3D(vert_br, vert_tl, vert_bl, drawclr0);
//         DrawTriangle3D(vert_br, vert_tr, vert_tl, drawclr1);
//     }

//     void Side_SOUTH(){                                                     // REFACTOR SIDES WITHOUT STRUCTS!
//         Vector3 vert_br = {1 *X, 0 *Y, 1 *Z}; // Bottom right
//         Vector3 vert_tl = {0 *X, 1 *Y, 1 *Z}; // Top left
//         Vector3 vert_bl = {0 *X, 0 *Y, 1 *Z}; // Bottom left
//         Vector3 vert_tr = {1 *X, 1 *Y, 1 *Z}; // Top right
        
//         Color drawclr0, drawclr1;
//         if (this.isDebugMode == false){
//             drawclr0 = this.clr;
//             drawclr1 = this.clr;
//         }
//         if (this.isDebugMode == true){
//             drawclr0 = Colors.PINK;
//             drawclr1 = Colors.RED;
//         }

//         DrawTriangle3D(vert_br, vert_tl, vert_bl, drawclr0);
//         DrawTriangle3D(vert_br, vert_tr, vert_tl, drawclr1);
//     }

//     void Side_EAST(){
//         Vector3 vert_br = {0 *X, 1 *Y, 0 *Z}; // Bottom right
//         Vector3 vert_tl = {0 *X, 0 *Y, 1 *Z}; // Top left
//         Vector3 vert_bl = {0 *X, 0 *Y, 0 *Z}; // Bottom left
//         Vector3 vert_tr = {0 *X, 1 *Y, 1 *Z}; // Top right
        
//         Color drawclr0, drawclr1;
//         if (this.isDebugMode == false){
//             drawclr0 = this.clr;
//             drawclr1 = this.clr;
//         }
//         if (this.isDebugMode == true){
//             drawclr0 = Colors.GREEN;
//             drawclr1 = Colors.DARKGREEN;
//         }

//         DrawTriangle3D(vert_br, vert_tl, vert_bl, drawclr0);
//         DrawTriangle3D(vert_br, vert_tr, vert_tl, drawclr1);
//     }

//     void Side_WEST(){
//         Vector3 vert_br = {1 *X, 1 *Y, 0 *Z}; // Bottom right
//         Vector3 vert_tl = {1 *X, 0 *Y, 1 *Z}; // Top left
//         Vector3 vert_bl = {1 *X, 0 *Y, 0 *Z}; // Bottom left
//         Vector3 vert_tr = {1 *X, 1 *Y, 1 *Z}; // Top right
        
//         Color drawclr0, drawclr1;
//         if (this.isDebugMode == false){
//             drawclr0 = this.clr;
//             drawclr1 = this.clr;
//         }
//         if (this.isDebugMode == true){
//             drawclr0 = Colors.YELLOW;
//             drawclr1 = Colors.BROWN;
//         }

//         DrawTriangle3D(vert_br, vert_tl, vert_bl, drawclr0);
//         DrawTriangle3D(vert_br, vert_tr, vert_tl, drawclr1);
//     }

//     void Side_UP(){
//         Vector3 vert_br = {1 *X, 1 *Y, 1 *Z}; // Bottom right
//         Vector3 vert_tl = {0 *X, 1 *Y, 0 *Z}; // Top left
//         Vector3 vert_bl = {0 *X, 1 *Y, 1 *Z}; // Bottom left
//         Vector3 vert_tr = {1 *X, 1 *Y, 0 *Z}; // Top right
        
//         Color drawclr0, drawclr1;
//         if (this.isDebugMode == false){
//             drawclr0 = this.clr;
//             drawclr1 = this.clr;
//         }
//         if (this.isDebugMode == true){
//             drawclr0 = Colors.WHITE;
//             drawclr1 = Colors.LIGHTGRAY;
//         }

//         DrawTriangle3D(vert_br, vert_tl, vert_bl, drawclr0);
//         DrawTriangle3D(vert_br, vert_tr, vert_tl, drawclr1);

//     }

//     void Side_DOWN(){
//         Vector3 vert_br = {1 *X, 0 *Y, 1 *Z}; // Bottom right
//         Vector3 vert_tl = {0 *X, 0 *Y, 0 *Z}; // Top left
//         Vector3 vert_bl = {0 *X, 0 *Y, 1 *Z}; // Bottom left
//         Vector3 vert_tr = {1 *X, 0 *Y, 0 *Z}; // Top right

//         Color drawclr0, drawclr1;
//         if (this.isDebugMode == false){
//             drawclr0 = this.clr;
//             drawclr1 = this.clr;
//         }
//         if (this.isDebugMode == true){
//             drawclr0 = Colors.DARKGRAY;
//             drawclr1 = Colors.BLACK;
//         }

//         DrawTriangle3D(vert_br, vert_tl, vert_bl, drawclr0);
//         DrawTriangle3D(vert_br, vert_tr, vert_tl, drawclr1);
//     }

//     this(float xin = 0, float yin = 0, float zin = 0, bool isDebug){
//         this.isDebugMode = isDebug;

//         this.pos.x = xin;
//         this.pos.y = yin;
//         this.pos.z = zin;

//         this.X = this.pos.x;
//         this.Y = this.pos.y;
//         this.Z = this.pos.z;
//     }

//     void setcolor(Color clr){
//         this.clr = clr;
//     }


//     void drawWholeBlock(){
//         rlDisableBackfaceCulling();

//         Side_NORTH();
//         Side_SOUTH();
//         Side_EAST();
//         Side_WEST();
//         Side_UP();
//         Side_DOWN();
//     }
// }