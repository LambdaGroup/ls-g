#ifndef MANDELBROT_H
#define MANDELBROT_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

extern uint16_t xres;
extern uint16_t yres;

bool mandelbrot(const uint16_t x, const uint16_t y);

#endif
