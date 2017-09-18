#!/usr/bin/perl -w

my %ERRORS=( OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 );
my %ERRORCODES=( 0 => 'OK', 1 => 'WARNING', 2 => 'CRITICAL', 3 => 'UNKNOWN' );

#use strict;
use Getopt::Long;
use Getopt::Long  qw(:config bundling);
use Scalar::Util 'looks_like_number';
#use vars qw($opt_V $opt_h $opt_F $opt_t $verbose $PROGNAME);

my $RETCODE;
my $proto;
my $port;
my $Version="0.1";



sub return_result;
sub print_help();
sub print_version();
sub print_usage();

# check for curl command and exit if not exist
my $CMD_curl=`whereis curl`;
  (my $dummy, $CMD_curl) = split(/ /,$CMD_curl,2);
  chop($CMD_curl);

my $curl_opts  = "-H \"Pragma: no-cache\" -o /dev/null -i -s ";
   $curl_opts .= "-w %{time_connect}:%{time_starttransfer}:%{time_total}:%{time_namelookup}:%{time_appconnect}:%{time_pretransfer}:%{time_redirect}";

if ($CMD_curl eq "") {
  return_result($ERRORS{UNKNOWN},"Command curl is missing in search path") ;
} 

#Getopt::Long::Configure(`bundling`);
GetOptions( 	"h" => \$opt_h,		"help" => \$opt_h,
		"V" => \$opt_V, 	"version" => \$opt_V,
		"H=s" => \$opt_H, 	"hostname=s" => \$opt_H,
                "S!" => \$opt_S, 	"SSL!" 	     => \$opt_S,
		"p=i" => \$opt_p, 	"port=i"     => \$opt_p,
		"u=s"  => \$opt_u,	"uri=s"      => \$opt_u,
		"w=s"  => \$opt_w, 	"warn=s"     => \$opt_w,
                "c=s"  => \$opt_c,      "crit=s"     => \$opt_c) ;


# -h means display verbose help screen
if ($opt_h) { print_help(); exit 0; }

# -V mean display version
if ($opt_V) { print_version(); exit 0; }

# -H means hostname and must be defined
$opt_H = shift unless ($opt_H);
unless ($opt_H) { print_usage(); exit -1; }

# -S means https 
if ( $opt_S ) {
  $proto="https://";
  $port=443;
} else {
  $proto="http://";
  $port=80;
}

# check if -p is used
if (defined $opt_p && $opt_p ne "" ) {
  $port=$opt_p ;
}

# check if -u is used, return / if not
my $url=$opt_u || "/" ;

for ($url) {
  if ( ! /^\// ) {
    $url = "/$url" ;
  }
}

# -w set warning level
if ( ! looks_like_number($opt_w) ) {
  if ( defined $opt_w ) {
    print "-w needs to be a number\n";
    exit -1 ;
  }
}

# -c set critical level
if ( ! looks_like_number($opt_c) ) {
  if ( defined $opt_c ) {
    print "-c needs to be a number\n";
    exit -1 ;
  }
}

#time_appconnect}:%{time_pretransfer}:%{time_redirect
print "cmd=$CMD_curl $curl_opts $proto$opt_H:$port$url\n" ;
$ret=`$CMD_curl $curl_opts $proto$opt_H:$port`;
(my $time_connect, my $time_start_xfr, my $time_total, my $time_dns, my $time_appconnect, my $time_prexfs, my $time_redirect )=split(/:/,$ret,7);

$data='' ;

$data .= "'Total time=$time_total"."s " ;
$data .= "'time connecting'=$time_connect"."s " ;
$data .= "'time start tramsfer'=$time_start_xfr"."s " ;
$data .= "'time dns lookup'=$time_dns"."s ";
$data .= "'time ssl connect'=$time_appconnect"."s ";
$data .= "'time neg. finished'=$time_prexfs"."s ";
$data .= "'time redirect'=$time_redirect"."s ";

my $status=$ERRORS{OK} ;

# make sure it's numeric

my $tt = eval $time_total ;

# check if warning is defined
if ( defined $opt_w ) {
  my $tw = eval $opt_w ;
  if ( $tt >= $tw ) {
    $status=$ERRORS{WARNING} ;
  }
}

# check if critial is defined
if ( defined $opt_c ) {
  my $tc = eval $opt_c ;
  if ( $tt >= $tc ) {
    $status=$ERRORS{CRITICAL} ;
  }
}


return_result($status,"Total time $time_total",$data) ;

#use lib "/opt/plugins";
 print_usage();
 return_result($ERRORS{UNKNOWN},"missing arguments");



#
# return result for nagios and exit with correct error level
#

sub return_result {
  my ($level,$msg,$data) = @_ ;

  #echo error text
  print $ERRORCODES{$level}." - ";

  #echo message
  print $msg ;

  #echo graph data if exist
  if (defined $data && $data ne "" ) {
    print "|$data" ;
  }

  print "\n" ;
  
  exit $level ;

}
 

sub print_version() {
  	my $arg0 =  $0;
	chomp $arg0;
	print "$arg0                        version $Version\n";
}

sub print_help() {
	print_version();
	print "\nCheck webserver returning multiple responstimesi\n\n";
	print_usage();
	print "\n";
	print "-H --hostname=HOST\n";
	print "   The name of address for webserver\n";
	print "-p --port=port number\n";
	print "   The port the webservice connects to\n";
        print "-S --SSL\n";
        print "connect with https\n";
        print "-u --uri=uri\n";
        print "   The uri path to request\n";
        print "-w --warn time\n";
        print "   The maximum respons time in seconds before command returns warning state\n";
	print "-c --crit time\n";
        print "   The maximum respons time in seconds before command return critical state\n";
}

sub print_usage() {
	print "check_web_pref -H host [-S] [-p port] [-u uri]\n";
	print " [-h | --help]\n";
	print " [-V | --version]\n";
} 
