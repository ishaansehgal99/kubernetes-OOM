FROM python:3.9-alpine

WORKDIR /app

COPY ./mem-stress.py .

CMD ["python", "mem-stress.py"]