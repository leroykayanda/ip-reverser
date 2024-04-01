FROM python:3.8-slim
WORKDIR /app
COPY ip-reverser/requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY ip-reverser/app.py .
EXPOSE 8080
CMD ["python3", "app.py"]