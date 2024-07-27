FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED True

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

ENV PORT 8080

RUN pip install --no-cache-dir -r requirements.txt

# Install production dependencies.
#RUN pip install uvicorn

EXPOSE 8080

# As an example here we're running the web service with one worker on uvicorn.
# CMD exec uvicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 main:app
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers 1
