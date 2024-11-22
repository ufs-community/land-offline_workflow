help([[
loads UFS Model prerequisites for Singularity container
]])

setenv("EPICHOME", "/opt")

prepend_path("MODULEPATH", pathJoin(os.getenv("EPICHOME"),"spack-stack/spack-stack-1.6.0/envs/fms-2024.01/install/modulefiles/Core"))

stack_intel_ver=os.getenv("stack_intel_ver") or "2021.10.0"
load(pathJoin("stack-intel", stack_intel_ver))

load("intel-oneapi-mpi/2021.9.0")
stack_intel_oneapi_mpi_ver=os.getenv("stack_intel_oneapi_mpi_ver") or "2021.9.0"
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

--stack_python_ver=os.getenv("stack_python_ver") or "3.10.13"
--load(pathJoin("stack-python", stack_python_ver))

cmake_ver=os.getenv("cmake_ver") or "3.23.1"
load(pathJoin("cmake", cmake_ver))

ecbuild_ver=os.getenv("ecbuild_ver") or "3.7.2"
load(pathJoin("ecbuild", ecbuild_ver))

jasper_ver=os.getenv("jasper_ver") or "2.0.32"
load(pathJoin("jasper", jasper_ver))

zlib_ver=os.getenv("zlib_ver") or "1.2.13"
load(pathJoin("zlib", zlib_ver))

libpng_ver=os.getenv("libpng_ver") or "1.6.37"
load(pathJoin("libpng", libpng_ver))

hdf5_ver=os.getenv("hdf5_ver") or "1.14.0"
load(pathJoin("hdf5", hdf5_ver))

netcdf_c_ver=os.getenv("netcdf_ver") or "4.9.2"
load(pathJoin("netcdf-c", netcdf_c_ver))

netcdf_fortran_ver=os.getenv("netcdf_fortran_ver") or "4.6.1"
load(pathJoin("netcdf-fortran", netcdf_fortran_ver))

pio_ver=os.getenv("pio_ver") or "2.5.10"
load(pathJoin("parallelio", pio_ver))

esmf_ver=os.getenv("esmf_ver") or "8.6.0"
load(pathJoin("esmf", esmf_ver))

fms_ver=os.getenv("fms_ver") or "2024.01"
load(pathJoin("fms",fms_ver))

bacio_ver=os.getenv("bacio_ver") or "2.4.1"
load(pathJoin("bacio", bacio_ver))

crtm_ver=os.getenv("crtm_ver") or "2.4.0"
load(pathJoin("crtm", crtm_ver))

g2_ver=os.getenv("g2_ver") or "3.5.1"
load(pathJoin("g2", g2_ver))

g2tmpl_ver=os.getenv("g2tmpl_ver") or "1.13.0"
load(pathJoin("g2tmpl", g2tmpl_ver))

ip_ver=os.getenv("ip_ver") or "4.3.0"
load(pathJoin("ip", ip_ver))

sp_ver=os.getenv("sp_ver") or "2.5.0"
load(pathJoin("sp", sp_ver))

w3emc_ver=os.getenv("w3emc_ver") or "2.10.0"
load(pathJoin("w3emc", w3emc_ver))

gftl_shared_ver=os.getenv("gftl_shared_ver") or "1.6.1"
load(pathJoin("gftl-shared", gftl_shared_ver))

mapl_ver=os.getenv("mapl_ver") or "2.40.3-esmf-8.6.0"
load(pathJoin("mapl", mapl_ver))

scotch_ver=os.getenv("scotch_ver") or "7.0.4"
load(pathJoin("scotch", scotch_ver))

load("py-cftime/1.0.3.4")
load("py-cython/0.29.36")
load("py-f90nml/1.4.3")
load("py-jinja2/3.0.3")
load("py-netcdf4/1.5.8")
load("py-numpy/1.22.3")
load("py-pandas/1.5.3")
load("py-python-dateutil/2.8.2")
load("py-pyyaml/6.0")

setenv("CFLAGS","-diag-disable=10448")
setenv("FFLAGS","-diag-disable=10448")

prepend_path("PATH","/opt/intel/oneapi/compiler/2024.0/bin:/opt/intel/oneapi/compiler/2023.2.3/linux/bin/intel64")
--setenv("CMAKE_C_COMPILER","mpiicc")
--setenv("CMAKE_CXX_COMPILER","mpicxx")
--setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CC", "mpiicc")
setenv("CXX", "mpiicpc")
setenv("FC", "mpiifort")

setenv("JEDI_PATH", pathJoin(os.getenv("EPICHOME"),""))

whatis("Description: UFS build environment")
