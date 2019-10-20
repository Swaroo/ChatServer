Initially, cd into the directory where you cloned the repo

1> First build the Docker image with the following command :
	docker build -t <image_name> .

2> Run the Docker image with the following command :
	docker run -it --rm -p 3000:3000 <image_name>:latest

3> Install the npm and Node.js

4> Use npm to install create-react-app
	sudo npm install -g create-react-app

5> Install react dev tools on chrome extension store
	https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en

6> cd into "ui" directory. Run "npm start" to run react code (webpage automatically opens).
   React code is being run from ui/src/index.js and is running in localhost:3006
	 port can be changed in package.json->scripts->start


