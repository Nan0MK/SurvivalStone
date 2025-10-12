module Chunk;
import raylib;
import Util;


void generateChunk(Block block){

	int chunkSize = 9;
	int debugSize = 0;

	int gap = cast(int)block.size.x;

	int z = 0;
	while(z < chunkSize){

		int y = 0;
		while(y < chunkSize){

			int x = 0;
			while( x < chunkSize) {

				if( y < 6) {
					block.color = Colors.BROWN;
				} else {
					block.color = Colors.GREEN;
				}

				Vector3 bpos = {(gap + debugSize) * x, (gap + debugSize) * y, (gap + debugSize) * z};
				block.pos = bpos;
				DrawCubeV(block.pos, block.size, block.color);

				x = x + 1;
				if( block.color == Colors.DARKGREEN) {
					block.color = Colors.LIME;
				} else if( block.color == Colors.LIME) {
					block.color = Colors.DARKGREEN;
				}

			}
			y = y + 1;
		}
		z = z + 1;
	}
	// DrawCubeV(block.pos, block.size, block.color);
}

// BlockV2[] generateChunk(){
// 	BlockV2[] chunkOut;

// 	int chunkSize = 9;
// 	int debugSize = 0;

// 	int gap = 2;

// 	int z = 0;
// 	while(z < chunkSize){

// 		int y = 0;
// 		while(y < chunkSize){

// 			int x = 0;
// 			while( x < chunkSize) {
// 				Color setclr;

// 				if( y < 6) {
// 					setclr = Colors.GRAY;
// 				} else {
// 					setclr = Colors.GREEN;
// 				}

//                 // Convert to working for BlockV2

// 				int px = (gap + debugSize) * x;
// 				int py = (gap + debugSize) * y;
// 				int pz = (gap + debugSize) * z;
// 				BlockV2 block = new BlockV2(px, py, pz, false);
// 				block.setcolor(setclr);
// 				chunkOut ~= block;

// 				x = x + 1;

// 			}
// 			y = y + 1;
// 		}
// 		z = z + 1;
// 	}
// }