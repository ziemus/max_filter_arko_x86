#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
void * in_buf, * out_buf;
extern void filter_x86(void* input, void* output, int box, int width, int height, int pad);

SDL_Surface *get_image_from_buf(char* buff,int size)
{
    SDL_RWops *rw = SDL_RWFromMem(buff,size);
    SDL_Surface *temp = (SDL_Surface*)IMG_Load_RW(rw, 1);

    if (temp == NULL)
    {
        printf("IMG_LOAD ERROR.\n");
        exit(1);
    }
    return temp;
}


int main(int argc, char**argv) //argc==3, *argv[2] = box size, *argv[1] = file directory
{
	in_buf=NULL, out_buf=NULL;
	FILE *img=NULL;
	SDL_Surface *surf = NULL,*screen=NULL;
	SDL_Window *wind = NULL;
	int32_t width, height, padd, box;
	size_t filesize;

	if(argc != 3)
    {
        printf("Too few arguments.\n");
        exit(1);
    }
	//get box size
	box = atoi(argv[2]);
	if(box < 0)
    {
        printf("Invlid box size.\n");
        exit(1);
    }

	img = fopen(argv[1],"rb");
	if(img == NULL)
    {
        printf("Invalid box size.\n");
        exit(1);
    }


    //load all data onto the buffer and then read data from the RAM
	//read width
	fseek(img, 18, SEEK_SET);

	fread(&width, 4, 1, img);
	//read height
	fread(&height, 4, 1, img);
	//calculate pwindadding
	padd = width % 4;
	//alloc buffers of *img size
	fseek(img,0,SEEK_END);
	filesize = (size_t)ftell(img);
	in_buf = malloc ( filesize );
	out_buf = malloc( filesize );
	//load image data into input buffer
	rewind(img);
	//fseek(img,0,SEEK_SET);
	fread(in_buf,filesize,1,img);
	fclose(img);
	//copy the bmp header to the output buffer
	memcpy(out_buf, in_buf, 54);
	//now that we have our buffers ready all we got to do is call the assembler function
	filter_x86(in_buf+54, out_buf+54, box, width, height, padd);
	//now to display the output buffer
	SDL_Init(SDL_INIT_VIDEO);
	surf = get_image_from_buf(out_buf, filesize);
	wind = SDL_CreateWindow("MaxFiter", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, 0);
    screen = SDL_GetWindowSurface(wind);
    SDL_BlitSurface(surf, NULL, screen, NULL);
    SDL_UpdateWindowSurface(wind);

	while(getch() != 'q');

	SDL_FreeSurface(surf);
	SDL_FreeSurface(screen);
	SDL_DestroyWindow(wind);
	free(in_buf);
	free(out_buf);

	return 0;
}
