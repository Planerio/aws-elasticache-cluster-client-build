# aws-elasticache-cluster-client-build

## Build the PHP memcached extension in ElastiCache flavor

### Prerequisites

- a working Docker setup

### Supported flavors

- only Linux 64bit
- PHP 7.1 through to PHP 7.4 - thanks to the sury.org PHP repository!
- with and without igbinary
- only without SASL
- only without JSON
- only without msgpack

### How-to

1. Clone this repo
2. `git submodule update --init`
3. In the `aws-elasticache-cluster-client-*` repos, switch to the git branch that you want to build. Usually the default is fine.
4. Build the library and the extension, either with or without support for igbinary serialization:
    ```
    docker build --iidfile=/tmp/elasticache.docker \
        --build-arg PHP_VERSION=7.4 \
        --build-arg ENABLE_IGBINARY=0 \
        .
    ```
5. Extract the freshly built PHP extension, optionally wrap into a tar file:
    ```
    docker run -ti \
        -v "$(pwd)/dist":/dist `cat /tmp/elasticache.docker` \
        bash -c 'cd `find /usr/lib/php/ -name memcached.so -printf '%h'` && \
            tar cvf /dist/AmazonElastiCacheClusterClient-PHP-64bit.tar.gz memcached.so'
    ```
    (This convoluted snippet stores the built extension in a .tar.gz file into the "dist" folder.)
6. Clean up Docker images 😉
