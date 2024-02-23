# ocp-tools

This repository hosts a collection of tools aimed at enhancing the management and operation of OpenShift clusters. Among these tools, the `ocp-resources-bkp.py` script is a key utility designed to facilitate the backup of OpenShift resources.

## Overview

The `ocp-resources-bkp.py` script automates the process of backing up various OpenShift resources. It is designed to be run within an OpenShift cluster environment, leveraging the cluster's access permissions to retrieve and store resource definitions.

## Features

- **Backup Flexibility:** Allows for the backup of specific resources across all namespaces or within specified ones.
- **Automation Friendly:** Designed to be easily integrated into CI/CD pipelines or scheduled backup routines using cron jobs.
- **Comprehensive Coverage:** Capable of backing up a wide range of OpenShift resource types, ensuring a broad protection scope.

## Prerequisites

- OpenShift CLI (`oc`) installed and configured to communicate with your cluster.
- Python 3.x environment for executing the script.
- Appropriate permissions to access and backup resources within the cluster.

## Usage

To use the script, ensure you have the necessary permissions to access the resources you intend to backup. Run the script from a terminal or integrate it into your automation tools with the following command:

```sh
python ocp-resources-bkp.py
```

You can also indicate the resources to backup inside a custom config file.

```sh
python ocp-resources-bkp.py -c config-infra.yml
```

The script will create files with the resources manifests inside the `/tmp/backups_OCP` directory.

## Customization

The script can be customized to target specific resources or namespaces by modifying the relevant sections of the code. Parameters such as resource types and namespace names can be adjusted to fit your backup requirements.

## Integration

For integrating this script into a CI/CD pipeline or a scheduled task:

- CI/CD Pipeline: Add the script execution as a step in your pipeline, ensuring that the environment where the pipeline runs has oc CLI access to the OpenShift cluster.
- Cron Job: Schedule the script to run at regular intervals by adding a cron job on a system with the necessary access and environment to execute the script.

## Contributing

Contributions to enhance the functionality or extend the coverage of backup resources are welcome. Please submit pull requests or create issues to discuss potential improvements.
