# drone-humble-vast-desktop

Vast.ai GPU desktop container for a drone inspection project using ROS2 Humble, DDS/PX4 tooling, Pegasus for Isaac Sim 5.1, Foxglove, and backend/dashboard development.

This repo intentionally does **not** use Isaac ROS.

## Maintainer setup guide

For Isaac Sim 5.1, Pegasus, VNC/noVNC display notes, root launch handling, DDS, and troubleshooting, see:

```text
docs/ISAAC_SIM_PEGASUS_VNC_SETUP.md
```

## Target stack

- Ubuntu 22.04 / ROS2 Humble
- Vast.ai CUDA base image
- Lightweight XFCE/noVNC desktop
- PX4 ROS2 support through Micro XRCE-DDS Agent
- Foxglove Bridge and rosbridge
- MAVROS/MAVLink utilities
- Backend/frontend development ports
- Optional Tailscale support
- Manual Isaac Sim 5.1 install later under `/workspace/isaacsim`
- Pegasus installed later inside Isaac Sim as an Isaac Sim extension

## Why DDS stays

PX4 ROS2 integration uses the PX4 `uxrce_dds_client` and a Micro XRCE-DDS Agent on the companion computer. PX4 documents ROS2 Humble on Ubuntu 22.04 as the recommended platform, and shows building Micro XRCE-DDS Agent v2.4.3 and running it with `MicroXRCEAgent udp4 -p 8888`.

## Expected image

```text
ghcr.io/dingdongdengdong/drone-humble-vast-desktop:ubuntu22
```

## Vast Docker options

```bash
--cap-add=NET_ADMIN \
--device=/dev/net/tun \
-p 1111:1111 \
-p 6100:6100 \
-p 73478:73478 \
-p 8384:8384 \
-p 72299:72299 \
-p 6200:6200 \
-p 5900:5900 \
-p 6080:6080 \
-p 8080:8080 \
-p 8765:8765 \
-p 9090:9090 \
-p 8000:8000 \
-p 3000:3000 \
-p 5173:5173 \
-p 7000:7000 \
-p 7001:7001 \
-p 7002:7002 \
-p 8888:8888/udp \
-p 11811:11811 \
-p 11811:11811/udp \
-e OPEN_BUTTON_TOKEN="1" \
-e JUPYTER_DIR="/" \
-e DATA_DIRECTORY="/workspace/" \
-e PORTAL_CONFIG="localhost:1111:11111:/:Instance Portal|localhost:6100:16100:/:Selkies Low Latency Desktop|localhost:6200:16200:/guacamole:Apache Guacamole Desktop (VNC)|localhost:6080:6080:/:noVNC Desktop|localhost:8080:8080:/:Jupyter|localhost:8080:8080:/terminals/1:Jupyter Terminal|localhost:8384:18384:/:Syncthing|localhost:8765:8765:/:Foxglove Bridge|localhost:8000:8000:/:Backend API|localhost:3000:3000:/:Frontend" \
-e OPEN_BUTTON_PORT="1111" \
-e SELKIES_ENCODER="x264enc"
```

## Important ports

| Port | Protocol | Purpose |
|---:|:---:|---|
| 5900 | TCP | VNC |
| 6080 | TCP | noVNC fallback desktop |
| 8080 | TCP | Jupyter / web tools |
| 8765 | TCP | Foxglove Bridge |
| 9090 | TCP | rosbridge websocket |
| 8000 | TCP | Backend API, FastAPI/Django |
| 3000 | TCP | React/Next frontend |
| 5173 | TCP | Vite frontend dev server |
| 8888 | UDP | Micro XRCE-DDS Agent default PX4 port |
| 11811 | TCP/UDP | Optional Fast DDS Discovery Server |

## Typical workflow

Verify the container:

```bash
verify_drone_stack.sh
```

Open a ROS2 Humble shell:

```bash
ros_humble_shell.sh
```

Start the PX4 Micro XRCE-DDS Agent:

```bash
start_microxrce_agent.sh
```

Start Foxglove Bridge:

```bash
start_foxglove.sh
```

Prepare PX4 ROS2 workspace sources:

```bash
setup_px4_ros_ws.sh
build_ros2_ws.sh
```

Launch Isaac Sim later from a clean shell, not a ROS-sourced shell:

```bash
isaac_clean_shell.sh
cd /workspace/isaacsim
./isaac-sim.sh
```

## Pegasus note

Pegasus is for Isaac Sim 5.1. It should be installed after Isaac Sim is installed. This image prepares the OS, ROS2, DDS, PX4 bridge tools, development ports, and desktop access, but does not bake Isaac Sim or Pegasus into the Docker image.

Suggested directories:

```text
/workspace/isaacsim
/workspace/pegasus
/workspaces/ros2_ws
/workspaces/pegasus_ws
```

## DDS guidance

For PX4 <-> ROS2, start Micro XRCE-DDS Agent on UDP 8888. For ROS2 nodes inside the same container, no extra port mapping is needed. For ROS2 DDS between your laptop and Vast, prefer Tailscale plus explicit CycloneDDS peers or a Fast DDS Discovery Server instead of trying to expose dynamic DDS ports publicly.
