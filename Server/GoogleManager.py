import requests
from utils import colors
from Photos import Photos


class GoogleManager:
    def get_image(self, access_token, file_id):
        url = f"https://www.googleapis.com/drive/v3/files/{file_id}?alt=media"
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            print(
                f"{colors().highlight('Successfully', 'green')} fetched image for file_id  {file_id}")
            return response.content
        else:
            response.raise_for_status()

    def get_file_metadata(self, access_token, file_id):
        url = f"https://www.googleapis.com/drive/v3/files/{file_id}"
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        params = {
            "fields": "id,name,mimeType,createdTime,modifiedTime,imageMediaMetadata"
        }
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            file_metadata = response.json()
            return file_metadata
        else:
            response.raise_for_status()

    def get_images(self, access_token, file_ids, dir_path: str) -> dict[str: str]:

        images: list[Photos] = []
        for file_id in file_ids:
            try:
                metadata = self.get_file_metadata(access_token, file_id)
                if metadata['mimeType'] == "application/vnd.google-apps.folder":  # If folder
                    files = self.get_files(access_token, file_id)
                    file_ids.extend(files)
                elif metadata['mimeType'].startswith("image/"):  # If image
                    image = self.get_image(access_token, file_id)

                    metadata['filepath'] = f'{dir_path}/{metadata["name"]}'
                    images.append(Photos(image, **metadata))
                    images[-1].save()

            except requests.exceptions.HTTPError as e:
                print(
                    f"{colors().highlight('Error:', 'red')} Failed to get image for file_id {file_id}: {e}")
        return images

    def get_files(self, access_token, folder_id):
        url = "https://www.googleapis.com/drive/v3/files"
        headers = {"Authorization": f"Bearer {access_token}"}
        params = {
            "q": f"'{folder_id}' in parents",
            "fields": "files(id, name, mimeType)"
        }
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return [x['id'] for x in response.json()["files"]]
        else:
            response.raise_for_status()
