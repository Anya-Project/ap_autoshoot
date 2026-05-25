import os
import io
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from rembg import remove
from PIL import Image

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "message": "Rembg server is running"}), 200

@app.route('/process', methods=['POST'])
def process_image():
    remove_bg = True
    enable_upscale = True
    img_data = None
    upload_type = 'discord'
    upload_url = 'https://api.fivemanage.com/api/v3/file'
    token = None
    webhook_url = None

    if request.is_json:
        req_data = request.get_json()
        image_url = req_data.get('image_url')
        if image_url:
            print(f"[Rembg] Fetching: {image_url}")
            try:
                resp = requests.get(image_url)
                if resp.status_code == 200:
                    img_data = resp.content
                else:
                    return jsonify({"error": f"Download failed, status: {resp.status_code}"}), 400
            except Exception as e:
                return jsonify({"error": str(e)}), 400
        
        upload_type = req_data.get('upload_type', 'discord')
        upload_url = req_data.get('upload_url', upload_url)
        token = req_data.get('upload_token')
        webhook_url = req_data.get('discord_webhook')
        remove_bg = req_data.get('remove_bg', True)
        enable_upscale = req_data.get('enable_upscale', True)
    
    if not img_data:
        file_key = 'file'
        if 'file' not in request.files:
            if 'files[]' in request.files:
                file_key = 'files[]'
            else:
                return jsonify({"error": "No file or image_url"}), 400
                
        uploaded_file = request.files[file_key]
        img_data = uploaded_file.read()
        
        upload_type = request.headers.get('X-Upload-Type', 'discord')
        upload_url = request.headers.get('X-Upload-Url', 'https://api.fivemanage.com/api/v3/file')
        token = request.headers.get('X-Upload-Token')
        webhook_url = request.headers.get('X-Discord-Webhook')
        remove_bg = request.headers.get('X-Remove-Bg', 'true').lower() == 'true'
        enable_upscale = request.headers.get('X-Enable-Upscale', 'true').lower() == 'true'
    
    print(f"[Rembg] Processing image: {len(img_data)} bytes")
    
    try:
        input_image = Image.open(io.BytesIO(img_data))
        
        if remove_bg:
            output_image = remove(input_image)
            bbox = output_image.getbbox()
            if bbox:
                padding = 15
                left = max(0, bbox[0] - padding)
                upper = max(0, bbox[1] - padding)
                right = min(output_image.width, bbox[2] + padding)
                lower = min(output_image.height, bbox[3] + padding)
                output_image = output_image.crop((left, upper, right, lower))
        else:
            output_image = input_image
            
        from PIL import ImageEnhance
        
        color_enhancer = ImageEnhance.Color(output_image)
        output_image = color_enhancer.enhance(1.12)
        
        contrast_enhancer = ImageEnhance.Contrast(output_image)
        output_image = contrast_enhancer.enhance(1.10)
        
        sharpness_enhancer = ImageEnhance.Sharpness(output_image)
        output_image = sharpness_enhancer.enhance(1.35)
        
        if enable_upscale:
            target_width = 1920
            if output_image.width < target_width:
                scale_factor = target_width / output_image.width
                target_height = int(output_image.height * scale_factor)
                
                try:
                    resample_filter = Image.Resampling.LANCZOS
                except AttributeError:
                    resample_filter = Image.LANCZOS
                    
                output_image = output_image.resize((target_width, target_height), resample=resample_filter)
        
        output_buffer = io.BytesIO()
        output_image.save(output_buffer, format='PNG')
        output_buffer.seek(0)
        
        if upload_type == 'fivemanage':
            if not token:
                token = request.headers.get('X-Upload-Token')
            if not token:
                return jsonify({"error": "Missing token"}), 400
            if not upload_url:
                upload_url = request.headers.get('X-Upload-Url', 'https://api.fivemanage.com/api/v3/file')
                
            files = {
                'file': ('screenshot.png', output_buffer, 'image/png')
            }
            headers = {
                'Authorization': token
            }
            resp = requests.post(upload_url, files=files, headers=headers)
            
            if resp.status_code not in [200, 201]:
                print(f"[Rembg] FiveManage error: {resp.status_code} - {resp.text}")
                return jsonify({"error": f"FiveManage error: {resp.status_code}"}), 502
                
            resp_data = resp.json()
            url = resp_data.get('data', {}).get('url')
            if url:
                return jsonify({"url": url})
            else:
                return jsonify({"error": "No URL in response"}), 500
                
        else:
            if not webhook_url:
                webhook_url = request.headers.get('X-Discord-Webhook')
            if not webhook_url:
                return jsonify({"error": "Missing webhook"}), 400
                
            if "wait=true" not in webhook_url:
                if "?" in webhook_url:
                    webhook_url += "&wait=true"
                else:
                    webhook_url += "?wait=true"
                    
            files = {
                'file': ('screenshot.png', output_buffer, 'image/png')
            }
            resp = requests.post(webhook_url, files=files)
            
            if resp.status_code not in [200, 204]:
                print(f"[Rembg] Discord error: {resp.status_code} - {resp.text}")
                return jsonify({"error": f"Discord error: {resp.status_code}"}), 502
                
            resp_data = resp.json()
            
            attachments = resp_data.get('attachments', [])
            if attachments:
                cdn_url = attachments[0].get('url')
                return jsonify({"url": cdn_url})
            else:
                return jsonify({"error": "No attachment URL"}), 500
                
    except Exception as e:
        print(f"[Rembg] Exception: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"Starting Rembg Server on port {port}")
    app.run(host='0.0.0.0', port=port)
