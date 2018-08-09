FROM jupyter/datascience-notebook

RUN sed -i "s/#c.NotebookApp.password = ''/c.NotebookApp.password = u'sha1:344d4aabc211:b23f6906656d3cae576d970c67aecc0a9f86545b'/" /home/jovyan/.jupyter/jupyter_notebook_config.py

VOLUME /home/jovyan/Explore311