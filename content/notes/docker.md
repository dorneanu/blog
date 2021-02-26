+++
title = "docker"
author = ["Victor Dorneanu"]
lastmod = 2021-02-26T11:12:20+01:00
tags = ["note"]
draft = false
weight = 2005
toc = true
noauthor = true
nocomment = true
nodate = true
nopaging = true
noread = true
+++

## Commands {#commands}

-   Run a container

    ```sh
        $ docker run -ti <image repository> --name <name of new container>
    ```
-   Attach to running container

    ```sh
        $ docker attach --name <name of container>
    ```
-   Run command inside a running container

    ```sh
        $ docker container exec -ti <name of container> <command>
    ```
