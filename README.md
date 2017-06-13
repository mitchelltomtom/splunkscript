# Field Pack Name
splunkscript

# Description
Perl script to extract data from APM for splunk. Adapted from https://github.com/DuaneNielsen/splunkscript. 

Adds considerations for Windows when generating CLW requests 

Adds in a logger for **metrics**, **error** and **audit** logs and log file management capability specified in parameters (Use it's own copy of Log4Perl for ease of deployment). 

It also adds the capability to take in the query parameters from a properties file. 

## APM version
9.x, should work with 10.x

## Supported third party versions
unknown

## License
Original script licences
[Licensing](https://communities.ca.com/docs/DOC-231150910#license) on the CA APM Developer Community.*

Please review the 
**LICENSE**
file in this repository.  Licenses may vary by repository.  Your download and use of this software constitutes your agreement to this license.

# Installation Instructions
*How to install.*

Copy this folder to your EM.  You will need perl installed.

Create your **metrics**, **error** and **audit** output folders.

Configure the metrics.properties.template and rename to metrics.properties

Configure the log4perf.conf file with the correct **METRICS_LOGFILE.filename**, **AUDIT_LOGFILE.filename** and **ERROR_LOGFILE.filename** locations. 
**NOTE:** These files must be named **metrics.log**, **audit.log** and **error.log** and have a directory each, only the directory should change relevant to your desired output directories.

Run or schediled the **run.sh** (requires perl installed) 


# Disclaimer 
I am not a perl developer.

