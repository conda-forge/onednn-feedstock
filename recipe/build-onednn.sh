#!/bin/bash

set -exuo pipefail

if [[ "${target_platform}" == "linux-64" ]]; then
  export LDFLAGS="-lrt ${LDFLAGS}"
elif [[ "${target_platform}" == "linux-ppc64le" ]]; then
  export CFLAGS="${CFLAGS//-fno-plt/}"
  export CXXFLAGS="${CXXFLAGS//-fno-plt/}"
fi

mkdir build
pushd build
DNNL_GPU_RUNTIME="NONE"
if [[ "${dnnl_cpu_runtime}" == "tbb" ]]; then
  export TBBROOT=${PREFIX}
  DNNL_CPU_RUNTIME="TBB"
elif [[ "${dnnl_cpu_runtime}" == "omp" ]]; then
  DNNL_CPU_RUNTIME="OMP"
elif [[ "${dnnl_cpu_runtime}" == "threadpool" ]]; then
  DNNL_CPU_RUNTIME="THREADPOOL"
elif [[ "${dnnl_cpu_runtime}" == "dpcpp" ]]; then
  CMAKE_PREFIX_PATH=${PREFIX}/lib/cmake/TBB
  export TBBROOT=${PREFIX}
  DNNL_CPU_RUNTIME="DPCPP"
  DNNL_GPU_RUNTIME="DPCPP"
fi

DNNL_EXPERIMENTAL_UKERNEL=OFF
# DNNL_EXPERIMENTAL_UKERNEL required by PyTorch
# However, it requires routines implemented for x64 only.
case ${target_platform} in
  linux-64|osx-64)
    DNNL_EXPERIMENTAL_UKERNEL=ON;;
esac
cmake ${CMAKE_ARGS} -GNinja \
  -DDNNL_CPU_RUNTIME=${DNNL_CPU_RUNTIME} \
  -DDNNL_GPU_RUNTIME=${DNNL_GPU_RUNTIME} \
  -DDNNL_EXPERIMENTAL_UKERNEL=${DNNL_EXPERIMENTAL_UKERNEL} \
  ..
ninja install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != 1 ]]; then
  # A simple test to validate environment setup for DPCPP
  if [[ "${dnnl_cpu_runtime}" == "dpcpp" ]]; then
    icpx -fsycl ${CXXFLAGS} ${RECIPE_DIR}/dpcpp_check.cpp ${LDFLAGS} -lpthread -o dpcpp_check.exe
    ./dpcpp_check.exe
  fi
  # GPU tests are skipped due to lack of GPU installed on the test systems
  # Gtests are sufficient to make sure the library is built correctly
  ctest --output-on-failure -E "gpu|benchdnn"
fi
popd
