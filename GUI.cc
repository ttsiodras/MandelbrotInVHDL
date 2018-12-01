#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include <SDL.h>
#include <SDL_rotozoom.h>

#include "mandelVHDL.h"

int MAXX=320, MAXY=240;
int WMAXX, WMAXY;

SDL_Surface *surface = NULL;
SDL_Surface *backBuffer = NULL;
Uint8 *buffer = NULL;

void panic(const char *fmt, ...)
{
    va_list arg;

    va_start(arg, fmt);
    vfprintf(stderr, fmt, arg);
    va_end(arg);
    exit(0);
}

void SetPalette(SDL_Surface *s)
{
    // A palette for Mandelbrot zooms...
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
    memcpy(&palette[128], &palette[0], 128*sizeof(palette[0]));
    SDL_SetColors(s, palette, 0, 256);
}

void CreateSurface()
{
    if (surface)
	SDL_FreeSurface(surface);
    surface = SDL_SetVideoMode(	WMAXX,
				WMAXY, 8, SDL_HWSURFACE | SDL_HWPALETTE | SDL_RESIZABLE
				);
    if (!surface)
        panic("Couldn't set video mode: %d", SDL_GetError());

    SetPalette(surface);

    //SDL_SetAlpha(surface, 0, SDL_ALPHA_OPAQUE);
    SDL_SetColorKey(surface, 0, 0);
    {
	SDL_PixelFormat *format = surface->format;
	backBuffer = SDL_CreateRGBSurface (SDL_SWSURFACE, MAXX, MAXY,
			  format->BitsPerPixel, 
			  format->Rmask, format->Gmask,
			  format->Bmask, format->Amask);
	SetPalette(backBuffer);
	//SDL_SetAlpha(backBuffer, 0, SDL_ALPHA_OPAQUE);
	SDL_SetColorKey(backBuffer, 0, 0);
    }
    if (SDL_MUSTLOCK(backBuffer)) {
        if (SDL_LockSurface(backBuffer) < 0)
            panic("Couldn't lock surface: %d", SDL_GetError());
    }
    buffer = (Uint8*)backBuffer->pixels;

}

void init256()
{
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
        panic("Couldn't initialize SDL: %d\n", SDL_GetError());
    atexit(SDL_Quit);

    CreateSurface();
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
	case SDL_VIDEORESIZE:
	    WMAXX = event.resize.w;
	    WMAXY = event.resize.h;
	    if (SDL_MUSTLOCK(surface))
		SDL_UnlockSurface(surface);
	    CreateSurface();
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

    WMAXX = MAXX;
    WMAXY = MAXY;
    double xld = -2.2, yld=-1.1, xru=-2+(MAXX/MAXY)*3., yru=1.1;

    st = SDL_GetTicks();
    while(1) {
        mandelVHDL(buffer, xld, yld, xru, yru);
        if (SDL_MUSTLOCK(backBuffer))
            SDL_UnlockSurface(backBuffer);
        {
            SDL_Surface *zoomed = zoomSurface(backBuffer, ((double)WMAXX)/MAXX, ((double)WMAXY)/MAXY, 0);
            SDL_SetColorKey(zoomed, 0, 0);
            SDL_BlitSurface(zoomed, NULL, surface, NULL);
            SDL_FreeSurface(zoomed);
            SDL_Flip(surface);
        }
        if (SDL_MUSTLOCK(backBuffer)) {
            if (SDL_LockSurface(backBuffer) < 0)
                panic("Couldn't lock surface: %d", SDL_GetError());
        }
        int result = kbhit(&x, &y);
	if (result == 1)
            break;
	else if (result == 2 || result == 3) {
	    double ratiox = ((double)x)/WMAXX;
	    double ratioy = ((double)y)/WMAXY;
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
    SDL_FreeSurface(backBuffer);
    mandelVHDL_shutdown();

    printf("Frames/sec:%5.2f\n\n", ((float) i) / ((en - st) / 1000.0f));
    fflush(stdout);
    return 0;
}
