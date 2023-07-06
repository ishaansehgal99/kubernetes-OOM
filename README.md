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

# Additional Exercise: Cgroup Limit Exploration 
Logged into host using:
```
minikube ssh
```

Viewed running containers using:
```
crictl ps
```

Found relevant container id:
```
CONTAINER	      NAME
c1d3b72cef072   oom-container
```

Inspected container: 
```
docker inspect c1d3b72cef072
```

This returned an entry:
```
 "CgroupParent": "/kubepods/burstable/pod6d5a0521-a5ad-4e7d-b233-d05c2ee50ae8"
```

Using this path we can insert it into the following 
```
cat /sys/fs/cgroup/memory/<cgroup_path>/memory.limit_in_bytes
```

This path represents the overall memory limit for all the containers in the pod. This limit ensures that the combined memory usage of all containers in the pod does not exceed the defined limit. 
```
cat /sys/fs/cgroup/memory/kubepods/burstable/pod6d5a0521-a5ad-4e7d-b233-d05c2ee50ae8/memory.limit_in_bytes
```
Which returns the correct bytes: 52428800

We can also go one folder deeper into the container of the pod like so:
```
cat /sys/fs/cgroup/memory/kubepods/burstable/pod6d5a0521-a5ad-4e7d-b233-d05c2ee50ae8/c1d3b72cef072add8f4e352a93ea8e0e1283e0b93b14c73531ed33f1bd4e0931/memory.limit_in_bytes
```
Which returns the correct bytes as well: 52428800 
This represents the memory limit specifically for this container on the pod. Ensuring memory usage of this specific container does not exceed the defined limit. 

If the pod just has one container as in this case, these two limits are the same. If the pod has mutliple containers, and you have memory limits for each container, then the pod's memory limit will be the sum of the memory limits of its containers. 
