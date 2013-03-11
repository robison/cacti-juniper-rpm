#!/usr/bin/perl

#This Script find the and monitor Juniper RPM tests.
#the problem with this mib is that the index is based on SnmpAdminString where each word is prefix with its length and the word is in ascii Decimal format
#any qestions or bugs to nitzan.tzelniker@gmail.com

#use warnings;
use strict;

my $node = $ARGV[0];
my $comm = $ARGV[1];
my $action1 = $ARGV[2];
my $action2 = $ARGV[3];
my $theindex = $ARGV[4];



my $snmppath = "/usr/bin/snmpwalk";
my $snmpget = "/usr/bin/snmpget";
my $version = "2c";
my $jnxRpmResCalcMin = '.1.3.6.1.4.1.2636.3.50.1.3.1.3';
my $jnxRpmResCalcMax = '.1.3.6.1.4.1.2636.3.50.1.3.1.4';
my $jnxRpmResCalcAverage = '.1.3.6.1.4.1.2636.3.50.1.3.1.5';
my $jnxRpmResCalcPkToPk = '.1.3.6.1.4.1.2636.3.50.1.3.1.6';
my $jnxRpmResCalcStdDev = '.1.3.6.1.4.1.2636.3.50.1.3.1.7';
my $jnxRpmResCalcStdDev = '.1.3.6.1.4.1.2636.3.50.1.3.1.7';
my $jnxRpmResSumSent = '.1.3.6.1.4.1.2636.3.50.1.2.1.2';
my $jnxRpmResSumReceived = '.1.3.6.1.4.1.2636.3.50.1.2.1.3';
my $jnxRpmResSumPercentLost = '.1.3.6.1.4.1.2636.3.50.1.2.1.4';
my @index;
my $owner;
my $test;
my @Tests;

sub indexes {
	my $queryOrIndex = shift;

	my @Index = `$snmppath -On -v $version $node -c $comm $jnxRpmResCalcAverage`;

	foreach (@Index) {

		if ($_ =~m/^\.1\.3\.6\.1\.4\.1\.2636\.3\.50\.1\.3\.1\.5\.(\d+).*\.1\.1 \= Gauge32.*$/i){ #Find the length of the owner string
		if ($_ =~m/^\.1\.3\.6\.1\.4\.1\.2636\.3\.50\.1\.3\.1\.5\.(\d+)((\.\d+){$1})\.(\d+).*\.1\.1 \= Gauge32.*$/i){ #Find the owner string and the length of te Test string
		if ($_ =~m/^\.1\.3\.6\.1\.4\.1\.2636\.3\.50\.1\.3\.1\.5\.(\d+)((\.\d+){$1})\.(\d+)((\.\d+){$4})\.1\.1 \= Gauge32.*$/i){ # Find the Test string
			my $owner = oid_to_ascii($2);
			my $test = oid_to_ascii($5);
			if ($queryOrIndex eq "query"){
				push @Tests , "$owner.$test:$owner.$test\n";
			}
			elsif ($queryOrIndex eq "index"){
				push @Tests, "$owner.$test\n" ;
			}
		}
	}
}
}
return @Tests
}
sub get_average {
	my $index_value = shift;
	my @values = split /\./,$index_value;
	my $lengthOwnerOid =  length ($values[0]);
	my $lengthTestOid =  length ($values[1]);
	my $ownerOid =  ascii_to_oid($values[0]);
	my $testOid = ascii_to_oid($values[1]);
	my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
	my @rtt =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResCalcAverage.$oidIndex.2.1`);
	return $rtt[1];
}
sub get_jitter {
	my $index_value = shift;
	my @values = split /\./,$index_value;
	my $lengthOwnerOid =  length ($values[0]);
	my $lengthTestOid =  length ($values[1]);
	my $ownerOid =  ascii_to_oid($values[0]);
	my $testOid = ascii_to_oid($values[1]);
	my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
	my @jitter =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResCalcPkToPk.$oidIndex.2.1`);
	return $jitter[1];
}
sub get_minrtt {
        my $index_value = shift;
        my @values = split /\./,$index_value;
        my $lengthOwnerOid =  length ($values[0]);
        my $lengthTestOid =  length ($values[1]);
        my $ownerOid =  ascii_to_oid($values[0]);
        my $testOid = ascii_to_oid($values[1]);
        my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
        my @minrtt =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResCalcMin.$oidIndex.2.1`);
        return $minrtt[1];
}
sub get_maxrtt {
        my $index_value = shift;
        my @values = split /\./,$index_value;
        my $lengthOwnerOid =  length ($values[0]);
        my $lengthTestOid =  length ($values[1]);
        my $ownerOid =  ascii_to_oid($values[0]);
        my $testOid = ascii_to_oid($values[1]);
        my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
        my @maxrtt =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResCalcMax.$oidIndex.2.1`);
        return $maxrtt[1];
}
sub get_stddev {
        my $index_value = shift;
        my @values = split /\./,$index_value;
        my $lengthOwnerOid =  length ($values[0]);
        my $lengthTestOid =  length ($values[1]);
        my $ownerOid =  ascii_to_oid($values[0]);
        my $testOid = ascii_to_oid($values[1]);
        my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
        my @stddev =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResCalcStdDev.$oidIndex.2.1`);
        return $stddev[1];
}
sub get_probesent {
        my $index_value = shift;
        my @values = split /\./,$index_value;
        my $lengthOwnerOid =  length ($values[0]);
        my $lengthTestOid =  length ($values[1]);
        my $ownerOid =  ascii_to_oid($values[0]);
        my $testOid = ascii_to_oid($values[1]);
        my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
        my @probesent =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResSumSent.$oidIndex.2`);
        return $probesent[1];
}
sub get_probercvd {
        my $index_value = shift;
        my @values = split /\./,$index_value;
        my $lengthOwnerOid =  length ($values[0]);
        my $lengthTestOid =  length ($values[1]);
        my $ownerOid =  ascii_to_oid($values[0]);
        my $testOid = ascii_to_oid($values[1]);
        my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
        my @probercvd =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResSumReceived.$oidIndex.2`);
        return $probercvd[1];
}
sub get_loss {
        my $index_value = shift;
        my @values = split /\./,$index_value;
        my $lengthOwnerOid =  length ($values[0]);
        my $lengthTestOid =  length ($values[1]);
        my $ownerOid =  ascii_to_oid($values[0]);
        my $testOid = ascii_to_oid($values[1]);
        my $oidIndex =  $lengthOwnerOid . $ownerOid . '.' . $lengthTestOid . $testOid;
        my @loss =  split (/ /,`$snmpget -Ov  -v $version $node -c $comm $jnxRpmResSumPercentLost.$oidIndex.2`);
        return $loss[1];
}
ARGUMENTS: {
	if ($action1 eq "index") { print indexes("index") ; last ARGUMENTS; }
	if ($action1 eq "query") { print indexes("query") ; last ARGUMENTS; }
	if ($action2 eq "average") { print get_average("$theindex") ; last ARGUMENTS; }
	if ($action2 eq "jitter") { print get_jitter("$theindex") ; last ARGUMENTS; }
	if ($action2 eq "minrtt") { print get_minrtt("$theindex") ; last ARGUMENTS; }
	if ($action2 eq "maxrtt") { print get_maxrtt("$theindex") ; last ARGUMENTS; }
	if ($action2 eq "stddev") { print get_stddev("$theindex") ; last ARGUMENTS; }
        if ($action2 eq "probesent") { print get_probesent("$theindex") ; last ARGUMENTS; }
        if ($action2 eq "probercvd") { print get_probercvd("$theindex") ; last ARGUMENTS; }
        if ($action2 eq "loss") { print get_loss("$theindex") ; last ARGUMENTS; }

	print "usage:\n\n./juniper-rpm.pl IP COMMUNITY index\n./juniper-rpm.pl IP COMMUNITY query \n./juniper-rpm.pl IP COMMUNITY get {average|jitter} index_oid\n";
}

sub oid_to_ascii ($)
{
	## Convert each two-digit hex number back to an ASCII character.
	(my $str = shift)  =~ s/([0-9]{1,3})/chr($1)/eg;
	my @noDotArry = split(/\./,$str);
	$str = join ('',@noDotArry);
	return $str;
}

sub ascii_to_oid($)
{
	my @chars = split(//,shift);
	my $oid = '';
	foreach (@chars){
		$oid .= '.' . ord ($_);
	}
	return $oid;
}

exit;
