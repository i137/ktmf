#!/bin/bash
VER="3.2.2"

####################################################################################
# Only define the location of the config file here. Set the rest of the settings   #
# in ktmf.conf.                                                                    #
####################################################################################

config=/glftpd/bin/ktmf.conf

####################################################################################
# No changes below here should be needed, but you are free to play around ofcourse #
####################################################################################

## Read config file
if [ -r "$config" ]; then
  . $config
else
  echo "Can not find or read config file: $config defined in ktmf.sh. Check settings and permissions."
  exit 0
fi

## Argument test sets these modes:
if [ "$1" = "test" -o "$1" = "TEST" ]; then
  DEBUG="TRUE"
  TEST="TRUE"
  SHOWEXCLUDES="TRUE"
fi


####################################################################################
# General check if paths and files are correct.                                    #
####################################################################################

if [ "$DEBUG" = "TRUE" ]; then
  msg="DEBUG is ON."
  if [ "$TEST" = "TRUE" ]; then
    msg="$msg TEST is ON."
  else
    msg="$msg TEST is OFF."
  fi
  if [ "$SHOWEXCLUDES" = "TRUE" ]; then
    msg="$msg SHOWEXCLUDES: ON."
  else
    msg="$msg SHOWEXCLUDES: OFF."
  fi
  echo "--[ Welcome to KTMF $VER. $msg ]--"
  if [ "$DUALDL" = "TRUE" ]; then
    msg="DualDownload: ON."
  else
    msg="DualDownload: OFF."
  fi
  if [ "$DUALUP" = "TRUE" ]; then
    msg="$msg DualUpload: ON."
  else
    msg="$msg DualUpload: OFF."
  fi
  echo "+----------[ ModuleInfo: ]----------+"
  echo "  $msg"
  if [ "$SLOWDLKICK" = "TRUE" ]; then
    msg="SlowDownload: ON."
  else
    msg="SlowDownload: OFF."
  fi
  if [ "$SLOWULKICK" = "TRUE" ]; then
    msg="$msg SlowUpload: ON."
  else
    msg="$msg SlowUpload: OFF."
  fi
  echo "  $msg"
  if [ "$IDLEKILL" = "TRUE" ]; then
    msg="Idle Kill   : ON."
  else
    msg="Idle Kill   : OFF."
  fi
  if [ "$GENKICK" = "TRUE" ]; then
    msg="$msg Gen Kick  : ON."
  else
    msg="$msg Gen Kick  : OFF."
  fi
  echo "  $msg"
  echo "+-----------------------------------+"
fi

if [ "$UNDUPE" != "" ]; then
  if [ -x $UNDUPE ]; then
    OK="YEPP"
  else
    "echo Error: $UNDUPE does not exist or is not excutable."
    exit 0
  fi
fi

if [ "$UNDUPE" != "" ]; then
  CHECK="$( grep -w FLAGS $USERFOLDER/$UNDUPEUSER | grep -i c )"
  if [ "$CHECK" = "" ]; then
    echo "Error: UNDUPE is set, but user $UNDUPEUSER does not have flag C."
    exit 0
  fi
fi

if [ -e $GLLOG ]; then
  OK="YEPP"
else
  echo "Cant find log file $GLLOG. Check settings."
  exit 0
fi
  
if [ -e $WHOBIN ]; then
  OK=YEPP
else
  echo "Cant find $WHOBIN. Make sure its there and executable."
  exit 0
fi

touch $TEMPPATH/testtouch.tmp
if [ -e "$TEMPPATH/testtouch.tmp" ]; then
  rm -f $TEMPPATH/testtouch.tmp
else
  echo "Cant create files in $TEMPPATH. Check permissions."
  exit 0
fi

if [ -e "$BYEFOLDER" ]; then
  OK=YEPP
else
  echo "Cant find $BYEFOLDER for byefiles. Check settings."
  exit 0
fi

touch $BYEFOLDER/testtouch.tmp
if [ -e "$BYEFOLDER/testtouch.tmp" ]; then
  rm -f $BYEFOLDER/testtouch.tmp
else
  echo "Cant create files in $BYEFOLDER. Check permissions."
  exit 0
fi

touch $USERFOLDER/testtouch.tmp
if [ -e "$USERFOLDER/testtouch.tmp" ]; then
  rm -f $USERFOLDER/testtouch.tmp
else
  echo "Cant create files in $USERFOLDER. Check permissions."
  exit 0
fi

if [ "$LOG" != "" ]; then
  touch $LOG
  if [ -e "$LOG" ]; then
    OK="YEPP"
  else
    echo "Set to log to $LOG, but I cant find, or dont have access, to that file."
  fi
fi

if [ "$LOCKFILE" ]; then
  if [ -e "$LOCKFILE" ]; then
    if [ "`find \"$LOCKFILE\" -type f -mmin -60`" ]; then
      echo "Script already running. Delete $LOCKFILE if you are sure its not."
      echo "Otherwise it will be automatically removed once it is 60 mins old."
      exit 0
    else
      rm -f $LOCKFILE
    fi
  fi

  touch $LOCKFILE
  if [ ! -e $LOCKFILE ]; then
    echo "Cant create lockfile $LOCKFILE. Check settings and permissions."
    exit 0
  fi
fi

#####################################################################################
## Excluding from groups, if enabled,                                               #
#####################################################################################

if [ "$PREEXCLUDE" != "" ]; then
  for folder in `echo $PREEXCLUDE`; do
    if [ -e $folder ]; then
      cd $folder
      for affils in `ls`; do
        if [ "$GAFFILS" = "" ]; then
          GAFFILS="$affils"
        else
          GAFFILS="$affils|$GAFFILS"
        fi
      done
    else
      echo "Can not find path $folder defined in PREEXCLUDE. I will just skip that one."
    fi
  done
  if [ "$GAFFILS" != "" ]; then
    GEXCLUDE="$GEXCLUDE|$GAFFILS"
  fi
  GAFFILS="$( echo $GAFFILS | tr -s '|' ' ' )"
  if [ "$DEBUG" = "TRUE" ]; then
    echo "Based on PREEXCLUDE, users of the following groups will be totally excluded:"
    echo "$GAFFILS"
  fi
fi

if [ "$EXCLUDE" != "" ]; then
  if [ "$DUALEXCLUDE" != "" ]; then
    EXCLUDE1="$EXCLUDE|$DUALEXCLUDE"
  else
    EXCLUDE1="$EXCLUDE"
  fi
else
  if [ "$DUALEXCLUDE" != "" ]; then
    EXCLUDE1="$DUALEXCLUDE"
  else
    EXCLUDE1="$EXCLUDE"
  fi
fi

if [ "$EXCLUDE" != "" ]; then
  if [ "$IDLEEXCLUDE" != "" ]; then
    EXCLUDE2="$EXCLUDE|$IDLEEXCLUDE"
  else
    EXCLUDE2="$EXCLUDE"
  fi
else
  if [ "$IDLEEXCLUDE" != "" ]; then
    EXCLUDE2="$IDLEEXCLUDE"
  else
    EXCLUDE2="$EXCLUDE"
  fi
fi

if [ "$EXCLUDE" != "" ]; then
  if [ "$SLOWEXCLUDE" != "" ]; then
    EXCLUDE3="$EXCLUDE|$SLOWEXCLUDE"
  else
    EXCLUDE3="$EXCLUDE"
  fi
else
  if [ "$SLOWEXCLUDE" != "" ]; then
    EXCLUDE3="$SLOWEXCLUDE"
  else
    EXCLUDE3="$EXCLUDE"
  fi
fi

if [ "$EXCLUDE" != "" ]; then
  if [ "$DUALUPEXCLUDE" != "" ]; then
    EXCLUDE4="$EXCLUDE|$DUALUPEXCLUDE"
  else
    EXCLUDE4="$EXCLUDE"
  fi
else
  if [ "$DUALUPEXCLUDE" != "" ]; then
    EXCLUDE4="$DUALUPEXCLUDE"
  else
    EXCLUDE4="$EXCLUDE"
  fi
fi

if [ "$EXCLUDE" != "" ]; then
  if [ "$SLOWEXCLUDEUL" != "" ]; then
    EXCLUDE5="$EXCLUDE|$SLOWEXCLUDEUL"
  else
    EXCLUDE5="$EXCLUDE"
  fi
else
  if [ "$SLOWEXCLUDEUL" != "" ]; then
    EXCLUDE5="$SLOWEXCLUDEUL"
  else
    EXCLUDE5="$EXCLUDE"
  fi
fi

if [ "$EXCLUDE" != "" ]; then
  if [ "$GENEXCLUDE" != "" ]; then
    GENEXCLUDE="$GENEXCLUDE|$EXCLUDE"
  else
    GENEXCLUDE="$EXCLUDE"
  fi
fi

if [ "$GEXCLUDEON" = "TRUE" ]; then
  if [ "$DEBUG" = "TRUE" ]; then
    echo "Checking who is in what group, so we can exclude them. Hang on."
  fi

  cd $USERFOLDER

  if [ "$GEXCLUDE" = "" ]; then
    GEXCLUDE="G5E4GeGeg"
  fi
  if [ "$IDLEGEXCLUDE" = "" ]; then
    IDLEGEXCLUDE="FEfefEFE3874893"
  fi
  if [ "$SLOWGEXCLUDE" = "" ]; then
    SLOWGEXCLUDE="FKLjflkejlke3898"
  fi
  if [ "$DUALGEXCLUDE" = "" ]; then
    DUALGEXCLUDE="WTQqhqfF"
  fi
  if [ "$DUALUPGEXCLUDE" = "" ]; then
    DUALUPGEXCLUDE="3feFEFefE43"
  fi
  if [ "$SLOWGEXCLUDEUL" = "" ]; then
    SLOWGEXCLUDEUL="kwejEFE"
  fi

  DUALGEXCLUDE="$GEXCLUDE|$DUALGEXCLUDE"
  IDLEGEXCLUDE="$GEXCLUDE|$IDLEGEXCLUDE"
  SLOWGEXCLUDE="$GEXCLUDE|$SLOWGEXCLUDE"
  DUALUPGEXCLUDE="$GEXCLUDE|$DUALUPGEXCLUDE"
  SLOWGEXCLUDEUL="$GEXCLUDE|$SLOWGEXCLUDEUL"

  ## Making a lame fix.
  if [ -z "$FOLDEREX" ]; then
    FOLDEREX="qQw98654321"
  fi

  if [ "$DUALDL" = "TRUE" ]; then
    if [ "$DUALGEXCLUDE" != "" ]; then
      GROUPUSERS="$( egrep $DUALGEXCLUDE $USERFOLDER/* -s | grep -w GROUP | egrep -v $FOLDEREX | awk -F":" '{print $1}' )"
      for user in $GROUPUSERS; do
        user="$( echo $user | tr -s '/' ' ' )"
          for segment in $user; do
          temp="$segment"
        done
        if [ "$EXCLUDE1" ]; then
          EXCLUDE1="$EXCLUDE1|$temp"
        else
          EXCLUDE1="$temp"
        fi
      done
    fi
  fi

  if [ "$IDLEKILL" = "TRUE" ]; then
    if [ "$IDLEGEXCLUDE" ]; then
      GROUPUSERS="$( egrep $IDLEGEXCLUDE $USERFOLDER/* -s | grep -w GROUP | egrep -v $FOLDEREX | awk -F":" '{print $1}' )"
      for user in $GROUPUSERS; do
        user="$( echo $user | tr -s '/' ' ' )"
          for segment in $user; do
          temp="$segment"
        done
        if [ "$EXCLUDE2" ]; then
          EXCLUDE2="$EXCLUDE2|$temp"
        else
          EXCLUDE2="$temp"
        fi
      done
    fi
  fi

  if [ "$SLOWDLKICK" = "TRUE" ]; then
    if [ "$SLOWGEXCLUDE" ]; then
      GROUPUSERS="$( egrep $SLOWGEXCLUDE $USERFOLDER/* -s | grep -w GROUP | egrep -v $FOLDEREX | awk -F":" '{print $1}' )"
      for user in $GROUPUSERS; do
        user="$( echo $user | tr -s '/' ' ' )"
          for segment in $user; do
          temp="$segment"
        done
        if [ "$EXCLUDE3" ]; then
          EXCLUDE3="$EXCLUDE3|$temp"
        else
          EXCLUDE3="$temp"
        fi
      done
    fi
  fi

  if [ "$DUALUP" = "TRUE" ]; then
    if [ "$DUALUPGEXCLUDE" ]; then
      GROUPUSERS="$( egrep $DUALUPGEXCLUDE $USERFOLDER/* -s | grep -w GROUP | egrep -v $FOLDEREX | awk -F":" '{print $1}' )"
      for user in $GROUPUSERS; do
        user="$( echo $user | tr -s '/' ' ' )"
          for segment in $user; do
          temp="$segment"
        done
        if [ "$EXCLUDE4" ]; then
          EXCLUDE4="$EXCLUDE4|$temp"
        else
          EXCLUDE4="$temp"
        fi
      done
    fi
  fi

  if [ "$SLOWULKICK" = "TRUE" ]; then
    if [ "$SLOWGEXCLUDEUL" ]; then
      GROUPUSERS="$( egrep $SLOWGEXCLUDEUL $USERFOLDER/* -s | grep -w GROUP | egrep -v $FOLDEREX | awk -F":" '{print $1}' )"
      for user in $GROUPUSERS; do
        user="$( echo $user | tr -s '/' ' ' )"
          for segment in $user; do
          temp="$segment"
        done
        if [ "$EXCLUDE5" ]; then
          EXCLUDE5="$EXCLUDE5|$temp"
        else
          EXCLUDE5="$temp"
        fi
      done
    fi
  fi
fi

if [ -z "$EXCLUDE1" ]; then
  EXCLUDE1="NoBodyAtAll"
fi
if [ -z "$EXCLUDE2" ]; then
  EXCLUDE2="NoBodyAtAll"
fi

if [ -z "$EXCLUDE3" ]; then
  EXCLUDE3="NoBodyAtAll"
fi

if [ -z "$EXCLUDE4" ]; then
  EXCLUDE4="NoBodyAtAll"
fi

if [ -z "$EXCLUDE5" ]; then
  EXCLUDE5="NoBodyAtAll"
fi

#####################################################################################
## Dual Downloaders part.                                                           #
#####################################################################################

if [ "$DUALDL" = "TRUE" ]; then
  if [ "$DEBUG" = "TRUE" ]; then
    echo "-----------------------------------"
    echo "Start Dual DL kick part.           "
  fi

  unset LAST
  unset DUALS
  unset DUALS2
  
  if [ "$KILLGHOST" != "" ]; then
    $KILLGHOST
  fi

  USERSON="0"
  for online in `$WHOBIN | tr -d ' '`; do
    USERSON=$[$USERSON+1]
  done

  if [ "$USERSON" -lt "$LIMITTODUALKICK" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "Only $USERSON users online. Not running unless theres $LIMITTODUALKICK on."
    fi
    DUALGO="NO"
  else
    DUALGO="YES"
  fi

  if [ "$DEBUG" = "TRUE" ]; then
    if [ "$SHOWEXCLUDES" = "TRUE" ]; then
      if [ "$EXCLUDE1" ]; then
        EXCLUDE1VIEW="$( echo $EXCLUDE1 | tr -s '|' ' ' )"
        echo " "
        echo "Based on excludes from groups and users, the following users wont be checked:"
        echo "$EXCLUDE1VIEW"
        echo " "
      fi
    fi
  fi

  if [ "$DUALGO" = "YES" ]; then
    for u in `$WHOBIN | tr -d ' '| grep -w Dn: | sed -e 's/^-NEW-/NotLoggedIn/' | egrep -v $EXCLUDE1 | sort ` ;do
      USERNOW="$( echo $u | awk -F"^" '{print $1}')"
      if [ "$PREFOLDERS" ]; then
        for prefolder in $PREFOLDERS; do
          VERPREFOLDER="$( echo $u | grep -w $prefolder )"
          if [ "$VERPREFOLDER" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "$USERNOW is in $prefolder and wont be checked"
            fi
            INPREFOLDERDL="YES"
            USERNOW="$RANDOM"
          else
            INPREFOLDERDL="NO"
          fi
        done
        unset VERPREFOLDER
        unset prefolder
      fi
      if [ "$INPREFOLDERDL" != "YES" ]; then
        if [ "$USERNOW" = "$LAST" ]; then
          VERIFY="$( echo $DUALS | grep -w $USERNOW )"
          if [ -z "$VERIFY" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "$USERNOW is dual downloading"
            fi
            if [ "$BOTDUALDLW" = "TRUE" ]; then
              if [ -e "$USERFOLDER/$USERNOW" ]; then
                echo `date "+%a %b %e %T %Y"` KTMFDLW: \"$USERNOW\" \"$DELAYDUALDL\" >> $GLLOG
              fi
              if [ "$LOG" ]; then
                echo "$(date +%x' '%T): DUALDL: $USERNOW - Early warning for Dual downloading." >> $LOG
              fi
            fi
            if [ -e "$USERFOLDER/$USERNOW" ]; then
              DUALS="$USERNOW $DUALS"
            fi
          fi
        fi
        unset INPREFOLDERDL
      fi
      LAST=$USERNOW
    done

    if [ -z "$DUALS" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "No users dualling. Quitting dual DL part"
      fi
      NODUAL="TRUE"
    else
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Going to check $DUALS after $DELAYDUALDL seconds."
      fi
    fi
  
    unset PIDS
    unset VERIFY

    if [ "$NODUAL" != "TRUE" ]; then
      sleep $DELAYDUALDL
      unset LAST
      unset USERNOW

      if [ "$DEBUG" = "TRUE" ]; then
        echo "-------------------------"
      fi

      for user in `echo $DUALS`; do
        for u in `$WHOBIN | tr -d ' ' | grep -w Dn: | sed -e 's/^-NEW-/NotLoggedIn/' | grep -w $user | egrep -v $EXCLUDE1 | sort ` ;do
          USERNOW="$( echo $u | awk -F"^" '{print $1}')"
          USERPID="$( echo $u | awk -F"^" '{print $2}')"
          if [ ! -e "$USERFOLDER/$USERNOW" ]; then
            USERNOW="$RANDOM"
          fi

          if [ "$USERNOW" = "$LAST" ]; then
            VERIFY="$( echo $DUALS2 | grep $USERNOW )"
            if [ -z "$VERIFY" ]; then
              if [ "$BOTDUALDL" = "TRUE" ]; then
                echo `date "+%a %b %e %T %Y"` KTMFDL: \"$USERNOW\" >> $GLLOG   
              fi
              if [ "$LOG" ]; then
                echo "$(date +%x' '%T): DUALDL: $USERNOW kicked." >> $LOG
              fi
              if [ "$DEBUG" = "TRUE" ]; then
                echo "$USERNOW is still dual downloading"
              fi
              if [ "$CREDITLOSSDD" = "TRUE" ]; then
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "Taking $CREDITLOSSDDMB MB from $USERNOW"
                fi
                if [ "$LOG" ]; then
                  echo "$(date +%x' '%T): DUALDL: $USERNOW lost $CREDITLOSSDDMB MB creds." >> $LOG
                fi
                if [ "$TEST" != "TRUE" ]; then
                  CREDITLOSSKB=$[$CREDITLOSSDDMB*1024]
                  BEFORECREDS="$(cat $USERFOLDER/$USERNOW | grep "^CREDITS " | awk -F" " '{print $2}')"
                  AFTERCREDS=$[$BEFORECREDS-$CREDITLOSSKB]
                  sed -e "s/^CREDITS [0-9]* /CREDITS $AFTERCREDS /" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.tmp
                  cp -f $TEMPPATH/$USERNOW.tmp $USERFOLDER/$USERNOW
                  rm -f $TEMPPATH/$USERNOW.tmp
                fi
              fi
              if [ "$TAKE1LOGIN" = "TRUE" ]; then
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "Removing 1 login from $USERNOW"
                fi
                BEFORELOGINS="$( grep "^LOGINS " $USERFOLDER/$USERNOW | awk -F" " '{print $2}' )"
                if [ "$BEFORELOGINS" = "1" ]; then
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "$USERNOW only have 1 login left. Not removing any."
                  fi
                  if [ "$LOG" ]; then
                    echo "$(date +%x' '%T): DUALDL: $USERNOW looses 1 login. Had 1 already. Not touching." >> $LOG
                  fi
                else
                  if [ "$TEST" != "TRUE" ]; then
                    AFTERLOGINS=$[$BEFORELOGINS-1]
                    sed -e "s/^LOGINS $BEFORELOGINS/LOGINS $AFTERLOGINS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.tmp
                    cp -f $TEMPPATH/$USERNOW.tmp $USERFOLDER/$USERNOW
                    rm -f $TEMPPATH/$USERNOW.tmp
                  fi
                fi
              fi
              if [ "$TAKE1DL" = "TRUE" ]; then
                if [ "$LOG" ]; then
                  echo "$(date +%x' '%T): DUALDL: $USERNOW lost 1 download slot." >> $LOG
                fi
                unset AFTERDL
                TMP1="$( grep "^LOGINS " $USERFOLDER/$USERNOW | awk -F" " '{print $2}' )"
                TMP2="$( grep "^LOGINS " $USERFOLDER/$USERNOW | awk -F" " '{print $3}' )"
                BEFOREDL="$( grep "^LOGINS " $USERFOLDER/$USERNOW | awk -F" " '{print $4}' )"
                if [ "$BEFOREDL" = "-1" ]; then
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "Taking one download. User had unlimited so setting it to 1 instead"
                  fi
                  if [ "$LOG" ]; then
                    echo "$(date +%x' '%T): DUALDL: $USERNOW lost 1 download slot. Had -1, setting to 1." >> $LOG
                  fi
                  AFTERDL="1"
                  OLDSTRING="$TMP1 $TMP2 $BEFOREDL"
                  NEWSTRING="$TMP1 $TMP2 $AFTERDL"
                  if [ "$TEST" != "TRUE" ]; then
                    sed -e "s/^LOGINS $OLDSTRING/LOGINS $NEWSTRING/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.tmp
                    cp -f $TEMPPATH/$USERNOW.tmp $USERFOLDER/$USERNOW
                    rm -f $TEMPPATH/$USERNOW.tmp
                  fi
                else
                  if [ "$BEFOREDL" = "1" ]; then
                    if [ "$DEBUG" = "TRUE" ]; then
                      echo "$USERNOW already have 1 sim down (weird since he did dual dl). Wont touch him."
                    fi
                    if [ "$LOG" ]; then
                      echo "$(date +%x' '%T): DUALDL: $USERNOW looses 1 max_sim_down. Already had 1. Not touching." >> $LOG
                    fi
                  else
                    AFTERDL=$[$BEFOREDL-1]
                    if [ "$DEBUG" = "TRUE" ]; then
                      echo "Taking 1 max_sim_down from $USERNOW ( from $BEFOREDL to $AFTERDL )."
                    fi
                    if [ "$LOG" ]; then
                      echo "$(date +%x' '%T): DUALDL: $USERNOW lost 1 max_sim_down. From $BEFOREDL to $AFTERDL." >> $LOG
                    fi
                    OLDSTRING="$TMP1 $TMP2 $BEFOREDL"
                    NEWSTRING="$TMP1 $TMP2 $AFTERDL"
                    if [ "$TEST" != "TRUE" ]; then
                      sed -e "s/^LOGINS $OLDSTRING/LOGINS $NEWSTRING/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.tmp
                      cp -f $TEMPPATH/$USERNOW.tmp $USERFOLDER/$USERNOW
                      rm -f $TEMPPATH/$USERNOW.tmp
                    fi
                  fi
                fi
              fi

              if [ "$BANDUAL" = "TRUE" ]; then
                if [ "$LASTBAN" != "$USERNOW" ]; then
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "Banning $USERNOW for $DUALBANTIME seconds."
                  fi
                  if [ "$LOG" ]; then
                    echo "$(date +%x' '%T): DUALDL: $USERNOW - Tempbanning for $DUALBANTIME seconds." >> $LOG
                  fi
                  if [ "$TEST" != "TRUE" ]; then
                  FLAGS="$( grep "^FLAGS " $USERFOLDER/$USERNOW | awk -F" " '{print $2}')"
                  CHECK="$( echo "$FLAGS" | grep "6" )"
                    if [ "$CHECK" ]; then
                      unset CHECK
                      if [ "$DEBUG" = "TRUE" ]; then
                        echo "$USERNOW - Already deleted. Will not delete again."
                        GOTBAN="$USERNOW $GOTBAN"
                      fi
                    else
                      if [ -e $USERFOLDER/$USERNOW ]; then
                        if [ "$DEBUG" = "TRUE" ]; then
                          echo "Putting ye oldie 6 flag on $USERNOW."
                        fi
                        if [ "$TEST" != "TRUE" ]; then
                          FLAGS="$( grep "^FLAGS " $USERFOLDER/$USERNOW | awk -F" " '{print $2}')"
                          sed -e "s/^FLAGS $FLAGS.*/FLAGS "$FLAGS"6/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
                          cp -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
                          rm -f $TEMPPATH/$USERNOW.new
                          GOTBAN="$USERNOW $GOTBAN"
                          echo "You were dual downloading. $DUALBANTIME seconds tempban." > $BYEFOLDER/$USERNOW.bye
                        fi
                      fi
                    fi
                  fi
                  LASTBAN=$USERNOW
                fi
              fi

              DUALS2="$USERNOW $DUALS2"
              PIDS="$USERPID $LASTPID $PIDS"

              if [ "$DEBUG" = "TRUE" ]; then
                echo "Going to kick $user - $PIDS"
              fi
              for pid in $PIDS;do
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "killing $pid now"
                  echo "---------------------"
                fi
                if [ "$TEST" != "TRUE" ]; then
                  kill $pid
                fi
              done
            else
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Also killing $USERPID now. Triple downloading?"
              fi
              if [ "$TEST" != "TRUE" ]; then
                kill $USERPID
              fi
            fi
          else
            unset PIDS
            unset PIDS2
          fi
          LASTPID=$USERPID
          LAST=$USERNOW
        done
      done
    fi

    if [ "$GOTBAN" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Waiting $DUALBANTIME seconds to readd banned dual download users."
      fi
      sleep $DUALBANTIME
      for user in $GOTBAN; do
        USERNOW="$user"
        if [ -e $BYEFOLDER/$user.bye ]; then
          if [ "$TEST" != "TRUE" ]; then
            rm -f $BYEFOLDER/$user.bye
          fi
        fi
        FLAGS="$( grep "^FLAGS " $USERFOLDER/$user | awk '{print $2}' )"
        VERIFY="$( echo "$FLAGS" | grep "6" )"
        if [ -z "$VERIFY" ]; then
          if [ "$DEBUG" = "TRUE" ]; then
            echo "No 6 flag on $user. Guess I never delled him."
          fi
        else
          if [ "$DEBUG" = "TRUE" ]; then
            echo "Removing 6 flag from $user"
          fi
          if [ "$LOG" ]; then
            echo "$(date +%x' '%T): DUALDL: Restoring tempban from $user." >> $LOG
          fi
          NEWFLAGS="$( echo "$FLAGS" | tr -d '6' )"
          sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
          cp -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
          rm -f $TEMPPATH/$USERNOW.new

          ## Verify that we really removed tempban.
          FLAGS="$( grep "^FLAGS " $USERFOLDER/$user | awk '{print $2}' )"
          VERIFY="$( echo "$FLAGS" | grep "6" )"
          if [ "$VERIFY" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Hm, user still got 6 flag. I might not have permissions now. Trying again."
            fi
            NEWFLAGS="$( echo "$FLAGS" | tr -d '6' )"
            sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
            cp -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
            rm -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW

            FLAGS="$( grep "^FLAGS " $USERFOLDER/$user | awk '{print $2}' )"
            VERIFY="$( echo "$FLAGS" | grep "6" )"
            if [ "$VERIFY" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Nope. Cant remove the 6 flag from $USERNOW. Check perms on userfiles."
              fi
              if [ "$LOG" ]; then
                echo "$(date +%x' '%T): DUALDL: ERROR. Cant remove tempban from $USERNOW." >> $LOG
              fi
            fi
          fi
        fi
      done
    fi
    unset LAST
    unset DUALS
    unset DUALS2
    unset LASTPID
    unset USERPID
    unset USERNOW
    unset u
    unset user
  fi
fi


#####################################################################################
## Dual Uploaders part.                                                             #
#####################################################################################

unset INPREFOLDERDL

if [ "$DUALUP" = "TRUE" ]; then
  if [ "$DEBUG" = "TRUE" ]; then
    echo ""
    echo "-----------------------------------"
    echo "Start Dual UP kick part.           "
  fi

  unset LAST
  unset DUALS
  unset DUALS2

  if [ "$KILLGHOST" ]; then
    $KILLGHOST
  fi

  USERSON="0"
  for online in `$WHOBIN | tr -d ' '`; do
    USERSON=$[$USERSON+1]
  done

  if [ "$USERSON" -lt "$LIMITTODUALUPKICK" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "Only $USERSON users online. Not running unless theres $LIMITTODUALUPKICK on."
    fi
    DUALUP="NO"
  else
    DUALUP="YES"
  fi 

  if [ "$DEBUG" = "TRUE" ]; then
    if [ "$SHOWEXCLUDES" = "TRUE" ]; then
      if [ "$EXCLUDE4" != "" ]; then
        EXCLUDE4VIEW="$( echo $EXCLUDE4 | tr -s '|' ' ' )"
        echo " "
        echo "Based on excludes from groups and users, the following users wont be checked:"
        echo "$EXCLUDE4VIEW"
        echo " "
      fi
    fi
  fi

  if [ "$DUALUP" = "YES" ]; then
    for u in `$WHOBIN | tr -d ' ' | grep -w Up: | sed -e 's/^-NEW-/NotLoggedIn/' | egrep -v $EXCLUDE4 | sort ` ;do
      USERNOW="$( echo $u | awk -F"^" '{print $1}')"
      if [ "$PREFOLDERS" != "" ]; then
        CHECKING="$( echo $PREUSERS | grep -w $USERNOW )"
        if [ "$CHECKING" = "" ]; then
          for prefolder in $PREFOLDERS; do
            VERPREFOLDER="$( echo $u | grep -w $prefolder )"
            if [ "$VERPREFOLDER" != "" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "$USERNOW is in $prefolder and wont be checked"
              fi
              INPREFOLDERDL="YES"
              PREUSERS="$USERNOW $PREUSERS"
            else
              INPREFOLDERDL="NO"
            fi
          done
        fi
        unset VERPREFOLDER
        unset prefolder
      fi

      if [ "$USERNOW" != "$LAST" ]; then
        UPFOLDER="$( echo $u | awk -F"^" '{print $5}' )"
        UPFOLDER="$( echo $UPFOLDER | tr -s '/' ' ' )"
      fi

      if [ "$CHECKING" ]; then
        INPREFOLDERDL="YES"
      fi

      if [ "$INPREFOLDERDL" != "YES" ]; then
        if [ ! -e "$USERFOLDER/$USERNOW" ]; then
          USERNOW="$RANDOM"
        fi
        if [ "$USERNOW" = "$LAST" ]; then
          UPFOLDER2="$( echo $u | awk -F"^" '{print $5}' )"
          UPFOLDER2="$( echo $UPFOLDER2 | tr -s '/' ' ' )"
  
          UPFOLDERNUMBER="$( echo "$UPFOLDER" | wc -w )"
          UPTO="0"
          for each in $UPFOLDER; do
            UPTO=$[$UPTO+1]
            if [ "$UPTO" = "1" ]; then
              somethinge=else
            else
              if [ "$UPTO" -lt "$UPFOLDERNUMBER" ]; then
                NEWUP="$NEWUP $each"
              fi
            fi
          done
          NEWUP="$( echo $NEWUP | tr -s ' ' '/' )"

          UPFOLDERNUMBER2="$( echo "$UPFOLDER2" | wc -w )"
          UPTO="0"
          for each in $UPFOLDER2; do
            UPTO=$[$UPTO+1]
            if [ "$UPTO" = "1" ]; then
              somethinge=else
            else
              if [ "$UPTO" -lt "$UPFOLDERNUMBER2" ]; then
                NEWUP2="$NEWUP2 $each"
              fi
            fi
          done
          NEWUP2="$( echo $NEWUP2 | tr -s ' ' '/' )"

          if [ "$NEWUP" = "$NEWUP2" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "$USERNOW is dual uploading in $NEWUP2"
            fi
            if [ "$BOTDUALUPW" = "TRUE" ]; then
              if [ -e "$USERFOLDER/$USERNOW" ]; then
                echo `date "+%a %b %e %T %Y"` KTMFULW: \"$USERNOW\" \"$NEWUP\" \"$DELAYDUALUP\" >> $GLLOG
              fi
              if [ "$LOG" ]; then
                echo "$(date +%x' '%T): DUALUP: $USERNOW - Early warning. Dual up in /$NEWUP" >> $LOG
              fi
            fi
            DUALUPS="$USERNOW $DUALUPS"
          fi
        else
          ## Not the same user. Reset dirs if set.
          unset NEWUP
          unset NEWUP2
        fi
      fi
      LAST="$USERNOW"
    done
  fi

  if [ -z "$DUALUPS" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "No users dual upping to the same release. Quitting Dual Upload kicker part"
      if [ -e $TEMPPATH/ktmfdualup.tmp ]; then
        rm -rf $TEMPPATH/ktmfdualup.tmp
      fi
    fi
    NODUALUP="TRUE"
  else
    if [ "$DEBUG" = "TRUE" ]; then
      echo "Going to check $DUALUPS after $DELAYDUALUP seconds."
    fi
  fi

  unset PIDS
  unset VERIFY
  unset USERNOW
  unset USERPID
  unset VERIFY
  unset NEWUP
  unset NEWUP2
  unset LAST
  
  if [ "$NODUALUP" != "TRUE" ]; then
    sleep $DELAYDUALUP
    unset LAST
    unset USERNOW

    if [ "$DEBUG" = "TRUE" ]; then
      echo "-------------------------"
    fi

    for user in $DUALUPS; do
      for u in `$WHOBIN | tr -d ' ' | grep -w Up: | sed -e 's/^-NEW-/NotLoggedIn/' | grep -w $user | egrep -v EXCLUDE4 | sort ` ;do
        USERNOW="$( echo $u | awk -F"^" '{print $1}')"
        DUALUPPIDS="$USERPID $DUALUPPIDS"        
        if [ "$USERNOW" != "$LAST" ]; then
          UPFOLDER="$( echo $u | awk -F"^" '{print $5}' )"
          UPFOLDER="$( echo $UPFOLDER | tr -s '/' ' ' )"
        fi
        if [ "$USERNOW" = "$LAST" ]; then
          UPFOLDER2="$( echo $u | awk -F"^" '{print $5}' )"
          UPFOLDER2="$( echo $UPFOLDER2 | tr -s '/' ' ' )"
          UPFOLDERNUMBER="$( echo "$UPFOLDER2" | wc -w )"
          UPTO="0"
          unset NEWUP
          for each in $UPFOLDER; do
            UPTO="$( expr $UPTO \+ 1 )"
            if [ "$UPTO" = "1" ]; then
              somethinge=else
            else
              if [ "$UPTO" -lt "$UPFOLDERNUMBER" ]; then
                NEWUP="$NEWUP $each"
              fi
            fi
          done
          NEWUP="$( echo $NEWUP | tr -s ' ' '/' )"

          UPFOLDERNUMBER2="$( echo "$UPFOLDER2" | wc -w )"
          UPTO="0"
          unset NEWUP2
          for each in $UPFOLDER2; do
            UPTO=$[$UPTO+1]
            if [ "$UPTO" = "1" ]; then
              somethinge=else
            else
              if [ "$UPTO" -lt "$UPFOLDERNUMBER2" ]; then
                NEWUP2="$NEWUP2 $each"
              fi
            fi
          done
          NEWUP2="$( echo $NEWUP2 | tr -s ' ' '/' )"

          if [ "$NEWUP" = "$NEWUP2" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "$USERNOW is still dual uploading in $NEWUP2"
            fi
            if [ "$LOG" ]; then
              echo "$(date +%x' '%T): DUALUP: $USERNOW kicked for dual up in /$NEWUP" >> $LOG
            fi
            if [ "$BOTDUALUP" = "TRUE" ]; then
              echo `date "+%a %b %e %T %Y"` KTMFUL: \"$USERNOW\" \"$NEWUP\" >> $GLLOG
            fi
            DUALUPSKICK="$USERNOW $DUALUPSKICK"
          fi
          unset INPREFOLDERDL
        fi 
        LAST="$USERNOW"
        unset NEWUP
        unset NEWUP2
      done
    done

    if [ "$DUALUPSKICK" ]; then
      unset DUALUPPIDS
      for userkick in $DUALUPSKICK; do
        for u in `$WHOBIN | tr -d ' ' | grep -w Up: | grep -w $userkick | sort`; do
          USERPID="$( echo $u | awk -F"^" '{print $2}')"
          DUALUPPIDS="$USERPID $DUALUPPIDS"
          WHAT="$( echo $u | awk -F"^" '{print $5}' )"
          WHATS="$WHAT $WHATS"
        done
      done
       
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Punishing users $DUALUPSKICK"
      fi

      if [ "$CREDITLOSSDU" = "TRUE" ]; then
        for loser in $DUALUPSKICK; do
          if [ "$DEBUG" = "TRUE" ]; then
            echo "Taking $CREDITLOSSDUMB MB from $loser"
          fi
          if [ "$LOG" ]; then
            echo "$(date +%x' '%T): DUALUP: $loser lost $CREDITLOSSDUMB MB" >> $LOG
          fi
          if [ "$TEST" != "TRUE" ]; then
            CREDITLOSSKB=$[$CREDITLOSSDUMB*1024]
            BEFORECREDS="$(cat $USERFOLDER/$loser | grep "^CREDITS " | awk -F" " '{print $2}')"
            AFTERCREDS=$[$BEFORECREDS-$CREDITLOSSKB]
            sed -e "s/^CREDITS [0-9]* /CREDITS $AFTERCREDS /" $USERFOLDER/$loser > $TEMPPATH/$loser.tmp
            cp -f $TEMPPATH/$loser.tmp $USERFOLDER/$loser
            rm -f $TEMPPATH/$loser.tmp
          fi
        done
      fi

      if [ "$TAKE1LOGINDU" = "TRUE" ]; then
        for loser in $DUALUPSKICK; do
          if [ "$DEBUG" = "TRUE" ]; then
            echo "Removing 1 login from $loser"
          fi
          if [ "$LOG" ]; then
            echo "$(date +%x' '%T): DUALUP: $loser lost 1 login slot." >> $LOG
          fi
          BEFORELOGINS="$( grep "^LOGINS " $USERFOLDER/$loser | awk -F" " '{print $2}' )"
          if [ "$BEFORELOGINS" = "1" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "$loser only have 1 login left. Not removing any."
            fi
          else
            if [ "$TEST" != "TRUE" ]; then
              AFTERLOGINS=$[$BEFORELOGINS-1]
              sed -e "s/^LOGINS $BEFORELOGINS/LOGINS $AFTERLOGINS/" $USERFOLDER/$loser > $TEMPPATH/$loser.tmp
              cp -f $TEMPPATH/$loser.tmp $USERFOLDER/$loser
              rm -f $TEMPPATH/$loser.tmp
            fi
          fi
        done
      fi

      if [ "$TAKE1UP" = "TRUE" ]; then
        for loser in $DUALUPSKICK; do
          unset AFTERUP
          TMP1="$( grep "^LOGINS " $USERFOLDER/$loser | awk -F" " '{print $2}')"
          TMP2="$( grep "^LOGINS " $USERFOLDER/$loser | awk -F" " '{print $3}')"
          TMP3="$( grep "^LOGINS " $USERFOLDER/$loser | awk -F" " '{print $4}')"
          BEFOREUP="$( grep "^LOGINS " $USERFOLDER/$loser | awk -F" " '{print $5}')"

          if [ "$BEFOREUP" = "-1" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Taking one upload from $loser. User had unlimited so setting it to 1 instead"
            fi
            if [ "$LOG" ]; then
              echo "$(date +%x' '%T): $loser looses 1 upload slot. Had unlimited. Setting 1." >> $LOG
            fi
            AFTERUP="1"
            OLDSTRING="$TMP1 $TMP2 $TMP3 $BEFOREUP"
            NEWSTRING="$TMP1 $TMP2 $TMP3 $AFTERUP"
            if [ "$TEST" != "TRUE" ]; then
              sed -e "s/^LOGINS $OLDSTRING/LOGINS $NEWSTRING/" $USERFOLDER/$loser > $TEMPPATH/$loser.tmp
              cp -f $TEMPPATH/$loser.tmp $USERFOLDER/$loser
              rm -f $TEMPPATH/$loser.tmp
            fi
          else
            if [ "$BEFOREUP" = "1" ]; then
               if [ "$DEBUG" = "TRUE" ]; then
                 echo "$loser already have 1 sim up (weird since he did dual up). Wont touch him."
               fi
               if [ "$LOG" ]; then
                 echo "$(date +%x' '%T): DUALUP: $loser looses 1 upload slot. Already had 1 (weird)." >> $LOG
               fi
            else
              AFTERUP=$[$BEFOREUP-1]
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Taking 1 max_sim_up from $loser ( from $BEFOREUP to $AFTERUP )."
              fi
              if [ "$LOG" ]; then
                echo "$(date +%x' '%T): DUALUP: $loser looses 1 upload slot. From $BEFOREUP to $AFTERUP." >> $LOG
              fi
              OLDSTRING="$TMP1 $TMP2 $TMP3 $BEFOREUP"
              NEWSTRING="$TMP1 $TMP2 $TMP3 $AFTERUP"
              if [ "$TEST" != "TRUE" ]; then
                sed -e "s/^LOGINS $OLDSTRING/LOGINS $NEWSTRING/" $USERFOLDER/$loser > $TEMPPATH/$loser.tmp
                cp -f $TEMPPATH/$loser.tmp $USERFOLDER/$loser
                rm -f $TEMPPATH/$loser.tmp
              fi
            fi
          fi
        done
      fi

      unset GOTBAN
      if [ "$BANDUALUP" = "TRUE" ]; then
        for loser in $DUALUPSKICK; do
          if [ "$LASTBAN" != "$loser" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Banning $loser for $DUALUPBANTIME seconds."
            fi
            if [ "$LOG" ]; then
              echo "$(date +%x' '%T): DUALUP: $loser gets tempbanned for $DUALUPBANTIME seconds." >> $LOG
            fi
            GOTBAN="$loser $GOTBAN"

            if [ "$TEST" != "TRUE" ]; then
              FLAGS="$( grep "^FLAGS " $USERFOLDER/$loser | awk -F" " '{print $2}' )"
              CHECK="$( echo "$FLAGS" | grep "6" )"
              if [ "$CHECK" ]; then
                unset CHECK
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "$loser - Already deleted. Will not delete again."
                fi
              else
                if [ -e "$USERFOLDER/$loser" ]; then
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "Putting ye oldie 6 flag on $loser."
                  fi
                  if [ "$TEST" != "TRUE" ]; then
                    FLAGS="$( grep "^FLAGS " $USERFOLDER/$loser | awk -F" " '{print $2}')"
                    sed -e "s/^FLAGS $FLAGS.*/FLAGS "$FLAGS"6/" $USERFOLDER/$loser > $TEMPPATH/$loser.new
                    cp -f $TEMPPATH/$loser.new $USERFOLDER/$loser
                    rm -f $TEMPPATH/$loser.new
                    GOTBAN="$loser $GOTBAN"
                    echo "You were dual uploading on the same release. $DUALUPBANTIME seconds tempban." > $BYEFOLDER/$loser.bye
                  fi
                fi
              fi
            fi
            LASTBAN=$loser
          fi
        done
      fi

      if [ "$DUALUPPIDS" ]; then
        if [ "$DEBUG" = "TRUE" ]; then
          echo "Pids to kick: $DUALUPPIDS"
        fi
        for pid in $DUALUPPIDS; do
          if [ "$DEBUG" = "TRUE" ]; then
            echo "Kicking $pid now."
          fi
          if [ "$TEST" != "TRUE" ]; then
            kill $pid
          fi
        done

        ## Delete and undupe files that were upped.
        for WHAT in $WHATS; do
          if [ -e "$GLROOT$WHAT" -a "$WHAT" != "" ]; then
            rm -f $GLROOT$WHAT
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Removing non complete file $WHAT"
            fi
            if [ "$UNDUPE" ]; then
              TEMPO="$( echo $WHAT | tr -s '/' ' ' )"
              for i in $TEMPO; do
                FILENAME="$i"
              done
              $UNDUPE -u $UNDUPEUSER -f $FILENAME >/dev/null 2>&1
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Unduping $FILENAME"
              fi
              if [ "$LOG" ]; then
                echo "$(date +%x' '%T): DUALUP: Removing & Unduping incomplete file $WHAT." >> $LOG
              fi
              unset FILENAME
              unset i
              unset TEMPO
            fi
          else
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Cant find $GLROOT$WHAT to delete (This means you have a good zipscript)."
            fi
          fi
        done
      fi

      if [ "$GOTBAN" ]; then
        if [ "$DEBUG" = "TRUE" ]; then
          echo "Waiting $DUALUPBANTIME seconds to readd banned dual upload users."
        fi
        sleep $DUALUPBANTIME
        for user in $DUALUPSKICK; do
          USERNOW="$user"
          if [ -e $BYEFOLDER/$user.bye ]; then
            if [ "$TEST" != "TRUE" ]; then
              rm -f $BYEFOLDER/$user.bye
            fi
          fi

          FLAGS="$( grep "^FLAGS " $USERFOLDER/$user | awk '{print $2}' )"
          VERIFY="$( echo "$FLAGS" | grep "6" )"
          if [ -z "$VERIFY" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "No 6 flag on $user. Guess I never delled him."
            fi
          else
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Removing 6 flag from $user"
            fi
            if [ "$LOG" ]; then
              echo "$(date +%x' '%T): DUALUP: Restoring tempban from $user." >> $LOG
            fi
            NEWFLAGS="$( echo "$FLAGS" | tr -d '6' )"
            sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
            cp -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
            rm -f $TEMPPATH/$USERNOW.new

            ## Verify that we really removed tempban.
            FLAGS="$( grep "^FLAGS " $USERFOLDER/$user | awk '{print $2}' )"
            VERIFY="$( echo "$FLAGS" | grep "6" )"
            if [ "$VERIFY" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Hm, user still got 6 flag. I might not have permissions now. Trying again."
              fi
              NEWFLAGS="$( echo "$FLAGS" | tr -d '6' )"
              sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
              cp -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
              rm -f $TEMPPATH/$USERNOW.new

              FLAGS="$( grep "^FLAGS " $USERFOLDER/$user | awk '{print $2}' )"
              VERIFY="$( echo "$FLAGS" | grep "6" )"
              if [ "$VERIFY" ]; then
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "Nope. Cant remove the 6 flag from $USERNOW. Check perms on userfiles."
                fi
                if [ "$LOG" ]; then
                  echo "$(date +%x' '%T): DUALUP: ERROR. Cant remove tempban from $USERNOW." >> $LOG
                fi
              fi
            fi
          fi
        done
      fi
    fi 
  fi    
  unset user
  unset USERNOW
  unset pid
  unset PIDS
  unset GOTBAN
  unset PIDS2
  unset VERIFY
fi


#####################################################################################
## Idle killer part.                                                                #
#####################################################################################


if [ "$IDLEKILL" = "TRUE" ]; then

  if [ "$DEBUG" = "TRUE" ]; then
    echo " "
    echo "-----------------------------------"
    echo "Start Idle kick part."
  fi

  if [ "$KILLGHOST" != "" ]; then
    $KILLGHOST
  fi

  USERSON="0"
  for online in `$WHOBIN | tr -d ' '`; do
    USERSON="$( expr "$USERSON" \+ "1" )"
  done

  if [ "$USERSON" -lt "$LIMITTOIDLEKICK" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "Only $USERSON users online. Not running unless theres $LIMITTOIDLEKICK on."
    fi
    IDLEGO="NO"
  else
    IDLEGO="YES"
  fi 

  if [ "$DEBUG" = "TRUE" ]; then
    if [ "$SHOWEXCLUDES" = "TRUE" ]; then
      if [ "$EXCLUDE2" != "" ]; then
      EXCLUDE2VIEW="$( echo $EXCLUDE2 | tr -s '|' ' ' )"
      echo " "
      echo "Based on excludes from groups and users, the following users wont be checked:"
      echo "$EXCLUDE2VIEW"
      echo " "
      fi
    fi
  fi

  LAST=""
  IDLES=""
  IDLES2=""
  VERIFY=""
  GOTBAN=""

  if [ "$IDLEGO" = "YES" ]; then
    for u in `$WHOBIN | tr -d ' ' | grep -w Idle: | sed -e 's/^-NEW-/NotLoggedIn/' | egrep -v $EXCLUDE2 | sort ` ;do
      USERNOW="$( echo $u | awk -F"^" '{print $1}')"
      if [ "$PREFOLDERS" != "" ]; then
        for prefolder in $PREFOLDERS; do
          VERPREFOLDER="$( echo $u | grep -w $prefolder )"
          if [ "$VERPREFOLDER" != "" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "$USERNOW: idle in $prefolder. Wont be checked."
            fi
            IDLEBEFORE="$( echo $IDLES | grep -w $USERNOW )"
            if [ "$IDLEBEFORE" != "" ]; then
              NEWIDLES=""
              for idlel in $IDLES; do
                rebuildcheck="$( echo $idlel | grep -w $USERNOW )"
                if [ "$rebuildcheck" = "" ]; then
                  NEWIDLES="$idlel $NEWIDLES"
                fi
              done
              IDLES="$NEWIDLES"
              NEWIDLES=""
            fi
            INPREFOLDERS="$USERNOW $INPREFOLDERS"
          fi
        done
        VERPREFOLDER=""
        prefolder=""
      fi

      ALREADYEXCLUDED="$( echo $INPREFOLDERS | grep -w $USERNOW )"
      if [ "$ALREADYEXCLUDED" = "" ]; then
        VERIFY="$( echo $IDLES | grep $USERNOW )"
        if [ -e "$USERFOLDER/$USERNOW" -o "$USERNOW" = "NotLoggedIn" ]; then
          ok=yes
        else
          VERIFY="$RANDOM"
        fi
        if [ "$VERIFY" = "" ]; then
          if [ "$BOTIDLEW" = "TRUE" ]; then
            echo `date "+%a %b %e %T %Y"` KTMFIDW: \"$USERNOW\" \"$DELAYIDLEKILL\" >> $GLLOG
            if [ "$LOG" != "" ]; then
              echo "$(date +%x' '%T): IDLE: $USERNOW got an early warning for idling." >> $LOG
            fi
          fi
          if [ "$DEBUG" = "TRUE" ]; then
            echo "$USERNOW is idle."
          fi
          IDLES="$USERNOW $IDLES"
        fi
      fi
      ALREADYEXCLUDED=""
      LAST=$USERNOW
    done

    if [ "$IDLES" = "" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "No users idle. Quitting Idle kicker part"
        if [ -e $TEMPPATH/ktmfidle.tmp ]; then
          rm -rf $TEMPPATH/ktmfidle.tmp
        fi
        NOIDLE="TRUE"
      fi
    else
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Going to check $IDLES after $DELAYIDLEKILL seconds."
      fi
    fi

    PIDS=""
    PIDS2=""
    VERIFY=""
    GOTBAN=""

    if [ "$NOIDLE" != "TRUE" ]; then
      sleep $DELAYIDLEKILL
      LAST=""
      USERNOW=""

      if [ "$DEBUG" = "TRUE" ]; then
        echo "-------------------------"
      fi

      for user in `echo $IDLES`; do
        for u in `$WHOBIN | tr -d ' ' | grep -w Idle: | sed -e 's/^-NEW-/NotLoggedIn/' | grep -w $user | egrep -v $EXCLUDE2 | sort ` ;do
          USERNOW="$( echo $u | awk -F"^" '{print $1}')"
          USERPID="$( echo $u | awk -F"^" '{print $2}')"
          if [ "$USERNOW" != "$LAST" ]; then
            VERIFY="$( echo $IDLES2 | grep $USERNOW )"
            if [ -z "$VERIFY" ]; then
              if [ "$BOTIDLE" = "TRUE" ]; then
                echo `date "+%a %b %e %T %Y"` KTMFID: \"$USERNOW\" >> $GLLOG
              fi
              if [ "$DEBUG" = "TRUE" ]; then
                echo "$USERNOW is still idle"
              fi
              if [ "$LOG" != "" ]; then
                echo "$(date +%x' '%T): IDLE: $USERNOW kicked for idling." >> $LOG
              fi
              if [ -e "$USERFOLDER/$USERNOW" ]; then
                touch $TEMPPATH/ktmfidle.tmp
                OLDIDLELISTVER="$(cat $TEMPPATH/ktmfidle.tmp | grep -w $user | awk -F" " '{print $1}')"
                if [ "$OLDIDLELISTVER" = "" ]; then
                  echo "$user 1" >> $TEMPPATH/ktmfidle.tmp
                  TIMESIDLE="1"
                else
                  TIMESIDLE="$(cat $TEMPPATH/ktmfidle.tmp | grep -w $user | awk -F" " '{print $2}')"
                  IDLENOW="$( expr "$TIMESIDLE" \+ "1" )"
                  sed -e "s/^$user.*/$user $IDLENOW/" $TEMPPATH/ktmfidle.tmp > $TEMPPATH/idles.tmp
                  mv -f $TEMPPATH/idles.tmp $TEMPPATH/ktmfidle.tmp
                fi
              fi
              IDLEUSERSKICKED="$user $IDLEUSERSKICKED"
              USERNOW=$user
              if [ "$CREDITLOSSIK" = "TRUE" -a "$USERNOW" != "NotLoggedIn" ]; then
                if [ "$TIMESIDLE" -lt "$TIMESBEFOREBANI" ]; then
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "$user has not yet idled enough times to loose creds."
                  fi
                  if [ "$LOG" != "" ]; then
                    echo "$(date +%x' '%T): IDLE: $USERNOW hasnt idled enough times to loose creds." >> $LOG
                  fi
                else
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "Taking $CREDITLOSSIKMB MB from $USERNOW"
                  fi
                  if [ "$LOG" != "" ]; then
                    echo "$(date +%x' '%T): IDLE: $USERNOW lost $CREDITLOSSIKMB MB credits." >> $LOG
                  fi
                  if [ "$TEST" != "TRUE" ]; then
                    CREDITLOSSKB="$( expr "$CREDITLOSSIKMB" \* "1024" )"
                    BEFORECREDS="$(cat $USERFOLDER/$USERNOW | grep -w CREDITS | awk -F" " '{print $2}')"
                    AFTERCREDS="$(expr "$BEFORECREDS" \- "$CREDITLOSSKB")"
                    sed -e "s/^CREDITS.*/CREDITS $AFTERCREDS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.tmp
                    mv -f $TEMPPATH/$USERNOW.tmp $USERFOLDER/$USERNOW
                  fi
                fi
              fi

              if [ "$BANIDLE" = "TRUE" -a "$USERNOW" != "NotLoggedIn" ]; then
                if [ "$TIMESIDLE" -lt "$TIMESTOBAN" ]; then
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "$user has not yet idled enough times to be banned."
                  fi
                  if [ "$LOG" != "" ]; then
                    echo "$(date +%x' '%T): IDLE: $user has not idled enough times to be tempbanned." >> $LOG
                  fi
                else
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "Banning $USERNOW for idling more then $TIMESTOBAN times."
                  fi
                  if [ "$LOG" != "" ]; then
                    echo "$(date +%x' '%T): IDLE: $USERNOW gets tempbanned for $IDLEBANTIME secs. Idle $TIMESTOBAN times in a row." >> $LOG
                  fi
                  if [ "$TEST" != "TRUE" ]; then
                    if [ "$LASTBAN" != "$USERNOW" ]; then
                      if [ "$DEBUG" = "TRUE" ]; then
                        echo "Banning $USERNOW for $IDLEBANTIME seconds."
                      fi
                      if [ "$TEST" != "TRUE" ]; then
                        FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
                        CHECK="$( echo $FLAGS | grep 6 )"
                        if [ "$CHECK" != "" ]; then
                          CHECK=""
                          if [ "$DEBUG" = "TRUE" ]; then
                            echo "$USERNOW - Already deleted. Will not delete again."
                          fi
                          GOTBAN="$USERNOW $GOTBAN"
                        else
                          if [ -e $USERFOLDER/$USERNOW ]; then
                            if [ "$DEBUG" = "TRUE" ]; then
                              echo "Putting ye oldie 6 flag on $USERNOW."
                            fi
                            FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
                            sed -e "s/^FLAGS $FLAGS.*/FLAGS "$FLAGS"6/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
                            mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
                            GOTBAN="$USERNOW $GOTBAN"
                            echo "You have idled $TIMESIDLE times in a row. Tempban initiated for $IDLEBANTIME seconds." > $BYEFOLDER/$USERNOW.bye
                          fi
                        fi
                      fi
                    fi
                  fi
                LASTBAN=$USERNOW
                fi
              fi

              PIDS="$USERPID"
              IDLES2="$USERNOW $IDLES2"

              if [ "$DEBUG" = "TRUE" ]; then
                echo "Going to kick $user - $PIDS"
              fi
              if [ "$TEST" != "TRUE" ]; then
                for pid in $PIDS; do
                  kill $pid
                done
              fi
            else
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Also killing $USERPID now. Triple idler?"
              fi
              if [ "$TEST" != "TRUE" ]; then
                kill $USERPID
              fi
            fi
          else
            p=""
            PIDS2=""
            PIDS=""
            USERPID2=""
          fi
          LASTPID=$USERPID
          LAST=$USERNOW
        done
      done
    fi
    LAST=""
    IDLES=""
    IDLES2=""
    LASTPID=""
    USERPID=""
    USERNOW=""
    u=""
    user=""

    if [ "$IDLEKILL" = "TRUE" ]; then
      for userskick in $IDLEUSERSKICKED; do
        if [ "$USERNOW" != "NotLoggedIn" ]; then
          touch $TEMPPATH/ktmfidle.tmp
          user="$userskick"
          USERNOW="$userskick"
          OLDIDLELISTVER="$(cat $TEMPPATH/ktmfidle.tmp | grep -w $userskick | awk -F" " '{print $1}')"
          TIMESIDLE="$(cat $TEMPPATH/ktmfidle.tmp | grep -w $userskick | awk -F" " '{print $2}')"
          if [ "$FIRSTIDLE" != "NO" ]; then
            echo "$userskick $TIMESIDLE" > $TEMPPATH/ktmf.tmp
            FIRSTIDLE="NO"  
          else
            echo "$userskick $TIMESIDLE" >> $TEMPPATH/ktmf.tmp
          fi  
        fi
      done

      if [ -e $TEMPPATH/ktmf.tmp ]; then 
        mv -f $TEMPPATH/ktmf.tmp $TEMPPATH/ktmfidle.tmp
      else
        rm -f $TEMPPATH/ktmf.tmp
      fi
    fi

    if [ "$GOTBAN" != "" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Waiting $IDLEBANTIME seconds to readd banned idle users."
      fi
      sleep $IDLEBANTIME
      for user in $GOTBAN; do
        if [ "$USERNOW" != "NotLoggedIn" ]; then
          USERNOW="$user"
          if [ -e $BYEFOLDER/$user.bye ]; then
            rm -f $BYEFOLDER/$user.bye
          fi

          FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
          VERIFY="$( echo $FLAGS | grep 6 )"
          if [ "$VERIFY" = "" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "No 6 flag on $user. Guess I never delled him."
            fi
          else
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Removing 6 flag from $user"
            fi
            if [ "$LOG" != "" ]; then
              echo "$(date +%x' '%T): IDLE: Restoring tempban from $user." >> $LOG
            fi
            NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
            sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
            mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW

            ## Verify that we really removed tempban.
            FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
            VERIFY="$( echo $FLAGS | grep 6 )"
            if [ "$VERIFY" != "" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Hm, user still got 6 flag. I might not have permissions now. Trying again."
              fi
              NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
              sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
              mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW

              FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
              VERIFY="$( echo $FLAGS | grep 6 )"
              if [ "$VERIFY" != "" ]; then
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "Nope. Cant remove the 6 flag from $USERNOW. Check perms on userfiles."
                fi
                if [ "$LOG" != "" ]; then
                  echo "$(date +%x' '%T): IDLE: ERROR. Cant remove tempban from $USERNOW." >> $LOG
                fi
              fi
            fi
          fi
        fi
      done
    fi
  fi
fi


#####################################################################################
## Slow Downloaders part                                                            #
#####################################################################################

GOTBAN=""
PIDS=""
PIDS2=""
USERSON="0"
TOCHECK=""
INPREFOLDERS=""

if [ "$SLOWDLKICK" = "TRUE" ]; then
  if [ "$DEBUG" = "TRUE" ]; then
    echo " "
    echo "-----------------------------------"
    echo "Start Slow download kick part.     "
  fi

  if [ "$KILLGHOST" != "" ]; then
    $KILLGHOST
  fi

  for online in `$WHOBIN | tr -d ' '`; do
    USERSON="$( expr "$USERSON" \+ "1" )"
  done
  
  if [ "$USERSON" -lt "$LIMITTOKICK" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "Only $USERSON users online. Not running unless theres $LIMITTOKICK on."
    fi
    SLOWDLGO="NO"
  else
    SLOWDLGO="YES"
  fi 

  if [ "$DEBUG" = "TRUE" ]; then
    if [ "$SHOWEXCLUDES" = "TRUE" ]; then
      if [ "$EXCLUDE3" != "" ]; then
        EXCLUDE3VIEW="$( echo $EXCLUDE3 | tr -s '|' ' ' )"
        echo " "
        echo "Based on excludes from groups and users, the following users wont be checked:"
        echo "$EXCLUDE3VIEW"
        echo " "
      fi
    fi
  fi

  if [ "$SLOWDLGO" = "YES" ]; then
    for u in `$WHOBIN | tr -d ' ' | grep -w Dn: | sed -e 's/^-NEW-/NotLoggedIn/' | egrep -v $EXCLUDE3 | sort` ;do
      USERNOW="$( echo $u | awk -F"^" '{print $1}')"
      USERPID="$( echo $u | awk -F"^" '{print $2}')"
      USERSPEED="$( echo $u | awk -F"^" '{print $4}')"
      USERSPEED2="$( echo $USERSPEED | awk -F"." '{print $1}')"
      if [ "$USERSPEED2" -lt "$SPEEDLIMIT" ]; then
        if [ "$PREFOLDERS" != "" ]; then
          for prefolder in $PREFOLDERS; do
            VERPREFOLDER="$( echo $u | grep -w $prefolder )"
            if [ "$VERPREFOLDER" != "" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "$USERNOW: Slowdownloading in in $prefolder. Wont be checked."
              fi
              INPREFOLDERSLOW="YES"
              IDLEBEFORE="$( echo $TOCHECK | grep -w $USERNOW )"
              if [ "$IDLEBEFORE" != "" ]; then
                NEWTOCHECK=""
                for slowl in $TOCHECK; do
                  rebuildcheck="$( echo $slowl | grep -w $USERNOW )"
                  if [ "$rebuildcheck" = "" ]; then
                    NEWTOCHECK="$slowl $NEWTOCHECK"
                  fi
                done
                TOCHECK="$NEWTOCHECK"
                NEWTOCHECK=""
              fi
              INPREFOLDERS="$USERNOW $INPREFOLDERS"
            fi
          done
          VERPREFOLDER=""
          prefolder=""
        fi
        
        if [ "$INPREFOLDERSLOW" != "YES" ]; then
          if [ "$DEBUG" = "TRUE" ]; then
            echo "$USERNOW is only downloading with $USERSPEED k/sec"
          fi
          VERIFY="$( echo $TOCHECK | grep -w $USERNOW )"
          if [ -e "$USERFOLDER/$USERNOW" ]; then
            ok=yes
          else
            VERIFY="$RANDOM"
          fi
          if [ "$VERIFY" = "" ]; then
            if [ "$BOTSLOWW" = "TRUE" ]; then
              if [ "$LOG" != "" ]; then
                echo "$(date +%x' '%T): SLOWDL: $USERNOW gets a warning for slow downloading ($USERSPEED k/Sec)" >> $LOG
              fi
              echo `date "+%a %b %e %T %Y"` KTMFSLDW: \"$USERNOW\" \"$USERSPEED\" \"$DELAYSLOWDL\" >> $GLLOG
            fi
            TOCHECK="$USERNOW $TOCHECK"
          fi
        fi
        INPREFOLDERSLOW=""     
      fi
    done
    
    SLOWDLGO=""

    if [ "$TOCHECK" = "" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Nobody is downloading below $SPEEDLIMIT k/sec"
      fi
      SLOWDLGO="NO"
    else
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Going to check $TOCHECK after $DELAYSLOWDL seconds."
      fi
      SLOWDLGO="YES"        
    fi
  fi

  if [ "$SLOWDLGO" = "YES" ]; then 
    sleep $DELAYSLOWDL
    USERSTOBAN=""
    LASTBAN=""
    GOTBAN=""

    for users in $TOCHECK; do
      for user in `$WHOBIN | grep -w Dn: | sed -e 's/^-NEW-/NotLoggedIn/' | grep -w $users | egrep -v $EXCLUDE3 | sort` ;do
        USERNOW="$( echo $user | awk -F"^" '{print $1}')"
        USERPID="$( echo $user | awk -F"^" '{print $2}')"
        USERSPEED="$( echo $user | awk -F"^" '{print $4}')"
        USERSPEED2="$( echo $USERSPEED | awk -F"." '{print $1}')"
        if [ "$USERSPEED2" -lt "$SPEEDLIMIT" ]; then
          if [ "$BOTSLOW" = "TRUE" ]; then
            echo `date "+%a %b %e %T %Y"` KTMFSLD: \"$USERNOW\" \"$USERSPEED\" >> $GLLOG
          fi

          if [ "$DEBUG" = "TRUE" ]; then
            echo "$USERNOW is still too slow at only $USERSPEED k/sec. Killing $USERPID"
          fi
          if [ "$LOG" != "" ]; then
             echo "$(date +%x' '%T): SLOWDL: $USERNOW kicked for slowdl at $USERSPEED k/sec" >> $LOG
          fi
          if [ "$BAN" = "TRUE" ]; then
            if [ "$LASTBAN" != "$USERNOW" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Banning $USERNOW for $BANTIME seconds."
              fi
              if [ "$LOG" != "" ]; then
                echo "$(date +%x' '%T): SLOWDL: $USERNOW tempbanned for $BANTIME seconds." >> $LOG
              fi
              if [ "$TEST" != "TRUE" ]; then
              FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
              CHECK="$( echo $FLAGS | grep 6 )"
                if [ "$CHECK" != "" ]; then
                  CHECK=""
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "$USERNOW - Already deleted. Will not delete again."
                    GOTBAN="$USERNOW $GOTBAN"
                  fi
                else
                  if [ -e $USERFOLDER/$USERNOW ]; then
                    if [ "$TEST" != "TRUE" ]; then
                      if [ "$DEBUG" = "TRUE" ]; then
                        echo "Putting ye oldie 6 flag on $USERNOW."
                      fi
                      FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
                      sed -e "s/^FLAGS $FLAGS.*/FLAGS "$FLAGS"6/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
                      mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
                      GOTBAN="$USERNOW $GOTBAN"
                      echo "You were downloading too slowly. Only $USERSPEED k/sec . $BANTIME seconds tempban." > $BYEFOLDER/$USERNOW.bye
                    fi
                  fi
                fi
              fi
              LASTBAN=$USERNOW
            fi
          fi
          PIDS="$USERPID"

          if [ "$PIDS" != "" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Killing $PIDS now."
            fi
            if [ "$TEST" != "TRUE" ]; then
              for pid in $PIDS; do
                kill $pid
              done
            fi
          else
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Cant find his pid anymore. Someone kicked him (me earlier perhaps)."
              echo "Nothing to worry about."
            fi
            if [ "$LOG" != "" ]; then
              echo "$(date +%x' '%T): SLOWDL: Cant find users pid anymore. Perhaps he logged (chicken)." >> $LOG
            fi
          fi
        fi
      done
    done

    if [ "$GOTBAN" != "" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Waiting $BANTIME seconds to readd banned slow download users."
      fi
      sleep $BANTIME
      for user in $GOTBAN; do
        USERNOW="$user"
        if [ -e $BYEFOLDER/$user.bye ]; then
          if [ "$TEST" != "TRUE" ]; then
            rm -f $BYEFOLDER/$user.bye
          fi
        fi

        FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
        VERIFY="$( echo $FLAGS | grep 6 )"
        if [ "$VERIFY" = "" ]; then
          if [ "$DEBUG" = "TRUE" ]; then
            echo "No 6 flag on $user. Guess I never delled him."
          fi
        else
          if [ "$DEBUG" = "TRUE" ]; then
            echo "Removing 6 flag from $user"
          fi
          if [ "$LOG" != "" ]; then
            echo "$(date +%x' '%T): SLOWDL: Restoring tempban from $user." >> $LOG
          fi
          NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
          sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
          mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW

          ## Verify that we really removed tempban.
          FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
          VERIFY="$( echo $FLAGS | grep 6 )"
          if [ "$VERIFY" != "" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Hm, user still got 6 flag. I might not have permissions now. Trying again."
            fi
            NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
            sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
            mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
            FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
            VERIFY="$( echo $FLAGS | grep 6 )"
            if [ "$VERIFY" != "" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Nope. Cant remove the 6 flag from $USERNOW. Check perms on userfiles."
              fi
              if [ "$LOG" != "" ]; then
                echo "$(date +%x' '%T): SLOWDL: ERROR. Cant remove tempban from $USERNOW." >> $LOG
              fi
            fi
          fi
        fi
      done
    fi
  fi
fi


#####################################################################################
## Slow Uploaders part                                                              #
#####################################################################################

GOTBAN=""
PIDS=""
PIDS2=""
USERSON="0"
TOCHECK=""
INPREFOLDERS=""
INPREFOLDERSLOW=""

if [ "$SLOWULKICK" = "TRUE" ]; then
  if [ "$DEBUG" = "TRUE" ]; then
    echo " "
    echo "-----------------------------------"
    echo "Start Slow Upload kick part.       "
  fi

  if [ "$KILLGHOST" != "" ]; then
    $KILLGHOST
  fi

  for online in `$WHOBIN | tr -d ' '`; do
    USERSON="$( expr "$USERSON" \+ "1" )"
  done
  
  if [ "$USERSON" -lt "$LIMITTOKICKUL" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "Only $USERSON users online. Not running unless theres $LIMITTOKICKUL on."
    fi
    SLOWULGO="NO"
  else
    SLOWULGO="YES"
  fi 

  if [ "$DEBUG" = "TRUE" ]; then
    if [ "$SHOWEXCLUDES" = "TRUE" ]; then
      if [ "$EXCLUDE5" != "" ]; then
        EXCLUDE5VIEW="$( echo $EXCLUDE5 | tr -s '|' ' ' )"
        echo " "
        echo "Based on excludes from groups and users, the following users wont be checked:"
        echo "$EXCLUDE5VIEW"
        echo " "
      fi
    fi
  fi

  if [ "$SLOWULGO" = "YES" ]; then
    for u in `$WHOBIN | tr -d ' ' | grep -w Up: | sed -e 's/^-NEW-/NotLoggedIn/' | egrep -v $EXCLUDE5 | sort` ;do
      USERNOW="$( echo $u | awk -F"^" '{print $1}')"
      USERPID="$( echo $u | awk -F"^" '{print $2}')"
      USERSPEED="$( echo $u | awk -F"^" '{print $4}')"
      USERSPEED2="$( echo $USERSPEED | awk -F"." '{print $1}')"
      if [ "$USERSPEED2" -lt "$SPEEDLIMITUL" ]; then

        if [ "$PREFOLDERS" != "" ]; then
          for prefolder in $PREFOLDERS; do
            VERPREFOLDER="$( echo $u | grep -w $prefolder )"
            if [ "$VERPREFOLDER" != "" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "$USERNOW: Slowuploading in in $prefolder. Wont be checked."
              fi
              INPREFOLDERSLOW="YES"
              IDLEBEFORE="$( echo $TOCHECK | grep -w $USERNOW )"
              if [ "$IDLEBEFORE" != "" ]; then
                NEWTOCHECK=""
                for slowup in $TOCHECK; do
                  rebuildcheck="$( echo $slowup | grep -w $USERNOW )"
                  if [ "$rebuildcheck" = "" ]; then
                    NEWTOCHECK="$slowup $NEWTOCHECK"
                  fi
                done
                TOCHECK="$NEWTOCHECK"
                NEWTOCHECK=""
              fi
              INPREFOLDERS="$USERNOW $INPREFOLDERS"
            fi
          done
          VERPREFOLDER=""
          prefolder=""
        fi

        if [ "$INPREFOLDERSLOW" != "YES" ]; then
          if [ "$DEBUG" = "TRUE" ]; then
            echo "$USERNOW is only uploading with $USERSPEED k/sec"
          fi
          VERIFY="$( echo $TOCHECK | grep -w $USERNOW )"
          if [ -e "$USERFOLDER/$USERNOW" ]; then
            ok=yes
          else
            VERIFY="$RANDOM"
          fi
          if [ "$VERIFY" = "" ]; then
            if [ "$BOTSLOWWUL" = "TRUE" ]; then
              if [ "$LOG" != "" ]; then
                echo "$(date +%x' '%T): SLOWUL: $USERNOW gets a warning for slow uploading ($USERSPEED k/Sec)" >> $LOG
              fi
              echo `date "+%a %b %e %T %Y"` KTMFSLUW: \"$USERNOW\" \"$USERSPEED\" \"$DELAYSLOWUL\" >> $GLLOG
            fi
            TOCHECK="$USERNOW $TOCHECK"
          fi
        fi
        INPREFOLDERSLOW=""
      fi
    done
    
  SLOWULGO=""

    if [ "$TOCHECK" = "" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Nobody is uploading below $SPEEDLIMITUL k/sec"
      fi
      SLOWULGO="NO"
    else
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Going to check $TOCHECK after $DELAYSLOWUL seconds."
      fi
      SLOWULGO="YES"
    fi
  fi

  if [ "$SLOWULGO" = "YES" ]; then 
    sleep $DELAYSLOWUL
    USERSTOBAN=""
    LASTBAN=""
    GOTBAN=""

    for users in $TOCHECK; do
      for user in `$WHOBIN | grep -w Up: | sed -e 's/^-NEW-/NotLoggedIn/' | grep -w $users | egrep -v $EXCLUDE5 | sort` ;do
        USERNOW="$( echo $user | awk -F"^" '{print $1}')"
        USERPID="$( echo $user | awk -F"^" '{print $2}')"
        USERSPEED="$( echo $user | awk -F"^" '{print $4}')"
        USERSPEED2="$( echo $USERSPEED | awk -F"." '{print $1}')"
        if [ "$USERSPEED2" -lt "$SPEEDLIMITUL" ]; then
          WHAT="$( echo $user | awk -F"^" '{print $5}' )"
          if [ "$BOTSLOWUL" = "TRUE" ]; then
            echo `date "+%a %b %e %T %Y"` KTMFSLU: \"$USERNOW\" \"$USERSPEED\" >> $GLLOG
          fi
          if [ "$DEBUG" = "TRUE" ]; then
            echo "$USERNOW is still too slow at only $USERSPEED k/sec. Killing $USERPID"
          fi
          if [ "$LOG" != "" ]; then
             echo "$(date +%x' '%T): SLOWUL: $USERNOW kicked for slowul at $USERSPEED k/sec" >> $LOG
          fi
          if [ "$BANUL" = "TRUE" ]; then
            if [ "$LASTBAN" != "$USERNOW" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Banning $USERNOW for $BANTIMEUL seconds."
              fi
              if [ "$LOG" != "" ]; then
                echo "$(date +%x' '%T): SLOWUL: $USERNOW tempbanned for $BANTIMEUL seconds." >> $LOG
              fi
              if [ "$TEST" != "TRUE" ]; then
              FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
              CHECK="$( echo $FLAGS | grep 6 )"
                if [ "$CHECK" != "" ]; then
                  CHECK=""
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "$USERNOW - Already deleted. Will not delete again."
                    GOTBAN="$USERNOW $GOTBAN"
                  fi
                else
                  if [ -e $USERFOLDER/$USERNOW ]; then
                    if [ "$DEBUG" = "TRUE" ]; then
                      echo "Putting ye oldie 6 flag on $USERNOW."
                    fi
                    if [ "$TEST" != "TRUE" ]; then
                      FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
                      sed -e "s/^FLAGS $FLAGS.*/FLAGS "$FLAGS"6/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
                      mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
                      GOTBAN="$USERNOW $GOTBAN"
                      echo "You were uploading too slowly. Only $USERSPEED k/sec . $BANTIMEUL seconds tempban." > $BYEFOLDER/$USERNOW.bye
                    fi
                  fi
                fi
              fi
              LASTBAN=$USERNOW
            fi
          fi
          PIDS="$USERPID"

          if [ "$PIDS" != "" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Killing $PIDS now."
            fi
            if [ "$TEST" != "TRUE" ]; then
              for pid in $PIDS; do
                kill $pid
                sleep 0.5
                if [ -e "$GLROOT$WHAT" -a "$WHAT" != "" ]; then
                  rm -f $GLROOT$WHAT
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "Removing non complete file $WHAT"
                  fi
                  if [ "$UNDUPE" != "" ]; then
                    TEMPO="$( echo $WHAT | tr -s '/' ' ' )"
                    for i in $TEMPO; do
                      FILENAME="$i"
                    done
                    $UNDUPE -u $UNDUPEUSER -f $FILENAME >/dev/null 2>&1
 	            if [ "$DEBUG" = "TRUE" ]; then
                      echo "Unduping $FILENAME"
                    fi
                    if [ "$LOG" != "" ]; then
                      echo "$(date +%x' '%T): SLOWUL: Removing & Unduping incomplete file $WHAT." >> $LOG
                    fi
                    FILENAME=""
		    i=""
		    TEMPO=""
                  fi
                else
                  if [ "$DEBUG" = "TRUE" ]; then
                    echo "Cant find $GLROOT$WHAT to delete (This means you have a good zipscript)."
                  fi
                fi
              done
            fi
          else
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Cant find his pid anymore. Someone kicked him (me earlier perhaps)."
              echo "Nothing to worry about."
            fi
            if [ "$LOG" != "" ]; then
              echo "$(date +%x' '%T): SLOWUL: Cant find users pid anymore. Perhaps he logged (chicken)." >> $LOG
            fi
          fi
        fi
      done
    done

    if [ "$GOTBAN" != "" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Waiting $BANTIMEUL seconds to readd banned slow upload users."
      fi
      sleep $BANTIMEUL
      for user in $GOTBAN; do
        USERNOW="$user"
        if [ -e $BYEFOLDER/$user.bye ]; then
          if [ "$TEST" != "TRUE" ]; then
            rm -f $BYEFOLDER/$user.bye
          fi
        fi
        FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
        VERIFY="$( echo $FLAGS | grep 6 )"
        if [ "$VERIFY" = "" ]; then
          if [ "$DEBUG" = "TRUE" ]; then
            echo "No 6 flag on $user. Guess I never delled him."
          fi
        else
          if [ "$DEBUG" = "TRUE" ]; then
            echo "Removing 6 flag from $user"
          fi
          if [ "$LOG" != "" ]; then
            echo "$(date +%x' '%T): SLOWUL: Restoring tempban from $user." >> $LOG
          fi
          NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
          sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
          mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW

          ## Verify that we really removed tempban.
          FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
          VERIFY="$( echo $FLAGS | grep 6 )"
          if [ "$VERIFY" != "" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Hm, user still got 6 flag. I might not have permissions now. Trying again."
            fi
            NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
            sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
            mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
            FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
            VERIFY="$( echo $FLAGS | grep 6 )"
            if [ "$VERIFY" != "" ]; then
             if [ "$DEBUG" = "TRUE" ]; then
                echo "Nope. Cant remove the 6 flag from $USERNOW. Check perms on userfiles."
              fi
              if [ "$LOG" != "" ]; then
                echo "$(date +%x' '%T): SLOWUL: ERROR. Cant remove tempban from $USERNOW." >> $LOG
              fi
            fi
          fi
        fi
      done
    fi
  fi
fi


#####################################################################################
## Generic Kick part                                                                #
#####################################################################################

GOTBAN=""
PIDS=""
PIDS2=""
USERSON="0"
TOKICK=""
LAST=""

if [ "$GENKICK" = "TRUE" ]; then 
  if [ "$DEBUG" = "TRUE" ]; then
    echo " "
    echo "-----------------------------------"
    echo "Start Generic kick part.           "
  fi

  if [ "$KILLGHOST" != "" ]; then
    $KILLGHOST
  fi

  for online in `$WHOBIN | tr -d ' '`; do
    USERSON="$( expr "$USERSON" \+ "1" )"
  done
  
  if [ "$USERSON" -lt "$LIMITTOGENKICK" ]; then
    if [ "$DEBUG" = "TRUE" ]; then
      echo "Only $USERSON users online. Not running unless theres $LIMITTOGENKICK on."
    fi
    GENKICK="NO"
  else
    GENKICK="YES"
  fi 

  if [ "$GENEXCLUDE" = "" ]; then
    GENEXCLUDE="FWEFw4fg4g4"
  fi

  if [ "$GENKICK" = "YES" ]; then
    if [ "$KICKGROUPS" != "" ]; then
      GROUPUSERS="$( egrep "$KICKGROUPS" $USERFOLDER/* -s | egrep -v "$GENEXCLUDE" | awk -F":" '{print $1}' )"
      for user in $GROUPUSERS; do
        user="$( basename $user )"
        if [ "$user" != "" ]; then
          if [ "$TOKICK" != "" ]; then
            TOKICK="$TOKICK $user"
          else
            TOKICK="$user"
          fi
        fi
      done
    fi

    if [ "$RATIO0KICK" = "TRUE" ]; then
      GROUPUSERS=""
      GROUPUSERS="$( grep -w 'RATIO 0' $USERFOLDER/* -s | egrep -v "$GENEXCLUDE" | awk -F":" '{print $1}' )"
      for user in $GROUPUSERS; do
        user="$( basename $user )"
        if [ "$user" != "" ]; then
          if [ "$TOKICK" != "" ]; then
            TOKICK="$TOKICK $user"
          else
            TOKICK="$user"
          fi
        fi
      done
    fi

    TOKICK="$( echo $TOKICK | tr -s ' ' '|' )"

    if [ "$KICKUSERS" != "" ]; then
      if [ "$TOKICK" = "" ]; then
        TOKICK="$KICKUSERS"
      else
        TOKICK="$KICKUSERS|$TOKICK"
      fi
    fi
 
    if [ "$DEBUG" = "TRUE" ]; then
      if [ "$SHOWEXCLUDES" = "TRUE" ]; then
        if [ "$TOKICK" != "" ]; then
          TOKICKNICE="$( echo $TOKICK | tr -s '|' ' ' )"        
          echo " "
          echo "Based on settings from groups and users, the following users WILL be kicked:"
          echo "$TOKICKNICE"
          echo " "
        fi
      fi
    fi

    if [ "$TOKICK" = "" ]; then
      if [ "$DEBUG" = "TRUE" ]; then
        echo "KTMF error. No excluded users or groups but GENKICK is TRUE."
      fi
      if [ "$LOG" != "" ]; then
        echo "Error: No excluded users or groups but GENKICK is TRUE." >> $LOG
      fi
    else
      USERSON="$( $WHOBIN | tr -d ' ' | sort | sed -e 's/^-NEW-/NotLoggedIn/' | egrep -w "$TOKICK" )"

      for rawdata in $USERSON; do
        name="$( echo $rawdata | awk -F"^" '{print $1}' )"
         
        ## Make a extra verification that the user was indeed to be kicked.
        unset verify
        verify="$( echo $TOKICK | grep -w "$name" )"
        if [ "$verify" = "" ]; then
          LAST="$name"
        fi

        if [ "$PREFOLDERS" != "" ]; then
          NOKICK=""
          for prefolder in $PREFOLDERS; do
            VERPREFOLDER="$( echo $rawdata | grep -w $prefolder )"
            if [ "$VERPREFOLDER" != "" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "$name: is in in $prefolder. That pid wont be checked/kicked."
              fi
              NOKICK="$name"
            fi
          done
        fi 
  
        if [ "$UPEXCLUDE" = "TRUE" ]; then
          ACTION="$( echo $rawdata | awk -F"^" '{print $3}' )"
          if [ "$ACTION" = "Up:" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "$name is uploading. That pid wont be kicked."
            fi
            NOKICK="$name"
          fi
        fi

        if [ "$name" != "$LAST" ]; then
          if [ "$NOKICK" != "$name" ]; then
            TOKICKLIVE="$name $TOKICKLIVE"
          fi
        fi

        if [ "$NOKICK" != "$name" ]; then
          pid="$( echo $rawdata | awk -F"^" '{print $2}' )"
          pids="$pid $pids"
          LAST="$name"
        fi
      done
    fi

    if [ "$TOKICKLIVE" != "" -o "$pids" != "" ]; then
      ## Start kick mode
      if [ "$TEMPBANLEECH" = "TRUE" ]; then
        for USERNOW in $TOKICKLIVE; do
          if [ "$TEST" != "TRUE" ]; then
            FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
            CHECK="$( echo $FLAGS | grep 6 )"
            if [ "$CHECK" != "" ]; then
              CHECK=""
              if [ "$DEBUG" = "TRUE" ]; then
                echo "$USERNOW - Already deleted. Will not delete again."
              fi
              GOTBAN="$USERNOW $GOTBAN"
            else
              if [ -e $USERFOLDER/$USERNOW ]; then
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "Putting ye oldie 6 flag on $USERNOW."
                fi
                if [ "$LOG" != "" ]; then
                  echo "$(date +%x' '%T): GENKICK: $USERNOW tempbanned for $TEMPBANTIME seconds." >> $LOG
                fi
                FLAGS="$(cat $USERFOLDER/$USERNOW | grep -w FLAGS | awk -F" " '{print $2}')"
                sed -e "s/^FLAGS $FLAGS.*/FLAGS "$FLAGS"6/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
                mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
                GOTBAN="$USERNOW $GOTBAN"
                echo "You were leech tempbanned for $TEMPBANTIME Seconds." > $BYEFOLDER/$USERNOW.bye
              fi
            fi
          fi
        done
      fi
      ## Kill pids
      if [ "$DEBUG" = "TRUE" ]; then
        echo "Going to kick users: $TOKICKLIVE"
        echo "Going to kick pids : $pids"
      fi
      if [ "$TEST" != "TRUE" ]; then
        for pid in $pids; do
          kill $pid
        done
      fi
      if [ "$BOTGEN" = "TRUE" ]; then
        echo `date "+%a %b %e %T %Y"` KTMFG: \"$TOKICKLIVE\" >> $GLLOG
      fi

      if [ "$GOTBAN" != "" ]; then
        if [ "$DEBUG" = "TRUE" ]; then
          echo "Waiting $TEMPBANTIME seconds to readd banned generic kick users."
        fi
        sleep $TEMPBANTIME

        for user in $GOTBAN; do
          USERNOW="$user"
          if [ -e $BYEFOLDER/$user.bye ]; then
            if [ "$TEST" != "TRUE" ]; then
              rm -f $BYEFOLDER/$user.bye
            fi
          fi

          FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
          VERIFY="$( echo $FLAGS | grep 6 )"
          if [ "$VERIFY" = "" ]; then
            if [ "$DEBUG" = "TRUE" ]; then
              echo "No 6 flag on $user. Guess I never delled him."
            fi
          else
            if [ "$DEBUG" = "TRUE" ]; then
              echo "Removing 6 flag from $user"
            fi
            if [ "$LOG" != "" ]; then
              echo "$(date +%x' '%T): GENKICK: Restoring tempban from $user." >> $LOG
            fi
            NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
            sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
            mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW

            ## Verify that we really removed tempban.
            FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
            VERIFY="$( echo $FLAGS | grep 6 )"
            if [ "$VERIFY" != "" ]; then
              if [ "$DEBUG" = "TRUE" ]; then
                echo "Hm, user still got 6 flag. I might not have permissions now. Trying again."
              fi
              NEWFLAGS="$( echo $FLAGS | tr -d '6' )"
              sed -e "s/^FLAGS $FLAGS.*/FLAGS $NEWFLAGS/" $USERFOLDER/$USERNOW > $TEMPPATH/$USERNOW.new
              mv -f $TEMPPATH/$USERNOW.new $USERFOLDER/$USERNOW
              FLAGS="$( grep FLAGS $USERFOLDER/$user | awk '{print $2}' )"
              VERIFY="$( echo $FLAGS | grep 6 )"
              if [ "$VERIFY" != "" ]; then
                if [ "$DEBUG" = "TRUE" ]; then
                  echo "Nope. Cant remove the 6 flag from $USERNOW. Check perms on userfiles."
                fi
                if [ "$LOG" != "" ]; then
                  echo "$(date +%x' '%T): GENKICK: ERROR. Cant remove tempban from $USERNOW." >> $LOG
                fi
              fi
            fi
          fi
        done
      fi
    fi
  fi
fi

rm -f $LOCKFILE
exit 0
