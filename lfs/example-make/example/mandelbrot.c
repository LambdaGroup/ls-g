#include "mandelbrot.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ITER 50
#define XMIN -2.5F
#define XMAX  1.0F
#define YMIN -1.0F
#define YMAX  1.0F

inline __attribute__((always_inline))
bool mandelbrot(const uint16_t x, const uint16_t y){
    double x0 = XMIN + (XMAX - XMIN) * (double)x / (double)xres;
    double y0 = YMIN + (YMAX - YMIN) * (double)y / (double)yres;

    // z ^ 2 +c

    double zr = 0;
    double zi = 0;

    double p = 0;
    double q = 0;

    for (uint16_t i = 0; i < MAX_ITER; i++){
        p = zr * zr;
        q = zi * zi;

        if (p + q > 4) return false;

        zi = 2 * zr * zi + y0;
        zr = p - q + x0;
    }

    return true;
}
