// Copyright (c) 2020 PaddlePaddle Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "lite/core/op_registry.h"
#include "lite/kernels/cuda/abs_compute.h"

namespace paddle {
namespace lite {
namespace kernels {
namespace cuda {

template <typename T>
__global__ void AbsKernel(const int num, const T* input, T* output);

template <>
__global__ void AbsKernel<float>(const int num,
                                 const float* input,
                                 float* output) {
  int index = blockIdx.x * blockDim.x + threadIdx.x;
  if (index < num) {
    output[index] = fabsf(input[index]);
  }
}

template <>
__global__ void AbsKernel<double>(const int num,
                                  const double* input,
                                  double* output) {
  int index = blockIdx.x * blockDim.x + threadIdx.x;
  if (index < num) {
    output[index] = fabs(input[index]);
  }
}

void AbsCompute::Run() {
  auto& param = this->Param<param_t>();
  auto& ctx = this->ctx_->template As<CUDAContext>();
  auto stream = ctx.exec_stream();

  int num = static_cast<int>(param.X->numel());
  auto input = param.X->data<float>();
  auto output = param.Out->mutable_data<float>(TARGET(kCUDA));

  const int threads = 512;
  const int blocks = (num + threads - 1) / threads;
  AbsKernel<float><<<blocks, threads, 0, stream>>>(num, input, output);
  cudaError_t error = cudaGetLastError();
  if (error != cudaSuccess) LOG(ERROR) << cudaGetErrorString(error);
}

}  // namespace cuda
}  // namespace kernels
}  // namespace lite
}  // namespace paddle

REGISTER_LITE_KERNEL(
    abs, kCUDA, kFloat, kNCHW, paddle::lite::kernels::cuda::AbsCompute, def)
    .BindInput("X", {LiteType::GetTensorTy(TARGET(kCUDA))})
    .BindOutput("Out", {LiteType::GetTensorTy(TARGET(kCUDA))})
    .Finalize();
