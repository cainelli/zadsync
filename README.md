# zadsync

> I know, Zimbra does have a tool such as zadsync to automate syncronization between AD/LDAP. However sometimes you want customize things and hopefully with this sample code you'll be able to do whatever you want.

## Support
You can run in any supported Zimbra Operating System(Network Edition or Open Source).  
- zimbra.com/downloads/ne-downloads.html

You should install the following Perl Modules:
- Net::LDAP;
- POSIX;
- MIME::Lite;

For ubuntu 14.04LTS i will make your life easier :
```
apt-get update
apt-get install libnet-ldap-perl libmime-lite-perl 
```
## Deployment

> You should do the following steps on the zimbra mailstore or zimbra ldap server.

```sh
git clone https://github.com/cainelli/zadsync.git
mkdir -p /etc/zadsync/
cp zadsync/etc/* /etc/zadsync/
cp zadsync/bin/* /usr/local/bin/
chmod +x /usr/local/bin/zadsync.pl
```
This is a base configuration you can use for initial setup:

```
zAdSyncLogFile=/var/log/zadsync.log
zAdSyncAccountNameMap=sAMAccountName
zAdSyncAttrMap=givenName=givenName
zAdSyncAttrMap=company=Company
zAdSyncAttrMap=sn=sn
zAdSyncAttrMap=description=description
zAdSyncAttrMap=displayName=displayName
zAdSyncLdapAdminBindDn=zimbra_sync@domain.com
zAdSyncLdapAdminBindPassword=MyActiveDirectoryPassword
zAdSyncLdapSearchBase=DC=domain,DC=com
zAdSyncLdapSearchFilter=(&(sAMAccountName=*)(objectClass=user)(givenName=*)(memberOf=cn=Zimbra_Internet,ou=ZIMBRA,ou=Gruoups,dc=domain,dc=com))
zAdSyncLdapURL=ldaps://192.0.0.22:636
zAdSyncDomainSync=domain.com
zAdSyncNotificationSMTPServer=smtp.server.com.br
zAdSyncNotificationBody=The following account was created:
zAdSyncNotificationFromAddress=fernando@cainelli.ninja
zAdSyncNotificationToAddress=fernando.cainelli@gmail.com
zAdSyncNotificationSubject=Zimbra Active Directory Sync
```


It's a good idea set a cron job each 5 min. as well.

```
*/5 * * * *     root    /usr/bin/perl /usr/local/bin/zadsync.pl
```


> Oh, you may run with zimbra or root user


