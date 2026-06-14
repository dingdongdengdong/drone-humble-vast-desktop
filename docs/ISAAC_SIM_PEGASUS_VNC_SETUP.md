# Isaac Sim 5.1 + Pegasus on Vast.ai: Desktop, VNC, DDS, and Maintainer Setup

This guide is for maintainers setting up `drone-humble-vast-desktop` for a ROS2 Humble + PX4 DDS + Pegasus drone simulation workflow on Vast.ai.

This project intentionally does **not** use Isaac ROS.

## 1. Stack summary

Target runtime stack:

```text
Vast.ai GPU instance
├── Ubuntu 22.04
├── ROS2 Humble
├── PX4 DDS tooling
├── Micro XRCE-DDS Agent on UDP 8888
├── Foxglove Bridge on TCP 8765
├── rosbridge on TCP 9090
├── backend/frontend dev ports
├── Isaac Sim 5.1 installed manually under /workspace/isaacsim
└── Pegasus Simulator v5.1.0 installed manually under /workspace/pegasus/PegasusSimulator
```

Pegasus v5.1.0 targets Isaac Sim 5.1.0. Do not mix Pegasus v5.1.0 with older Isaac Sim versions.

## 2. Important ports

Recommended Vast Docker Options include these ports:

```bash
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
-p 11811:11811/udp
```

Port meanings:

| Port | Protocol | Purpose |
|---:|:---:|---|
| 5900 | TCP | VNC |
| 6080 | TCP | noVNC fallback desktop |
| 8080 | TCP | Jupyter / web tools |
| 8765 | TCP | Foxglove Bridge |
| 9090 | TCP | rosbridge websocket |
| 8000 | TCP | backend API |
| 3000 | TCP | React/Next frontend |
| 5173 | TCP | Vite frontend |
| 8888 | UDP | Micro XRCE-DDS Agent for PX4 |
| 11811 | TCP/UDP | optional Fast DDS Discovery Server |

## 3. Desktop access options

### 3.1 noVNC / VNC

The image provides a fallback desktop using:

```text
Xvfb + xfce4 + x11vnc + websockify/noVNC
```

This is useful for terminals, file browser, light GUI tools, and setup work.

Access noVNC over SSH tunnel:

```bash
ssh -p <VAST_SSH_PORT> root@<VAST_IP> \
  -L 6080:localhost:6080 \
  -L 8080:localhost:8080 \
  -L 8765:localhost:8765 \
  -L 8000:localhost:8000
```

Then open:

```text
http://localhost:6080/vnc.html
```

### 3.2 noVNC caveat for Isaac Sim GUI

The fallback noVNC display is normally an Xvfb software display. Isaac Sim GUI needs a real GPU-backed OpenGL/Vulkan display.

If the VNC display uses Mesa/llvmpipe software rendering, Isaac Sim GUI may crash, show a black screen, or fail during Kit startup.

Check the renderer inside the VNC desktop terminal:

```bash
apt-get update && apt-get install -y mesa-utils vulkan-tools
DISPLAY=:1 glxinfo -B | egrep 'OpenGL vendor|OpenGL renderer|OpenGL version' || true
vulkaninfo --summary | head -80 || true
```

Good sign:

```text
OpenGL vendor string: NVIDIA Corporation
OpenGL renderer string: NVIDIA RTX ...
```

Bad sign:

```text
llvmpipe
Mesa
Software Rasterizer
```

If the renderer is `llvmpipe`, do not expect Isaac Sim GUI to work well in that VNC session. Use a GPU-backed desktop session such as Selkies/real Xorg/VirtualGL, or run Isaac Sim headless.

## 4. Isaac Sim 5.1 install

Install Isaac Sim manually under `/workspace/isaacsim`:

```bash
cd /workspace
mkdir -p isaacsim
cd /workspace/isaacsim

wget https://download.isaacsim.omniverse.nvidia.com/isaac-sim-standalone-5.1.0-linux-x86_64.zip
unzip isaac-sim-standalone-5.1.0-linux-x86_64.zip
./post_install.sh
rm isaac-sim-standalone-5.1.0-linux-x86_64.zip
```

Validate Isaac Python:

```bash
/workspace/isaacsim/python.sh -c "print('Isaac Python OK')"
```

## 5. `isaac_run` helper

Because Vast containers commonly run as root, Isaac Sim needs either:

```bash
export OMNI_KIT_ALLOW_ROOT=1
```

or:

```bash
--allow-root
```

Create a helper command:

```bash
cat >/usr/local/bin/isaac_run <<'SCRIPT'
#!/usr/bin/env bash
set -eo pipefail

export DISPLAY="${DISPLAY:-:1}"
export ISAACSIM_PATH="${ISAACSIM_PATH:-/workspace/isaacsim}"
export ISAACSIM_PYTHON="${ISAACSIM_PATH}/python.sh"
export ISAACSIM="${ISAACSIM_PATH}/isaac-sim.sh"

export OMNI_KIT_ALLOW_ROOT=1
export ROS_DISTRO=humble
export RMW_IMPLEMENTATION="${ISAAC_RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"

unset AMENT_PREFIX_PATH COLCON_PREFIX_PATH PYTHONPATH CMAKE_PREFIX_PATH || true

if [ -n "${LD_LIBRARY_PATH:-}" ]; then
  LD_LIBRARY_PATH="$(echo "${LD_LIBRARY_PATH}" | tr ':' '\n' | grep -v '^/opt/ros/humble' | paste -sd ':' -)"
fi

if [ -d "${ISAACSIM_PATH}/exts/isaacsim.ros2.bridge/humble/lib" ]; then
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:${ISAACSIM_PATH}/exts/isaacsim.ros2.bridge/humble/lib"
fi

if [ ! -x "${ISAACSIM}" ]; then
  echo "Isaac Sim launcher not found or not executable: ${ISAACSIM}" >&2
  exit 1
fi

if [ ! -x "${ISAACSIM_PYTHON}" ]; then
  echo "Isaac Sim python.sh not found or not executable: ${ISAACSIM_PYTHON}" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  exec "${ISAACSIM}" --allow-root
elif [[ "$1" == --* ]]; then
  exec "${ISAACSIM}" --allow-root "$@"
elif [ -f "$1" ]; then
  exec "${ISAACSIM_PYTHON}" "$@"
else
  echo "Usage:"
  echo "  isaac_run"
  echo "  isaac_run --help"
  echo "  isaac_run script.py"
  exit 1
fi
SCRIPT

chmod +x /usr/local/bin/isaac_run
```

Test:

```bash
isaac_run --help
```

Launch GUI on the active VNC/X display:

```bash
export DISPLAY=:1
isaac_run
```

Run headless test:

```bash
isaac_run --no-window --/app/quitAfter=10
```

## 6. Running Isaac Sim from VNC vs SSH

To display Isaac Sim in VNC, the process must target the VNC display:

```bash
export DISPLAY=:1
export OMNI_KIT_ALLOW_ROOT=1
cd /workspace/isaacsim
./isaac-sim.sh --allow-root
```

Running the same command from SSH is acceptable if `DISPLAY=:1` points to the VNC display. However, if that display is Xvfb/software-rendered, Isaac Sim GUI may still crash.

## 7. Install Pegasus Simulator v5.1.0

Install after Isaac Sim is validated:

```bash
cd /workspace
mkdir -p pegasus
cd /workspace/pegasus

git clone https://github.com/PegasusSimulator/PegasusSimulator.git
cd PegasusSimulator
git checkout v5.1.0
```

Install Pegasus into Isaac Sim Python:

```bash
cd /workspace/pegasus/PegasusSimulator/extensions
/workspace/isaacsim/python.sh -m pip install --editable pegasus.simulator
```

Enable Pegasus in Isaac Sim GUI:

```text
Window → Extensions → Settings/gear icon
Add extension search path:
  /workspace/pegasus/PegasusSimulator/extensions
Third Party tab → enable Pegasus Simulator
```

## 8. PX4 and DDS flow

Start the Micro XRCE-DDS Agent in a separate terminal:

```bash
start_microxrce_agent.sh
```

This runs the equivalent of:

```bash
MicroXRCEAgent udp4 -p 8888
```

Keep this terminal open while PX4/Pegasus is running.

Expected ROS2 topics after PX4 connects:

```text
/fmu/out/vehicle_odometry
/fmu/out/vehicle_status
/fmu/out/sensor_combined
/fmu/in/trajectory_setpoint
/fmu/in/offboard_control_mode
```

Check topics:

```bash
ros_humble_shell.sh
ros2 topic list
```

## 9. Foxglove

Start Foxglove Bridge:

```bash
start_foxglove.sh
```

Use SSH tunnel:

```bash
ssh -p <VAST_SSH_PORT> root@<VAST_IP> -L 8765:localhost:8765
```

Connect Foxglove to:

```text
ws://localhost:8765
```

## 10. Troubleshooting

### Cloudflare 502 from Vast web desktop

A Cloudflare 502 usually means the tunnel is alive but the backend desktop service is not responding.

Check listeners:

```bash
ss -lntp | egrep '1111|6100|6200|5900|6080|8080|8384|8765|9090|8000|3000|5173' || true
```

Fallback route:

```text
Use SSH tunnel to localhost:6080 and open http://localhost:6080/vnc.html
```

### `AMENT_TRACE_SETUP_FILES: unbound variable`

Do not use `set -u` while sourcing ROS setup files. Use:

```bash
set -eo pipefail
source /opt/ros/humble/setup.bash
```

### `MicroXRCEAgent missing` but `/usr/local/bin/MicroXRCEAgent` exists

This can be a false negative from a shell pipeline with `pipefail`. Check directly:

```bash
command -v MicroXRCEAgent
MicroXRCEAgent --help | sed -n '1,20p'
```

### Isaac Sim refuses root

Use:

```bash
export OMNI_KIT_ALLOW_ROOT=1
./isaac-sim.sh --allow-root
```

### Isaac Sim crashes in VNC

Check whether the display is GPU-backed:

```bash
DISPLAY=:1 glxinfo -B | egrep 'OpenGL vendor|OpenGL renderer|OpenGL version'
vulkaninfo --summary | head -80
```

If renderer is `llvmpipe`/Mesa software rasterizer, VNC is not GPU-backed enough for Isaac Sim GUI.

## 11. References

- Pegasus Simulator docs: https://pegasussimulator.github.io/PegasusSimulator/
- Pegasus installation docs: https://pegasussimulator.github.io/PegasusSimulator/source/setup/installation.html
- Pegasus GitHub: https://github.com/PegasusSimulator/PegasusSimulator
- PX4 ROS2 guide: https://docs.px4.io/main/en/ros2/user_guide.html
