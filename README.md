## STEP 1

1. Get TARPN install scrypts to run under any "user" not limited to "pi" user.
- The scripts in the repo will install TARPN on a Raspberry Pi.
- All the setup steps from the original scripts have been left the same with the exeption of the fallowing:

### Changes from Original script
1. changed all referances in the scripts to the directory /home/pi have been changed to use the variable `$HOME` 

2. All referances to the user `pi` have been changed to use the variable `$USER`

3. changed where the scripts contained in the repo are sourced so that the above changes can be made. Scripts contained in this repo will check for the next needed script in the folder `~/Tarpn-Anything` rather then downloading an unmodified one that is hard coded for the `pi` user.


## STEP 2

This is not complete yet
1. try to develope the scripts to install TARPN and all other needed programs to run a TARPN node on x86/x64
