
# HCL Universal Orchestrator

## Introduction
To ensure a fast and responsive experience when using HCL Universal Orchestrator, you can deploy HCL Universal Orchestrator on a cloud infrastructure. A cloud deployment ensures access anytime anywhere and is a fast and efficient way to get up and running quickly. It also simplifies maintenance, lowers costs, provides rapid upscale and downscale, minimizes IT requirements and physical on-premises data storage.

As more and more organizations move their critical workloads to the cloud, there is an increasing demand for solutions and services that help them easily migrate and manage their cloud environment.

To respond to the growing request to make automation opportunities more accessible, HCL Universal Orchestrator containers can be deployed into the following supported third-party cloud provider infrastructures:

- ![Amazon EKS](images/tagawseks.png "Amazon EKS") Amazon Web Services (AWS) Elastic Kubernetes Service (EKS)
- ![Microsoft Azure](images/tagmsa.png "Microsoft Azure") Microsoft&reg; Azure Kubernetes Service (AKS)
- ![Google GKE](images/taggke.png "Google GKE") Google Kubernetes Engine (GKE)
- ![OpenShift](images/tagOpenShift.png "OpenShift") OpenShift (OCP)

HCL Universal Orchestrator is a complete, modern solution for batch and real-time workload management. It enables organizations to gain complete visibility and control over attended or unattended workloads. From a single point of control, it supports multiple platforms and provides advanced integration with enterprise applications including ERP, Business Analytics, File Transfer, Big Data, and Cloud applications.

For more information about HCL Universal Orchestrator, see the product documentation library in [HCL Universal Orchestrator documentation](https://help.hcltechsw.com/UnO/v1.1/index.html).

## Details

By default, all microservices and the Dynamic Workload Console (console) are installed. 

To achieve high availability in an HCL Universal Orchestrator environment, the minimum base configuration is composed of 2 Dynamic Workload Consoles and 2 replicas of all microservices. For more details about HCL Universal Orchestrator and high availability, see: 


[An active-active high availability scenario](https://help.hcltechsw.com/UnO/v1.1/Mobile_guides/highavailability.html).

HCL Universal Orchestrator can be deployed across a single cluster, but you can add multiple instances of the product microservices by using a different namespace in the cluster. The product microservices can run in multiple failure zones in a single cluster.

 
## Supported Platforms

- ![Amazon EKS](images/tagawseks.png "Amazon EKS") Amazon Elastic Kubernetes Service (EKS) on amd64: 64-bit Intel/AMD x86
- ![Microsoft Azure](images/tagmsa.png "Microsoft Azure") Azure Kubernetes Service (AKS) on amd64: 64-bit Intel/AMD x86
- ![Google GKE](images/taggke.png "Google GKE") Google Kubernetes Engine (GKE) on amd64: 64-bit Intel/AMD x86
- ![OpenShift](images/tagOpenShift.png "OpenShift") OpenShift (OCP)
- Any Kubernetes platform from V1.20 and above

### Openshift support
You can deploy HCL Universal Orchestrator on Openshift 4.2 or later version by following the instruction in this documentation and using helm charts. 
Ensure you modify the value of the `waconsole.console.exposeServiceType` parameter from `LoadBalancer` to `Routes`.
	
## Accessing the container images

You can access the HCL Universal Orchestrator chart and container images from the Entitled Registry. See [Create the secret](#creating-the-secret) for more information about accessing the registry. The images are as follows:

 - hcl-uno-external-pod
 - hcl-uno-agentmanager
 - hcl-uno-gateway
 - hcl-uno-iaa
 - hcl-uno-scheduler
 - hcl-uno-storage
 - hcl-uno-toolbox
 - hcl-uno-audit
 - hcl-uno-timer
 - hcl-uno-executor 
 - hcl-uno-orchestrator

## Prerequisites
Before you begin the deployment process, ensure your environment meets the following prerequisites:

**Mandatory**
- Kubetctl v 1.25.8 or later
- Kubernetes cluster v 1.25 or later
- Helm v 3.10 or later
- Messaging system: Apache Kafka v 3.4.0 or later OR Redpanda v 23.11 or later 
- Database: MongoDB v 5 or later OR Azure Cosmos DB for MongoDB (vCore) 

**Optional**
-   Grafana and Prometheus for monitoring dashboard
-   Jetstack cert-manager

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
|**uno-orchestrator microservice**  | CPU: 2, Memory: 1 GB  |CPU: 0.3, Memory: 1 GB|
|**Each remaining microservice**  | CPU: 2, Memory: 1 GB  |CPU: 0.3, Memory: 0.5 GB  |
|**Console**  | CPU: 4, Memory: 16 GB  |CPU: 1, Memory: 4 GB, Storage: 5 GB  |
No disk space is required for the microservices, however, at least 100 GB are recommended for Kafka and 100 GB for MongoDB. Requirements vary depending on your workload.

## Deploying

Deploying and configuring HCL Universal Orchestrator involves the following high-level steps:

1. [Creating the Namespace](#creating-the-namespace)
2. [Creating a Kubernetes Secret](#creating-the-secret) by accessing the entitled registry to store an entitlement key for the HCL Universal Orchestrator offering on your cluster. 
3. [Deploying the product components](#deploying-the-product-components)
4. [Verifying the deployment](#verifying-the-deployment)


### Creating the Namespace

To create the namespace, run the following command:

        kubectl create namespace <uno_namespace>
	

### Creating the Secret 

If you already have a license, then you can proceed to obtain your entitlement key. To learn more about acquiring an HCL Universal Orchestrator license, contact HWAinfo@hcl.com. 

Obtain your entitlement key and store it on your cluster by creating a [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/). Using a Kubernetes secret allows you to securely store the key on your cluster and access the registry to download the chart and product images. 

1. Access the entitled registry.  Contact your HCL sales representative for the login details required to access the HCL Entitled Registry.
2. To create a pull secret for your entitlement key that enables access to the entitled registry, run the following command:

         kubectl create secret docker-registry -n <uno_namespace> sa-<uno_namespace> --docker-server=<registry_server> --docker-username=<user_name> --docker-password=<password>
	   
	where,
	* <uno_namespace> represents the namespace where the product components are installed
	* <registry_server> is `hclcr.io`
	* <user_name> is the user name provided by your HCL representative
	* \<password> is the entitled key copied from the entitled registry `<api_key>`


### Deploying the product components		

To deploy the HCL Universal Orchestrator, perform the following steps:

1. Download the chart from the HCL Entitled Registry: `hclcr.io` and unpack it to a local directory.
2. Add the repository:
   
        helm repo add <repo_name> https://hclcr.io/chartrepo/wa --username <username> --password <api_key>
   where 
   <repo_name> represents the name of the chosen local repository.
   <api_key> represents the key to access the registry.
3. Update the Helm chart:
 
        helm repo update 
   
4. Pull the Helm chart:

        helm pull <repo_name>/hcl-uno-prod
	
**Note:** If you want to download a specific version of the chart use the `--version` option in the `helm pull` command.
	
5. Customize the deployment. Configure each product component by adjusting the values in the `values.yaml` file. The `values.yaml`file contains a detailed explanation for each parameter. 

6. Deploy the instance by running the following command: 

        helm install -f values.yaml <uno_release_name> <repo_name>/hcl-uno-prod -n <uno_namespace>


 where 
   <uno_release_name> is the deployment name of the instance. 
**TIP:** Use a short name or acronym when specifying this value to ensure it is readable.

The following are some useful Helm commands:

* To list all of the Repo releases: 

        helm list -A
	
* To update the Helm release:

        helm upgrade <uno_release_name> <repo_name>/hcl-uno-prod -f values.yaml -n <uno_namespace>
	
* To delete the Helm release: 

        helm uninstall <uno_release_name> -n <uno_namespace>
		

### Verifying the deployment 

After the deployment procedure is complete, you can validate the deployment to ensure that everything is working. 

To manually verify that the deployment has successfully completed, perform the following check:
 
Run the following command to verify the pods installed in the <uno_namespace>:
   
           kubectl get pods -n <uno_namespace>

 **Verify that the default engine connection is created from the Dynamic Workload Console**

Verifying the default engine connection depends on the network enablement configuration you implement. To determine the URL to be used to connect to the console, follow the procedure for the appropriate network enablement configuration.

**For load balancer:**

1. Run the following command to obtain the token to be inserted in https://\<loadbalancer>:9443/console to connect to the console:

![Amazon EKS](images/tagawseks.png "Amazon EKS") 
	
        kubectl get svc <workload_automation_release_name>-waconsole-lb  -o 'jsonpath={..status.loadBalancer.ingress..hostname}' -n <workload_automation_namespace>

![Microsoft Azure](images/tagmsa.png "Microsoft Azure")

       kubectl get svc <workload_automation_release_name>-waconsole-lb  -o 'jsonpath={..status.loadBalancer.ingress..ipaddress}' -n <workload_automation_namespace>
       

![Google GKE](images/taggke.png "Google GKE")

       kubectl get svc <workload_automation_release_name>-waconsole-lb  -o 'jsonpath={..status.loadBalancer.ingress..ipaddress}' -n <workload_automation_namespace>


2. With the output obtained, replace \<loadbalancer> in the URL https://\<loadbalancer>:9443/console.

**For ingress:**

1. Run the following command to obtain the token to be inserted in https://\<ingress>/console to connect to the console:


        kubectl get ingress/<workload_automation_release_name>-waconsole -o 'jsonpath={..host}'-n <workload_automation_namespace>
  
2.   With the output obtained, replace \<ingress> in the URL https://\<ingress>/console.

**Logging into the console:**

1. Log in to the console by using the URLs obtained in the previous step.

2. For the credentials, specify the user name (wauser) and password (wa-pwd-secret, the password specified when you created the secrets file to store passwords for the server, console and database).
	
3. From the navigation toolbar, select **Administration -> Manage Engines**.
	
4.  Verify that the default engine, **engine_<release_name>-gateway** is displayed in the Manage Engines list:

To ensure the Dynamic Workload Console logout page redirects to the login page, modify the value of the logout url entry available in file authentication_config.xml:


       <jndiEntry value="${logout.url}" jndiName="logout.url" />

where the logout.url string in jndiName should be replaced with the logout URL of the provider.
	   
## Uninstalling the Chart

 To uninstall the deployed components associated with the chart and clean up the orphaned Persistent Volumes, run:
 
         helm uninstall release_name -n <uno_namespace> 
  
	
 The command removes all of the Kubernetes components associated with the chart and uninstalls the <uno_release_name> release.
 	
## Configuring

Configuration parameters are available in the **values.yaml** files, together with explanatory comments.

The following procedures are ways in which you can configure the default deployment of the product components. They include the following configuration topics:

* [Network enablement](#network-enablement)
* [Scaling the product](#scaling-the-product)
* [Managing your custom certificates](#managing-your-custom-certificates)

### Network enablement

The HCL Universal Orchestrator server and console can use two different ways to route external traffic into the Kubernetes Service cluster:

* A **load balancer** service that redirects traffic
* An **ingress** service that manages external access to the services in the cluster

You can freely switch between these two types of configuration.

#### Network policy

You can specify an egress network policy to include a list of allowed egress rules for each components. Each rule allows traffic leaving the cluster which matches both the "to" and "ports" sections. For example, the following sample demonstrates how to allow egress to another destination:

networkpolicyEgress:

	- name: to-mdm
	  egress:
	  - to:
	    - podSelector:
	        matchLabels:
		  app.kubernetes.io/name: waserver
	    - port: 31116
	      protocol: TCP
	- name: dns
	  egress:
	    - to:
	      - namespaceSelector:
	          matchLabels:
		    name: kube-system
	    - ports:
	        - port: 53
		  protocol: UDP
		- port: 53
		  protocol: TCP

For more information, see [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

#### Node affinity Required
You can also specify node affinity required to determine on which nodes a component can be deployed using custom labels on nodes and label selectors specified in pods. The following is an example:

nodeAffinityRequired:

	-key: iwa-node
	  operator: In
	  values:
	  - 'true'

where **iwa-node** represents the value of the node affinity required.

#### Load balancer service


  To configure a load balancer, follow these steps:

1. Locate the following parameters in the `values.yaml` file:

		exposeServiceType
		exposeServiceAnnotation

For more information about these configurable parameters, see the explanatory comments available in the **values.yaml** file.

2. Set the value of the `exposeServiceType` parameter to `LoadBalancer`.

3. In the `exposeServiceAnnotation` section, uncomment the lines in this section as follows:

![Amazon EKS](images/tagawseks.png "Amazon EKS") 

		service.beta.kubernetes.io/aws-load-balancer-type: nlb
		service.beta.kubernetes.io/aws-load-balancer-internal: "true"
		
![Microsoft Azure](images/tagmsa.png "Microsoft Azure") 

		service.beta.kubernetes.io/azure-load-balancer-internal: "true"

![Google GKE](images/taggke.png "Google GKE") 

		networking.gke.io/load-balancer-type: "Internal"


4. Specify the load balancer type and set the load balancer to internal by specifying "true".


#### Ingress service

  To configure an ingress for the server, follow these steps:

1. Locate the following parameters in the `values.yaml` file:

		exposeServiceType
		exposeServiceAnnotation

   For more information about these configurable parameters, see the explanatory comments available in the **values.yaml** file.

2. Set the value of the `exposeServiceType`parameter to `Ingress`.

3. In the `exposeServiceAnnotation` section, leave the following lines as comments:

![Amazon EKS](images/tagawseks.png "Amazon EKS") 

		#service.beta.kubernetes.io/aws-load-balancer-type:nlb
		#service.beta.kubernetes.io/aws-load-balancer-internal: "true"

![Microsoft Azure](images/tagmsa.png "Microsoft Azure")

		#service.beta.kubernetes.io/azure-load-balancer-internal: "true"	
		
![Google GKE](images/taggke.png "Google GKE") 

                #networking.gke.io/load-balancer-type: "Internal"

	
### Scaling the product 

HCL Universal Orchestrator is installed by default with autoscaling enabled. A single Dynamic Workload Console is installed. To scale the Dynamic Workload Console, increase or decrease the values of the `replicaCount` parameter in the `values.yaml` file and save the changes.

**Note**: HCL Universal Orchestrator Helm chart does not support scaling to zero nor proportional scaling.
		  
### Managing your custom certificates
    
  If you want to use custom certificates, set `useCustomizedCert:true` and use kubectl to apply the secret in the \<uno_namespace>.
 Type the following command:
 
 ```
kubectl create secret generic waserver-cert-secret --from-file=TWSClientKeyStore.kdb --from-file=TWSClientKeyStore.sth --from-file=TWSClientKeyStoreJKS.jks --from-file=TWSClientKeyStoreJKS.sth --from-file=TWSServerKeyFile.jks --from-file=TWSServerKeyFile.jks.pwd --from-file=TWSServerTrustFile.jks --from-file=TWSServerTrustFile.jks.pwd -n <workload-automation-namespace>   
 ``` 
  
    
> **Note:** if you set `db.sslConnection:true`, you must also set the `useCustomizedCert` setting to true on both UnO and Dynamic Workload Console charts and, in addition, you must add the following certificates in the customized SSL certificates secret on both UnO and Dynamic Workload Console charts:

  * ca.crt
  * tls.key
  * tls.crt

 Customized files must have the same name as the ones listed above.
         
If you want to use SSL connection to DB, set `db.sslConnection:true` and `useCustomizedCert:true`, then use kubectl to create the secret in the same namespace where you want to deploy the chart:

      bash
      $ kubectl create secret generic release_name-secret --from-file=TWSServerTrustFile.jks --from-file=TWSServerKeyFile.jks --from-file=TWSServerTrustFile.jks.pwd --from-file=TWSServerKeyFile.jks.pwd --namespace=<uno_namespace>
        
If you define custom certificates, you are in charge of keeping them up to date, therefore, ensure you check their duration and plan to rotate them as necessary. To rotate custom certificates, delete the previous secret and upload a new secret, containing new certificates. The pod restarts automatically and the new certificates are applied.

## Metrics monitoring 

HCL Universal Orchestrator uses Grafana to display performance data related to the product. This data includes metrics related to the server and console application server (Open Liberty), your workload, your workstations, message queues, the database connection status, and more. Grafana is an open source tool for visualizing application metrics. Metrics provide insight into the state, health, and performance of your deployments and infrastructure. HCL Universal Orchestrator cloud metric monitoring uses an opensource Cloud Native Computing Foundation (CNCF) project called Prometheus. It is particularly useful for collecting time series data that can be easily queried. Prometheus integrates with Grafana to visualize the metrics collected.



The following metrics are collected and available to be visualized in the preconfigured Grafana dashboard. The dashboard is named **<uno_namespace> <uno_release_name>**:

For a list of metrics exposed by HCL Universal Orchestrator, see [Exposing metrics to monitor your workload](https://help.hcltechsw.com/UnO/v1.1/Monitoring/awsrgmonprom.html).
  
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


## Documentation

To access the complete product documentation library for HCL Universal Orchestrator, see [HCL Universal Orchestrator documentation](https://help.hcltechsw.com/UnO/v1.1/index.html).



## Change history

### Added August 2023
First release


