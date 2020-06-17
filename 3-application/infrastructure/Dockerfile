FROM openjdk:alpine

EXPOSE 8080 
ADD springbootapp.jar springbootapp.jar

#entry point to execute inside the container 
#-Xmx1024 ( complier arguments for memory management - 1gigbyte 1024 as minimum  )
#-Xmx1800m give it the tio level for that memory 
#use this as baseline for the container needs 
ENTRYPOINT ["java", "-jar", "-Xms1024m", "-Xmx1800m", "springbootapp.jar"]
