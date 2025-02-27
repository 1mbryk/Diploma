from utils import *
from GoogleManager import GoogleManager
from GroupPhotos import *
import ssl
import json
import uuid
import os


def handle_connection(ssl_client_socket: ssl.SSLSocket):
    work_dir = f'content/{uuid.uuid4()}'
    try:
        os.mkdir(work_dir)
    except Exception as e:
        print(f'{colors().highlight("Failed to create directory", "red")}: {e}')

    print(colors().highlight("SSL Handshake successful", "green"))

    # Read the request line and headers
    request_data = ssl_client_socket.recv(1024).decode("utf-8")
    headers, _, body = request_data.partition(
        "\r\n\r\n")  # Split headers and body

    # Extract Content-Length if available
    content_length = 0
    for line in headers.split("\r\n"):
        if line.lower().startswith("content-length:"):
            content_length = int(line.split(":")[1].strip())

    # Read remaining body data if not fully received
    body_data = body.encode()
    while len(body_data) < content_length:
        body_data += ssl_client_socket.recv(content_length - len(body_data))

    # ? Expected body format
    # {
    #    "Type": "Group",
    #    "Method": "Face" | "Date" | "Metadata"
    #    "AccessToken" : - Access token from Google OAuth
    #    "CurrentDirectory" : - Current directory in Google Drive
    #    "Content": - List of file ids
    # }

    formatted_headers = headers.replace("\n", "\n\t")
    print(f"{colors().highlight('Received Headers:','blue')}\n\t{formatted_headers}")
    print(f"{colors().highlight('Received Body: ','blue')}{body_data.decode('utf-8')}")

    response_body = json.dumps(
        {
            "recieved": len(body_data),
        }
    )

    http_response = f"""\
                    HTTP/1.1 200 OK
                    Content-Type: text/plain
                    Content-Length: {len(response_body)}

                    {response_body}
                    """
    ssl_client_socket.send(http_response.encode())

    body_data = json.loads(body_data.decode())
    access_token = body_data["AccessToken"]
    if access_token != None:
        manager = GoogleManager()
        images = manager.get_images(
            access_token, body_data["Content"], work_dir)
    else:
        remove_files(work_dir)
        return
    group_photos(images,
                 body_data['Content'],
                 body_data['CurrentDirectory'],
                 body_data['Method'])
    # ! for debug:
    input()
    remove_files(work_dir)
