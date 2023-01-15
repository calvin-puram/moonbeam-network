## Setting Up A Full Node On Moonbean Network

> Moonbeam makes it possible to use the popular Ethereum-based extension in the Polkadot ecosystem

Setting up a blockchain node infrastructure on GCP & AWS Vms Using:

* Terraform to create vm and manage disk
* Ansible for node configuration
* Packer for machine image creation
* Atlantis for terraform PR automation

Running a node on a Moonbeam-based network allows you to connect to the network, sync with a bootnode, obtain local access to RPC endpoints, and more. In this repository, we use supervisor to set up a service to run the lastest binary of:

* Moonriver
* Moonbeam
* Moonbease Alpha

 The minimum specs recommended to run a node are shown in the following table

 | **Components** 	|          **Requirement**         	|
|:--------------:	|:--------------------------------:	|
|       CPU      	| 8 Cores (Fastest per core speed) 	|
|       RAM      	|               16 GB              	|
|       SSD      	|        1 TB (recommended)        	|

