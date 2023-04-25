# Provisioning Necessary Cloud Infrastructure using Terraform

Having a pre-configured AMI built by Packer and Ansible, Terraform can now be used to create the exam network infrastructure and the cloud instance for each examinee.

However, since the Terraform environment is going to be integrated into the NodeJS backend server which will be distributed across multiple nodes, [lots of conflicts and inconsistencies will arise due to how Terraform State is stored locally by default](https://www.terraform.io/language/state/purpose). Therefore, a Remote State Backend has been created to store Terraform State remotely.

**Note:** for Terraform variables, since Terraform CLI is invoked from NodeJS REST API server per request, this project frequently uses the approach of using the “-var” command-line argument to assign variables individually.

Throughout this document, [execution dependency graphs generated by Terraform CLI](https://developer.hashicorp.com/terraform/cli/commands/graph) has been used to visualize the dependencies between terraform resources used for the creation of different infrastructure.

## Creating Terraform Remote State Backend

AWS S3 bucket enabled with versioning for data recovery and server-side encryption for security purposes has been created to store the Terraform State. Moreover, as a means of state synchronization and write-conflicts resolution, a DynamoDB table has been created with a configured hash/partition key named ‘LockID’, which is reserved for Terraform. This acts as a binary lock where at most one invocation that modifies the state can acquire the lock at a time, hence, eliminating the issues of Terraform State in a distributed environment.

Additionally, Terraform Workspaces have been utilized and integrated with the Remote Terraform State to be able to provision different infrastructure instances from the same configuration file, each having its own state. For visualization:
![Terraform Remote State Backend execution graph](https://github.com/zSorour/Examatic/blob/master/images/AWS%20S3%20DynamoDB%20Backend%20Terraform%20Execution%20Graph.png?raw=true 'Terraform Remote State Backend execution graph')

## Usage of Terraform Workspaces

For traditional use cases of Terraform, having a single state for a configuration file is perfectly fine. Typically, a Terraform module of configuration files is responsible for managing a set of infrastructure resources in what is known as a “default” workspace.

But what if it is required to manage different distinct copies of a set of infrastructure, each having its own state independent of the others, using the same configuration files? For example, all students undertaking the same exam should have EC2 instances initialized from the same configuration file, however, each having their own state. To solve such an issue, Terraform Workspaces can be utilized to allow multiple states to be associated with the same configuration files.

The configuration files still have one remote backend for state management and synchronization, however, distinct infrastructure resources created from the same configuration files can have their own state without having to create new backends or change anything related to the configuration.

This project utilizes Terraform Workspaces technique to effectively manage multiple EC2 instances and networks created for each exam, each having their own state although generated from the same configuration files. The following sections further illustrate the usage of Workspaces in managing the network components and the EC2 instances necessary for carrying out
a practical software lab exam online in the cloud.

## Provisioning Exam Network Infrastructure

To create the exam network infrastructure, Terraform configuration files have been written to use the Remote State backend with a workspace prefix of “exam_vpcs” so that the state files of the created exams network infrastructure will be isolated in an “exam_vpcs” path. Moreover, each exam is given a unique workspace name, typically the exam ID or the exam unique name. Example:
![Distinct workspace for each exam vpc](https://github.com/zSorour/Examatic/blob/master/images/Distinct%20Workspaces%20for%20Each%20Examp%20VPC.png?raw=true 'Distinct workspace for each exam vpc')

Finally, the Terraform configurations and resources necessary for creating the exam infrastructure have been defined such as a Virtual Private Cloud (VPC), a public subnet, an internet gateway, a custom routing table, and a security group containing all the necessary firewall rules. Moreover, the outputs **vpc_id** and **sg_id** have been defined so that they can be outputted and parsed by the NodeJS backend server as the exam network infrastructure is created. Their values will be used as input variables for the creation of the exam EC2 instance itself. For visualization:
![Exam network infrastructure Terraform execution graph](https://github.com/zSorour/Examatic/blob/master/images/Excution%20Graph%20of%20Terraform%20Resources%20for%20Creating%20Exams%20VPCs.png?raw=true 'Exam network infrastructure Terraform execution graph')

## Provisioning Exam EC2 Instance

As for the creation of the exam instance itself (in which each student connects to a designated ec2 instance), the workspace prefix ‘exam_instances’ has been used, and a concatenation of the examinee ID and the exam ID is used for the unique workspace name. For example, if a student of ID “ahmad186081” is undertaking an exam with unique name “21CS123-LABTEST1”, the Workspace name will be “21CS123-LABTEST1-ahmad186081”. The Terraform state file of such Workspace would be typically stored in the remote backend AWS S3 bucket in the path “186081-gp-tf-backend-state/examinstances/21CS123-LABTEST1-ahmad186081/backend-state”.

The Terraform configuration files have been configured to build an EC2 instance referencing the **sg_id** and **vpc_id** that have been generated from the previous step and parsed by the NodeJS backend invoking Terraform. Similarly, [the AMI name of the server template that has been initially created via Packer](https://github.com/zSorour/Examatic/tree/master/packer-windows-vs-template#building-a-vm-image-server-template-using-packer) is supplied from the NodeJS backend.

With such workflow, a cloud instance that is preconfigured with all the required exam material is instantiated via Terraform on-demand, whenever invoked by the NodeJS backend server. The output variables **instance_ip** and **temp_password** are then parsed by the NodeJS backend and persisted in the database. These will be send to the student whenever requested so that they can connect to the designated provisioned exam instance. For visualization of the Exam EC2 instance Terraform dependencies:
![Execution Dependency Graph of the Terraform Resources Used to Create an EC2](https://github.com/zSorour/Examatic/blob/master/images/Execution%20Dependency%20Graph%20of%20the%20Terraform%20Resources%20Used%20to%20Create%20an%20EC2.png?raw=true 'Execution Dependency Graph of the Terraform Resources Used to Create an EC2')