import requests
from utils import colors
from Photos import Photos


class GoogleManager:
    def __init__(self, access_token):
        self.base_url = "https://www.googleapis.com/drive/v3/files"
        self.access_token = access_token
        self.headers = {
            "Authorization": f"Bearer {self.access_token}"
        }

    # * Getter methods
    def get_image(self, file_id):
        url = f"{self.base_url}/{file_id}?alt=media"
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            print(
                f"{colors().highlight('Successfully', 'green')} fetched image for file_id  {file_id}")
            return response.content
        else:
            response.raise_for_status()

    def get_file_metadata(self, file_id):
        url = f"{self.base_url}/{file_id}"
        params = {
            "fields": "id,name,mimeType,createdTime,modifiedTime,parents,imageMediaMetadata"
        }
        response = requests.get(url, headers=self.headers, params=params)
        if response.status_code == 200:
            file_metadata = response.json()
            return file_metadata
        else:
            response.raise_for_status()

    def get_images_data(self, file_ids, dir_path: str, get_images=True) -> list[Photos]:
        """
        Args:
            access_token (str): The OAuth2 access token for Google Drive API authentication
            file_ids (list): List of Google Drive file IDs to process
            dir_path (str): Local directory path where images will be saved
            get_images (bool, optional): If True, downloads actual image data. If False, only metadata is retrieved. Defaults to True.

        Returns: 
            list[Photos]: A list of Photos objects containing image data and metadata
      """

        images: list[Photos] = []
        for file_id in file_ids:
            try:
                metadata = self.get_file_metadata(file_id)
                if metadata['mimeType'] == "application/vnd.google-apps.folder":  # If folder
                    files = self.get_files(file_id)
                    file_ids.extend(files)
                elif metadata['mimeType'].startswith("image/"):  # If image
                    if get_images:
                        image = self.get_image(file_id)
                    else:
                        image = None

                    metadata['filepath'] = f'{dir_path}/{metadata["name"]}'
                    images.append(Photos(image=image, **metadata))

            except requests.exceptions.HTTPError as e:
                print(
                    f"{colors().highlight('Error:', 'red')} Failed to get image for file_id {file_id}: {e}")
        return images

    def get_files(self, folder_id):
        url = f"{self.base_url}"
        params = {
            "q": f"'{folder_id}' in parents",
            "fields": "files(id, name, mimeType)"
        }
        response = requests.get(url, headers=self.headers, params=params)
        if response.status_code == 200:
            return [x['id'] for x in response.json()["files"]]
        else:
            print(f"{colors().highlight('Error', 'red')}: Failed get files")
            response.raise_for_status()

    def get_folder_id(self, folder_name):
        params = {
            "q": f"mimeType='application/vnd.google-apps.folder' and name='{folder_name}'",
            "fields": "files(id, name)"
        }

        response = requests.get(
            self.base_url, headers=self.headers, params=params)

        if response.status_code == 200:
            files = response.json().get("files", [])
            return files[0]["id"] if files else None
        else:
            print(
                f"{colors().highlight('Error', 'red')}: Failed to get folder id'")
            return {"error": response.json(), "status_code": response.status_code}

    # * Setter methods

    def create_folder(self, folder_name, parent_folder_id=None):
        url = f"{self.base_url}"
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        data = {
            "name": folder_name,
            "mimeType": "application/vnd.google-apps.folder"
        }
        if parent_folder_id:
            data["parents"] = [parent_folder_id]
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            print(
                f"{colors().highlight('Successfully', 'green')} created folder {folder_name}")
            return response.json()["id"]
        else:
            print(
                f"{colors().highlight('Error:', 'red')} Failed to create folder {folder_name}")
            response.raise_for_status()

    def move_file(self, file_id, parents_id, new_parent_id):
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        params = {
            "addParents": new_parent_id,
            "removeParents": parents_id,
        }

        url = f"{self.base_url}/{file_id}"

        response = requests.patch(url, headers=headers, params=params)

        if response.status_code == 200:
            print(
                f"{colors().highlight('Successfully', 'green')} moved file '{file_id}'")
            return response.json()
        else:
            response.raise_for_status()
            print(
                f"{colors().highlight('Error', 'red')}: Failed to move file '{file_id}'")
            return {"error": response.json(), "status_code": response.status_code}
