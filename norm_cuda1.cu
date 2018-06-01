#include <stdio.h>

#define N 5
#define M 10

//global means it is called by host, run by device
//mat is the original matrix *already allocated on GPU*
//mat_res is the matrix to store the result *already allocated on GPU*
//s is the scalar, passed directly from host to function
__global__ 
void mat_mult(int *mat, int *mat_res, int *mult)
{
	//row
	int tidX = blockIdx.x * blockDim.x + threadIdx.x;

	//col
	int tidY = blockIdx.y * blockDim.y + threadIdx.y;

	//thread ID must be < # of matrix rows and columns
	if(tidX < M && tidY < N)
		mat_res[tidX * N  + tidY] = mat[tidX * N + tidY] * mult[tidY];
}

//__host__ is default (called and run on host), so this is optional
__host__
int main()
{
	//host stuff
	int *mat = (int *) malloc(N * M * sizeof(int));
	int *mat_res = (int *) malloc(N * M * sizeof(int));

	int *mult = (int *) malloc(N * sizeof(int));
	int *mult_res = (int *) malloc(M * sizeof(int));


	//device stuff
	int *d_mat, *d_mat_res, *d_mult, *d_mult_res;

	printf("Past Pointer Var Dec\n");

	//fill host matrix
	int i, j;
	for(i = 0; i < M; i++)
		for(j = 0; j < N; j++)
			mat[i * M + j] = i * N + j;

	for(i = 0; i < N; i++)
		mult[i] = 20 + i;

	printf("Original matrix...\n");
	for(i = 0; i < M; i++)
	{
		for(j = 0; j < N; j++)
			printf("%d\t", mat[i * M + j]);
		printf("\n");
	}
	
	printf("Allocating CUDA memory\n");
	//allocate device memory
	cudaMalloc((void **) &d_mat,N * M * sizeof(int));
	cudaMalloc((void **) &d_mat_res, N * M * sizeof(int));

	printf("1\n");

	cudaMalloc((void **) &d_mult, N * sizeof(int));
	cudaMalloc((void **) &d_mult_res, M * sizeof(int));
	

	//copy host matrix to device
	printf("Copying to device...\n");
	cudaMemcpy(d_mat, mat, N * M * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_mult, mult, N * sizeof(int), cudaMemcpyHostToDevice);

	printf("Starting kernel...\n");
	
	//specify the number of threads per block in X and Y dimensions
	dim3 dimBlock(16, 16, 1);
		
	//specify the number of blocks: we need enough blocks in both the X and Y
	// dimensions to cover the entire matrix, assuming we have 16 threads/block
	dim3 dimGrid((M - 1)/16 + 1, (N - 1)/16 + 1, 1);

	//call the kernel
	mat_mult<<<dimGrid, dimBlock>>>(d_mat, d_mat_res, d_mult);

	printf("Copying back...\n");

	cudaMemcpy(mat_res, d_mat_res, N * M * sizeof(int), cudaMemcpyDeviceToHost);

	printf("Final matrix...\n");
	for(i = 0; i < M; i++)
	{
		for(j = 0; j < N; j++)
			printf("%d\t", mat_res[i * M + j]);
		printf("\n");
	}
	
	return 0;
}
