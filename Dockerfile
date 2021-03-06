FROM python:3.8.3-slim-buster as base
EXPOSE 5000
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Prevent writing .pyc files on the import of source modules
# and set unbuffered mode to ensure logging outputs
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set working directory
WORKDIR /app

# Add default user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME 

# Install requirements
COPY ./requirements.txt . 
RUN pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade pip
RUN pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt


############### DEVELOPMENT ###############
FROM base as development
ENV FLASK_APP=wsgi.py
ENV FLASK_ENV=development
COPY ./requirements-test.txt .
RUN pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements-test.txt

COPY . .
RUN bandit -r app \
  && pylint app \
  && safety check -r requirements.txt -r requirements-test.txt \
  && mypy app \
  && pytest

USER $USERNAME
CMD flask run -h 0.0.0.0 -p 5000 

############### PRODUCTION ###############
FROM base as production
COPY . .
USER $USERNAME
CMD gunicorn --bind 0.0.0.0:5000 'wsgi:app'
