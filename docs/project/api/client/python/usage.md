# How to use API in your application

This section outlines how to integrate the HTC grid with your current application.
## How to use the API in your application
Below you will find a python example that demonstrate how to use the API in your application
```Python

from api.connector import AWSConnector

import os
import json
import logging

client_config_file = os.environ['AGENT_CONFIG_FILE']

with open(client_config_file, 'r') as file:
    client_config_file = json.loads(file.read())


if __name__ == "__main__":

    logging.info("Simple Client")
    gridConnector = AWSConnector()

    gridConnector.init(client_config_file, username=username, password=password)
    gridConnector.authenticate()

    task_1_definition = {
        "worker_arguments": ["1000", "1", "1"]
    }

    task_2_definition = {
        "worker_arguments": ["2000", "1", "1"]
    }

    submission_resp = gridConnector.send([task_1_definition, task_2_definition])
    logging.info(submission_resp)


    results = gridConnector.get_results(submission_resp, timeout_sec=100)
    logging.info(results)
```

Current release of HTC-Grid includes only Python3 API. However, if required, it is possible to develop a custom API using different languages (e.g., Java, .Net, etc.). Existing API is very concise and relies on the AWS API to interact with AWS services (refer to./source/client/python/api-v0.1/api for the example).

## How to run a client application
### Running a Client Application as a pod on EKS

This is the easiest way to deploy a client application for testing purposes. Overview:
1. A client application is being packaged locally into a container.
2. The container is being deployed on the same EKS cluster governed by HTC-Grid as Job.
3. Once container is deployed, it launches the client application that submits the tasks.

#####
Details:
1. **Build and Push docker image** Build an image that will have all dependencies to be able to execute the client. See example in `examples/submissions/k8s_jobs/Dockerfile.Submitter`.
   In the example below we copy client.py into a container and install all dependencies form the requirements.txt.

    ```Docker
    FROM python:3.7.7-slim-buster

    RUN mkdir -p /app/py_connector
    RUN mkdir -p /dist

    COPY ./dist/* /dist/
    COPY ./examples/client/python/requirements.txt /app/py_connector/

    WORKDIR /app/py_connector

    RUN pip install -r requirements.txt

    COPY ./examples/client/python/client.py .
    ```

   Push the image into the registry

    ```Makefile
    SUBMITTER_IMAGE_NAME=submitter
    TAG=<the tag specified during the HTC-Grid deployment>
    HTCGRID_ECR_REPO=$(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com

    docker push $(HTCGRID_ECR_REPO)/$(SUBMITTER_IMAGE_NAME):$(TAG)
    ```
2. Create a deployment .yaml file. For example:

    ```yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
    name: single-task
    spec:
    template:
        spec:
        containers:
        - name: generator
            securityContext:
                {}
            image: XXXXXX.dkr.ecr.eu-west-1.amazonaws.com/submitter:XXXX
            imagePullPolicy: Always
            resources:
                limits:
                cpu: 100m
                memory: 128Mi
                requests:
                cpu: 100m
                memory: 128Mi
            command: ["python3","./simple_client.py", "-n", "1",  "--worker_arguments", "1000 1 1","--job_size","1","--job_batch_size","1","--log","warning"]
            volumeMounts:
            - name: agent-config-volume
                mountPath: /etc/agent
            env:
            - name: INTRA_VPC
                value: "1"
        restartPolicy: Never
        nodeSelector:
            htc/node-type: core
        tolerations:
        - effect: NoSchedule
            key: htc/node-type
            operator: Equal
            value: core
        volumes:
            - name: agent-config-volume
            configMap:
                name: agent-configmap
    backoffLimit: 0
    ```

   For the examples provided with HTC-Grid, these .yaml files are generated automatically when `make happy-path` command is executed. Each .yaml file is a template (e.g., examples/submissions/k8s_jobs/single-task-test.yaml.tpl) that is being filled in with relevant fields that match the AWS account and deployment configuration. The substitution is done by examples/submissions/k8s_jobs/Makefile and relevant attributes are passed in by the ./Makefile.

   Note, once docker image is built and pushed into registry, the yaml file contains the ``command`` parameter that tells how to launch the client application once container is running.

   The deployment yaml file can be generated by extending existing build process, written manually, or generated in any other way that suited the workload.

3. To launch the client, simply execute the following command.

    ```Bash
    kubectl apply -f ./generated/<custom.yaml.file>.yaml
    ```

### Running a Client Application locally

<TODO>
