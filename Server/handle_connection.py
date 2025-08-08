from utils import *
from GroupPhotos import *
import ssl
import json


def handle_connection(ssl_client_socket: ssl.SSLSocket):
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
    # * {
    # *    "Type": "Group",
    # *    "Method": "Face" | "Date" | "Metadata.<data>"
    # *    "AccessToken" : - Access token from Google OAuth
    # *    "CurrentDirectory" : - Current directory in Google Drive
    # *    "Content": - List of file ids
    # * }

    formatted_headers = headers.replace("\n", "\n\t")
    print(f"{colors().highlight('Received Headers:', 'blue')}\n\t{formatted_headers}")
    print(f"{colors().highlight('Received Body: ', 'blue')}{body_data.decode('utf-8')}")

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

    body_data = json.loads(body_data.decode())
    group_photos(body_data)
    ssl_client_socket.send(http_response.encode())

    ssl_client_socket.close()
