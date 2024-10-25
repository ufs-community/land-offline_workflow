.. role:: raw-html(raw)
    :format: html

.. _TechOverview:

*********************
Technical Overview
*********************

.. _prerequisites:

Prerequisites
***************

Minimum System Requirements
==============================

:term:`UFS` applications, models, and components require a UNIX-based operating system (i.e., Linux or MacOS). 

Additionally, users will need:

   * Disk space: ~24GB (11GB for Land DA System [or 6.5GB for Land DA container], 12GB for Land DA data, and ~1GB for staging and output) 
   * 26 CPU cores (13 CPUs may be possible, but it has not been tested)

Software Prerequisites
========================

The Land DA System requires:

   * An :term:`MPI` implementation
   * A Fortran compiler
   * Python
   * :term:`NetCDF`
   * Lmod 
   * `spack-stack <https://github.com/JCSDA/spack-stack>`_ (|spack-stack-ver|)
   * `jedi-bundle <https://github.com/JCSDA/jedi-bundle>`_ (|skylabv|)

These software prerequisites are pre-installed in the Land DA :term:`container` and on other Level 1 systems (see :ref:`below <LevelsOfSupport>` for details). However, users on non-Level 1 systems will need to install them.

Before using the Land DA container, users will need to install `Singularity/Apptainer <https://apptainer.org/docs/admin/1.2/installation.html>`_ and an **Intel** MPI (available `free here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`_). 


.. _LevelsOfSupport:

Supported Systems for Running Land DA
****************************************

Four levels of support have been defined for :term:`UFS` applications, and the Land DA System operates under this paradigm: 

* **Level 1** *(Preconfigured)*: Prerequisite software libraries are pre-built and available in a central location; code builds; full testing of model.
* **Level 2** *(Configurable)*: Prerequisite libraries are not available in a centralized location but are expected to install successfully; code builds; full testing of model.
* **Level 3** *(Limited-test platforms)*: Libraries and code build on these systems, but there is limited testing of the model.
* **Level 4** *(Build-only platforms)*: Libraries and code build, but running the model is not tested.

Level 1 Systems
==================
Preconfigured (Level 1) systems for Land DA already have the required external libraries available in a central location via :term:`spack-stack` and the :term:`jedi-bundle` (|skylabv|). Land DA is expected to build and run out-of-the-box on these systems, and users can download the Land DA code without first installing prerequisite software. With the exception of the Land DA container, users must have access to these Level 1 systems in order to use them. For the most updated information on stack locations, compilers, and MPI, users can check the :land-wflow-repo:`build and run version files <tree/develop/versions>` for their machine of choice. 

.. _stack-compiler-locations:

.. list-table:: *Software Prerequisites & Locations*
   :header-rows: 1
   :widths: 10 20 20 100 70

   * - Platform
     - Compiler
     - MPI
     - *spack-stack* Installation
     - *jedi-bundle* Installation
   * - Hera
     - intel/2021.5.0
     - impi/2021.5.1
     - /scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.6.0/envs/fms-2024.01/install/modulefiles/Core
     - /scratch2/NAGAPE/epic/UFS_Land-DA_Dev/jedi_v7
   * - Orion
     - intel/2021.9.0
     - impi/2021.9.0
     - /work/noaa/epic/role-epic/spack-stack/orion/spack-stack-1.6.0/envs/fms-2024.01/install/modulefiles/Core
     - /work/noaa/epic/UFS_Land-DA_Dev/jedi_v7_stack1.6
   * - Hercules
     - intel/2021.9.0
     - impi/2021.9.0
     - /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.6.0/envs/fms-2024.01/install/modulefiles/Core
     - /work/noaa/epic/UFS_Land-DA_Dev/jedi_v7_hercules
   * - Container
     - intel-oneapi-compilers/2021.10.0
     - intel-oneapi-mpi/2021.9.0
     - /opt/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core (inside the container)
     - /opt/jedi-bundle (inside the container)

Level 2-4 Systems
===================

On non-Level 1 platforms, the Land DA System can be run within a container that includes the prerequisite software; otherwise, the required libraries will need to be installed as part of the Land DA build process. Once these prerequisite libraries are installed, Land DA should build and run successfully. However, users may need to perform additional troubleshooting on Level 3 or 4 systems since little or no pre-release testing has been conducted on these systems.

.. _repos-dir-structure:

Code Repositories and Directory Structure
********************************************

.. _components:

Hierarchical Repository Structure
===================================

The main repository for the Land DA System is named ``land-DA_workflow``; 
it is available on GitHub at https://github.com/ufs-community/land-DA_workflow. 
This :term:`umbrella repository` uses Git submodules and an ``app_build.sh`` file to pull in code from the appropriate versions of external repositories associated with the Land DA System. :numref:`Table %s <LandDAComponents>` describes the various subrepositories that form the UFS Land DA System. 

.. _LandDAComponents:

.. list-table:: UFS Land DA System Components
   :header-rows: 1

   * - Land DA Submodule Name
     - Repository Name
     - Repository Description
     - Authoritative Repository URL
   * - apply_incr.fd
     - land-apply_jedi_incr
     - Contains code that applies the JEDI-generated DA increment to UFS ``sfc_data`` restart 
     - https://github.com/NOAA-PSL/land-apply_jedi_incr
   * - ufs_model.fd
     - ufs-weather-model
     - Repository for the UFS Weather Model (WM). This repository contains a number of subrepositories, which are documented :ufs-wm:`in the WM User's <CodeOverview.html>`.
     - https://github.com/ufs-community/ufs-weather-model/

.. note::
   The prerequisite libraries (including NCEP Libraries and external libraries) are not included in the UFS Land DA System repository. The `spack-stack <https://github.com/JCSDA/spack-stack>`_ repository assembles these prerequisite libraries. Spack-stack has already been built on :ref:`preconfigured (Level 1) platforms <LevelsOfSupport>`. However, it must be built on other systems. See the :spack-stack:`spack-stack Documentation <>` for details on installing spack-stack. 

.. _file-dir-structure:

File & Directory Structure
============================

The ``land-DA_workflow`` is evolving to follow the :term:`NCEP` Central Operations (NCO) :nco:`WCOSS Implementation Standards <ImplementationStandards.v11.0.0.pdf>`. When the ``land-DA_workflow`` repository is cloned with the ``--recursive`` argument, the specific GitHub repositories described in ``/sorc/app_build.sh`` are cloned into ``sorc``. The diagram below illustrates the file and directory structure of the Land DA System. Directories in parentheses () are only visible after the build step. Some files and directories have been removed for brevity. 

.. code-block:: console

   land-offline_workflow
    ├── doc
    ├── (exec)
    ├── fix
    ├── jobs
    ├── (lib*)
    ├── modulefiles
    ├── parm
    │     ├── jedi
    │     ├── templates
    │     │     └── template.land_analysis.yaml
    │     ├── check_release_outputs.sh
    │     ├── detect_platform.sh
    │     ├── parm_xml_<platform>.yaml
    │     └── launch_rocoto_wflow.sh
    ├── scripts
    ├── sorc
    |     ├── apply_incr.fd
    |     |     └── sorc
    |     |           ├── apply_incr_noahmp_snow.f90
    |     |           └── NoahMPdisag_module.f90
    │     ├── (build)
    │     ├── cmake
    │     ├── (conda)
    |     |     └── envs
    |     |           └── land_da 
    │     ├── test
    │     │     ├── <platform>_ctest.sh
    │     │     └── run_<platform>_ctest.sh
    │     ├── tile2tile_converter.fd
    │     ├── ufs_model.fd
    │     ├── CMakeLists.txt
    │     └── app_build.sh
    ├── ush
    |     ├── fill_jinja_template.py
    |     ├── hofx_analysis_stats.py
    |     ├── letkf_create_ens.py
    |     └── plot_forecast_restart.py
    ├── versions
    ├── LICENSE
    └── README.md

:numref:`Table %s <Subdirectories>` describes the contents of the most important Land DA subdirectories. :numref:`Section %s <components>` describes the Land DA System components. Users may reference the :nco:`NCO Implementation Standards <ImplementationStandards.v11.0.0.pdf>` (p. 19) for additional details on repository structure in NCO-compliant repositories. 

.. _Subdirectories:

.. list-table:: *Subdirectories of the land-DA_workflow repository*
   :widths: 20 50
   :header-rows: 1

   * - Directory Name
     - Description
   * - doc
     - Repository documentation
   * - exec
     - Binary executables
   * - fix
     - Location of fix/static files 
   * - jobs
     - :term:`J-job <J-jobs>` scripts launched by Rocoto
   * - lib
     - Model-specific libraries
   * - modulefiles
     - Files that load the modules required for building and running the workflow
   * - parm
     - Parameter files used to configure the model, physics, workflow, and various components
   * - scripts
     - Scripts launched by the :term:`J-jobs`
   * - sorc
     - External source code used to build the Land DA System
   * - ush
     - Utility scripts
   * - versions
     - Contains ``build.ver_*`` and ``run.ver_*``, which are files that get automatically sourced in order to track package versions at compile and run time respectively.

.. _land-component:

The UFS Land Component
=========================

The UFS Land DA System has been updated to build and run the UFS Noah-MP land component. The land component makes use of a National Unified Operational Prediction Capability (:term:`NUOPC`) cap to interface with a coupled modeling system. 
Unlike the standalone Noah-MP land driver, the Noah-MP :term:`NUOPC cap` is able to create an :term:`ESMF` multi-tile grid by reading in a mosaic grid file. For the domain, the :term:`FMS` initializes reading and writing of the cubed-sphere tiled output. Then, the Noah-MP land component reads static information and initial conditions (e.g., surface albedo) and interpolates the data to the date of the simulation. The solar zenith angle is calculated based on the time information. 

Unified Workflow (UW) Tools
============================
The Unified Workflow (UW) is a set of tools intended to unify the workflow for various UFS applications under one framework. The UW toolkit includes rocoto, template, and configuration (config) tools, and additional tools and drivers are under development. The Land DA workflow makes use of the rocoto tool to generate a workflow XML file; other UW tools may be incorporated into the workflow in the future. More details about UW tools can be found in the `uwtools <https://github.com/ufs-community/uwtools>`_ GitHub repository and in the :uw:`UW Documentation <>`.