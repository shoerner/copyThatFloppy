#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5;

$| = 1; #Sync writes.

my $floppyIndex = 0;
my $storageDir = '/home/'. $ENV{"USER"} . '/floppyStorage/';
my $doMD5 = 0;

# Sub to copy that floppy
sub doCopy
{
	my $floppyDigest = Digest::MD5->new if $doMD5 != 0;
	# I have read that it is a simple cat to get the floppy drive moved
	# So lets try to grab it using 'open'
	open(my $floppyDrive, '<' , '/dev/fd0');

	# Check to see if anticipated filename exists
	my $filename =  $storageDir . "floppy$floppyIndex.bin";
	if(-e $filename)
	{
		print "File already exists. Overwrite? \n[Y/n]: ";
		my $choice = <>;
		chomp($choice);
		if(lc($choice) eq 'y')
		{
			#Overwrite file. Delete it first just in case
			unlink($filename);
		}
		elsif(lc($choice) eq 'n')
		{
			# Halt execution
			# TODO: Allow rename
			exit(253);
		}
		else
		{
			#User is ignorant. Halt execution because I said so
			exit(444);
		}
	}
	# Open a file for output
	open(my $floppyOutput, '>', $storageDir . "floppy$floppyIndex.bin");

	while(<$floppyDrive>)
	{
		print $floppyOutput $_;

		# Begin calculating floppy drive checksum (if marked)
		$floppyDigest->add($_) if $doMD5 != 0;
	}

	close($floppyOutput);
	close($floppyDrive);

	if($doMD5 != 0)
	{
		# Get Checksum from final filehandle
		# This could be done without reopening the file if the input type were to change.

		# Given the nature of the medium and potential for loss, closing and reopening the file seems 
		# like a better choice
		open(my $floppyOutput, '<', $storageDir . "floppy$floppyIndex.bin");

		# Create digest object
		my $outputDigest = Digest::MD5->new;
		$outputDigest->addfile($floppyOutput);

		# Close the read
		close($floppyOutput);

		# Perform final digest calcluations
		my $floppyResult = $floppyDigest->digest;
		my $outputResult = $outputDigest->digest;
		if($floppyResult ne $outputResult)
		{
			# Alert the user
			print "!!! Floppy and output files have differing MD5 sums [$floppyResult vs $outputResult]\n";

			# Re-run sub
			doCopy();
		}
	}
}

# Sense what index we are at in the files
sub senseFiles
{
	# Operational requirement: each floppy file will be named floppy[index].bin

	opendir(DIR,$storageDir);
	my @files = readdir(DIR);
	closedir(DIR);

	@files = sort @files;

	# Filename we want is the last one plus one
	my $lastFile = $files[-1];

	# Remove everything not a number to get the final string
	$lastFile =~ s/[^0-9]//g;

	# Add one for one more file and begin
	$floppyIndex = $lastFile++;

	print "Scans show next file should be $floppyIndex\n\n";
}

# Sub for operator intervention
sub doOperator
{
	print "Please insert floppy... <Ctrl-C to exit>";
	my $nothingness = <>;

	print "Now creating floppy image: floppy$floppyIndex.bin\n";
	doCopy();

	# Increment floppy count.
	$floppyIndex++;
}

if(defined $ARGV[0] && -e $ARGV[0])
{
	$storageDir = $ARGV[0] . '/';
}

# Begin execution.
print "+-------------------------------------------------------------------------------------+\n";
print "| 							shoerner's \"Copy That Floppy\"							   |\n";
print "+-------------------------------------------------------------------------------------+\n\n";

print " Performing directory check to see if older files exist...\n";
senseFiles();

print "Beginning copy loop. Press <Ctrl-C> to exit.\n\n";

while(1)
{
	doOperator();
}