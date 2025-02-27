import os


def remove_files(dir):
    for filename in os.listdir(dir):
        file_path = os.path.join(dir, filename)
        try:
            if os.path.isdir(file_path):
                remove_files(file_path)
                if file_path != 'content':
                    os.rmdir(file_path)
            else:
                os.remove(file_path)
        except Exception as e:
            print(
                f'{colors().highlight("Failed to delete", "red")} \'{file_path}\'. Reason: {e}')


class colors:
    def __init__(self):
        self.RED = '\033[38;5;196m'
        self.WHITE = '\033[97m'
        self.BLUE = '\033[94m'
        self.GREEN = '\033[92m'
        self.YELLOW = '\033[93m'
        self.CYAN = '\033[96m'
        self.MAGENTA = '\033[95m'
        self.RESET = '\033[0m'

    def highlight(self, text: str, color: str):
        color = color.lower()
        match color:
            case 'red':
                h_color = self.RED
            case 'white':
                h_color = self.WHITE
            case 'blue':
                h_color = self.BLUE
            case 'green':
                h_color = self.GREEN
            case 'yellow':
                h_color = self.YELLOW
            case 'cyan':
                h_color = self.CYAN
            case 'magenta':
                h_color = self.MAGENTA
            case _:
                h_color = self.RESET

        return f"{h_color}{text}{self.RESET}"
