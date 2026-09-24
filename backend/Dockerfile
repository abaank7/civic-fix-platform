FROM python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory to the backend root
WORKDIR /backend

# Install dependencies
COPY requirements.txt .
RUN uv pip install --system --no-cache -r requirements.txt

# Copy the entire backend folder (including the app directory)
COPY . .

# Run Uvicorn from /backend, targeting main.py inside the app module
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}