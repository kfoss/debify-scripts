debify-scripts
=======================

#### Create an installable .deb from a repository of shell scripts ####
This project makes it easy for developers to package scripts -- along with associated files and directories -- into a .deb for double-click installation by end users.  


### Use ###
```
debify-scripts [-v version] [-d description] [-n author_name] [-e author_email] repo/script
```
will generate a **deb** subdirectory within **repo** that stores:
* deb package of the format **{repo}_{version}-{iteration}.deb**, which is...
* described by the command-line switches **-vdne**, and...
* mirrored at **{repo}_current.deb** for direct download, which...
* contains the entire **repo**, and...
* as root, executes **{script}** and extracts **{repo}** on installation (in case the script uses additional files you can reference in /tmp)


### Installation ###
**A) Install [debify-scripts_current.deb](https://va-vsrv-github.a.internal/kylef/debify-scripts/raw/master/deb/debify-scripts_current.deb)**:
```
1. Download and Double-click 
```

**B) Install Hands-on** (the old way):
```
1. git clone {repo}
2. chmod a+x debify_scripts.sh && cp debify_scripts.sh {destination-of-choice}
3. sudo ln --symbolic /usr/bin/debify-scripts {destination-of-choice}/debify_scripts.sh
```

#### Example ####
The installation deb was generated with the following command:
```
debify-scripts -d "Install debify-scripts systemwide" -n "Kyle Foster" -e "kyle.b.foster@gmail.com" debify-scripts/install.sh
```


#### Background ####
This project makes it easy for developers to package scripts -- along with associated files and directories -- into a .deb for double-click installation by end users.

Installing from source, in general, requires familiarity with command-line instructions and developer packages that many end users do not use.  Moreover, such installations happen outside the purview of the system's package manager, reducing systemwide visibility into package and version installations.  Debian/Ubuntu/Mint's package managers primarily focus on installing compiled applications, but they can easily bundle shell scripts for easier installation.  


#### Tested Environments ####
> * Linux Mint (15-"Olivia" with Cinnamon desktop)
> * Ubuntu (13.04LTS-"raring" with Gnome3 desktop) 
