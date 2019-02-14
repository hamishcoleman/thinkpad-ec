#!/usr/bin/env perl
use warnings;
use strict;
#
# Apply a diff of two hexdumps as a binary patch
#
# Copyright (C) 2016-2019 Hamish Coleman

use IO::File;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Quotekeys = 0;

sub usage() {
    print("This utility will take a diff of two hexdumps and can apply\n");
    print("the binary changes to the original binary file, using the\n");
    print("context lines to provide data to match and confirm we are\n");
    print("patching the right file\n");
    print("\n");
    print("Usage:\n");
    print("  hexpatch.pl [--rm_on_fail] [--report file] binaryfile patchfile [patchfile...]\n");
    print("\n");
    exit(1);
}

sub parse_hexline {
    my $line = shift;

    my $addr;
    my $binary;

    my @fields = split(/\s+/,$line);

    if ($fields[0] !~ m/^([0-9a-fA-F])+$/) {
        return undef;
    }
    $addr = hex($fields[0]);
    shift @fields;

    while (defined($fields[0]) && $fields[0] =~ m/^([0-9a-fA-F])+$/) {
        $binary .= chr(hex($fields[0]));
        shift @fields;
    }

    return ($addr,$binary);
}

sub read_patchfile {
    my $filename = shift;

    my $fh = IO::File->new($filename, O_RDONLY);
    if (!defined($fh)) {
        return undef;
    }

    my $db = {};

    my $seen_at_symbols = 0;

    while(<$fh>) {
        # anything before we see a starting at symbol line can be ignored
        if (!$seen_at_symbols) {
            if (m/^\@\@ (.*) \@\@$/) {
                $seen_at_symbols = 1;
                $db->{name} = $1;
            }
            next;
        }

        my $addr;
        my $binary;
        my $type;
        if (m/^([-+ ])(.*)/) {
            # a context, oldfile or newfile line
            $type = $1;
            ($addr, $binary) = parse_hexline($2);
        } elsif (m/^\@\@ .* \@\@$/) {
            # hunk separator - we can ignore it since we use the hex addr
            next;
        } else {
            warn("Invalid prefix in patchfile");
            # TODO - linenumber
            return(undef);
        }

        if (!defined($addr)) {
            warn("Invalid data in hexline");
            # TODO - linenumber
            return(undef);
        }

        if (!defined($binary)) {
            # this line was empty of data
            next;
        }

        if ($type eq ' ') {
            $type = 'context';
        } elsif ($type eq '-') {
            $type = 'old';
        } elsif ($type eq '+') {
            $type = 'new';
        }

        if (defined($db->{addr}{$addr}{$type})) {
            warn("Duplicate address in hexdata");
            # TODO - linenumber
            return(undef);
        }

        $db->{addr}{$addr}{$type} = $binary;
    }
    return $db;
}

sub verify_context {
    my $db = shift;
    my $fh = shift;

    for my $addr (sort keys(%{$db->{addr}})) {
        my $entry = $db->{addr}{$addr};
        my $expected;
        if ($entry->{context}) {
            $expected = $entry->{context};
        } elsif ($entry->{old}) {
            $expected = $entry->{old};
        } elsif ($entry->{new}) {
            warn("Address $addr has new data but no old data\n");
            return undef;
        } else {
            # No data of any kind here, just skip it
            next;
        }

        my $found;
        $fh->seek($addr,SEEK_SET);
        $fh->read($found,length($expected));

        # TODO - if found eq new warn "patch reversed?"
        if ($found ne $expected) {
            warn("Address $addr mismatched data\n");
            printf("found:  0x%08x: %s\n", $addr, join(' ',unpack('(H2)*', $found)));
            printf("expect: 0x%08x: %s\n", $addr, join(' ',unpack('(H2)*', $expected)));
            return undef;
        }
    }
    return 1;
}

sub apply_patch {
    my $db = shift;
    my $fh = shift;

    for my $addr (sort keys(%{$db->{addr}})) {
        my $entry = $db->{addr}{$addr};

        my $newdata;
        if ($entry->{new}) {
            $newdata = $entry->{new};
        } else {
            # No data to write at this address, just skip it
            next;
        }

        $fh->seek($addr,SEEK_SET);
        $fh->print($newdata);

    }
}

sub output_report {
    my $filename = shift;
    my @patches = @_;

    my $fh = IO::File->new($filename, "w");
    if (!defined($fh)) {
        warn("Could not open report file $filename: $!\n");
        exit(1);
    }

    if (!@patches) {
        $fh->print("No patches applied: Lenovo default firmware\n");
        return;
    }

    $fh->print("Patches applied:\n");
    my $line = "";
    for my $patch (@patches) {
        if (length($line)+length($patch)+1 > 79) {
            $line .= "\n";
            $fh->print($line);
            $line = "";
        }
        if ($line) {
            $line .= " ";
        }
        $line .= $patch;
    }
    if ($line) {
        $line .= "\n";
        $fh->print($line);
    }
}

sub rm_on_fail {
    my ($bool, $filename) = @_;

    if ($bool) {
        unlink($filename);
    }
}

sub main() {
    my $rm_on_fail;
    if (defined($ARGV[0]) && $ARGV[0] eq "--rm_on_fail") {
        $rm_on_fail=1;
        shift @ARGV;
    }

    my $reportfile;
    if (defined($ARGV[0]) && $ARGV[0] eq "--report") {
        shift @ARGV;
        $reportfile=shift @ARGV;
    }

    my $binaryfile = shift @ARGV;
    if (!defined($binaryfile) or !defined($ARGV[0])) {
        usage();
    }

    my $fh = IO::File->new($binaryfile, O_RDWR);
    if (!defined($fh)) {
        warn("Could not open binaryfile\n");
        exit(1);
    }

    print("Attempting to patch $binaryfile\n");

    my @report_patches;
    while ($ARGV[0]) {
        my $patchfile = shift @ARGV;

        if (!-e $patchfile) {
            warn("Patchfile $patchfile not present, skipping\n");
            next;
        }

        my $db = read_patchfile($patchfile);

        if (!defined($db)) {
            warn("Cannot read $patchfile\n");
            rm_on_fail($rm_on_fail,$binaryfile);
            exit(1);
        }

        if (!verify_context($db,$fh)) {
            warn("The binaryfile does not match the context bytes from $patchfile\n");
            rm_on_fail($rm_on_fail,$binaryfile);
            exit(1);
        }

        print("Applying ",$patchfile," ",$db->{name},"\n");
        apply_patch($db,$fh);
        push @report_patches,$patchfile;
    }

    if ($reportfile) {
        output_report($reportfile,@report_patches);
    }
}
main();

