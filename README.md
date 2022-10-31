# lab-caddy
OCI container image for my home lab's reverse proxy, Caddy. 

The idea here is to make it small and rootless.
This is done a few ways:

1. Uses Google's Distroless image as its base
2. Uses a non-root user (named `nonroot`) 
3. Uses unpriveliged HTTP(S) ports

That last part means that the container won't need to run with root either.
Access to the ports will be done with the host machine's firewall, which already has root.
That is to say, the firewall will redirect `$if_inet:{80,443}` to `127.0.0.1:{8080,4443}`.

So, running this container in rootless Podman it starts listening on 8080.
It happens to be running on a host using firewalld. 
Running this following command sets up the port redirecting:

```
# firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080
```

Note that there's no final `:toaddr=<ip>` and that we didn't need to enable masquerading.
Then it works! 
Request to port 80 get redirected to Caddy, everything happy and working without root.

The command to start the container, for my own future reference was:

```
$ podman run -i -t -p 8080:8080 ghcr.io/samhclark/lab-caddy:latest
```
