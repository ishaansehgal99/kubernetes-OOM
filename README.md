# kubernetes-OOM
Simple project testing out OOM failure case for Kubernetes Pods

# Building the Project
1. Create DockerHub repo for project
```
(Example: https://hub.docker.com/repository/docker/ishaansehgal99/stress-test/general)
```

2. Build and Push the docker image to Dockerhub
```
docker build -t ishaansehgal99/stress-test .
docker push ishaansehgal99/stress-test
```

# Running the Project
1. Start the Minikube VM
```
minikube start
```
2. Create an OOM failing pod using oom-example-pod.yaml
```
kubectl apply -f oom-example-pod.yaml
```

 # Observations
 1. Pod Initialization: Upon running the command to create the pod, kubernetes schedules the pod for creation and starts initializing it
 2. Pod Running: Kubernetes sucessfully starts the pod, and the python script inside the pod starts running. The script then goes on to consume a large amount of memory quickly.
 3. OOM Killed: Because the python script uses more memory than the specified limit (50Mi in this case), the pod exceeds its memory limit. As a result the Linux kernel employs the OOM killer process to kick in and terminates the pod to prevent it using more memory.
 4. CrashLoopBackOff: Once the pod is terminated due to OOM kill, Kubernetes uses an exponential backoff to try and restart the pod. However since the program's memory consumption hasn't changed it quickly runs out of memory again and gets terminated.
 5. Exponential backoff: Kubernetes uses an exponential backoff schedule, delaying restart attempts more and more for each failure, as it recognizes immediate restart is not solving the problem.
 6. Persistent Failure: Despite repeated attempts, Kubernetes cannot keep the pod running because the pod always exceeds the memory limit and gets killed. Kubernetes continues to attempt to restart the pod, but it always ends up in the CrashLoopBackOff state.

In general this behavior highlights Kubernetes reslience in attempting to keep workloads running, but also its limitations in cases where pod's behavior consistently leads to its own failure. It emphasizes importance of properly configuring resource limits and ensuring that workloads can run within those limits to avoid such issues. 
