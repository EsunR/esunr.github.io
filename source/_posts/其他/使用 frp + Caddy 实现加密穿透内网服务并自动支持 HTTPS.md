---
title: 使用 frp + Caddy 实现加密穿透内网服务并支持 HTTPS
tags:
  - Caddy
  - Nginx
  - frp
  - Canvas
  - Https
categories:
  - 其他
date: 2025-05-22 10:33:18
---
# 1. 前置概念

## 1.1 内网穿透与 frp

当我们在内网部署了某些服务后，想要在公网使用，却有没有公网 IP，这时候就需要用到内网穿透。所谓的内网穿透实际上就是我们找一台具有公网 IP 的服务器，然后将内网与这台公网服务器建立连接，当用户访问公网服务器时，公网服务器就能将请求转发到内网的服务器上，实现了在公网访问内网的服务。

frp 就是一个使用 Go 编写的内网穿透工具，可以在公网服务器上部署 frps（frp 服务端），在内网环境部署 frpc（frp 客户端），frp 支持使用各种协议让服务端与客户端建立连接，比如最简单的 TCP、UDP 连接，也支持带加密的 STCP、HTTPS 链接。

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202505221059502.png)

## 1.2 Caddy

Caddy 是一个类似于 Nginx 的服务器，但是相对于 Nginx 配置更为简单，并且 Caddy 的一大特点是可以自动校验域名的归属并自动为网站申请免费的 TLS 证书（通过 ACME），让网站支持 HTTPS。

# 2. 实现

frp 是支持 https 服务的穿透的，但是如果每一个网站都要我们自己配置 https 证书并配置对应的 frp 穿透的话就太累了。

同时，frp 也支持 STCP 通信，这样就可以将 http 请求包裹一层 STCP 加密来实现公网信息的加密传输，但是这就也要要求公网用户必须使用 frpc 来访问 frps（类似起到一个 VPN 客户端的作用），中间的公网服务器起到一个转发的作用，frps 本身并不提 STCP 协议，frp 使用 STCP 协议通信时的流程如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202505221142458.png)

那有什么办法可以让客户端不装 frpc 也能加密访问内网的服务吗，方法当然是有的，那就是在公网服务器上同时部署 frpc 和 frps 以及 caddy。当公网用户访问公网服务器时，使用的是 caddy 提供的 https 连接，然后 caddy 将 https 解密为 http 后将请求转发到 frpc 中，frpc 将请求套一层 STCP 加密后会丢给 frps，frps 再通过已与内网环境建立的连接，将请求传递给内网环境中的 frpc，然后内网环境的 frpc 将 STCP 解密得到公网用户原始的 http 请求，将请求再转发给内网的 http 服务器（如 Nginx），http 服务再去请求内网环境部署的各种服务即可。整体的流程如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202505221349091.png)

Caddy 配置：

```
app.example.site {
    reverse_proxy localhost:1443
}
```

公网服务器 frpc 配置：

```toml
serverAddr = "127.0.0.1"
serverPort = 6666

[[visitors]]
name = "secret_http_visitor"
type = "stcp"
serverName = "secret_http"
secretKey = "your-secret"
bindAddr = "127.0.0.1"
bindPort = 1443
```

公网服务器 frps 配置：

```toml
bindPort = 6666
```

内网 frpc 配置：

```toml
serverAddr = "111.123.10.1"
serverPort = 6666

[[proxies]]
name = "secret_http"
type = "stcp"
secretKey = "your-secret"
localIp = "127.0.0.1"
localPort = 80
```

内网 Nginx 反向代理配置，请求 Origin 为 `app.example.site` 的请求转发至 `http://127.0.0.1:2222`（仅供参考）：

```
server {
    listen 80 ; 
    server_name app.example.site; 
    index index.html; 
    proxy_set_header Host $host; 
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; 
    proxy_set_header X-Forwarded-Host $server_name; 
    proxy_set_header X-Real-IP $remote_addr; 
    proxy_http_version 1.1; 
    proxy_set_header Upgrade $http_upgrade; 
    proxy_set_header Connection $http_connection; 
    client_max_body_size 5120M;
    
    location ^~ / {
	    proxy_pass http://127.0.0.1:2222; 
	    proxy_set_header Host $host; 
	    proxy_set_header X-Real-IP $remote_addr; 
	    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; 
	    proxy_set_header REMOTE-HOST $remote_addr; 
	    proxy_set_header Upgrade $http_upgrade; 
	    proxy_set_header Connection $http_connection; 
	    proxy_set_header X-Forwarded-Proto $scheme; 
	    proxy_http_version 1.1; 
	    add_header X-Cache $upstream_cache_status; 
	    add_header Cache-Control no-cache; 
	    proxy_ssl_server_name off; 
	    proxy_ssl_name $proxy_host; 
	}
}
```

这种模式下 frpc 与 frps 服务之间存在依赖关系，因此需要按照以下顺序启动：

1. 公网服务器的 frps
2. 内网的 frpc 服务
3. 公网服务器的 fprc
