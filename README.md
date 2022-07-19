# MassOS-Snapd
Support for the snapd package manager on MassOS.

This is designed to improve software support on MassOS and complement Flatpak.

Since snapd is highly controversial, it will **NOT** be installed on MassOS by default, however you can easily install it using the scripts in this repository.

# Requirements
MassOS **2022.07** or later is required.

# Installing
All of the following commands should be run in a terminal. Find the terminal app or press Control+Alt+T to open the terminal. Commands prepended with `sudo` may require you to enter your user password.

Before installing, set the default `tar` implementation to GNU tar (required for snapd's snapshotting functionality to work):
```
sudo set-default-tar gtar
```
If you want to change it back to the original later, replace `gtar` with `bsdtar` in the above command.

To install snapd, first download the setup script:
```
curl -LOs https://raw.githubusercontent.com/MassOS-Linux/MassOS-Snapd/main/install-snapd.sh
```
Make the script executable like this:
```
chmod +x install-snapd.sh
```
Run it like this (you may need to enter your user password):
```
sudo ./install-snapd.sh
```
After the script checks the latest available version, it will prompt you to confirm you want to install. Type `y` at the prompt to continue.

Now wait patiently, and when snapd is finished installing, you'll be shown a message giving information on how to use and manage snapd.

You **WILL** need to reboot your system after installing snapd.

# Upgrading
To check for snapd updates, run the following command:
```
sudo /usr/lib/snapd/update-snapd.sh
```
If there is an update available, the script will prompt you to update. Answer `y` at the prompt and wait patiently.

After the update, you **WILL** need to reboot your system.

# Removing
If you decide you want to completely remove snapd from your system, for the best result you should try to make sure no snap packages are running.

To completely uninstall snapd and all installed snap packages, run the following command:
```
sudo /usr/lib/snapd/remove-snapd.sh
```
You should reboot after the removal to ensure everything is cleaned up properly.

# GUI software center
Optionally, install the Snap Store by using the following command:
```
snap install snap-store
```
Then you will be able to use the graphical "Snap Store" app to find, install and manage snap packages.
