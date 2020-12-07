# Image Scraper - Containerised for AWS Lambda Deployment
This project containerises a web scraper that can query Google Images and then scrape
and save a specified number of results to an AWS S3 Bucket of choice.

## The Source Code
The src code for this project is found in the [app](./app) directory; [app.py](./app/app.py)
contains the lambda function handler and modules [scraper](./app/scraper) and [aws_s3](./app/aws_s3)
are helper modules for image scraping and persisting to S3 respectively.

## The Dockerfile and building the image
The [Dockerfile](./Dockerfile) contains the instructions to build this image. You can
run the command to create the image lambda/image-scraper version 1.0
```
docker build -t lambda/image-scraper:1.0 .
```

## Running and experimenting locally
The image can be run locally before you deploy to deploy to AWS Lambda. Providing
you already have AWS credentials setup in `~/.aws/credentials` you can simply run the
command.
```
docker run -p 9000:8080 -v ~/.aws/:/root/.aws/ lambda/image-scraper:1.0
```
The -v flag mounts your local AWS credentials into the docker container allowing it access
to your AWS account and S3 bucket.

To confirm the container is working as it should locally, you can run a similar command to
```
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"query":"labrador", "count":3
, "bucket":"my-dogs", "folder_path":"local/"}'
```
This command intends to query google images for 'labrador', scrape the first 3 images
returned and then persist them to a bucket called 'my-dogs' within a 'folder' called
'local'. A successful result should return something like this...
```
"Successfully loaded 3 images to bucket my-dogs. Folder path local/ and file names ['4ddebbca9a.jpeg', 'eafde83cd9.jpeg
', 'b61b601eea.jpeg']."
```
The image names are based on a hash of their data so the names are likely to differ. You can also 
verify the result by checking your S3 bucket on AWS.

## Deploying to Lambda.
AWS Lambda can now take an image to run as a serverless function. At the time of
writing this feature is limited to certain regions so you will need to carefully select
the region. For extra help, AWS have published a guide to working with containers in 
Lambda https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html.

You will also need to create an Elastic Container Registry within AWS - a place to 
store your Docker images so they can be used by Lambda. For extra help, AWS have published
a guide to working with ECR https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html.

## Debugging - Gotchas and Quick Fixes
Once running your container on Lambda you may get an error message. This may be a result of a short
timeout period and low memory capacity. I use a timeout period of 60 seconds and a
500Mb allocation of memory to be on the safe side. I am only scraping 2-3 images per request. You
may need to adjust your timeout and memory needs accordingly.