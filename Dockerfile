FROM swift:5.1

# Create app directory
WORKDIR /app/kombucha

# Copy necessary components
COPY Package.swift ./
COPY Sources ./Sources
COPY Tests ./Tests

# Add a default config
COPY sample.json ./kombucha.json

# Build the release
RUN swift build -c release

# Create build symlink
RUN ln -s /app/kombucha/.build/release/kombucha /usr/local/bin/kombucha