#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		  : plot_obs_ghcn.py
## Usage	  : Plot GHCN observation ioda file of land-DA workflow
## Input file : ghcn_snwd_ioda.nc
## NOAA/EPIC
## History ===============================
## V000: 2024/12/03: Chan-Hoo Jeon : Preliminary version
###################################################################### CHJ #####

import os, sys
import yaml
import numpy as np
import netCDF4 as nc
import cartopy
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable


# Main part (will be called at the end) ============================= CHJ =====
def main():
# =================================================================== CHJ =====

    yaml_file="plot_obs_ghcn.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()
    print("YAML_DATA:",yaml_data)

    work_dir=yaml_data['work_dir']
    fn_input=yaml_data['fn_input']
    out_title_base=yaml_data['out_title_base']
    out_fn_base=yaml_data['out_fn_base']
    cartopy_ne_path=yaml_data['cartopy_ne_path']
    
    # Set the path to Natural Earth dataset
    cartopy.config['data_dir']=cartopy_ne_path

    print(' ===== INPUT: '+fn_input+' ================================')
    # open the data file
    fpath=os.path.join(work_dir,fn_input)
    try: mdat=nc.Dataset(fpath)
    except: raise Exception('Could NOT find the file',fpath)
    print(mdat)
    print(mdat.groups['MetaData'])
    print(mdat.groups['ObsError'])
    print(mdat.groups['ObsValue'])
    print(mdat.groups['PreQC'])

    longitude=mdat.groups['MetaData'].variables['longitude'][:]
    latitude=mdat.groups['MetaData'].variables['latitude'][:]
    datetime=mdat.groups['MetaData'].variables['dateTime'][:]
    stationElevation=mdat.groups['MetaData'].variables['stationElevation'][:]
#    height=mdat.groups['MetaData'].variables['height'][:]
    stationID=mdat.groups['MetaData'].variables['stationIdentification'][:]

    # Longitude 0:360 => -180:180
#    lon_max=np.max(lon)
#    if lon_max>180:
#        lon=(lon+180)%360-180

    lon=longitude
    lat=latitude

    # Highest and lowest longitudes and latitudes for plot extent
    lon_min=np.min(lon)
    lon_max=np.max(lon)
    lat_min=np.min(lat)
    lat_max=np.max(lat)
#    extent=[lon_min,lon_max,lat_min,lat_max]
    # for CONUS
#    extent=[-125,-66,23,53]
    # for Northern Hemisphere
    extent=[-179,179,0,82.5]
    print(extent)

#    c_lon=np.mean(extent[:2])
    c_lon=-77.0369 # D.C.
    print(' c_lon=',c_lon)

    # Variables
#    vars_out=["ObsValue","ObsError","PreQC"]
    vars_out=["ObsValue"]
    for svar in vars_out:
        svar_plot(svar,mdat,lon,lat,extent,c_lon,out_title_base,out_fn_base,work_dir)
    

# Variable plot =============================================== CHJ =====
def svar_plot(svar,mdat,lon,lat,extent,c_lon,out_title_base,out_fn_base,work_dir):
# ============================================================= CHJ =====

    print(' ===== '+svar+' === Total Snow Depth =====================')
    # Extract data array
    sfld=mdat.groups[svar].variables['totalSnowDepth'][:]

    svar="SnowDepth"
    out_title_fld=out_title_base+svar
    out_fn=out_fn_base+svar

    cs_cmap='gist_ncar_r'
    lb_ext='neither'
    tick_ln=1.5
    tick_wd=0.45
    tlb_sz=3
    scat_sz=1.0
    n_rnd=2
    cmap_range='fixed'

    print(' svar name=',svar)

    # Max and Min of the field
    fmax=np.max(sfld)
    fmin=np.min(sfld)
    print(' fld_max=',fmax)
    print(' flx_min=',fmin)

    # Make the colormap range symmetry
    print(' cmap range=',cmap_range)
    if cmap_range=='symmetry':
        tmp_cmp=max(abs(fmax),abs(fmin))
        cs_min=round(-tmp_cmp,n_rnd)
        cs_max=round(tmp_cmp,n_rnd)
    elif cmap_range=='round':
        cs_min=round(fmin,n_rnd)
        cs_max=round(fmax,n_rnd)
    elif cmap_range=='real':
        cs_min=fmin
        cs_max=fmax
    elif cmap_range=='fixed':
        cs_min=0
        cs_max=1000.0
    else:
        sys.exit('ERROR: wrong colormap-range flag !!!')

    print(' cs_max=',cs_max)
    print(' cs_min=',cs_min)
    print(' extent=',extent)

    # Plot field
    fig,ax=plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Robinson(c_lon)))
    ax.set_extent(extent, ccrs.PlateCarree())
    # Call background plot
    back_plot(ax)
    ax.set_title(out_title_fld,fontsize=9)
    cs=ax.scatter(lon,lat,transform=ccrs.PlateCarree(),c=sfld,cmap=cs_cmap,
                  vmin=cs_min,vmax=cs_max,s=scat_sz)
    divider=make_axes_locatable(ax)
    ax_cb=divider.new_horizontal(size="3%",pad=0.1,axes_class=plt.Axes)
    fig.add_axes(ax_cb)
    cbar=plt.colorbar(cs,cax=ax_cb,extend=lb_ext)
    cbar.ax.tick_params(labelsize=8)
    cbar.set_label(svar,fontsize=8)

    # Output figure
    ndpi=300
    out_file(work_dir,out_fn,ndpi)


# Background plot ==================================================== CHJ =====
def back_plot(ax):
# ==================================================================== CHJ =====

    # Resolution of background natural earth data ('50m' or '110m')
    back_res='50m'

    fline_wd=0.5  # line width
    falpha=0.7 # transparency

    # natural_earth
    land=cfeature.NaturalEarthFeature('physical','land',back_res,
                      edgecolor='face',facecolor=cfeature.COLORS['land'],
                      alpha=falpha)
    lakes=cfeature.NaturalEarthFeature('physical','lakes',back_res,
                      edgecolor='blue',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)
    coastline=cfeature.NaturalEarthFeature('physical','coastline',
                      back_res,edgecolor='black',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)
    states=cfeature.NaturalEarthFeature('cultural','admin_1_states_provinces',
                      back_res,edgecolor='green',facecolor='none',
                      linewidth=fline_wd,linestyle=':',alpha=falpha)
    borders=cfeature.NaturalEarthFeature('cultural','admin_0_countries',
                      back_res,edgecolor='red',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)

#    ax.add_feature(land)
#    ax.add_feature(lakes)
#    ax.add_feature(states)
#    ax.add_feature(borders)
    ax.add_feature(coastline)


# Output file ======================================================= CHJ =====
def out_file(work_dir,out_file,ndpi):
# =================================================================== CHJ =====
    # Output figure
    fp_out=os.path.join(work_dir,out_file)
    plt.savefig(fp_out+'.png',dpi=ndpi,bbox_inches='tight')
    plt.close('all')


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

