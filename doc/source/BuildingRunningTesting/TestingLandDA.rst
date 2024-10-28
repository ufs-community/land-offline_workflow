.. _TestingLandDA:

************************************
Testing the Land DA Workflow
************************************

This chapter provides instructions for using the Land DA CTest suite. These steps are designed for use on :ref:`Level 1 <LevelsOfSupport>` systems (e.g., Hera and Orion) and may require significant changes on other systems. 

.. COMMENT: Will they work with the container?

.. attention:: 

   This chapter assumes that the user has already built the Land DA System according to the instructions in :numref:`Section %s <BuildRunLandDA>` and has access to the data provided in the most recent release. (See :numref:`Table %s <Level1Data>` for the locations of pre-staged data on NOAA :term:`RDHPCS`.)

Process
*********

Method #1: Run from the ``build`` Directory
============================================

From the working directory (``$LANDDAROOT``), navigate to ``build`` and run: 

.. code-block:: console
   
   cd land-DA_workflow/sorc/build
   salloc --ntasks 8 --exclusive --qos=debug --partition=<partition> --time=00:30:00 --account=<account_name>
   source ../../versions/build.ver_<platform>
   module use ../../modulefiles
   module load build_<platform>_intel 
   ctest

where ``<account_name>`` corresponds to the user's actual account name, ``<partition>`` is a valid partition on the platform of choice (e.g., ``debug`` or ``orion``), and ``<platform>`` is ``hera``, ``orion``, or ``hercules``.

This will submit an interactive job, load the appropriate modulefiles, and run the CTests. 

If the tests are successful, a message will be printed to the console. For example:

.. code-block:: console

   Test project /work/noaa/epic/${USER}/landda/land-DA_workflow/sorc/build
       Start 1: test_create_ens
   1/4 Test #1: test_create_ens ..................   Passed   13.91 sec
       Start 2: test_letkfoi_snowda
   2/4 Test #2: test_letkfoi_snowda ..............   Passed   67.94 sec
       Start 3: test_apply_jediincr
   3/4 Test #3: test_apply_jediincr ..............   Passed    6.88 sec
       Start 4: test_ufs_datm_land
   4/4 Test #4: test_ufs_datm_land ...............   Passed   98.56 sec

   100% tests passed, 0 tests failed out of 4

   Total Test time (real) = 187.29 sec

Method #2: Run from the ``test`` Directory
============================================

.. note:: 

   This method works only on Hera, Orion, and Hercules and will run even if the Land DA System has not been built yet. 

From the working directory (``$LANDDAROOT``), navigate to ``test`` and run: 

.. code-block:: console
   
   cd land-DA_workflow/sorc/test
   ./run_ctest_platform.sh

The CTest working directory will appear in ``build/test``, and the log file can be found in ``build/Testing/Temporary``.

Tests
*******

The CTests test the operability of four major elements of the Land DA System: ``create_ens``, ``letkfoi_snowda``, ``apply_jediincr``, and ``ufs_datm_land``. The tests and their dependencies are listed in the ``land-DA_workflow/test/CMakeLists.txt`` file. Currently, the CTests are only run on Hera, Orion, and Hercules; they cannot yet be run via container. 

.. COMMENT: Is this still true?

.. list-table:: *Land DA CTests*
   :widths: 20 50
   :header-rows: 1

   * - Test
     - Description
   * - ``test_create_ens``
     - Tests creation of a pseudo-ensemble for use in :term:`LETKF-OI`.
   * - ``test_letkfoi_snowda``
     - Tests the use of LETKF-OI to assimilate snow data. 
   * - ``test_apply_jediincr``
     - Tests the ability to add a JEDI increment.
   * - ``test_ufs_datm_land``
     - Tests proper functioning of the UFS land model (``ufs-datm-lnd``)

.. note::

   There are plans to add workflow end-to-end (WE2E) tests to the Land DA System. Currently, when ``TEST: "YES"``, this functionality checks that the output from the Jan. 3-4, 2000 sample case is within the tolerance set (via the ``WE2E_ATOL`` variable) at the end of the three main tasks --- *analysis*, *forecast*, and *post_anal*. The results are logged by default in ``we2e.log``. In the future, this functionality will be expanded to encompass a full range of WE2E tests. 

