# Use the Python 3.13 slim image to match your local uv environment
FROM python:3.13-slim

# Copy the pre-compiled uv binary from Astral's official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt .

# Use uv to install dependencies globally within the container
RUN uv pip install --system --no-cache -r requirements.txt

# Copy the rest of the backend source code
COPY . .

# Expose the port Cloud Run expects (8080 is standard)
EXPOSE 8080

# Run the FastAPI application using Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]