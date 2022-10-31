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
