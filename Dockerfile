FROM scratch

RUN echo "Hello World 1"

CMD ["/bin/sh", "-c", "echo 'Hello World 2'"]
