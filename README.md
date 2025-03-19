# LUMI-containers
Recipes for containers directly provided to LUMI users or used as part of the environment.
Might add more CI at some point. 

## Available visualization containers 

Visualization containers are currently shared through Allas: 
<https://a3s.fi/swift/v1/AUTH_ac5838fe86f043458516efa4b8235d7a/lumi-containers/>
So they cannot be directly used in `.def` files but can be used with `singularity pull` / `wget` 

The recipes live under the [Recipes](/Recipes) folder:
- `PARAVIEW_LUMI.sif`
  - RPM Based paraview installation with virtualGL
- `VGL_LUMI.sif`
  - Base VGL container with VNC   	
- `VNC_LUMI.sif`
  - Base VNC container
- `VISIT_LUMI.sif`
  - Visit installation with virtualGL (centos based) 

### Adding visualization containers

- Create a PR
- Follow the naming scheme. <container_name>.def -> <container_name>.sif
- Update the info in `data.json` when making changes
- PR:s can not be merged if the tests don't work

## Docker containers for AI and general application support.

Recipes for AI and generic application support employ Docker recipes. 
The infrastructure is available under the [RecipesDocker](/RecipesDocker) folder.

For more info read that folder [documentation](/RecipesDocker/README.md).
