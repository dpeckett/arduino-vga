// Generate Encoded Font Glyph Table
// Apple II Character Set.

#include <stdio.h>
#include <stdlib.h>

unsigned char glyphs[64][5][3] = {
	// '@'
	{{0,1,0},
	{1,0,1},
	{1,1,1},
	{1,0,0},
	{0,1,1}},
	// 'A'
	{{0,1,0},
	{1,0,1},
	{1,1,1},
	{1,0,1},
	{1,0,1}},
	// 'B'
	{{1,1,0},
	{1,0,1},
	{1,1,0},
	{1,0,1},
	{1,1,0}},
	// 'C'
	{{0,1,0},
	{1,0,1},
	{1,0,0},
	{1,0,1},
	{0,1,0}},
	// 'D'
	{{1,1,0},
	{1,0,1},
	{1,0,1},
	{1,0,1},
	{1,1,0}},
	// 'E'
	{{1,1,1},
	{1,0,0},
	{1,1,0},
	{1,0,0},
	{1,1,1}},
	// 'F'
	{{1,1,1},
	{1,0,0},
	{1,1,0},
	{1,0,0},
	{1,0,0}},
	// 'G'
	{{0,1,1},
	{1,0,0},
	{1,0,1},
	{1,0,1},
	{0,1,0}},
	// 'H'
	{{1,0,1},
	{1,0,1},
	{1,1,1},
	{1,0,1},
	{1,0,1}},
	// 'I'
	{{1,1,1},
	{0,1,0},
	{0,1,0},
	{0,1,0},
	{1,1,1}},
	// 'J'
	{{1,1,1},
	{0,1,0},
	{0,1,0},
	{0,1,0},
	{1,1,0}},
	// 'K'
	{{1,0,1},
	{1,0,1},
	{1,1,0},
	{1,0,1},
	{1,0,1}},
	// 'L'
	{{1,0,0},
	{1,0,0},
	{1,0,0},
	{1,0,0},
	{1,1,1}},
	// 'M'
	{{1,0,1},
	{1,1,1},
	{1,0,1},
	{1,0,1},
	{1,0,1}},
	// 'N'
	{{1,0,1},
	{1,1,1},
	{1,1,1},
	{1,1,1},
	{1,0,1}},
	// 'O'
	{{0,1,0},
	{1,0,1},
	{1,0,1},
	{1,0,1},
	{0,1,0}},
	// 'P'
	{{1,1,0},
	{1,0,1},
	{1,1,0},
	{1,0,0},
	{1,0,0}},
	// 'Q'
	{{0,1,0},
	{1,0,1},
	{1,0,1},
	{0,1,0},
	{0,0,1}},
	// 'R'
	{{1,1,0},
	{1,0,1},
	{1,1,0},
	{1,0,1},
	{1,0,1}},
	// 'S'
	{{0,1,1},
	{1,0,0},
	{0,1,0},
	{0,0,1},
	{1,1,0}},
	// 'T'
	{{1,1,1},
	{0,1,0},
	{0,1,0},
	{0,1,0},
	{0,1,0}},
	// 'U'
	{{1,0,1},
	{1,0,1},
	{1,0,1},
	{1,0,1},
	{0,1,0}},
	// 'V'
	{{1,0,1},
	{1,0,1},
	{1,0,1},
	{0,1,0},
	{0,1,0}},
	// 'W'
	{{1,0,1},
	{1,0,1},
	{1,1,1},
	{1,1,1},
	{0,1,0}},
	// 'X'
	{{1,0,1},
	{1,0,1},
	{0,1,0},
	{1,0,1},
	{1,0,1}},
	// 'Y'
	{{1,0,1},
	{1,0,1},
	{0,1,0},
	{0,1,0},
	{0,1,0}},
	// 'Z'
	{{1,1,1},
	{0,0,1},
	{0,1,0},
	{1,0,0},
	{1,1,1}},
	// '['
	{{0,1,1},
	{0,1,0},
	{0,1,0},
	{0,1,0},
	{0,1,1}},
	// '\'
	{{1,0,0},
	{1,0,0},
	{0,1,0},
	{0,1,0},
	{0,0,1}},
	// ']'
	{{1,1,0},
	{0,1,0},
	{0,1,0},
	{0,1,0},
	{1,1,0}},
	// '^'
	{{0,1,0},
	{1,0,1},
	{0,0,0},
	{0,0,0},
	{0,0,0}},
	// '_'
	{{0,0,0},
	{0,0,0},
	{0,0,0},
	{0,0,0},
	{1,1,1}},
	// ' '
	{{0,0,0},
	{0,0,0},
	{0,0,0},
	{0,0,0},
	{0,0,0}},
	// '!'
	{{0,1,0},
	{0,1,0},
	{0,1,0},
	{0,0,0},
	{0,1,0}},
	// '"'
	{{1,0,1},
	{1,0,1},
	{0,0,0},
	{0,0,0},
	{0,0,0}},
	// '#'
	{{1,0,1},
	{1,1,1},
	{1,0,1},
	{1,1,1},
	{1,0,1}},
	// '$'
	{{0,1,1},
	{1,1,0},
	{1,1,1},
	{0,1,1},
	{1,1,0}},
	// '%'
	{{1,0,1},
	{0,0,1},
	{0,1,0},
	{1,0,0},
	{1,0,1}},
	// '&'
	{{0,1,0},
	{1,0,1},
	{0,1,0},
	{1,0,1},
	{0,1,1}},
	// '\''
	{{0,1,0},
	{0,1,0},
	{0,0,0},
	{0,0,0},
	{0,0,0}},
	// '('
	{{0,0,1},
	{0,1,0},
	{0,1,0},
	{0,1,0},
	{0,0,1}},
	// ')'
	{{1,0,0},
	{0,1,0},
	{0,1,0},
	{0,1,0},
	{1,0,0}},
	// '*'
	{{0,0,0},
	{1,0,1},
	{0,1,0},
	{1,0,1},
	{0,0,0}},
	// '+'
	{{0,0,0},
	{0,1,0},
	{1,1,1},
	{0,1,0},
	{0,0,0}},
	// ''
	{{0,0,0},
	{0,0,0},
	{0,0,0},
	{0,1,0},
	{1,0,0}},
	// '-'
	{{0,0,0},
	{0,0,0},
	{1,1,1},
	{0,0,0},
	{0,0,0}},
	// '.'
	{{0,0,0},
	{0,0,0},
	{0,0,0},
	{0,0,0},
	{0,1,0}},
	// '/'
	{{0,0,1},
	{0,0,1},
	{0,1,0},
	{0,1,0},
	{1,0,0}},
	// '0'
	{{1,1,1},
	{1,0,1},
	{1,0,1},
	{1,0,1},
	{1,1,1}},
	// '1'
	{{0,1,0},
	{1,1,0},
	{0,1,0},
	{0,1,0},
	{1,1,1}},
	// '2'
	{{0,1,0},
	{1,0,1},
	{0,0,1},
	{1,1,0},
	{1,1,1}},
	// '3'
	{{1,1,0},
	{0,0,1},
	{0,1,0},
	{0,0,1},
	{1,1,0}},
	// '4'
	{{1,0,1},
	{1,0,1},
	{1,1,1},
	{0,0,1},
	{0,0,1}},
	// '5'
	{{1,1,1},
	{1,0,0},
	{1,1,1},
	{0,0,1},
	{1,1,0}},
	// '6'
	{{0,1,1},
	{1,0,0},
	{1,1,0},
	{1,0,1},
	{0,1,0}},
	// '7'
	{{1,1,1},
	{0,0,1},
	{0,1,0},
	{1,0,0},
	{1,0,0}},
	// '8'
	{{1,1,1},
	{1,0,1},
	{1,1,1},
	{1,0,1},
	{1,1,1}},
	// '9'
	{{0,1,0},
	{1,0,1},
	{0,1,1},
	{0,0,1},
	{1,1,0}},
	// ':'
	{{0,0,0},
	{0,1,0},
	{0,0,0},
	{0,1,0},
	{0,0,0}},
	// ';'
	{{0,0,0},
	{0,1,0},
	{0,0,0},
	{0,1,0},
	{1,0,0}},
	// '<'
	{{0,0,1},
	{0,1,0},
	{1,0,0},
	{0,1,0},
	{0,0,1}},
	// '='
	{{0,0,0},
	{1,1,1},
	{0,0,0},
	{1,1,1},
	{0,0,0}},
	// '>'
	{{1,0,0},
	{0,1,0},
	{0,0,1},
	{0,1,0},
	{1,0,0}},
	// '?'
	{{0,1,0},
	{1,0,1},
	{0,0,1},
	{0,1,0},
	{0,1,0}}
};

int main() {
	int i;
	unsigned char character;

	printf("\nROW_GLYPH_1:\n");
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][0][0]<<3) | (glyphs[i][0][1]<<2) | (glyphs[i][0][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][0][0]<<3) | (glyphs[i][0][1]<<2) | (glyphs[i][0][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][0][0]<<3) | (glyphs[i][0][1]<<2) | (glyphs[i][0][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}	
	for(i = 0; i < 64; ++i) {
		character = ((glyphs[i][0][0]<<3) | (glyphs[i][0][1]<<2) | (glyphs[i][0][2]<<1))&0xF;
		printf(".byte 0x%02x\n", character);
	}

	printf("\nROW_GLYPH_2:\n");
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][1][0]<<3) | (glyphs[i][1][1]<<2) | (glyphs[i][1][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][1][0]<<3) | (glyphs[i][1][1]<<2) | (glyphs[i][1][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][1][0]<<3) | (glyphs[i][1][1]<<2) | (glyphs[i][1][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = ((glyphs[i][1][0]<<3) | (glyphs[i][1][1]<<2) | (glyphs[i][1][2]<<1))&0xF;
		printf(".byte 0x%02x\n", character);
	}	

	printf("\nROW_GLYPH_3:\n");
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][2][0]<<3) | (glyphs[i][2][1]<<2) | (glyphs[i][2][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][2][0]<<3) | (glyphs[i][2][1]<<2) | (glyphs[i][2][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][2][0]<<3) | (glyphs[i][2][1]<<2) | (glyphs[i][2][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = ((glyphs[i][2][0]<<3) | (glyphs[i][2][1]<<2) | (glyphs[i][2][2]<<1))&0xF;
		printf(".byte 0x%02x\n", character);
	}		

	printf("\nROW_GLYPH_4:\n");
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][3][0]<<3) | (glyphs[i][3][1]<<2) | (glyphs[i][3][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][3][0]<<3) | (glyphs[i][3][1]<<2) | (glyphs[i][3][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][3][0]<<3) | (glyphs[i][3][1]<<2) | (glyphs[i][3][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = ((glyphs[i][3][0]<<3) | (glyphs[i][3][1]<<2) | (glyphs[i][3][2]<<1))&0xF;
		printf(".byte 0x%02x\n", character);
	}

	printf("\nROW_GLYPH_5:\n");
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][4][0]<<3) | (glyphs[i][4][1]<<2) | (glyphs[i][4][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}	
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][4][0]<<3) | (glyphs[i][4][1]<<2) | (glyphs[i][4][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = (~((glyphs[i][4][0]<<3) | (glyphs[i][4][1]<<2) | (glyphs[i][4][2]<<1)))&0xF;
		printf(".byte 0x%02x\n", character);
	}
	for(i = 0; i < 64; ++i) {
		character = ((glyphs[i][4][0]<<3) | (glyphs[i][4][1]<<2) | (glyphs[i][4][2]<<1))&0xF;
		printf(".byte 0x%02x\n", character);
	}

	return 0;
}