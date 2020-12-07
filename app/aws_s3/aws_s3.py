import logging
import boto3
from botocore.exceptions import ClientError

logging.basicConfig(format='%(asctime)s %(levelname)s %(process)d --- %(name)s %(funcName)20s() : %(message)s',
                    datefmt='%d-%b-%y %H:%M:%S', level=logging.INFO)


def upload_object(object: bytes, bucket: str, key: str, content_type: str,
                  grant_read: str = None, metadata={}) -> bool:
    """
    Upload an image file to an S3 bucket

    object: The file in bytes to upload to s3
    bucket: Bucket to upload to
    key: The key to save the object as
    content_type: The ContentType of the object
    grant_read: Specify the read-access of the object, default is public read
    metadata: A dict to specify any metadata

    Returns:
        True if file was uploaded, else False
    """
    if grant_read is None:
        grant_read = 'uri="http://acs.amazonaws.com/groups/global/AllUsers"'
    s3_client = boto3.client('s3')
    try:
        s3_client.put_object(Body=object, Bucket=bucket, GrantRead=grant_read, ContentType=content_type, Key=key,
                             Metadata=metadata)
        logging.info(f"Successfully uploaded object to '{bucket}' as '{key}'.")
    except ClientError as e:
        logging.error(e)
        return False
    return True
