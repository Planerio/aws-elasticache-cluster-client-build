# aws-elasticache-cluster-client-build

## Build the PHP memcached extension in ElastiCache flavor

### Prerequisites

- a working Docker setup

### Supported flavors

- only Linux 64bit
- PHP 7.1 through to PHP 7.4 and also PHP 8 - thanks to the sury.org and remirepo.net PHP repositories!
- with or without igbinary (`--build-arg ENABLE_IGBINARY=1`)
- with or without msgpack (`--build-arg ENABLE_MSGPACK=1`)
- with or without JSON (`--build-arg ENABLE_JSON=1`)
- only without SASL

### How-to

1. Clone this repo
2. `git submodule update --init`
3. In the `aws-elasticache-cluster-client-*` repos, switch to the git branch that you want to build. Usually the default is fine.
4. **For Debian 10 / compatible:** Build the library and the extension, enable optional features using the `build-arg`s listed above:
    ```
    docker build -f Dockerfile.debian --iidfile=/tmp/elasticache.docker \
        --build-arg PHP_VERSION=7.4 \
        --build-arg ENABLE_JSON=1 \
        .
    ```
    **For Amazon Linux 2 / CentOS 7:** Build the library and the extension, enable optional features using the `build-arg`s listed above:
    ```
    docker build -f Dockerfile.amazonlinux2 --iidfile=/tmp/elasticache.docker \
        --build-arg PHP_VERSION=7.4 \
        --build-arg ENABLE_JSON=1 \
        .
    ```
5. Extract the freshly built PHP extension, optionally wrap into a tar file:
    ```
    docker run -ti --rm \
        -v "$(pwd)/dist":/dist `cat /tmp/elasticache.docker` \
        bash -c 'cd /build/final && \
            tar czvf /dist/AmazonElastiCacheClusterClient-PHP-64bit.tar.gz memcached.so'
    ```
    (This convoluted snippet stores the built extension in a .tar.gz file into the "dist" folder.)
6. Clean up Docker images 😉
