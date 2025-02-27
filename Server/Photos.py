from datetime import date
from utils import colors


class Photos:
    id: str
    image: bytes
    filepath: str
    createdTime: date
    modifiedTime: date
    imageMediaMetadata: dict

    def __init__(self, image, id, filepath, createdTime, modifiedTime, imageMediaMetadata, **kwargs):
        self.image = image
        self.id = id
        self.filepath = filepath
        self.createdTime = createdTime
        self.modifiedTime = modifiedTime
        self.imageMediaMetadata = imageMediaMetadata

    def save(self):
        with open(self.filepath, "wb") as file:
            try:
                file.write(self.image)
            except Exception as e:
                print(
                    f"{colors().highlight('Error:', 'red')} Failed to save image: {e}")
                return
            print(
                f"{colors().highlight('Successfully', 'green')} saved image")
