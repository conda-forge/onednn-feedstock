#!/bin/bash

set -exuo pipefail

if [[ "${target_platform}" == "linux-64" ]]; then
  export LDFLAGS="-lrt ${LDFLAGS}"
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
  export TBBROOT=${PREFIX}
  DNNL_CPU_RUNTIME="DPCPP"
  DNNL_GPU_RUNTIME="DPCPP"
fi

cmake ${CMAKE_ARGS} -GNinja \
  -DDNNL_CPU_RUNTIME=${DNNL_CPU_RUNTIME} \
  -DDNNL_GPU_RUNTIME=${DNNL_GPU_RUNTIME} \
  ..
ninja install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != 1 ]]; then
  # GPU tests are skipped due to lack of GPU installed on the test systems
  # Gtests are sufficient to make sure the library is built correctly
  ctest --output-on-failure -E "gpu|benchdnn"
fi
popd
