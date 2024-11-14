# (C) Copyright 2017-2020 UCAR.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.


################################################################################
# LandDA
################################################################################

cmake_minimum_required( VERSION 3.12 )
project( LandDA VERSION 0.0.0 LANGUAGES C CXX Fortran)
find_package(ecbuild 3.3.2 REQUIRED)
enable_testing()

# Inlcude externalproject
# -----------------------
add_custom_target(build DEPENDS pbuild)
include(ExternalProject)

################################################################################
# Dependencies
################################################################################
find_package(MPI REQUIRED COMPONENTS C CXX Fortran)
find_package(NetCDF REQUIRED COMPONENTS Fortran)
include_directories( ${NETCDF_INCLUDE_DIRS} )

################################################################################
# Sources
################################################################################

message(APP="${APP}")
if(NOT APP)
  set(APP "LND")
endif()
message(APP="${APP}")

message(CCPP_SUITES="${CCPP_SUITES}")
if((NOT APP MATCHES "LND") AND (NOT CCPP_SUITES))
  set(CCPP_SUITES "FV3_GFS_v17_p8")
endif()
message(CCPP_SUITES="${CCPP_SUITES}")

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()

if(APP MATCHES "ATML")
  # UFS_UTILS
  list(APPEND UFS_UTILS_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DBUILD_TESTING=OFF"
    "-DCHGRES=ON"
    "-DCPLD_GRIDGEN=OFF"
    "-DFRENCTOOLS=OFF"
    "-DFVCOMTOOLS=OFF"
    "-DGBLEVENTS=OFF"
    "-DGCYCLE=OFF"
    "-DGRIDTOOLS=OFF"
    "-DICEBLEND=OFF"
    "-DOCEAN_MERGE=OFF"
#    "-DOCNICE_PREP=OFF"
    "-DOROG_MASK_TOOLS=OFF"
#    "-DOROG_NETCDF_TOOLS=OFF"
    "-DSFC_CLIMO_GEN=OFF"
    "-DSNOW2MDL=OFF"
    "-DVCOORD_GEN=OFF"
    "-DWEIGHT_GEN=OFF"
  )
 
  list(APPEND TARGET LIST UFS_UTILS.fd)
  ExternalProject_Add(UFS_UTILS.fd
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/UFS_UTILS.fd
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/UFS_UTILS.fd
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS ${UFS_UTILS_ARGS}
    BUILD_ALWAYS TRUE
    STEP_TARGETS build
    )

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

# UFS Weather Model (ufs_model)
list(APPEND TARGET LIST ufs_model.fd)
ExternalProject_Add(ufs_model.fd
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/ufs_model.fd
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ufs_model.fd
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  CMAKE_ARGS ${UFS_MODEL_ARGS}
  INSTALL_COMMAND mkdir -p ${CMAKE_INSTALL_PREFIX}/bin && cp ${CMAKE_CURRENT_BINARY_DIR}/ufs_model.fd/src/ufs_model.fd-build/ufs_model ${CMAKE_INSTALL_PREFIX}/bin
  BUILD_ALWAYS TRUE
  STEP_TARGETS build
  )

# APPLY_INCR for JEDI
list(APPEND APPLY_INCR_ARGS
  "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
)
list(APPEND TARGET LIST apply_incr.fd)
ExternalProject_Add(apply_incr.fd
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/apply_incr.fd
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/apply_incr.fd
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  CMAKE_ARGS ${APPLY_INCR_ARGS}
  BUILD_ALWAYS TRUE
  STEP_TARGETS build
  )

# Tile to Tile Converter
list(APPEND TILE2TILE_CONVERTER_ARGS
  "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"  
)
list(APPEND TARGET LIST tile2tile_converter.fd)
ExternalProject_Add(tile2tile_converter.fd
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/tile2tile_converter.fd
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/tile2tile_converter.fd
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  CMAKE_ARGS ${TILE2TILE_CONVERTER_ARGS}
  BUILD_ALWAYS TRUE
  STEP_TARGETS build
  )

# C-Test
add_subdirectory(test)

# add custom target for separate build and install
foreach(i ${TARGET_LIST})
  list(APPEND BUILD_LIST "${i}-build")
endforeach()

add_custom_target(pbuild DEPENDS ${BUILD_LIST})
