.. _BuildRunLandDA:

***************************************
Land DA Workflow (Hera/Orion/Hercules)
***************************************

This chapter provides instructions for building and running the Unified Forecast System (:term:`UFS`) Land DA System using a Jan. 3-4, 2000 00z sample case using :term:`GSWP3` data with the UFS Noah-MP land component and data atmosphere (DATM) component.

.. attention::
   
   These steps are designed for use on :ref:`Level 1 <LevelsOfSupport>` systems (e.g., Hera, Orion) and may require significant changes on other systems. It is recommended that users on other systems run the containerized version of Land DA. Users may reference :numref:`Chapter %s: Containerized Land DA Workflow <Container>` for instructions.

.. _create-dir:

Create a Working Directory
*****************************

Users can either create a new directory for their Land DA work or choose an existing directory, depending on preference. Then, users should navigate to this directory. For example, to create a new directory and navigate to it, run: 

.. code-block:: console

   mkdir /path/to/landda
   cd /path/to/landda

where ``/path/to/landda`` is the path to the directory where the user plans to run Land DA experiments. In the experiment configuration file, this directory is referred to as ``$EXP_BASEDIR``. 

Optionally, users can save this directory path in an environment variable (e.g., ``$LANDDAROOT``) to avoid typing out full path names later. 

.. code-block:: console

   export LANDDAROOT=`pwd`

In this documentation, ``$LANDDAROOT`` is used, but users are welcome to choose another name for this variable if they prefer. 

.. _GetCode:

Get Code
***********

Clone the Land DA workflow repository. To clone the most recent release, run: 

.. code-block:: console

   git clone -b release/public-v2.0.0 --recursive https://github.com/ufs-community/land-DA_workflow.git

To clone the ``develop`` branch, run the same command with ``develop`` in place of |branch|: 

.. code-block:: console

   git clone -b develop --recursive https://github.com/ufs-community/land-DA_workflow.git

.. _build-land-da:

Build the Land DA System
***************************

#. Navigate to the ``sorc`` directory.

   .. code-block:: console

      cd $LANDDAROOT/land-DA_workflow/sorc

#. Run the build script ``app_build.sh``:

   .. code-block:: console

      ./app_build.sh

   Users may need to press the ``Enter`` key to advance the build once the list of currently loaded modules appears. 
   If the code successfully compiles, the console output should end with:
   
   .. code-block:: console

      [100%] Completed 'ufs_model.fd'
      [100%] Built target ufs_model.fd
      ... Moving pre-compiled executables to designated location ...
   
   Additionally, the ``exec`` directory will contain the following executables: 

      * ``apply_incr.exe``
      * ``tile2tile_converter.exe``
      * ``ufs_model``

.. _config-wflow:

Configure an Experiment
*************************

.. _load-env:

Load the Workflow Environment
===============================

To load the workflow environment, run: 

.. include:: ../doc-snippets/load-env.rst

This activates the ``land_da`` conda environment, and the user typically sees ``(land_da)`` in front of the Terminal prompt at this point.

.. _configure-expt:

Modify the Workflow Configuration YAML
========================================

Copy the experiment settings into ``land_analysis.yaml``:

.. code-block:: console

   cd $LANDDAROOT/land-DA_workflow/parm
   cp parm_xml_<platform>.yaml parm_xml.yaml

where ``<platform>`` is ``hera``, ``orion``, or ``hercules``.
   
Users will need to configure the ``account`` and ``exp_basedir`` variables in ``parm_xml.yaml``: 

   * ``account:`` A valid account name. Hera, Orion, Hercules, and most NOAA :term:`RDHPCS` systems require a valid account name; other systems may not (in which case, any value will do).
   * ``exp_basedir:`` The full path to the directory where ``land-DA_workflow`` was cloned (i.e., ``$LANDDAROOT``). For example, if ``land-DA_workflow`` is located at ``/scratch2/NAGAPE/epic/User.Name/landda/land-DA_workflow`` on Hera, set ``exp_basedir`` to its parent directory: ``/scratch2/NAGAPE/epic/User.Name/landda``. 

.. note::

   To determine an appropriate ``account`` field for Level 1 systems that use the Slurm job scheduler, run ``saccount_params``. On other systems, running ``groups`` will return a list of projects that the user has permissions for. Not all listed projects/groups have an HPC allocation, but those that do are potentially valid account names. 

Users may configure other elements of an experiment in ``parm/templates/template.land_analysis.yaml`` if desired. For example, users may wish to alter the ``cycledef.spec`` to indicate a different start cycle, end cycle, and increment. The ``template.land_analysis.yaml`` files contain reasonable default values for running a Land DA experiment. Users who wish to run a more complex experiment may change the values in this file using information from Sections :numref:`%s: Workflow Configuration Parameters <ConfigWorkflow>`, :numref:`%s: I/O for the Noah-MP Model <Model>`, and :numref:`%s: I/O for JEDI DA <DASystem>`. 

.. _GetData:

Data
------

:numref:`Table %s <Level1Data>` shows the locations of pre-staged data on NOAA :term:`RDHPCS` (e.g., Hera, Orion). These data locations are already linked to the Land DA System during the build but are provided here for informational purposes. 
   
.. _Level1Data:

.. list-table:: Level 1 RDHPCS Data
   :header-rows: 1

   * - Platform
     - Data Location
   * - Hera
     - /scratch2/NAGAPE/epic/UFS_Land-DA_Dev/inputs
   * - Hercules & Orion
     - /work/noaa/epic/UFS_Land-DA_Dev/inputs

Users who have difficulty accessing the data on Hera, Orion, or Hercules may download it according to the instructions in :numref:`Section %s <GetDataC>`. Its subdirectories are soft-linked to the ``land-DA_workflow/fix`` directory by the build script (``sorc/app_build.sh``); when downloading new data, it should be placed in or linked to the ``fix`` directory.

.. _generate-wflow:

Generate the Rocoto XML File
==============================

Generate the workflow XML file with ``uwtools`` by running: 

.. code-block:: console

   uw template render --input-file templates/template.land_analysis.yaml --values-file parm_xml.yaml --output-file land_analysis.yaml
   uw rocoto realize --input-file land_analysis.yaml --output-file land_analysis.xml

If the commands run without issue, ``uwtools`` will output a "0 errors found" message similar to the following: 

.. code-block:: console

   [2024-03-01T20:36:03]     INFO 0 UW schema-validation errors found
   [2024-03-01T20:36:03]     INFO 0 Rocoto validation errors found

The generated workflow XML file (``land_analysis.xml``) will be used by the Rocoto workflow manager to determine which tasks (or "jobs") to submit to the batch system and when to submit them (e.g., when task dependencies are satisfied). 

Run the Experiment
********************

.. _wflow-overview:

Workflow Overview
==================

Each Land DA experiment includes multiple tasks that must be run in order to satisfy the dependencies of later tasks. These tasks are housed in the :term:`J-job <j-jobs>` scripts contained in the ``jobs`` directory. 

.. _WorkflowTasksTable:

.. list-table:: *J-job Tasks in the Land DA Workflow*
   :header-rows: 1

   * - J-job Task
     - Description
   * - JLANDDA_PREP_OBS
     - Sets up the observation data files
   * - JLANDDA_PRE_ANAL
     - Transfers the snow data from the restart files to the surface data files
   * - JLANDDA_ANALYSIS
     - Runs :term:`JEDI` and adds the increment to the surface data files
   * - JLANDDA_POST_ANAL
     - Transfers the JEDI result from the surface data files to the restart files
   * - JLANDDA_FORECAST
     - Runs the forecast model
   * - JLANDDA_PLOT_STATS
     - Plots the JEDI result (scatter/histogram) and the restart files

Users may run these tasks :ref:`using the Rocoto workflow manager <run-w-rocoto>`. 

.. _run-w-rocoto:

Run With Rocoto
=================

To run the experiment, users can automate job submission via :term:`crontab` or submit tasks manually via ``rocotorun``. 

Automated Run
---------------

To automate task submission, users must be on a system where :term:`cron` is available. On Orion, cron is only available on the orion-login-1 node, and likewise on Hercules, it is only available on hercules-login-1, so users will need to work on those nodes when running cron jobs on Orion/Hercules.

.. code-block:: console

   cd parm
   ./launch_rocoto_wflow.sh add

To check the status of the experiment, see :numref:`Section %s <VerifySuccess>` on tracking experiment progress.

.. note::

   If users run into issues with the launch script, they can run ``conda deactivate`` before running the launch script. 

Manual Submission
-------------------

To run the experiment, issue a ``rocotorun`` command from the ``parm`` directory: 

.. code-block:: console

   rocotorun -w land_analysis.xml -d land_analysis.db

Users will need to issue the ``rocotorun`` command multiple times. The tasks must be run in order, and ``rocotorun`` initiates the next task once its dependencies have completed successfully. Details on checking experiment status are provided in the :ref:`next section <VerifySuccess>`.

.. _VerifySuccess:

Track Experiment Status
-------------------------

To view the experiment status, run: 

.. code-block:: console

   rocotostat -w land_analysis.xml -d land_analysis.db

If ``rocotorun`` was successful, the ``rocotostat`` command will print a status report to the console. For example:

.. code-block:: console

   CYCLE                TASK                       JOBID        STATE   EXIT STATUS   TRIES   DURATION
   =========================================================================================================
   200001030000     prep_obs                    61746064       QUEUED             -       1        0.0
   200001030000     pre_anal   druby://10.184.3.62:41973   SUBMITTING             -       1        0.0
   200001030000     analysis                           -            -             -       -          -
   200001030000    post_anal                           -            -             -       -          -
   200001030000     forecast                           -            -             -       -          -
   200001030000   plot_stats                           -            -             -       -          -
   =========================================================================================================
   200001040000     prep_obs   druby://10.184.3.62:41973   SUBMITTING             -       1        0.0
   200001040000     pre_anal                           -            -             -       -          -
   200001040000     analysis                           -            -             -       -          -
   200001040000    post_anal                           -            -             -       -          -
   200001040000     forecast                           -            -             -       -          -
   200001040000   plot_stats                           -            -             -       -          -

Note that the status table printed by ``rocotostat`` only updates after each ``rocotorun`` command (whether issued manually or via cron automation). For each task, a log file is generated. These files are stored in ``$LANDDAROOT/ptmp/test/com/output/logs``. 

The experiment has successfully completed when all tasks say SUCCEEDED under STATE. Other potential statuses are: QUEUED, SUBMITTING, RUNNING, and DEAD. Users may view the log files to determine why a task may have failed.

.. _check-output:

Check Experiment Output
=========================

As the experiment progresses, it will generate a number of directories to hold intermediate and output files. The structure of those files and directories appears below:

.. _land-da-dir-structure:

.. code-block:: console

   $LANDDAROOT (<EXP_BASEDIR>): Base directory
    ├── land-DA_workflow (<HOMElandda> or <CYCLEDIR>): Home directory of the land DA workflow
    └── ptmp (<PTMP>)
          └── test (<envir> or <OPSROOT>)
                └── com (<COMROOT>)
                │     ├── landda (<NET>)
                │     │     └── vX.Y.Z (<model_ver>)
                │     │           └── landda.YYYYMMDD (<RUN>.<PDY>): Directory containing the output files
                │     │                 ├── hofx
                │     │                 └── plot
                │     └── output
                │           └── logs (<LOGDIR>): Directory containing the log files for the Rocoto workflow
                └── tmp (<DATAROOT>)
                     ├── <jobid> (<DATA>): Working directory
                     └── DATA_SHARE
                           ├── YYYYMMDD (<PDY>): Directory containing the intermediate or temporary files
                           ├── hofx: Directory containing the soft links to the results of the analysis task for plotting
                           └── DATA_RESTART: Directory containing the soft links to the restart files for the next cycles

Each variable in parentheses and angle brackets (e.g., ``(<VAR>)``) is the name for the directory defined in the file ``land_analysis.yaml`` (derived from ``template.land_analysis.yaml`` or ``parm_xml.yaml``) or in the NCO Implementation Standards. For example, the ``<envir>`` variable is set to "test" (i.e., ``envir: "test"``) in ``template.land_analysis.yaml``. In the future, this directory structure will be further modified to meet the :nco:`NCO Implementation Standards<>`.

Check for the output files for each cycle in the experiment directory:

.. code-block:: console

   ls -l $LANDDAROOT/ptmp/test/com/landda/<model_ver>/landda.YYYYMMDD

where ``YYYYMMDD`` is the cycle date, and ``<model_ver>`` is the model version (currently |latestr| in the ``develop`` branch). The experiment should generate several restart files. 

.. _plotting:

Plotting Results
-----------------

Additionally, in the ``plot`` subdirectory, users will find images depicting the results of the ``analysis`` task for each cycle as a scatter plot (``hofx_oma_YYYYMMDD_scatter.png``) and as a histogram (``hofx_oma_YYYYMMDD_histogram.png``). 

The scatter plot is named OBS-ANA (i.e., Observation Minus Analysis [OMA]), and it depicts a map of snow depth results. Blue points indicate locations where the observed values are less than the analysis values, and red points indicate locations where the observed values are greater than the analysis values. The title lists the mean and standard deviation of the absolute value of the OMA values. 

The histogram plots OMA values on the x-axis and frequency density values on the y-axis. The title of the histogram lists the mean and standard deviation of the real value of the OMA values. 

.. |logo1| image:: https://raw.githubusercontent.com/wiki/ufs-community/land-DA_workflow/images/LandDAScatterPlot.png
   :alt: Map of snow depth in millimeters (observation minus analysis)

.. |logo2| image:: https://raw.githubusercontent.com/wiki/ufs-community/land-DA_workflow/images/LandDAHistogram.png 
   :alt: Histogram of snow depth in millimeters (observation minus analysis) on the x-axis and frequency density on the y-axis

.. _sample-plots:

.. list-table:: Snow Depth Plots for 2000-01-04

   * - |logo1|
     - |logo2|

.. note::

   There are many options for viewing plots, and instructions for this are highly machine dependent. Users should view the data transfer documentation for their system to secure copy files from a remote system (such as :term:`RDHPCS`) to their local system. 
   Another option is to download `Xming <https://sourceforge.net/projects/xming/>`_ (for Windows) or `XQuartz <https://www.xquartz.org/>`_ (for Mac), use the ``-X`` option when connecting to a remote system via SSH, and run:

   .. code-block:: console

      module load imagemagick
      display file_name.png

   where ``file_name.png`` is the name of the file to display/view. Depending on the system, users may need to install imagemagick and/or adjust other settings (e.g., for X11 forwarding). Users should contact their machine administrator with any questions. 
