#!/usr/bin/env python3

import os
import yaml
import numpy as np
import netCDF4
import matplotlib.pyplot as plt
from scipy.stats import norm
import cartopy
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import matplotlib.ticker
import matplotlib as mpl
from matplotlib.colors import ListedColormap

def get_obs_stats(fdir, plottype, jedi_exe):
    global lat,lon
    omb_=[]
    oma_=[]    
    obs_=[]
    qc_ =[]
    err_=[]
    lat_=[]
    lon_=[]
    
    for fname in os.listdir(fdir):
        print("=== File Name:",fname)
        f=netCDF4.Dataset(fdir+'/'+fname)
        print("NETCDF:",f)
        obs=f.groups['ObsValue'].variables['totalSnowDepth']
        print("ObsValue:",obs)
        if jedi_exe == 'letkf':
          ombg=f.groups['ombg'].variables['totalSnowDepth']
          print("OMBG:",ombg)
        else:
          ombg=np.zeros(obs.shape)
          print("WARNING: ombg is not set in obs output file !!!")
        oman=f.groups['oman'].variables['totalSnowDepth']
        print("OMAN:",oman)
        qc=f.groups['PreQC'].variables['totalSnowDepth']
        print("PreQC:",qc)
        obstime=f.groups['MetaData'].variables['dateTime']
        print("OBS_TIME:",obstime)
        if plottype=='histogram':
            ombg_=np.ma.masked_where(qc != 0, ombg)
            ombg_=np.ma.masked_where(ombg == 0, ombg_) 
            oman_=np.ma.masked_where(qc != 0, oman)
            oman_=np.ma.masked_where(ombg == 0, oman_)
            ombg=ombg_
            oman=oman_
        lat=f.groups['MetaData'].variables['latitude']
        lon=f.groups['MetaData'].variables['longitude']

        obs_.append(obs[:])
        omb_.append(ombg[:])
        oma_.append(oman[:])
        lat_.append(lat[:])
        lon_.append(lon[:])

    total_omb=np.concatenate(omb_)
    total_oma=np.concatenate(oma_)
    total_obs=np.concatenate(obs_)
    total_lat=np.concatenate(lat_)
    total_lon=np.concatenate(lon_)

    return total_oma,total_omb,total_lat,total_lon

def plot_scatter():
    print("===== PLOT: SCATTER =====")
    
    # Set the path to Natural Earth dataset
    cartopy.config['data_dir']=yaml_data['cartopy_ne_path']

    field_mean=float("{:.2f}".format(np.mean(np.absolute(field))))
    field_std=float("{:.2f}".format(np.std(np.absolute(field))))
    field_max=float("{:.2f}".format(np.max(np.absolute(field))))
    field_min=float("{:.2f}".format(np.min(np.absolute(field))))
    print("Mean |OMA|=",field_mean)
    print("STDV |OMA|=",field_std)
    print("Max |OMA|=",field_max)
    print("Min |OMA|=",field_min)    
    crs=ccrs.PlateCarree()
    fig=plt.figure(figsize=(8,5))
    ax=plt.subplot(111, projection=crs)
    coastline=cfeature.NaturalEarthFeature('physical','coastline','50m',edgecolor='black',facecolor='none',
                      linewidth=0.5,alpha=0.7)
    ax.add_feature(coastline)
    norm=plt.Normalize(yaml_data['field_range'][0],yaml_data['field_range'][1])
    num_cmap=25
    cmap_neg=mpl.colormaps['Blues_r'].resampled(num_cmap)
    cmap_pos=mpl.colormaps['Reds'].resampled(num_cmap)
    cmap_color=np.vstack((cmap_neg(np.linspace(0.1,0.7,num_cmap)),cmap_pos(np.linspace(0.2,0.8,num_cmap))))
    cmap_new=ListedColormap(cmap_color, name='BlueRed_rw')
    sc=ax.scatter(lon, lat, c=field, s=1.5, cmap=cmap_new, transform=crs, norm=norm)
    cbar=plt.colorbar(sc, orientation="horizontal", shrink=0.5, pad=0.05)
    stitle=yaml_data['title_fig']+' \n '+'Mean |OMA| ='+str(field_mean)+', STDV |OMA| ='+str(field_std)
    plt.title(stitle)
    output_fn=yaml_data['output_prefix']+"_scatter.png"
    plt.savefig(output_fn,dpi=200,bbox_inches='tight')
    plt.close('all')

def plot_histogram():
    print("===== PLOT: HISTOGRAM =====")    
    field_mean=float("{:.2f}".format(np.mean(field)))
    field_std=float("{:.2f}".format(np.std(field)))
    field_max=float("{:.2f}".format(np.max(field)))
    field_min=float("{:.2f}".format(np.min(field)))
    print("Mean OMA=",field_mean)
    print("STDV OMA=",field_std)
    print("Max OMA=",field_max)
    print("Min OMA=",field_min)
    nbins=yaml_data['nbins']

    opt_xlimit='auto'
    if opt_xlimit=='auto':
        fld_min=int(field_min)
        fld_max=int(field_max)
        xlimit=[fld_min,fld_max]
        print("xlimit min=",fld_min)
        print("xlimit max=",fld_max)
        print("xlimit=",xlimit)
    else:
        xlimit=yaml_data['field_range']
        
    plt.hist(field[:], bins=nbins, range=xlimit, density=True, color ="blue")
    stitle=yaml_data['title_fig']+' \n '+'Mean(OMA) ='+str(field_mean)+', STDV(OMA) ='+str(field_std)
    plt.title(stitle)
    output_fn=yaml_data['output_prefix']+"_histogram.png"
    plt.savefig(output_fn,dpi=150,bbox_inches='tight')
    plt.close('all')

if __name__ == '__main__':
    global field,yaml_data

    yaml_file="plot_hofx.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()
    print("YAML_DATA:",yaml_data)

    oma,omb,lat,lon=get_obs_stats(yaml_data['hofx_files'],yaml_data['plottype'],yaml_data['jedi_exe'])
    if yaml_data['field_var']=='OMA':
        field=oma
    if yaml_data['field_var']=='OMB':
        field=omb    

    if yaml_data['plottype']=='scatter' or yaml_data['plottype']=='both': 
        plot_scatter()
    if yaml_data['plottype']=='histogram' or yaml_data['plottype']=='both':
        plot_histogram()
