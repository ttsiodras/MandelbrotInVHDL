#include <stdio.h>
#include <stdint.h>


// Macros configuring fixed-point operations
#define FRACT_BITS 26
#define SCALE (1<<FRACT_BITS)
#define FLOAT2FIXED(x) ((x) * SCALE)
#define MULFIX(a,b)  ((((uint64_t)(a))*(b)) >> FRACT_BITS)

// The number of iterations of the Mandelbrot computation,
// after which we consider the pixel as belonging in the "lake".
#define ITERATIONS 240

// Precompute outside loops
const int32_t FOUR = FLOAT2FIXED(4.0);

uint32_t mandel(int32_t re, int32_t im)
{
    // Good old fixed-point; in this case,
    // 6.26 fixed point, which will allow us
    // to zoom-in in the Mandelbrot set.
    unsigned k;
    int32_t rez, imz;
    int32_t t1, t2, o1, o2, o3;

    rez = re;
    imz = im;
    fprintf(stderr, "IN: x: %08x, y: %08x\n\n", rez, imz);

    k = 0;
    while (k < ITERATIONS) {
        o1 = MULFIX(rez, rez);
        o2 = MULFIX(imz, imz);
        o3 = MULFIX(rez, imz);
        t1 = o1 - o2;
        t2 = o1 + o2;
        rez = t1 + re;
        imz = 2*o3 + im;
        t2 = o1 + o2;
        fprintf(stderr,
            "x: %08x, y: %08x, "
            "x^2: %08x, y^2: %08x, x*y: %08x,\n\t2*x*y: %08x, "
            "x^2-y^2: %08x, x^2+y^2: %08x\n\n",
            rez, imz,
            o1, o2, o3, 2*o3,
            t1, t2);
        if (t2 > FOUR)
            break;
        k++;
    }
    fprintf(stderr, "FINAL: %d\n\n====\n", k);
    return k;
}

int main()
{
    double red;
    int32_t re, im;
    printf("    constant patterns : pattern_array := (\n");
    for(red = -2.2; red<0; red+=0.05) {
        re = FLOAT2FIXED(red);
        im = FLOAT2FIXED(-0.9);
        printf("      (X\"%08x\", X\"%08x\", %d),\n", re, im, mandel(re, im));
    }
    red = 0;
    re = FLOAT2FIXED(red);
    im = FLOAT2FIXED(-0.9);
    printf("      (X\"%08x\", X\"%08x\", %d)\n);\n", re, im, mandel(re, im));
}
