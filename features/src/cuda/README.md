
# CUDA Toolkit (cuda)

A feature to install the NVIDIA CUDA Toolkit

## Example Usage

```json
"features": {
    "ghcr.io/rapidsai/devcontainers/features/cuda:25": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of the CUDA Toolkit to install. | string | 12.8 |
| cuDNNVersion | Version of cuDNN to install. | string | 8 |
| installCompilers | Install NVIDIA CUDA Compiler (nvcc) | boolean | true |
| installProfilers | Install NVIDIA NSight Systems Profiler (nsys) | boolean | true |
| installCTKLibraries | Shortcut to install all CUDA Toolkit Libraries | boolean | true |
| installDevPackages | Whether to install the CUDA dev packages (static libraries + headers) | boolean | true |
| installcuDNN | Install CUDA Deep Neural Network Library (cuDNN) | boolean | false |
| installcuTensor | Install CUDA Tensor Linear Algebra Library (cuTensor) | boolean | false |
| installNCCL | Install NVIDIA Collective Communications Library (NCCL) | boolean | true |
| installCUDARuntime | Install CUDA Runtime Library (cudart) | boolean | true |
| installNVRTC | Install NVIDIA Runtime Compilation Library (NVRTC) | boolean | false |
| installOpenCL | Install NVIDIA CUDA OpenCL Library | boolean | false |
| installcuBLAS | Install CUDA Basic Linear Algebra Library (cuBLAS) | boolean | false |
| installcuSPARSE | Install CUDA Basic Linear Algebra for Sparse Matrices Library (cuSPARSE) | boolean | false |
| installcuFFT | Install CUDA Fast Fourier Transform Library (cuFFT) | boolean | false |
| installcuFile | Install CUDA GPUDirect Storage API Library (cuFile) | boolean | false |
| installcuRAND | Install CUDA Random Number Generation Library (cuRAND) | boolean | false |
| installcuSOLVER | Install CUDA Direct Linear Solvers Library (cuSOLVER) | boolean | false |
| installNPP | Install NVIDIA Performance Primitives (NPP) | boolean | false |
| installnvJPEG | Install NVIDIA JPEG decoder, encoder, and transcoder library (nvJPEG) | boolean | false |
| pruneStaticLibs | Whether to remove static libs from the CUDA Toolkit to save image size | boolean | true |

## Customizations

### VS Code Extensions

- `ms-vscode.cpptools`
- `nvidia.nsight-vscode-edition`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rapidsai/devcontainers/blob/main/features/src/cuda/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
