#!/usr/bin/env python3

import numpy as np
from netCDF4 import Dataset
import sys
# routine to create pseudo-ensemble for use in LETKF-OI for snow depth
# reads in sfc_data restarts, and sets snowdepth to +/- 
# perturbation, given stdev(ensemble) of B
# Clara Draper, October, 2021.

if (len(sys.argv) != 4): 
    print('argument error, usage: letkf_create file_stub variable back_error' ) 

fstub=sys.argv[1]
vname=sys.argv[2]
b = float(sys.argv[3]) 

# 2 ens members 
offset=b/np.sqrt(2)

print('adjusting '+fstub+'* by '+str(offset))

sign = [1,-1]
ens_dirs=['mem_pos','mem_neg'] 

for ens in range(2): 
    for tt in range(6):
        # open file 
        out_netcdf = ens_dirs[ens]+'/'+fstub+'.sfc_data.tile'+str(tt+1)+'.nc'
        #print (out_netcdf)
        ncOut = Dataset(out_netcdf, "r+")  
        # get land mask
        slmsk_array = ncOut.variables['slmsk'][:]
        vtype_array = ncOut.variables['vtype'][:]
        slmsk_array[vtype_array==15]=0 # remove glacier locations
        # add offset to the snow
        var_array = ncOut.variables[vname][:]
        var_array[slmsk_array==1]  = var_array[slmsk_array==1] + sign[ens]*offset
        ncOut.variables[vname][0,:,:] = var_array[:]
        ncOut.close()
