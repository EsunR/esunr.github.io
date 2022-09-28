---
title: K8S 快速入门指南
tags: []
categories:
  - CICD
  - K8S
date: 2022-09-15 14:42:48
---
# 1. 安装 minikube

## 指定 kubectl 使用的配置文件

kubectl 是基于 HTTP 可以对多个集群进行操作的，因此 kubectl 具体操作哪个集群是需要用户进行一定的配置的。具体的配置文件在 `$HOME/.kube` 目录下存放。当 minikube 安装完成并启动后，会自动将配置文件改写为指向 minikube，你可以查看 `$HOME/.kube/config` 文件中的内容，其内容为即为连接 minikube 的配置文件。

执行 `minikube start` 前的默认配置文件：

```
apiVersion: v1
clusters: null
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null
```

执行 `minikube start` 后配置文件被改写为：

```
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /Users/***/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Thu, 15 Sep 2022 15:02:11 CST
        provider: minikube.sigs.k8s.io
        version: v1.26.1
      name: cluster_info
    server: https://127.0.0.1:53926
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Thu, 15 Sep 2022 15:02:11 CST
        provider: minikube.sigs.k8s.io
        version: v1.26.1
      name: context_info
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /Users/***/.minikube/profiles/minikube/client.crt
    client-key: /Users/***/.minikube/profiles/minikube/client.key
```

同理，你也可以通过指定配置文件来访问集群，只需要在操作指令前加上 `--kubeconfig` 来指定目标配置文件即可，如：

```sh
kubectl --kubeconfig kubectl.conf -n test get pod
```

# 2. 部署应用

应用部署行为都是在 master 节点上执行的，目标是为了将多个 pod 部署到 woker 节点上。在部署多个 pod 的过程中，k8s 会自动或按照用户制定的规则，将这些 pod 分配给不同的 worker 节点。``

## 2.1 使用命令行

可以使用 `kubectl` 命令行来部署应用：

```sh
kubectl run test-cli --image=ccr.ccs.tencentyun.com/k8s-tutorial/test-k8s:v1
```

部署完成之后会创建一个 pod，通过 `kubectl get pod` 可以查看到该 pod：

```
NAME                        READY   STATUS    RESTARTS   AGE
test-cli                    1/1     Running   0          0s
```

> 使用 `kubectl get pod -o wide` 可以参看更详细的信息

## 2.2 使用 Pod 类型的工作负载文件

此外，可以编写一个 YAML 文件来创建 pod：

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  # 定义容器，可以多个
  containers:
    - name: node-app # 容器名字
      image: ccr.ccs.tencentyun.com/k8s-tutorial/test-k8s:v1 # 镜像
```

使用指令部署该文件：`kubectl apply -f ./pod.yaml`

创建完成后查看创建的 pod：

```
NAME                        READY   STATUS    RESTARTS   AGE
test-pod                    1/1     Running   0          0s
```

## 2.3 使用 Deployment 类型的工作负载

上面的文件只能创建一个 pod，如果你想要创建多个 pod，可以编写一个类型为 `Deployment` 的文件来创建多个 pod：

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  # 部署名字
  name: test-deployment
spec:
  replicas: 2
  # 用来查找关联的 Pod，所有标签都匹配才行
  selector:
    matchLabels:
      app: node-app
  # 定义 Pod 相关数据
  template:
    metadata:
      labels:
        app: node-app
    spec:
      # 定义容器，可以多个
      containers:
      - name: node-app # 容器名字
        image: ccr.ccs.tencentyun.com/k8s-tutorial/test-k8s:v1 # 镜像
```

使用指令部署该文件：`kubectl apply -f ./deployment.yaml`

创建完成后查看创建的 pod：

```
NAME                                   READY   STATUS    RESTARTS   AGE
test-deployment-977f5477d-9zsv9        1/1     Running   0          13s
test-deployment-977f5477d-wm6c6        1/1     Running   0          13s
```

使用 label 的作用是可以定位到所创建的多个 pod 中部署的某一应用：

![](https://s2.loli.net/2022/08/14/YfUhxKRzv2AjZ7i.png)

可以使用 `kubectl get deployment` 来查看通过 Deployment 方式部署的服务：

```
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
test-deployment   2/2     2            2           0s
```

在此，关于工作负载的类型，k8s 中有以下几个类型定义：

-   Deployment  
    适合无状态应用，所有pod等价，可替代
-   StatefulSet  
    有状态的应用，适合数据库这种类型。
-   DaemonSet  
    在每个节点上跑一个 Pod，可以用来做节点监控、节点日志收集等
-   Job & CronJob  
    Job 用来表达的是一次性的任务，而 CronJob 会根据其时间规划反复运行。

[文档](https://kubernetes.io/zh/docs/concepts/workloads/)

## 2.4 更新或回滚 pod

### 更新

如果需要更新 pod，则只需要修改 deployment 文件的信息，然后再执行 `kubectl apply -f ./deployment.yaml` 指令对 pod 重新部署，k8s 就会自动将所有的 pod 更新为最新的版本。

> 在这一过程中，k8s 会逐个将 pod 销毁然后再重新创建，以保证线上服务不会被中断。

此外还可以使用命令行来直接更新 pod 中的某个应用的镜像源：

```sh
kubectl set image deployment <deployment name> <container name>=<image> --record
```

> `--record` 可以将这次操作写入历史记录，方便后续回滚

如果在修改的过程中你需要执行多个操作，但你并不想每执行一个操作都重新部署一遍，那么可以使用 `kubectl rollout pause deployment <deployment name>` 指令先暂停部署，修改完成后再使用 `kubectl rollout resume deployment <deployment name>` 恢复部署。

更新完成后如果你想要获取一份最新的 deployment yaml 文件，可以执行：

```sh
kubectl get deployment <deployment name> -o yaml >> new.yaml
```

### 回滚

如果应用在更新后出现了问题，我们需要回滚 pod，则只需执行：

```sh
kubectl rollout undo deployment <deployment name> [--to-reversion=<reversion>]
```

> --to-reversion 可以指定回滚到具体哪个版本，如果不加则自动回滚到上一版本

如果需要查看所有的历史记录，则可以使用该指令：

```sh
kubectl rollout history deployment <deployment name>
```

```
deployment.apps/test-deployment 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none> # 如果是通过修改 deployment 文件来更新的话是不会留下历史记录的
```

## 2.5 关于 pod 的其他指令

- `kubectl get all` 查看所有信息
- `kubectl describe pod <pod name>` 可以查看单个 pod 的详细信息
- `kubectl logs [pod/]<pod name> -c <container name> -f` 查看单个 pod 的日志
	- 如果 pod 中只有一个容器应用，则不需要指定容器
- `kubectl exec -it [pod/]<pod name> -c <container name>` 进入到某个 pod 的容器中
	- 如果 pod 中只有一个容器应用，则不需要指定容器
- `kubectl scale deployment <deployment name> --replicas=<pod count>` 修改某个部署的 pod 数量
	- 如果指定的新的 pod 数量大于当前的数量，这是一个扩展行为，原有已创建的 pod 还会仍会存在，并不会被销毁
	- 如果指定的新的 pod 数量小于当前的数量，这是一个削减行为，会删除掉部分已有的 pod
- `kubectl rollout restart deployment <delpyment name>` 重新部署某个服务
- `kubectl delete pod <pod name>`  删除某个 pod，但这个 pod 如果是某个部署的 pod，则会在删除之后重新生成一个
- `kubectl delete deployment <deployment name>`  删除某个部署
- `kubectl delete all --all` 删除全部资源
- `kubectl port-forward <pod name> <target port>:<container port>` 通过端口映射方式访问到指定 pod 中的端口

> 更多官网关于 [Deployment](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/) 的介绍

## 2.6 将 Pod 指定到某个节点运行

将 Pod 指定到某个节点运行：[nodeselector](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)  
限定 CPU、内存总量：[文档](https://kubernetes.io/zh/docs/concepts/policy/resource-quotas/#%E8%AE%A1%E7%AE%97%E8%B5%84%E6%BA%90%E9%85%8D%E9%A2%9D)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: ssd
```

