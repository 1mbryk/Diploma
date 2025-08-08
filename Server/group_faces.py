import cv2
from Photos import Photos
from ultralytics import YOLO
from itertools import compress
import face_recognition as fr


def group_faces(images: list[Photos]) -> list[list[Photos]]:
    model = YOLO('./yolo.pt')

    photos_metadata = []
    photos = []
    boxes = []

    imgs = [cv2.imread(image.filepath) for image in images]

    results = model.predict(imgs, verbose=False)

    for image, result in zip(images, results):
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            photos_metadata.append(image)
            photos.append(fr.load_image_file(image.filepath))
            boxes.append((y1, x2, y2, x1))

    img_encoded = []
    for image, box in zip(photos, boxes):
        enc = fr.face_encodings(image, [box], model='large')
        if enc:
            img_encoded.append(enc[0])

    skip_indexes = []
    persons = []
    for i in range(len(img_encoded)):
        if i in skip_indexes:
            continue
        distances = fr.face_distance(img_encoded, img_encoded[i])
        mask = distances < 0.5
        skip_indexes.extend([i for i, val in enumerate(mask) if val])
        persons.append(list(compress(photos_metadata, mask)))

    return persons
