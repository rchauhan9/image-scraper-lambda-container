import scraper
import aws_s3 as s3s


def handler(event, context):
    scr = scraper.ImageScraper()
    urls = scr.get_image_urls(query=event['query'], max_urls=event['count'], sleep_between_interactions=1)
    files = []
    for url in urls:
        img_obj, img_hash = scr.get_in_memory_image(url, 'jpeg')
        files.append(img_hash)
        s3s.upload_object(img_obj, event['bucket'], event['folder_path']+img_hash, 'jpeg')
    scr.close_connection()
    return "Successfully loaded {} images to bucket {}. Folder path {} and file names {}.".format(event['count'],
                                                                                                  event['bucket'],
                                                                                                  event['folder_path'],
                                                                                                  files)
