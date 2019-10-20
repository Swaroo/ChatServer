Initially, cd into the directory where you cloned the repo

1> First build the Docker image with the following command :
	docker build -t <image_name> .

2> Run the Docker image with the following command :
	docker run -it --rm -p 3000:3000 <image_name>:latest
