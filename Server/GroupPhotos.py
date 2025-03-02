from Photos import Photos
from GoogleManager import GoogleManager
from utils import colors


def group_photos(body_data, work_dir):
    access_token = body_data["AccessToken"]
    current_dir = body_data["CurrentDirectory"]
    content = body_data["Content"]
    google_manager = GoogleManager(access_token)
    images: list[Photos]
    method, group_by = body_data["Method"].split('.')

    images = google_manager.get_images_data(content,
                                            work_dir,
                                            get_images=False)
    folders: dict[str:str] = {}  # Folder name and folder id

    match method:
        # * FACE
        case "Face":
            images = google_manager.get_images_data(content,
                                                    work_dir,
                                                    get_images=True)
            for image in images:
                image.save()

            return
        # * DATE
        case "Date":
            group_by = 'date'

        case _:
            pass

    for image in images:
        if group_by == 'date':
            name = image.createdTime.strftime("%d.%m.%Y")
        else:
            name = image.imageMediaMetadata.get(group_by)
            if not name:
                continue

        if not folders.get(name):
            folder_id = google_manager.get_folder_id(name)
            if not folder_id:  # if not exist create
                folder_id = google_manager.create_folder(name,
                                                         current_dir)
            folders[name] = folder_id
        google_manager.move_file(file_id=image.id,
                                 parents_id=image.parents,
                                 new_parent_id=folders[name])
