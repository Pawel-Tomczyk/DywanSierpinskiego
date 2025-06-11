// Compile: nvcc dywan.cu -o cu_dywan

#include <iostream>
#include <cstdlib>
#include <cuda.h>
#include <cmath>

struct box
{
    int x0; // pixel startowy w osi x
    int xn; // pixel koncowy w osi x
    int y0; // pixel startowy w osi y
    int yn; // pixel koncowy w osi y

    int id; // id pixela, między 0 a 8 - służy do stwierdzenia czy pixel jest czarny czy biały // czy dalej wchodzić w rekursje
};

#define WIDTH (9 * 9 * 9 * 9 * 9)
#define HEIGHT (9 * 9 * 9 * 9 * 9)

static void HandleError(cudaError_t err, const char *file, int line)
{
    if (err != cudaSuccess)
    {
        fprintf(stderr, "CUDA error: %s in %s at line %d\n", cudaGetErrorString(err), file, line);
        exit(EXIT_FAILURE);
    }
}
#define HANDLE_ERROR(err) (HandleError(err, __FILE__, __LINE__))

__global__ void sierpinskiKernel(box *boxesIn, box *boxesOut, int *pixelArray, int numBoxes, int currentDepth)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= numBoxes)
        return;

    box b = boxesIn[idx];

    int width = b.xn - b.x0;
    int height = b.yn - b.y0;

    if (b.id == 4)
    {
        for (int x = b.x0; x < b.xn; x++)
        {
            for (int y = b.y0; y < b.yn; y++)
            {
                pixelArray[y * WIDTH + x] = 255;
            }
        }
        return;
    }
    else if (width < 2 || height < 2)
    {
        for (int x = b.x0; x < b.xn; x++)
        {
            for (int y = b.y0; y < b.yn; y++)
            {
                pixelArray[y * WIDTH + x] = 0;
            }
        }
        return;
    }

    // podział na 9 nowych boksów
    int dx = width / 3;
    int dy = height / 3;
    for (int i = 0; i < 9; i++)
    {
        int col = i % 3;
        int row = i / 3;

        int outIdx = idx * 9 + i; // bo każdy wątek tworzy 9 boksów

        boxesOut[outIdx].x0 = b.x0 + col * dx;
        boxesOut[outIdx].xn = b.x0 + (col + 1) * dx;
        boxesOut[outIdx].y0 = b.y0 + row * dy;
        boxesOut[outIdx].yn = b.y0 + (row + 1) * dy;
        boxesOut[outIdx].id = i;
    }
}

int main(void)
{
    const int maxDepth = 5; // zależnie od WIDTH/HEIGHT
    box *d_current;
    box *d_next;

    box startBox;
    startBox.x0 = 0;
    startBox.xn = WIDTH;
    startBox.y0 = 0;
    startBox.yn = HEIGHT;
    startBox.id = -1;

    cudaMalloc(&d_current, sizeof(box) * 1);
    cudaMemcpy(d_current, &startBox, sizeof(box), cudaMemcpyHostToDevice);
    cudaMalloc(&d_next, sizeof(box) * pow(9, maxDepth));

    int *d_pixels;
    cudaMalloc(&d_pixels, sizeof(int) * WIDTH * HEIGHT);
    cudaMemset(d_pixels, 0, sizeof(int) * WIDTH * HEIGHT);

    int numBoxes = 1;

    for (int depth = 0; depth < maxDepth; ++depth)
    {
        int threads = 256;
        int blocks = (numBoxes + threads - 1) / threads;

        sierpinskiKernel<<<blocks, threads>>>(d_current, d_next, d_pixels, numBoxes, depth);
        cudaDeviceSynchronize();
        HANDLE_ERROR(cudaGetLastError());

        HANDLE_ERROR(cudaDeviceSynchronize());

        std::swap(d_current, d_next);
        numBoxes *= 9;
    }

    int *pixels = new int[WIDTH * HEIGHT];
    cudaMemcpy(pixels, d_pixels, sizeof(int) * WIDTH * HEIGHT, cudaMemcpyDeviceToHost);

    cudaFree(d_pixels);
    cudaFree(d_current);
    cudaFree(d_next);

    for (int y = 0; y < HEIGHT; y += HEIGHT / 100)
    {
        for (int x = 0; x < WIDTH; x += WIDTH / 100)
        {
            std::cout << (pixels[y * WIDTH + x] > 0 ? " " : "#");
        }
        std::cout << std::endl;
    }

    return EXIT_SUCCESS;
}