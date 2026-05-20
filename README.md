# CS340400 HW3 — Codegen

## Repository Structure

```
compiler-design-2026-hw3/
├── docker-compose.yml
├── src/
│   ├── scanner.l       ← YOUR WORK GOES HERE
│   ├── parser.y        ← YOUR WORK GOES HERE
│   ├── Makefile        ← do not modify
│   └── main.c          ← do not modify
├── testcases/
│   ├── ArithmeticExpression/
│   ├── Basic/
│   └── ...
└── scripts/
    ├── run_test.sh         ← run all testcases (docker)
    ├── run_codegen.sh      ← run your codegen (docker)
    ├── run_golden.sh       ← run golden codegen (docker)
    └── local_run_test.sh   ← run all testcases (local, no docker)
```

---

## Path A — Develop with Docker (Recommended)

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine + Compose

### Setup

```bash
docker pull compilerdesign/compiler-design-2026-hw3
```

### Workflow

Edit `src/scanner.l` and `src/parser.y`, then:

**Run all testcases:**
```bash
./scripts/run_test.sh
```

**Run a single testcase:**
```bash
./scripts/run_test.sh Basic/0
```

**Debug mode — see your output vs golden side by side:**
```bash
./scripts/run_test.sh debug Basic/0
```

**Run your codegen interactively:**
```bash
./scripts/run_codegen.sh < testcases/Basic/0.c
```

**Run the golden codegen interactively:**
```bash
./scripts/run_golden.sh < testcases/Basic/0.c
```

**Drop into a shell inside the container:**
```bash
docker compose run --rm hw3 bash
```

Inside the container you can compile and test manually:
```bash
# compile
cp /hw3/src/scanner.l /hw3/build/
cp /hw3/src/parser.y /hw3/build/
cp /hw3/src/main.c /hw3/build/
make -C /hw3/build

# run your codegen
/hw3/build/codegen < /hw3/testcases/Basic/0.c
riscv32-unknown-elf-gcc /hw3/src/main.c codegen.S
spike pk a.out

# run golden codegen
riscv32-unknown-elf-gcc -S -c -DHIGH=1 -DLOW=0 -Wno-implicit-function-declaration /hw3/testcases/Basic/0.c -o golden_codegen.S
riscv32-unknown-elf-gcc -o golden.out /hw3/src/main.c golden_codegen.S
spike pk golden.out
```

---

## Path B — Develop Locally (No Docker)

If you have `flex` and `byacc` and `gcc` and RISC-V Toolchain installed locally, you can develop without Docker.

### Prerequisites

```bash
# Ubuntu / Debian
sudo apt install flex byacc gcc make

# macOS
brew install flex byacc
```

### RISC-V Toolchain Setup

The installation of the RISC-V toolchain is **the same as described in the section below**:

> **Docker file for building RISC-V Toolchain & Simulator**

Please follow that section to install:
- `riscv32-unknown-elf-gcc`
- `spike`
- `pk (proxy kernel)`
- required environment variables (`RISCV`, `PATH`)

After installation, set environment variables:

```bash
export RISCV=/opt/riscv
export PATH=$PATH:$RISCV/bin
```

Verify installation:

```bash
riscv32-unknown-elf-gcc --version
spike --version
```

### Workflow

Edit `src/scanner.l` and `src/parser.y`, then:

**Run all testcases:**
```bash
./scripts/local_run_test.sh
```

**Run a single testcase:**
```bash
./scripts/local_run_test.sh Basic/0
```

**Debug mode — see your output vs golden side by side:**
```bash
./scripts/local_run_test.sh debug Basic/0
```

### Docker file for building RISC-V Toolchain & Simulator
- For those who are interested in building and customizing the image on your own, you can refer to this Dockerfile for building the previously mentioned image. (platform of the build machine should be amd64/linux)
```dockerfile
# Dockerfile for Building RISC-V Toolchain & Simulator
# Developed for NTHU Compiler Design Class
# Use an appropriate base image
FROM ubuntu:22.04

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    byacc \
    flex \
    vim \
    wget \
    tar \
    git \
    device-tree-compiler \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV RISCV=/opt/riscv
# Add the toolchain to the PATH
ENV PATH="$PATH:$RISCV/bin"

# Create the directory where the toolchain will be installed
RUN mkdir -p $RISCV

# Download and extract the file
RUN wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2024.04.12/riscv32-elf-ubuntu-22.04-gcc-nightly-2024.04.12-nightly.tar.gz -O /tmp/riscv32-elf-gcc.tar.gz \
    && tar -xzf /tmp/riscv32-elf-gcc.tar.gz -C $RISCV --strip-components=1 \
    && rm /tmp/riscv32-elf-gcc.tar.gz

# Build pk
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/riscv-software-src/riscv-pk
WORKDIR /tmp/riscv-pk
RUN mkdir build
WORKDIR /tmp/riscv-pk/build
RUN ../configure --prefix=$RISCV --host=riscv32-unknown-elf \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf /tmp/riscv-pk

# Build Spike
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/riscv-software-src/riscv-isa-sim
WORKDIR /tmp/riscv-isa-sim
RUN mkdir build
WORKDIR /tmp/riscv-isa-sim/build
RUN ../configure --prefix=$RISCV --with-target=riscv32-unknown-elf --with-isa=RV32IMAFC \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf /tmp/riscv-isa-sim

WORKDIR /workspace

RUN echo 'export PS1="\[\033[01;32m\]root@compiler_design_2024spring@:\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]$ "' >> /root/.bashrc

# Set the entrypoint to bash
ENTRYPOINT ["/bin/bash"]
```

---

## Submission

Submit only `src/scanner.l` and `src/parser.y` to the course platform. Do not modify `src/Makefile` and `src/main.c`.
