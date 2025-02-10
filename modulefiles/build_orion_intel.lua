help([[
loads modules necessary for building the land-DA workflow on Orion using Intel
]])

whatis([===[Loads modules necessary for building the land-DA workflow on Orion]===])

prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))
load(pathJoin("stack-python", stack_python_ver))

load(pathJoin("cmake", cmake_ver))
load(pathJoin("ecbuild", ecbuild_ver))

load(pathJoin("jasper", jasper_ver))
load(pathJoin("zlib", zlib_ver))
load(pathJoin("libpng", libpng_ver))
load(pathJoin("hdf5", hdf5_ver))
load(pathJoin("netcdf-c", netcdf_c_ver))
load(pathJoin("netcdf-fortran", netcdf_fortran_ver))
load(pathJoin("parallelio", parallelio_ver))
load(pathJoin("esmf", esmf_ver))
load(pathJoin("fms",fms_ver))
load(pathJoin("bacio", bacio_ver))
load(pathJoin("crtm", crtm_ver))
load(pathJoin("g2", g2_ver))
load(pathJoin("g2tmpl", g2tmpl_ver))
load(pathJoin("ip", ip_ver))
load(pathJoin("sp", sp_ver))
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("gftl-shared", gftl_shared_ver))
load(pathJoin("mapl", mapl_ver))
load(pathJoin("scotch", scotch_ver))

load(pathJoin("nemsio", nemsio_ver))
load(pathJoin("sfcio", sfcio_ver))
load(pathJoin("sigio", sigio_ver))
load(pathJoin("nccmp", nccmp_ver))

load(pathJoin("prod_util", prod_util_ver))
load(pathJoin("ufs-pyenv", ufs_pyenv_ver))

setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441")

setenv("CC", "mpiicc")
setenv("CXX", "mpiicpc")
setenv("FC", "mpiifort")
setenv("CMAKE_Platform", "orion.intel")

