FROM swift:5.0.1-bionic
WORKDIR /app
COPY Package.swift ./
COPY Sources ./Sources
COPY Tests ./Tests
RUN swift build -c release