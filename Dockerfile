# Use a base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy application code
COPY . /app

# Install dependencies
RUN pip install -r requirements.txt

# Expose application port
EXPOSE 5000

# Command to run the application
CMD ["python", "app.py"]
