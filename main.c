#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>

extern void filter_x86(void* input, void* output, int box, int width, int height, int pad);

int main(int argc, char**argv) //argc==3, *argv[2] = box size, *argv[1] = file directory
{	
	void *in_buf, *out_buf;
	FILE *img;
	SDL_RWops *ops=NULL;
	SDL_Surface *surf = NULL;
	SDL_Texture *txtr = NULL;
	SDL_Renderer * rend = NULL;
	SDL_Window *wind = NULL;
	int32_t width, height, padd, box;
	size_t filesize;
	SDL_Init(SDL_INIT_VIDEO);
	
	img = fopen(argv[1],"rb");
	//read width
	fseek(img, 18, SEEK_SET);
	fread(&width, 4, 1, img);					
	//read height
	fread(&height, 4, 1, img);					
	//get box size
	box = atoi(argv[1]);						
	//calculate padding
	padd = width % 4;				
	//alloc buffers of *img size
	fseek(img,0,SEEK_END);						
	filesize = (size_t)ftell(img);
	in_buf = malloc ( filesize );
	out_buf = malloc( filesize );
	//load image data into input buffer
	rewind(img);
	fread(in_buf,filesize,1,img);				
	fclose(img);
	//copy the bmp header to the output buffer
	for(int i = 0 ; i<54 ; ++i)
		*(out_buf+i) = *(in_buf+i);
	
	//now that we have our buffers ready all we got to do is call the assembler function
	filter_x86(in_buf+54, out_buf+54, box, width, height, pad);
	
	//now to display the output buffer
	ops = SDL_RWFromMem(out_buf, filesize);
	surf = (SDL_Surface*)IMG_Load_RW(ops, 1);
	surf = SDL_ConvertSurfaceFormat(surf, SDL_PIXELFORMAT_UNKNOWN, 0);
	wind = SDL_CreateWindow("MaxFiter", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, 0);
	rend = SDL_CreateRenderer(wind, -1, 0);
	txtr = SDL_CreateTextureFromSurface(rend, surf);
	SDL_RenderCopy(rend, txtr, NULL, NULL);
	SDL_RenderPresent(rend);
	
	while(getch() != 'q')
	{
	}
	
	SDL_DestroyTexture(txtr);
	SDL_FreeSurface(surf);
	SDL_DestroyRenderer(rend);
	SDL_DestroyWindow(wind);
	free(in_buff);
	free(out_buff);
	
	return 0;
}