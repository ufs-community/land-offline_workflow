.. _Intro:

****************
Introduction
****************

This User's Guide provides guidance for running the Unified Forecast System 
(:term:`UFS`) offline Land Data Assimilation (DA) System. Land DA is an offline version of the Noah Multi-Physics (Noah-MP) land surface model (LSM) used in the `UFS Weather Model <https://github.com/ufs-community/ufs-weather-model>`_ (WM). Its data assimilation framework uses 
the Joint Effort for Data assimilation Integration (:term:`JEDI`) software. Currently, the offline UFS Land DA System only works with snow data. 
Thus, this User's Guide focuses primarily on the snow DA process.

The following improvements were made to the Land DA System ahead of the |latestr| release:

* Added cycled run capability (:land-wflow-repo:`PR #101 <pull/101/>`)
* Provided automated run option using cron (:land-wflow-repo:`PR #110 <pull/110>`)
* Incorporated `Unified Workflow Tools <https://github.com/ufs-community/uwtools>`_:

   * Added Rocoto tool to produce the Rocoto workflow XML file from a YAML configuration file (:land-wflow-repo:`PR #47 <pull/47>`)
   * Added template tool to render a configuration file from a template (:land-wflow-repo:`PR #153 <pull/153>`)
* Added plotting options: 

   * Analysis plotting task (:land-wflow-repo:`PR #107 <pull/107>`)
   * Plotting option for forecast task restart files (:land-wflow-repo:`PR #149 <pull/149>`)
   * Time-history plots (:land-wflow-repo:`PR #151 <pull/151>`)
* Extended and updated container support (:land-wflow-repo:`PR #85 <pull/85>` and :land-wflow-repo:`PR #147 <pull/147>`)
* Ported ``land-DA_workflow`` to Hercules (:land-wflow-repo:`PR #133 <pull/133>`)
* Added prerequisites for workflow end-to-end (WE2E) testing capability (:land-wflow-repo:`PR #131 <pull/131>`)
* Upgraded to JEDI Skylab v7.0 (:land-wflow-repo:`PR #92 <pull/92/>`)
* Upgraded to spack-stack v1.6.0 (:land-wflow-repo:`PR #102 <pull/102>`)
* Updated directory structure for NCO compliance (e.g., :land-wflow-repo:`PR #75 <pull/75>`)
* Added platform test to CTest & updated version of UFS WM (:land-wflow-repo:`PR #146 <pull/146>`)
* Removed land driver from CTest (:land-wflow-repo:`PR #123 <pull/123>`)
* Removed land driver and vector2tile (:land-wflow-repo:`PR #129 <pull/129>`)

The Land DA System citation is as follows and should be used when presenting results based on research conducted with the Land DA System:

UFS Development Team. (2024, October 30). Unified Forecast System (UFS) Land Data Assimilation (DA) System (Version v2.0.0). Zenodo. https://doi.org/10.5281/zenodo.13909475

Organization
**************

This User's Guide is organized into four sections: (1) *Background Information*; (2) *Building, Running, and Testing the Land DA System*; (3) *Customizing the Workflow*; and (4) *Reference*.

Background Information
========================
   * This chapter (Introduction) provides user support information and background information on the Unified Forecast System (:term:`UFS`) and the Noah-MP model. 
   * :numref:`Chapter %s <TechOverview>` (Technical Overview) outlines prerequisites, supported systems, and directory structure. 

Building, Running, and Testing the Land DA System
===================================================

   * :numref:`Chapter %s: Land DA Workflow <BuildRunLandDA>` explains how to build and run the Land DA System on :ref:`Level 1 <LevelsOfSupport>` systems (currently Hera, Orion, and Hercules).
   * :numref:`Chapter %s: Containerized Land DA Workflow <Container>` explains how to build and run the containerized Land DA System on non-Level 1 systems. 
   * :numref:`Chapter %s: Testing the Land DA Workflow <TestingLandDA>` explains how to run Land DA System tests. 

Customizing the Workflow
=========================

   * :numref:`Chapter %s: Available Workflow Configuration Parameters <ConfigWorkflow>` explains all of the user-configurable options currently available in the workflow configuration file (``land_analysis*.yaml``).
   * :numref:`Chapter %s: Model <Model>` provides information on input data and configuration parameters in the Noah-MP LSM.
   * :numref:`Chapter %s: DA Framework <DASystem>` provides information on the DA system, required data, and configuration parameters. 

Reference
===========

   * :numref:`Chapter %s: Rocoto <RocotoInfo>` provides background information on the Rocoto workflow manager as used in Land DA.  
   * :numref:`Chapter %s: FAQ <FAQ>` addresses frequently asked questions. 
   * :numref:`Chapter %s: Glossary <Glossary>` lists important terms. 

User Support and Documentation
********************************

Questions
==========

The Land DA System's `GitHub Discussions <https://github.com/ufs-community/land-DA_workflow/discussions/categories/q-a>`_ forum provides online support for UFS users and developers to post questions and exchange information. When users encounter difficulties running the Land DA System, this is the place to post. Users can expect an initial response within two business days. 

When posting a question, it is recommended that users provide the following information: 

* The platform or system being used (e.g., Hera, Orion, container)
* The version of the Land DA System being used (e.g., ``develop``, ``release/public-v1.1.0``). (To determine this, users can run ``git branch``, and the name of the branch with an asterisk ``*`` in front of it is the name of the branch or tag they are working with.) Note that the Land DA version being used and the version of the documentation being used should match, or users will run into difficulties.
* Stage of the application when the issue appeared (i.e., build/compilation, configuration, or forecast run)
* Contents of relevant configuration files
* Full error message (preferably in text form rather than a screenshot)
* Current shell (e.g., bash, csh) and modules loaded
* Compiler + MPI combination being used
* Run directory and code directory, if available on supported platforms

Bug Reports
============

If users (especially new users) believe they have identified a bug in the system, it is recommended that they first ask about the problem in :land-wflow-repo:`GitHub Discussions <discussions/categories/q-a>`, since many "bugs" do not require a code change/fix --- instead, the user may be unfamiliar with the system and/or may have misunderstood some component of the system or the instructions, which is causing the problem. Asking for assistance in a :land-wflow-repo:`GitHub Discussion <discussions/categories/q-a>` post can help clarify whether there is a simple adjustment to fix the problem or whether there is a genuine bug in the code. Users are also encouraged to search :land-wflow-repo:`open issues <issues>` to see if their bug has already been identified. If there is a genuine bug, and there is no open issue to address it, users can report the bug by filing a :land-wflow-repo:`GitHub Issue <issues/new>`. 

Feature Requests and Enhancements
==================================

Users who want to request a feature enhancement or the addition of a new feature have a few options: 

   #. File a `GitHub Issue <https://github.com/ufs-community/land-DA_workflow/issues/new>`_ and add (or request that a code manager add) the ``EPIC Support Requested`` label. 
   #. Post a request for a feature or enhancement in the `Enhancements <https://github.com/ufs-community/land-DA_workflow/discussions/categories/enhancements>`_ category of GitHub Discussions. These feature requests will be forwarded to the Earth Prediction Innovation Center (`EPIC <https://epic.noaa.gov/>`_) management team for prioritization and eventual addition to the Land DA System. 
   #. Email the request to support.epic@noaa.gov. 


.. _Background:

Background Information
************************

Unified Forecast System (UFS)
===============================

The UFS is a community-based, coupled, comprehensive Earth modeling system. It includes :ufs:`multiple applications <applications>` that support different forecast durations and spatial domains. NOAA's operational model suite for numerical weather prediction (:term:`NWP`) is quickly transitioning to the UFS from many different modeling systems. 
The UFS is designed to enable research, development, and contribution
opportunities within the broader :term:`Weather Enterprise` (including
government, industry, and academia). For more information about the UFS, visit the :ufs:`UFS Portal <>`.


.. _NoahMP:

Noah-MP
==========

The offline Noah-MP LSM is a stand-alone, uncoupled model used to execute land surface simulations. In this traditional uncoupled mode, near-surface atmospheric :term:`forcing data` are required as input forcing. This LSM simulates soil moisture (both liquid and frozen), soil temperature, skin temperature, snow depth, snow water equivalent (SWE), snow density, canopy water content, and the energy flux and water flux terms of the surface energy balance and surface water balance.

Noah-MP uses: 

* a big-leaf approach with a separated vegetation canopy accounting for vegetation effects on surface energy and water balances, 
* a modified two-stream approximation scheme to include the effects of vegetation canopy gaps that vary with solar zenith angle and the canopy 3-D structure on radiation transfer, 
* a 3-layer physically-based snow model
* a more permeable frozen soil by separating a grid cell into a permeable fraction and impermeable fraction, 
* a simple groundwater model with a TOPMODEL-based runoff scheme, and 
* a short-term leaf phenology model. 

Noah-MP LSM enables a modular framework for diagnosing differences 
in process representation, facilitating ensemble forecasts and uncertainty 
quantification, and choosing process presentations appropriate for the application. 
Noah-MP developers designed multiple parameterization options for leaf dynamics, 
radiation transfer, stomatal resistance, soil moisture stress factor for stomatal 
resistance, aerodynamic resistance, runoff, snowfall, snow surface albedo, 
supercooled liquid water in frozen soil, and frozen soil permeability. 

The Noah-MP LSM has evolved through community efforts to pursue and refine a modern-era LSM suitable for use in the National Centers for Environmental Prediction (:term:`NCEP`) operational weather and climate prediction models. This collaborative effort continues with participation from entities such as NCAR, NCEP, NASA, and university groups. 

Noah-MP has been implemented in the UFS via the :term:`CCPP` physics package and 
is currently being tested for operational use in GFSv17 and RRFS v2. Additionally, the UFS Weather Model now contains a Noah-MP land component. Noah-MP has 
also been used operationally in the NOAA National Water Model (NWM) since 2016. Details about the model's physical parameterizations can be found in :cite:t:`NiuEtAl2011` (2011), and a full description of the model is available in the `Community Noah-MP Land Surface Modeling System Technical Description Version 5.0 <https://opensky.ucar.edu/islandora/object/technotes:599>`_. 

Disclaimer 
*************

The United States Department of Commerce (DOC) GitHub project code is
provided on an “as is” basis and the user assumes responsibility for its
use. DOC has relinquished control of the information and no longer has a
responsibility to protect the integrity, confidentiality, or
availability of the information. Any claims against the Department of
Commerce stemming from the use of its GitHub project will be governed by
all applicable Federal laws. Any reference to specific commercial
products, processes, or services by service mark, trademark,
manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation, or favoring by the Department of Commerce.
The Department of Commerce seal and logo, or the seal and logo of a DOC
bureau, shall not be used in any manner to imply endorsement of any
commercial product or activity by DOC or the United States Government.

References
*************

.. bibliography:: ../references.bib