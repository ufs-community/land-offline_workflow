# (C) Copyright 2017-2020 UCAR.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.


################################################################################
# LandDA
################################################################################

cmake_minimum_required( VERSION 3.12 )
project( LandDA VERSION 0.0.0 LANGUAGES C CXX Fortran)

if(DEFINED ENV{JEDI_INSTALL})
 set( JEDI_INSTALL  $ENV{JEDI_INSTALL}/jedi-bundle)
else()
  message(FATAL_ERROR "Define the environment variable 'JEDI_INSTALL' to point to the parent directory of fv3-bundle on your system")
endif()
find_package(ecbuild 3.3.2 REQUIRED)
enable_testing()
include( ecbuild_system NO_POLICY_SCOPE )
ecbuild_declare_project()

# Inlcude externalproject
# -----------------------
include(ExternalProject)

# Initialize bundle
# -----------------
ecbuild_bundle_initialize()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(landda_compiler_flags)


################################################################################
# Dependencies
################################################################################
find_package(NetCDF REQUIRED COMPONENTS Fortran)
include_directories( ${NETCDF_INCLUDE_DIRS} )

################################################################################
# Sources
################################################################################
set(LANDDA_LINKER_LANGUAGE CXX)

if(NOT APP)
  set(APP "LND")
endif()

if(NOT CCPP_SUITES)
  set(CCPP_SUITES "FV3_GFS_v17_p8")
endif()

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()

if(APP STREQUAL "ATML")
  list(APPEND UFS_MODEL_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DAPP=${APP}"
    "-DCCPP_SUITES=${CCPP_SUITES}"
    "-D32BIT=ON"
    "-DMPI=ON"
  )
else()
  list(APPEND UFS_MODEL_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DAPP=${APP}"
    "-DMPI=ON"
  )
endif()

ExternalProject_Add(ufs_model.fd
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/ufs_model.fd
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ufs_model.fd
  CMAKE_ARGS ${UFS_MODEL_ARGS}
  INSTALL_COMMAND cmake
  )

add_subdirectory(tile2tile_converter.fd)
add_subdirectory(apply_incr.fd)
# Include testing.
add_subdirectory(test)

if(ECBUILD_INSTALL_FORTRAN_MODULES)
  install(DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/${CMAKE_CFG_INTDIR} DESTINATION ${INSTALL_INCLUDE_DIR} )
endif()

################################################################################
# Finalise configuration
################################################################################

# prepares a tar.gz of the sources and/or binaries
ecbuild_install_project( NAME LandDA )

# print the summary of the configuration
ecbuild_print_summary()
