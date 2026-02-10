#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         ThyrosimAdvanced.cgi
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   Show UI for Thyrosim, Advanced.
#==============================================================================

use CGI qw/:standard/;
use Data::Dumper;
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
}

#====================================================================
# Initialize page
#====================================================================
use lib $ENV{DOCUMENT_ROOT}."/$F_ROOT/pm";
use THYROSIM;
use THYROWEB;

my $ts = THYROSIM->new(setshow => 'default',
                       docRoot => $ENV{DOCUMENT_ROOT},
                       fRoot   => $F_ROOT,
                       thysim  => 'Thyrosim',
                       loadParams => 1);
my $tw = THYROWEB->new(THYROSIM => $ts,
                       advanced => 1);

my $q = new CGI();

print $q->header("text/html");
print $q->start_html($tw->getHead());

print $tw->insertForm();

print $q->end_html();

#====================================================================
# Section
#====================================================================

#----------------------------------------------------------
# Sub-section
#----------------------------------------------------------
