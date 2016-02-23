# Field Pack Name (Version)
splunkscript

# Description
Perl script to extract data from APM for splunk

## APM version
9.x, should work with 10.x

## Supported third party versions
unknown

## License
[Licensing](https://communities.ca.com/docs/DOC-231150910#license) on the CA APM Developer Community.*

Please review the 
**LICENSE**
file in this repository.  Licenses may vary by repository.  Your download and use of this software constitutes your agreement to this license.

# Installation Instructions
*How to install the field pack.*

Copy the perl script file to your EM.  You will need perl installed.

Set the following variables in the file to correct values

```
   my $LOGFILE = "/opt/Introscope/scripts/JMXaudit/wily_data.log";
   my $JAVA = "/opt/Introscope/jre/bin/java";
   my $CLWorkstation = "/opt/Introscope/lib/CLWorkstation.jar";
```

Then run the script (requires perl installed) 

This script was written by https://github.com/srikns

## Support
This document and associated tools are made available from CA Technologies as examples and provided at no charge as a courtesy to the CA APM Community at large. This resource may require modification for use in your environment. However, please note that this resource is not supported by CA Technologies, and inclusion in this site should not be construed to be an endorsement or recommendation by CA Technologies. These utilities are not covered by the CA Technologies software license agreement and there is no explicit or implied warranty from CA Technologies. They can be used and distributed freely amongst the CA APM Community, but not sold. As such, they are unsupported software, provided as is without warranty of any kind, express or implied, including but not limited to warranties of merchantability and fitness for a particular purpose. CA Technologies does not warrant that this resource will meet your requirements or that the operation of the resource will be uninterrupted or error free or that any defects will be corrected. The use of this resource implies that you understand and agree to the terms listed herein.

Although these utilities are unsupported, please let us know if you have any problems or questions by adding a comment to the CA APM Community Site area where the resource is located, so that the Author(s) may attempt to address the issue or question.

Unless explicitly stated otherwise this field pack is only supported on the same platforms as the APM core agent. See [APM Compatibility Guide](http://www.ca.com/us/support/ca-support-online/product-content/status/compatibility-matrix/application-performance-management-compatibility-guide.aspx).


# Contributing
The [CA APM Community](https://communities.ca.com/community/ca-apm) is the primary means of interfacing with other users and with the CA APM product team.  The [developer subcommunity](https://communities.ca.com/community/ca-apm/ca-developer-apm) is where you can learn more about building APM-based assets, find code examples, and ask questions of other developers and the CA APM product team.

If you wish to contribute to this or any other project, please refer to [easy instructions](https://communities.ca.com/docs/DOC-231150910) available on the CA APM Developer Community.

