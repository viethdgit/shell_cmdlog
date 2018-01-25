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
