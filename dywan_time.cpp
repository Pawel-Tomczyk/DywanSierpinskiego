// Compile: g++ -std=c++17 -O2 -fopenmp -o dywan_time dywan_time.cpp
#include <iostream>
#include <numeric>
#include <complex>
#include <omp.h>
#include <chrono>

#define WIDTH (9 * 9 * 9 * 9)
#define HEIGHT (9 * 9 * 9 * 9)
int pixels[WIDTH][HEIGHT];

struct box
{
    int x0; // pixel startowy w osi x
    int xn; // pixel koncowy w osi x
    int y0; // pixel startowy w osi y
    int yn; // pixel koncowy w osi y

    int id; // id pixela, między 0 a 8 - służy do stwierdzenia czy pixel jest czarny czy biały // czy dalej wchodzić w rekursje
};

// Przyjmuj startBox - pudełko do podzielenia i vectos<box> boxes - początkowo pusty wektor do którego dodawane są nowe pudełka
int divideIntoBoxes(box startBox, box boxes[9])
{
    try
    {
        // podziel box na 9 mniejszych boxów
        int x0 = startBox.x0;
        int xn = startBox.xn;
        int y0 = startBox.y0;
        int yn = startBox.yn;

        int dx = (xn - x0) / 3;
        int dy = (yn - y0) / 3;
        for (int i = 0; i < 9; i++)
        {
            int col = i % 3;
            int row = i / 3;

            box newBox;
            newBox.x0 = x0 + dx * col;
            newBox.xn = x0 + dx * (col + 1);
            newBox.y0 = y0 + dy * row;
            newBox.yn = y0 + dy * (row + 1);
            newBox.id = i;

            boxes[i] = newBox;
        }
        return 0;
    }
    catch (std::exception &e)
    {
        std::cerr << "Error: " << e.what() << std::endl;
        return -1;
    }
}

int makeSierpinski(box start)
{
    if (start.id == 4)
    {
        // white pixel - no children
        for (int x = start.x0; x < start.xn; x++)
        {
            for (int y = start.y0; y < start.yn; y++)
            {
                pixels[x][y] = 255;
            }
        }
        return 0;
    }
    else if (start.x0 - start.xn > -2 && start.y0 - start.yn > -2) // EDIT
    {
        // black pixel - no children
        for (int x = start.x0; x < start.xn; x++)
        {
            for (int y = start.y0; y < start.yn; y++)
            {
                pixels[x][y] = 0;
            }
        }
        // pixels[start.x0][start.y0] = 0;
        return 0;
    }
    // divide the box into 9 smaller boxes
    box boxes[9];
    if (divideIntoBoxes(start, boxes) == -1)
    {
        printf("Error dividing into boxes\n");
        return -1;
    };
    for (int i = 0; i < 9; i++)
    {
#pragma omp task
        {
            makeSierpinski(boxes[i]);
        }
    }

    return 0;
}

int main()
{
    // Initialize SDL
    int width = WIDTH;
    int height = HEIGHT;
    // Draw the pixels

    // CODE
    box startBox;
    startBox.x0 = 0;
    startBox.xn = WIDTH;
    startBox.y0 = 0;
    startBox.yn = HEIGHT;
    startBox.id = -1; // -1 oznacza, że nie jest to pixel
#pragma omp parallel
    {
#pragma omp single
        makeSierpinski(startBox);
    }
    return 0;
}