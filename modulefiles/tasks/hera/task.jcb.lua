prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))

load(pathJoin("prod_util", prod_util_ver))

