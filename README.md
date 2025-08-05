# HCL Universal Orchestrator

## Introduction
HCL Universal Orchestrator is a cloud-native process orchestrator and requires to be deployed on a Kubernetes platform, either on a public or a private cloud infrastructure. A cloud deployment ensures access anytime anywhere and is a fast and efficient way to get up and running quickly. It also simplifies maintenance, lowers costs, provides rapid upscale and downscale, minimizes IT requirements and physical on-premises data storage.

As more and more organizations move their critical applications to the cloud, there is an increasing demand for solutions and services that help them easily migrate and manage their cloud environment.

To respond to the growing request to make automation opportunities more accessible, HCL Universal Orchestrator containers can be deployed into the following supported third-party cloud provider infrastructures:

- ![Amazon EKS](images/tagawseks.png "Amazon EKS") Amazon Web Services (AWS) Elastic Kubernetes Service (EKS)
- ![Microsoft Azure](images/tagmsa.png "Microsoft Azure") Microsoft&reg; Azure Kubernetes Service (AKS)
- ![Google GKE](images/taggke.png "Google GKE") Google Kubernetes Engine (GKE)
- ![OpenShift](images/tagOpenShift.png "OpenShift") OpenShift (OCP)

HCL Universal Orchestrator is a complete, modern solution to orchestrate calendar-based and event-driven tasks, business and IT processes. It enables organizations to gain complete visibility and control over attended or unattended workflows. From a single point of control, it supports multiple platforms and provides advanced integration with enterprise applications including ERP, Business Analytics, File Transfer, Big Data, and Cloud applications.

For more information about HCL Universal Orchestrator, see the product documentation library in [HCL Universal Orchestrator documentation](https://help.hcltechsw.com/UnO/v2.1.2/index.html).

## Details

All microservices and the UnO Console are installed. The Dynamic Workload Console is available by enabling a specific parameter in the values.yaml file.

To achieve high availability in an HCL Universal Orchestrator environment, the minimum base configuration is composed of 2 replicas of all microservices.

HCL Universal Orchestrator can be deployed across a single cluster, but you can add multiple instances of the product microservices by using a different namespace in the cluster. The product microservices can run in multiple failure zones in a single cluster.

 
## Supported Platforms

- ![Amazon EKS](images/tagawseks.png "Amazon EKS") Amazon Elastic Kubernetes Service (EKS) on amd64: 64-bit Intel/AMD x86
- ![Microsoft Azure](images/tagmsa.png "Microsoft Azure") Azure Kubernetes Service (AKS) on amd64: 64-bit Intel/AMD x86
- ![Google GKE](images/taggke.png "Google GKE") Google Kubernetes Engine (GKE) on amd64: 64-bit Intel/AMD x86
- ![OpenShift](images/tagOpenShift.png "OpenShift") OpenShift (OCP)
- Any Kubernetes platform from V1.29 and above

HCL Universal Orchestrator supports all the platforms supported by the runtime provider of your choice.

### Openshift support
You can deploy HCL Universal Orchestrator on Openshift by following the instruction in this documentation and using helm charts. 
Ensure you modify the value of the `waconsole.console.exposeServiceType` parameter from `LoadBalancer` to `Routes`.
	
## Accessing the container images


You do not need a license key to access the container images. Instead, use the same credentials you use for HCL services through OIDC provider to pull the necessary images from the HCL Container Registry. The images are as follows:

Core:

 - hcl-uno-agentmanager
 - hcl-uno-gateway
 - hcl-uno-iaa
 - hcl-uno-scheduler
 - hcl-uno-storage
 - hcl-uno-toolbox
 - hcl-uno-audit
 - hcl-uno-timer
 - hcl-uno-executor
 - hcl-uno-eventmanager 
 - hcl-uno-orchestrator
 - hcl-uno-console
 - hcl-uno-notification
 - hcl-uno-external-pod

UnO AI Pilot:

 - hcl-uno-pilot-notification
 - hcl-aipilot-core
 - hcl-aipilot-actions
 - hcl-aipilot-nlg
 - pgvector
 
 UnO Agentic AI Builder:

 - hcl-agentic-ams
 - hcl-agentic-runner
 - hcl-agentic-cm

## Prerequisites
Before you begin the deployment process, ensure your environment meets the following prerequisites:

**Mandatory**
 - Kubectl v 1.29.4 or later
 - Kubernetes cluster v 1.29 or later
 - Helm v 3.12 or later
 - Messaging system: Apache Kafka v 3.4.0 or later OR Redpanda v 23.11 or later 
 - Database: MongoDB v 5 or later OR Azure Cosmos DB for MongoDB (vCore) OR DocumentDB v 5 for AWS deployment.
 - Enablement of an OIDC provider.
 
 **For Agentic AI Builder**
 - Valkey (Redis-compatible): Used as the in-memory data store. Acts as a drop-in replacement for Redis.
 - PostgreSQL: Serves as the primary relational database for storing application data.
 - APISIX Gateway: Functions as the API gateway to route traffic to services. Includes the following:
  * etcd: Backend key-value store for APISIX configuration.
  * Ingress Controller: Manages ingress traffic rules.
  * APISIX Dashboard: Web interface for managing gateway configurations.

**Strongly recommended**

 - Jetstack cert-manager

  We strongly recommend the use of a cert-manager as it automatically generates and updates the required certificates. You can choose not to use it, in which case you need to:
         
   - Create your own custom certificates
   - Insert the certificates inside the correct Kubernetes secrets
   - Make sure that the names of the Kubernetes secrets match the names specified in the `values.yaml`deployment file

**Optional**
-   Grafana and Prometheus for monitoring dashboard

The following are prerequisites specific to each supported cloud provider:

![Amazon EKS](images/tagawseks.png "Amazon EKS") 
- Amazon Kubernetes Service (EKS) installed and running
- AWS CLI (AWS command line)

![Microsoft Azure](images/tagmsa.png "Microsoft Azure") 
- Azure Kubernetes Service (AKS) installed and running
- azcli (Azure command line)

![Google GKE](images/taggke.png "Google GKE") 
- Google Kubernetes Engine (GKE) installed and running
- gcloud SDK (Google command line)


## Resources Required
  
 The following resources correspond to the default values required to manage a production environment. These numbers might vary depending on the environment.
 
| Component | Container resource limit | Container resource request |
|--|--|--|
|**uno-orchestrator microservice**  | CPU: 2, Memory: 1 GB  |CPU: 0.6, Memory: 1 GB|
|**Each remaining microservice**  | CPU: 2, Memory: 1 GB  |CPU: 0.6, Memory: 0.5 GB  |
|**Dynamic Workload Console**  | CPU: 4, Memory: 16 GB  |CPU: 1, Memory: 4 GB, Storage: 5 GB  |
|**AIPilot-core** | CPU : 1, Memory: 2.5GB | CPU 0.5, Memory: 2GB
|**AIPilot-action**| CPU: 0.3, Memory: 0.3GB | CPU: 0.1, Memory: 0.2GB
|**AIPilot-nlg**| CPU: 0.3, Memory: 0.5GB | CPU: 0.1, Memory: 0.3GB
|**AIPilot-rag**| CPU: 0.8, Memory: 1Gi | CPU: 0.2 , Memory: 0.2Gi
|**PgVector**| CPU: 0.15 Memory: 0.192GB Ephemeral-storage : 2Gi |  CPU: 0.1 Memory: 0.1Gi Ephemeral-storage: 50Mi

No disk space is required for the microservices, however, at least 100 GB are recommended for Kafka and 100 GB for MongoDB. Requirements vary depending on your workload.

## Deploying

Deploying and configuring HCL Universal Orchestrator involves the following high-level steps:

1. [Creating the Namespace](#creating-the-namespace)
2. [Creating a Kubernetes Secret](#creating-the-secret) by accessing the entitled registry to store an entitlement key for the HCL Universal Orchestrator offering on your cluster. 
3. [Deploying the product components](#deploying-the-product-components)
4. [Configuring optional product components](#configuring-optional-product-components)
5. [Verifying the deployment](#verifying-the-deployment)


### Creating the Namespace

To create the namespace, run the following command:

        kubectl create namespace <uno_namespace>
	
### Creating the Secret 

If you already have a license, then you can proceed to obtain your entitlement key. To learn more about acquiring an HCL Universal Orchestrator license, contact HWAinfo@hcl.com. 

Obtain your entitlement key and store it on your cluster by creating a [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/). Using a Kubernetes secret allows you to securely store the key on your cluster and access the registry to download the chart and product images. 

1. Access the entitled registry with your OIDC credentials after being accepted into the beta program.
2. To create a pull secret for your entitlement key that enables access to the entitled registry, run the following command:

         kubectl create secret docker-registry -n <uno_namespace> sa-<uno_namespace> --docker-server=<registry_server> --docker-username=<user_name> --docker-password=<password>
	   
	where,
	* <uno_namespace> represents the namespace where the product components are installed
	* <registry_server> is `hclcr.io`
	* <user_name> is the user name provided by your HCL representative
	* \<password> is the entitled key copied from the entitled registry `<api_key>`


### Deploying the product components		

Before starting to deploy the product components, make sure that all the [prerequisites](#prerequisites) are met.

To deploy HCL Universal Orchestrator, perform the following steps:

1. Log into the registry:
 
        helm registry login hclcr.io  
   
2. Pull the Helm chart:

        helm pull oci://hclcr.io/uno-ea/hcl-uno-chart --version 2.1.2-beta3
	
**Note:** If you want to download a specific version of the chart use the `--version` option in the `helm pull` command.
	
3. Customize the deployment.

   Configure each product component by adjusting the values in the **values.yaml** file. The **values.yaml** file contains a detailed explanation for each parameter.

- Accepting the license agreement

The licence parameter determines whether the licence agreement is accepted or not. Supported values are `accept` and `not accepted`. To accept the license agreement, set the value as:

    global.license: accept


- Configuring the database section in the values.yaml file

The values of the following parameters are placeholders used as an example. When assigning values to these parameters in your values.yaml file, make sure that they reflect the values used in the database deployment configuration.

    uno.database.url: mongodb://hcl-uno-db-mongodb.db.svc.cluster.local:27017
    uno.database.type: mongodb
    uno.database.databaseName: uno
    uno.database.username: mongouser
    uno.database.password: mongopassword
    uno.database.tls: false
    uno.database.tlsInsecure: false
   

- Configuring the kafka section in the values.yaml file

The values of the following parameters are placeholders used as an example. When assigning values to these parameters in your values.yaml file, make sure that they reflect the values used in the kafka deployment configuration.

    uno.kafka.url: hcl-uno-kafka-0.kafka-headless.kafka.svc.cluster.local:9092
    uno.kafka.username: kafkauser
    uno.kafka.password: kafkapassword
    uno.kafka.tls: false
    uno.kafka.saslMechanism: PLAIN
    uno.kafka.jaasConfig: org.apache.kafka.common.security.plain.PlainLoginModule required username="my-username" password="my-password";
    uno.kafka.securityProtocol: SASL_PLAINTEXT
    uno.kafka.tlsInsecure: false
    uno.kafka.kerberosServiceName: kerberosservicenameexample
    uno.kafka.topicReplicas: 1

- Configuring the authentication.oidc section in the **values.yaml** file

You can enable an OIDC user registry by configuring the **values.yaml** deployment file as follows:

    uno.authentication.oidc.enabled: true

The values of the following parameters are placeholders used as an example. When assigning values to these parameters in your values.yaml file, make sure that they reflect the values used in the OIDC deployment configuration.

    uno.authentication.oidc.server: https://unokeycloak.k8s.uat.uno/realms/uno
    uno.authentication.oidc.clientId: uno-service
    uno.authentication.oidc.credentialSecret: put_oidc_secret_here
    uno.authentication.oidc.tlsVerification: required

- Configuring the networking in the **values.yaml** file

  The HCL Universal Orchestrator server and console can use two different ways to route external traffic into the Kubernetes Service cluster:

* **Ingress** and OpenShift **routes** services that manage external access to the services in the cluster.

  To configure an ingress control for the microservices, set the following parameters in the **values.yaml** file:

      uno.ingress.ingressClassName: nginx
      uno.ingress.baseDomainName: .k8s.uat.uno

  If you are using OpenShift routes, set the following parameter is the **values.yaml** file to false:

      uno.ingress.enabled: false

  To make sure HCL Universal Orchestrator tusts the external components used for the environment deployment, you must assign the certificate values of the external components as secrets for the following parameters:

    uno.config.certificates.additionalCASecrets: certificatesecret

4. Deploy the instance by running the following command: 

        helm install -f values.yaml <uno_release_name> <repo_name>/hcl-uno-chart -n <uno_namespace>

 where 
   <uno_release_name> is the deployment name of the instance.
   
**TIP:** Use a short name or acronym when specifying this value to ensure it is readable.

The following are some useful Helm commands:

* To list all of the Repo releases: 

        helm list -A
	
* To update the Helm release:

        helm upgrade <uno_release_name> <repo_name>/hcl-uno-chart -f values.yaml -n <uno_namespace>
		
* To update helm repo release:
  
        helm repo update
	
* To delete the Helm release: 

        helm uninstall <uno_release_name> -n <uno_namespace>

### Configuring optional product components

**Human task e-mail notifications**

Human tasks are associated with queues, which act as containers for Human tasks. When a Human task is created, it references a specific queue, which is defined by a folder and a name. When defining a queue, you can customize its notification behavior by overriding the global settings. The available optional parameters are **Group email** and **Sender name**; for more information, see [Human task queues](https://help.hcl-software.com/UnO/v2.1.2/Focused_Scenarios/Task/c_queue.html).

To enable e-mail notifications, edit the **values.yaml** file to set the `uno.mail.enabled` parameter to `true`, and then specify the required Simple Mail Transfer Protocol (SMTP) configuration parameters and credentials. 

For more information about email notifications and notification templates, see [Human tasks](https://help.hcl-software.com/UnO/v2.1.2/Focused_Scenarios/Task/c_human_task.html).

**AI Agents**

You can create an AI agent using three different agent types: External MCP, Basic, and Agentic AI Builder. For more information, see [Managing agent types in the AI Agent] (https://help.hcl-software.com/UnO/v2.1.2/Orchestrating/to_manage_agent_types.html).

**UnoAIPilot**

You can enable UnoAIPilot by configuring the **values.yaml** file as follows: 
		
		global.enableUnoAIPilot: true
  


**Generative AI**

You can enable generative AI features by requesting access. You will then receive a specific genAikey to insert into your values.yaml file here:

    uno:
      config:
        genai:
          enabled: true
          serviceUrl: https://genai.hcluno.mywire.org
          betaKey: <GenAIKey>



**Session timeout**

After a period of inactivity on the UI, users are automatically logged out. You can change the session timeout value, which is set by default to 30 minutes, by modifying the following parameter in the **values.yaml** file of the Helm chart:

    uno.config.console.sessionTimeoutMinutes: 30

**Log out option**

To enable the log out option, set the following parameter in the **values.yaml** file of the Helm chart to true:

     uno.config.console.enableLogout: true

**Generative workflows and knowledege base**

You can enable the generative features of the UnO AI Pilot for both workflow generation and generative knowledge base by setting the following parameter in the **values.yaml** file of the Helm chart to true:

    uno.config.genai.enabled: true

**Justifications**

The administrator can enable justifications so that users are prompted to provide information when saving or performing changes to items in the environment. To enable justifications, set the following parameter in the **values.yaml** file of the Helm chart to true:

    uno.config.engine.justificationEnabled: true

You can configure different justification levels by setting the related parameters in the values.yaml file of the Helm chart as follows:

     uno.config.engine.justificationCategoryRequired: true
     uno.config.engine.justificationTicketNumberRequire: true
     uno.config.engine.justificationDescriptionRequired: true

For more information about justifications, see [Keeping track of changes in your environment](https://help.hcl-software.com/UnO/v2.1.2/Deployment/justifications.html).

**Encryption**

You can configure the password or key to encrypt data, such as passwords, agent database, and kafka messages by configuring the **values.yaml** file as follows: 
		
    uno.config.encryption.key: yourpassword

**Administrative user customization**

You can change the name of the default administrative user modifying the parameter in the **values.yaml** file of the Helm chart:

     uno.authentication.adminName: wauser


Check the **values.yaml** file for more customization options.

### Security and verification for OCLI and UnO agent binaries 

To ensure the integrity and authenticity of the downloaded files, we use GPG (GNU Privacy Guard) encryption. You must have the GPG tool installed on your system to decrypt and verify the files. 

The Orchestration CLI and HCL UnO agent packages are signed with our private key. A corresponding .asc signature file accompanies the downloadable file. You can extract the file and use the public key to decrypt and verify the files.

Importing the GPG Public Key

1.  Import the HCL public GPG key using the following command:

    ```bash
    gpg --import path-to-gpg-public-key
    ```

    A successful import generates an output similar to the following:

    ```
    gpg: /root/.gnupg/trustdb.gpg: trustdb created
    gpg: key 1E4A814A2159AC84: public key "HCL America Inc." imported
    gpg: Total number processed: 1
    gpg:                 imported: 1
    ```

Verifying the OCLI File

2.  Verify the OCLI file's signature using the following command:

    ```bash
    gpg --verify path-to-OCLI-file
    ```

    A successful verification produces an output similar to the following:

    ```
    gpg: Signature made Tue Jan 14 16:24:39 2025 CET
    gpg:                using RSA key 1E4A814A2159AC84
    gpg: Good signature from "HCL America Inc." [unknown]
    gpg: WARNING: This key is not certified with a trusted signature!
    gpg:         There is no indication that the signature belongs to the owner.
    Primary key fingerprint: A2E5 F8D8 6EB5 1D05 BD14 EFA2 1E4A 814A 2159 AC84
    ```

    The warning about the uncertified signature can be safely ignored if the fingerprint matches the expected value.

For more information on verifying a file with gpg keys, see [GnuPG documentation](https://www.gnupg.org/gph/en/manual.html). 

When you decrypt the files with the public key and if the signature is valid, you can see a message indicating the file is correctly signed and the key ID matches with the public key. If the signature is invalid, you can see an error message, means the file is corrupted. 

By verifying the file, you can ensure that it is not tampered during the download and can confirm the file is genuinely valid. You can download the public key from [here](https://github.com/HCL-TECH-SOFTWARE/hcl-universal-orchestrator-chart/blob/main/HCL_Universal_Orchestrator_public_key.gpg).

### Verifying the deployment 

After the deployment procedure is complete, you can validate the deployment to ensure that everything is working. 

To manually verify that the deployment has successfully completed, perform the following check:
 
Run the following command to verify the pods installed in the <uno_namespace>:
   
           kubectl get pods -n <uno_namespace>


 **Verifying the microservices network ingresses**

To obtain the URLs related to the ingresses of the different microservices, use the following command:

    kubectl get ingress <uno_release_name>-uno-ingress -n <uno_namespace> -o json | jq -r '.spec.rules[] | .host + .http.paths[].path'

To obtain the OpenShift routes of the different microservices, use the following command:

    kubectl get route -n <uno_namespace>


**Logging into the UnO console:**

Logging in the UnO console is only possible if an OIDC provider has been previously configured.

1. Log in to the UnO console by using the URLs obtained in the previous step, and inserting the previously defined administrative user credentials and the password associated to that user in the OIDC provider.
	
2. Verify that the UnO console is successfully connected to the engine by accessing either the Graphical Designer or the Orchestration Monitor.

## Upgrading the product components

To upgrade HCL Universal Orchestrator, perform the following steps:

1. Configure each product component by adjusting the values in the **values.yaml** file. The **values.yaml** file contains a detailed explanation for each parameter.

2. Upgrade the instance by running the following command:

         helm upgrade <uno_release_name> <repo_name>/hcl-uno-chart -f values.yaml -n <uno_namespace>
		 
 where 
   <uno_release_name> is the deployment name of the instance. 
   
**TIP:** Use a short name or acronym when specifying this value to ensure it is readable.
	   
## Uninstalling the Chart

 To uninstall the deployed components associated with the chart and clean up the orphaned Persistent Volumes, run:
 
         helm uninstall release_name -n <uno_namespace> 
  
	
 The command removes all of the Kubernetes components associated with the chart and uninstalls the <uno_release_name> release.
 	
## Configuring

Configuration parameters are available in the **values.yaml** files, together with explanatory comments.

The following procedures are ways in which you can configure the default deployment of the product components. They include the following configuration topics:

* [Scaling the product](#scaling-the-product)
* [Managing your custom certificates](#managing-your-custom-certificates)

	
### Scaling the product 

HCL Universal Orchestrator is installed by default with autoscaling enabled. To enable high availability, set the following parameter in the `values.yaml` file to 2:

    uno.deployment.global.minTargetReplicas: 2

**Note**: HCL Universal Orchestrator Helm chart does not support scaling to zero nor proportional scaling.
		  
### Managing your custom certificates
    
To use custom certificates: 

1. Genereta your custom certificates
2. Set `uno.congfig.certificates.useCustomizedCert: true`
3. Assign the certificate values as secrets in the certificates section of the **values.yaml** file:

    uno.config.certificates.caPairSecretName: ca-key-pair
    uno.config.certificates.certSecretName: uno-certificate
    uno.config.certificates.certExtAgtSecretName: uno-certificate-ext-agt

        
If you define custom certificates, you are in charge of keeping them up to date, therefore, ensure you check their duration and plan to rotate them as necessary. To rotate custom certificates, delete the previous secret and upload a new secret, containing new certificates. The pod restarts automatically and the new certificates are applied.

When using custom certificates make sure to update the following fields:
		
			uno.hclaipilot.certificates.useCustomizedCert: true
			uno.hclaipilot.certificates.caPairSecretName: <the secret name of the CA you want to use to sign the certificate created by default>
			uno.hclaipilot.certificates.certSecretName: <the name of the custom certificate you want to use>
		
			uno.hclaipilot.rag.certificates.useCustomizedCert: true
			uno.hclaipilot.rag.certificates.caPairSecretName: <the secret name of the CA you want to use to sign the certificate created by default>
			uno.hclaipilot.rag.certificates.certSecretName: <the name of the custom certificate you want to use>
	
			uno.hclaipilot.pgvector.tls.caPairSecretName: <the secret name of the CA you want to use to sign the certificate created by default>
			uno.hclaipilot.pgvector.tls.certificatesSecret: <the name of the custom certificate you want to use>

## Metrics monitoring 

HCL Universal Orchestrator uses Grafana to display performance data related to the product. This data includes metrics related to the server and console application server (Open Liberty), your workload, your workstations, message queues, the database connection status, and more. Grafana is an open source tool for visualizing application metrics. Metrics provide insight into the state, health, and performance of your deployments and infrastructure. HCL Universal Orchestrator cloud metric monitoring uses an opensource Cloud Native Computing Foundation (CNCF) project called Prometheus. It is particularly useful for collecting time series data that can be easily queried. Prometheus integrates with Grafana to visualize the metrics collected.



The following metrics are collected and available to be visualized in the preconfigured Grafana dashboard. The dashboard is named **<uno_namespace> <uno_release_name>**:

For a list of metrics exposed by HCL Universal Orchestrator, see [Exposing metrics to monitor your workload](https://help.hcltechsw.com/UnO/v2.1.2/Monitoring/awsrgmonprom.html).
  
  ### Setting the Grafana service
Before you set the Grafana service, ensure that you have already installed Grafana and Prometheus on your cluster. For information about deploying Grafana see [Install Grafana](https://github.com/helm/charts/blob/master/stable/grafana/README.md). For information about deploying the open-source Prometheus project see [Download Promotheus](https://github.com/helm/charts/tree/master/stable/prometheus).
  
1. Log in to your cluster. To identify where Grafana is deployed, retrieve the value for the \<grafana-namespace> by running:
  
          helm list -A
		  
2. Download the grafana_values.yaml file by running:

        helm get values grafana -o yaml -n <grafana-namespace> grafana_values.yaml

3. Modify the grafana_values.yaml file by setting the following parameter values:	

	    dashboards:
		     SCProvider: true
		     enabled: true
		     folder: /tmp/dashboards
		     label: grafana_dashboard
		     provider:
			 allowUiUpdates: false
			 disableDelete: false
			 folder: ""
			 name: sidecarProvider
			 orgid: 1
			 type: file
		     searchNamespace: ALL

4. Update the grafana_values.yaml file in the Grafana pod by running the following command:

    ` helm upgrade grafana stable/grafana -f grafana_values.yaml -n <grafana-namespace>`
					 
5. To access the Grafana console:

     a. Obtain the EXTERNAL-IP address value of the Grafana service by running:
	 
        kubectl get services -n <grafana-namespace>
		
     b. Browse to the EXTERNAL-IP address and log in to the Grafana console.		
 
### Viewing the preconfigured dashboard in Grafana

To get an overview of the cluster health, you can view a selection of metrics on the predefined dashboard:

1. In the left navigation toolbar, click **Dashboards**.

2. On the **Manage** page, select the predefined dashboard named **<uno_namespace> <uno_release_name>**.

For more information about using Grafana dashboards see [Dashboards overview](https://grafana.com/docs/grafana/latest/features/dashboard/dashboards/).


## Limitations

*  Limited to amd64 platforms.
*  Anonymous connections are not permitted.

## AI Pilot Knowledge base
To ensure a user can import, export, or delete the custom knowledge base, they must have the AI_PILOT_ADMINISTRATOR role. By default, this role is assigned to all administrator accounts.

## Documentation

To access the complete product documentation library for HCL Universal Orchestrator, see [HCL Universal Orchestrator documentation](https://help.hcltechsw.com/UnO/v2.1.2/index.html).



