# Dockerized Gukort2

The Docker specific files are located in the `docker` directory:

```
docker
├── .env.sample
├── docker-compose.yml
├── docker-entrypoint-initdb.d/
│   └── .keep
├── api/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── .dockerignore
└── scripts/
    ├── setup.sh
    ├── build.sh
    ├── prepare_for_git.sh
    └── teardown.sh

```

Use your real `.env` file instead of the `.env.sample` and follow the instructions below. 
(The `docker-compose.yml` provided is the one for development.)

If you have access to the gukort2 image referred to in `docker-compose.yml`/`.env`, just follow these steps:

1. Change directory to the `docker` directory.
2. Copy your gukort2 sql dump file to `docker-entrypoint-initdb.d/`.
3. Run `docker-compose up`, if you want to run gukort2 in the foreground, or `docker-compose up -d`, if you want to run it [d]etached.

If you have to build the gukort2 image yourself, but don't want to modify anything, start by doing the following:

1. Change directory to the `docker/scripts` directory.
2. Run `./setup.sh`.
3. Run `./build.sh`.
4. Run `./teardown.sh`.

If you want to modify the project, proceed as follows:

1. Change directory to the `docker/scripts` directory.
2. Run ./`setup.sh`.
3. Make your changes. (If you want to modify `Dockerfile`, `entrypoint.sh` or `.dockerignore`, you should make your changes in the versions in the `gukort2` directory.) 
4. Change the existing value of IMAGE_API in `../.env`, and other values if necessary.
5. Run `./build.sh`.
6. Change directory: `../..`
7. Follow the three  instructions for deploying using `docker-compose` above.
8. Change directory to the `docker/scripts` directory.
9. If necessary, repeat steps 3-8 above.
10. When you are ready to publish your results, run `./prepare_for_git.sh`
11. Add and commit to the `dockerize` Git branch and push to the `dockerize` branch of the gukort2 repo on GitHub.
12. Run `./teardown.sh`.

