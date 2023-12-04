# 10. Kubernetes

0.) Minikube

Minikube is local Kubernetes, focusing on making it easy to learn and develop for Kubernetes.
All you need is Docker (or similarly compatible) container or a Virtual Machine environment.
As a VM-driver we will use Docker to run nodes as containers. So we have to have Docker engine installed and configured to run privileged containers.
If curl binary is absent, we should also install curl.

In the guide, we use Ubuntu 22.04.3 LTS x86_64

1.) Install Minikube 

```shell
sudo apt intall curl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

2.) Verify and start Minikube

```shell
minikube version
minikube start --vm-driver=docker
minikube status
```
3.) Install kubectl

To interact with the cluster, we should also install kubectl cli.
We must use a kubectl version that is within one minor version difference of your cluster.
As follows from the logs, Minikube runs Kubernetes v1.28.x, so we should install kubectl v1.28.x.

Download 1.28.3 version of kubectl:

```shell
curl -LO https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl
```

Validate the binary (optional):

```shell
curl -LO "https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
```

Install kubectl and check the version:

```shell
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version
```

4.) Interact with the cluster

Let’s check current k8s context:

```shell
kubectl config current-context
```

As we have a functional k8s cluster with internal components, we can easily list all pods across different namespaces:

```shell
kubectl get pods -A
```

For additional insight into your cluster state, minikube bundles the Kubernetes Dashboard, 
allowing users to get easily acclimated to your new environment:

```shell
minikube dashboard
```

To check k8s nodes, run:

```shell
kubectl get node -o wide
```

As we can see, we only have 1 node which acts like a master/worker. Docker is a container runtime. 
Since we configured to run nodes as containers, let’s check running containers via docker cli:

```shell
docker container ls
```

5.) Run a pod

Let’s run a single pod with nginx container. Instead of using kubectl run command, 
we will use kubectl apply command with a yaml manifest file:

```nginx-pod.yml```
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: myapp
    type: frontend
spec:
  containers:
    - name: nginx-container
      image: nginx
```

Apply pod’s k8s manifest. Worth noting that we are deploying to the “default” namespace if we don’t specify it explicitly:

```shell
kubectl apply -f nginx-pod.yml
```

Get logs of Nginx container:

```shell
kubectl logs nginx-pod
```

List all running pods in the “default” namespace. Since we deployed only 1 pod, we should see only 1 pod:

```shell
kubectl get pods
```

5.) Run a replica set

Let’s run a replica set with 3 nginx pods. To deploy a replica set, we will use kubectl apply command with a yaml manifest file:

```nginx-replicaset.yml```
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
  labels:
    app: myapp
    type: frontend
spec:
  template:
    metadata:
      name: nginx-pod
      labels:
        app: myapp
        type: frontend
    spec:
      containers:
        - name: nginx-container
          image: nginx
  replicas: 3
  selector:
    matchLabels:
      type: frontend
```

Apply replica set’s k8s manifest:

```shell
kubectl apply -f nginx-replicaset.yml
```

List all replica sets. Since we deployed only 1 replica set, we should see only 1 replica set:

```shell
kubectl get rs
```

List all running pods. Since we deployed 3 pods, we should see 3 pods:

```shell
kubectl get pods
```

However, where is the old pod we created in the previous step? The total number of running pods should be 4 you say.
Relax, that pod is still running. It’s just managed by the replica set.

The culprit is the selector field, as the labels in our single pod match those in the pods in the replicaset configuration.
Replica set found a pod that matches the selector and took control of it. That’s why we don’t see 4 pods, but only 3.
And this is the main difference between a replication controller and a replica set.

Let's delete the replica set and check that no pods are running:

```shell
kubectl delete -f nginx-replicaset.yml
kubectl get pods
```

6.) Run a deployment

Deploy a deployment with 3 nginx pods. To deploy a deployment object, we will use kubectl apply command with a yaml manifest file:

```nginx-deployment.yml```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: myapp
    type: frontend
spec:
  template:
    metadata:
      name: nginx-pod
      labels:
        app: myapp
        type: frontend
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.25.2
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
  replicas: 3
  selector:
    matchLabels:
      type: frontend
```
Apply the deployment’s k8s manifest:

```shell
kubectl apply -f nginx-deployment.yml
```

List all deployments in "default" namespace. Since we deployed only 1 replica set, we should see only 1 replica set:

```shell
kubectl get deployment
```

List all rollouts of the deployment. Since we have only 1 rollout, we should see only 1 rollout:

```shell
kubectl rollout history deployment/nginx-deployment
```

The initial rollout is called revision 1. Let's update the image for nginx container of the deployment and check the rollout history:

```shell
kubectl set image deployment/nginx-deployment nginx-container=nginx:1.25.3
kubectl rollout history deployment/nginx-deployment
```

Inspect the deployment:

```shell
kubectl describe deployment nginx-deployment
```
As we can see, the current image of nginx container is nginx:1.25.3.

Let's rollback to the previous revision, check the rollout history, and check nginx container image:

```shell
kubectl rollout undo deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl describe deployment nginx-deployment
```

The current revision is 3, and the current image of nginx container is nginx:1.25.2.
After executing the "Rollout undo" command, the deployment was rolled back to the previous revision. 
However, instead of deleting revision 2, it created revision 3.

Let's scale the the deployment to 6 replicas imperatively and check the number of replicas:

```shell 
kubectl scale deployment/nginx-deployment --replicas=6
kubectl get pods
```

Compare the current state of the deployment against the state that the deployment would be in if the manifest was applied:

```shell
kubectl diff -f nginx-deployment.yml
```

7.) Create a service

To reach our application, we should create a service. To create a service, 
we will use kubectl apply command with a yaml manifest file:

```nginx-service.yml```
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: myapp
    type: frontend
```

Create a service:

```shell
kubectl apply -f nginx-service.yml
```

List all services in "default" namespace:

```shell
kubectl get service
```

Get the information about the service in yaml format:

```shell
kubectl get service nginx -o yaml
```

Now we want to check that we can reach our application. To do that, we should do port forwarding:

```shell
kubectl port-forward service/nginx 8085:80
```

Open http://localhost:8085 in your browser or run the following command in another terminal window:

```shell
curl http://localhost:8085
```

Close port-forwarding by pressing Ctrl+C.

Delete the deployment and the service:

```shell
kubectl delete deployment nginx-deployment
kubectl delete service nginx
```