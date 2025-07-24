# Netbooks: Jupyter notebook tutorial server for the Network Zoo 

## Overview
Netbooks is a webserver that hosts many uses cases related to gene regulatory networks using the Network Zoo.
These use cases span gene regulatory network inference and reconstruction, community detection, network analysis applied to different types of cancer, drug repurposing, and sex-specific regulation. 

## Technical consideration
The webserver is built using [Jupyter Hub](https://jupyter.org/hub) and includes R and Python kernels.

You can access Netbooks through the [web interface](https://netbooks.networkmedicine.org), or you can clone [this GitHub](https://github.com/netZoo/netbooks) repository to run the 
notebooks on your machine.

On the webserver, you can create new cells in each notebook to do extra analysis on specific use case, however, please make sure to save your work before closing the session, otherwise the work is lost.

If you are intrested in having a permanent user space, consider uploading the notebooks to [google colab](https://colab.research.google.com/notebooks/intro.ipynb#recent=true).

## Deploying a JupyterHub server

We provide a Vagrant recipe to deploy a JupyterHub server on Ubuntu 22.04 using Netbooks as an example. To do so, you'd need to install [vagrant](https://developer.hashicorp.com/vagrant) and [virtualbox](https://www.virtualbox.org/) and follow these steps:
```
git clone https://github.com/netZoo/netbooks.git

cd netbooks/vagrant

vagrant up

vagrant ssh

jupyterhub
```

## Issues
If you have any issue or suggestion, please open an [issue](https://github.com/netZoo/netbooks/issues) in the GitHub repository.
