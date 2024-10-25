prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack_unienv"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))
load(pathJoin("stack-python", stack_python_ver))

load(pathJoin("prod_util", prod_util_ver))
load(pathJoin("py-cartopy", py_cartopy_ver))
load(pathJoin("py-matplotlib", py_matplotlib_ver))
load(pathJoin("py-netcdf4", py_netcdf4_ver))
load(pathJoin("py-numpy", py_numpy_ver))
load(pathJoin("py-pandas", py_pandas_ver))
load(pathJoin("py-pyyaml", py_pyyaml_ver))
load(pathJoin("py-scipy", py_scipy_ver))
load(pathJoin("py-xarray", py_xarray_ver))

