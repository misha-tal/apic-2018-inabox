FROM openjdk:7
COPY fakeSMTP-2.0.jar /app/fakeSMTP-2.0.jar
WORKDIR /app/
EXPOSE 25
CMD java -jar fakeSMTP-2.0.jar -o ./emails/ -b -s -p 25