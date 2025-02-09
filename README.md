# Security & Memory Concepts in Docker

This repository contains basic security concepts that should be applied in order to keep dockerized applications safe and secure.

‎

## I-Persistence and Mounting:

This script outputs the command "Ran!" once every time it is called. It does not save any data: ```docker run python:3.12-alpine python -c 'f="/data.txt";open(f, "a").write(f"Ran!\n");print(open(f).read())'```
- Output when called once: ```Ran!```
- Output when called four times: ```Ran!```

We can edit this script so that the data remains persistent. The following script outputs the command "Ran!" as many times as it is called.
The concept of 'persistence' forces data to be saved locally.
```docker run -v mydata:/data python:3.12-alpine python -c 'f="/data/data.txt";open(f, "a").write(f"Ran!\n");print(open(f).read())'```
- Output when called once: ```Ran!```
- Output when called four times: 
```
Ran! 
Ran! 
Ran!
Ran!
```
### Mount Types:
- Volumes (used for persistence)
- Bind-mounts (used for persistence)
- Tempfs mounts (NOT used for persistence)

‎

## II-Docker Layers: Security Warning
- **```DELETE``` creates new layers:** A run command that deletes something does not modify the previous layer; it creates a new layer on top of it. That means that **it's not safe to put any sensitive information in docker images... even if you delete that information in a later command**
- **Deleted data can be recovered by users:** Layers act similarly to git history; creating a new commit will not stop a malicious user from pulling data out from previous commits

‎

## III-Multistage Builds
> Purpose: Increased security + decreased image size

```
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY src/mysite mysite

EXPOSE 8000

CMD ["uvicorn", "mysite.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

The problem in the above code is that the final image contains things only needed during the build process, and are not actually needed in production. In a real-life scenario, we would have even more files, the build process itself can generate many unwanted files (like caches and logs), and the build tools' availability on a production machine can be a huge security hazard due to a much greater attack surface.

That is why we use multistage builds, aka separating commands used for building vs running the application into separate stages. In our build stage, the goal is to produce all the wheels we need to install. The run stage needs to install those pre-built wheels and run. Our optimized code would look like this:

```
FROM python:3.12-slim AS builder

WORKDIR /app

COPY pyproject.toml requirements.txt ./
RUN pip wheel --no-cache-die --no-deps --wheel-dir wheels -r requirements.txt

COPY src src
RUN pip wheel --no-cache-die --no-deps --wheel-dir wheels . 

FROM python:3.12-slim AS runner

COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/* && rm -rf /wheels

EXPOSE 8000

CMD ["uvicorn", "mysite.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

‎

## IV-Docker Compose
Since Dockerfiles are meant for separate components, managing each container individually may be heavy and time-consuming.
For certain compositions, we use a higher-level tool called Docker Compose. Refer to ```docker-compose.yml```.

```
services:
  frontend:
    ...
    
  backend:
    ...
```

When all the images are built in the yml file, we can start everything all at once by running the command ```docker compose up```.

