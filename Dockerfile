# Isolated sshhole reproduction image.
FROM alpine:3.24.1

# Keep the pre-fix OpenSSH package set for this reproduction.
# Alpine's repository now publishes a newer revision.
ARG ALPINE_ARCH=aarch64
ARG ALPINE_MAIN_REPO=https://dl-cdn.alpinelinux.org/alpine/v3.24/main
ARG OPENSSH_PACKAGE_VERSION=10.3_p1-r1

# Install matching OpenSSH packages. These split packages must use the same
# revision because they have exact-version dependencies on one another.
RUN set -eux; \
    apk update; \
    for package in \
        openssh-server-pam \
        openssh-server-common \
        openssh-keygen; \
    do \
        apk_file="/tmp/${package}-${OPENSSH_PACKAGE_VERSION}.apk"; \
        wget \
            --output-document="$apk_file" \
            "${ALPINE_MAIN_REPO}/${ALPINE_ARCH}/${package}-${OPENSSH_PACKAGE_VERSION}.apk"; \
    done; \
    apk add \
        "/tmp/openssh-server-pam-${OPENSSH_PACKAGE_VERSION}.apk" \
        "/tmp/openssh-server-common-${OPENSSH_PACKAGE_VERSION}.apk" \
        "/tmp/openssh-keygen-${OPENSSH_PACKAGE_VERSION}.apk"; \
    rm \
        "/tmp/openssh-server-pam-${OPENSSH_PACKAGE_VERSION}.apk" \
        "/tmp/openssh-server-common-${OPENSSH_PACKAGE_VERSION}.apk" \
        "/tmp/openssh-keygen-${OPENSSH_PACKAGE_VERSION}.apk"; \
    ssh-keygen -A

# Configure the lab-only authentication path before Alpine's defaults.
RUN set -eux; \
    { \
        printf '%s\n' \
            'PasswordAuthentication yes' \
            'UsePAM no'; \
        cat /etc/ssh/sshd_config; \
    } > /tmp/sshd_config; \
    mv /tmp/sshd_config /etc/ssh/sshd_config

# `alpine` is the passwordless target, represented by a literal `*` in
# /etc/shadow. OpenSSH borrows a salt from another account with a real password
# hash while checking this account. `authsource` supplies that hash; its
# password is throwaway and exists only for this isolated reproduction.
RUN set -eux; \
    adduser -D alpine; \
    sed -i 's/^alpine:[^:]*:/alpine:*:/' /etc/shadow; \
    adduser -D authsource; \
    printf '%s\n' 'authsource:lab-only-password' | chpasswd

EXPOSE 22

CMD ["/usr/sbin/sshd.pam", "-D", "-e"]
