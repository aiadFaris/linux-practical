

#!/bin/bash

## This Shell script is licensed under the terms of the MIT.
## The script is version 0.2.
#-----------------------------------------------------------------------------------

## DISCLAIMER
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
####################################################################################

### CAVEAT
## Make sure to adjust the paths in the variables and the array sections before running the script and this script is executable. You can run the script with ``./Incremental.backup.sh``. The target drive must not be mounted. The script takes care of mounting it. If it was accidentally mounted, unmount it.
####################################################################################

### Variables
mntPnt=none
DST=lnb-home
srcDvc="/dev/nvme0n1"
dvcID="c072b60f-c042-2d4c-8757-21a859021688"
fltr="rsync_lnb_HOME_filter.txt"
wdy="$(date +%a)"
SRC=$HOME
### Optional
## dstPath="${mntPnt}/${DST}"
# -------------------------


## In addition to functionality, this script also aims to fulfill the didactic aspect.
## The many comments leave nothing new unexplained.

## This is a script to create an incremental backup with rsync
## Rsync's options will not be covered here, see rsync above.

### Abstract
## We should look at the backup process from the "point of view" of the script, not in a
## chronological order that is familiar to people and makes it easier to understand.
## While we can defer cycles by their characteristics, such as aging, we should not check
## the second cycle as extra step

### weekdays and weekends
## There is no distinction between weekdays and weekends. Weekdays are used for both.

### Calling this script with ./NAME.sh or 'bash NAME.sh' instead of 'sh NAME.sh' is preferable.

## Notes and testing are separately documented.
## I wrote numbered notes like [note¹] below. Positionally, they are placed where a reason for
## explanation is needed Or a reference to testing makes sense.
## However, they themselves are not an integral part of this script.

## To the distribution's environment
## When using the Dolphin file manager GUI to mount a disc, the mount path appears
## to follow the respective entry in the fstab file
## When excluding files, use either a relative or absolute path (but then check)
##  #/home/user/.avfs
##  # Or so when we run the script from $SRC
##  #.avfs

## Syntax
## To remove files, here the escaped "rm" command is used since it is shadowed by alias.
## The escaped form \rm is avoided since it raise an error

# Limitations:
#1. Preserving the Extended File Attribute
## I haven't found a way to preserve the extended file attribute. I am using Debian GNU/Linux
## Bullseye with ext4 file system. Despite what some tutorials claim, neither rsync nor cp nor
## The tar or dar tools helped preserve the extended file attribute
## However, I kept the -"AX" and --rsync-path="/usr/bin/rsync --fake-super" options in the script
##
## If you find files with such attributes and want to save them to a file:
## $ find ~/ -type f -iname "fl0*" -exec lsattr {} + | grep  -v -- '-------------' \
## | sed -e 's/\(-\|e\)//g' > lsattr.lst


### Cycles
##-------------+----------------------------------------+----------------------------------------+
##            | First Cycle                            |  Next Cycle                            |
##            | ---------------------------------------+----------------------------------------+
##            | current (created e.g. Sun)             |  current (synced Mon)                  |
##            | |                                      |  |                                     |
##            | v                                      |  v                                     |
## Folders    | c  Mon  Tue  Wed  Thu  Fri  Sat  Sun   |  c  Tue  Wed  Thu  Fri  Sat  Sun  Mon  |
## Day number | 1   2    3    4    5    6    7    8    |  9   10   11   12   13   14   15   16  |
##-----------------------------------------------------+----------------------------------------+

## The order of the course: The 1. Cycle
## Initial full backup
## 1. On the 1st day
## We start the first day with an initial full backup by filling the "current" folder.
## Rsync is used for this in this script. However, since rsync is usually of
## no use here, "cp -apr" command can be used instead. unless there is a reason to use rsync.

## From the 2nd day to the 8th day
## We create the folders named after each day with abbreviated weekday name accordingly
## to the pattern "$(date +%a)", which can also be represented by a variable.
## These folders are named after each day with abbreviated weekday name for
## today's day.
## Let us assume that today is Monday, backups folder will be "Mon/"
## then we will have backups folder as next:
## on 3nd day the "Tue/" and so on till the 8th day that will be Sunday and the folder created is "Sun".

## On the 9th day it's the "current" folder's turn.

## In the first cycle the folder must have been created before the synchronization.
## Unless the folder therefor in nested nested path, the creation can be implicitly
## done. This script create the folder explicitly, which maybe advantageous in some cases.

## The order of the course: Repetition cycle.
## This is the cycle from the first iteration and repeats as long as we backup content.
## Affected folders in these cycles are always once the "current"folder and 7 times the daily
## weekday folder.
### The criteria that characterize the Repetition cycle:
## 1. Exists the "current" folder and is not empty
## 2. The number of daily backup folders are 0-7 beside the "current" folder.
## 3. At the beginning of the first repeat cycle, the oldest folder must not be older than 8 days
## if the backup has not been paused
## If this is our first iteration, it starts with day 8 by syncing the "current" folder.
## The next day we sync the daily weekday folder "$(date +%a)" this will be "Mon"
## if we started our weekday backup on a Monday.
## We're just making sure the appropriate folder exists so we can start syncing.

## Sources of error
## If the backup process stopped for a while, but new data was produced, then
## it can make it difficult to restore the content in chronological order.
## At least the modification time (on the EXT file system of Linux) differs and
## if we rely on it, we can get unexpected results.
## It is questionable whether it would not be better to start over with the backup.

## prerequisite for synchronization
## The one-time creation of the "current" folder and the creation of the daily weekday folder is a
## prerequisite for synchronization.

# Synchronizing incrementally & hard link
## The daily folders are synchronized incrementally, i.e. the existing files and folders in the "current"
## folder are not copied to the daily folder again, but linked via hard link.
##  using the --link-dest option to point to the previous backup so that unchanged files are hard linked to there.
## The hard links are preserved even if the "current" folder is deleted
## The new content that is not in the "current" folder moves to the folder of the respective day of the
## week "$(date +%a)".

# Restoring the Backups:
## As a rule, we restore the backup to the full extent in sequence. I.e. the older the
## content, the sooner it will be restored. We’ll start the restore with "current" and then
## the contents of the weekday folder based on its age.
##  A quick rsync restore:
##  $ rsync -aruv ./dest/* ./src

# eject command
## The command: ``sudo eject -v /media/sg`` doesn't work

# Notes about work logic, syntax and semantic if you adjust the path.
## Make sure paths don't accumulate through chattered assignments, become empty through
## unreliability, and unintentionally apply to dangerous paths.
##-----------------------------------------------------------------------------------------------------

# To verify that the platform we're running the script on is the correct device, I check a device's specific
# property. Here's the main nvme disk is such a property. Note here that '\"' is used to escape the delimiter '"'.
# Check the platform by checking the main nvme disk. the Delimiter is masked '\"'
if [ "$(sudo blkid $srcDvc | awk -F\" '{print $2}')" == $dvcID ]; then
	d=$?; echo "It is the lnb, value is: $d";
else
	echo
  "NOT the lnb, if that's what you want, then adjust the path (lnb-home) accordingly. Now the script will exit"
	exit 1
fi

######## Array
# To be able to use more than one drive to back up contents the array can be expanded
declare -A dvc; dvc[node]=sdb2; dvc[label]=lnx; dvc[uuid]=0a524df6-5863-45d3-b6d8-d00e23f9bd4e; \
dvc[prtUuid]=30e4d5f7-02;
#dvc[node2]=sdb1;dvc[label2]=bundUSB; dvc[uuid2]=0a6344e2-003e-4215-8915-b65c1646bbaf;
#------

# To ensure that the external hard drive we are going to use is available :
dvcLsblk=$(lsblk -e7 | awk 'FNR == 4 {print $1}' | sed 's/└─//');
if [ "$(sudo blkid "/dev/$dvcLsblk" | awk -F\" '{print $4}')" == "${dvc[uuid]}" ]; then \
   echo "label is: $(sudo blkid "/dev/$dvcLsblk" | awk -F\" '{print $2}')"
else
   echo "The device doesn't seem to be available, maybe it's the wrong one or not connected!"
fi

# Is the filter rsync_lnb_HOME_filter present?
if [ ! -f "$SRC/$fltr" ]; then
   echo "The rsync_lnb_Home_filter is not found. If necessary, exit with ^C Ctrl+C to fix the problem"
   # exit 1
fi

# Is the external device already mounted and if so, where is it mounted?
if mount -l | grep -q "${dvc[node]}"; then
   mntNode=$(mount -l | awk '$1 ~ /sdb2/ { print $1 }'); mntOn=$(mount -l | awk 'ENDFILE{ print $3 }')
   printf "The device with node %s, must be %s and already mounted on %s \n" "${dvc[node]} before starting" "$mntNode" "$mntOn/"

    if [ ! -d /$mntPnt ]; then
        echo "${dvc[label]} mounted on wrong mntPnt";
	      sudo umount "$(mount -l | grep "${dvc[label]}" | awk '{print $3}')" && mnt=true; echo "umount done" || mnt=false;
        if [ "$mnt" == true ]; then
          sudo mount -U "${dvc[uuid]}" /$mntPnt;
          echo "${dvc[label]} must now mounted on /$mntPnt"
        fi
        if (($(mount -l | grep "${dvc[label]}" | awk '{print $3}' | wc -l) > 1)); then \
          echo "bind mount occurs:"; mount -l | grep "${dvc[label]}" | awk '{print $1 " on " $3}';
        fi
        echo "now manually mounted as $(mount -l | grep "${dvc[label]}" | awk '{print $1 " on " $3}')"
    fi
else
    sudo mount -U "${dvc[uuid]}" /$mntPnt
    echo "now manually mounted as $(mount -l | grep "${dvc[label]}" | awk '{print $1 " !! on " $3}')"
    dvc[node]=$(mount -l | grep "${dvc[label]}" | awk '{print $1}' | cut -d "/" -f 3)
    echo "dvc[node] is ${dvc[node]}"
fi
#

# [Note¹]

# Is the storage space (still) sufficient?
# dvcSz="$(df -h "/dev/${dvc[node]}" | awk '$1 ~ /dev/ { print $4 }' | awk '{sub(/T$/,""); print}')";
dvcSz="$(df -h "/dev/${dvc[node]}" | awk '$1 ~ /dev/ { print $4 }')";
bkpDUsg="$(sudo du -hs "$SRC" | awk '{ print $1 }')";
echo "capacity of ${dvc[node]} is now $dvcSz, this backup need $bkpDUsg "
#bkpDUsg="$(sudo du -hs "$SRC" | awk '{ print $1 }' | awk '{sub(/G$/,""); print}' )";
printf "Press ^C if you want to cancel\n"; for i in {1..20}; do sleep 1; printf "0%% \r $i"; done

# [Note²] Testing

### Initial Cycle:: 1. Creating "rsynclog" folder:
##==============================================
if [ ! -d /$mntPnt/$DST/rsynclog ]; then
	mkdir -pv /$mntPnt/$DST/rsynclog && echo "again /$mntPnt/$DST/rsynclog is created"
fi

### Initial Cycle:: 1. Creating and Filling "current" folder:
##=========================================================
if [ ! -d /$mntPnt/$DST/current ]; then
# Otherwise, if this were omitted, the shell would create it here implicitly.
 	mkdir -vp /$mntPnt/$DST/current  && echo "again /$mntPnt/$DST/current is created"
  printf "The content size of the source \"$SRC\" is %s while that of the target \"/$mntPnt/$DST/current\" is %s" \
  "$(du -sh "$SRC" | awk '{print $1}')" "$(du -sh "/$mntPnt/$DST/current" | awk '{print $1}')"

  b="$(echo ""; printf -- '-%.0s' {1..30}; echo "")"
  echo -e "We’ll sync as follow:$b
    rsync -aPpvuHhAXt --filter="exclude $fltr" --exclude-from=$fltr --rsync-path="/usr/bin/rsync --fake-super" --stats \
    --filter="exclude $fltr" --exclude-from=$fltr $SRC/ /$mntPnt/$DST/current/
  $b"

  printf "Press ^C if you want to cancel\n";
  for i in {1..10}; do sleep 1; printf "0%% \r $i"; done

  rsync -aPpvuHhAXt --filter="exclude $fltr" --exclude-from=$fltr --rsync-path="/usr/bin/rsync --fake-super" --stats \
  --filter="exclude $fltr" --exclude-from=$fltr "$SRC"/ /$mntPnt/$DST/current/
fi

### Initial Cycle:: 2. Creating and Filling the today's weekday folder (every day):
##===============================================================================
## and the $wdy folder doesn't yet exist, then create it:


## If the "current" folder, exists, isn't empty (arbitrarily > 5) and the "current" folder more than 2 hours old
## and the "current" folder more than 0 days old, otherwise the $(date +%a) folder
##  will be synced right after the "current" folder is synced. If both folders are
##  synchronized at the same time, the $(date +%a) folder will not contain anything
##  other than what "current" folder has in terms of content. Ex.:
### mkdir -v dst/current2 && touch -d "2 hours ago" dst/current2

if [ -d /$mntPnt/$DST/current ] && (($(fdfind -d 2 . "/$mntPnt/$DST/current/" | wc -l) > 5 )) \
&& (($(fdfind -td "current" --changed-before 2h | wc -l) > 0 )); then
# # We need to anticipate synchronization and set the possibility for writing log now
# # Since /$mntPnt/$DST/rsynclog is already created we can created the log file in it.
  if [ ! -f "/$mntPnt/$DST/rsynclog/$wdy.log" ]; then
    touch -- "/$mntPnt/$DST/rsynclog/$wdy.log" && echo "/$mntPnt/$DST/rsynclog/$wdy.log is created" || echo "$wdy.log exists already"
  fi
  if [ ! -d /$mntPnt/$DST/"$wdy" ]; then
    mkdir -pv /$mntPnt/$DST/"$wdy" && echo "yes /$mntPnt/$DST/$wdy is created" || echo "yes /$mntPnt/$DST/$wdy exists already"
  fi

  # check path
  b="$(echo ""; printf -- '-%.0s' {1..30}; echo "")"
  echo -e "We’ll sync as follow:$b
  rsync -aPpvuHhAXt --delete --filter="exclude $fltr"  --exclude-from=$fltr --rsync-path="/usr/bin/rsync --fake-super" --stats \
  --link-dest="/$mntPnt/$DST/current"  --log-file="/$mntPnt/$DST/rsynclog/"$wdy"".log $SRC/ /$mntPnt/$DST/$wdy/
  $b"

  printf "\n again %s \e[7m --link-dest="/$mntPnt/$DST/current" \e[0m ...  \e[7m $SRC/ \e[0m .. \e[7m  /$mntPnt/$DST/$wdy/\e[0m ...\n"

  printf "Press ^C if you want to cancel\n";
  for i in {1..20}; do sleep 1; printf "0%% \r $i"; done

  rsync -aPpvuHhAXt --delete --filter="exclude $fltr"  --exclude-from=$fltr --rsync-path="/usr/bin/rsync --fake-super" --stats \
  --link-dest="/$mntPnt/$DST/current"  --log-file="/$mntPnt/$DST/rsynclog/$wdy".log "$SRC"/ /$mntPnt/$DST/"$wdy"/
fi

## dry-run: rsync -apvn /$mntPnt/$DST/current/ $DST/"$wdy"/

### Next cycle:: 1. Syncing the "current" folder.
##=============================================================


##We recognize the new cycle every day by the fact that the respective today's folder is not empty and is 10 days old. As
##a weekday folder we describe its age comparison as follows:

#---
# Is the current folder is present and at least before 7 days?
# # Actually at this time of check it must be 8 days old.            AND
# Is the current folder is not empty (arbitrarily has > 5 items).    AND
# Is there a 7 days old weekday backup folder. Actually at
# # this time of check it must be 8 days old.                        AND
# Are there more than 6 weekday backup folders?
# # Actually at this time of check they must be 7 folders.

if [[ "$(fdfind -td -d 1 --regex '^current' --changed-before 7d /$mntPnt/$DST/)" ]] && \
(($(fdfind -d 2 . "/$mntPnt/$DST/current/" | wc -l) > 5 )) && \
[[ "$(fdfind --regex '^[A-W]+[a-z]{2}$' --changed-before 7d /$mntPnt/$DST/)" ]] && \
(($(fdfind --regex '^[A-W]+[a-z]{2}$' /$mntPnt/$DST/ | wc -l) > 6 )); then
  echo "The current folder exists, 7 days old, not empty (with > 5), there is a 7 days weekday old folder and 7 weekday folders".



    echo "7 weekday folders are found, "/$mntPnt/$DST/current" will be synced";
# ## First delete the respective log file of the day
    if [ -f "/$mntPnt/$DST/rsynclog/current.log" ]; then "rm" "/$mntPnt/$DST/rsynclog/current.log"; fi
    # Create a new log file to be able to log:
    touch -- "/$mntPnt/$DST/rsynclog/current.log" && echo "/$mntPnt/$DST/rsynclog/current.log is created"

    b="$(echo ""; printf -- '-%.0s' {1..30}; echo "")"
    echo -e "We’ll sync as follow:$b
    rsync -aPpvuHhAXt --delete --filter="exclude $fltr"  --exclude-from=$fltr --rsync-path="/usr/bin/rsync --fake-super" --stats --log-file="/$mntPnt/$DST/rsynclog/current".log
    $SRC/ /$mntPnt/$DST/current/
    $b"

    printf "Press ^C if you want to cancel\n";
    for i in {1..20}; do sleep 1; printf "0%% \r $i"; done

    rsync -aPpvuHhAXt --delete --filter="exclude $fltr"  --exclude-from=$fltr --rsync-path="/usr/bin/rsync --fake-super" --stats --log-file="/$mntPnt/$DST/rsynclog/current".log  "$SRC"/ /$mntPnt/$DST/current/
fi

# Now this is how to do:
# $ date
# Thu 11 May 2023 11:26:46 PM CEST
# The Date to required can only relay on modification time xx?
# $ fdfind -td -d 1 --regex '^current$'  --changed-before 0d .
#   current
# ? # that said how to say 7 days old?
# $ for i in *; do echo "$(stat -c %n $i), $(stat -c %y $i | cut -d' ' -f1)"; done
# Thu, 2023-05-04
# Fri, 2023-05-05
# Mon, 2023-05-08
# Sat, 2023-05-06
# Sun, 2023-05-07
# Tue, 2023-05-09
# Wed, 2023-05-10

# Since we've today Sat, 2023-05-13:01:35, the oldest weekday dir is the previous Sat 2023-05-05, thus xxx?
# current's modification time must have been the day before
# touch -d "2023-05-05 01:18" current
#---

### Next cycle:: 2. Syncing the today's weekday folder (every day):
##===================================================================================
##We recognize the new cycle every day by the fact that the respective today's folder is not empty and is 10 days old. As
##a weekday folder we describe its age comparison as follows:
if [[ "/$mntPnt/$DST/$(date --date="7 days ago" +"%a")" == "$(fdfind --regex '[A-W]+[a-z]{2}' --changed-before 7d /$mntPnt/$DST/)" ]]; then
    rlct="$(fdfind --regex '[A-W]+[a-z]{2}' --changed-before 7d /$mntPnt/$DST/)" &&  echo "7 days old weekday folder \"${rlct:?}\" exists."
    echo "The 7 day old folder ${rlct:?} is not empty because it contains more than 3 files/folders (arbitrarily > 3)."

## First delete the respective log file of the day
    if [ -f "/$mntPnt/$DST/rsynclog/$wdy.log" ]; then "rm" "/$mntPnt/$DST/rsynclog/$wdy.log"; fi
#     # Create a new log file to be able to log:
      touch -- "/$mntPnt/$DST/rsynclog/$wdy.log" && echo "/$mntPnt/$DST/rsynclog/$wdy.log is created"

#     # The creation of the log file is only repeated because inexplicable errors and subsequent errors occur at runtime:
#     # I assume the reason is elsewhere --delete
#     # Err. # rsync: [client] failed to open log-file lnb-home/rsynclog/Tue.log: No such file or directory (2)
#       # Err. # Ignoring "log file" setting.
      if [ ! -f "/$mntPnt/$DST/rsynclog/$wdy.log" ]; then touch "/$mntPnt/$DST/rsynclog/$wdy.log" && \
      echo "$wdy.log is created on the 2nd pass"; fi

      b="$(echo ""; printf -- '-%.0s' {1..30}; echo "")"
      echo -e "We’ll sync as follow:$b

      rsync -aPpvuHhAXt --rsync-path="/usr/bin/rsync --fake-super" --stats \
      --link-dest=/$mntPnt/$DST/current --filter="exclude $fltr"  --exclude-from=$fltr \
      --log-file=/$mntPnt/$DST/rsynclog/$wdy.log $SRC/ $DST/$wdy/
    $b"

    printf "Press ^C to cancel\n"
    for i in {1..20}; do sleep 1; printf "0%% \r $i"; done

    rsync -aPpvuHhAXt --rsync-path="/usr/bin/rsync --fake-super" --stats \
    --link-dest="/$mntPnt/$DST/current" --filter="exclude $fltr"  --exclude-from=$fltr \
    --log-file="/$mntPnt/$DST/rsynclog/$wdy".log "$SRC"/ $DST/"$wdy"/
fi

## [Note³]
## [Note⁴]

b="$(echo ""; printf -- '-%.0s' {1..30}; echo "")"
echo "Random Sample"
slsts="$SRC/it/lists";
if [ -d "$slsts" ]; then
   {
    echo -e "$b
    # Home Backup
    $b"
    echo -e "$(date +%a-%b-%d-%Y_%H-%M) :\n\n"
    echo -e "\ndiff -rq $slsts /$mntPnt/$DST/current/it/lists :\n";
    diff -rq "$slsts" /$mntPnt/$DST/current/it/lists
    echo -e "$b
    # md5deep verify md5
    $b"
    md5deep -rl "$slsts" | head -3 > /$mntPnt/$DST/rsynclog/crnt_lists.dm5
    md5sum -c /$mntPnt/$DST/rsynclog/crnt_lists.dm5
   } >> /$mntPnt/$DST/rsynclog/crnt_diff_slsts.log

   {
    echo -e "$b
    # Home Backup
    $b"
    echo -e "$(date +%a-%b-%d-%Y_%H-%M) :\n\n"
    echo -e "\ndiff -rq $slsts /$mntPnt/$DST/$wdy/it/lists :\n";
    diff -rq "$slsts" /$mntPnt/$DST/"$wdy"/it/lists
    echo -e "$b
    # md5deep verify md5
    $b"
    md5deep -rl "$slsts" | tail -3 > /$mntPnt/$DST/rsynclog/"$wdy"_lists.dm5
    md5sum -c /$mntPnt/$DST/rsynclog/"$wdy"_lists.dm5
    echo -e "\n\n"
   } >> /$mntPnt/$DST/rsynclog/"$wdy"_diff_slsts.log

  else
   printf " No data transfer took place";
fi

printf "Cat crnt_diff_slsts.log:\n\n%s\n" "$(cat /$mntPnt/$DST/rsynclog/crnt_diff_slsts.log)"
printf "Cat "$wdy"_diff_slsts.log:\n\n%s\s" "$(cat /$mntPnt/$DST/rsynclog/"$wdy"_diff_slsts.log)"

echo -e "\ncurrent folder has $(find /$mntPnt/$DST/current/* -type f -links +1 | wc -l) hard links"

for i in $(fdfind -d 1 -td --regex '[A-W]+[a-z]{2}' /$mntPnt/$DST/); do \
echo "$i has $(find "${i}"/* -type f -links +1 | wc -l) hard links"; done

echo "The size of parent folder $(du -sh /$mntPnt/$DST/)"

##=== END OF THE SCRIPT ================

### - Notes::
## ========

# Check a success syncing by having an Overview with:
## $ ls -RF

# Testing check
## $ date
##   Mon 17 Apr 2023 12:01:18 PM CEST
## $ touch -d "7 days ago" "$(date +%a -d "-7 days").log"
## $ ls -l "$(date +%a -d "-7 days").log"
##   -rw-r--r-- 1 user user 0 Apr 10 11:57 Mon.log

# Explanatory representation:
##   ┌─────── cmd ──────┐     ┌──── filename ────┐
## $ touch -d "7 days ago" "$(date +%a -d "-7 days").log"
## Which is the same as:
## $ touch -d "7 days ago" "$(date +%a).log"
## Or:
## $ touch -d "7 days ago" Mon.log

# find contents according to their age
## $ mkdir -v xmple{01..03}
##   mkdir: created directory 'xmple01'
##   mkdir: created directory 'xmple02'
##   mkdir: created directory 'xmple03'

## $ touch -d "7 days ago" xmple0*
## $ find . -type d -mtime +6
##   ./xmple01
##   ./xmple02
##   ./xmple03

# Remove non-empty folders with "find.* -delete" instead of "rm -rf"
## In stressful situations, I have had disastrous experiences with the
## "rm -rf" command. I only use it in modified form. A good alternative
## is the "find" command with the "-delete" option
##
## $ mkdir -v xmple{01..02}
##   mkdir: created directory 'xmple01'
##   mkdir: created directory 'xmple02'
##
## $ fortune | tee xmple0{1,2}/fl0{01..04}.txt
##   Q:      What do you call a WASP who doesn't work for his father, isn't a
##   ...
##
## $ ls -R
##   .:
##   xmple01  xmple02
##   ./xmple01:
##   fl001.txt  fl002.txt  fl003.txt  fl004.txt
##   ./xmple02:
##   fl001.txt  fl002.txt  fl003.txt  fl004.txt
##
## $ find . -name "*" -delete
## $ ls -l
##   total 0

# Check the hard links
## $ ls -l dst/current  | wc -l
##   14
## $ ls -l dst/Sat  | wc -l
##   17
## The number 17 is because 3 new files/folders were added in the dst/Sat folder
## When we moved the new contents elsewhere
## $ mv dst/Sat/fl0* deli/
## $ ls -l dst/Sat  | wc -l
##   14
## $ du -sh dst/current dst/Sat

## The original files of the "current" folder with their original size illustrate the change of file types
## that took place in "dst/sat" folder when we compare both.
## The comparison showed that the hard links in the "dst/Sat" folder are smaller than the original files.
##   100K    dst/current
##   8.0K    dst/Sat

## Besides the hard links have the same inode number that represents the original file
## $ ls -i Sat/
##   20319050 fl01.txt  20319126 fl02.txt  20319127 fl03.txt  20319128 fl04.txt
## Needless to say that the hard links have the same content as the original files

# (In a context of testing)
# Verifying the md5sum of source
## $ md5deep -rl ~/it/lists > /$mntPnt/$DST/slist.md5;
## user@lnb:/tmp/tmpi$ md5sum -c /$mntPnt/$DST/slist.md5
## /home/user/it/lists/03.12.md: OK
## /home/user/it/lists/tab29.08: OK

## [Note¹]
## When in the GUI of Dolphin, the KDE's file manager, the label "lnx" is clicked, the /dev/sdb2 will also be mounted on the mount path /nono.

# [Note²]
# (According to the calender)
# (In a context of testing)
# Mockup of the daily backup folders created in a week and named by abbreviated weekday names
## $ for i in {1..7}; do mkdir "$(date +%a -d "-$i days")" && touch -d "$i days ago" "$(date +%a -d "-$i days")"; done
## $ ls -lt | awk '{print $6, $7, $9}' | sed -z 's/\n/, /g;s/,$/\n/'
##   , May 2 Tue, May 1 Mon, Apr 30 Sun, Apr 29 Sat, Apr 28 Fri, Apr 27 Thu, Apr 26 Wed

## $ date
##   Tue 02 May 2023 10:49:10 PM CEST
##
## $ for i in {1..7}; do set -x mkdir "$(date +%a -d "-$i days")" && touch -d "$i days ago" "$(date +%a -d "-$i days")"; done; set +x
##   ++ date +%a -d '-1 days'
##   + touch -d '1 days ago' Mon
##   + for i in {1..7}
##   ++ date +%a -d '-2 days'
##   + set -x mkdir Sun
##   ++ date +%a -d '-2 days'
##   + touch -d '2 days ago' Sun
##   ... truncated
##   ++ date +%a -d '-7 days'
##   + touch -d '7 days ago' Tue
##   + set +x

## [Note³]
## Mocking up $rlct
##  date --date="today" +"%F"
##   2023-04-07
##
##  date --date="7 days ago" +"%F"
##    2023-03-31

# Test
#|if ...|
## if [[ -n $(find dst/ -name "current" -mtime +6) ]]; then echo y; else echo n; fi             n
## if [ $(find dst/ -name "current" -mtime +6 | wc -l) -gt 0 ]; then echo y; else echo n; fi    n
## if [ $(fdfind -d 2 -td -i current --changed-before 7d "dst/" | wc -l) -gt 0 ]; then echo y; else echo n; fi    n
## if [[ -n $(fdfind -d 2 -td -i current --changed-before 7d "dst/") ]]; then echo y; else echo n; fi
## n
## if [[ -n $(fdfind -d 2 -td -i current --changed-before 7d .) ]]; then echo y; else echo n; fi
## y

##delete
#if [ "$(find dst/ -name "current" -mtime +6 | wc -l)" -gt 0 ]; then
#  echo "current found";
#  if (( $(fdfind --regex '[A-W]+[a-z]{2}' "dst/" | wc -l) > 6 )); then
#    echo "7 weekday folders found too";
#    else
#     echo "No weekday folders found";
#  fi
#else
#   echo "No current found too";
#fi

##
## $ ls dst
##   current  Fri  Mon  Sat  Sun  Thu  Tue  Wed
## $ if ...
##   dst/current
##   current found
##   7 weekday folders found too
### $ mv -v dst/current .
###   renamed 'dst/current' -> './current'

### $ fdfind --regex '[A-W]+[a-z]{2}' "dst/" -x mv -v {} .
#     renamed 'dst/Sat' -> './Sat'
#     renamed 'dst/Mon' -> './Mon'
#     renamed 'dst/Fri' -> './Fri'
#     renamed 'dst/Sun' -> './Sun'
#     renamed 'dst/Tue' -> './Tue'
#     renamed 'dst/Thu' -> './Thu'
#     renamed 'dst/Wed' -> './Wed'


# Bash: 'if' statement always seems to evaluate first condition as true even when false (Not confirmable )

# Bash IF statement Why aren't some nested conditions applied?
# Bash IF statement Why are the false conditions in the first nested IF evaluated as true

# [Note⁴]
## Why should a weekday folder lie around empty and still untreated?
#   if [ -d "$wdy" ] && files=$(ls -qAH -- "$wdy") && [ -z "$files" ]; then ..; fi # see R.rsync.tmp3.sh if necessary.

# During the boot process there was an error that I investigate with the following command:
# $ sudo dmesg -T --color=always --level=err,warn  | grep "none"
# [Mon May 15 16:50:54 2023] systemd-fstab-generator[420]: Mount point none is not a valid path, ignoring.

#The System add the last entry to fstab which cause the error:
#$ cat /etc/fstab
## /etc/fstab: static file system information.
## Use 'blkid' to print the universally unique identifier for a device; this may
## ... # truncated
##/dev/sdb1                                      none        ext4   users     0 0

## END ###########################################################################
