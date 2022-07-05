#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "mandelbrot.h"

uint16_t xres = 80;
uint16_t yres = 40;

int main(const __attribute__((unused)) int argc, const __attribute__((unused)) char **argv){

    bool *img = malloc(sizeof(bool) * (xres * yres));

// #pragma omp parallel for schedule(dynamic)
    for (uint16_t i = 0; i < yres; i++){
        for (uint16_t j = 0; j < xres; j++){
            img[j * yres + i] = mandelbrot(j, i);
        }
    }

    for (uint16_t i = 0; i < yres; i++){
        for (uint16_t j = 0; j < xres; j++){
            printf("%c", img[j * yres + i] ? '*' : ' ');
        }
        puts("");
    }

    return 0;
}
