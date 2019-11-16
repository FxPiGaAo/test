NVCC=nvcc
NVCCFLAGS=-O3 -Xcompiler -O3 -Xptxas -dlcm=ca,-O3,-v -gencode=arch=compute_52,code=sm_52
#NVCCFLAGS=-O3 -Xcompiler -O3 -Xptxas -O3,-v
#NVCCFLAGS=-O0 -Xcompiler -O0 -Xptxas -O0,-v
#NVCCFLAGS=-O0 -Xcompiler -O0 -Xptxas -O0,-v -gencode=arch=compute_61,code=sm_61
CUDA_LIB_DIR=/usr/local/cuda/lib64/
all: tesla-attack

tesla-attack.o: main.cu
	$(NVCC) $(NVCC_FLAGS) -c main.cu -o tesla-attack.o

#tesla-attack: main.cu
#	$(NVCC) $(NVCCFLAGS) -lm main.cu -o tesla-attack

tesla-attack: tesla-attack.o
	g++ -O3 tesla-attack.o -o tesla-attack -L$(CUDA_LIB_DIR) -lcudart -lm
clean:
	rm -f tesla-attack main.o

