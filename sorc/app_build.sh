#!/bin/bash

set -x

# usage instructions
usage () {
cat << EOF_USAGE
Usage: $0 [OPTIONS]

OPTIONS
  -h, --help
      show this help guide
  -p, --platform=PLATFORM
      name of machine you are building on
      (e.g. hera | jet | orion | hercules )
  -c, --compiler=COMPILER
      compiler to use; default depends on platform
      (e.g. intel | gnu | cray | gccgfortran)
  -a, --app=APPLICATION
      weather model application to build; for example, ATML for ATM+LAND
      (e.g. LND | ATML )
  --ccpp="CCPP_SUITE1,CCPP_SUITE2..."
      CCPP suites (CCPP_SUITES) to include in build; delimited with ','
  --remove
      removes existing build; overrides --continue
  --clean
      does a "make clean"
  --build
      build only in BUILD_DIR
  --move
      move binaries to final location.
  --build-dir=BUILD_DIR
      build directory
  --install-dir=INSTALL_DIR
      installation prefix
  --bin-dir=BIN_DIR
      installation binary directory name ("exec" by default; any name is available)
  --conda=BUILD_CONDA (on|off|only)
  --conda-dir=CONDA_DIR
      installation location for miniconda (SRW clone conda subdirectory by default)
  --build-type=BUILD_TYPE
      build type; defaults to Release
      (e.g. Debug | Release | RelWithDebInfo)
  --build-jobs=BUILD_JOBS
      number of build jobs; defaults to 4
  -v, --verbose
      build with verbose output

NOTE: See User's Guide for detailed build instructions

EOF_USAGE
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  HOME_DIR=${HOME_DIR}
  BUILD_DIR=${BUILD_DIR}
  INSTALL_DIR=${INSTALL_DIR}
  BIN_DIR=${BIN_DIR}
  PLATFORM=${PLATFORM}
  COMPILER=${COMPILER}
  APP=${APPLICATION}
  CCPP=${CCPP_SUITES}
  REMOVE=${REMOVE}
  BUILD_TYPE=${BUILD_TYPE}
  BUILD_JOBS=${BUILD_JOBS}
  VERBOSE=${VERBOSE}

EOF_SETTINGS
}

# print usage error and exit
usage_error () {
  printf "ERROR: $1\n" >&2
  usage >&2
  exit 1
}

# default settings
LCL_PID=$$
SORC_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
HOME_DIR="${SORC_DIR}/.."
BUILD_DIR="${SORC_DIR}/build"
INSTALL_DIR="${SORC_DIR}/build"
BIN_DIR="exec"
CONDA_BUILD_DIR="${SORC_DIR}/conda"
COMPILER=""
APPLICATION=""
CCPP_SUITES=""
BUILD_TYPE="Release"
BUILD_JOBS=4
REMOVE=false
VERBOSE=false
BUILD_CONDA="on"

# Make options
CLEAN=false
BUILD=false
MOVE=false

# process required arguments
if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
  usage
  exit 0
fi

# process optional arguments
while :; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --platform=?*|-p=?*) PLATFORM=${1#*=} ;;
    --platform|--platform=|-p|-p=) usage_error "$1 requires argument." ;;
    --compiler=?*|-c=?*) COMPILER=${1#*=} ;;
    --compiler|--compiler=|-c|-c=) usage_error "$1 requires argument." ;;
    --app=?*|-a=?*) APPLICATION=${1#*=} ;;
    --app|--app=|-a|-a=) usage_error "$1 requires argument." ;;
    --ccpp=?*) CCPP_SUITES=${1#*=} ;;
    --ccpp|--ccpp=) usage_error "$1 requires argument." ;;
    --remove) REMOVE=true ;;
    --remove=?*|--remove=) usage_error "$1 argument ignored." ;;
    --clean) CLEAN=true ;;
    --build) BUILD=true ;;
    --move) MOVE=true ;;
    --build-dir=?*) BUILD_DIR=${1#*=} ;;
    --build-dir|--build-dir=) usage_error "$1 requires argument." ;;
    --install-dir=?*) INSTALL_DIR=${1#*=} ;;
    --install-dir|--install-dir=) usage_error "$1 requires argument." ;;
    --bin-dir=?*) BIN_DIR=${1#*=} ;;
    --bin-dir|--bin-dir=) usage_error "$1 requires argument." ;;
    --conda=?*) BUILD_CONDA=${1#*=} ;;
    --conda|--conda=) usage_error "$1 requires argument." ;;
    --conda-dir=?*) CONDA_BUILD_DIR=${1#*=} ;;
    --conda-dir|--conda-dir=) usage_error "$1 requires argument." ;;
    --build-type=?*) BUILD_TYPE=${1#*=} ;;
    --build-type|--build-type=) usage_error "$1 requires argument." ;;
    --build-jobs=?*) BUILD_JOBS=$((${1#*=})) ;;
    --build-jobs|--build-jobs=) usage_error "$1 requires argument." ;;
    --verbose|-v) VERBOSE=true ;;
    --verbose=?*|--verbose=) usage_error "$1 argument ignored." ;;
    # unknown
    -?*|?*) usage_error "Unknown option $1" ;;
    *) break
  esac
  shift
done

# Ensure uppercase / lowercase ============================================
APPLICATION=$(echo ${APPLICATION} | tr '[a-z]' '[A-Z]')
PLATFORM=$(echo ${PLATFORM} | tr '[A-Z]' '[a-z]')
COMPILER=$(echo ${COMPILER} | tr '[A-Z]' '[a-z]')

# move the pre-compiled executables to the designated location and exit
if [ "${BUILD}" = false ] && [ "${MOVE}" = true ]; then
  if [[ ! ${HOME_DIR} -ef ${INSTALL_DIR} ]]; then
    printf "... Moving pre-compiled executables to designated location ...\n"
    mkdir -p ${HOME_DIR}/${BIN_DIR}
    cd "${INSTALL_DIR}/${BIN_DIR}"
    for file in *; do
      [ -x "${file}" ] && mv "${file}" "${HOME_DIR}/${BIN_DIR}"
    done
  fi
  exit 0
fi

# check if PLATFORM is set
if [ -z $PLATFORM ] ; then
  # Automatically detect HPC platforms for hera, jet, orion, hercules, wcoss2, etc
  source ${HOME_DIR}/parm/detect_platform.sh
  if [ "${PLATFORM}" = "unknown" ]; then
    printf "\nERROR: Please set PLATFORM.\n\n"
    usage
    exit 0
  fi
fi
printf "PLATFORM(MACHINE)=${PLATFORM}\n" >&2

# Remove option
if [ "${REMOVE}" = true ]; then
  printf "Remove build directory\n"
  printf "  BUILD_DIR=${BUILD_DIR}\n"
  if [ -d "${BUILD_DIR}" ]; then
    rm -rf ${BUILD_DIR}
  fi
  printf "Remove BIN_DIR directory\n"
  printf "  BIN_DIR=${HOME_DIR}/${BIN_DIR}\n"
  if [ -d "${HOME_DIR}/${BIN_DIR}" ]; then
    rm -rf "${HOME_DIR}/${BIN_DIR}"
  fi
  printf "Remove lib directory\n"
  printf "  LIB_DIR=${HOME_DIR}/lib\n"
  if [ -d "${HOME_DIR}/lib" ]; then
    rm -rf "${HOME_DIR}/lib"
    rm -rf "${HOME_DIR}/lib64"
  fi
  printf "Remove submodules\n"
  if [ -d "${SORC_DIR}/apply_incr.fd" ]; then
    printf "... Remove apply_incr.fd ...\n"
    rm -rf "${SORC_DIR}/apply_incr.fd"
  fi
  if [ -d "${SORC_DIR}/ufs_model.fd" ]; then
    printf "... Remove ufs_model.fd ...\n"
    rm -rf "${SORC_DIR}/ufs_model.fd"
  fi

  cd "${HOME_DIR}"
  git submodule update --init --recursive
  cd "${SORC_DIR}"
  exit 0  
fi

# Conda is not used on Gaea-c5 F2 filesystem as well as wcoss2
if [ "${PLATFORM}" = "gaea-c5" ] || [ "${PLATFORM}" = "wcoss2" ]; then
  BUILD_CONDA="off"
fi
# build conda and conda environments, if requested.
if [ "${BUILD_CONDA}" = "on" ] || [ "${BUILD_CONDA}" = "only" ]; then
  if [ "${BUILD_CONDA}" = "only" ]; then
    if [ -d "${CONDA_BUILD_DIR}" ]; then
      printf "Removing conda build directory ...\n"
      rm -rf "${CONDA_BUILD_DIR}"
      printf "Removed ...\n"
    fi
  fi

  if [ ! -d "${CONDA_BUILD_DIR}" ] ; then
    os=$(uname)
    test $os == Darwin && os=MacOSX
    hardware=$(uname -m)
    installer=Miniforge3-${os}-${hardware}.sh
    curl -L -O "https://github.com/conda-forge/miniforge/releases/download/23.3.1-1/${installer}"
    bash ./${installer} -bfp "${CONDA_BUILD_DIR}"
    rm ${installer}
  fi

  source ${CONDA_BUILD_DIR}/etc/profile.d/conda.sh
  # Put some additional packages in the base environment on MacOS systems
  if [ "${os}" == "MacOSX" ] ; then
    mamba install -y bash coreutils sed
  fi
  conda activate
  if ! conda env list | grep -q "^land_da\s" ; then
    mamba env create -n land_da --file ${HOME_DIR}/parm/conda_environment.yml
  fi

else
  if [ -d "${CONDA_BUILD_DIR}" ] ; then
    source ${CONDA_BUILD_DIR}/etc/profile.d/conda.sh
    conda activate
  fi
fi

CONDA_BUILD_DIR="$(readlink -f "${CONDA_BUILD_DIR}")"
echo ${CONDA_BUILD_DIR} > ${HOME_DIR}/parm/conda_loc

[[ "${BUILD_CONDA}" == "only" ]] && exit 0

if [ -d "${BUILD_DIR}" ]; then
  while true; do
    if [[ $(ps -o stat= -p ${LCL_PID}) != *"+"* ]] ; then
      printf "ERROR: Build directory already exists.\n" >&2
      printf "  BUILD_DIR=${BUILD_DIR}\n\n" >&2
      usage >&2
      exit 64
    fi
    # interactive selection
    printf "Build directory (${BUILD_DIR}) already exists.\n"
    printf "Please choose what to do:\n\n"
    printf "[R]emove the existing directory and continue to build\n"
    printf "[C]ontinue building in the existing directory\n"
    printf "[Q]uit this build script\n"
    read -p "Choose an option (R/C/Q):" choice
    case ${choice} in
      [Rr]* ) rm -rf ${BUILD_DIR}; break ;;
      [Cc]* ) break ;;
      [Qq]* ) exit ;;
      * ) printf "Invalid option selected.\n" ;;
    esac
  done
fi

set -eu

# automatically determine compiler
if [ -z "${COMPILER}" ] ; then
  case ${PLATFORM} in
    jet|hera|gaea) COMPILER=intel ;;
    orion|hercules) COMPILER=intel ;;
    wcoss2) COMPILER=intel ;;
    macos|singularity) COMPILER=gnu ;;
    odin|noaacloud) COMPILER=intel ;;
    *)
      COMPILER=intel
      printf "WARNING: Setting default COMPILER=intel for new platform ${PLATFORM}\n" >&2;
      ;;
  esac
fi
printf "COMPILER=${COMPILER}\n" >&2

# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

# cmake settings
CMAKE_SETTINGS="\
 -DCMAKE_BUILD_TYPE=${BUILD_TYPE}\
 -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}\
 -DCMAKE_INSTALL_BINDIR=${BIN_DIR}"

if [ ! -z "${APPLICATION}" ]; then
  CMAKE_SETTINGS="${CMAKE_SETTINGS} -DAPP=${APPLICATION}"
fi
if [ ! -z "${CCPP_SUITES}" ]; then
  CMAKE_SETTINGS="${CMAKE_SETTINGS} -DCCPP_SUITES=${CCPP_SUITES}"
fi

# make settings
MAKE_SETTINGS="-j ${BUILD_JOBS}"
if [ "${VERBOSE}" = true ]; then
  MAKE_SETTINGS="${MAKE_SETTINGS} VERBOSE=1"
fi

module purge

# source version file for build
BUILD_VERSION_FILE="${HOME_DIR}/versions/build.ver_${PLATFORM}"
if [ -e ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi

# set MODULE_FILE for this platform/compiler combination
MODULE_FILE="build_${PLATFORM}_${COMPILER}"
if [ ! -f "${HOME_DIR}/modulefiles/${MODULE_FILE}.lua" ]; then
  printf "ERROR: module file does not exist for platform/compiler\n" >&2
  printf "  MODULE_FILE=${MODULE_FILE}\n" >&2
  printf "  PLATFORM=${PLATFORM}\n" >&2
  printf "  COMPILER=${COMPILER}\n\n" >&2
  printf "Please make sure PLATFORM and COMPILER are set correctly\n" >&2
  usage >&2
  exit 64
fi

printf "MODULE_FILE=${MODULE_FILE}\n" >&2

# load modules for platform/compiler combination, then build the code
printf "... Load MODULE_FILE and create BUILD directory ...\n"
module use ${HOME_DIR}/modulefiles
module load ${MODULE_FILE}
module list

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

if [ "${CLEAN}" = true ]; then
  if [ -f $PWD/Makefile ]; then
    printf "... Clean executables ...\n"
    make ${MAKE_SETTINGS} clean 2>&1 | tee log.make
  fi
else
  printf "... Generate CMAKE configuration ...\n"
  ecbuild ${SORC_DIR} ${CMAKE_SETTINGS} 2>&1 | tee log.ecbuild

  printf "... Compile executables ...\n"
  make ${MAKE_SETTINGS} 2>&1 | tee log.make

  # move executables to the designated location (HOMEdir/exec) only when 
  # both --build and --move are not set (no additional arguments) or
  # both --build and --move are set in the build command line
  if [[ "${BUILD}" = false && "${MOVE}" = false ]] || 
     [[ "${BUILD}" = true && "${MOVE}" = true ]]; then
    printf "... Moving pre-compiled executables to designated location ...\n"
    mkdir -p ${HOME_DIR}/${BIN_DIR}
    cd "${INSTALL_DIR}/bin"
    # copy executables in build/bin to BIN_DIR
    for file in *; do
      [ -x "${file}" ] && cp "${file}" "${HOME_DIR}/${BIN_DIR}"
    done
    # copy libraries
    cp -r ${BUILD_DIR}/lib ${HOME_DIR}
    cp -r ${BUILD_DIR}/lib64 ${HOME_DIR}
    # copy ufs_model to BIN_DIR
    cp ${BUILD_DIR}/ufs_model.fd/src/ufs_model.fd-build/ufs_model ${HOME_DIR}/${BIN_DIR}
  fi
fi

# Link land-DA input files to FIXlandda directory
if [ "${PLATFORM}" = "hera" ]; then
  landda_fix_orig="/scratch2/NAGAPE/epic/UFS_Land-DA_Dev/inputs"
elif [ "${PLATFORM}" = "orion" ] || [ "${PLATFORM}" = "hercules" ]; then
  landda_fix_orig="/work/noaa/epic/UFS_Land-DA_Dev/inputs"
fi
ln -nsf ${landda_fix_orig}/* ${HOME_DIR}/fix

exit 0
