# Azure Terraform use case
## Description

In an empty Azure Subscription, we need to deploy the following services using Terraform:
  - Azure Update (new Update Center experience)
    -   We need to create a Maintenance Configuration object that installs only Security and Critical updates on Windows Virtual Machines on the second Sunday of every month.
    -   An Azure Policy that applies this service to all the Virtual Machines with the tag AutoPatching=TRUE
  - Azure Defender for Cloud
    - Enable Azure Defender for Cloud
    - Create an Azure Policy that installs and enables Defender on each Virtual Machine with the tag Defender=TRUE
  - Create two Windows Virtual Machines
    -	**VM1**
      - Name: TESTDC01
      - Tag AutoPatching=FALSE
      - Tag Defender=TRUE
    -	**VM2**
      - Name: TESTAPP01
      - Tag AutoPatching=TRUE
      - Tag Defender=TRUE
    -	**All VMS have to be created with the following extensions**
      - Azure Monitor
      - Azure Defender for Cloud

While, for this exercise, you could need to create other resources like a simple vnet, the focus is to demonstrate the ability to create an Azure Policy-driven environment.
The goal is to create a Virtual Machine where Updates and Defender are automatically configured using Tags and Azure Policies.
