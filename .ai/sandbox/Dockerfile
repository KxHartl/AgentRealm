# Secure, isolated python sandbox for AgentRealm execution
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    build-essential \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Set up non-root user for security
RUN useradd -m -s /bin/bash agent
WORKDIR /home/agent/workspace

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Switch to the non-root user
USER agent

# Default entrypoint to start a bash terminal
CMD ["/bin/bash"]
