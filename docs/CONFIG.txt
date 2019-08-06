Configuring which patches are used
----------------------------------

This repository has two sets of patches - one set for the keyboard
changes and one for turning off the battery validation.  The battery
patches are disabled by default, but are easy to enable.

Any combination of the two sets of patches can be enabled or disabled
(even including a version with no patches at all - to revert all changes)

There are several makefile targets that exist to help you configure which
patches are enabled.  Choose one or more of the following commands to
configure as you want:

    make patch_enable_battery clean     # Uses the battery validate patch
    make patch_disable_battery clean    # Turns off the battery validate patch
    make patch_enable_keyboard clean    # Uses the keyboard patches
    make patch_disable_keyboard clean   # Turns off the keyboard patches

Behind the scenes
-----------------

Each hardware and EC firmware version combination needs its own set of
patches, which are stored in directories called "*.img.d".  The Makefile
defines these patches into named groups ("KEYBOARD" and "BATTERY") which
can be enabled or disabled via a config file.

The enable and disable commands are simply updating the config file with
the appropriate settings.
