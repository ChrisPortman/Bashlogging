# Bash Logging

This is a simple way of logging user logins via SSH as well as each command they run.

## Setup

In the most basic sense to get local logging of user activity, copy the contents of [append_to_bashrc](etc/append_to_bashrc) to the end of your /etc/bashrc file.  This will cause the contents of /etc/bashrc.d/*.sh
to be run. This is the same as /etc/profile and /etc/profile.d.  Then create the directory /etc/bashrc.d/ and put [bashlog.sh](etc/bashrc.d/bashlog.sh) in it.

Log out and log back in and you should see your loging and activity being logged to /var/log/secure (on RHEL, YMMV).  If not, check your systems syslog config to see where its sending authpriv.info logs.

## Extras

If you are sending your syslogs to a logstash server somewhere, here is an example [logstash config](Logstash/example.conf) that will identify and tag the log entries as 'login_event', for the logins and 'bashlog' for the commands
as well as tag them with the user name that you can use to set up kibana dashboards to track server and user activity.
