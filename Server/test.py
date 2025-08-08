from ultralytics import YOLO
import matplotlib.pyplot as plt
import cv2

model = YOLO('./yolo.pt')
img = cv2.imread(
    '/Users/macvejpazh/Downloads/IMG_3893.JPG')
results = model.predict(img, verbose=False)

color = (0, 255, 255)
for result in results:
    for box in result.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        cv2.rectangle(img, (x1, y1), (x2, y2), color, 8)

plt.figure(figsize=(20, 20))
plt.axis("off")
plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
plt.subplots_adjust(left=0, bottom=0, right=1, top=1)
plt.show()
