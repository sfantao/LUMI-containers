# LUMI-containers
Singularity recipes for containers directly provided to LUMI user or used as part of the environment.
Might addd more CI at some point. 

## Available containers 

Containers are currently shared through Allas: 
<https://a3s.fi/swift/v1/AUTH_ac5838fe86f043458516efa4b8235d7a/lumi-containers/>
So the can not be directly used in `.def` files but can be used with `singularity pull` / `wget` 

- `PARAVIEW_LUMI.sif`
  - RPM Based paraview installation with virtualGL
- `VGL_LUMI.sif`
  - Base VGL container with VNC   	
- `VNC_LUMI.sif`
  - Base VNC container 

## Adding containers

- Follow the naming scheme. <container_name>.def -> <container_name>.sif
- Update the info in `data.json` when making changes
