apiVersion: batch/v1
kind: Job
metadata:
  name: portfolio-pricing-full-run
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: "runtime/default"
spec:
  parallelism: 1
  completions: 20
  backoffLimit: 10
  activeDeadlineSeconds: 21600
  template:
    spec:
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: generator
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          seccompProfile:
            type: RuntimeDefault
          capabilities:
            drop:
            - NET_RAW
            - ALL
        image: {{account_id}}.dkr.ecr.{{region}}.amazonaws.com/{{image_name}}:{{image_tag}}
        imagePullPolicy: Always
        resources:
            limits:
              cpu: 4
              memory: 16Gi
            requests:
              cpu: 1
              memory: 2Gi
        command: ["python3","./portfolio_pricing_client.py", "--workload_type", "random_portfolio", "--portfolio_size", "500000", "--trades_per_worker", "100", "--timeout_sec", "21600"]
        volumeMounts:
          - name: agent-config-volume
            mountPath: /etc/agent
        env:
          - name: INTRA_VPC
            value: "1"
      restartPolicy: OnFailure
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
