# Stage 1: Clone the repository
FROM node:20-bullseye-slim as clone
WORKDIR /app
RUN git clone https://github.com/imputnet/cobalt.git /app

# Stage 2: Set up the environment and install dependencies
FROM node:20-bullseye-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Stage 3: Build the application
FROM base AS build
WORKDIR /app

# Copy the cloned repository files
COPY --from=clone /app /app

RUN corepack enable
RUN apt-get update && \
    apt-get install -y python3 build-essential

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

# Stage 4: Prepare the API
FROM base AS api
WORKDIR /app

# Copy the built API files
COPY --from=build /prod/api /app

# Expose the required port and run the application
EXPOSE 9000
CMD [ "node", "src/cobalt" ]

