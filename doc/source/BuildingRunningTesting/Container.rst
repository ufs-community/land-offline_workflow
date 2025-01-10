.. _Container:

**********************************
Containerized Land DA Workflow
**********************************

These instructions will help users build and run a basic case for the Unified Forecast System (:term:`UFS`) Land Data Assimilation (DA) System using a `Singularity/Apptainer <https://apptainer.org/docs/user/latest/>`_ container. The Land DA :term:`container` packages together the Land DA System with its dependencies (e.g., :term:`spack-stack`, :term:`JEDI`) and provides a uniform environment in which to build and run the Land DA System. Normally, the details of building and running Earth system models will vary based on the computing platform because there are many possible combinations of operating systems, compilers, :term:`MPIs <MPI>`, and package versions available. Installation via Singularity/Apptainer container reduces this variability and allows for a smoother experience building and running Land DA. This approach is recommended for users not running Land DA on a supported :ref:`Level 1 <LevelsOfSupport>` system (e.g., Hera, Orion). 

This chapter provides instructions for building and running the Unified Forecast System (:term:`UFS`) Land DA System sample case using a container. The sample case runs for Jan. 3-4, 2000 00z and uses :term:`GSWP3` data with the UFS Noah-MP land component and data atmosphere (:term:`DATM`) component.

.. attention::

   This chapter of the User's Guide should **only** be used for container builds. For non-container builds, see :numref:`Chapter %s <BuildRunLandDA>`, which describes the steps for building and running Land DA on a :ref:`Level 1 System <LevelsOfSupport>` **without** a container. 

.. _Prereqs:

Prerequisites 
*****************

The containerized version of Land DA requires: 

   * `Installation of Apptainer <https://apptainer.org/docs/admin/latest/installation.html>`_ (or its predecessor, Singularity)
   * At least 26 CPU cores (may be possible to run with 13, but this has not been tested)
   * An **Intel** compiler and :term:`MPI` (available for `free here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`_) 
   * The `Slurm <https://slurm.schedmd.com/quickstart.html>`_ job scheduler


Install Apptainer
==================

.. note::

   As of November 2021, the Linux-supported version of Singularity has been `renamed <https://apptainer.org/news/community-announcement-20211130/>`_ to *Apptainer*. Apptainer has maintained compatibility with Singularity, so ``singularity`` commands should work with either Singularity or Apptainer (see `compatibility details here <https://apptainer.org/docs/user/1.2/introduction.html>`_.)

To build and run Land DA using a Apptainer container, first install the software according to the `Apptainer Installation Guide <https://apptainer.org/docs/admin/1.2/installation.html>`_. This will include the installation of all dependencies. 

.. attention:: 
   Docker containers can only be run with root privileges, and users generally do not have root privileges on :term:`HPCs <HPC>`. However, an Apptainer image may be built directly from a Docker image for use on the system.

.. _DownloadContainer:

Build the Container
**********************

.. _CloudHPC:

Set Environment Variables
=============================

For users working on systems with limited disk space in their ``/home`` directory, it is important to set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. For example:

.. code-block:: 

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

where ``/absolute/path/to/writable/directory/`` refers to a writable directory (usually a project or user directory within ``/lustre``, ``/work``, ``/scratch``, or ``/glade`` on NOAA :term:`RDHPCS` systems). If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. 

On NOAA Cloud systems, the ``sudo su`` command may also be required. For example, users would run:
   
.. code-block:: 

   mkdir /lustre/cache
   mkdir /lustre/tmp
   sudo su
   export SINGULARITY_CACHEDIR=/lustre/cache
   export SINGULARITY_TMPDIR=/lustre/tmp
   exit

.. note:: 
   ``/lustre`` is a fast but non-persistent file system used on NOAA Cloud systems. To retain work completed in this directory, `tar the files <https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/>`_ and move them to the ``/contrib`` directory, which is much slower but persistent.

.. _ContainerBuild:

Build the Container
======================

Set a top-level directory location for Land DA work, and navigate to it. For example:

.. code-block:: console 

   mkdir /path/to/landda
   cd /path/to/landda
   export LANDDAROOT=`pwd`

where ``/path/to/landda`` is the path to this top-level directory (e.g., ``/Users/Joe.Schmoe/landda``). 

.. hint::
   If a ``singularity: command not found`` error message appears in any of the following steps, try running: ``module load singularity`` or (on Derecho) ``module load apptainer``.

NOAA RDHPCS Systems
----------------------

On many NOAA :term:`RDHPCS`, a container named ``ubuntu22.04-intel-landda-release-public-v2.0.0.img`` has already been built, and users may access the container at the locations in :numref:`Table %s <PreBuiltContainers>`.

.. _PreBuiltContainers:

.. table:: Locations of Pre-Built Containers

   +-----------------+--------------------------------------------------------+
   | Machine         | File location                                          |
   +=================+========================================================+
   | Gaea            | /gpfs/f5/epic/world-shared/containers                  |
   +-----------------+--------------------------------------------------------+
   | Hera            | /scratch1/NCEPDEV/nems/role.epic/containers            |
   +-----------------+--------------------------------------------------------+
   | Jet             | /mnt/lfs5/HFIP/hfv3gfs/role.epic/containers            |
   +-----------------+--------------------------------------------------------+
   | NOAA Cloud      | /contrib/EPIC/containers                               |
   +-----------------+--------------------------------------------------------+
   | Orion/Hercules  | /work/noaa/epic/role-epic/contrib/containers           |
   +-----------------+--------------------------------------------------------+

Users can simply set an environment variable to point to the container: 

.. code-block:: console

   export img=path/to/ubuntu22.04-intel-landda-release-public-v2.0.0.img

If users prefer, they may copy the container to their local working directory. For example, on Jet:

.. code-block:: console

   cp /mnt/lfs5/HFIP/hfv3gfs/role.epic/containers/ubuntu22.04-intel-landda-release-public-v2.0.0.img .

Other Systems
----------------

On other systems, users can build the Singularity container from a public Docker :term:`container` image or download the ``ubuntu22.04-intel-landda-release-public-v2.0.0.img`` container from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. Downloading may be faster depending on the download speed on the user's system. 

To download from the data bucket, users can run:

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v2.0.0/ubuntu22.04-intel-landda-release-public-v2.0.0.img

To build the container from a Docker image, users can run:

.. code-block:: console

   singularity build --force ubuntu22.04-intel-landda-release-public-v2.0.0.img docker://noaaepic/ubuntu22.04-intel21.10-landda:ue160-fms2024.01-release

This process may take several hours depending on the system. 

.. note:: 

   Some users may need to issue the ``singularity build`` command with ``sudo`` (i.e., ``sudo singularity build...``). Whether ``sudo`` is required is system-dependent. If ``sudo`` is required (or desired) for building the container, users should set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables with ``sudo su``, as in the NOAA Cloud example from :numref:`Section %s <CloudHPC>` above.

.. _GetDataC:

Get Data
***********

In order to run the Land DA System, users will need input data in the form of fix files, model forcing files, restart files, and observations for data assimilation. These files are already present on Level 1 systems (see :numref:`Section %s <Level1Data>` for details). 

Users on any system may download and untar the data from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`__ into their ``$LANDDAROOT`` directory. 

.. code-block:: console

   cd $LANDDAROOT
   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v2.0.0/LandDAInputDatav2.0.0.tar.gz
   tar xvfz LandDAInputDatav2.0.0.tar.gz

If users choose to add data in a location other than ``$LANDDAROOT``, they can set the input data directory by running:

.. code-block:: console

   export LANDDA_INPUTS=/path/to/inputs

where ``/path/to`` is replaced by the absolute path to the location of their Land DA input data. 

.. _RunContainer:

Run the Container
********************

To run the container, users must:

   #. :ref:`Set up the container <SetUpContainerC>`
   #. :ref:`Configure the experiment <ConfigureExptC>`
   #. :ref:`Run the experiment <RunExptC>`

.. _SetUpContainerC:

Set Up the Container
=======================

Save the location of the container in an environment variable.

.. code-block:: console

   export img=/path/to/ubuntu22.04-intel-landda-release-public-v2.0.0.img

Users may convert a container ``.img`` file to a writable sandbox. This step is optional on most systems:

.. code-block:: console

   singularity build --sandbox ubuntu22.04-intel-landda-release-public-v2.0.0 $img

When making a writable sandbox on NOAA :term:`RDHPCS`, the following warnings commonly appear and can be ignored:

.. code-block:: console

   INFO:    Starting build...
   INFO:    Verifying bootstrap image ubuntu22.04-intel-landda-release-public-v2.0.0.img
   WARNING: integrity: signature not found for object group 1
   WARNING: Bootstrap image could not be verified, but build will continue.

From within the ``$LANDDAROOT`` directory, copy the ``setup_container.sh`` script out of the container. 

.. code-block:: console

   singularity exec -H $PWD $img cp -r /opt/land-DA_workflow/setup_container.sh .

The ``setup_container.sh`` script should now be in the ``$LANDDAROOT`` directory. If for some reason, the previous command was unsuccessful, users may try a version of the following command instead: 

.. code-block:: console

   singularity exec -B /<local_base_dir>:/<container_dir> $img cp -r /opt/land-DA_workflow/setup_container.sh .

where ``<local_base_dir>`` and ``<container_dir>`` are replaced with a top-level directory on the local system and in the container, respectively. Additional directories can be bound by adding another ``-B /<local_base_dir>:/<container_dir>`` argument before the container location (``$img``). Note that if previous steps included a ``sudo`` command, ``sudo`` may be required in front of this command. 

.. note::

   Sometimes binding directories with different names can cause problems. In general, it is recommended that the local base directory and the container directory have the same name. For example, if the host system's top-level directory is ``/user1234``, the user may want to convert the ``.img`` file to a writable sandbox and create a ``user1234`` directory in the sandbox to bind to. 

Run the ``setup_container.sh`` script with the proper arguments. Ensure ``LANDDA_INPUTS`` variable is set before running this script.

.. code-block:: console

   ./setup_container.sh -c=<compiler> -m=<mpi_implementation> -i=$img

where:

   * ``-c`` is the compiler on the user's local machine (e.g., ``intel/2022.1.2``, ``intel-oneapi-compilers/2022.2.1``, ``intel/2023.2.0``)
   * ``-m`` is the :term:`MPI` on the user's local machine (e.g., ``impi/2022.1.2``, ``intel-oneapi-mpi/2021.7.1``, ``cray-mpich/8.1.28``)
   * ``-i`` is the full path to the container image ( e.g., ``$LANDDAROOT/ubuntu22.04-intel-landda-release-public-v2.0.0.img``).
   
When using a Singularity container, Intel compilers and Intel :term:`MPI` (preferably 2020 versions or newer) need to be available on the host system to properly launch MPI jobs. Generally, this is accomplished by loading a module with a recent Intel compiler and then loading the corresponding Intel MPI. 

.. _ConfigureExptC:

Configure the Experiment
===========================

The user should now see the ``Land-DA_workflow`` and ``jedi-bundle`` directories in the ``$LANDDAROOT`` directory. 

Because of a conda conflict between the container and the host system, it is best to load rocoto separately instead of using workflow files found in the ``modulefiles`` directory. 

.. note::

   Some modules need to be loaded or a path appended before loading rocoto.

   For Hercules/Orion, add the contrib module before loading rocoto by:

   .. code-block:: console

      module load contrib

   For Gaea, source the following path before loading rocoto by: 

   .. code-block:: console

      module use /ncrc/proj/epic/rocoto/modulefiles/

.. code-block:: console

   module load rocoto
   
The ``setup_container.sh`` script creates the ``parm_xml.yaml`` from the ``parm_xml_singularity.yaml`` file. Update any relevant variables in this file (e.g., ``account`` or ``exp_basedir``) before creating the Rocoto XML file.

.. code-block:: console

   cd $LANDDAROOT/land-DA_workflow/parm
   vi parm_xml.yaml

Save and close the file.

Once everything looks good, run the `uwtools <https://github.com/ufs-community/uwtools>`_ scripts to create the Rocoto XML file:

.. code-block:: console

   ../sorc/conda/envs/land_da/bin/uw template render --input-file templates/template.land_analysis.yaml --values-file parm_xml.yaml --output-file land_analysis.yaml
   ../sorc/conda/envs/land_da/bin/uw rocoto realize --input-file land_analysis.yaml --output-file land_analysis.xml

A successful run of these commands will output a “0 errors found” message.

.. note:: 

   To run the container on Gaea, the SLURM options in the ``land_analysis.xml`` needs to be modified by running the following command before starting the experiment: 

   .. code-block:: console

      sed -i 's|<queue>batch</queue>|<native> --clusters=c5 --partition=batch --export=NONE</native>|g' land_analysis.xml

.. _RunExptC:

Run the Experiment
=====================

To start the experiment, run: 

.. code-block:: console
   
   rocotorun -w land_analysis.xml -d land_analysis.db

Users will need to issue the ``rocotorun`` command multiple times. The tasks must be run in order, and ``rocotorun`` initiates the next task once its dependencies have completed successfully. 

See the :ref:`Workflow Overview <wflow-overview>` section to learn more about the steps in the workflow process.

.. _TrackProgress:

Track Progress
----------------

To check on the job status, users on a system with a Slurm job scheduler may run: 

.. code-block:: console

   squeue -u $USER

To view the experiment status, run:

.. code-block:: console

   rocotostat -w land_analysis.xml -d land_analysis.db

See the :ref:`Track Experiment Status <VerifySuccess>` section to learn more about the ``rocotostat`` output.

.. _CheckExptOutput:

Check Experiment Output
-------------------------

Since this experiment in the container is the same experiment explained in the previous document section, it is suggested that users view the :ref:`experiment output structure <land-da-dir-structure>` and :ref:`plotting results <plotting>` sections to learn more about the expected experiment output. 

