FROM python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY requirements.txt .
RUN uv pip install --system --no-cache -r requirements.txt
COPY . .

# Move into the backend folder where main.py lives
WORKDIR /backend/app

# Run uvicorn using the dynamic Cloud Run port
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}