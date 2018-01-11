#!/bin/bash

#checklist 1:16

#password 4:7
if grep -Fq "7" /etc/system-release
then
	P='/etc/pam.d/system-auth-ac'
	grep -qF "minlen" $P || sed -i \
	"s/$(egrep '^password\s+requisite\s+pam_pwquality.so' $P)/$(egrep '^password\s+requisite\s+pam_pwquality.so' $P) minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/g" $P
	grep -qF "remember" $P || sed -i "s/$(egrep '^password\s+sufficient\s+pam_unix.so' $P)/$(egrep '^password\s+sufficient\s+pam_unix.so' $P) remember=5/g" $P

	P='/etc/pam.d/password-auth-ac'
	grep -qF "minlen" $P || sed -i \
	"s/$(egrep '^password\s+requisite\s+pam_pwquality.so' $P)/$(egrep '^password\s+requisite\s+pam_pwquality.so' $P) minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/g" $P
	grep -qF "remember" $P || sed -i "s/$(egrep '^password\s+sufficient\s+pam_unix.so' $P)/$(egrep '^password\s+sufficient\s+pam_unix.so' $P) remember=5/g" $P
elif grep -Fq "6" /etc/system-release
then
	P='/etc/pam.d/system-auth-ac'
	grep -qF "minlen" $P || sed -i \
	"s/$(egrep '^password\s+requisite\s+pam_cracklib.so' $P)/$(egrep '^password\s+requisite\s+pam_cracklib.so' $P) minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/g" $P
	grep -qF "remember" $P || sed -i "s/$(egrep '^password\s+sufficient\s+pam_unix.so' $P)/$(egrep '^password\s+sufficient\s+pam_unix.so' $P) remember=5/g" $P

	P='/etc/pam.d/password-auth-ac'
	grep -qF "minlen" $P || sed -i \
	"s/$(egrep '^password\s+requisite\s+pam_cracklib.so' $P)/$(egrep '^password\s+requisite\s+pam_cracklib.so' $P) minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/g" $P
	grep -qF "remember" $P || sed -i "s/$(egrep '^password\s+sufficient\s+pam_unix.so' $P)/$(egrep '^password\s+sufficient\s+pam_unix.so' $P) remember=5/g" $P
fi
#----
sed -i -e 's/PASS_MAX_DAYS	99999/PASS_MAX_DAYS	90/g' /etc/login.defs

authconfig --update

#filewall

#cmdlog
grep -qF "PROMPT_COMMAND='RETRN_VAL=\$?;logger" /etc/bashrc || echo \
'export PROMPT_COMMAND='\''RETRN_VAL=$?;logger -p local6.debug "[$(echo $SSH_CLIENT | cut -d" " -f1)] # $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//" )"'\''' >> /etc/bashrc

grep -qF "/var/log/cmdlog.log" /etc/rsyslog.conf || echo \
"local6.debug                /var/log/cmdlog.log" >> /etc/rsyslog.conf

service rsyslog restart
chmod 644 /var/log/cmdlog.log 2> /dev/null

cat > /etc/logrotate.d/cmdlog << EOF
/var/log/cmdlog.log {
	create 0644 root root
	compress
	weekly
	rotate 12
	sharedscripts
	postrotate
		/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
	endscript
}
EOF

#SSH 13
echo $'\n' >> /etc/ssh/sshd_config
grep -q "^ClientAliveInterval" /etc/ssh/sshd_config || echo 'ClientAliveInterval 300' >> /etc/ssh/sshd_config
grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config || echo 'ClientAliveCountMax 0' >> /etc/ssh/sshd_config
## sed -i -e 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
## grep -q "^PermitRootLogin" /etc/ssh/sshd_config || echo 'PermitRootLogin no' >> /etc/ssh/sshd_config

service sshd reload

#crontab 16
[ -f /etc/cron.allow ] || touch /etc/cron.allow
[ -f /etc/at.allow ] || touch /etc/at.allow
chown -R root:root /etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d /etc/cron.allow /etc/at.allow 
chmod og-rwx /etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d /etc/cron.allow /etc/at.allow