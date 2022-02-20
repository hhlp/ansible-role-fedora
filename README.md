# Ansible Role 

This is my personal **Ansible Playbook** for Automatitaion the setup of a Fresh _FEDORA_ instalation in a few simple steps.

First Steps:

* Install ansible and ansible-collection-community-general packages
* Configure Ansible:

```
sudo nvim /etc/ansible/hosts
``` 

and add these lines at the END of the File

```
[localhost]
127.0.0.1   ansible_connection=local
```

1. Docker Playbook _f35-setup-docke.yaml_

* Add Docker CE repo
* Install Docker
* Install docker-compose
* Enable Experimental Fucntions in Docker
* Install Docker Machine 
* Install Docker Machine Driver KVM

  - Aditional Steps:

  * Install IBM Cloud CLI

  - Execute:

  ```
  ansible-playbook -K f35-setup-docker.yaml
  ```

2. Vscode Role _vscode-setup.yaml_

* Create user font directory if it does not exist
* Install nerd font
* name: Install extensions
* Create vscode config directory if it does not exist
* Install config file

You need to edit this file and add there all the plug-ins to install:

```
/home/$USER/ansible-role-fedora/vscode/vscode/defaults
```

  - Execute:

  ```
  ansible-playbook vscode-setup.yml
  ```

1. Fedora 

- _f35-setup-repos.yaml_

* Set hostname to FedoraBox
* Install rpm fusion repo
* Enable Copr Repos
* Install som packages from a remote repo
* Install media codecs
* Creating a file with content mongodb repo
* Install mongodb tools
* Creating a file with content gitHub Cli Repo
* Istall gh-cli
* Download Balena-Etcher Repo 
* Install balena etcher
* Add Vivaldi/Brave Browser Repo
* Install Vivaldi/Brave Browser
* Add Microsoft Edge Browser Repo
* Install Microsoft Edge Browser
* Install Balena Etcher

  - Execute:

  ```
  ansible-playbook -K f35-setup-repos
  ```

- _f35-setup-programs.yaml_

* Install common packages

  - Execute:

  ```
  ansible-playbook -K f35-setup-programs
  ```

- _f35-setup-flatpak.yaml_

* Add the flathub repository remote to the user installation
* Add the Fedora repository remote to the user installation
* Install comon flatpaks (flathub) Applications
* Disable Gnome software download update

  - Execute:

  ```
  ansible-playbook f35-setup-flatpak
  ```
