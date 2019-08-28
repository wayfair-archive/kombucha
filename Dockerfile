FROM swift:5.0.2

# Create app directory
WORKDIR /app

# Copy necessary components
COPY Package.swift ./
COPY Sources ./Sources
COPY Tests ./Tests

# Build the release
RUN swift build -c release