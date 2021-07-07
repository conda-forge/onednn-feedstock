@echo on

md "%SRC_DIR%"\build
pushd "%SRC_DIR%"\build
set CMAKE_PREFIX_PATH=%LIBRARY_PREFIX%
if [%dnnl_cpu_runtime%]==[tbb] (
    set TBBROOT=%LIBRARY_PREFIX%
    set DNNL_CPU_RUNTIME=TBB
    )
if [%dnnl_cpu_runtime%]==[omp] set DNNL_CPU_RUNTIME=OMP
if [%dnnl_cpu_runtime%]==[threadpool] set DNNL_CPU_RUNTIME=THREADPOOL

cmake -GNinja %CMAKE_ARGS% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DDNNL_CPU_RUNTIME=%DNNL_CPU_RUNTIME% ^
  -DDNNL_GPU_RUNTIME=NONE ^
  ..
if errorlevel 1 exit 1
ninja install
if errorlevel 1 exit 1
ninja test
if errorlevel 1 exit 1
popd
