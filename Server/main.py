import socket
import ssl
import threading
from utils import colors
import utils
from handle_connection import handle_connection
import os

# Define server address and port
server_address = ("localhost", 8443)

# Create a socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Create an SSL context
context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
context.verify_mode = ssl.CERT_REQUIRED
context.load_verify_locations("../keys/ca.crt")
context.load_cert_chain(certfile="../keys/server.crt",
                        keyfile="../keys/server.pem")


def main():
    os.system('clear')
    # Bind the socket to the address and port
    sock.bind(server_address)
    sock.listen(5)
    threads = []
    while True:
        print(
            f'{colors().highlight(f"Server listening on {server_address[0]}:{server_address[1]}", "blue")}')
        try:
            client_socket, client_address = sock.accept()
            print(
                f'{colors().highlight("Connection from: ", "green")}{client_address}')

            # * New thread for each connection
            threads.append(
                threading.Thread(target=handle_connection,
                                 args=(context.wrap_socket(client_socket, server_side=True),))
            )
            threads[-1].start()

        except KeyboardInterrupt:
            print(colors().highlight("\nServer shutting down...", "blue"))
            sock.close()
            utils.remove_files("content")
            for thread in threads:
                thread.join()
            break
        except Exception as e:
            print(f'{colors().highlight("Connection error: ", "red")}{e}')


if __name__ == "__main__":
    main()
