#include<stdio.h>
#include<iostream>
#include<malloc.h>
#include<ctime>
#include<cuda_runtime.h>
#include<assert.h>
using namespace std;
//__constant__ int* device_array;

__global__ void test_clock(int &delay, int &add){
   int threadID = (blockIdx.x * blockDim.x) + threadIdx.x;
   clock_t start=0;
   if(threadID == 0) start = clock();
   for(int k=0;k<100;k++){
      for(int j =0;j<10;j++){
         for(int i=0;i<100;i++){
            if(threadID==0){add+=i;}
	    //add+=j;
	    //if(threadID<11){add+=k;}
		 add+=k;
         }
      }
   }
   if(threadID==0){
       clock_t end = clock();
       delay = (int)(end - start);
   }
}



__global__ void sequence_read(long long int &latency, int* device_array, int n, int access_number){
   extern __shared__ int shared_array[];
   for(int i=0;i<n;i++){shared_array[i]=device_array[i];}
   int* j = &shared_array[0];
   //for(int i=0;i<access_number;i++){j=*(int **)j;}
   //j = &shared_array[0];
   long long int temp = clock64();
   for(int i=0;i<access_number;i++){j=*(int **)j;}
   latency = clock64() - temp;
}
__global__ void static_sequence_read(int &latency, long long unsigned* device_array, int access_number, long long unsigned &last_access_value, int array_size){
   int threadID = (blockIdx.x * blockDim.x) + threadIdx.x;
   long long unsigned *j;
   if(threadID == 0){
       for(int i=0;i<array_size;i++){
          last_access_value = device_array[i];
       }
   }
   j = &device_array[0];
   __syncthreads();//finish intializing the array
   clock_t temp=0;
   if(threadID == 0){temp = clock();}//start clocking
   for(int i=0;i<access_number;i++){if(threadID == 0) j=*(long long unsigned **)j;}//access the data array
   if(threadID == 0){
	   latency = (int)(clock() - temp);
	   last_access_value = j[0];
   }
}
__global__ void static_sequence_read_multism(int* latency, long long unsigned* device_array, int access_number, long long unsigned* last_access_value, int array_size){
   //int threadID = (blockIdx.x * blockDim.x) + threadIdx.x;
   int threadx =threadIdx.x;
   int smid = blockIdx.x;
   clock_t start, end;
   long long unsigned temp_value;
   long long unsigned *j;
   if(threadx == 0){
       for(int i=0;i<array_size;i++){
          temp_value = device_array[i+array_size*smid];
       }
   }
   last_access_value[smid]=temp_value;
   j = &(device_array[array_size*smid]);
   __syncthreads();//finish intializing the array
   //start=0;
   if(threadx == 0){start = clock();}//start clocking
   for(int i=0;i<access_number;i++){if(threadx == 0) j=*(long long unsigned **)j;}//access the data array
   if(threadx == 0){
	   end = clock();
	   latency[smid] = (int)(end - start);
	   last_access_value[smid] = j[0];
   }
}

/*
__global__ void static_sequence_read_noinitialize(int* latency, long long unsigned* device_array, int access_number, long long unsigned* last_access_value, int array_size){
   int threadID = (blockIdx.x * blockDim.x) + threadIdx.x;
   long long unsigned *j;
   
   if(threadID == 0){
       for(int i=0;i<array_size;i++){
          last_access_value = device_array[i];
       }
   }
   j = &device_array[0];
   __syncthreads();//finish intializing the array
   clock_t temp=0;
   if(threadID == 0){temp = clock();}//start clocking
   for(int i=0;i<access_number;i++){if(threadID == 0) j=*(long long unsigned **)j;}//access the data array
   if(threadID == 0){
	   latency = (int)(clock() - temp);
	   last_access_value = j[0];
   }
}
*/
int main(void){
   FILE* fp = fopen("./programout.txt","w");
   assert(fp!=NULL);

/*
   for(int array_size = 64; array_size<2048;array_size+=8){
     int device_size = sizeof(int)*array_size;
     int* device_array;
     int* host_array = (int*)malloc(array_size*sizeof(int*));
     cudaMalloc((void**)&device_array,device_size);
     int stride = 4;
     for(int i = 0; i < array_size; i++){
         int t = i + stride;
         if(t >= array_size) t %= stride;
         host_array[i] = *((int*)(&device_array)) + 4*t;//converse the device from int* to int; 4 is the byte size of an int type
     }
     long long int* timing = (long long int*)malloc(sizeof(long long int));
     long long int* timing_d;
     cudaMalloc((void**)&timing_d, sizeof(long long int));
     printf("start computing!\n");
     cudaMemcpy(device_array,host_array,device_size,cudaMemcpyHostToDevice);
     sequence_read<<<1,1,array_size*sizeof(int)>>>(timing_d[0], device_array, array_size, 1000000);
     cudaMemcpy(timing,timing_d,sizeof(long long int),cudaMemcpyDeviceToHost);
     printf ("It took me %lld clicks.\n",timing[0]);
     delete host_array;
     //printf ("It took me %Lf clicks.\n",timing[0]);
   }
*/
	/*
	//cudaEvent_t event1, event2;
	//cudaEventCreate(&event1);
	//cudaEventCreate(&event2);
	
	int* d_time;
	int time;
     int add = 0;
     int* d_add;printf("%d,%d\n",time,add);
     cudaMalloc((void**)&d_time,sizeof(int));
     cudaMalloc((void**)&d_add,sizeof(int));
     cudaMemcpy(d_add,&add,sizeof(int),cudaMemcpyHostToDevice); 
     clock_t start = clock();
     //cudaEventRecord(event1 ,0);
     test_clock<<<1,1>>>(d_time[0],d_add[0]);
     //cudaEventRecord(event2,0);
     //cudaEventSynchronize(event1);
     //cudaEventSynchronize(event2);
     //cudaDeviceSynchronize();
     clock_t end = clock();
     cudaMemcpy(&time,d_time,sizeof(int),cudaMemcpyDeviceToHost);
     cudaMemcpy(&add,d_add,sizeof(int),cudaMemcpyDeviceToHost);
     long double time_elapsed_ms = 1000.0 * (end-start) / CLOCKS_PER_SEC;
     cout << "CPU time used: " << time_elapsed_ms << " ms\n";
     printf("%d,%d\n",time,add);
     //float dt_ms;
     //cudaEventElapsedTime(&dt_ms, event1, event2);
     //cout << "cuda event elpased time:" << dt_ms << " ms\n";
*/
     for(long long unsigned array_size = 16; array_size < 20; array_size += 4){
     int sm_max = 1;
     //long long unsigned array_size = 16;
     //printf("array size =%d\n",array_size);
     fprintf(fp,"%d\t",array_size);
     long long unsigned device_size = sizeof(long long unsigned)*array_size*sm_max;
     long long unsigned* device_array;
     long long unsigned* host_array = (long long unsigned*)malloc(array_size*sizeof(long long unsigned*)*sm_max);
     printf("Strat mallocing\n");
     assert(cudaSuccess == cudaMalloc((void**)&device_array,device_size));
     int stride = 16;//set the access stride = cache_line_size / sizeof(long long unsigned) = 128/8=16
     for(int sm_id =0;sm_id<sm_max;sm_id++){
         for(int i = 0; i < array_size; i++){
             int t = i + stride;
             if(t >= array_size) t %= stride;
             host_array[i+array_size*sm_id] = (long long unsigned)(&(device_array[sm_id*array_size])) + sizeof(long long unsigned)*t;//converse the device from int* to int; 4 is the byte size of an int type
         }
     }
   

/*
     cout<< "sizeof long long unsigned" << sizeof(long long unsigned) << endl;
     cout<< "device array adress: " << (long long unsigned)device_array << endl;
     for(int i=0;i<array_size;i++){
         cout << host_array[i] << endl;
     }
     return 0;
*/


     int* timing = (int*)malloc(sizeof(int)*sm_max);
     int* timing_d;
    // printf ("It took me %d clicks before the funvtion call.\n",timing[0]);
     assert(cudaSuccess == cudaMalloc((void**)&timing_d, sizeof(int)*sm_max));
     long long unsigned* last_access_value = (long long unsigned*)malloc(sizeof(long long unsigned)*sm_max);
     long long unsigned* d_last_access_value;
    // printf ("original last_access value: %llu\n", last_access_value[0]);
     assert(cudaSuccess == cudaMalloc((void**)&d_last_access_value, sizeof(long long unsigned)*sm_max));
    // printf("start computing!\n");
     assert(cudaSuccess == cudaMemcpy(device_array,host_array,device_size,cudaMemcpyHostToDevice));
    
double access_time;
    /* 
     cudaDeviceSynchronize();
     static_sequence_read_multism<<<sm_max,1>>>(timing_d, device_array, 4, d_last_access_value, array_size);
     cudaDeviceSynchronize();
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int)*sm_max,cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned)*sm_max,cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     access_time=0;
     for(int i=0;i<sm_max;i++){
     //printf ("It took me %d clicks, last_access value: %llu.\n",timing[i], last_access_value[i]);
         access_time+=timing[i];
     }
     printf("It took me %lf clicks",access_time/sm_max);
    */



     cudaDeviceSynchronize();
     static_sequence_read_multism<<<sm_max,1>>>(timing_d, device_array, 16, d_last_access_value, array_size);
     cudaDeviceSynchronize();
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int)*sm_max,cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned)*sm_max,cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     access_time = 0;
     for(int i=0;i<sm_max;i++){
     //printf ("It took me %d clicks, last_access value: %llu.\n",timing[i], last_access_value[i]);
         access_time+=timing[i];
     }
    // printf("It took me %lf clicks",access_time/sm_max);
     fprintf(fp,"%lf\n",access_time/sm_max);
     fclose(fp);


     /*
     cudaDeviceSynchronize();
     static_sequence_read_multism<<<sm_max,1>>>(timing_d, device_array, 1, d_last_access_value, array_size);
     cudaDeviceSynchronize();
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int)*sm_max,cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned)*sm_max,cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     access_time = 0;
     for(int i=0;i<sm_max;i++){
     //printf ("It took me %d clicks, last_access value: %llu.\n",timing[i], last_access_value[i]);
         access_time+=timing[i];
     }
     printf("It took me %lf clicks",access_time/sm_max);
     printf("\n");
*/


/*
     static_sequence_read<<<1,1>>>(timing_d[0], device_array, 32, d_last_access_value[0], array_size);
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int),cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned),cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     printf ("It took me %d clicks, last_access value: %llu.\n",timing[0], last_access_value[0]);
     
     static_sequence_read<<<1,1>>>(timing_d[0], device_array, 128, d_last_access_value[0], array_size);
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int),cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned),cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     printf ("It took me %d clicks, last_access value: %llu.\n",timing[0], last_access_value[0], array_size);
*/
    /* static_sequence_read_noinitialize<<<1,1>>>(timing_d[0], device_array, 4096, d_last_access_value[0], array_size);
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int),cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned),cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     printf ("no initiliaze took %d clicks, last_access value: %llu.\n",timing[0], last_access_value[0]);
*/
     /*
     static_sequence_read<<<1,1>>>(timing_d[0], device_array, 4096, d_last_access_value[0], array_size);
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int),cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned),cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     printf ("It took me %d clicks, last_access value: %llu.\n",timing[0], last_access_value[0]);
  */
     /*   
     static_sequence_read_noinitialize<<<1,1>>>(timing_d[0], device_array, 4096, d_last_access_value[0], array_size);
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int),cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned),cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     printf ("no initiliaze took %d clicks, last_access value: %llu.\n",timing[0], last_access_value[0]);
*/
     /*
     static_sequence_read<<<1,1>>>(timing_d[0], device_array, 4096, d_last_access_value[0], array_size);
     assert(cudaSuccess == cudaMemcpy(timing,timing_d,sizeof(int),cudaMemcpyDeviceToHost));
     assert(cudaSuccess == cudaMemcpy(last_access_value,d_last_access_value,sizeof(long long unsigned),cudaMemcpyDeviceToHost));
     cudaDeviceSynchronize();
     printf ("It took me %d clicks, last_access value: %llu.\n",timing[0], last_access_value[0]);
     delete host_array;
     printf ("\n");
     */
     }
   return 0;
} 





