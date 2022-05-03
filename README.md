# LUMI-containers
Singularity recipes for containers directly provided to LUMI user or used as part of the environment.

## Available containers 

Containers are currently shared through Allas: 
<https://a3s.fi/swift/v1/AUTH_ac5838fe86f043458516efa4b8235d7a/lumi-containers/>
So the can not be directly used in `.def` files but can be used with `singularity pull` / `wget` 

- `PARAVIEW_LUMI.sif`
  - RPM Based paraview installation with virtualGL
  - sha256 `35e28350d74294dbf0e9cf517f511e6ea96dbcf3b87522a1125eca679af40580`
- `VGL_LUMI.sif`
  - Base VGL container with VNC   	
- `VNC_LUMI.sif`
  - Base VNC container 
