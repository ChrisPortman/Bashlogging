#!/bin/bash

#BASHLOGGING

#Only process for ssh connections.
if [ "$SSH_TTY" ]; then
  #Learn some stuff about the session for use in logging.
  if [ -z "$SSH_FP" ]; then
    #Work out the SSH key fingerprint from the secure log
    pts=${SSH_TTY#/dev/}
    sshpid=`/bin/ps fax | /bin/grep -m 1 "sshd: ${USER}@${pts}" | /usr/bin/awk '{print \$1}'`
    SSH_FP=`grep -m 1 "\[${sshpid}\]: Found matching" /var/log/secure | awk '{print \$NF}'`

    #Non root SSH logins seem to spawn an SSH process for the user, which does the logging, but then another child
    #process for the pts. Thus, the above search will be searching the secure log for the fingerprint using the wrong pid.
    #the parent process does log the child pid though so we can search the log for the child pid, to find the pid of the parent process
    #note the \\\\ escaping in the awk.  This dbl escaping is required to escape the \ when bash interprets it and again for awk.
    #The final implementation should be \[([0-9]+)\] to match [1234]
    if [ -z "$SSH_FP" ]; then
      sshpid=`grep -m 1 "User child is on pid ${sshpid}" /var/log/secure | awk '{match(\$0, "\\\\[([0-9]+)\\\\]",p)}END{print p[1]}'`
      SSH_FP=`grep -m 1 "\[${sshpid}\]: Found matching" /var/log/secure | awk '{print \$NF}'`
    fi

    #Make the fingerprint "NULL" if we couldnt find it for whatever reason. Reduces confusion in log processors
    if [ -z "$SSH_FP" ]; then
      SSH_FP='NULL'
    fi

    #Try to work out the user for the key.  This is done by parsing each line in ~/.ssh/authorized_keys
    #calculating the fingerprint for the key and if it matches, taking the comment from the keys line in autorized_keys
    SSH_USER="NULL"
    if [ "$SSH_FP" != "NULL" ]; then
      while read key; do
        key_owner=`echo $key | awk {'print $3'}`
        key_fp=`ssh-keygen -lf /dev/stdin <<<$key | awk {'print $2'}`
        if [ "$SSH_FP" == "$key_fp" ]; then
          SSH_USER="$key_owner"
          break
        fi
      done <~/.ssh/authorized_keys
    fi
          
    export SSH_USER
    export SSH_FP
  fi
  
  if [ -z "$SID" ]; then
    SSH_CLIENT_IP=`echo $SSH_CLIENT | awk '{print $1}'`
    SSH_CLIENT_HOSTNAME=$(host -W 1 $SSH_CLIENT_IP | awk '{print $NF}'  | sed -e 's/.$//')
    if [[ ! $SSH_CLIENT_HOSTNAME =~ ^([a-zA-Z0-9_\-]+\.){2,} ]]; then
      SSH_CLIENT_HOSTNAME=$SSH_CLIENT_IP
    fi
    SID=$$
    export SID
    echo '' | logger -p authpriv.info -t "bash[$SID]: LOGIN: USER: $USER, HOSTNAME: $HOSTNAME, FROM: $SSH_CLIENT_HOSTNAME, FINGERPRINT: $SSH_FP, SSH_USER: $SSH_USER"
  fi
    
  CMDLOG='history -a >(tee -a ~/.bash_history | logger -p authpriv.info -t "bash[$SID]: BASHLOG: USER: $LOGNAME, HOSTNAME: $HOSTNAME, FINGERPRINT: $SSH_FP, SSH_USER: $SSH_USER, CMD")'
  PROMPT_COMMAND="$CMDLOG; $PROMPT_COMMAND"
fi

#END BASHLOGGING

