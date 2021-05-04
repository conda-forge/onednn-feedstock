#!/bin/bash

set -exuo pipefail

mkdir build
pushd build
if [[ "${dnnl_cpu_runtime}" == "tbb" ]]; then
  export TBBROOT=${PREFIX}
  export LDFLAGS="${LDFLAGS} -ltbb"
  DNNL_CPU_RUNTIME="TBB"
elif [[ "${dnnl_cpu_runtime}" == "omp" ]]; then
  DNNL_CPU_RUNTIME="OMP"
fi
cmake ${CMAKE_ARGS} -GNinja \
  -DDNNL_CPU_RUNTIME=${DNNL_CPU_RUNTIME} \
  -DDNNL_GPU_RUNTIME=NONE \
  ..
ninja install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != 1 ]]; then
  ninja test
fi
popd
