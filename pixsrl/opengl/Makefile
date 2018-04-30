
all: vnc-virtual-gl

self.pem:
	openssl req -new -x509 -days 365 -nodes -out $@ -keyout $@

vnc-virtual-gl: self.pem

%: Dockerfile.%
	docker build . -t $@ -f $<
#	docker run --runtime=nvidia -ti --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix $@
