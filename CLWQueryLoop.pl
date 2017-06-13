#!/usr/bin/perl
#
package WilyMetrics::Logger;
use warnings;
use POSIX qw( strftime );
use lib qw(./);

#Add trim functionality
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

#Get properties hash
my $PROPSFILE = ".\\metrics.properties";
open my $PROPS, "<$PROPSFILE" or die "cannot open properties file $PROPSFILE: $!";
my $properties = {};
while(my $prop = <$PROPS>){
  my $trimmedProp = trim($prop);
  my $firstchar = substr $trimmedProp, 0, 1;
  if( #Ignore comments, invalid entries and blank lines
      $firstchar eq '#' or
      index($trimmedProp, "=") == -1 or
      $trimmedProp eq ""
  ){
    next
  }
  my ($propname,$propvalue) = split("=",$trimmedProp);
  $properties{trim($propname)} = trim($propvalue);
}
close $PROPS;

#Required Properties / No Sensible Default:
my $username        = $properties{'username'}       ? $properties{'username'}      : die "No username provided in the metrics.properties file";
my $password        = $properties{'password'}       ? $properties{'password'}      : die "No password provided in the metrics.properties file";
my $momhost         = $properties{'momhost'}        ? $properties{'momhost'}       : die "No hostname provided for Wily MOM in the metrics.properties file";
my $agentRegex      = $properties{'agentRegex'}     ? $properties{'agentRegex'}    : die "No agentRegex provided in the metrics.properties file";

#Look Up property or use a sensible default:
my $CLWorkstation   = $properties{'CLWorkstation'}  ? $properties{'CLWorkstation'} : "/opt/Introscope/lib/CLWorkstation.jar";
my $metricRegex     = $properties{'metricRegex'}    ? $properties{'metricRegex'}   : "(.*)";
my $domainRegex     = $properties{'domainRegex'}    ? $properties{'domainRegex'}   : "(.*)";
my $port            = $properties{'port'}           ? $properties{'port'} + 0      : 6001;
my $offset          = $properties{'offset'}         ? $properties{'offset'} + 0    : 60;
my $range           = $properties{'range'}          ? $properties{'range'} + 0     : 60;
my $frequency       = $properties{'frequency'}      ? $properties{'frequency'} + 0 : 60;
my $timeout         = $properties{'timeout'}        ? $properties{'timeout'} + 0   : 45;
my $maxMetricsFileSizeMB = $properties{'maxMetricsFileSizeMB'}      ? $properties{'maxMetricsFileSizeMB'} + 0   : 100;
my $maxAuditFileSizeMB = $properties{'maxAuditFileSizeMB'}        ? $properties{'maxAuditFileSizeMB'} + 0   : 10;
my $maxErrorFileSizeMB = $properties{'maxErrorFileSizeMB'}        ? $properties{'maxErrorFileSizeMB'} + 0   : 10;
my $maxNumberMetricsFiles = $properties{'maxNumberMetricsFiles'}      ? $properties{'maxNumberMetricsFiles'} + 0 : 10;
my $maxNumberAuditFiles = $properties{'maxNumberAuditFiles'}        ? $properties{'maxNumberAuditFiles'} + 0   : 10;
my $maxNumberErrorFiles = $properties{'maxNumberErrorFiles'}        ? $properties{'maxNumberErrorFiles'} + 0   : 10;

use Log::Log4perl;
Log::Log4perl::init_and_watch('.\log4perlLoop.conf',60);
my $errorLogger = Log::Log4perl->get_logger("error");
my $metricsLogger = Log::Log4perl->get_logger("metrics");
my $auditLogger = Log::Log4perl->get_logger("audit");


# CSV Output Header
#$metricsLogger->info("ActualStartTimestamp,ActualEndTimestamp,Domain,Host,Process,AgentName,Resource,MetricName,CorrectedValue");
my $startTime = time();
sub DoMetricsRequest{

  my $date1 = strftime("%Y-%m-%d %H:%M:%S", localtime($startTime - $offset - $range * 1));
  my $date2 = strftime("%Y-%m-%d %H:%M:%S", localtime($startTime - $offset - $range * 0));
  my $sumMetricCount = 0;
  my $sumValueCount = 0;

  # Resulting CLW Command:
  my $CLWCommand = "java -Xmx128M -Duser=$username -Dpassword=$password -Dhost=$momhost  -Dport=$port -jar $CLWorkstation " .
          "get historical data from agents matching $agentRegex and metrics matching $metricRegex " .
  #        "for past 5 minute with frequency of 60 seconds";
          "between $date1 and $date2 with frequency of $frequency seconds";
  #print $CLWCommand;
  #exit 1;
  # Execute and open pipe for the CLWCommand
  my $clwpid = open (CLW, $CLWCommand . ' |') or die "Could not create pipe: $!\n";

  # Kill the CLWCommand if it takes longer than $timeout seconds
  local $SIG{ALRM} = sub {
          print STDERR "Timeout occured reading from pipe. CLWCommand: $CLWCommand\n";
          $errorLogger->error(localtime()." ERROR: Timeout occured reading from pipe. CLWCommand: $CLWCommand");
          kill 9, $clwpid;
  };
  alarm $timeout;

  # Iterate each line of output from the CLW query
  while (<CLW>)
  {
          # skip first two lines:
          next if 1..2;

          # Parse the line of CLW output
          my @fields = split (/,/, $_);
          # Ignore input unless its exactly 21 columns
          next unless @fields == 21;
          my ($Domain, $Host, $Process, $AgentName, $Resource, $MetricName, $RecordType, $Period,
                 $IntendedEndTimestamp, $ActualStartTimestamp, $ActualEndTimestamp,
                 $ValueCount, $ValueType, $IntegerValue, $IntegerMin, $IntegerMax,
                 $FloatValue, $FloatMin, $FloatMax, $StringValue, $DateValue, $Extra) = @fields;

          next if $Domain !~ $domainRegex;
          next unless $ValueType eq "Integer" or $ValueType eq "Long";

          # Correct values for IntCounter and LongCounter metrics
          my $CorrectedValue = $IntegerValue;
          if (
                  $IntegerValue == $IntegerMax && # sig of IntCounter: value=max, min=any, count=any
                  !(
                          $IntegerMax == $ValueCount && $IntegerMin == 0 || #sig of PIC: value==max=count, min=0
                          $IntegerMax == $IntegerMin  # sig of avg: min<=value<=max, count=any
                  )
          ) {
                  $CorrectedValue = ($IntegerMin+$IntegerMax)/2;
          }

                  $sumMetricCount++;
          $sumValueCount++ unless $ValueCount == 0;

          # Output line to CSV log file
          $metricsLogger->info("$ActualStartTimestamp, $ActualEndTimestamp,$Domain,$Host!$Process!$AgentName,$Resource,$MetricName,$CorrectedValue");
          #print "$ActualStartTimestamp, $ActualEndTimestamp,$Domain,$Host!$Process!$AgentName,$Resource,$MetricName,$CorrectedValue\n";

  }

  alarm 0;
  close (CLW);
  my $pipestatus = ($? >> 8);
  if ($pipestatus) {
          print STDERR "Error code $pipestatus while running CLWCommand: $CLWCommand\n";
          $errorLogger->error(localtime()." ERROR: Return code of $pipestatus while running CLWCommand: $CLWCommand");
  }

  $auditLogger->info(localtime()." INFO: Finished in: ".(time()-$startTime)." seconds. sumMetricCount=$sumMetricCount, sumValueCount=$sumValueCount");
  $startTime = $startTime + $frequency;

}

#Loop to run query on a specific interval:
$interval = 60;
for (;;) {
    print "Starting Loop\n----------\n";
    my $start = time;
    DoMetricsRequest();
    if ((my $remaining = $interval - (time - $start)) > 0) {
        print "Time remaining:\n";
        print $remaining."\n";
        sleep $remaining;
    }
    print "Ending Loop\n----------\n";
}
