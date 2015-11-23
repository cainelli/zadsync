#!/usr/bin/perl
use warnings;
use strict;
use Net::LDAP;
use POSIX;
use Data::Dumper;
use MIME::Lite;


# Read Config
my $config_dir = "/etc/zadsync";


open(CONFIG,"<$config_dir/zadsync.cfg");
my ($var, $value, %config, @attr_map);
while (<CONFIG>) {
    	chomp;                  # no newline
#    	s/#.*//;                # no comments
    	s/^\s+//;               # no leading white
    	s/\s+$//;               # no trailing white
    	next unless length;     # anything left?
    	($var, $value) = split(/\s*=\s*/, $_, 2);
    	if ( $var eq 'zAdSyncAttrMap'){
		push(@attr_map,"$value");
		next;
	}
    	$config{$var} = $value;
	#print "$var=$value\n";
}
close CONFIG;

# Global
my $ldapProp = &getLdapProperties;

my @prov;


# get Base
my $z_base = $config{zAdSyncDomainSync};
$z_base =~ s/\.|^/,dc=/g;
$z_base =~ s/^,//g;

##########################################################################################
#LOG
open (LOG, ">>$config{'zAdSyncLogFile'}");
&toLog("INOVA - AutoProvisioning...");

# ldap connection
## log



# Connect Active Directory
&toLog("connecting active directory server $config{'zAdSyncLdapURL'}...");
my $ad_ldap = Net::LDAP->new( $config{'zAdSyncLdapURL'} ) or die "$@";
$ad_ldap->bind ($config{'zAdSyncLdapAdminBindDn'},
			password => $config{'zAdSyncLdapAdminBindPassword'},
			scheme => 'ldap'
			);


# Connect Zimbra Ldap
&toLog("connecting zimbra ldap server $ldapProp->{'ldap_host'}...");
my $z_ldap = Net::LDAP->new( $ldapProp->{"ldap_host"} ) or die "$@";
$z_ldap->bind($ldapProp->{"zimbra_ldap_userdn"} , password => $ldapProp->{"zimbra_ldap_password"});



# Search Active Directory Users
&toLog("searching active directory users in base $config{'zAdSyncLdapSearchBase'}...");
my $ad_search = $ad_ldap->search ( base => $config{'zAdSyncLdapSearchBase'},
			scope => 'sub',
			filter => $config{'zAdSyncLdapSearchFilter'}
			);

# Search Zimbra Users
&toLog("searching zimbra users in base $z_base...");
my $z_search = $z_ldap->search ( base => $z_base,
                        scope => 'sub',
                        filter => 'mail=*',
			attr => 'mail'
                        );

$ad_search->entry;

# die if error
$ad_search->code && die $ad_search->error;
$z_search->code && die $z_search->error;
#

my %z_users;
for my $z_user ($z_search->entries)
{
	for my $mail ($z_user->get_value('mail'))
	{
		$z_users{$mail}=1;
	}

}
#

open(ZPROV,">/tmp/zadsync.zm");
for my $user ($ad_search->entries)
{
	my $ad_user = lc($user->get_value($config{'zAdSyncAccountNameMap'}) . '@' . $config{'zAdSyncDomainSync'});
	if ( ! $z_users{$ad_user} )
	{
		my @attrs;
		for my $attr (@attr_map)
		{
			my ($ad_att, $z_att) = split(/\s*=\s*/, $attr, 2);
			push (@attrs,$z_att  . " '" . $user->get_value($ad_att) . "'") if $user->get_value($ad_att);

			#push(@prov,$ad_user);
		}
		&toLog("sincyng $ad_user");
                &sendMail($ad_user);

		print ZPROV "createAccount $ad_user zWdx6qw3A7Xgnd3EZF @attrs\n";
	}
}


close ZPROV;
close LOG;


&toLog("running: /opt/zimbra/bin/zmprov -f /tmp/zadsync.zm");
system("/opt/zimbra/bin/zmprov -f /tmp/zadsync.zm");




###########################################################################################
# SUBS
sub toLog{
        my $msg2log = shift;
        my $date_time;
        $date_time = strftime ( '%b %d %H:%M:%S', localtime);
        print LOG "$date_time - $msg2log\n";
        print "$date_time - $msg2log\n";
}



sub getLdapProperties
{
	my %ldapProp;

	my $cmd = '/opt/zimbra/bin/zmlocalconfig -s | grep ldap';
	&toLog("Getting Zimbra LDAP properties ($cmd).");
	my @output = map {s/^\s+|\s+$//g; $_} `$cmd`;

	for my $entry (@output)
	{
		$entry =~ m/(.+?)(?:\s\=\s)(.+)/o;
		$ldapProp{$1} = $2;
	}

	return \%ldapProp;
}


sub sendMail
{
	my $account = shift;
	# Create the initial text of the message
	my $mime_msg = MIME::Lite->new(
	   From => $config{'zAdSyncNotificationFromAddress'},
	   To   => $config{'zAdSyncNotificationToAddress'},
	   Subject => $config{'zAdSyncNotificationSubject'},
	   Type => 'text',
	   Data => $config{'zAdSyncNotificationBody'} . ' ' . $account
	   )
	  or die "Error creating MIME body: $!\n";

	# Let MIME::Lite handle the Net::SMTP details
	MIME::Lite->send('smtp', $config{'zAdSyncNotificationSMTPServer'});
	$mime_msg->send() or die "Error sending message: $!\n";
}
