#!/usr/bin/env python3

import argparse
import yaml
import subprocess
import os
from datetime import datetime

default_config = {
    "global": {
        "resources": ["Namespace", "RBACDefinition" ]
    },
    "ns_all": {
        "resources": ["rolebindings", "serviceaccount"]
    },
    "ns_infra": {
        "namespace": ["openshift-config", "openshift-ingress", "openshift-marketplace"],
        "resources": ["cm", "secret"]
    }
}

def load_config_from_yaml(file_path):
    with open(file_path, 'r') as file:
        return yaml.safe_load(file)

def parse_arguments():
    parser = argparse.ArgumentParser(description="Backup OpenShift or K8S resources.")
    parser.add_argument('-c', '--config', help="Path to the YAML configuration file.", type=str)
    args = parser.parse_args()
    if args.config:
        return load_config_from_yaml(args.config)
    else:
        return default_config

# Function to log messages
def echolog(message, to_stdout=True, to_log=True):
    log_date = datetime.now().strftime('[%F %T %Z]')
    formatted_message = f"{log_date} - {message}\n"
    if to_stdout:
        print(formatted_message, end='')
    if to_log:
        with open(log_file, 'a') as f:
            f.write(formatted_message)

def echostatuslog(message, status):
    log_date = datetime.now().strftime('[%F %T %Z]')
    msg = f"{log_date} - {message}"
    status_text = "[Done]" if status == 0 else "[Failed]"
    formatted_message = f"{msg} {status_text}\n"
    with open(log_file, 'a') as f:
        f.write(formatted_message)
    print(formatted_message, end='')

# Function to run oc commands and save outputs
def backup_resource(command, output_path):
    result = subprocess.run(command, shell=True, capture_output=True)
    if result.returncode == 0:
        with open(output_path, 'w') as file:
            file.write(result.stdout.decode())
    return result.returncode

# Function to backup global or namespaced resources
def backup_resources(res_type, backup_path, resources, namespaces=None):
    if res_type == 'global':
        for resource in resources:
            output_path = f"{backup_path}/{resource}.yml"
            command = f"{oc_bin} get {resource} -o yaml"
            status = backup_resource(command, output_path)
            echostatuslog(f"...{resource} manifest yaml backup", status)
    else:
        for ns in namespaces:
            ns_backup_path = os.path.join(backup_path, ns)
            os.makedirs(ns_backup_path, exist_ok=True)
            for resource in resources:
                output_path = f"{ns_backup_path}/{resource}.yml"
                command = f"{oc_bin} -n {ns} get {resource} -o yaml"
                status = backup_resource(command, output_path)
                echostatuslog(f"...{resource} resource yaml backup in {ns} namespace", status)


# Initial configurations
config = parse_arguments()
oc_bin = "/usr/local/bin/oc"
cluster_name = subprocess.getoutput(f"{oc_bin} whoami --show-server").split('/')[2].split(':')[0]
date_str = datetime.now().strftime('%Y%m%d-%H%M')
backup_base_path = f"/tmp/backups_OCP/{cluster_name}/{date_str}"
backup_path_globals = os.path.join(backup_base_path, 'globals')
backup_path_ns_all = os.path.join(backup_base_path, 'namespaces')
backup_path_ns_infra = os.path.join(backup_base_path, 'namespaces-infra')
log_file = os.path.join(backup_base_path, 'backup_ocp_resources.log')

# Create backup directories
os.makedirs(backup_path_globals, exist_ok=True)
os.makedirs(backup_path_ns_all, exist_ok=True)
os.makedirs(backup_path_ns_infra, exist_ok=True)

resources_global = config['global']['resources']
resources_ns_all = config['ns_all']['resources']
resources_ns_infra = config['ns_infra']['resources']
namespaces_all = subprocess.getoutput(f"{oc_bin} get ns -o custom-columns=name:.metadata.name --sort-by=.metadata.name --no-headers").split('\n')
namespaces_infra = config['ns_infra']['namespace']

print("\n\n")
echolog("Starting Global resources backup...\n")
backup_resources('global', backup_path_globals, resources_global)

print("\n\n")
echolog("Starting Namespaced resources backup in all namespaces...\n")
backup_resources('namespaced', backup_path_ns_all, resources_ns_all, namespaces_all)

print("\n\n")
echolog("Starting Namespaced resources backup in infra namespaces...\n")
backup_resources('namespaced', backup_path_ns_infra, resources_ns_infra, namespaces_infra)

print("\n\n")
echolog("The backup is located at: " + backup_base_path + "\n\n")
echolog("OCP resources backup finished!!")
