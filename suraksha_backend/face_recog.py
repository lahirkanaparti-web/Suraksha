import cv2
import face_recognition
import serial
import numpy as np
import requests
import time

# CHANGE THIS
ESP32_STREAM = "http://10.135.41.132/stream"
arduino = serial.Serial('COM5', 9600)

time.sleep(2)

# Load known face
known = face_recognition.load_image_file("me.jpg")
known_enc = face_recognition.face_encodings(known)[0]

video = cv2.VideoCapture(ESP32_STREAM)

while True:
    ret, frame = video.read()
    if not ret:
        continue

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    faces = face_recognition.face_locations(rgb)
    encs = face_recognition.face_encodings(rgb, faces)

    for enc in encs:
        match = face_recognition.compare_faces([known_enc], enc)

        if True in match:
            print("ACCESS GRANTED")
            arduino.write(b'1')  # unlock
            time.sleep(5)

    cv2.imshow("ESP32-CAM Face Lock", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

video.release()
cv2.destroyAllWindows()