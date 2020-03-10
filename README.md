
COMPATIBILTY WARNING:
---------------------

As the result of CVE-2019-6171, it looks like newer Lenovo firmware update
files are adding a digital signature.  If you upgrade to a version using
this, you will not be able to patch your EC.

| laptop | last good | first locked version | Action |
| ------ | --------- | -------------------- | ------ |
| t430   | BIOS 2.81 (G1ETC1WW) EC 1.13 (G1HT35WW) | BIOS 2.82 (G1ETC2WW) EC 1.14 (G1HT36WW) | roll back to 2.81 (disable secure rollback prevention) |
| t430s  | BIOS 2.75 (G7ETB5WW) EC 1.16 (G7HT39WW) | BIOS 2.76 (G7ETB6WW) EC 1.16 (G7HT40WW) | |
| t530, t530i | BIOS 2.76 (G4ETB6WW) EC 1.13 (G4HT39WW) | BIOS 2.77 (G4ETB7WW) EC 1.14 (G4HT40WW) | |
| w530   | BIOS 2.75 (G5ETB5WW) EC 1.13 (G4HT39WW) | BIOS 2.76 (G5ETB6WW) EC 1.14 (G4HT40WW) | |
| x230   | BIOS 2.75 (G2ETB5WW) EC 1.14 (G2HT35WW) | BIOS 2.77 (G2ETB7WW) EC 1.15 (G2HT36WW) | |
| x230t  | BIOS 2.73 (GCETB3WW) EC 1.14 (GCHT25WW) | BIOS 2.75 (GCETB5WW) EC 1.15 (GCHT26WW) | |

Basically, any BIOS update package where the changelog mentions CVE-2019-6171
will have this lockdown.

Lenovo is tracking their response to this CVE at:
    https://support.lenovo.com/gb/en/solutions/len-27764

If you upgraded your BIOS to the locked version:
* Ensure that downgrading is possible in BIOS settings (Security/UEFI BIOS Update Option/Secure Rollback Prevention -> Disable)
* Downgrade it to the latest supported version. EC will be automatically downgraded as well

Intro
-----

The main purpose of this software is to patch the EC on xx30 series thinkpads
to make the classic 7-row keyboards work.  There are also patches included (but
disabled by default) to disable the authentic battery validation check.

With the patches included here, you can install the classic keyboard
hardware on many xx30 series laptops and make almost every key work properly.
The only keys that are not working are Fn+F3 (Battery) and Fn+F12 (Hibernate)

Unfortunately, there are a small number of thinkpads with a model number
from the "xx30" series that are using a completely different EC CPU and
a different BIOS update strategy.  Thus they are not currently able to
be patched.  This is known to be the case for at least the L430, L530
and E330.

* A full writeup of the hardware modifications needed can be found at:
    http://www.thinkwiki.org/wiki/Install_Classic_Keyboard_on_xx30_Series_ThinkPads

* More information for hacking on this can be found in the [HACKING doc](docs/HACKING.txt).

* A video presenting how these thinkpad laptops were hacked is online:
    https://www.youtube.com/watch?v=Fzmm87oVQ6c

Step-by-step instructions:
--------------------------

This software expects to be run under Linux (real Linux, not Microsoft
Windows Linux subsystem).  For best results, ensure you have updated your
BIOS to a recent version before starting.  If there is too large a
difference between the BIOS and EC versions then the flash process will
not complete.

A little more detail about the BIOS versions:
It is not so much a question about upgrading to a recent BIOS version, but
more of ensuring you are using a compatible EC firmware version.  For
safety, ensure that the EC version you are running is the same as the EC
version used by the patched image you build.  The version used to build
the patch is shown at the end of the build process and during the pre-flash
warning message.

1. Ensure you have installed the prerequisite packages
   On Debian, this can be done with:

    ```
    sudo apt-get update
    sudo apt-get install build-essential git mtools libssl-dev
    ```

   On Fedora, you could install it with dnf:

    ```
    sudo dnf install git mtools openssl-devel
    sudo dnf group install "C Development Tools and Libraries"
    ```
    

2. Clone a copy of this repo on to your computer:

    ```
    git clone https://github.com/hamishcoleman/thinkpad-ec
    ```

3. Change to the directory created by the clone:

    ```
    cd thinkpad-ec
    ```

4. Show the list of laptops and USB image file names:

    ```
    make list_laptops
    ```

5. Choose your laptop model name from the list shown.
   E.G. "patched.x230.img" for a x230 laptop.

6. Using the name chosen in the previous step, make the fully
   patched image for this laptop (this will download the original
   file from Lenovo and patch it):

    ```
    make patched.x230.img
    ```

7. Insert your USB stick and determine what device name it has.
   (Note: chose a USB stick with nothing important on it, it will
   be erased in the next step) This command should help you find the
   right device:

    ```
    lsblk -d -o NAME,SIZE,LABEL
    ```

8. Write the bootable patched image onto the USB stick device (replace
   the "sdx" in this command with the correct name for your usb stick)

   WARNING: if you do not have the right device name, you might overwrite
   your hard drive!

   ```
   sudo dd if=patched.x230.img of=/dev/sdx bs=4M status=progress conv=fsync
   ```

Your USB stick is now ready to boot and install the patched firmware.


Notes:
------

* You can also create a bootable CDROM image for burning to a disk
  by asking for a ".iso" file instead of the ".img" in step 6 above.
  Then you can use your normal CDROM burning tools to put this image on
  a blank cd and boot it up, skipping steps 7 and 8.

* To include the battery validation patch or to make a build that
  reverts any EC changes, read the [CONFIG doc](docs/CONFIG.md) and follow
  the configuration instructions in it before running step 6.


Booting the stick and flashing the firmware:
--------------------------------------------

While flashing the firmware is as simple as booting the USB stick
created above, there are a couple of steps that can help the process.
This is more a list of issues that the community has discovered as the
patch was applied in different circumstances than a hard and fast set
of requirements.

The flashing process takes place in two distinct steps (these are outlined
below, but explained in more detail in [firmware_flashing doc](docs/firmware_flashing.txt))

1. Booting the USB stick:
   * First shows a page with information about the patch, including
     which laptop type it was built for.
   * Then it hands the new EC update to the BIOS, "staging" it for
     a future flashing into the EC hardware
   * Finally it reboots the system.

1. Under the BIOS control, during a bootup:
   * During the boot, the BIOS notices that it has a new EC update staged
   * It then checks if it is safe to flash this update to the EC.
   * If everything is safe, it will show a screen saying "Flashing EC"
   * The system will bootup normally with the new EC code running.

If you don't see this second screen with the "Flashing EC" message,
your EC has not been flashed, and you should continue reading below to
see what steps you can take to ensure the EC is properly flashed with
the patched firmware.  In this cases everything might look like it was
successful but after the reboot the keys are not remapped.

* For best results, ensure you have the power charger plugged in during
  the flashing process.

  * Some chargers seem to have issues with actually performing the flashing
    procedure after the flash process reboots.  So, if you have - or can
    borrow - other chargers, try that.

* The firmware flash process generally requires you to have a charged
  battery plugged in to the laptop before it will complete.

  * It may be possible to bypass the requirement for a charged battery
    if you unplug the battery completely.
  * Alternatively, it might be simply looking for any battery /and/
    the power charger plugged in.

  Yes, this is contradictory, but it is worth trying both options.

* An ultrabay battery is not considered by the update mechanism to be
  a suitable source of power - when trying different battery options,
  ensure you are trying batteries in the main battery slot.

* Ensure your BIOS has been configured to boot from "Legacy" and not
  "UEFI" before trying to boot.

* If you do normally use UEFI boot, there has been at least one case where
  the EC does not get flashed until the BIOS is switched back into UEFI
  mode - after which the EC was automatically flashed on the next reboot.
