The Multiple Stateful Import script is used to import multiple Instances at once to a Stateful Elastigroup.
Each Instance will be managed in it's own Elastigroup.

* This script recieves account_id, token and filename and imports Stateful instances as specified in the given file.
* Every line in the file is equal to one instance
* The line format should be: instance_id;elastigroup_name;region;instance_types;shouldKeepPrivateIP(true/false);
* Instance types should be written: instance_type1,instance_type2,...
* If shouldKeepPrivateIP is set to true the original instance will be terminated in the process
* and the Elastigroup will be configured to Maintain Private IP
* Example: i-01365b71385ef3b86;elastigorup-stateful;us-west-2;t2.medium,t3.large;False
