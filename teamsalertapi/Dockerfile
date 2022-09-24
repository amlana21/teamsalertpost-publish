FROM ubuntu:20.04
RUN apt-get update -y && apt-get install software-properties-common -y  && apt-get upgrade -y && apt-get install curl -y
RUN mkdir /home/pipinstall && mkdir /home/teamsalertap
RUN cd home/pipinstall && apt install python3-pip -y
EXPOSE 5000
WORKDIR /home/teamsalertap
COPY . /home/teamsalertap
RUN pip3 install -r requirements.txt
CMD ["gunicorn", "--bind", "0.0.0.0:5000","-w","4","-k","uvicorn.workers.UvicornWorker", "main:app"]