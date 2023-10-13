@echo on

md "%SRC_DIR%"\build
pushd "%SRC_DIR%"\build
set CMAKE_PREFIX_PATH=%LIBRARY_PREFIX%
set DNNL_GPU_RUNTIME=NONE
if [%dnnl_cpu_runtime%]==[tbb] (
    set TBBROOT=%LIBRARY_PREFIX%
    set DNNL_CPU_RUNTIME=TBB
    )
if [%dnnl_cpu_runtime%]==[omp] set DNNL_CPU_RUNTIME=OMP
if [%dnnl_cpu_runtime%]==[threadpool] set DNNL_CPU_RUNTIME=THREADPOOL
if [%dnnl_cpu_runtime%]==[dpcpp] (
    set TBBROOT=%LIBRARY_PREFIX%
    set DNNL_CPU_RUNTIME=DPCPP
    set DNNL_GPU_RUNTIME=DPCPP
    :: A workaround for the dpcpp compiler environment issue:
    :: https://github.com/conda-forge/intel-compiler-repack-feedstock/pull/25
    set "LIB=%BUILD_PREFIX%\Library\lib;%LIB%"
    set "INCLUDE=%BUILD_PREFIX%\include;%INCLUDE%"
    )

cmake -GNinja %CMAKE_ARGS% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DDNNL_CPU_RUNTIME=%DNNL_CPU_RUNTIME% ^
  -DDNNL_GPU_RUNTIME=%DNNL_GPU_RUNTIME% ^
  ..
if errorlevel 1 exit 1
ninja install
if errorlevel 1 exit 1
:: GPU tests are skipped due to lack of GPU installed on the test systems
:: Gtests are sufficient to make sure the library is built correctly
ctest --output-on-failure -E "(gpu^|benchdnn)"
if errorlevel 1 exit 1
popd
