#!/usr/bin/perl
#
package WilyMetrics::Logger;
use warnings;
use POSIX qw( strftime );
use FindBin;
use lib "$FindBin::Bin/.";
use MIME::Base64;

#Add trim functionality
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

#Get properties hash
my $PROPSFILE = "$FindBin::Bin/metrics.properties";
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
my $password        = $properties{'password'}       ? $properties{'password'}      : die "No 'password' provided in the metrics.properties file";
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

my $metricsDirectory = $properties{'metricsDirectory'}              ? $properties{'metricsDirectory'} : '/opt/splunkforwarder/wily-metrics-logger/metrics/';
my @metricsFiles = <$metricsDirectory/*>;
my $metricsFileCount = @metricsFiles;
# Clean Up number of files if required
while($metricsFileCount > $maxNumberMetricsFiles){
  my $file_to_delete = (sort{(stat $a)[10] <=> (stat $b)[10]}glob "$metricsDirectory/*.log")[0];
  unlink $file_to_delete;
  $metricsFileCount--;
}

my $auditDirectory = $properties{'auditDirectory'}                  ? $properties{'auditDirectory'}   : '/opt/splunkforwarder/wily-metrics-logger/audit/';
my @auditFiles = <$auditDirectory/*>;
my $auditFileCount = @auditFiles;
# Clean Up number of files if required
print $auditFileCount > $maxNumberAuditFiles;
while($auditFileCount > $maxNumberAuditFiles){
  my $file_to_delete = (sort{(stat $a)[10] <=> (stat $b)[10]}glob "$auditDirectory/*.log")[0];
  unlink $file_to_delete;
  $auditFileCount--;
}

my $errorDirectory = $properties{'errorDirectory'}                  ? $properties{'errorDirectory'}   : '/opt/splunkforwarder/wily-metrics-logger/error/';
my @errorFiles = <$errorDirectory/*>;
my $errorFileCount = @errorFiles;
# Clean Up number of files if required
while($errorFileCount > $maxNumberErrorFiles){
  my $file_to_delete = (sort{(stat $a)[10] <=> (stat $b)[10]}glob "$errorDirectory/*.log")[0];
  unlink $file_to_delete;
  $errorFileCount--;
}



my $metricsFileName = $metricsDirectory . "/metrics.log";
my $auditFileName   = $auditDirectory   . "/audit.log";
my $errorFileName   = $errorDirectory   . "/metrics.log";

my $sizeMetricsMB = ((-s $metricsFileName) || 0) / (1000 * 1000) ;
my $sizeErrorsMB = ((-s $errorFileName) || 0) / (1000 * 1000) ;
my $sizeAuditMB = ((-s $auditFileName) || 0) / (1000 * 1000) ;

my $startTime = time();

if ($sizeMetricsMB > $maxMetricsFileSizeMB){
  my $replace = "metrics-". strftime("%Y-%m-%d %H-%M-%S", localtime($startTime)) .".log";
  my $newName = $metricsFileName;
  my $find = "metrics.log";
  $find = quotemeta $find; # escape regex metachars if present
  $newName =~ s/$find/$replace/g;
  rename($metricsFileName, $newName) or die "Cannot rename metrics file: [$!]";
}

if ($sizeErrorsMB > $maxErrorFileSizeMB){
  my $replace = "error-". strftime("%Y-%m-%d %H-%M-%S", localtime($startTime)) .".log";
  my $newName = $errorFileName;
  my $find = "error.log";
  $find = quotemeta $find; # escape regex metachars if present
  $newName =~ s/$find/$replace/g;
  rename($errorFileName, $newName) or die "Cannot rename error file: [$!]";
}

if ($sizeAuditMB > $maxAuditFileSizeMB){
  my $replace = "audit-". strftime("%Y-%m-%d %H-%M-%S", localtime($startTime)) .".log";
  my $newName = $auditFileName;
  my $find = "audit.log";
  $find = quotemeta $find; # escape regex metachars if present
  $newName =~ s/$find/$replace/g;
  rename($auditFileName, $newName) or die "Cannot rename audit file: [$!]";
}


use Log::Log4perl;
my $confFile = "$FindBin::Bin/log4perl.conf";
Log::Log4perl::init_and_watch($confFile, 60);
my $errorLogger = Log::Log4perl->get_logger("error");
my $metricsLogger = Log::Log4perl->get_logger("metrics");
my $auditLogger = Log::Log4perl->get_logger("audit");


sub DoMetricsRequest{

  my $date1 = strftime("%Y-%m-%d %H:%M:%S", localtime($startTime - $offset - $range * 1));
  my $date2 = strftime("%Y-%m-%d %H:%M:%S", localtime($startTime - $offset - $range * 0));
  my $sumMetricCount = 0;
  my $sumValueCount = 0;
  my $stringValueCount = 0;
  my $dateValueCount = 0;
  my $otherValueCount = 0;

  # Resulting CLW Command:
  my $CLWCommand = "";
  my $opSys = "$^O\n";
  if("MSWin32" eq trim($opSys)){
    $CLWCommand = $CLWCommand."java -Xmx128M -Duser=$username -Dpassword=$password -Dhost=$momhost  -Dport=$port -jar $CLWorkstation " .
            "get historical data from agents matching $agentRegex and metrics matching $metricRegex " .
            "between $date1 and $date2 with frequency of $frequency seconds";
  }else{
    $CLWCommand = $CLWCommand."java -Xmx128M -Duser=$username -Dpassword=$password -Dhost=$momhost  -Dport=$port -jar $CLWorkstation " .
            "get historical data from agents matching '$agentRegex' and metrics matching '$metricRegex' " .
            "between '$date1' and '$date2' with frequency of '$frequency' seconds";
  }


  # Execute and open pipe for the CLWCommand
  my $clwpid = open (CLW, $CLWCommand . ' |') or die "Could not create pipe: $!\n";

  # Kill the CLWCommand if it takes longer than $timeout seconds
  local $SIG{ALRM} = sub {
          print STDERR "Timeout occured reading from pipe. CLWCommand\n";
          $errorLogger->error(localtime()." ERROR: Timeout occured reading from pipe. CLWCommand\n");
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

          my $CorrectedNumericValue = $IntegerValue;
          if($ValueType eq "Integer" or $ValueType eq "Long"){
            if (
                    $IntegerValue == $IntegerMax && # sig of IntCounter: value=max, min=any, count=any
                    !(
                            $IntegerMax == $ValueCount && $IntegerMin == 0 || #sig of PIC: value==max=count, min=0
                            $IntegerMax == $IntegerMin  # sig of avg: min<=value<=max, count=any
                    )
            ) {
                    $CorrectedNumericValue = ($IntegerMin+$IntegerMax)/2;
            }

            $sumMetricCount++;
            $sumValueCount++ unless $ValueCount == 0;

          }elsif($ValueType eq "String"){
            $stringValueCount++;
          }elsif($ValueType eq "Date"){
            $dateValueCount++;
          }else{
            $otherValueCount++;
            next;
          }

          # Output line to CSV log file
          $metricsLogger->info("$ActualStartTimestamp,$ActualEndTimestamp,$Domain,$Host,$Process,$AgentName,$Resource,$MetricName,$ValueType,$CorrectedNumericValue,$IntegerMin,$IntegerMax,$ValueCount,$StringValue,$DateValue");
          #print "$ActualStartTimestamp, $ActualEndTimestamp,$Domain,$Host!$Process!$AgentName,$Resource,$MetricName,$CorrectedValue\n";

  }
  alarm 0;
  close (CLW);
  my $pipestatus = ($? >> 8);
  if ($pipestatus) {
          print STDERR "Error code $pipestatus while running CLWCommand\n";
          $errorLogger->error(localtime()." ERROR: Return code of $pipestatus while running CLWCommand\n");
  }

  $auditLogger->info(localtime()." INFO: Finished in: ".(time()-$startTime)." seconds. sumMetricCount=$sumMetricCount, sumValueCount=$sumValueCount".
  ", stringValueCount=$stringValueCount, dateValueCount=$dateValueCount, otherValueCount=$otherValueCount"
  );
  $startTime = $startTime + $frequency;
}

DoMetricsRequest();

#Loop to run query on a specific interval:
#$interval = 60;
#for (;;) {
#    my $start = time;
#    DoMetricsRequest();
#    if ((my $remaining = $interval - (time - $start)) > 0) {
#        sleep $remaining;
#    }
#}
