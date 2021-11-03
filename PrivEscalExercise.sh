#!/bin/bash

#Username and fullname of the account to be created can be entered here using flags.
while getopts u:f:p: flag
do
        case "${flag}" in
                u) Username=${OPTARG};;
                f) Fullname=${OPTARG};;
                p) Password=${OPTARG};;
        esac
done

#Additionally, the Username variable is also used to see if it has been made succesfully.
echo "Attempting to create sudo account: $Username - $Fullname"
echo "Use CTRL+C to abort the operation."

#Infinite loop that breaks when the account is succesfully created.
while true
do
        #Run the command that attempts to add a user account.
        dbus-send --system --dest=org.freedesktop.Accounts --type=method_call --print-reply /org/freedesktop/Accounts org.freedesktop.Accounts.CreateUser string:$Username string:$Fullname int32:1 & sleep 0.002s ; kill $!

        #Fill a variable with all users presents in passwd.
        Userlist=$(awk -F: '{print $1}' /etc/passwd)

        #Check to see if the new username exists in passwd.
        if [[ $Userlist == *$Username* ]]; then
                echo "The desired account has been succesfully created!"
                break
        fi
done

#Before moving on, we're giving the system a second to process the new profile to prevent errors.
sleep 1

#Next a password has to be set for the account.
echo "Setting password to for $Username to '$Password'..."

#We need the user id in order to set an account's password.
Userid="User$(id $Username -u)"

#The dbus command requires a hash rather than a plaintext password.
Hashedpassword=$(openssl passwd -5 $Password)

#Try to run the command 20 times to be safe.
for i in {1..20}
do
        dbus-send --system --dest=org.freedesktop.Accounts --type=method_call --print-reply /org/freedesktop/Accounts/$Userid org.freedesktop.Accounts.User.SetPassword string:$Hashedpassword string:empty & sleep 0.002s ; kill $!
done

echo "Done!"
