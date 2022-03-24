cat <<\EOF > /tmp/createuser.sh
#!/bin/bash

# Script to add a user to Linux system
# -------------------------------------------------------------------------

if [ $(id -u) -eq 0 ]; then
  read -p "Enter username : " USERNAME
  read -s -p "Enter password : " PASSWORD
  egrep "^$USERNAME" /etc/passwd >/dev/null
  if [ $? -eq 0 ]; then
    echo -e "\n$USERNAME already exists!\n"
    exit 1
  else
    ENCRYPTED_PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
    useradd -m -p $ENCRYPTED_PASS -d /home/$USERNAME -s /bin/bash $USERNAME

    if [ $? -eq 0 ] 
    then
      echo "User has been added to system!"
    else
      echo "Failed to add a user!"
      exit 1
    fi

    usermod -a -G wheel $USERNAME

    if [ $? -eq 0 ]
    then
      echo "User has been added to wheel group"
    else
      echo "Failed to add user to wheel group!"
      exit 1
    fi

    echo -e "\n Adding user $USERNAME to sudoers\n"
    SUDOER_TMP=$(mktemp)
    cat /etc/sudoers > $SUDOER_TMP
    sed -i -e "/^root.*/a$USERNAME  ALL=(ALL)\tNOPASSWD: ALL" $SUDOER_TMP > /dev/null
    visudo -c -f $SUDOER_TMP
    cat $SUDOER_TMP > /etc/sudoers
    rm -f $SUDOER_TMP

    echo -e "\nCreating ssh directory on home folder\n"
    mkdir /home/$USERNAME/.ssh
    touch /home/$USERNAME/.ssh/authorized_keys
    chown $USERNAME:$USERNAME /home/$USERNAME -R
    chmod 700 /home/$USERNAME /home/$USERNAME/.ssh
    chmod 600 /home/$USERNAME/.ssh/authorized_keys
  fi
else
  echo -e "\nOnly root may add a user to the system\n"
  exit 2
fi
EOF
