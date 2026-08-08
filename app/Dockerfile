# -slim image is much smaller than the default image by stripping out build tools making the image lighter and faster to deploy
FROM python:3.12-slim 

# Set the container's working directory
WORKDIR /app

# We want to copy requiremnts.txt and then install them simiarly to how we set up the venv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all the files into the current working directory
COPY . .

# Expose the port the app will run on. This is documentation and doesn't actually publish the port by itself
EXPOSE 8080

# Run the app
CMD ["python", "main.py"]