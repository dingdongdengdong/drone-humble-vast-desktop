# Vast.ai Ubuntu 22.04 base + desktop + ROS2 Humble + PX4 DDS tooling
#
# Isaac Sim and Pegasus are intentionally NOT installed here.
# Install Isaac Sim 5.1 manually under /workspace/isaacsim, then install Pegasus as an Isaac Sim extension.

ARG BASE_IMAGE=vastai/base-image:cuda-12.8.1-cudnn-devel-ubuntu22.04
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV ROS_DISTRO=humble
ENV ROS_WS=/workspaces/ros2_ws
ENV PEGASUS_WS=/workspaces/pegasus_ws
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV CYCLONEDDS_URI=file:///etc/cyclonedds/px4_humble.xml
ENV DISPLAY=:1
ENV RESOLUTION=1920x1080x24
ENV MICRO_XRCE_DDS_AGENT_REF=v2.4.3

RUN source /etc/os-release && \
    echo "Detected Ubuntu codename: ${VERSION_CODENAME}" && \
    test "${VERSION_CODENAME}" = "jammy"

# Core Ubuntu tools. Do not reinstall supervisor: Vast base-image already has it.
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    curl \
    wget \
    git \
    gnupg \
    ca-certificates \
    lsb-release \
    software-properties-common \
    sudo \
    nano \
    vim \
    tmux \
    htop \
    pciutils \
    usbutils \
    iproute2 \
    iputils-ping \
    net-tools \
    build-essential \
    cmake \
    make \
    ninja-build \
    pkg-config \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    python3-yaml \
    python3-empy \
    python3-numpy \
    python3-lark \
    python3-jinja2 \
    libasio-dev \
    libtinyxml2-dev \
    && locale-gen en_US en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Enable universe and install lightweight desktop/noVNC.
RUN add-apt-repository universe -y && \
    apt-get update && apt-get install -y --no-install-recommends \
    dbus-x11 \
    x11-xserver-utils \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    xfce4 \
    xfce4-terminal \
    && rm -rf /var/lib/apt/lists/*

# Tailscale CLI/daemon, optional runtime use with --cap-add=NET_ADMIN --device=/dev/net/tun.
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg \
      -o /usr/share/keyrings/tailscale-archive-keyring.gpg && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list \
      -o /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y --no-install-recommends tailscale && \
    rm -rf /var/lib/apt/lists/*

# ROS2 Humble apt repository and drone/ROS packages.
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
      -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
      > /etc/apt/sources.list.d/ros2.list && \
    apt-get update && apt-get install -y --no-install-recommends \
      python3-colcon-common-extensions \
      python3-rosdep \
      python3-vcstool \
      python3-argcomplete \
      ros-humble-ros-base \
      ros-humble-demo-nodes-cpp \
      ros-humble-demo-nodes-py \
      ros-humble-rmw-cyclonedds-cpp \
      ros-humble-rmw-fastrtps-cpp \
      ros-humble-cyclonedds \
      ros-humble-foxglove-bridge \
      ros-humble-rosbridge-suite \
      ros-humble-mavros \
      ros-humble-mavros-extras \
      ros-humble-geographic-msgs \
      ros-humble-vision-msgs \
      ros-humble-image-transport \
      ros-humble-compressed-image-transport \
      ros-humble-compressed-depth-image-transport \
      ros-humble-cv-bridge \
      ros-humble-tf2-ros \
      ros-humble-tf-transformations \
      ros-humble-rviz2 \
      ros-humble-rqt-graph \
      ros-humble-rqt-image-view \
      ros-humble-nav2-msgs \
      ros-humble-diagnostic-updater \
      ros-humble-rosbag2 \
      ros-humble-rosbag2-storage-mcap \
      && rm -rf /var/lib/apt/lists/*

# Build Micro XRCE-DDS Agent standalone for PX4 ROS2 bridge.
RUN git clone -b ${MICRO_XRCE_DDS_AGENT_REF} --depth 1 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git /tmp/Micro-XRCE-DDS-Agent && \
    cmake -S /tmp/Micro-XRCE-DDS-Agent -B /tmp/Micro-XRCE-DDS-Agent/build && \
    cmake --build /tmp/Micro-XRCE-DDS-Agent/build -j"$(nproc)" && \
    cmake --install /tmp/Micro-XRCE-DDS-Agent/build && \
    ldconfig /usr/local/lib && \
    rm -rf /tmp/Micro-XRCE-DDS-Agent

# MAVROS geographiclib datasets, best-effort because mirrors occasionally fail.
RUN if [ -x /opt/ros/humble/lib/mavros/install_geographiclib_datasets.sh ]; then \
      /opt/ros/humble/lib/mavros/install_geographiclib_datasets.sh || true; \
    fi

# Workspace directories.
RUN rosdep init || true && rosdep update || true && \
    mkdir -p ${ROS_WS}/src ${PEGASUS_WS}/src /workspace/isaacsim /workspace/pegasus /workspace/data /etc/cyclonedds

COPY config/px4_humble_cyclonedds.xml /etc/cyclonedds/px4_humble.xml
COPY scripts/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Lightweight desktop launcher registered with supervisor.
RUN cat <<'EOF' >/usr/local/bin/start_desktop.sh
#!/usr/bin/env bash
set -euo pipefail
export DISPLAY="${DISPLAY:-:1}"
RESOLUTION="${RESOLUTION:-1920x1080x24}"

if ! pgrep -f "Xvfb ${DISPLAY}" >/dev/null 2>&1; then
  Xvfb "${DISPLAY}" -screen 0 "${RESOLUTION}" -ac +extension GLX +render -noreset &
fi
sleep 2
if ! pgrep -f "xfce4-session" >/dev/null 2>&1; then
  startxfce4 &
fi
sleep 2
if ! pgrep -f "x11vnc.*${DISPLAY}" >/dev/null 2>&1; then
  x11vnc -display "${DISPLAY}" -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 -xkb &
fi
exec websockify --web=/usr/share/novnc/ 0.0.0.0:6080 localhost:5900
EOF
RUN chmod +x /usr/local/bin/start_desktop.sh && \
    mkdir -p /etc/supervisor/conf.d && \
    cat <<'EOF' >/etc/supervisor/conf.d/desktop.conf
[program:desktop]
command=/usr/local/bin/start_desktop.sh
autostart=true
autorestart=true
startsecs=5
stdout_logfile=/var/log/desktop.log
stderr_logfile=/var/log/desktop.err
EOF

RUN cat <<'EOF' >/etc/profile.d/drone_humble_vast.sh
export ROS_WS="${ROS_WS:-/workspaces/ros2_ws}"
export PEGASUS_WS="${PEGASUS_WS:-/workspaces/pegasus_ws}"
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}"
export CYCLONEDDS_URI="${CYCLONEDDS_URI:-file:///etc/cyclonedds/px4_humble.xml}"
alias rosenv='source /opt/ros/humble/setup.bash && [ -f "$ROS_WS/install/setup.bash" ] && source "$ROS_WS/install/setup.bash" || true'
alias foxglove='start_foxglove.sh'
alias microxrce='start_microxrce_agent.sh'
alias verify_drone='verify_drone_stack.sh'
EOF

EXPOSE 5900 6080 8080 8765 9090 8000 3000 5173 7000 7001 7002 11811/tcp 11811/udp 8888/udp

WORKDIR /workspaces
