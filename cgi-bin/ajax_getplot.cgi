#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         ajax_getplot.cgi
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   The main function that:
#     1. Takes form values from the browser
#     2. Sends commands out to the ODE solver
#     3. Collects results to send back to the browser for graphing
#==============================================================================

use CGI qw/:standard/;
use Data::Dumper;
use JSON::Syck;                    # Convert between JSON and Perl objects
$Data::Dumper::Sortkeys = 1;
$CGI::POST_MAX = 1024 * 1024 * 10; # Max 10MB posts
$CGI::DISABLE_UPLOADS = 1;         # No uploads

#====================================================================
# Compile time items
#====================================================================
my @S_NAME;
my $F_ROOT;
BEGIN {

    # Folder root
    @S_NAME = split(/\//, $ENV{SCRIPT_NAME});
    $F_ROOT = $S_NAME[1];

    # Document root
    if(!$ENV{DOCUMENT_ROOT}) {
        $ENV{DOCUMENT_ROOT} = '/home/www';
    }

    # Restrict this script to AJAX calls only. This disallows directly executing
    # this script from the browser. This environment variable and value is set
    # by jQuery by default.
    if (exists $ENV{HTTP_X_REQUESTED_WITH} &&
               $ENV{HTTP_X_REQUESTED_WITH} eq "XMLHttpRequest") {
        # Looks good
    } else {
        # Return a message and exit
        my $q = CGI->new();
        print
            $q->header(-status=>'400 Bad Request',-type=>'text/html'),
            $q->start_html(-title=>'Bad Request'),
            $q->h1('Bad Request'),
            $q->end_html();
        exit 0;
    }
}

#====================================================================
# Generate JSON output
#====================================================================
use lib $ENV{DOCUMENT_ROOT}."/$F_ROOT/pm";
use THYROSIM;

# Create THYROSIM object
my $thsim = THYROSIM->new(setshow => 'default',
                          docRoot => $ENV{DOCUMENT_ROOT},
                          fRoot   => $F_ROOT);

# New CGI object and read form values from UI.
my $q = new CGI;
my $dat = $q->param('data'); # Form values are passed as 1 string
$thsim->processForm($dat);

#----------------------------------------------------------
# Define command. Currently using Java ODE solver. Command arguments are
# generated in the section below.
# Description of command arguments (zero-based):
# 0 - 18:  19 compartments' initial conditions.
# 19:      ODE start time.
# 20:      ODE end time.
# 21 - 24: Dial values (secretion/absorption).
# 25 - 26: Infusion values.
# 27:      The thysim parameters to load.
# 28:      Whether to initialize IC (recalculate IC).
# 29 - 77: Parameters kdelay and p1 - p48.
#----------------------------------------------------------
my $solver = $thsim->getSolver();
my $thysim = $thsim->getThysim();
my $ps     = $thsim->getParams();

#----------------------------------------------------------
# Decide whether to perform the 0th integration (i0).
# When the SS values are already known or if recalculate IC is off, i0 is
# skipped. Otherwise, perform i0. In either case, we must set the IC for the
# next integration, i1.
# NOTES: i0 runs the model to SS using clinically derived IC. This step is
# important because it allows material to enter the delay compartments. The end
# values of i0 are used as the IC of i1. We run i0 from 0-1008 hours so that it
# is a multiple of 24. This solved an issue where the initial day didn't start
# at exactly SS (i0 used to run from 0-1000 hours).
#----------------------------------------------------------
my $dials = $thsim->getDialString(); # Only needed once
my $ickey = $thsim->getICKey();
if ($thsim->hasICKey($ickey) || !$thsim->recalcIC()) { # Skipping i0
    $thsim->processKeyVal($ickey,'0');
} else {
    my $ICstr = $thsim->getICString('0');

    my $cmd = "$solver $ICstr 0 1008 $dials 0 0 $thysim initic $ps";
    my @res = `$cmd` or die "died: $!";
    $thsim->processResults(\@res,'0');
}

#----------------------------------------------------------
# Perform i1 to iX integrations.
# Integration intervals were determined in detIntSteps(), so here we retrieve
# them and call the solver.
#----------------------------------------------------------
my $iXs = $thsim->getIntCount();
foreach my $iThis (@$iXs) {
    my $start = $thsim->toHour($thsim->getIntStart('thisStep',$iThis));
    my $end   = $thsim->toHour($thsim->getIntBound('thisStep',$iThis));
    my $ICstr = $thsim->getICString($iThis);
    my $u     = $thsim->getInfValue($iThis);

    my $cmd = "$solver $ICstr $start $end $dials $u $thysim noinit $ps";
    my @res = `$cmd` or die "died: $!";
    $thsim->processResults(\@res,$iThis);
}

#----------------------------------------------------------
# Convert to JSON and print to browser
#----------------------------------------------------------
my $browserObj = $thsim->getBrowserObj();
print $q->header("text/html");
print JSON::Syck::Dump($browserObj);

#----------------------------------------------------------
# Error checking
#----------------------------------------------------------

# Print results to log. Make sure included comps were set to show.
#--------------------------------------------------
# my $reslog = $ENV{DOCUMENT_ROOT}."/$F_ROOT/tmp/reslog";
# $thsim->printCompResults($reslog,"t","1","4","7","ft4","ft3");
#-------------------------------------------------- 

#--------------------------------------------------
# my $reslog = $ENV{DOCUMENT_ROOT}."/$F_ROOT/tmp/reslog";
# $thsim->printInitialConditions($reslog);
#-------------------------------------------------- 

# Print objects to log
#--------------------------------------------------
# my $log = $ENV{DOCUMENT_ROOT}."/$F_ROOT/tmp/log";
# $thsim->printToLog($log,$thsim->{input},$thsim->{inputTime});
# $thsim->printToLog($log,\%ENV);
# $thsim->printToLog($log,$thsim->{params});
# $thsim->printToLog($log,$thsim->{CF});
#-------------------------------------------------- 
