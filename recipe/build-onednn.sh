#!/bin/bash

set -exuo pipefail

if [[ "${target_platform}" == "linux-64" ]]; then
  export LDFLAGS="-lrt ${LDFLAGS}"
fi

if [[ "${target_platform}" == "osx-"* ]]; then
  # workaround till https://gitlab.kitware.com/cmake/cmake/-/merge_requests/7941 is merged
  ln -sf ${PREFIX}/include/CL ${PREFIX}/include/Headers
fi

mkdir build
pushd build
if [[ "${dnnl_cpu_runtime}" == "tbb" ]]; then
  export TBBROOT=${PREFIX}
  DNNL_CPU_RUNTIME="TBB"
elif [[ "${dnnl_cpu_runtime}" == "omp" ]]; then
  DNNL_CPU_RUNTIME="OMP"
elif [[ "${dnnl_cpu_runtime}" == "threadpool" ]]; then
  DNNL_CPU_RUNTIME="THREADPOOL"
fi

DNNL_GPU_RUNTIME=$(echo "${dnnl_gpu_runtime}" | tr '[:lower:]' '[:upper:]')

cmake ${CMAKE_ARGS} -GNinja \
  -DDNNL_CPU_RUNTIME=${DNNL_CPU_RUNTIME} \
  -DDNNL_GPU_RUNTIME=${DNNL_GPU_RUNTIME} \
  -DCMAKE_FIND_FRAMEWORK=LAST \
  ..
ninja install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != 1 ]]; then
  ninja test
fi
popd

if [[ "${target_platform}" == "osx-"* ]]; then
  # workaround till https://gitlab.kitware.com/cmake/cmake/-/merge_requests/7941 is merged
  rm -f ${PREFIX}/include/Headers
fi
