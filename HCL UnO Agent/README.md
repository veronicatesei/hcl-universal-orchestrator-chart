# Installing the HCL Universal Orchestrator agent on Kubernetes

The HCL UnO agent provides a secure running environment for HCL Universal Orchestrator within your Kubernetes cluster. Designed for operational continuity, the agent supports automated maintenance and zero-downtime updates without disrupting critical workflows. By leveraging a containerized architecture, the agent minimizes downtime and simplifies lifecycle management for your scheduling environment.

This is the procedure to deploy a HCL Universal Orchestrator (UnO) agent into a Kubernetes environment using the provided Helm chart.

## Prerequisites

Ensure that the following requirements are met before proceeding with the installation:

* A running Kubernetes instance.
* A deployed instance of HCL Universal Orchestrator.
* Access to the `hcl-uno-agent-chart` directory.
* A valid API key with the `REGISTERAGENT` permission and `ADD` permission for the workstation folder.

If you are deploying the HCL UnO Agent into a **different namespace** than HCL Universal Orchestrator, you must create a Kubernetes Secret in the target namespace. Run the following command to create the pull secret in the Agent's namespace:

```
kubectl create secret docker-registry sa-<agent_namespace> \
-n <agent_namespace> \
--docker-server=hclcr.io \
--docker-username=<user_name> \
--docker-password=<api_key>
```

**Parameters:**
* `<agent_namespace>` : The namespace where you intend to install the Agent.
* `<user_name>` : Your HCL Entitled Registry username.
* `<api_key>` : Your HCL Entitled Registry API key.

## Procedure

### Create the Kubernetes secret (Optional)

To avoid storing sensitive authentication data in plain text within the configuration files, create a Kubernetes secret to store the API key. Run the following command, replacing `<your_api_key>` with the valid key generated from the environment:

```
kubectl create secret generic uno-agent-secret --from-literal=apikey=<your_api_key> -n <agent_namespace>
```

### 1. Configure the values.yaml file

The `values.yaml` file defines the configuration parameters for the deployment. Open the file and modify the following parameters:

* **Global settings:**
    * Set `global.license` to `"accept"` to agree to the license terms.
* **Image registry:**
    * If your environment requires a private or custom container registry, update `config.registry.name` with the corresponding URL.
    * Otherwise, retain the default value.
* **Agent configuration:**
    * Set `agent.configuration.agentManagerUrl` to the URL of the HCL UnO agent manager microservice (e.g., `<agentmanager_hostname_url>`).
    * Configure the API Key Secret (Choose ONE of the following):
        * **Option A:** Set `agent.configuration.apiKeySecretName` to `uno-agent-secret` (the name of the secret created in the optional *Create the Kubernetes secret* step).
        * **Option B:** Set `agent.configuration.apiKeySecret` to `apikey` (an API key created in the HCL Universal Orchestrator UI).
    * Define the `agent.configuration.name`. Ensure the name contains only alphanumeric characters, dashes, or underscores.
* **Persistence:**
    * Ensure `persistence.useDynamicProvisioning` is set to `true` to enable Kubernetes to allocate storage for the agent data automatically.

### 2. Install the chart

Deploy the agent service by running the following Helm command from the parent directory of the chart:

```
helm3 install uno-agent ./hcl-uno-agent-chart -f values.yaml -n <agent_namespace>
``` 

### 3. Verify the installation

* **Option 1: Kubernetes Logs (Local)** Check the pod status and logs directly to ensure the agent is running without errors.
    ```bash
    kubectl get pods -n <agent_namespace>
    kubectl logs -f deployment/uno-agent -n <agent_namespace>
    ``` 

* **Option 2: Orchestrator Monitor (UI)** Log in to the HCL UnO UI. In the Orchestrator Monitor, navigate to the **Workstations** view and verify that the new agent is listed with `ONLINE` status.

* **Option 3: OCLI (Command Line)** Use the Orchestrator Command Line Interface (OCLI) to query the workstation status.
    ```
    ocli show workstation @/@
    ```