# jupyter-multy-kernel
dockerized multi kernel notebook

## Current Supported Kernels:

* Python
* PHP
* C#
* R

## using docker-compose:

change/set up the .env file.
NOTEBOOK_VOLUME= # shared volume for notebooks data / default - ./notebook_data
NOTE_BOOK_PORT= # the notebook port / default - 8888

1. docker-compose up -d
2. go to http://localhost:NOTE_BOOK_PORT

To add notebook security remove the following from the docker-compose.yml file:
- --NotebookApp.token=''
- --NotebookApp.password=''