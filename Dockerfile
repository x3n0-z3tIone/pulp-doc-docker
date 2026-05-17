FROM ubuntu:22.04

RUN apt update && apt upgrade -y && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=UTC

RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        curl git build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils \
        tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
        ca-certificates python3 python-is-python3 pipx python3-pip \
        libcairo2-dev libgirepository1.0-dev gir1.2-glib-2.0 \
        pkg-config python3-dev gir1.2-ostree-1.0 libostree-dev\
 && rm -rf /var/lib/apt/lists/*

ENV PYENV_ROOT="/root/.pyenv"

ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

ENV PIPX_DEFAULT_PYTHON="$PYENV_ROOT/shims/python"

RUN curl https://pyenv.run | bash && \
    pyenv init - >> /etc/profile

RUN pyenv install 3.11.12 && pyenv global 3.11.12

RUN python -m pip install --user pipx

RUN python -m pipx ensurepath

RUN pipx install git+https://github.com/pulp/pulp-docs.git@main

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

CMD ["bash", "-c", "cd /opt/pulp/pulp-docs && pulp-docs serve"]
