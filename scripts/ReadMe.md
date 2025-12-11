# How to gather data using data gather script
These scripts allow you to collect logs and definitions from a Kubernetes environment where the UNO application is deployed.
The definitions are retrieved from OCLI, according to the current context. You can check the existing contexts from the `config.yaml` file within the `.OCLI` folder.
You can change the current context by running the following command:

    ``ocli context list``
    ``ocli context switch <context_name>``
    
The logs, instead, are retrieved from Kubernetes, according to the current context. You can check the existing contexts from the `config` file within the `.kube` folder.
You can change the current context by running the following command:

   `` kubectl config get-contexts``
    ``kubectl config use-context <context_name>``

## Prerequisites

- `kubectl` configured for the target cluster.
- Permissions to execute commands and copy files from pods.
- (Optional) Path to the OCLI executable to extract definitions with a preconfigured context. If not provided, the script will try to use the OCLI available in the system PATH.

## Examples:

### LINUX:

To show help:
``./data-gather.sh -h`` 
``./data-gather.ps1 --help``

To extract logs:
``./data-gather.sh -n namespace_name``

To extract logs and definitions providing the OCLI path:
``./data-gather.sh -n namespace_name -o /my/ocli/path/ocli``

To extract only logs, skipping definitions extraction:
``./data-gather.sh -n namespace_name -sd``



### WINDOWS:

To show help:
``data-gather.ps1 -Help``

To extract logs:
``data-gather.ps1 -Namespace namespace_name``

To extract logs and definitions providing a specific OCLI path:
``data-gather.ps1 -Namespace namespace_name -OcliPath C:\my\ocli\path\ocli.exe``

To extract only logs, skipping definitions extraction:
``data-gather.ps1 -Namespace namespace_name -SkipDefs``
