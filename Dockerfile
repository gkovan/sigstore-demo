FROM registry.access.redhat.com/ubi8/go-toolset as builder
COPY main.go .
RUN go build -o ./app .

FROM docker.io/gkovan/ubi8-minimal:stable
#FROM registry.access.redhat.com/ubi8/ubi-minimal:8.3
LABEL base.image="docker.io/gkovan/ubi8-minimal:stable"
CMD ["./app"]
COPY --from=builder /opt/app-root/src/app .
