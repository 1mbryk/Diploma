from Photos import Photos
from GoogleManager import GoogleManager
from utils import colors


def group_photos(body_data, work_dir):
    access_token = body_data["AccessToken"]
    current_dir = body_data["CurrentDirectory"]
    content = body_data["Content"]
    google_manager = GoogleManager(access_token)
    images: list[Photos]
    match body_data["Method"]:
        # * FACE
        case "Face":
            images = google_manager.get_images_data(content,
                                                    work_dir,
                                                    get_images=True)
            for image in images:
                image.save()

        # * DATE
        case "Date":
            images = google_manager.get_images_data(content,
                                                    work_dir,
                                                    get_images=False)
            folders: dict[str:str] = {}  # Folder name and folder id
            for image in images:
                date = image.createdTime.strftime("%d.%m.%Y")
                if not folders.get(date):
                    folder_id = google_manager.get_folder_id(date)
                    if not folder_id:  # if not exist create
                        folder_id = google_manager.create_folder(date,
                                                                 current_dir)
                    folders[date] = folder_id
                google_manager.move_file(file_id=image.id,
                                         parents_id=image.parents,
                                         new_parent_id=folders[date])

        case "Metadata":
            pass
        case _:
            pass
