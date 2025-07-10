from oauthenticator.github import GitHubOAuthenticator
import systemdspawner
import os, subprocess, sys
import pandas as pd
import boto3
from io import StringIO

# Configuration file for jupyterhub.
c = get_config()  #noqa

# Define proxy and authenticator parameters
c.ConfigurableHTTPProxy.command = '/home/vagrant/miniforge3/bin/configurable-http-proxy'
c.JupyterHub.authenticator_class = "shared-password"
c.SharedPasswordAuthenticator.user_password = "my-password"
# Use the following code for GitHub authentication
#c.JupyterHub.authenticator_class = 'oauthenticator.LocalGitHubOAuthenticator'
#c.GithubOAuthenticator.oauth_callback_url = 'https://myurl.org/hub/oauth_callback'

# Fetch user list
#use following code for reading a list of users from the cloud
#client = boto3.client('s3')
#bucket_name = 'mybucket'
#object_key = 'my_allowed_users.csv'
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
#c.JupyterHub.spawner_class = systemdspawner.SystemdSpawner
#c.SystemdSpawner.dynamic_users = True
#c.SystemdSpawner.unit_extra_properties = {'RuntimeDirectoryPreserve': 'no'}
c.Spawner.default_url = 'lab/workspaces/auto-V/tree/netbooks/netbooks/Welcome_to_netBooks.ipynb'
#c.SystemdSpawner.disable_user_sudo = True
#c.SystemdSpawner.readonly_paths = ['/']
#c.SystemdSpawner.isolate_tmp = True
#c.SystemdSpawner.isolate_devices = True
#c.JupyterHub.template_paths = ['/etc/jupyterhub/templates/']
#c.Spawner.environment = {
#  'myvar': '/my/home/path'
#}

# Define HTTPS access
#c.JupyterHub.port = 443
#c.JupyterHub.ssl_key = '/etc/letsencrypt/live/myurl.org/privkey.pem'
#c.JupyterHub.ssl_cert = '/etc/letsencrypt/live/myurl.org/fullchain.pem'

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
c.Spawner.cmd = '/home/vagrant/miniforge3/bin/jupyterhub-singleuser'

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
