ARG BUILD=linux/amd64

FROM --platform=$BUILD python:3.11.12-slim-bookworm AS mkdocs

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
#ENV PYENV_ROOT="/root/.pyenv"
#ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
#ENV PIPX_DEFAULT_PYTHON="$PYENV_ROOT/shims/python"
ENV PATH="/root/.local/bin:$PATH"

#RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
#        curl git build-essential libssl-dev zlib1g-dev libbz2-dev \
#        libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils \
#        tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
#        ca-certificates pipx python3-pip \
#        libcairo2-dev libgirepository1.0-dev gir1.2-glib-2.0 \
#        pkg-config gir1.2-ostree-1.0 libostree-dev \
#    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
        git build-essential ca-certificates pipx python3-pip \
        libcairo2-dev libgirepository1.0-dev gir1.2-glib-2.0 \
        pkg-config gir1.2-ostree-1.0 libostree-dev \
    && rm -rf /var/lib/apt/lists/*

#RUN curl https://pyenv.run | bash \
#    && pyenv init - >> /etc/profile \
#    && pyenv install 3.11.12 \
#    && pyenv global 3.11.12 \
#    && rm -rf "$PYENV_ROOT/cache"

RUN python -m pip install --user pipx uv \
    && python -m pipx ensurepath \
    && pipx install git+https://github.com/pulp/pulp-docs.git@main \
    && find ~/.cache/pip -name "*.whl" -delete \
    && rm -rf ~/.cache/pipx/cache

RUN RUN set -eux; \
    mkdir -p /opt/pulp && \
    cd /opt/pulp && \
    for repo in \
        pulpcore pulp_rpm pulp_file pulp_container pulp_deb pulp_ansible \
        pulp_python pulp_ostree pulp_gem pulp_maven pulp_npm pulp_certguard \
        pulp_hugging_face pulp_rust pulp-cli pulp-glue pulp-ui pulp-operator \
        pulp-oci-images pulp-openapi-generator pulpcore-selinux oci_env pulp-docs; \
    do \
        git clone --depth=1 https://github.com/pulp/${repo}.git; \
    done

LABEL org.opencontainers.image.licenses="MIT"
      
LABEL org.opencontainers.image.source="https://github.com/iralthereal/pulp-doc-docker.git"

RUN cd /opt/pulp/pulp-docs && pulp-docs build

#EXPOSE 8000

#CMD ["bash", "-c", "cd /opt/pulp/pulp-docs && pulp-docs serve --dev-addr=0.0.0.0:8000"]

FROM nginx:alpine

COPY --from=mkdocs /opt/pulp/pulp-docs/site/ /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN apk update && apk upgrade --no-cache

LABEL org.opencontainers.image.licenses="MIT"

LABEL org.opencontainers.image.source="https://github.com/iralthereal/pulp-doc-docker.git"

EXPOSE 8000
