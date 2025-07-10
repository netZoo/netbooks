from oauthenticator.github import GitHubOAuthenticator
import systemdspawner
import os, subprocess, sys
import pandas as pd
import boto3
from io import StringIO

# Configuration file for jupyterhub.
c = get_config()  #noqa

# Define proxy and authenticator parameters
c.ConfigurableHTTPProxy.command = '/home/vagrant/miniforge3/envs/notebooks2/bin/configurable-http-proxy'
c.JupyterHub.authenticator_class = "shared-password"
c.SharedPasswordAuthenticator.user_password = "my-workshop-2042"
#c.JupyterHub.authenticator_class = 'oauthenticator.LocalGitHubOAuthenticator'
#c.GithubOAuthenticator.oauth_callback_url = 'https://netbooks.networkmedicine.org/hub/oauth_callback'

# Fetch user list
#client = boto3.client('s3')
#bucket_name = 'netzoo'
#object_key = 'netbooks/netbooks_allowed_users.csv'
#csv_obj = client.get_object(Bucket=bucket_name, Key=object_key)
#body = csv_obj['Body']
#csv_string = body.read().decode('utf-8')
#df = pd.read_csv(StringIO(csv_string),sep=',')
#c.Authenticator.allowed_users = set(df.users)
#c.Authenticator.admin_users={'vagrant'}
c.Authenticator.allowed_users = {'vagrant'}
c.LocalAuthenticator.create_system_users = True
c.Authenticator.delete_invalid_users = True

# Define spawner parameters
c.JupyterHub.spawner_class = systemdspawner.SystemdSpawner
#c.SystemdSpawner.dynamic_users = True
#c.SystemdSpawner.unit_extra_properties = {'RuntimeDirectoryPreserve': 'no'}
#c.Spawner.default_url = '/home/vagrant/netbooks/netbooks/Welcome_to_netBooks.ipynb'
#c.SystemdSpawner.disable_user_sudo = True
#c.SystemdSpawner.readonly_paths = ['/']
#c.SystemdSpawner.isolate_tmp = True
#c.SystemdSpawner.isolate_devices = True
#c.JupyterHub.template_paths = ['/etc/jupyterhub/templates/']
c.Spawner.environment = {
  'CMDSTAN': '/home/ubuntu/.cmdstan/cmdstan-2.34.1'
}

# Define HTTPS access
#c.JupyterHub.port = 443
#c.JupyterHub.ssl_key = '/etc/letsencrypt/live/netbooks.networkmedicine.org/privkey.pem'
#c.JupyterHub.ssl_cert = '/etc/letsencrypt/live/netbooks.networkmedicine.org/fullchain.pem'

import shutil, pwd, grp, distutils
from subprocess import check_call

def copyDirectory(src, dest):
        try: # shutil.copytree(src, dest)
            shutil.copytree(src, dest) #distutils.dir_util.copy_tree(src, dest)
        # Directories are the same
        except shutil.Error as e:
            print('Directory not copied. Error: %s' % e)
        # Any error saying that the directory doesn't exist
        except OSError as e:
            print('Directory not copied. Error: %s' % e)

def create_dir_hook(spawner):
    username = spawner.user.name # get the username
    volume_path = '/var/lib/private/' + username
    if os.path.exists(volume_path):
        shutil.rmtree(volume_path)
    tutorials_src = os.path.join('/home/vagrant/netbooks', 'netbooks')
    tutorials_dest=os.path.join(volume_path)
    copyDirectory(tutorials_src, tutorials_dest)

# attach the hook function to the spawner
#c.Spawner.pre_spawn_hook = create_dir_hook
c.Spawner.cmd = '/home/vagrant/miniforge3/envs/notebooks2/bin/jupyterhub-singleuser' #['jupyterhub-singleuser']

# Idle process management
'''
c.JupyterHub.services = [
    {
        "name": "jupyterhub-idle-culler-service",
        "command": [
            sys.executable,
            "-m", "jupyterhub_idle_culler",
            "--timeout=1200","--cull-users=True","--max-age=7200","--remove-named-servers=True",
        ],
    }
]
'''
