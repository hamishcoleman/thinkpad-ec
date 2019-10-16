Description of the patch sets
-----------------------------

This repository has two sets of patches - one set for the keyboard
changes and one for turning off the battery validation.  The battery
patches are disabled by default, but are easy to enable.

Any combination of the two sets of patches can be enabled or disabled
(even including a version with no patches at all - to revert all changes)

### KEYBOARD patchset

Applying this set of patches will adjust your Embedded Controller to support
the slightly different keymapping used with a xx20 keyboard.  If you prefer
to use the older 7-row keyboard instead of the newer xx30 6-row keyboard, then
you want this patchset enabled.  It is enabled by default.

### BATTERY patchset

Applying this set of patches will disable the check that the system makes for
Lenovo original batteries.  If you wish to use aftermarket batteries, then
you want to enable this patchset.  It is disabled by default.

Note that this authentic battery check was done by Lenovo for a good reason
as aftermarket battery construction and quality is highly variable.  There
have been a number of people who have discovered that their aftermarket
battery is not working even after installing this patch and (so far) they
have all found that the battery itself was broken.

Configuring which patches are used
----------------------------------

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
