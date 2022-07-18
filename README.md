# MassOS-Snapd
Support for the snapd package manager on MassOS.

This is designed to improve software support on MassOS and complement Flatpak.

Since snapd is highly controversial, it will **NOT** be installed on MassOS by default, however you can easily install it using the scripts in this repository.

# Requirements
MassOS **2022.07** or later is required.

# Installing
To install it, first run this command in a terminal to download the setup script:
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
If you decide you want to completely remove snapd from your system, you must first uninstall all snap packages.

To find out what snap packages you currently have installed, run the following command:
```
snap list
```
Remove a package like this (do this for all packages, **making sure to replace** `<package-name>` **with the package name**):
```
snap remove --purge <package-name>
```
Once all the installed snaps are removed, uninstall snapd by running the following command:
```
sudo /usr/lib/snapd/remove-snapd.sh
```
You should reboot after the removal to ensure everything is cleaned up properly.
