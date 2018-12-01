#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include <SDL.h>

#include "mandelVHDL.h"

const int MAXX = 320;
const int MAXY = 240;

SDL_Surface *surface;
Uint8 *buffer = NULL;

void panic(const char *fmt, ...)
{
    va_list arg;

    va_start(arg, fmt);
    vfprintf(stderr, fmt, arg);
    va_end(arg);
    exit(0);
}

void init256()
{
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
        panic("Couldn't initialize SDL: %d\n", SDL_GetError());
    atexit(SDL_Quit);

    surface = SDL_SetVideoMode(MAXX,
                               MAXY, 8, SDL_HWSURFACE | SDL_HWPALETTE);
    if (!surface)
        panic("Couldn't set video mode: %d", SDL_GetError());

    if (SDL_MUSTLOCK(surface)) {
        if (SDL_LockSurface(surface) < 0)
            panic("Couldn't lock surface: %d", SDL_GetError());
    }
    buffer = (Uint8*)surface->pixels;

    // A palette for Mandelbrot zooms...
    {
        SDL_Color palette[256];
        int i;
	int ofs=0;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 16*(16-abs(i-16));
            palette[i+ofs].g = 0;
            palette[i+ofs].b = 16*abs(i-16);
        }
	ofs= 16;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 0;
            palette[i+ofs].g = 16*(16-abs(i-16));
            palette[i+ofs].b = 0;
        }
	ofs= 32;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 0;
            palette[i+ofs].g = 0;
            palette[i+ofs].b = 16*(16-abs(i-16));
        }
	ofs= 48;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 16*(16-abs(i-16));
            palette[i+ofs].g = 16*(16-abs(i-16));
            palette[i+ofs].b = 0;
        }
	ofs= 64;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 0;
            palette[i+ofs].g = 16*(16-abs(i-16));
            palette[i+ofs].b = 16*(16-abs(i-16));
        }
	ofs= 80;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 16*(16-abs(i-16));
            palette[i+ofs].g = 0;
            palette[i+ofs].b = 16*(16-abs(i-16));
        }
	ofs= 96;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 16*(16-abs(i-16));
            palette[i+ofs].g = 16*(16-abs(i-16));
            palette[i+ofs].b = 16*(16-abs(i-16));
        }
	ofs= 112;
        for (i = 0; i < 16; i++) {
            palette[i+ofs].r = 16*(8-abs(i-8));
            palette[i+ofs].g = 16*(8-abs(i-8));
            palette[i+ofs].b = 16*(8-abs(i-8));
        }
        SDL_SetColors(surface, palette, 0, 256);
    }
}

int kbhit(int *xx, int *yy)
{
    int x,y;
    SDL_Event event;

    Uint8 *keystate = SDL_GetKeyState(NULL);
    if ( keystate[SDLK_ESCAPE] )
	return 1;

    if(SDL_PollEvent(&event)) {
        switch(event.type) {
	case SDL_QUIT:
	    return 1;
	    break;
        default:
            break;
        }
    }

    Uint8 btn = SDL_GetMouseState (&x, &y);
    if (btn & SDL_BUTTON(SDL_BUTTON_LEFT)) {
	*xx = x;
	*yy = y;
	return 2;
    }
    if (btn & SDL_BUTTON(SDL_BUTTON_RIGHT)) {
	*xx = x;
	*yy = y;
	return 3;
    }
    return 0;
}

int main()
{
    printf("\nMandelbrot Zoomer by Thanassis (an experiment in VHDL).\n");
    init256();
    mandelVHDL_init();

    int x,y;
    unsigned i=0, st, en;

    const char *usage = "Left click to zoom-in, right-click to zoom-out, ESC to quit...";
    SDL_WM_SetCaption(usage,usage);

    st = SDL_GetTicks();

    double xld = -2.2, yld=-1.1, xru=-2+(MAXX/MAXY)*3., yru=1.1;
    while(1) {
        mandelVHDL(buffer, xld, yld, xru, yru);
        SDL_UpdateRect(surface, 0, 0, MAXX, MAXY);
        int result = kbhit(&x, &y);
	if (result == 1)
            break;
	else if (result == 2 || result == 3) {
	    double ratiox = ((double)x)/MAXX;
	    double ratioy = ((double)y)/MAXY;
	    double xrange = xru-xld;
	    double yrange = yru-yld;
	    double direction = result==2?1.:-1.;
	    if ((xru-xld)<0.00002 && direction==1)
                continue;
	    xld += direction*0.01*ratiox*xrange;
	    xru -= direction*0.01*(1.-ratiox)*xrange;
	    yld += direction*0.01*(1.-ratioy)*yrange;
	    yru -= direction*0.01*ratioy*yrange;
	} 
	i++;
    }
    en = SDL_GetTicks();
    mandelVHDL_shutdown();

    printf("Frames/sec:%5.2f\n\n", ((float) i) / ((en - st) / 1000.0f));
    fflush(stdout);
    return 0;
}
